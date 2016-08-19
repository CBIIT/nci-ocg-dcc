#!/usr/bin/env perl

use strict;
use warnings;
use sigtrap qw(handler sig_handler normal-signals error-signals ALRM);
use Cwd qw(cwd);
use File::Basename qw(basename);
use File::Path qw(mkpath);
use Getopt::Long qw(:config auto_help auto_version);
use List::Util qw(min);
use Parallel::Forker;
use Pod::Usage qw(pod2usage);
use Sort::Key qw(nkeysort);
use Unix::Processors;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

sub sig_handler {
    die "$0 program exited gracefully [", scalar localtime, "]\n";
}
our $VERSION = '0.1';
# unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

# defaults
my $l2_data_matrix_file;
my $array_annot_file;
my $num_parallel_procs = 0;
my $output_dir = cwd();
my $sample_data_col_types_csv_str = 'AVG_Beta';
my $add_output_sample_id_prefix = '';
my $debug = 0;
GetOptions(
    'l2-data-matrix-file=s'         => \$l2_data_matrix_file,
    'array-annot-file=s'            => \$array_annot_file,
    'parallel=i'                    => \$num_parallel_procs,
    'output-dir=s'                  => \$output_dir,
    'sample-data-col-types=s'       => \$sample_data_col_types_csv_str,
    'add-output-sample-id-prefix=s' => \$add_output_sample_id_prefix,
    'debug'                         => \$debug,
) || pod2usage(-verbose => 0);
pod2usage(-message => 'Missing required parameter --l2-data-matrix-file', -verbose => 0) unless defined $l2_data_matrix_file;
pod2usage(-message => 'L2 data matrix file not valid', -verbose => 0) unless -f $l2_data_matrix_file;
#pod2usage(-message => 'Missing required parameter --array-annot-file', -verbose => 0) unless defined $array_annot_file;
pod2usage(-message => 'Array annotation file not valid', -verbose => 0) if defined $array_annot_file and !-f $array_annot_file;
pod2usage(-message => 'Invalid --sample-data-col-types csv string', -verbose => 0) unless $sample_data_col_types_csv_str;
my @sample_data_col_types = split /,/, $sample_data_col_types_csv_str;
mkpath($output_dir) unless -d $output_dir;
print "#", '-' x 100, "#\n",
      "# Illumina Infinium Methylation Arrays L2 to L3 Transformer [" . scalar localtime() . "]\n\n";
