#!/usr/bin/env perl

use strict;
use warnings;
use File::Find;
use Getopt::Long qw(:config auto_help auto_version);
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natsort);
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

# config
my @target_cgi_proj_codes = qw(
    ALL
    AML
    CCSK
    NBL
    OS
    WT
);

my $no_cell_lines_xenos = 0;
my $cell_lines_xenos_only = 0;
my $cases_only = 0;
GetOptions(
    'no-cell-lines-xenos' => \$no_cell_lines_xenos,
    'cell-lines-xenos-only' => \$cell_lines_xenos_only,
    'cases-only' => \$cases_only,
) || pod2usage(-verbose => 0);
pod2usage(-message => 'Project code required',
          -verbose => 0) unless @ARGV;
my $project_code = shift @ARGV;
my ($project, $subproject) = split('-', $project_code);
my $cgi_dataset_dir = "/local/target/data/$project/WGS/current/CGI";
die "ERROR: invalid CGI directory $cgi_dataset_dir\n" unless -d $cgi_dataset_dir;
print "$cgi_dataset_dir\n";
my @cases = split(/,/, shift @ARGV) if @ARGV;
my $cases_regexp_str = join('|', @cases);
my $barcode_regexp = $cases_regexp_str 
                   ? qr/(([A-Z]+-\d{2}(?:-\d{2})?-(?:$cases_regexp_str))-(\d{2})(?:\.\d+)?[A-Z]-\d{2}[A-Z])/
                   : qr/(([A-Z]+-\d{2}(?:-\d{2})?-[A-Z0-9]+)-(\d{2})(?:\.\d+)?[A-Z]-\d{2}[A-Z])/;
my %unique_ids;
find({
    follow => 1,
    wanted => sub {
        if (my ($barcode, $case, $tissue_code) = $_ =~ /$barcode_regexp/) {
            return if ($no_cell_lines_xenos   and $tissue_code =~ /^(5|6)/) or
                      ($cell_lines_xenos_only and $tissue_code !~ /^(5|6)/);
            $unique_ids{$case}{$barcode}++;
        }
    },
}, 
$cgi_dataset_dir);
if (%unique_ids) {
    for my $case (natsort keys %unique_ids) {
        if ($cases_only) {
            print "$case\n";
            next;
        }
        for my $barcode (natsort keys %{$unique_ids{$case}}) {
            print "$case\t$barcode\n";
        }
    }
}
exit;

__END__

=head1 NAME 

find_cgi_cases_barcodes.pl - TARGET CGI Case and Barcode Finder

=head1 SYNOPSIS

 find_cgi_cases_barcodes.pl [options] <project code> <case 1>,<case 2>,...,<case n>
 
 Parameters:
    <project code>              Disease project code (required)
    <case 1>,...,<case n>       List of case IDs to search for (optional: default find all barcodes)
 
 Options:
    --no-cell-lines-xenos       Exclude cell lines and xenografts
    --cell-lines-xenos-only     Include only cell lines and xenografts
    --cases-only                Display only cases
    --help                      Display usage message and exit
    --version                   Display program version and exit

=cut
