#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw(fileparse);
use File::Find;
use File::Spec;
use Getopt::Long qw(:config auto_help auto_version);
use List::MoreUtils qw(any);
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
my @target_cgi_proj_codes = qw(
    ALL
    AML
    CCSK
    NBL
    OS
    WT
);
my $target_data_dir = '/local/target/data';
my $cgi_dir_name = 'CGI';
my @cgi_data_dir_names = qw(
    PilotAnalysisPipeline2
    OptionAnalysisPipeline2
);

my $verbose = 0;
my $dry_run = 0;
my $clean_only = 0;
my $debug = 0;
GetOptions(
    'verbose' => \$verbose,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
my %user_cgi_proj_codes;
if (@ARGV) {
    %user_cgi_proj_codes = map { uc($_) => 1 } split(',', shift @ARGV);
    print STDERR "\%user_cgi_proj_codes:\n", Dumper(\%user_cgi_proj_codes) if $debug;
}
for my $proj_code (@target_cgi_proj_codes) {
    next if %user_cgi_proj_codes and !$user_cgi_proj_codes{uc($proj_code)};
    print "[$proj_code]\n";
    my $cgi_dataset_dir = "$target_data_dir/$proj_code/WGS/current/$cgi_dir_name";
    my @cgi_data_dirs;
    for my $dir_name (@cgi_data_dir_names) {
        my $cgi_data_dir = "$cgi_dataset_dir/$dir_name";
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
                if ($proj_code eq 'OS' and $dir =~ /(Pilot|Option)AnalysisPipeline2\/Illumina\/READMEs/i) {
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

list_target_cgi_normal_data_paths.pl

=head1 SYNOPSIS

 list_target_cgi_normal_data_paths.pl [options] <proj 1>,<proj 2>,...,<proj n>
 
 Parameters:
    <proj 1>,<proj 2>,...,<proj n>      Disease project code(s) (optional: default all disease projects)
 
 Options:
    --verbose                           Be verbose
    --debug                             Show debug information
    --help                              Display usage message and exit
    --version                           Display program version and exit

=cut

