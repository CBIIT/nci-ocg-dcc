#!/usr/bin/env perl

use strict;
use warnings;
use Cwd qw(cwd);
use Getopt::Long qw(:config auto_help auto_version);
use LWP::UserAgent;
use Pod::Usage qw(pod2usage);
use XML::Tidy;
use Data::Dumper;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

# config
my $xml_tidy_indent_str = ' ' x 4;

# options
my $verbose = 0;
my @debug = ();
GetOptions(
    'verbose' => \$verbose,
    'debug:s' => \@debug,
) || pod2usage(-verbose => 0);
my $run_id_file = shift(@ARGV) or pod2usage(
    -message => 'Run ID file is required parameter',
    -verbose => 0,
);
my $ua = LWP::UserAgent->new();
open(my $in_fh, '<', $run_id_file) or die "ERROR: couldn't open $run_id_file: $!";
while (my $run_id = <$in_fh>) {
    $run_id =~ s/\s+//g;
    my $response = $ua->get(
        "http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=xml&term=$run_id"
    );
    if (!$response->is_success) {
        print "ERROR: failed to get SRA $run_id experiment package XML: ", $response->status_line, "\n";
        next;
    }
    my $xml_tidy_obj = XML::Tidy->new('xml' => $response->decoded_content);
    $xml_tidy_obj->tidy($xml_tidy_indent_str);
    $xml_tidy_obj->write(cwd() . "/${run_id}.xml");
}
close($in_fh);

__END__

=head1 NAME 

get_sra_xml.pl - SRA-XML Downloader

=head1 SYNOPSIS

 get_sra_xml.pl [options] <run id file>
 
 Parameters:
    <run id file>       File with list of SRA run IDs
 
 Options:
    --verbose           Be verbose
    --help              Display usage message and exit
    --version           Display program version and exit

=cut
