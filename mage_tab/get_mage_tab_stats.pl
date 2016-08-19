#!/usr/bin/env perl

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(fileparse);
use File::Find;
use Getopt::Long qw(:config auto_help auto_version);
use List::MoreUtils qw(uniq);
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natsort);
use Spreadsheet::Read qw(ReadData cellrow);
use Data::Dumper;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

my $list_mage_tabs = 0;
my $debug = 0;
GetOptions(
    'list-mage-tabs' => \$list_mage_tabs,
    'debug'          => \$debug,
) || pod2usage(-verbose => 0);
if (!@ARGV) {
    pod2usage(
        -message => 'Missing required parameter: top-level data/download directory path', 
        -verbose => 0
    ); 
}
my $root_data_dir_path = shift @ARGV;
if (!-d $root_data_dir_path or 
    abs_path($root_data_dir_path) !~ /^\/local\/(target|cgci)\/(data|download)\/?/) {
    pod2usage(
        -message => "Directory $root_data_dir_path is not allowed", 
        -verbose => 0,
    );
}
if (!$list_mage_tabs) {
    print "Disease Project\tAssay Type\tPlatform\tSources\tSamples\tExtracts\tRuns/Hybs\n";
}
my $is_data_path = abs_path($root_data_dir_path) =~ /^\/local\/(target|cgci)\/data\/?/ ? 1 : 0; 
find({
    preprocess => \&find_preprocess,
    wanted     => \&find_wanted,
    no_chdir   => 1,
}, $root_data_dir_path);
exit;

sub find_preprocess {
    return natsort @_;
}

