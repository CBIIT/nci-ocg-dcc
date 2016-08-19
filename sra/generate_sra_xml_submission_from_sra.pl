#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib/perl5";
use Config::Tiny;
use File::Basename qw(dirname fileparse);
use File::Path 2.11 qw(make_path remove_tree);
use Getopt::Long qw(:config auto_help auto_version);
use List::MoreUtils qw(any firstidx uniq notall none);
use LWP::UserAgent;
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natsort natkeysort);
use Storable qw(lock_nstore lock_retrieve);
use Text::CSV;
use Text::Template;
use XML::Simple::SRA_XML qw(:strict);
use XML::Tidy;
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
my $BARCODE_REGEXP = qr/${CASE_REGEXP}-\d{2}(?:\.\d+)?[A-Z]-\d{2}[A-Z]/;

# config
my $cache_dir = "$FindBin::Bin/cache";
my %sra_xml_schemas = (
    exp => 'http://www.ncbi.nlm.nih.gov/viewvc/v1/trunk/sra/doc/SRA_1-5/SRA.experiment.xsd?view=co',
    run => 'http://www.ncbi.nlm.nih.gov/viewvc/v1/trunk/sra/doc/SRA_1-5/SRA.run.xsd?view=co',
    sub => 'http://www.ncbi.nlm.nih.gov/viewvc/v1/trunk/sra/doc/SRA_1-5/SRA.submission.xsd?view=co',
);
my $xml_indent_str = ' ' x 4;
my %sra_data_types = map { $_ => 1 } qw(
    Bisulfite-seq
    ChIP-seq
    miRNA-seq
    RNA-seq
    WGS
    WXS
    Targeted-Capture
);
my %program_project_conf = (
    'TARGET' => {
        'ALL' => {
            'dbGaP_study_ids' => ['phs000464'],
        },
        'AML' => {
            'dbGaP_study_ids' => ['phs000465', 'phs000515'],
        },
        'CCSK' => {
            'dbGaP_study_ids' => ['phs000466'],
        },
        'NBL' => {
            'dbGaP_study_ids' => ['phs000467'],
        },
        'OS' => {
            'dbGaP_study_ids' => ['phs000468'],
        },
        'MDLS-PPTP' => {
            'dbGaP_study_ids' => ['phs000469'],
        },
        'RT' => {
            'dbGaP_study_ids' => ['phs000469', 'phs000470'],
        },
        'WT' => {
            'dbGaP_study_ids' => ['phs000471'],
        },
    },
    CGCI => {
        'BLGSP' => {
            'dbGaP_study_ids' => ['phs000527'],
        },
        'HTMCP-CC' => {
            'dbGaP_study_ids' => ['phs000528'],
        },
        'HTMCP-DLBCL' => {
            'dbGaP_study_ids' => ['phs000529'],
        },
        'HTMCP-LC' => {
            'dbGaP_study_ids' => ['phs000530'],
        },
        'MB' => {
            'dbGaP_study_ids' => ['phs000531'],
        },
        'NHL' => {
            'dbGaP_study_ids' => ['phs000532'],
        },
    },
);
my $default_manifest_file_name = 'MANIFEST.txt';
my %debug_types = map { $_ => 1 } qw(
    all
    params
    conf
    run_info
    xml
);
# options
my $use_cached_run_info = 0;
my $use_cached_xml = 0;
my %filter = ();
my $verbose = 0;
my @debug = ();
GetOptions(
    'use-cached-run-info' => \$use_cached_run_info,
    'use-cached-xml' => \$use_cached_xml,
    'filter=s' => \%filter,
    'verbose' => \$verbose,
    'debug:s' => \@debug,
) || pod2usage(-verbose => 0);
my %debug = map { $_ => 1 } split(',', join(',', map { lc($_) || 'all' } @debug));
for my $debug_type (natsort keys %debug) {
    if (!$debug_types{$debug_type}) {
        pod2usage(-message => "Invalid debug type: $debug_type", -verbose => 0);
    }
}
%filter = map { lc($_) => uc($filter{$_}) } keys %filter;
if ($debug{all} or $debug{params}) {
    print STDERR "\%filter:\n", Dumper(\%filter);
}
my $config = Config::Tiny->read("$FindBin::Bin/generate_sra_xml_submission.conf");
die "ERROR: couldn't load config: ", Config::Tiny->errstr unless $config;
print STDERR "\$config:\n", Dumper($config) if $debug{all} or $debug{conf};
my $submission_label = shift(@ARGV) or pod2usage(-message => 'Required parameter: submission label', -verbose => 0);
pod2usage(-message => "No configuration section defined for $submission_label", -verbose => 0) unless exists $config->{$submission_label};
my ($program_name, $project_name, $data_type) = split('_', $submission_label);
$program_name = uc($program_name);
pod2usage(-message => "Invalid program name $program_name", -verbose => 0) unless exists $program_project_conf{$program_name};
$project_name = uc($project_name);
pod2usage(-message => "Invalid project name $project_name", -verbose => 0) unless exists $program_project_conf{$program_name}{$project_name};
$data_type =~ s/^mRNA/RNA/i;
($data_type) = grep { m/^$data_type$/i } keys %sra_data_types;
pod2usage(-message => "Invalid data type $data_type", -verbose => 0) unless $data_type;
my $debug_xml_dir;
if ($debug{all} or $debug{xml}) {
    $debug_xml_dir = "$FindBin::Bin/$submission_label/sra_xml";
    if (!-d $debug_xml_dir) {
        print "Creating $debug_xml_dir\n";
        make_path($debug_xml_dir, { chmod => 0700 }) 
            or die "ERROR: could not create $debug_xml_dir: $!\n";
    }
    elsif (!-z $debug_xml_dir) {
        print "Cleaning $debug_xml_dir\n";
        remove_tree($debug_xml_dir, { keep_root => 1 })
            or die "ERROR: could not clean $debug_xml_dir: $!\n";
    }
}
print "[$submission_label]\n";
my %metadata_by_barcode;
# read data file info
print "Reading data file info $config->{$submission_label}->{data_dir}\n" if $verbose;
opendir(my $dh, $config->{$submission_label}->{data_dir}) or die "$!";
my @data_file_names = natsort grep { -f "$config->{$submission_label}->{data_dir}/$_" and $_ ne $default_manifest_file_name } readdir $dh;
closedir($dh);
my $num_data_files_used = 0;
for my $file_name (@data_file_names) {
    if (my ($barcode) = $file_name =~ /($BARCODE_REGEXP)/i) {
        $barcode = uc($barcode);
        my ($file_type) = $file_name =~ /\.(?:(bam|fastq)(?:\.gz)?)$/i;
        $file_type = lc($file_type);
        push @{$metadata_by_barcode{$barcode}{'files'}}, {
            name => $file_name,
            type => $file_type,
        };
        $num_data_files_used++;
    }
    else {
        die "ERROR: could not obtain barcode from $file_name";
    }
}
print "$num_data_files_used files used\n" if $verbose;
# read manifest file
my $manifest_file = "$config->{$submission_label}->{data_dir}/$default_manifest_file_name";
print "Loading checksums $manifest_file\n" if $verbose;
open(my $checksums_fh, '<', $manifest_file) or die "ERROR: could not open $manifest_file: $!";
my $num_checksums_loaded = 0;
while (<$checksums_fh>) {
    next if m/^\s*$/;
    s/^\s+//;
    s/\s+$//;
    my ($checksum, $file_name) = split / (?:\*| )/, $_, 2;
    if (my ($barcode) = $file_name =~ /($BARCODE_REGEXP)/i) {
        $barcode = uc($barcode);
        if (exists $metadata_by_barcode{$barcode}) {
            my $file_idx = firstidx { $_->{'name'} eq $file_name } @{$metadata_by_barcode{$barcode}{'files'}};
            if ($file_idx >= 0) {
                if (!exists $metadata_by_barcode{$barcode}{files}[$file_idx]{'checksum'}) {
                    $metadata_by_barcode{$barcode}{'files'}[$file_idx]{'checksum'} = $checksum;
                    $metadata_by_barcode{$barcode}{'files'}[$file_idx]{'checksum_method'} = length($checksum) == 32 ? 'MD5' : 'SHA256';
                    $num_checksums_loaded++;
                }
                else {
                    die "ERROR: $file_name checksum already loaded\n";
                }
            }
            else {
                die "ERROR: $file_name not loaded when reading data files\n";
            }
        }
    }
    else {
        die "ERROR: could not obtain barcode from $file_name\n";
    }
}
close($checksums_fh);
print "$num_checksums_loaded checksums loaded\n" if $verbose;
my $ua = LWP::UserAgent->new();
# get dbGaP study SRA run info
my $run_info_by_data_type_hashref;
my @dbgap_study_ids = natsort @{$program_project_conf{$program_name}{$project_name}{'dbGaP_study_ids'}};
for my $dbgap_study_id (@dbgap_study_ids) {
    print "Getting SRA run info for $dbgap_study_id\n";
    my $run_info_storable_file = "$cache_dir/${dbgap_study_id}_run_info_by_data_type_hashref.pls";
    if (!-f $run_info_storable_file or !$use_cached_run_info) {
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
                    my $study_run_info_by_data_type_hashref;
                    my $col_header_row_arrayref = $csv->getline($run_table_csv_fh);
                    my %col_header_idxs = map { $col_header_row_arrayref->[$_] => $_ } 0 .. $#{$col_header_row_arrayref};
                    while (my $table_row_arrayref = $csv->getline($run_table_csv_fh)) {
                        my $data_type = $table_row_arrayref->[$col_header_idxs{'LibraryStrategy'}];
                        $data_type =~ s/-Seq$/-seq/i;
                        my $run_id = $table_row_arrayref->[$col_header_idxs{'Run'}];
                        my $seq_center_name = 
                            uc($table_row_arrayref->[$col_header_idxs{'CenterName'}]) eq 'COMPLETEGENOMICS' ? 'CGI'  :
                            uc($table_row_arrayref->[$col_header_idxs{'CenterName'}]) eq 'BCCAGSC'          ? 'BCCA' :
                            uc($table_row_arrayref->[$col_header_idxs{'CenterName'}]);
                        my $platform = 
                            uc($table_row_arrayref->[$col_header_idxs{'Platform'}]) eq 'COMPLETE_GENOMICS' ? 'CGI' :
                            uc($table_row_arrayref->[$col_header_idxs{'Platform'}]);
                        $study_run_info_by_data_type_hashref->{$data_type}->{run_ids}->{$run_id}++;
                        $study_run_info_by_data_type_hashref->{$data_type}->{center_platforms}->{$seq_center_name}->{$platform}++;
                    }
                    close($run_table_csv_fh);
                    print "Serializing run info $run_info_storable_file\n" if $verbose;
                    my $run_info_storable_dir = dirname($run_info_storable_file);
                    if (!-d $run_info_storable_dir) {
                        make_path($run_info_storable_dir, { chmod => 0700 }) 
                            or die "ERROR: could not create $run_info_storable_dir: $!\n";
                    }
                    lock_nstore($study_run_info_by_data_type_hashref, $run_info_storable_file)
                        or die "ERROR: could not serialize and store $run_info_storable_file: $!\n";
                    if (defined $run_info_by_data_type_hashref) {
                        $run_info_by_data_type_hashref = merge_run_info_hash(
                            $run_info_by_data_type_hashref, 
                            $study_run_info_by_data_type_hashref
                        );
                    }
                    else {
                        $run_info_by_data_type_hashref = $study_run_info_by_data_type_hashref;
                    }
                }
                else {
                    print "ERROR: could not open SRA $dbgap_study_id RunSelector CSV table in-memory filehandle: $!\n";
                    next;
                }
            }
            else {
                print "ERROR: cannot create Text::CSV object: ", Text::CSV->error_diag(), "\n";
                next;
            }
        }
        else {
            print "ERROR: failed to download SRA $dbgap_study_id RunSelector CSV table: ", $response->status_line, "\n";
            next;
        }
    }
    else {
        print "Loading cached run info $run_info_storable_file\n" if $verbose;
        my $study_run_info_by_data_type_hashref = lock_retrieve($run_info_storable_file)
            or die "ERROR: could not deserialize and retrieve $run_info_storable_file: $!\n";
        if (defined $run_info_by_data_type_hashref) {
            $run_info_by_data_type_hashref = merge_run_info_hash(
                $run_info_by_data_type_hashref, 
                $study_run_info_by_data_type_hashref
            );
        }
        else {
            $run_info_by_data_type_hashref = $study_run_info_by_data_type_hashref;
        }
    }
}
if ($debug{all} or $debug{run_info}) {
    print STDERR "\$run_info_by_data_type_hashref:\n", Dumper($run_info_by_data_type_hashref);
}
# get XMLs
my (@exp_xmls, @run_xmls);
my $xs = XML::Simple::SRA_XML->new();
my @run_ids = natsort keys %{$run_info_by_data_type_hashref->{$data_type}->{run_ids}};
print "--> $data_type (", scalar(@run_ids), " runs)\n",
      "Getting XMLs\n";
