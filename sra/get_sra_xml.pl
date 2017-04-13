#!/usr/bin/env perl

use strict;
use warnings;
use Cwd qw(cwd);
use File::Path 2.11 qw( make_path );
use Getopt::Long qw( :config auto_help auto_version );
use LWP::UserAgent;
use Pod::Usage qw( pod2usage );
use Term::ANSIColor;
use XML::Simple qw( :strict );
use XML::Tidy;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

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
my $output_dir = @ARGV ? shift(@ARGV) : cwd();
if (!-d $output_dir) {
    make_path($output_dir, { chmod => 0770 })
        or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
               ": could not create $output_dir: $!";
}
my $ua = LWP::UserAgent->new();
my $num_fetched = 0;
open(my $ids_fh, '<', $run_id_file)
    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
           ": couldn't open $run_id_file: $!";
while (my $run_id = <$ids_fh>) {
    $run_id =~ s/\s+//g;
    my $exp_pkg_set_xml;
    my $response = $ua->get(
        "http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=xml&term=$run_id"
    );
    if ($response->is_success) {
        $exp_pkg_set_xml = XMLin(
            $response->decoded_content,
            KeyAttr => {
                #'SAMPLE_ATTRIBUTE' => 'TAG',
                'Table' => 'name',
            },
            ForceArray => [
                'EXPERIMENT_ATTRIBUTE',
                #'SAMPLE_ATTRIBUTE',
                'RUN',
                'RUN_ATTRIBUTE',
                'Table',
            ],
            GroupTags => {
                'STUDY_ATTRIBUTES' => 'STUDY_ATTRIBUTE',
                'SUBMISSION_ATTRIBUTES' => 'SUBMISSION_ATTRIBUTE',
                'EXPERIMENT_ATTRIBUTES' => 'EXPERIMENT_ATTRIBUTE',
                'SAMPLE_ATTRIBUTES' => 'SAMPLE_ATTRIBUTE',
                'RUN_SET' => 'RUN',
                'RUN_ATTRIBUTES' => 'RUN_ATTRIBUTE',
                'RELATED_STUDIES' => 'RELATED_STUDY',
                'QualityCount' => 'Quality',
                'AlignInfo' => 'Alignment',
                'Databases' => 'Database',
            },
            #SuppressEmpty => 1,
            #StrictMode => 0,
        );
    }
    else {
        warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
             ": failed to get $run_id experiment package XML: ",
             $response->status_line, "\n";
        next;
    }
    if ($exp_pkg_set_xml->{Error}) {
        warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
             ": failed to get $run_id experiment package XML: $exp_pkg_set_xml->{Error}\n";
        next;
    }
    {
        local $SIG{__WARN__} = sub {
            my ($message) = @_;
            warn +(-t STDERR ? colored('WARN', 'red') : 'WARN'),
                 ": XML::Tidy processing $run_id experiment package XML: ",
                 $message, "\n";
        };
        my $xml_tidy_obj = XML::Tidy->new('xml' => $response->decoded_content);
        $xml_tidy_obj->tidy($xml_tidy_indent_str);
        $xml_tidy_obj->write("$output_dir/${run_id}.xml");
    }
    $num_fetched++;
    print "\r$num_fetched xmls fetched" if -t STDOUT;
}
close($ids_fh);
print "$num_fetched xmls fetched" unless -t STDOUT and $num_fetched;
print "\n";

__END__

=head1 NAME 

get_sra_xml.pl - SRA-XML Downloader

=head1 SYNOPSIS

 get_sra_xml.pl [options] <run id file> <output dir>
 
 Parameters:
    <run id file>       File with list of SRA run IDs (required)
    <output dir>        Output directory path (optional, default $PWD)
 
 Options:
    --verbose           Be verbose
    --help              Display usage message and exit
    --version           Display program version and exit

=cut
