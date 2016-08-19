#!/usr/bin/env perl

use strict;
use warnings;
use sigtrap qw(handler sig_handler normal-signals error-signals ALRM);
use Cwd qw(abs_path);
use File::Basename qw(fileparse);
use File::Find;
use Getopt::Long qw(:config auto_help auto_version);
use List::Util qw(any all max none);
use List::MoreUtils qw(uniq);
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natsort);
use Spreadsheet::Read qw(ReadData cellrow);
use Term::ANSIColor;
use Data::Dumper;

sub sig_handler {
    die "Caught signal, exiting\n";
}

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;
#$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = sub {
    my ($hashref) = @_;
    my @sorted_keys = natsort keys %{$hashref};
    return \@sorted_keys;
};

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
my @data_level_dir_names = (
    'L1',
    'L2',
    'L3',
    'L4',
    'METADATA',
);
my @param_groups = qw(
    programs
    projects
    data_types
    data_sets
);

# options
my $list_only = 0;
my $clean = 0;
my $verbose = 0;
my $debug = 0;
GetOptions(
    'list-only' => \$list_only,
    'clean' => \$clean,
    'verbose' => \$verbose,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
my %user_params;
if (@ARGV) {
    for my $i (0 .. $#param_groups) {
        next unless defined($ARGV[$i]) and $ARGV[$i] !~ /^\s*$/;
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
                if ($user_param =~ /^RNA-seq$/i) {
                    $user_param = 'mRNA-seq';
                }
                elsif ($user_param =~ /^targeted_capture_seq/i) {
                    $user_param = 'Targeted-Capture';
                }
            }
            for my $data_type (@data_types) {
                push @valid_user_params, $data_type if any { m/^$data_type$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @data_types;
            }
            @valid_choices = @data_types;
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
for my $program_name (@program_names) {
    next if defined($user_params{programs}) and none { $program_name eq $_ } @{$user_params{programs}};
    my $manifest_download_gid = getgrnam("\L$program_name\E-dn-adm") 
        or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": couldn't get gid for \L$program_name\E-dn-adm\n";
    for my $project_name (@{$program_project_names{$program_name}}) {
        next if defined($user_params{projects}) and none { $project_name eq $_ } @{$user_params{projects}};
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
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid subproject '$subproject'\n";
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
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid subproject '$subproject'\n";
                }
            }
            else {
                die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid disease project '$disease_proj'\n";
            }
        }
        DATA_TYPE: for my $data_type (@data_types) {
            next if defined($user_params{data_types}) and none { $data_type eq $_ } @{$user_params{data_types}};
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
                next DATA_TYPE;
            }
            for my $dataset (@datasets) {
                next if defined($user_params{data_sets}) and none { $dataset eq $_ } @{$user_params{data_sets}};
                my $dataset_dir = $data_type_dir . ($dataset eq '' ? $dataset : "/$dataset" ) . '/current';
                next unless -d $dataset_dir;
                # data types that have data levels
                if (any { $data_type eq $_ } @data_types_w_data_levels) {
                    for my $data_level_dir_name (@data_level_dir_names) {
                        next unless $data_level_dir_name eq 'METADATA';
                        my $data_level_dir = "$dataset_dir/$data_level_dir_name";
                        next unless -d $data_level_dir;
                        my $printed_header;
                        find({
                            preprocess => sub {
                                return natsort @_;
                            },
                            wanted => sub {
                                # files only
                                return unless -f;
                                my $file_name = $_;
                                my $file = $File::Find::name;
                                my ($file_basename, $file_dir, $file_ext) = fileparse($file, qr/\.[^.]*/);
                                return unless $file_ext =~ /\.(xls|xlsx)$/i;
                                if (!$printed_header) {
                                    print "[$program_name $project_name $data_type", 
                                          ($dataset ne '' ? " $dataset" : ''),
                                          "]\n";
                                    $printed_header++;
                                }
                                my %readdata_opts = (
                                    cells => 0, attr => 0,
                                );
                                my $mage_tab_workbook = ReadData($file, %readdata_opts)
                                    or die colored('ERROR', 'red'), ": could not open MAGE-TAB archive $file";
                                if (
                                    scalar(keys %{$mage_tab_workbook->[0]->{sheet}}) != 2 or
                                    !exists($mage_tab_workbook->[0]->{sheet}->{IDF}) or
                                    $mage_tab_workbook->[0]->{sheet}->{IDF} != 1 or
                                    !exists($mage_tab_workbook->[0]->{sheet}->{SDRF}) or
                                    $mage_tab_workbook->[0]->{sheet}->{SDRF} != 2
                                ) {
                                    warn +(-t STDERR ? colored('WARN', 'red') : 'WARN'), 
                                         ": not a valid MAGE-TAB archive $file\n";
                                    return;
                                }
                                if ($list_only) {
                                    print "Found $file\n";
                                    return;
                                }
                                print "Using $file\n";
                                if ($clean) {
                                    (my $file_basename_wo_date = $file_basename) =~ s/_\d+$//;
                                    my @old_file_names = <"${file_dir}${file_basename_wo_date}*.{idf,sdrf}.txt">;
                                    for my $old_file_name (@old_file_names) {
                                        print "Removing $old_file_name\n";
                                        unlink($old_file_name) or die "ERROR: could not unlink $old_file_name: $!\n";
                                    }
                                }
                                my $v = "-v$verbose";
                                my $d = "-d$debug";
                                my $xlscat_cmd_1 = "xlscat $v $d -s '\\t' -u --noclip -S 1 $file > ${file_dir}${file_basename}.idf.txt";
                                print "$xlscat_cmd_1\n" if $debug;
                                print "Generating ${file_dir}${file_basename}.idf.txt\n";
                                system($xlscat_cmd_1) == 0 or die "ERROR: xlscat failed: ", $? >> 8, "\n";
                                # fix IDF file fields
                                open(my $idf_in_fh, '<', "${file_dir}${file_basename}.idf.txt") 
                                    or die "ERROR: could not read-open ${file_dir}${file_basename}.idf.txt\n";
                                chomp(my @idf_file_lines = <$idf_in_fh>);
                                close($idf_in_fh);
                                my ($num_protocols);
                                for my $idf_line (@idf_file_lines) {
                                    if ($idf_line =~ /^SDRF File/) {
                                        $idf_line =~ s/^SDRF File\t[^\t]+/SDRF File\t${file_basename}.sdrf.txt/;
                                    }
                                    elsif ($idf_line =~ /^Protocol Name/) {
                                        $num_protocols = scalar(split("\t", $idf_line)) - 1;
                                    }
                                    elsif ($idf_line =~ /^Protocol Description/) {
                                        my @protocol_descriptions = split("\t", $idf_line);
                                        if ($num_protocols != scalar(@protocol_descriptions) - 1) {
                                            warn +(-t STDERR ? colored('WARN', 'red') : 'WARN'), 
                                                 ": IDF protocol descriptions don't match number of protocols $num_protocols\n";
                                        }
                                        $idf_line = join("\t", $protocol_descriptions[0], map { s/"/\"/g; "\"$_\"" } @protocol_descriptions[1..$#protocol_descriptions]);
                                    }
                                }
                                open(my $idf_out_fh, '>', "${file_dir}${file_basename}.idf.txt") 
                                    or die "ERROR: could not write-open ${file_dir}${file_basename}.idf.txt\n";
                                print $idf_out_fh join("\n", @idf_file_lines);
                                close($idf_out_fh);
                                my $xlscat_cmd_2 = "xlscat $v $d -s '\\t' -u --noclip -S 2 $file > ${file_dir}${file_basename}.sdrf.txt";
                                print "$xlscat_cmd_2\n" if $debug;
                                print "Generating ${file_dir}${file_basename}.sdrf.txt\n";
                                system($xlscat_cmd_2) == 0 or die "ERROR: xlscat failed: ", $? >> 8, "\n";
                            },
                        }, $data_level_dir);
                    }
                }
            }
        }
    }
}
exit;

__END__

=head1 NAME 

convert_mage_tab_xls2txt.pl - MAGE-TAB XLS(X)-to-TXT Converter

=head1 SYNOPSIS

 convert_mage_tab_xls2txt.pl <project name(s)> <data type(s)> <data set(s)> [options]
 
 Parameters:
    <program name(s)>       Comma-separated list of program name(s) (optional, default: all programs)
    <project name(s)>       Comma-separated list of project name(s) (optional, default: all program projects)
    <data type(s)>          Comma-separated list of data type(s) (optional, default: all project data types)
    <data set(s)>           Comma-separated list of data set(s) (optional, default: all data type data sets)
 
 Options:
    --list-only             List MAGE-TAB archives found and exit
    --clean                 Clean up older versions of MAGE-TAB archives
    --verbose               Be verbose
    --debug                 Run in debug mode
    --help                  Display usage message and exit
    --version               Display program version and exit

=cut
