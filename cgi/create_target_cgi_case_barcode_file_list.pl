#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw(fileparse);
use File::Find;
use File::Spec;
use Getopt::Long qw(:config auto_help auto_version);
use List::MoreUtils qw( any none );
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natkeysort);
use Data::Dumper;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

# const
my $CASE_REGEXP = qr/[A-Z]+-\d{2}(?:-\d{2})?-[A-Z0-9]+/;
my $CGI_CASE_DIR_REGEXP = qr/${CASE_REGEXP}(?:(?:-|_)\d+)?/o;
my $BARCODE_REGEXP = qr/${CASE_REGEXP}-\d{2}(?:\.\d+)?[A-Z]-\d{2}[A-Z]/o;

# config
my @project_names = qw(
    ALL
    AML
    CCSK
    NBL
    MDLS-NBL
    OS
    OS-Toronto
    WT
);
my $target_download_ctrld_dir = '/local/ocg-dcc/download/TARGET/Controlled';
my $data_type_dir_name = 'WGS';
my $cgi_dir_name = 'CGI';
my @target_cgi_data_dir_names = qw(
    PilotAnalysisPipeline2
    OptionAnalysisPipeline2
);
my @param_groups = qw(
    projects
);

my $verbose = 0;
my $dry_run = 0;
my $clean_only = 0;
my $debug = 0;
GetOptions(
    'verbose' => \$verbose,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
my %user_params;
if (@ARGV) {
    for my $i (0 .. $#param_groups) {
        next unless defined $ARGV[$i] and $ARGV[$i] !~ /^\s*$/;
        my (@valid_user_params, @invalid_user_params, @valid_choices);
        my @user_params = split(',', $ARGV[$i]);
        if ($param_groups[$i] eq 'projects') {
            for my $project_name (@project_names) {
                push @valid_user_params, $project_name if any { m/^$project_name$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @project_names;
            }
            @valid_choices = @project_names;
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
for my $project_name (@project_names) {
    next if defined $user_params{projects} and none { $project_name eq $_ } @{$user_params{projects}};
    print "[$project_name]\n";
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
    my $data_type_dir = "$target_download_ctrld_dir/$project_dir/$data_type_dir_name";
    my $dataset_dir_name = $project_name eq 'ALL' 
                         ? 'Phase1+2'
                         : '';
    my $dataset_dir = $dataset_dir_name
                    ? "$data_type_dir/$dataset_dir_name"
                    : $data_type_dir;
    my $dataset_cgi_dir = "$dataset_dir/$cgi_dir_name";
    my @cgi_data_dirs;
    for my $data_dir_name (@target_cgi_data_dir_names) {
        my $cgi_data_dir = "$dataset_cgi_dir/$data_dir_name";
        push @cgi_data_dirs, $cgi_data_dir if -d $cgi_data_dir;
    }
    if ($debug) {
        print STDERR "\@cgi_data_dirs:\n", Dumper(\@cgi_data_dirs);
    }
    my @file_data;
    find({
        follow => 1,
        wanted => sub {
            # directories
            if (-d) {
                my $dir_name = $_;
                my $dir = $File::Find::name;
                # skip OS Illumina READMEs directories
                if ($project_name eq 'OS' and $dir =~ /(Pilot|Option)AnalysisPipeline2\/Illumina\/READMEs/i) {
                    $File::Find::prune = 1;
                    return;
                }
                # TARGET case-named directories (with possible CGI numeric extension)
                elsif ($dir_name =~ /^$CGI_CASE_DIR_REGEXP$/o) {
                    # do nothing for now
                }
                # TARGET barcode-named directories
                elsif ($dir_name =~ /^$BARCODE_REGEXP$/o) {
                    # do nothing for now
                }
            }
            # files
            elsif (-f) {
                my $file_name = $_;
                my $file = $File::Find::name;
                my $dir = $File::Find::dir;
                if ($file_name =~ /^masterVarBeta/i) {
                    my @dir_parts = File::Spec->splitdir($dir);
                    my ($barcode) = grep { m/^$BARCODE_REGEXP$/ } @dir_parts;
                    my ($case) = $barcode =~ /^($CASE_REGEXP)/;
                    $file_name =~ s/\.bz2$//i;
                    push @file_data, [
                        $case,
                        $barcode,
                        $file_name,
                    ];
                }  
            }
        },
    }, @cgi_data_dirs);
    for my $data_row_arrayref (natkeysort { $_->[1] } @file_data) {
        print join("\t", @{$data_row_arrayref}), "\n";
    }
}
exit;

sub get_barcode_info {
    my ($barcode) = @_;
    my ($case_id, $disease_code, $tissue_code);
    my @barcode_parts = split('-', $barcode);
    # TARGET sample ID/barcode
    if (scalar(@barcode_parts) == 5) {
        $case_id = join('-', @barcode_parts[0..2]);
        ($disease_code, $tissue_code) = @barcode_parts[1,3];
    }
    else {
        die "\nERROR: invalid sample ID/barcode $barcode\n\n";
    }
    ($tissue_code, my $xeno_cell_line_code) = split(/\./, $tissue_code);
    my $tissue_ltr = substr($tissue_code, -1);
    #$tissue_code =~ s/\D//g;
    $tissue_code = substr($tissue_code, 0, 2);
    my $tissue_type = $tissue_code eq '01' ? 'Primary' :
                      $tissue_code eq '02' ? 'Recurrent' :
                      $tissue_code eq '03' ? 'Primary' :
                      $tissue_code eq '04' ? 'Recurrent' :
                      $tissue_code eq '05' ? 'Primary' :
                      # 06 is actually Metastatic but Primary for this purpose
                      $tissue_code eq '06' ? 'Primary' :
                      $tissue_code eq '09' ? 'Primary' :
                      $tissue_code eq '10' ? 'Normal' :
                      $tissue_code eq '11' ? 'Normal' :
                      $tissue_code eq '12' ? 'BuccalNormal' :
                      $tissue_code eq '13' ? 'EBVNormal' :
                      $tissue_code eq '14' ? 'Normal' :
                      $tissue_code eq '15' ? 'NormalFibroblast' :
                      $tissue_code eq '16' ? 'Normal' :
                      $tissue_code eq '20' ? 'CellLineControl' : 
                      $tissue_code eq '40' ? 'Recurrent' :
                      $tissue_code eq '41' ? 'Recurrent' :
                      $tissue_code eq '42' ? 'Recurrent' : 
                      $tissue_code eq '50' ? 'CellLine' :
                      $tissue_code eq '60' ? 'Xenograft' :
                      $tissue_code eq '61' ? 'Xenograft' :
                      undef;
    die "\nERROR: unknown tissue code $tissue_code\n\n" unless defined $tissue_type;
    # special fix for TARGET-10-PANKMB
    if ($case_id eq 'TARGET-10-PANKMB' and $tissue_type eq 'Primary') {
        $tissue_type .= "${tissue_code}${tissue_ltr}";
    }
    # special fix for TARGET-10-PAKKCA
    elsif ($case_id eq 'TARGET-10-PAKKCA' and $tissue_type eq 'Primary') {
        $tissue_type .= "${tissue_code}${tissue_ltr}";
    }
    # special fix for TARGET-30-PARKGJ
    elsif ($case_id eq 'TARGET-30-PARKGJ' and ($tissue_type eq 'Primary' or $tissue_type eq 'Normal')) {
        $tissue_type .= $barcode_parts[$#barcode_parts];
    }
    # special fix for TARGET-50-PAKJGM
    elsif ($case_id eq 'TARGET-50-PAKJGM' and $tissue_type eq 'Normal') {
        $tissue_type .= $barcode_parts[$#barcode_parts];
    }
    return ($case_id, $disease_code, $tissue_type, $xeno_cell_line_code);
}

__END__

=head1 NAME 

create_target_cgi_case_barcode_file_list.pl

=head1 SYNOPSIS

 create_target_cgi_case_barcode_file_list.pl [options] <proj 1>,<proj 2>,...,<proj n>
 
 Parameters:
    <proj 1>,<proj 2>,...,<proj n>      Disease project code(s) (optional: default all disease projects)
 
 Options:
    --verbose               Be verbose
    --debug                 Show debug information
    --help                  Display usage message and exit
    --version               Display program version and exit

=cut

