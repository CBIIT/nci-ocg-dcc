#!/usr/bin/env perl

use strict;
use warnings;
use sigtrap qw(handler sig_handler normal-signals error-signals ALRM);
use Cwd qw(realpath);
use Digest::MD5;
#use Crypt::Digest::SHA256 qw(sha256_file_hex);
use Digest::SHA;
use File::Basename qw(fileparse);
use File::Find;
use File::Spec;
use Getopt::Long qw(:config auto_help auto_version);
use List::Util qw(any all max none);
use List::MoreUtils qw(uniq);
use Number::Bytes::Human;
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natsort);
use Term::ANSIColor;
use Data::Dumper;

sub sig_handler {
    die "Caught signal, exiting\n";
}

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

# const
my $CASE_REGEXP = qr/[A-Z]+-\d{2}(?:-\d{2})?-[A-Z0-9]+/;
my $BARCODE_REGEXP = qr/${CASE_REGEXP}-\d{2}(?:\.\d+)?[A-Z]-\d{2}[A-Z]/;
my $TARGET_CGI_CASE_DIR_REGEXP = qr/${CASE_REGEXP}(?:(?:-|_)\d+)?/;

# config
my @program_names = qw(
    TARGET
    CGCI
    CTD2
);
my %program_project_names = (
    TARGET => [qw(
        ALL
        AML
        CCSK
        MDLS-NBL
        MDLS-PPTP
        NBL
        OS
        OS-Brazil
        OS-Toronto
        RT
        WT
        Resources
    )],
    CGCI => [qw(
        BLGSP
        HTMCP-CC
        HTMCP-DLBCL
        HTMCP-LC
        MB
        NHL
        Resources
    )],
    CTD2 => [qw(
        Broad
        Columbia
        CSHL
        DFCI
        Emory
        FHCRC-1
        FHCRC-2
        MDACC
        Stanford
        TGen
        UCSF-1
        UCSF-2
        UTSW
        Resources
    )],
);
my @data_types = qw(
    biospecimen
    Bisulfite-seq
    ChIP-seq
    clinical
    copy_number_array
    gene_expression_array
    GWAS
    kinome
    methylation_array
    miRNA_array
    miRNA_pcr
    misc
    miRNA-seq
    mRNA-seq
    pathology_images
    SAMPLE_MATRIX
    targeted_capture_sequencing
    targeted_pcr_sequencing
    WGS
    WXS
);
my @data_types_w_data_levels = qw(
    Bisulfite-seq
    ChIP-seq
    copy_number_array
    gene_expression_array
    GWAS
    kinome
    methylation_array
    miRNA_array
    miRNA_pcr
    miRNA-seq
    mRNA-seq
    targeted_capture_sequencing
    targeted_pcr_sequencing
    WGS
    WXS
);
my $target_cgi_dir_name = 'CGI';
my @data_level_dir_names = (
    'L1',
    'L2',
    'L3',
    'L4',
    'METADATA',
    $target_cgi_dir_name,
);
my @param_groups = qw(
    programs
    projects
    data_types
    data_sets
    data_level_dirs
);