sub find_wanted {
    return unless -f;
    my ($file_basename, $file_path, $file_ext) = fileparse($_, qr/\..*/);
    return unless ($is_data_path ? $file_path =~ /\/(current\/METADATA|METADATA\/current)\//i 
                                 : $file_path =~ /\/METADATA\//i and 
                                   $file_path !~ /^$root_data_dir_path\/(Controlled|Public)/i) and 
                  #$file_basename =~ /^MAGE-TAB/ and 
                  $file_ext =~ /\.(xls|xlsx|sdrf\.txt)$/i;
    my $mage_tab_path = $_;
    if ($list_mage_tabs) {
        print "$mage_tab_path\n";
        return;
    }
    my $mage_tab_is_csv = $mage_tab_path =~ /\.sdrf\.txt$/ ? 1 : 0;
    # create MAGE-TAB Spreadsheet::Read workbook
    my %readdata_opts = (
        cells => 0, attr => 0,
    );
    if ($mage_tab_is_csv) {
        $readdata_opts{parser} = 'csv';
        $readdata_opts{sep} = "\t";
    }
    my $mage_tab_workbook = ReadData($mage_tab_path, %readdata_opts)
        or die "ERROR: could not open $mage_tab_path\n\n";
    my $sdrf_sheet = $mage_tab_workbook->[$mage_tab_workbook->[0]->{sheets}];
    print STDERR "\$sdrf_sheet:\n", Dumper($sdrf_sheet) if $debug;
    # create @sdrf_col_headers data structure
    my @sdrf_col_headers = cellrow($sdrf_sheet, 1);
    # clean up column headers
    for (@sdrf_col_headers) {
        s/^\s+//;
        s/\s+$//;
        s/\s+/ /g;
    }
    print STDERR "\@sdrf_col_headers:\n", Dumper(\@sdrf_col_headers) if $debug;
    # create %sdrf_col_nums data structure
    my %sdrf_col_nums;
    for my $col_idx (0 .. $#sdrf_col_headers) {
        if (exists $sdrf_col_nums{$sdrf_col_headers[$col_idx]} or 
            exists $sdrf_col_nums{"$sdrf_col_headers[$col_idx] 1"}) {
            if (exists $sdrf_col_nums{$sdrf_col_headers[$col_idx]}) {
                $sdrf_col_nums{"$sdrf_col_headers[$col_idx] 1"} = $sdrf_col_nums{$sdrf_col_headers[$col_idx]};
                delete $sdrf_col_nums{$sdrf_col_headers[$col_idx]};
            }
            for (my $col_header_num = 2; ; $col_header_num++) {
                if (!exists $sdrf_col_nums{"$sdrf_col_headers[$col_idx] $col_header_num"}) {
                    $sdrf_col_nums{"$sdrf_col_headers[$col_idx] $col_header_num"} = $col_idx + 1;
                    last;
                }
            }
        }
        else {
            $sdrf_col_nums{$sdrf_col_headers[$col_idx]} = $col_idx + 1;
        }
    }
    print STDERR "\%sdrf_col_nums:\n", Dumper(\%sdrf_col_nums) if $debug;
    #die "ERROR: $mage_tab_path SDRF matrix not rectangular\n\n"
    #    unless $#{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Source Name'}]} == 
    #           $#{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Sample Name'}]} and
    #           $#{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Source Name'}]} ==
    #           $#{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Extract Name'}]} and
    #           $#{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Source Name'}]} ==
    #           $#{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Assay Name'}]};
    #my (@source_ids, @sample_ids, @extract_ids, @assay_ids);
    #for my $row_num (2 .. $#{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Source Name'}]}) {
    #    my $sample_id = $sdrf_sheet->{cell}->[$sdrf_col_nums{'Sample Name'}]->[$row_num];
    #    if (defined $sample_id and $sample_id !~ /^\s*$/) {
    #        print "$sample_id\n";
    #        my ($disease_project, $disease_code, $case_id, $tissue_code) = split '-', $sample_id;
    #        if (defined $tissue_code) {
    #            $tissue_code = substr($tissue_code, 0, 2);
    #            print "$tissue_code\n";
    #        }
    #    }
    #}
    my @source_ids = natsort uniq(
        grep {
            defined and !m/^\s*$/
        }
        @{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Source Name'}]}[
            2 .. $#{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Source Name'}]}
        ]
    );
    my @sample_ids = natsort uniq(
        grep {
            defined and !m/^\s*$/
        }
        @{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Sample Name'}]}[
            2 .. $#{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Sample Name'}]}
        ]
    );
    my @extract_ids = natsort uniq(
        grep {
            defined and !m/^\s*$/
        }
        @{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Extract Name'}]}[
            2 .. $#{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Extract Name'}]}
        ]
    );
    my @assay_ids = natsort uniq(
        grep {
            defined and !m/^\s*$/
        }
        @{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Assay Name'}]}[
            2 .. $#{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Assay Name'}]}
        ]
    );
    my (undef, undef, $disease_proj, $assay_type, $platform) = split('_', $file_basename);
    if (exists $sdrf_col_nums{'Comment[Platform]'}) {
        $platform = join('+', natsort uniq(
            map {
                m/^Complete Genomics/i ? 'CGI' :
                m/^Illumina/i          ? 'Illumina' : 
                                         $_
            }
            grep {
                defined and !m/^(\s*|unspecified)$/
            }
            @{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Comment[Platform]'}]}[
                2 .. $#{$sdrf_sheet->{cell}->[$sdrf_col_nums{'Comment[Platform]'}]}
            ]
        ));
    }
    print "$disease_proj\t$assay_type\t$platform\t", 
          scalar(@source_ids), "\t", scalar(@sample_ids), "\t", 
          scalar(@extract_ids), "\t", scalar(@assay_ids), "\n";
}

__END__

=head1 NAME 

get_mage_tab_stats.pl - MAGE-TAB Statistcs

=head1 SYNOPSIS

 get_mage_tab_stats.pl [options] <top-level data download directory path>
 
 Parameters:
    <top-level directory path>      Path to top-level data/download directory tree to search for MAGE-TAB archives
 
 Options:
    --list-mage-tabs                List MAGE-TAB archives found and exit
    --help                          Display usage message and exit
    --version                       Display program version and exit

=cut
