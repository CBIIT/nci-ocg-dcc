#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long qw(:config auto_help auto_version);
use List::Util qw(max);
use LWP::UserAgent;
use Math::Round qw(round);
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natsort);
use Text::CSV;
use XML::Simple qw(:strict);
use Data::Dumper;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

# config
my %dbgap_study_id2name = (
    phs000463 => 'TARGET ALLP1',
    phs000464 => 'TARGET ALLP2',
    phs000465 => 'TARGET AML',
    phs000515 => 'TARGET AML-IF',
    phs000466 => 'TARGET CCSK',
    phs000467 => 'TARGET NBL',
    phs000468 => 'TARGET OS',
    phs000469 => 'TARGET PPTP',
    phs000470 => 'TARGET RT',
    phs000471 => 'TARGET WT',
    phs000527 => 'CGCI BLGSP',
    phs000528 => 'CGCI HTMCP-CC',
    phs000529 => 'CGCI HTMCP-DLBCL',
    phs000530 => 'CGCI HTMCP-LC',
    phs000531 => 'CGCI MB',
    phs000532 => 'CGCI NHL',
);

my $list_data_types = 0;
my $distribute = 0;
my $clean = 0;
my $debug = 0;
GetOptions(
    'list-data-types' => \$list_data_types,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
my $dbgap_study_id = shift @ARGV;
die "ERROR: dbGaP study ID $dbgap_study_id not supported\n" 
    if defined $dbgap_study_id and !defined $dbgap_study_id2name{$dbgap_study_id};
my $data_type = shift @ARGV;
my $ua = LWP::UserAgent->new();
my $total_data_size = 0;
my @dbgap_study_ids = defined $dbgap_study_id ? ($dbgap_study_id) : natsort keys %dbgap_study_id2name;
my $study_ids_max_length = max(map(length, keys %dbgap_study_id2name));
my $study_names_max_length = max(map(length, values %dbgap_study_id2name));
my $data_types_max_length = length('Targeted-Capture'); # currently longest assay type name
for my $dbgap_study_id (@dbgap_study_ids) {
    my %data_type_run_ids;
    my $response = $ua->get(
        #"http://trace.ncbi.nlm.nih.gov/Traces/study/?acc=$dbgap_study_id&get=csv"
        #"http://trace.ncbi.nlm.nih.gov/Traces/study/be/nph-run_selector.cgi?&acc=$dbgap_study_id&get=csv"
        "http://trace.ncbi.nlm.nih.gov/Traces/sra/?sp=runinfo&acc=$dbgap_study_id"
    );
    if ($response->is_success) {
        if (my $csv = Text::CSV->new({
            binary => 1,
            #sep_char => "\t",
        })) {
            if (open(my $run_table_csv_fh, '<:encoding(utf8)', \$response->decoded_content)) {
                # column header
                my $col_header_row_arrayref = $csv->getline($run_table_csv_fh);
                my %col_header_idxs = map { $col_header_row_arrayref->[$_] => $_ } 0 .. $#{$col_header_row_arrayref};
                while (my $table_row_arrayref = $csv->getline($run_table_csv_fh)) {
                    next if defined $data_type and uc($data_type) ne uc($table_row_arrayref->[$col_header_idxs{'LibraryStrategy'}]);
                    push @{$data_type_run_ids{$table_row_arrayref->[$col_header_idxs{'LibraryStrategy'}]}}, $table_row_arrayref->[$col_header_idxs{'Run'}];
                }
                close($run_table_csv_fh);
            }
            else {
                print "ERROR: could not open SRA $dbgap_study_id RunSelector CSV table in-memory filehandle: $!\n";
                next;
            }
        }
        else {
            print "ERROR: cannot create Text::CSV object: " . Text::CSV->error_diag(), "\n";
            next;
        }
    }
    else {
        print "ERROR: failed to download SRA $dbgap_study_id RunSelector CSV table: ", $response->status_line, "\n";
        next;
    }
    if ($list_data_types) {
        print "Data types:\n", join("\n", natsort keys %data_type_run_ids), "\n";
        next;
    }
    print STDERR "\%data_type_run_ids:\n", Dumper(\%data_type_run_ids) if $debug;
    my $study_total_data_size = 0;
    for my $data_type (natsort keys %data_type_run_ids) {
        my @run_ids = natsort @{$data_type_run_ids{$data_type}};
        print sprintf("%-${study_names_max_length}s", "$dbgap_study_id2name{$dbgap_study_id}"),
              " ($dbgap_study_id)  ",
              sprintf("%-${data_types_max_length}s", $data_type);
        my $run_num = 1;
        my $output_str = '';
        my $data_type_total_data_size = 0;
        # get SRA experiment package XML
        for my $run_id (@run_ids) {
            my $response = $ua->get(
                "http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=xml&term=$run_id"
            );
            if ($response->is_success) {
                my $exp_pkg_set_xml = XMLin(
                    $response->decoded_content,
                    KeyAttr => {
                        #'SAMPLE_ATTRIBUTE' => 'TAG',
                        'Table' => 'name',
                    },
                    ForceArray => [
                        #'SAMPLE_ATTRIBUTE',
                        'Table',
                    ],
                    GroupTags => {
                        'STUDY_ATTRIBUTES' => 'STUDY_ATTRIBUTE',
                        'SUBMISSION_ATTRIBUTES' => 'SUBMISSION_ATTRIBUTE',
                        'EXPERIMENT_ATTRIBUTES' => 'EXPERIMENT_ATTRIBUTE',
                        'SAMPLE_ATTRIBUTES' => 'SAMPLE_ATTRIBUTE',
                        'RUN_ATTRIBUTES' => 'RUN_ATTRIBUTE',
                        'RELATED_STUDIES' => 'RELATED_STUDY',
                        'QualityCount' => 'Quality',
                        'AlignInfo' => 'Alignment',
                        'Databases' => 'Database',
                    },
                    #SuppressEmpty => 1,
                    #StrictMode => 0,
                );
                if ($exp_pkg_set_xml->{Error}) {
                    print "\nERROR: failed to get SRA $run_id experiment package XML: $exp_pkg_set_xml->{Error}\n";
                    next;
                }
                # only one experiment package in each set since querying by run ID so to save some typing later
                my $exp_pkg_xml = $exp_pkg_set_xml->{EXPERIMENT_PACKAGE};
                # fix $exp_pkg_xml->{RUN_SET}->{RUN} data struct for multiple runs by selecting the current RUN
                if (ref($exp_pkg_xml->{RUN_SET}->{RUN}) eq 'ARRAY') {
                    for my $run_hashref (@{$exp_pkg_xml->{RUN_SET}->{RUN}}) {
                        if ($run_hashref->{accession} eq $run_id) {
                            $exp_pkg_xml->{RUN_SET}->{RUN} = $run_hashref;
                            last;
                        }
                    }
                }
                print STDERR "\n\$exp_pkg_xml:\n", Dumper($exp_pkg_xml) if $debug;
                if (defined $exp_pkg_xml->{RUN_SET}->{RUN}->{size}) {
                    $data_type_total_data_size += $exp_pkg_xml->{RUN_SET}->{RUN}->{size};
                    print STDERR $exp_pkg_xml->{RUN_SET}->{RUN}->{size}, " bytes\n" if $debug;
                }
                else {
                    print "ERROR: failed to get SRA $run_id data size\n";
                }
            }
            else {
                print "ERROR: failed to get SRA $run_id experiment package XML: ", $response->status_line, "\n";
            }
            print "\b" x length($output_str);
            $output_str = ' (' . sprintf("%4s", $run_num) . ' runs)' . sprintf("%7s", round($data_type_total_data_size/(1024*1024*1024))) . ' GB';
            print $output_str;
            $run_num++;
        }
        print "\n";
        $study_total_data_size += $data_type_total_data_size;
    }
    $total_data_size += $study_total_data_size;
}
my $line_length = $study_names_max_length + $study_ids_max_length + $data_types_max_length + 28;
print '-' x $line_length, "\nTOTAL",
      sprintf('%' . ($line_length - length('TOTAL')) . 's', round($total_data_size/(1024*1024*1024*1024)) . ' TB'),
      "\n\n";
exit;

__END__

=head1 NAME 

calc_sra_data_sizes.pl - OCG SRA Data Size Calculator

=head1 SYNOPSIS

 calc_sra_data_sizes.pl [options] <dbGaP Study ID> <data type>
 
 Options:
    --list-data-types       Display data types for dbGaP study and exit
    --help                  Display usage message and exit
    --version               Display program version and exit

=cut
