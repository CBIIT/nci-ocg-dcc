#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw(fileparse);
use File::Find;
use Getopt::Long qw(:config auto_help auto_version);
use List::Compare;
use List::MoreUtils qw(uniq);
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natsort);
use Spreadsheet::Read qw(ReadData cellrow);
use Term::ANSIColor;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

# config
my @data_levels = qw(
    L1
    L2
    L3
    L4
);
my $default_manifest_file_name = 'MANIFEST.txt';

my @mage_tab_paths;
# default column with sample IDs in SDRF
my %sdrf_sample_id_cols = map { $_ => 'Extract Name' } @data_levels;
my $debug = 0;
GetOptions(
    'mage-tab-path=s' => \@mage_tab_paths,
    'sdrf-l1-sample-id-col=s' => \$sdrf_sample_id_cols{L1},
    'sdrf-l2-sample-id-col=s' => \$sdrf_sample_id_cols{L2},
    'sdrf-l3-sample-id-col=s' => \$sdrf_sample_id_cols{L3},
    'sdrf-l4-sample-id-col=s' => \$sdrf_sample_id_cols{L4},
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
if (!@ARGV) {
    pod2usage(
        -message => 'Missing required parameter: dataset directory path', 
        -verbose => 0
    ); 
}
my $dataset_dir_path = shift @ARGV;
$dataset_dir_path = "$dataset_dir_path/current" if -d "$dataset_dir_path/current";
$dataset_dir_path =~ s/\/{2,}/\//;
print "Using dataset directory: $dataset_dir_path\n";

if (!-d $dataset_dir_path or (
    !-d "$dataset_dir_path/L1" and
    !-d "$dataset_dir_path/L2" and
    !-d "$dataset_dir_path/L3" and
    !-d "$dataset_dir_path/L4") or (
    !@mage_tab_paths and 
    !-d "$dataset_dir_path/METADATA")) {
    pod2usage(
        -message => 'Dataset directory path is not valid, must point to L1/2/3/4/METADATA containing directory', 
        -verbose => 0,
    );
}
if (!@mage_tab_paths) {
    my $metadata_dir_path = "$dataset_dir_path/METADATA";
    my %mage_tabs_to_use;
    for my $file_path (grep { -f } <"$metadata_dir_path/*.{xls,XLS,xlsx,XLSX,sdrf,sdrf.txt}">) {
        my ($file_basename, undef, $file_ext) = fileparse($file_path, qr/\..*/);
        $file_ext =~ s/^\.//;
        $file_ext = lc($file_ext);
        if (!defined $mage_tabs_to_use{$file_basename} or 
            ($file_ext =~ /^xls/ and $mage_tabs_to_use{$file_basename}{ext} =~ /^sdrf/) or 
            ($file_ext eq 'xlsx' and $mage_tabs_to_use{$file_basename}{ext} eq 'xls')) {
            $mage_tabs_to_use{$file_basename} = {
                path => $file_path,
                ext => lc($file_ext),
            };
        }
    }
    @mage_tab_paths = map { $mage_tabs_to_use{$_}{path} } sort keys %mage_tabs_to_use;
    # not used anymore
    ## get newest modified MAGE-TAB if there are more than one
    #($mage_tab_path) = sort { -M $a <=> -M $b } 
    #                   grep { -f } 
    #                   <"$metadata_dir_path/*.{xls,XLS,xlsx,XLSX,sdrf.txt}">;
}
else {
    for my $mage_tab_path (@mage_tab_paths) {
        if (!-f $mage_tab_path) {
            die colored('ERROR', 'red'), ": specified MAGE-TAB archive $mage_tab_path not found or not valid\n";
        }
    }
}
if (!@mage_tab_paths) {
    die colored('ERROR', 'red'), ": no MAGE-TAB archive(s) specified or found in $dataset_dir_path/METADATA\n";
}
my (%sdrf_data_file_names, %sdrf_data_file_sample_ids);
for my $mage_tab_path (@mage_tab_paths) {
    my $mage_tab_is_csv = $mage_tab_path =~ /\.sdrf(\.txt|)$/ ? 1 : 0;
    print "Using MAGE-TAB archive: $mage_tab_path\n\n";
    # create MAGE-TAB Spreadsheet::Read workbook
    my %readdata_opts = (
        cells => 0, attr => 0,
    );
    if ($mage_tab_is_csv) {
        $readdata_opts{parser} = 'csv';
        $readdata_opts{sep} = "\t";
    }
    my $mage_tab_workbook = ReadData($mage_tab_path, %readdata_opts)
        or die colored('ERROR', 'red'), ": could not open MAGE-TAB archive file $mage_tab_path\n";
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
    # check if user-specified column for data level sample IDs exists
    for my $level (@data_levels) {
        if (!exists $sdrf_col_nums{$sdrf_sample_id_cols{$level}}) {
            die colored('ERROR', 'red'), ": '$sdrf_sample_id_cols{$level}' column not found in SDRF\n";
        }
    }
    # create %sdrf_data_level_col_nums data structure
    # determine from @sdrf_col_headers the L1/2/3/4 data column numbers,
    # for L2/3/4 there can be multiple columns of each so multiple numbers
    my %sdrf_data_level_col_nums;
    for my $col_idx (0 .. $#sdrf_col_headers) {
        if (my ($data_file_col_name, $is_higher_level) = $sdrf_col_headers[$col_idx] =~ /^((Derived )?Array Data File)$/i) {
            if ($sdrf_col_headers[$col_idx + 1] =~ /^Comment ?\[ ?OCG Data Level ?\]$/i) {
                # L1
                if (!$is_higher_level) {
                    if (!defined $sdrf_data_level_col_nums{L1}) {
                        # check Comment[OCG Data Level] column data
                        for my $row_num (2 .. $#{$sdrf_sheet->{cell}->[$col_idx + 2]}) {
                            my $row_data_col_val = $sdrf_sheet->{cell}->[$col_idx + 1][$row_num];
                            my $row_data_level_col_val = $sdrf_sheet->{cell}->[$col_idx + 2][$row_num];
                            if (
                                defined $row_data_col_val and $row_data_col_val !~ /^\s*$/ and
                                ( !defined $row_data_level_col_val or $row_data_level_col_val ne '1' )
                            ) {
                                die colored('ERROR', 'red'), 
                                    ": '$data_file_col_name' -> 'Comment[OCG Data Level]' SDRF column data values must all be set to 1\n"; 
                            }
                        }
                        push @{$sdrf_data_level_col_nums{L1}}, $col_idx + 1;
                    }
                    else {
                        die colored('ERROR', 'red'), ": '$data_file_col_name' column found more than once in SDRF\n";
                    }
                }
                # L2/3/4
                else {
                    # check Comment[OCG Data Level] column data
                    my $data_level_col_val;
                    for my $row_num (2 .. $#{$sdrf_sheet->{cell}->[$col_idx + 2]}) {
                        my $row_data_col_val = $sdrf_sheet->{cell}->[$col_idx + 1][$row_num];
                        my $row_data_level_col_val = $sdrf_sheet->{cell}->[$col_idx + 2][$row_num];
                        if (!defined $data_level_col_val and defined $row_data_level_col_val and $row_data_level_col_val !~ /^\s*$/) {
                            $data_level_col_val = $row_data_level_col_val;
                        }
                        if (
                            defined $row_data_col_val and $row_data_col_val !~ /^\s*$/ and
                            ( !defined $row_data_level_col_val or $row_data_level_col_val ne $data_level_col_val )
                        ) {
                            die colored('ERROR', 'red'), 
                                ": '$data_file_col_name' -> 'Comment[OCG Data Level]' SDRF column data must all be set to $data_level_col_val\n";
                        }
                    }
                    if (defined $sdrf_data_level_col_nums{'L' . ($data_level_col_val + 1)}) {
                        die colored('ERROR', 'red'), 
                            ": '$data_file_col_name' L$data_level_col_val cannot be after L", $data_level_col_val + 1, "columns\n";
                    }
                    push @{$sdrf_data_level_col_nums{"L$data_level_col_val"}}, $col_idx + 1;
                }
            }
            else {
                die colored('ERROR', 'red'), 
                    ": '$data_file_col_name' column must be followed by 'Comment[OCG Data Level]' column in SDRF\n";
            }
        }
    }
    print STDERR "\%sdrf_data_level_col_nums:\n", Dumper(\%sdrf_data_level_col_nums) if $debug;
    # add to %sdrf_data_file_names and %sdrf_data_file_sample_ids data structures
    for my $level (@data_levels) {
        if (!defined $sdrf_data_file_names{$level}) {
            # init so that List::Compare doesn't complain below
            $sdrf_data_file_names{$level} = [];
        }
        if (defined $sdrf_data_level_col_nums{$level}) {
            my @new_sdrf_data_file_names = natsort uniq(
                grep {
                    defined and !m/^\s*$/
                }
                map {
                    @{$sdrf_sheet->{cell}->[$_]}[2 .. $#{$sdrf_sheet->{cell}->[$_]}]
                }
                @{$sdrf_data_level_col_nums{$level}}
            );
            if (!@{$sdrf_data_file_names{$level}}) {
                @{$sdrf_data_file_names{$level}} = @new_sdrf_data_file_names;
            }
            else {
                my $lc_obj = List::Compare->new(
                    '--unsorted', 
                    $sdrf_data_file_names{$level}, \@new_sdrf_data_file_names,
                );
                my @intersection = $lc_obj->get_intersection();
                if (!@intersection) {
                    @{$sdrf_data_file_names{$level}} = natsort uniq(
                        @{$sdrf_data_file_names{$level}},
                        @new_sdrf_data_file_names,
                    );
                }
                else {
                    die colored('ERROR', 'red'), 
                        ": the following $level file names exist in already loaded MAGE-TAB(s):\n",
                        join("\n", natsort @intersection),
                        "\n";
                }
            }
            # init %{$sdrf_data_file_sample_ids{$level}} with all new data file name keys since in rare
            # case there might be a data file name that maps back to an undef sample ID and in
            # inner for loop below then it won't get set
            for my $sdrf_data_file_name (@new_sdrf_data_file_names) {
                if (!defined $sdrf_data_file_sample_ids{$level}{$sdrf_data_file_name}) {
                    $sdrf_data_file_sample_ids{$level}{$sdrf_data_file_name} = {};
                }
                else {
                    die colored('ERROR', 'red'), 
                        ": $sdrf_data_file_name $level file name exists in already loaded MAGE-TAB(s)\n";
                }
            }
            for my $col_num (@{$sdrf_data_level_col_nums{$level}}) {
                for my $row_num (2 .. $#{$sdrf_sheet->{cell}->[$col_num]}) {
                    if (defined $sdrf_sheet->{cell}->[$col_num]->[$row_num] and
                        $sdrf_sheet->{cell}->[$col_num]->[$row_num] !~ /^\s*$/ and 
                        defined $sdrf_sheet->{cell}->[$sdrf_col_nums{$sdrf_sample_id_cols{$level}}]->[$row_num] and 
                        $sdrf_sheet->{cell}->[$sdrf_col_nums{$sdrf_sample_id_cols{$level}}]->[$row_num] !~ /^\s*$/) {
                        $sdrf_data_file_sample_ids{
                            $level
                        }{
                            $sdrf_sheet->{cell}->[$col_num]->[$row_num]
                        }{
                            $sdrf_sheet->{cell}->[$sdrf_col_nums{$sdrf_sample_id_cols{$level}}]->[$row_num]
                        }++;
                    }
                }
            }
        }
    }
}
if ($debug) {
    print STDERR "\%sdrf_data_file_names:\n", Dumper(\%sdrf_data_file_names),
                 "\%sdrf_data_file_sample_ids:\n", Dumper(\%sdrf_data_file_sample_ids);
}
# build %fs_data_file_names file system data structure, check file names against MAGE-TAB SDRF and report
print "SDRF-to-DATASET differences report:\n\n";
my %fs_data_file_names;
for my $level (@data_levels) {
    my $data_dir_path = "$dataset_dir_path/$level";
    next unless -d $data_dir_path;
    find({
        wanted => sub {
            push @{$fs_data_file_names{$level}}, $_ if -f and $_ ne $default_manifest_file_name;
        },
    }, $data_dir_path);
    @{$fs_data_file_names{$level}} = natsort @{$fs_data_file_names{$level}};
    # report diffs between SDRF and FS
    my $lc_obj = List::Compare->new(
        '--unsorted', 
        $sdrf_data_file_names{$level}, $fs_data_file_names{$level},
    );
    my @Ronly = $lc_obj->get_Ronly;
    my @Lonly = $lc_obj->get_Lonly;
    print "$level ($data_dir_path):\n", ('-' x length("$level ($data_dir_path):")), "\n";
    if (@Ronly) {
        print colored('DATASET ONLY', 'red'), ":\n", join("\n", natsort @Ronly), "\n";
    }
    if (@Lonly) {
        print colored('SDRF ONLY', 'red'), ":\n", join("\n", natsort @Lonly), "\n";
    }
    if (!@Ronly and !@Lonly) {
        print colored('OK', 'green'), "\n\n";
    }
    else {
        print "\n\n";
    }
}
print STDERR "\%fs_data_file_names:\n", Dumper(\%fs_data_file_names) if $debug;
# check multi-sample L1/2/3/4 file headers against MAGE-TAB SDRF sample IDs and report
my $have_multi_sample_data_to_report;
print "SDRF-to-DATA FILE SAMPLE ID differences report:\n\n";
my ($data_type) = $dataset_dir_path =~ /(copy_number|methylation|gene_expression|miRNA)/;
for my $level (@data_levels) {
    my $data_dir_path = "$dataset_dir_path/$level";
    next unless -d $data_dir_path;
    DATAFILE: for my $data_file_name (natsort keys %{$sdrf_data_file_sample_ids{$level}}) {
        my @sdrf_sample_ids = natsort keys %{$sdrf_data_file_sample_ids{$level}{$data_file_name}};
        my (undef, undef, $data_file_ext) = fileparse($data_file_name, qr/\.[^.]*/);
        $data_file_ext =~ s/\.//g;
        $data_file_ext = lc($data_file_ext);
        # skip checking files that don't map back to any samples
        # skip checking files that map back to one sample
        # skip checking L3 copy number files that map back to two samples (paired)
        next DATAFILE if 
            !@sdrf_sample_ids or 
            scalar(@sdrf_sample_ids) == 1 or 
            ($data_type eq 'copy_number' and $level eq 'L3' and scalar(@sdrf_sample_ids) == 2);
        # skip certain data files that don't need checking or cannot be checked
        if (($dataset_dir_path =~ /(WT|CCSK|ALL)\// and 
            $data_type eq 'gene_expression' and 
            $level eq 'L3' and 
            $data_file_name =~ /collapsed(_|-)(mapping|nulls)/i) or 
            $data_file_ext eq 'pdf') {
            print colored('SKIPPED', 'green'), ": $data_file_name\n\n";
            next DATAFILE;
        }
        $have_multi_sample_data_to_report++;
        my $data_file_found;
        find(sub {
            return unless -f and $_ eq $data_file_name;
            $data_file_found++;
            if (open(my $data_fh, '<', $File::Find::name)) {
                my @file_sample_ids;
                # gene expression GCT
                if ($data_type eq 'gene_expression' and $data_file_ext eq 'gct') {
                    # throw away first two GCT file header lines
                    <$data_fh>; <$data_fh>;
                    my $col_header_line = <$data_fh>;
                    $col_header_line =~ s/\s+$//;
                    if ($col_header_line !~ /^(Name|Probe Set ID)\tDescription\t/i) {
                       warn colored('ERROR', 'red'), ": invalid data column header in $File::Find::name\n";
                       #next DATAFILE;
                       return;
                    }
                    my @col_headers = split /\t/, $col_header_line;
                    # throw away first 2 column headers
                    splice(@col_headers, 0, 2);
                    @file_sample_ids = natsort uniq(@col_headers);
                }
                # gene expression RMA/TXT
                elsif ($data_type eq 'gene_expression' and $data_file_ext eq 'txt') {
                    my @col_headers;
                    # ALL GEX
                    if ($dataset_dir_path =~ /ALL\//) {
                        my $col_header_line = <$data_fh>;
                        $col_header_line =~ s/\s+$//;
                        if ($col_header_line !~ /^Probe Set ID\t/i) {
                            warn colored('ERROR', 'red'), ": invalid data column header in $File::Find::name\n";
                            #next DATAFILE;
                            return;
                        }
                        @col_headers = split /\t/, $col_header_line;
                        # throw away first 1 column headers
                        splice(@col_headers, 0, 1);
                    }
                    # OS RMA Affy exon arrays
                    elsif ($dataset_dir_path =~ /OS\//) {
                        while (<$data_fh>) {
                            s/^\s+//;
                            s/\s+$//;
                            if (m/^probeset_id\t(gene_assignment\t|)/i) {
                                @col_headers = split /\t/;
                                last;
                            }
                            # since files are huge if haven't found header by first 1000 lines then quit looking
                            elsif ($. eq 1000) {
                                last;
                            }
                        }
                        if (!@col_headers) {
                            warn colored('ERROR', 'red'), ": could not find data column header in $File::Find::name\n";
                            #next DATAFILE;
                            return;
                        }
                        # throw away first 1 or 2 column headers
                        splice(@col_headers, 0, $level eq 'L2' ? 1 : 2);
                    }
                    # AML RMA
                    elsif ($dataset_dir_path =~ /AML\//) {
                        my $col_header_line = <$data_fh>;
                        $col_header_line =~ s/\s+$//;
                        if ($col_header_line !~ /^"ID"\t(Gene Symbol\t|)/i) {
                            warn colored('ERROR', 'red'), ": invalid data column header in $File::Find::name\n";
                            #next DATAFILE;
                            return;
                        }
                        @col_headers = split /\t/, $col_header_line;
                        # throw away first 1 or 2 column headers
                        splice(@col_headers, 0, $level eq 'L2' ? 1 : 2);
                    }
                    # regular RMA
                    else {
                        my $col_header_line = <$data_fh>;
                        $col_header_line =~ s/\s+$//;
                        if (($level eq 'L2' and
                            $col_header_line !~ /^"ID"\tseqname\tstart\tstop\tstrand\ttotal_probes\tgene_assignment\tGene Symbol\tRefSeq\t/i) or
                            ($level eq 'L3' and
                            $col_header_line !~ /^Label\tLevel\tStatistic\t/i)) {
                            warn colored('ERROR', 'red'), ": invalid data column header in $File::Find::name\n";
                            #next DATAFILE;
                            return;
                        }
                        @col_headers = split /\t/, $col_header_line;
                        # throw away first 9 or 3 column headers
                        splice(@col_headers, 0, $level eq 'L2' ? 9 : 3);
                    }
                    @file_sample_ids = natsort uniq(@col_headers);
                }
                # methylation
                elsif ($data_type eq 'methylation' and $data_file_ext eq 'txt') {
                    # ALL NimbleGen HELP
                    if ($dataset_dir_path =~ /ALL\//) {
                        my $col_header_line = <$data_fh>;
                        $col_header_line =~ s/\s+$//;
                        if ($col_header_line !~ /^probeset\t/i) {
                            warn colored('ERROR', 'red'), ": invalid data column header in $File::Find::name\n";
                            #next DATAFILE;
                            return;
                        }
                        my @col_headers = split /\t/, $col_header_line;
                        # throw away first 1 column headers
                        splice(@col_headers, 0, 1);
                        @file_sample_ids = natsort uniq(@col_headers);
                    }
                    ## OS Illumina Infinium
                    elsif ($dataset_dir_path =~ /OS\//) {
                        my $col_header_line = <$data_fh>;
                        $col_header_line =~ s/\s+$//;
                        if ($col_header_line !~ /^ReporterID\t/i) {
                            warn colored('ERROR', 'red'), ": invalid data column header in $File::Find::name\n";
                            #next DATAFILE;
                            return;
                        }
                        my @col_headers = split /\t/, $col_header_line;
                        # throw away first 1 column headers
                        splice(@col_headers, 0, 1);
                        @file_sample_ids = natsort uniq(@col_headers);
                    }
                    # all other Infinium
                    else {
                        if ($dataset_dir_path =~ /(WT|CCSK)\// and $level eq 'L2' and $data_file_name =~ /samples_table/i) {
                            my @col_headers = split /\t/, <$data_fh>;
                            while (<$data_fh>) {
                                my $sample_id;
                                (undef, $sample_id) = split /\t/;
                                push @file_sample_ids, $sample_id;
                            }
                        }
                        else {
                            my @col_headers;
                            while (<$data_fh>) {
                                s/^\s+//;
                                s/\s+$//;
                                if (m/^(Index\t|)TargetID\t(ProbeID_A\tProbeID_B\t|)/i) {
                                    @col_headers = split /\t/;
                                    last;
                                }
                                # since files are huge if haven't found header by first 100 lines then quit looking
                                elsif ($. eq 100) {
                                    last;
                                }
                            }
                            if (!@col_headers) {
                                warn colored('ERROR', 'red'), ": could not find data column header in $File::Find::name\n";
                                #next DATAFILE;
                                return;
                            }
                            # extract only sample data column headers and extract sample IDs
                            @file_sample_ids = 
                                map {
                                    s/\.(AVG_Beta|Intensity|Detection( |_)Pval|Signal_A|Signal_B|BEAD_STDERR_A|BEAD_STDERR_B|Avg_NBEADS_A|Avg_NBEADS_B)$//i; $_;
                                } 
                                grep {
                                    m/\.(AVG_Beta|Intensity|Detection( |_)Pval|Signal_A|Signal_B|BEAD_STDERR_A|BEAD_STDERR_B|Avg_NBEADS_A|Avg_NBEADS_B)$/i
                                } @col_headers;
                        }
                        # special fix for WT methylation files that don't have TARGET-50- prefix in L2
                        if ($dataset_dir_path =~ /WT\// and $level eq 'L2') {
                            for my $sample_id (@file_sample_ids) {
                                if ($sample_id !~ /^(TARGET-50-|Perlman Lab)/) {
                                    $sample_id = "TARGET-50-$sample_id"
                                }
                            }
                        }
                        @file_sample_ids = natsort uniq(@file_sample_ids);
                    }
                }
                # copy number 
                elsif ($data_type eq 'copy_number' and $data_file_ext eq 'txt' and $level eq 'L2') {
                    my @col_headers;
                    my $col_header_line = <$data_fh>;
                    $col_header_line =~ s/\s+$//;
                    # OS
                    if ($dataset_dir_path =~ /OS\//) {
                        my $num_first_headers_to_exclude;
                        if ($col_header_line =~ /^ProbeSetID\tChromosome\tPosition\t/i) {
                            $num_first_headers_to_exclude = 3;
                        }
                        elsif ($col_header_line =~ /^Probe Set ID\t/i) {
                            $num_first_headers_to_exclude = 1;
                        }
                        else {
                            warn colored('ERROR', 'red'), ": invalid column header in $File::Find::name\n";
                            #next DATAFILE;
                            return;
                        }
                        @col_headers = split /\t/, $col_header_line;
                        splice(@col_headers, 0, $num_first_headers_to_exclude);
                    }
                    else {
                        my $has_annot_cols;
                        if ($col_header_line !~ /^"ID"\t(Associated Gene\tdbSNP RS ID\tChromosome\tChromosome Start\tChromosome Stop\tPhysical Position\t|)/i) {
                            warn colored('ERROR', 'red'), ": invalid data column header in $File::Find::name\n";
                            #next DATAFILE;
                            return;
                        }
                        else {
                            $has_annot_cols = $1;
                        }
                        @col_headers = split /\t/, $col_header_line;
                        # throw away first 1 or 7 column headers
                        splice(@col_headers, 0, $has_annot_cols ? 7 : 1);
                    }
                    @file_sample_ids = @col_headers;
                    # AML L2 fix: they used the diagnostic/tumor sample IDs to label 
                    # paired data so must fix so matching remission/normals don't fail
                    if ($dataset_dir_path =~ /AML\//) {
                        my %new_file_sample_ids;
                        for my $sample_id (@file_sample_ids) {
                            my $new_sample_id = join('-', (split('-', $sample_id))[0..2]);
                            if (!exists $new_file_sample_ids{$new_sample_id}) {
                                $new_file_sample_ids{$new_sample_id}++;
                            }
                            else {
                                warn colored('ERROR', 'red'), ": $sample_id found more than once in data file\n";
                                #next DATAFILE;
                                return;
                            }
                        }
                        @file_sample_ids = keys %new_file_sample_ids;
                    }
                    @file_sample_ids = natsort uniq(@file_sample_ids);
                }
                elsif ($data_type eq 'copy_number' and $data_file_ext eq 'txt' and $level eq 'L3') {
                    my @col_headers = split /\t/, <$data_fh>;
                    while (<$data_fh>) {
                        my $sample_id;
                        # ALL, OS
                        if ($dataset_dir_path =~ /(ALL|OS)\//) {
                            # special case for ALLP1 L3 LOH file
                            # use 2nd 'Sample' column which holds TARGET Sample ID
                            if ($data_file_name =~ /LOH/) {
                                (undef, $sample_id) = split /\t/;
                            }
                            # use 1st 'SampleName' column which holds TARGET Sample ID
                            else {
                                ($sample_id) = split /\t/;
                            }
                        }
                        else {
                            # use 6th 'Label' column which holds TARGET Sample ID instead of the 
                            # 7th 'Sample ID' column which holds the L1 data file name (could use 
                            # 'Sample ID' column if run program with --sdrf-l3-sample-id-col='Array Data File')
                            (undef, undef, undef, undef, undef, $sample_id) = split /\t/;
                        }
                        push @file_sample_ids, $sample_id;
                    }
                    @file_sample_ids = uniq(@file_sample_ids);
                    # AML and OS L3 fix: they used the diagnostic/tumor sample IDs to label 
                    # paired data so must fix so matching remission/normals don't fail
                    if ($dataset_dir_path =~ /(AML|OS)\//) {
                        my %new_file_sample_ids;
                        for my $sample_id (@file_sample_ids) {
                            my $new_sample_id = join('-', (split('-', $sample_id))[0..2]);
                            if (!exists $new_file_sample_ids{$new_sample_id}) {
                                $new_file_sample_ids{$new_sample_id}++;
                            }
                            else {
                                warn colored('ERROR', 'red'), ": $sample_id found more than once in data file\n";
                                #next DATAFILE;
                                return;
                            }
                        }
                        @file_sample_ids = keys %new_file_sample_ids;
                    }
                    @file_sample_ids = natsort @file_sample_ids;
                }
                # miRNA
                elsif ($data_type eq 'miRNA' and $data_file_ext eq 'txt') {
                    my $col_header_line = <$data_fh>;
                    $col_header_line =~ s/\s+$//;
                    if ($col_header_line !~ /^(Filename|Sample Name|miRNA)\t/i) {
                        warn colored('ERROR', 'red'), ": invalid data column header in $File::Find::name\n";
                        #next DATAFILE;
                        return;
                    }
                    my @col_headers = split /\t/, $col_header_line;
                    # throw away first 1 column headers
                    splice(@col_headers, 0, 1);
                    @file_sample_ids = natsort uniq(@col_headers);
                }
                else {
                    warn colored('ERROR', 'red'), ": unsupported file type $File::Find::name\n";
                    #next DATAFILE;
                    return;
                }
                close($data_fh);
                print STDERR "$data_file_name\n\@file_sample_ids:\n", Dumper(\@file_sample_ids) if $debug;
                # report diffs between SDRF and FILE
                my $lc_obj = List::Compare->new(
                    '--unsorted', 
                    \@sdrf_sample_ids, \@file_sample_ids,
                );
                my @Ronly = $lc_obj->get_Ronly;
                my @Lonly = $lc_obj->get_Lonly;
                print "$File::Find::name:\n", ('-' x length("$File::Find::name:")), "\n";
                if (@Ronly) {
                    print colored('FILE ONLY', 'red'), ":\n", join("\n", natsort @Ronly), "\n";
                }
                if (@Lonly) {
                    print colored('SDRF ONLY', 'red'), ":\n", join("\n", natsort @Lonly), "\n";
                }
                if (!@Ronly and !@Lonly) {
                    print colored('OK', 'green'), "\n\n";
                }
                else {
                    print "\n";
                }
            }
            else {
                warn colored('ERROR', 'red'), ": could not open $File::Find::name: $!\n";
            }
        }, $data_dir_path);
        if (!$data_file_found) {
            warn colored('ERROR', 'red'), ": could not find $data_file_name\n";
        }
    }
}
print "N/A\n" unless $have_multi_sample_data_to_report;
exit;

__END__

=head1 NAME 

validate_array_mage_tab.pl - OCG DCC Microarray MAGE-TAB-to-Dataset Validator

=head1 SYNOPSIS

 validate_array_mage_tab.pl [options] <dataset directory path>
 
 Parameters:
    <dataset directory path>            Path to dataset directory containing L1, L2, L3, L4, METADATA directories
 
 Options:
    --mage-tab-path=<path>              Alternate path to MAGE-TAB archive (optional, multiple entries allowed, defaults to archives in METADATA dir)
    --sdrf-l1-sample-id-col="<name>"    Alternate MAGE-TAB SDRF column name holding L1 data file sample IDs (optional, default 'Extract Name' column)
    --sdrf-l2-sample-id-col="<name>"    Alternate MAGE-TAB SDRF column name holding L2 data file sample IDs (optional, default 'Extract Name' column)
    --sdrf-l3-sample-id-col="<name>"    Alternate MAGE-TAB SDRF column name holding L3 data file sample IDs (optional, default 'Extract Name' column)
    --sdrf-l4-sample-id-col="<name>"    Alternate MAGE-TAB SDRF column name holding L4 data file sample IDs (optional, default 'Extract Name' column)
    --help                              Display usage message and exit
    --version                           Display program version and exit

=cut