my $num_runs_processed = 0;
for my $run_id (@run_ids) {
    my $exp_pkg_set_xml_str;
    my $exp_pkg_set_xml_file = "$cache_dir/xml/${run_id}.xml";
    if (!-f $exp_pkg_set_xml_file or !$use_cached_xml) {
        my $response = $ua->get(
            "http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=xml&term=$run_id"
        );
        if ($response->is_success) {
            my $exp_pkg_set_xml_dir = dirname($exp_pkg_set_xml_file);
            if (!-d $exp_pkg_set_xml_dir) {
                make_path($exp_pkg_set_xml_dir, { chmod => 0700 }) 
                    or die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                           ": could not create $exp_pkg_set_xml_dir: $!";
            }
            $exp_pkg_set_xml_str = $response->decoded_content;
            open(my $xml_out_fh, '>', $exp_pkg_set_xml_file) or die "ERROR: could not create $exp_pkg_set_xml_file: $!";
            print $xml_out_fh $exp_pkg_set_xml_str;
            close($xml_out_fh);
        }
        else {
            print "ERROR: failed to get SRA $run_id experiment package XML: ", $response->status_line, "\n";
            next;
        }
    }
    else {
        local $/;
        open(my $xml_in_fh, '<', $exp_pkg_set_xml_file) or die "ERROR: could not open $exp_pkg_set_xml_file: $!";
        $exp_pkg_set_xml_str = <$xml_in_fh>;
        close($xml_in_fh);
    }
    my $exp_pkg_set_xml = $xs->XMLin(
        $exp_pkg_set_xml_str,
        ForceArray => 1,
        ForceContent => 1,
        KeyAttr => [],
    );
    if ($exp_pkg_set_xml->{Error}) {
        print "\nERROR: failed to get SRA $run_id experiment package XML: $exp_pkg_set_xml->{Error}\n";
        next;
    }
    # only one experiment package in each set since querying by run ID so to save some typing later
    my $exp_pkg_xml = $exp_pkg_set_xml->{EXPERIMENT_PACKAGE};
    # if multiple runs remove other runs
    if (scalar(@{$exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}}) > 1) {
        for my $run_hashref (@{$exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}}) {
            if ($run_hashref->{accession} eq $run_id) {
                $exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN} = [ $run_hashref ];
                last;
            }
        }
    }
    if ($debug{all} or $debug{xml}) {
        print STDERR "\n\$exp_pkg_xml:\n", Dumper($exp_pkg_xml);
    }
    if (%filter) {
        if ($filter{center}) {
            my $seq_center_name = 
                defined $exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}->[0]->{run_center}
                    ? uc($exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}->[0]->{run_center}) eq 'COMPLETEGENOMICS' ? 'CGI'  :
                      uc($exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}->[0]->{run_center}) eq 'BCCAGSC'          ? 'BCCA' :
                      uc($exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}->[0]->{run_center}) :
                defined $exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}->[0]->{center_name}
                    ? uc($exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}->[0]->{center_name}) eq 'COMPLETEGENOMICS' ? 'CGI'  :
                      uc($exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}->[0]->{center_name}) eq 'BCCAGSC'          ? 'BCCA' :
                      uc($exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}->[0]->{center_name})
                    : uc($exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}->[0]->{center_name}) eq 'COMPLETEGENOMICS' ? 'CGI'  :
                      uc($exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}->[0]->{center_name}) eq 'BCCAGSC'          ? 'BCCA' :
                      uc($exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}->[0]->{center_name});
            next unless $filter{center} eq $seq_center_name;
        }
    }
    if ($debug{all} or $debug{xml}) {
        my $xml_tidy_obj = XML::Tidy->new('xml' => $exp_pkg_set_xml_str);
        $xml_tidy_obj->tidy($xml_indent_str);
        $xml_tidy_obj->write("$debug_xml_dir/${run_id}.xml");
    }
    my $exp_xml = $exp_pkg_xml->[0]->{EXPERIMENT}->[0];
    my $run_xml = $exp_pkg_xml->[0]->{RUN_SET}->[0]->{RUN}->[0];
    my $sub_xml = $exp_pkg_xml->[0]->{SUBMISSION}->[0];
    my $sample_xml = $exp_pkg_xml->[0]->{SAMPLE}->[0];
    my ($sample_barcode) = map { $_->{content} } grep { exists $_->{label} and $_->{label} eq 'submitted sample id' } @{$sample_xml->{IDENTIFIERS}->[0]->{EXTERNAL_ID}};
    # transform exp xml into submission format
    if (!exists $config->{$submission_label}->{no_exp}) {
        delete $exp_xml->{accession};
        delete $exp_xml->{IDENTIFIERS}->[0]->{PRIMARY_ID};
        $exp_xml->{broker_name} = 'NCI';
        $exp_xml->{DESIGN}->[0]->{DESIGN_DESCRIPTION}->[0]->{content} = $config->{$submission_label}->{design_description};
        $exp_xml->{DESIGN}->[0]->{DESIGN_DESCRIPTION}->[0]->{content} = $config->{$submission_label}->{library_contruction_protocol};
        delete @{$exp_xml}{qw( EXPERIMENT_ATTRIBUTES )};
        my $exp_xml_tidy_obj = XML::Tidy->new(
            'xml' => $xs->XMLout(
                $exp_xml,
                RootName => 'EXPERIMENT',
                KeyAttr => [],
            )
        );
        $exp_xml_tidy_obj->tidy($xml_indent_str);
        # remove dtd first line
        my $exp_xml_tidy_str = $exp_xml_tidy_obj->toString();
        $exp_xml_tidy_str =~ s/^.+\n//;
        # indent every line
        $exp_xml_tidy_str =~ s/^(.+)$/$xml_indent_str$1/gm;
        push @exp_xmls, {
            xml => $exp_xml_tidy_str,
            barcode => $sample_barcode,
        };
    }
    # skip run if no file data
    if (exists $metadata_by_barcode{$sample_barcode}) {
        # transform run xml into submission format
        for my $key (keys $run_xml) {
            if (!ref($run_xml->{$key})) {
                if ($key eq 'alias') {
                    if (scalar(@{$metadata_by_barcode{$sample_barcode}{files}}) > 1) {
                        $run_xml->{$key} = "${sample_barcode}.fastq";
                    }
                    else {
                        ($run_xml->{$key}) = map { $_->{name} } @{$metadata_by_barcode{$sample_barcode}{files}};
                    }
                }
                elsif ($key ne 'center_name' and $key ne 'broker_name') {
                    delete $run_xml->{$key};
                }
            }
        }
        $run_xml->{broker_name} = 'NCI';
        $run_xml->{run_center} = $config->{$submission_label}->{center_name};
        delete @{$run_xml}{qw( AlignInfo Bases Databases Pool QualityCount Statistics )};
        delete $run_xml->{IDENTIFIERS}->[0]->{PRIMARY_ID};
        delete $run_xml->{IDENTIFIERS}->[0]->{SECONDARY_ID};
        $run_xml->{IDENTIFIERS}->[0]->{SUBMITTER_ID}->[0]->{namespace} = $config->{$submission_label}->{center_name};
        $run_xml->{IDENTIFIERS}->[0]->{SUBMITTER_ID}->[0]->{content} = $run_xml->{alias};
        if (!exists $run_xml->{PLATFORM} and
             exists $exp_xml->{PLATFORM}) {
            $run_xml->{PLATFORM} = $exp_xml->{PLATFORM};
        }
        if (!exists $run_xml->{PROCESSING} and
             exists $exp_xml->{PROCESSING}) {
            $run_xml->{PROCESSING} = $exp_xml->{PROCESSING};
        }
        if (exists $run_xml->{PROCESSING}) {
            $run_xml->{PROCESSING}->[0]->{PIPELINE}->[0]->{PIPE_SECTION}->[0]->{section_name} = 'Base Calls';
            $run_xml->{PROCESSING}->[0]->{PIPELINE}->[0]->{PIPE_SECTION}->[1]->{section_name} = 'Quality Scores';
            if ($submission_label eq 'target_os_wgs_nci-meltzer_02') {
                push @{$run_xml->{PROCESSING}->[0]->{PIPELINE}->[0]->{PIPE_SECTION}}, {
                    'PREV_STEP_INDEX' => [
                        {
                            'content' => '2'
                        }
                    ],
                    'PROGRAM' => [
                        {
                            'content' => 'BWA-MEM'
                        }
                    ],
                    'STEP_INDEX' => [
                        {
                            'content' => '3'
                        }
                    ],
                    'VERSION' => [
                        {
                            'content' => '0.7.5a'
                        }
                    ],
                    'section_name' => 'Alignment',
                };
            }
        }
        if (exists $run_xml->{PROCESSING}->[0]->{DIRECTIVES} and
            !%{$run_xml->{PROCESSING}->[0]->{DIRECTIVES}->[0]}) {
            delete $run_xml->{PROCESSING}->[0]->{DIRECTIVES};
        }
        push @{$run_xml->{DATA_BLOCK}->[0]->{FILES}->[0]->{FILE}}, map {
            {
                checksum => $_->{checksum},
                checksum_method => $_->{checksum_method},
                filetype => $_->{type},
                filename => $_->{name},
            }
        } @{$metadata_by_barcode{$sample_barcode}{files}};
        if (exists $config->{$submission_label}->{assembly}) {
            unshift @{$run_xml->{RUN_ATTRIBUTES}->[0]->{RUN_ATTRIBUTE}}, {
                'TAG' => [
                    {
                        'content' => 'Assembly'
                    }
                ],
                'VALUE' => [
                    {
                        'content' => $config->{$submission_label}->{assembly}
                    }
                ],
            };
        }
        my $run_xml_tidy_obj = XML::Tidy->new(
            'xml' => $xs->XMLout(
                $run_xml,
                RootName => 'RUN',
                KeyAttr => [],
            )
        );
        $run_xml_tidy_obj->tidy($xml_indent_str);
        # remove dtd first line
        my $run_xml_tidy_str = $run_xml_tidy_obj->toString();
        $run_xml_tidy_str =~ s/^.+\n//;
        # indent every line
        $run_xml_tidy_str =~ s/^(.+)$/$xml_indent_str$1/gm;
        push @run_xmls, {
            xml => $run_xml_tidy_str,
            barcode => $sample_barcode,
        };
    }
    else {
        print "\nERROR: no file data for $sample_barcode\n";
    }
    print "\b" x length("$num_runs_processed processed"), ++$num_runs_processed, ' processed';
}
print "\n";
print "Building SRA-XML\n";
if (!exists $config->{$submission_label}->{no_exp}) {
    my $exp_xml_file = "$FindBin::Bin/$submission_label/${submission_label}.exp.xml";
    print "Generating $exp_xml_file\n";
    open(my $exp_xml_fh, '>', $exp_xml_file) or die "ERROR: could not create $exp_xml_file: $!";
    print $exp_xml_fh
        '<EXPERIMENT_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"', "\n",
        '                xsi:noNamespaceSchemaLocation="http://www.ncbi.nlm.nih.gov/viewvc/v1/trunk/sra/doc/SRA_1-5/SRA.experiment.xsd?view=co">', "\n";
    for my $exp_xml_hashref (natkeysort { $_->{barcode} } @exp_xmls) {
        print $exp_xml_fh $exp_xml_hashref->{xml};
    }
    print $exp_xml_fh '</EXPERIMENT_SET>', "\n";
    close($exp_xml_fh);
}
my $run_xml_file = "$FindBin::Bin/$submission_label/${submission_label}.run.xml";
print "Generating $run_xml_file\n";
open(my $run_xml_fh, '>', $run_xml_file) or die "ERROR: could not create $run_xml_file: $!";
print $run_xml_fh
    '<RUN_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"', "\n",
    '         xsi:noNamespaceSchemaLocation="http://www.ncbi.nlm.nih.gov/viewvc/v1/trunk/sra/doc/SRA_1-5/SRA.run.xsd?view=co">', "\n";