my $total_only = 0;
my $in_bytes = 0;
my $verbose = 0;
my $debug = 0;
GetOptions(
    'total-only' => \$total_only,
    'in-bytes' => \$in_bytes,
    'verbose' => \$verbose,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
my %user_params;
if (@ARGV) {
    for my $i (0 .. $#param_groups) {
        next unless defined $ARGV[$i] and $ARGV[$i] !~ /^\s*$/;
        my (@valid_user_params, @invalid_user_params, @valid_choices);
        my @user_params = split(',', $ARGV[$i]);
        if ($param_groups[$i] eq 'programs') {
            for my $program_name (@program_names) {
                push @valid_user_params, $program_name if any { m/^$program_name$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @program_names;
            }
            @valid_choices = @program_names;
        }
        elsif ($param_groups[$i] eq 'projects') {
            my @program_projects = uniq(
                defined($user_params{programs})
                    ? map { @{$program_project_names{$_}} } @{$user_params{programs}}
                    : map { @{$program_project_names{$_}} } @program_names
            );
            for my $project_name (@program_projects) {
                push @valid_user_params, $project_name if any { m/^$project_name$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @program_projects;
            }
            @valid_choices = @program_projects;
        }
        elsif ($param_groups[$i] eq 'data_types') {
            for my $user_param (@user_params) {
                $user_param = 'mRNA-seq' if $user_param =~ /^RNA-seq$/i;
            }
            for my $data_type (@data_types) {
                push @valid_user_params, $data_type if any { m/^$data_type$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @data_types;
            }
            @valid_choices = @data_types;
        }
        elsif ($param_groups[$i] eq 'data_level_dirs') {
            for my $data_level_dir_name (@data_level_dir_names) {
                push @valid_user_params, $data_level_dir_name if any { m/^$data_level_dir_name$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @data_level_dir_names;
            }
            @valid_choices = @data_level_dir_names;
        }
        else {
            @valid_user_params = @user_params;
        }
        if (@invalid_user_params) {
            (my $type = $param_groups[$i]) =~ s/s$//;
            $type =~ s/_/ /g;
            pod2usage(
                -message => 
                    "Invalid $type" . ( scalar(@invalid_user_params) > 1 ? 's' : '' ) . ': ' .
                    join(', ', @invalid_user_params) . "\n" .
                    'Choose from: ' . join(', ', @valid_choices),
                -verbose => 0,
            );
        }
        $user_params{$param_groups[$i]} = \@valid_user_params;
    }
}
print STDERR "\%user_params:\n", Dumper(\%user_params) if $debug;
my $total_num_bytes = 0;
my $total_num_files = 0;
my $printed_total_header;
my $total_output_str = '';
my $nbh = Number::Bytes::Human->new();
for my $program_name (@program_names) {
    next if defined $user_params{programs} and none { $program_name eq $_ } @{$user_params{programs}};
    for my $project_name (@{$program_project_names{$program_name}}) {
        next if defined $user_params{projects} and none { $project_name eq $_ } @{$user_params{projects}};
        my ($disease_proj, $subproject) = split /-(?=NBL|PPTP|Toronto|Brazil)/, $project_name, 2;
        my $project_dir = $disease_proj;
        if (defined $subproject) {
            if ($disease_proj eq 'MDLS') {
                if ($subproject eq 'NBL') {
                    $project_dir = "$project_dir/NBL";
                }
                elsif ($subproject eq 'PPTP') {
                    $project_dir = "$project_dir/PPTP";
                }
                else {
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                        ": invalid subproject '$subproject'\n";
                }
            }
            elsif ($disease_proj eq 'OS') {
                if ($subproject eq 'Toronto') {
                    $project_dir = "$project_dir/Toronto";
                }
                elsif ($subproject eq 'Brazil') {
                    $project_dir = "$project_dir/Brazil";
                }
                else {
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                        ": invalid subproject '$subproject'\n";
                }
            }
            else {
                die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                    ": invalid disease project '$disease_proj'\n";
            }
        }
        DATA_TYPE: for my $data_type (@data_types) {
            next if defined $user_params{data_types} and none { $data_type eq $_ } @{$user_params{data_types}};
            (my $data_type_dir_name = $data_type) =~ s/-Seq$/-seq/i;
            my $data_type_dir = "/local/\L$program_name\E/data/$project_dir/$data_type_dir_name";
            next unless -d $data_type_dir;
            opendir(my $data_type_dh, $data_type_dir) 
                or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $data_type_dir: $!";
            my @data_type_sub_dir_names = grep { -d "$data_type_dir/$_" and !m/^\./ } readdir($data_type_dh);
            closedir($data_type_dh);
            my @datasets;
            if (all { m/^(current|old)$/ } @data_type_sub_dir_names) {
                push @datasets, '';
            }
            elsif (none { m/^(current|old)$/ } @data_type_sub_dir_names) {
                for my $data_type_sub_dir_name (@data_type_sub_dir_names) {
                    my $data_type_sub_dir = "$data_type_dir/$data_type_sub_dir_name";
                    opendir(my $data_type_sub_dh, $data_type_sub_dir) 
                        or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $data_type_sub_dir: $!";
                    my @sub_dir_names = grep { -d "$data_type_sub_dir/$_" and !m/^\./ } readdir($data_type_sub_dh);
                    closedir($data_type_sub_dh);
                    if (all { m/^(current|old)$/ } @sub_dir_names) {
                        push @datasets, $data_type_sub_dir_name;
                    }
                    else {
                        warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": $data_type_dir subdirectory structure is invalid\n";
                        next DATA_TYPE;
                    }
                }
            }
            else {
                warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": $data_type_dir subdirectory structure is invalid\n";
                next;
            }
            for my $dataset (@datasets) {
                next if defined $user_params{data_sets} and none { $dataset eq $_ } @{$user_params{data_sets}};
                my $dataset_dir = $data_type_dir . ($dataset eq '' ? $dataset : "/$dataset" ) . '/current';
                next unless -d $dataset_dir;
                # data types that have data levels
                if (any { $data_type eq $_ } @data_types_w_data_levels) {
                    for my $data_level_dir_name (@data_level_dir_names) {
                        next if defined $user_params{data_level_dirs} and none { $data_level_dir_name eq $_ } @{$user_params{data_level_dirs}};
                        my $data_level_dir = "$dataset_dir/$data_level_dir_name";
                        next unless -d $data_level_dir;
                        my $num_bytes = 0;
                        my $num_files = 0;
                        my $printed_header;
                        my $output_str = '';
                        find({
                            follow => 1,
                            wanted => sub {
                                # files only
                                return unless -f;
                                $num_bytes += -s $File::Find::name;
                                $num_files++;
                                if (!$total_only) {
                                    if (!$printed_header) {
                                        print "[$program_name $project_name $data_type", 
                                              ($dataset ne '' ? " $dataset" : ''),
                                              " $data_level_dir_name", 
                                              "]\n";
                                        $printed_header++;
                                    }
                                    print "\r", ' ' x length($output_str);
                                    $output_str = ( $in_bytes ? $num_bytes : $nbh->format($num_bytes) ) . ", $num_files files";
                                    print "\r$output_str";
                                }
                            },
                        }, $data_level_dir);
                        $total_num_bytes += $num_bytes;
                        $total_num_files += $num_files;
                        if ($total_only) {
                            if (!$printed_total_header) {
                                print "[TOTAL]\n";
                                $printed_total_header++;
                            }
                            print "\r", ' ' x length($total_output_str);
                            $total_output_str = ( $in_bytes ? $total_num_bytes : $nbh->format($total_num_bytes) ) . ", $total_num_files files";
                            print "\r$total_output_str";
                        }
                        elsif ($num_files > 0) {
                            print "\n";
                        }
                    }
                }
                # data types that don't have data levels
                else {
                    my $num_bytes = 0;
                    my $num_files = 0;
                    my $printed_header;
                    my $output_str = '';
                    find({
                        follow => 1,
                        wanted => sub {
                            # files only
                            return unless -f;
                            $num_bytes += -s $File::Find::name;
                            $num_files++;
                            if (!$total_only) {
                                if (!$printed_header) {
                                    print "[$program_name $project_name $data_type", 
                                          ($dataset ne '' ? " $dataset" : ''),
                                          "]\n";
                                    $printed_header++;
                                }
                                print "\r", ' ' x length($output_str);
                                $output_str = ( $in_bytes ? $num_bytes : $nbh->format($num_bytes) ) . ", $num_files files";
                                print "\r$output_str";
                            }
                        },
                    }, $dataset_dir);
                    $total_num_bytes += $num_bytes;
                    $total_num_files += $num_files;
                    if ($total_only) {
                        if (!$printed_total_header) {
                            print "[TOTAL]\n";
                            $printed_total_header++;
                        }
                        print "\r", ' ' x length($total_output_str);
                        $total_output_str = ( $in_bytes ? $total_num_bytes : $nbh->format($total_num_bytes) ) . ", $total_num_files files";
                        print "\r$total_output_str";
                    }
                    elsif ($num_files > 0) {
                        print "\n";
                    }
                }
            }
        }
    }
}
if (!$total_only) {
    print "[TOTAL]\n",
          ( $in_bytes ? $total_num_bytes : $nbh->format($total_num_bytes) ),
          ", $total_num_files files\n";
}
else {
    print "\n";
}
exit;

__END__

=head1 NAME 

calculate_dcc_data_sizes.pl - OCG DCC Data Size Calculator

=head1 SYNOPSIS

 calculate_dcc_data_sizes.pl [options] <program name(s)> <project name(s)> <data type(s)> <data set(s)> <data level dir(s)>
 
 Parameters:
    <program name(s)>       Comma-separated list of program name(s) (optional, default: all programs)
    <project name(s)>       Comma-separated list of project name(s) (optional, default: all program projects)
    <data type(s)>          Comma-separated list of data type(s) (optional, default: all project data types)
    <data set(s)>           Comma-separated list of data set(s) (optional, default: all data type data sets)
    <data level dir(s)>     Comma-separated list of data level dir(s) (optional, default: all data set data level dirs)
 
 Options:
    --total-only            Report total size only of group being analyzed (default off)
    --in-bytes              Report size(s) in bytes (default off, human-readable sizes)
    --verbose               Be verbose
    --debug                 Show debug information
    --help                  Display usage message and exit
    --version               Display program version and exit

=cut