my $annotations_hashref;
if (defined $array_annot_file) {
    # parse GEO array annotation file and generate annotations data struct
    print "[Annotations]\nParsing ", basename($array_annot_file), "\n";
    my %annot_col_header_idx;
    my $annotations_processed = 0;
    open(my $array_annot_fh, '<', $array_annot_file) 
        or die "Could not open input array annotation file $array_annot_file: $!\n";
    while(<$array_annot_fh>) {
        s/^\s+//;
        s/\s+$//;
        # column header
        if (m/^!platform_table_begin/i) {
            my @col_headers = split /\t/, <$array_annot_fh>;
            for my $i (0 .. $#col_headers) {
                $col_headers[$i] =~ s/\s+//g;
                $col_headers[$i] = lc($col_headers[$i]);
                if ($col_headers[$i] =~ /^id$/) {
                    $annot_col_header_idx{id} = $i;
                }
                elsif ($col_headers[$i] =~ /^(entrez|)(_| |)gene(_| |)id$/) {
                    $annot_col_header_idx{gene_id} = $i;
                }
                elsif ($col_headers[$i] =~ /^((gene|)(_| |)symbol|ucsc_refgene_name)$/) {
                    $annot_col_header_idx{gene_symbol} = $i;
                }
                elsif ($col_headers[$i] =~ /^chr$/) {
                    $annot_col_header_idx{chromosome} = $i;
                }
                elsif ($col_headers[$i] =~ /^mapinfo$/) {
                    $annot_col_header_idx{position} = $i;
                }
                elsif ($col_headers[$i] =~ /^refseq(_id| id|)$/) {
                    $annot_col_header_idx{refseq_id} = $i;
                }
                elsif ($col_headers[$i] =~ /^(ucsc_refgene_accession|accession|gb_acc)$/) {
                    $annot_col_header_idx{accession} = $i;
                }
                elsif ($col_headers[$i] =~ /^gb(_| |)list$/) {
                    $annot_col_header_idx{accession_list} = $i;
                }         
                elsif ($col_headers[$i] =~ /^unigene(_| |)id$/) {
                    $annot_col_header_idx{unigene_id} = $i;
                }
                elsif ($col_headers[$i] =~ /^spot(_id| id|)$/) {
                    $annot_col_header_idx{spot_id} = $i;
                }
            }
        }
        # file header
        elsif (m/^(\^|#|!)/) {
            next;
        }
        # annotation table
        else {
            my @data_fields = split /\t/;
            s/\s+//g for @data_fields;
            my $unique_gene_symbols_str = '';
            if (defined $annot_col_header_idx{gene_symbol} and $data_fields[$annot_col_header_idx{gene_symbol}]) {
                $unique_gene_symbols_str = fix_gene_symbols_str($data_fields[$annot_col_header_idx{gene_symbol}]);
            }
            $annotations_hashref->{$data_fields[$annot_col_header_idx{id}]} = {
                gene_symbol_str => $unique_gene_symbols_str,
                chromosome => $data_fields[$annot_col_header_idx{chromosome}],
                position => $data_fields[$annot_col_header_idx{position}],
            };
            $annotations_processed++;
        }
    }
    close($array_annot_fh);
    print "$annotations_processed probe annotations loaded\n\n";
}
print STDERR "\%annotations_hashref:\n", Dumper(\%annotations_hashref) if $debug;
# parse data matrix header
print "[L2 --> L3]\nParsing ", basename($l2_data_matrix_file), "\n";
open(my $l2_data_matrix_fh, '<', $l2_data_matrix_file) 
    or die "Could not open L2 data matrix file $l2_data_matrix_file: $!\n";
my (%data_col_header_idx, $sample_col_header_data_hashref);
while (<$l2_data_matrix_fh>) {
    #s/^\s+//;
    #s/\s+$//;
    # data column header
    if (m/^\s*(TargetID|Index)/i) {
        my @data_col_headers = split /\t/;
        %data_col_header_idx = map { uc($data_col_headers[$_]) => $_ } 0 .. $#data_col_headers;
        # process sample IDs and relevant column header indexes
        my $sample_num = 1;
        for my $i (0 .. $#data_col_headers) {
            for my $sample_data_col_type (@sample_data_col_types) {
                if ((my $sample_id) = $data_col_headers[$i] =~ /^(.+?)\.$sample_data_col_type$/i) {
                    if (not exists $sample_col_header_data_hashref->{$sample_id}) {
                        $sample_col_header_data_hashref->{$sample_id}->{order} = $sample_num;
                        $sample_num++;
                    }
                    $sample_col_header_data_hashref->{$sample_id}->{idx}->{$sample_data_col_type} = $i;
                }
            }
        }
        last;
    }
}
close($l2_data_matrix_fh);
if ($debug) {
    print STDERR "\%data_col_header_idx:\n", Dumper(\%data_col_header_idx);
    print STDERR "\$sample_col_header_data_hashref:\n", Dumper($sample_col_header_data_hashref);
}
die "Did not properly parse and process L2 data column header, no column header info captured\n" 
    unless defined $sample_col_header_data_hashref;
# set gene symbols L2 data file column header index (different for 27K and 450K)
my $gene_symbols_data_col_header_idx = $data_col_header_idx{UCSC_REFGENE_NAME} || $data_col_header_idx{SYMBOL};
# parse entire L2 data matrix for each sample 
# (otherwise have to store all sample relevant data in memory which would require a lot of RAM)
# parallel
if ($num_parallel_procs > 1) {
    my $fork_manager = Parallel::Forker->new(
        use_sig_child => 1, 
        max_proc => min($num_parallel_procs, Unix::Processors->new()->max_physical),
    );
    $SIG{CHLD} = sub { 
        Parallel::Forker::sig_child($fork_manager);
    };
    $SIG{TERM} = sub { 
        $fork_manager->kill_tree_all('TERM') if $fork_manager and $fork_manager->in_parent; 
        die "Exiting child process\n" 
    };
    for my $sample_id (nkeysort { $sample_col_header_data_hashref->{$_}->{order} } keys %{$sample_col_header_data_hashref}) {
        $fork_manager->schedule(run_on_start => sub {
            parse_l2_and_write_l3($sample_id);
        })->ready();
    }
    # wait for all child processes to finish
    $fork_manager->wait_all();
}
# serial
else {
    for my $sample_id (nkeysort { $sample_col_header_data_hashref->{$_}->{order} } keys %{$sample_col_header_data_hashref}) {
        parse_l2_and_write_l3($sample_id);
    }
}
print "\nIllumina Infinium Methylation Arrays L2 to L3 Transformer complete [", scalar localtime, "]\n\n";
exit;

sub parse_l2_and_write_l3 {
    my ($sample_id) = @_;
    print "Processing ", ($add_output_sample_id_prefix ? "${add_output_sample_id_prefix}-" : ''), "${sample_id} L2 data", $num_parallel_procs > 1 ? " [PID $$]\n" : "\n";
    # get rid of certain shell metacharacters in sample IDs
    my $l3_out_file_name;
    ($l3_out_file_name = ($add_output_sample_id_prefix ? "${add_output_sample_id_prefix}-" : '') . "${sample_id}_L3.txt") =~ s/[\$\/\(\)\[\]\s]/_/g;
    my (@sample_data, $read_col_header, $in_control_section);
    open(my $l2_data_matrix_fh, '<', $l2_data_matrix_file) 
        or die "Could not open L2 data matrix file $l2_data_matrix_file: $!\n";
    while (<$l2_data_matrix_fh>) {
        #s/^\s+//;
        #s/\s+$//;
        # column header
        if (m/^\s*(TargetID|Index)/i) {
            $read_col_header++;
        }
        # control section
        elsif (m/^\s*\[Control/i) {
            $in_control_section++;
        }
        # main data table
        elsif ($read_col_header and !m/^\s*\[/ and not $in_control_section) {
            my @data_fields = split /\t/;
            if (defined $annotations_hashref and 
                not exists $annotations_hashref->{$data_fields[$data_col_header_idx{TARGETID}]} and 
                not $in_control_section
            ) {
                die "$data_fields[$data_col_header_idx{TARGETID}] not found in annotations file\n";
            }
            push @sample_data, [
                $sample_id,
                $data_fields[$data_col_header_idx{TARGETID}],
                @data_fields[@{$sample_col_header_data_hashref->{$sample_id}->{idx}}{@sample_data_col_types}],
                (
                    # use L2 data file existing annotations if no GEO annotations loaded or 
                    # if in control section where there are no GEO annotations
                    (not defined $annotations_hashref or $in_control_section)
                        ? (
                            fix_gene_symbols_str($data_fields[$gene_symbols_data_col_header_idx]),
                            $data_fields[$data_col_header_idx{CHR}],
                            $data_fields[$data_col_header_idx{MAPINFO}],
                        )
                    # else use GEO annotations
                        : (
                            # fix stupid bug in GEO 27K annotations file where they have integers as some gene symbols,
                            # fall back to L2 existing gene symbol(s) if this is the case
                            (
                                $annotations_hashref->{$data_fields[$data_col_header_idx{TARGETID}]}->{gene_symbol_str} !~ /^\d+$/
                                    ? $annotations_hashref->{$data_fields[$data_col_header_idx{TARGETID}]}->{gene_symbol_str}
                                    : fix_gene_symbols_str($data_fields[$gene_symbols_data_col_header_idx])
                            ),
                            $annotations_hashref->{$data_fields[$data_col_header_idx{TARGETID}]}->{chromosome}, 
                            $annotations_hashref->{$data_fields[$data_col_header_idx{TARGETID}]}->{position},
                        )
                ),
            ];
        }
    }
    die "No L2 sample data extracted, possible problem with L2 data matrix file\n" unless @sample_data;
    # sort output by gene symbols string (with empty gene symbols last) first then original L2 target ID order and write L3 file
    print "Writing    $l3_out_file_name", $num_parallel_procs > 1 ? " [PID $$]\n" : "\n";
    open(my $l3_out_fh, '>', "$output_dir/$l3_out_file_name")
        or die "Could not create L3 output file $output_dir/$l3_out_file_name: $!\n";
    print $l3_out_fh "Sample ID\tProbe Name", (map { "\t$_" } @sample_data_col_types), "\tGene Symbols\tChromosome\tPosition\n";
    my $gene_symbol_str_idx = $#{$sample_data[0]} - 2;
    for my $sample_data_row_arrayref (
        # sort naturally by gene symbol but with empty fields last
        sort { 
            (!length($a->[$gene_symbol_str_idx]) xor !length($b->[$gene_symbol_str_idx]))
                ? length($b->[$gene_symbol_str_idx]) - length($a->[$gene_symbol_str_idx])
                : $a->[$gene_symbol_str_idx] cmp $b->[$gene_symbol_str_idx]
        } @sample_data
    ) {
        print $l3_out_fh join("\t", @{$sample_data_row_arrayref}), "\n";
    }
    close($l3_out_fh);
    close($l2_data_matrix_fh);
    #print "Finished   ", ($add_output_sample_id_prefix ? "${add_output_sample_id_prefix}-" : ''), "${sample_id} L2 data [PID $$]\n" if $num_parallel_procs > 1;
}

sub fix_gene_symbols_str {
    my ($gene_symbols_str) = @_;
    my @gene_symbols = split /;/, $gene_symbols_str;
    my %unique_gene_symbols;
    for my $i (0 .. $#gene_symbols) {
        if (not exists $unique_gene_symbols{$gene_symbols[$i]}) {
            $unique_gene_symbols{$gene_symbols[$i]} = $i;
        }
    }
    return join(';', nkeysort { $unique_gene_symbols{$_} } keys %unique_gene_symbols);
}

__END__

=head1 NAME 

transform_illumina_infinium_meth_L2to3.pl - Illumina Infinium Methylation Arrays L2 to L3 Transformer

=head1 SYNOPSIS

 transform_illumina_infinium_meth_L2to3.pl [options]

 Options:
    --l2-data-matrix-file=/path/to/file     Path to input L2 methylation data matrix file (required)
    --array-annot-file=/path/to/file        Path to array GEO annotation file (optional: if not provided will use L2 data matrix file annotations)
    --parallel=n                            Number of parallel processes to use for parsing and generating L3 output files (default: no parallel processing)
    --output-dir=/path/to/dir               Path to L3 output files directory (default: current working directory)
    --sample-data-col-types=Col1,Col2       CSV string of L2 sample data columns to transform to L3 file (default: AVG_Beta)
    --help                                  Display usage message and exit
    --version                               Display program version and exit

=cut