for my $run_xml_hashref (natkeysort { $_->{barcode} } @run_xmls) {
    print $run_xml_fh $run_xml_hashref->{xml};
}
print $run_xml_fh '</RUN_SET>', "\n";
close($run_xml_fh);
my $sub_xml_file = "$FindBin::Bin/$submission_label/${submission_label}.sub.xml";
print "Generating $sub_xml_file\n";
open(my $sub_xml_fh, '>', $sub_xml_file) or die "ERROR: could not create $sub_xml_file: $!";
my $sub_xml_tmpl = Text::Template->new(
    TYPE => 'FILE',
    SOURCE => -f "$FindBin::Bin/$submission_label/${submission_label}.sub.xml.tmpl"
        ? "$FindBin::Bin/$submission_label/${submission_label}.sub.xml.tmpl" 
        : "$FindBin::Bin/default.sub.xml.tmpl",
) or die "ERROR: couldn't construct template ${submission_label}.sub.xml.tmpl: $Text::Template::ERROR";
$sub_xml_tmpl->fill_in(
    OUTPUT => $sub_xml_fh,
    HASH => {
        broker_name => $config->{_}->{broker_name},
        center_name => $config->{$submission_label}->{center_name},
        submission_label => $submission_label,
        submission_name => uc($submission_label),
    },
) or die "ERROR: couldn't fill in template ${submission_label}.sub.xml.tmpl: $Text::Template::ERROR";
close($sub_xml_fh);
print "Validating SRA-XML\n";
for my $xml_type (sort keys %sra_xml_schemas) {
    my $xml_file = 
        "$FindBin::Bin/$submission_label/${submission_label}_${xml_type}.xml";
    if (-f $xml_file) {
        my $xmllint_cmd = "xmllint --noout --schema $sra_xml_schemas{$xml_type} $xml_file";
        print "$xmllint_cmd\n" if $verbose;
        system(split(' ', $xmllint_cmd)) == 0 or warn "ERROR: xmllint failed: ", $? >> 8, "\n";
    }
}
exit;

sub merge_run_info_hash {
    my ($run_info_by_data_type_hashref, $study_run_info_by_data_type_hashref) = @_;
    for my $data_type (keys %{$study_run_info_by_data_type_hashref}) {
        for my $seq_center_name (keys %{$study_run_info_by_data_type_hashref->{$data_type}->{center_platforms}}) {
            for my $platform (keys %{$study_run_info_by_data_type_hashref->{$data_type}->{center_platforms}->{$seq_center_name}}) {
                if (defined $run_info_by_data_type_hashref->{$data_type}->{center_platforms}->{$seq_center_name}->{$platform}) {
                    $run_info_by_data_type_hashref->{$data_type}->{center_platforms}->{$seq_center_name}->{$platform} +=
                        $study_run_info_by_data_type_hashref->{$data_type}->{center_platforms}->{$seq_center_name}->{$platform};
                }
                else {
                    $run_info_by_data_type_hashref->{$data_type}->{center_platforms}->{$seq_center_name}->{$platform} =
                        $study_run_info_by_data_type_hashref->{$data_type}->{center_platforms}->{$seq_center_name}->{$platform};
                }
            }
        }
        for my $run_id (keys %{$study_run_info_by_data_type_hashref->{$data_type}->{run_ids}}) {
            if (defined $run_info_by_data_type_hashref->{$data_type}->{run_ids}->{$run_id}) {
                $run_info_by_data_type_hashref->{$data_type}->{run_ids}->{$run_id} +=
                    $study_run_info_by_data_type_hashref->{$data_type}->{run_ids}->{$run_id};
            }
            else {
                $run_info_by_data_type_hashref->{$data_type}->{run_ids}->{$run_id} =
                    $study_run_info_by_data_type_hashref->{$data_type}->{run_ids}->{$run_id};
            }
        }
    }
    return $run_info_by_data_type_hashref;
}

__END__

=head1 NAME 

generate_sra_xml_submission_from_sra.pl - SRA-XML Submission Generator from Existing Metadata at SRA

=head1 SYNOPSIS

 generate_sra_xml_submission_from_sra.pl [options] <submission label>
 
 Parameters:
    <submission label>          Submission label used in config file and directory
 
 Options:
    --filter <field>=<value>    Filter runs by particular field values (optional, can be specified multiple times)
    --use-cached-run-info       Use cached SRA run info (default: download latest run info table from SRA)
    --use-cached-xml            Use cached SRA-XML files (default: download latest SRA-XML from SRA)
    --verbose                   Be verbose
    --help                      Display usage message and exit
    --version                   Display program version and exit

=cut
