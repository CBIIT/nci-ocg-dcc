#!/usr/bin/env perl

use strict;
use warnings;
use Cwd qw(cwd);
use File::Basename qw(fileparse dirname);
use File::Find;
use File::Path 2.11 qw(make_path remove_tree);
use File::Spec;
use Getopt::Long qw(:config auto_help auto_version);
use List::Util qw(any sum);
use List::MoreUtils qw(firstidx);
use Path::Iterator::Rule;
use Pod::Usage qw(pod2usage);
use Spreadsheet::Read qw(ReadData cellrow);
use Sort::Key::Natural qw(natsort);
use Storable qw(lock_nstore lock_retrieve);
use Data::Dumper;

our $VERSION = '0.1';

# unbuffer error and output streams 
# make sure STDOUT is last so that it remains the default filehandle
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

# const
my $CASE_REGEXP = qr/[A-Z]+-\d{2}(?:-\d{2})?-[A-Z0-9]+/;
my $CGI_CASE_DIR_REGEXP = qr/${CASE_REGEXP}(?:(?:-|_)\d+)?/;
my $BARCODE_END_REGEXP = qr/(?:\.\d+)?[A-Z]-\d{2}[A-Z]/;
my $BARCODE_REGEXP = qr/${CASE_REGEXP}-\d{2}${BARCODE_END_REGEXP}/;

# config
my %program_project_conf = (
    'TARGET' => {
        'ALL' => {
        },
        'AML' => {
        },
        'CCSK' => {
        },
        'NBL' => {
        },
        'OS' => {
        },
        'RT' => {
        },
        'WT' => {
            'WXS' => {
                'L3' => {
                    'parse_files' => [
                        'target-wt-17pairs-somatic-v1.1.mafplus.xlsx',
                        'target-wt-17pairs-NCI-somatic-exonic.bcmmaf.txt',
                        'target-wt-primary-recurrent-NCI-somatic-exonic.bcmmaf.txt',
                        'target-wt-pilot-bcm-somatic-v4.0.mafplus.xlsx',
                        'target-wt-pilot-nci-somatic-v4.0.mafplus.xlsx',
                    ],
                },
            },
        },
    },
    'CGCI' => {
        'BLGSP' => {
        },
        'HTMCP-CC' => {
        },
        'HTMCP-DLBCL' => {
        },
        'HTMCP-LC' => {
        },
        'MB' => {
        },
        'NHL-DLBCL' => {
        },
        'NHL-FL' => {
        },
    },
);
my %maf_conf = (
    'CGI' => {
        'blank_val' => '',
        'gene_symbol' => 'Hugo_Symbol',
        'tumor_barcode' => 'Tumor_Sample_Barcode',
        'norm_barcode' => 'Match_Normal_Sample_Barcode',
        'chr' => 'Chromosome',
        'pos' => 'Start_position',
        'end_pos' => 'End_position',
        'variant_type' => 'VariantType',
        'variant_class' => 'Variant_Classification',
        'ref_allele' => 'Reference_Allele',
        'tumor_allele_1' => 'Tumor_Seq_Allele1',
        'tumor_allele_2' => 'Tumor_Seq_Allele2',
        'ver_method' => 'Verification_Method',
        'ver_status' => 'Verification_Status',
        'ver_status_val' => 'Somatic',
        'ver_ref_allele' => 'Reference_Allele_VS',
        'ver_tumor_allele_1' => 'Tumor_Seq_Allele1_VS',
        'ver_tumor_allele_2' => 'Tumor_Seq_Allele2_VS',
        'ver_norm_allele_1' => 'Match_Norm_Allele1_VS',
        'ver_norm_allele_2' => 'Match_Norm_Allele2_VS',
        'ver_vcf_filter' => 'VCF_Filter_VS',
        'tumor_tot_count' => 'TumorTotalCount_VS',
        'tumor_ref_count' => 'TumorRefCount_VS',
        'tumor_var_count' => 'TumorVarCount_VS',
        'tumor_var_ratio' => 'TumorVarRatio_VS',
        'norm_tot_count' => 'NormalTotalCount_VS',
        'norm_ref_count' => 'NormalRefCount_VS',
        'norm_var_count' => 'NormalVarCount_VS',
        'norm_var_ratio' => 'NormalVarRatio_VS',
    },
    'BCM' => {
        'blank_val' => '.',
        'gene_symbol' => 'Hugo_Symbol',
        'tumor_barcode' => 'Tumor_Sample_Barcode',
        'norm_barcode' => 'Matched_Norm_Sample_Barcode',
        'chr' => 'Chromosome',
        'pos' => 'Start_position',
        'end_pos' => 'End_position',
        'variant_type' => 'Variant_Type',
        'variant_class' => 'Variant_Classification',
        'ref_allele' => 'Reference_Allele',
        'tumor_allele_1' => 'Tumor_Seq_Allele1',
        'tumor_allele_2' => 'Tumor_Seq_Allele2',
        'ver_method' => 'Validation_Method',
        'ver_status' => 'Verification_Status',
        'ver_status_val' => 'Valid',
        'val_status' => 'Validation_Status',
        'val_status_val' => 'Valid',
        'mut_status' => 'Mutation_Status',
        'mut_status_val' => 'Somatic',
        'ver_ref_allele' => 'Reference_Validation_Allele',
        'ver_tumor_allele_1' => 'Tumor_Validation_Allele1',
        'ver_tumor_allele_2' => 'Tumor_Validation_Allele2',
        'ver_norm_allele_1' => 'Match_Norm_Validation_Allele1',
        'ver_norm_allele_2' => 'Match_Norm_Validation_Allele2',
        'ver_vcf_filter' => 'Validation_VCF_Filter',
        'tumor_tot_count' => 'TTotCovVal',
        'tumor_ref_count' => 'TRefCovVal',
        'tumor_var_count' => 'TVarCovVal',
        'tumor_var_ratio' => 'TVarRatioVal',
        'norm_tot_count' => 'NTotCovVal',
        'norm_ref_count' => 'NRefCovVal',
        'norm_var_count' => 'NVarCovVal',
        'norm_var_ratio' => 'NVarRatioVal',
    },
    'BCCA' => {
        'blank_val' => '',
        'gene_symbol' => 'Gene Symbol',
        'tumor_barcode' => 'Tumor_Sample_Barcode',
        'norm_barcode' => 'Match_Norm_Sample_Barcode',
        'chr' => 'Chromosome',
        'pos' => 'Start_Position',
        'end_pos' => 'End_Position',
        'variant_type' => 'Variant_Type',
        'variant_class' => 'Transcript architecture around variant',
        'ref_allele' => 'Reference_Allele',
        'tumor_allele_1' => 'Tumor_Seq_Allele1',
        'tumor_allele_2' => 'Tumor_Seq_Allele2',
        'ver_method' => 'Verification_Method',
        'ver_status' => 'Verification_Status',
        'ver_status_val' => 'Somatic',
        'ver_ref_allele' => 'Reference_Allele_VS',
        'ver_tumor_allele_1' => 'Tumor_Seq_Allele1_VS',
        'ver_tumor_allele_2' => 'Tumor_Seq_Allele2_VS',
        'ver_norm_allele_1' => 'Match_Norm_Allele1_VS',
        'ver_norm_allele_2' => 'Match_Norm_Allele2_VS',
        'ver_vcf_filter' => 'VCF_Filter_VS',
        'tumor_tot_count' => 'TumorTotalCount_VS',
        'tumor_ref_count' => 'TumorRefCount_VS',
        'tumor_var_count' => 'TumorVarCount_VS',
        'tumor_var_ratio' => 'TumorVarRatio_VS',
        'norm_tot_count' => 'NormalTotalCount_VS',
        'norm_ref_count' => 'NormalRefCount_VS',
        'norm_var_count' => 'NormalVarCount_VS',
        'norm_var_ratio' => 'NormalVarRatio_VS',
    },
);
# always order types 
# strelka
# mpileup vcfs
# mpileup mafs
my @ver_data_file_types = qw(
    tcs_strelka_snv_vcf
    tcs_strelka_indel_vcf
    tcs_tumor_snv_vcf
    tcs_normal_snv_vcf
    tcs_tumor_indel_vcf
    tcs_normal_indel_vcf
    tcs_tumor_snv_maf
    tcs_normal_snv_maf
    rna_tumor_snv_maf
    rna_normal_snv_maf
    rna_tumor_indel_vcf
    rna_normal_indel_vcf
);
my @data_types = qw(
    WGS
    WXS
);
my %debug_types = map { $_ => 1 } qw(
    all
    params
    conf
    cgi
    maf_parse
    maf_xls
    ver_data
    ver_step
);
my $cgi_dir_name = 'CGI';
my @cgi_data_dir_names = qw(
    PilotAnalysisPipeline2
    OptionAnalysisPipeline2
);
my @param_groups = qw(
    programs
    projects
    data_types
    data_sets
    cases
);
my $count_ratio_format = '%.9f';
my $maf_sep_char = '|';

my $output_dir = cwd();
my $cache_dir = "$ENV{'HOME'}/.ocg-dcc/verified_mafs";
my $rebuild_cache = 0;
my $no_cache = 0;
my $no_unverified = 0;
my $conserve_memory = 0;
my $use_cgi_filtered_mafs = 0;
my $use_dbm = 0;
my $verbose = 0;
my @debug = ();
GetOptions(
    'output-dir=s' => \$output_dir,
    'cache-dir=s' => \$cache_dir,
    'rebuild-cache' => \$rebuild_cache,
    'no-cache' => \$no_cache,
    'no-unverified' => \$no_unverified,
    'conserve-memory' => \$conserve_memory,
    'use-cgi-filtered-mafs' => \$use_cgi_filtered_mafs,
    'use-dbm' => \$use_dbm,
    'verbose' => \$verbose,
    'debug:s' => \@debug,
) || pod2usage(-verbose => 0);
my %debug = map { $_ => 1 } split(',', join(',', map { lc($_) || 'all' } @debug));
for my $debug_type (natsort keys %debug) {
    if (!$debug_types{$debug_type}) {
        pod2usage(-message => "Invalid debug type: $debug_type", -verbose => 0);
    }
}
my %user_params;
if (@ARGV) {
    for my $i (0 .. $#param_groups) {
        if (defined $ARGV[$i] and $ARGV[$i] !~ /^\s*$/) {
            %{$user_params{$param_groups[$i]}} = map { uc($_) => 1 } split(',', $ARGV[$i]);
        }
    }
}
if ($debug{all} or $debug{params}) {
    print STDERR "\%user_params:\n", Dumper(\%user_params);
}
if (!-d $cache_dir) {
    make_path($cache_dir, { chmod => 0700 }) 
        or die "ERROR: could not create $cache_dir: $!\n";
}
for my $program_name (reverse natsort keys %program_project_conf) {
    next if defined $user_params{programs} and not exists $user_params{programs}{uc($program_name)};
    for my $project_name (natsort keys %{$program_project_conf{$program_name}}) {
        next if defined $user_params{projects} and not exists $user_params{projects}{uc($project_name)};
        my ($disease_proj, $subproject) = split /-(?=MDLS|VALD|PPTP)/, $project_name, 2;
        my ($project_dir, $project_disc_dir, $project_vald_dir);
        if ($disease_proj =~ /^ALLP(1|2)$/) {
            $project_dir = 'ALL/Phase_' . ( $1 eq 1 ? 'I' : 'II' );
        }
        else {
            $project_dir = $disease_proj;
        }
        if ($disease_proj !~ /^(MB|NHL-(DLBCL|FL))$/) {
            $project_disc_dir = "$project_dir/Discovery";
            $project_vald_dir = "$project_dir/Validation";
        }
        for my $data_type (@data_types) {
            next if defined $user_params{data_types} and not exists $user_params{data_types}{uc($data_type)};
            print "[$program_name $project_name $data_type]\n";
            my $data_type_dir = $data_type;
            my $disc_dataset_dir = "/local/\L$program_name\E/data/$project_disc_dir/$data_type_dir/current";
            if (!-d $disc_dataset_dir) {
                print STDERR "ERROR: $disc_dataset_dir doesn't exist\n";
                next;
            }
            my $dataset_output_dir = "$output_dir/$project_name/$data_type";
            # re-init output dir if exists
            if ( -d $dataset_output_dir and
                !-z $dataset_output_dir) {
                remove_tree($dataset_output_dir, { keep_root => 1 }) or die "ERROR: could not re-init $dataset_output_dir: $!";
            }
            my $disc_tcs_data_dir = "/local/\L$program_name\E/data/$project_disc_dir/targeted_capture_sequencing/current/L3";
            print "Found Disc TCS $disc_tcs_data_dir\n" if -d $disc_tcs_data_dir;
            my $vald_tcs_data_dir = "/local/\L$program_name\E/data/$project_vald_dir/targeted_capture_sequencing/current/L3";
            print "Found Vald TCS $vald_tcs_data_dir\n" if -d $vald_tcs_data_dir;
            my $disc_rna_data_dir = "/local/\L$program_name\E/data/$project_disc_dir/mRNA-seq/current/L3";
            print "Found Disc RNA $disc_rna_data_dir\n" if -d $disc_rna_data_dir;
            if ($data_type eq 'WGS') {
                # CGI WGS
                if (-d "$disc_dataset_dir/$cgi_dir_name") {
                    my $cgi_dataset_dir = "$disc_dataset_dir/$cgi_dir_name";
                    my @cgi_data_dirs;
                    for my $dir_name (@cgi_data_dir_names) {
                        my $cgi_data_dir = "$cgi_dataset_dir/$dir_name";
                        push @cgi_data_dirs, $cgi_data_dir if -d $cgi_data_dir;
                    }
                    if ($debug{all} or $debug{cgi}) {
                        print STDERR "\@cgi_data_dirs:\n", Dumper(\@cgi_data_dirs);
                    }
                    my $maf_type = 'CGI';
                    my $cgi_somatic_maf_regexp = $use_cgi_filtered_mafs
                        ? qr/^somatic_filtered_data_only$/i
                        : qr/^somaticVcfBeta.+?somatic_maf.*?\.txt$/i;
                    my %maf_out_file_names_by_type;
                    print "Scanning $cgi_dataset_dir\n";
                    find({
                        follow => 1,
                        wanted => sub {
                            # directories
                            if (-d) {
                                my $dir_name = $_;
                                # skip "old_data" subdirectory trees
                                # skip "VCF_files_without_FET" subdirectory trees
                                if ($dir_name =~ /(old_data|VCF_files_without_FET)/i) {
                                    #print "Skipping $File::Find::name\n" if $verbose;
                                    $File::Find::prune = 1;
                                    return;
                                }
                                # TARGET case-named directories (with possible CGI numeric extension)
                                elsif ($dir_name =~ /^$CGI_CASE_DIR_REGEXP$/) {
                                    my ($case_id) = $dir_name =~ /^($CASE_REGEXP)/;
                                    my @case_id_parts = split('-', $case_id);
                                    my $s_case_id = $case_id_parts[$#case_id_parts];
                                    # if analyzing specific cases prune tree if not in list
                                    if (defined $user_params{cases} and !exists $user_params{cases}{uc($s_case_id)}) {
                                        $File::Find::prune = 1;
                                        return;
                                    }
                                }
                                # TARGET barcode-named directories
                                #elsif ($dir_name =~ /^$BARCODE_REGEXP$/) {
                                #    
                                #}
                            }
                            # files
                            elsif (-f) {
                                my $file_name = $_;
                                # CGI somatic MAFs
                                if ($file_name =~ /$cgi_somatic_maf_regexp/) {
                                    my @dir_parts = File::Spec->splitdir($File::Find::dir);
                                    my ($case_dir_name) = grep { m/^$CGI_CASE_DIR_REGEXP$/ } @dir_parts;
                                    my $case_exp_dir = File::Spec->catdir(@dir_parts[0 .. $#dir_parts - 2]);
                                    my ($disease_barcode) = grep { m/^$BARCODE_REGEXP$/ } @dir_parts;
                                    # determine comparator
                                    if ($dir_parts[$#dir_parts] ne 'ASM' or
                                        $dir_parts[$#dir_parts - 2] ne 'EXP') {
                                        die "ERROR: invalid CGI sample directory path: $File::Find::dir";
                                    }
                                    if ($debug{all} or $debug{cgi}) {
                                        print STDERR "\$case_exp_dir:\n$case_exp_dir\n";
                                    }
                                    my @other_sample_dirs = 
                                        grep {
                                            -d and 
                                            m/^$case_exp_dir\/$BARCODE_REGEXP$/ and 
                                            $_ ne "$case_exp_dir/$dir_parts[$#dir_parts - 1]"
                                        } glob("$case_exp_dir/*");
                                    if ($debug{all} or $debug{cgi}) {
                                        print STDERR "\@other_sample_dirs:\n", Dumper(\@other_sample_dirs);
                                    }
                                    my ($normal_barcode, $normal_sample_dir);
                                    if (scalar(@other_sample_dirs) > 1) {
                                        my @other_normal_sample_dirs;
                                        for my $other_sample_dir (@other_sample_dirs) {
                                            my @other_sample_dir_parts = File::Spec->splitdir($other_sample_dir);
                                            my $barcode = $other_sample_dir_parts[$#other_sample_dir_parts];
                                            if (get_barcode_info($barcode)->{tissue_type} =~ /Normal/) {
                                                push @other_normal_sample_dirs, $other_sample_dir;
                                            }
                                        }
                                        if (scalar(@other_normal_sample_dirs) == 1) {
                                            $normal_sample_dir = $other_normal_sample_dirs[0];
                                            my @normal_sample_dir_parts = File::Spec->splitdir($normal_sample_dir);
                                            $normal_barcode = $normal_sample_dir_parts[$#normal_sample_dir_parts];
                                        }
                                        else {
                                            die "ERROR: could not determine comparator sample directory in $case_exp_dir";
                                        }
                                    }
                                    elsif (scalar(@other_sample_dirs) == 1) {
                                        $normal_sample_dir = $other_sample_dirs[0];
                                        my @normal_sample_dir_parts = File::Spec->splitdir($normal_sample_dir);
                                        $normal_barcode = $normal_sample_dir_parts[$#normal_sample_dir_parts];
                                    }
                                    else {
                                        die "ERROR: sample directories missing in $case_exp_dir";
                                    }
                                    if ($debug{all} or $debug{cgi}) {
                                        print STDERR "\$normal_sample_dir:\n$normal_sample_dir\n";
                                    }
                                    if (!-d "$normal_sample_dir/ASM") {
                                        die "ERROR: invalid sample data directory: $normal_sample_dir";
                                    }
                                    if (
                                        grep { -f and m/^$normal_sample_dir\/ASM\/somaticVcfBeta/i }
                                        glob("$normal_sample_dir/ASM/*")
                                    ) {
                                        die "ERROR: comparator sample data directory contains somatic data: $normal_sample_dir/ASM";
                                    }
                                    if ($debug{all} or $debug{cgi}) {
                                        print STDERR "\$disease_barcode: $disease_barcode\n\$normal_barcode: $normal_barcode\n";
                                    }
                                    my $ver_data_hashref = get_verification_data(
                                        $disease_barcode, $normal_barcode,
                                        $disc_tcs_data_dir, $vald_tcs_data_dir, $disc_rna_data_dir,
                                    );
                                    my (%maf_out_data_by_type, @maf_col_headers, %maf_col_idx_by_name, 
                                        @splice_col_offsets, $maf_num_orig_cols);
                                    print "Parsing ", File::Spec->abs2rel($File::Find::name, $cgi_dataset_dir), "\n" if $verbose;
                                    open(my $maf_in_fh, '<', $File::Find::name)
                                        or die "ERROR: could not open $File::Find::name";
                                    while (<$maf_in_fh>) {
                                        s/\s+$//;
                                        if (!m/^#/ and !@maf_col_headers) {
                                            @maf_col_headers = split /\t/;
                                            for (@maf_col_headers) {
                                                s/^\s+//;
                                                s/\s+$//;
                                            }
                                            $maf_num_orig_cols = scalar(@maf_col_headers);
                                            # insert new columns before tumor_ref_count
                                            push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'tumor_ref_count'} } @maf_col_headers;
                                            splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'ver_ref_allele'};
                                            push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'tumor_ref_count'} } @maf_col_headers;
                                            splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'ver_tumor_allele_1'};
                                            push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'tumor_ref_count'} } @maf_col_headers;
                                            splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'ver_tumor_allele_2'};
                                            push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'tumor_ref_count'} } @maf_col_headers;
                                            splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'ver_norm_allele_1'};
                                            push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'tumor_ref_count'} } @maf_col_headers;
                                            splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'ver_norm_allele_2'};
                                            push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'tumor_ref_count'} } @maf_col_headers;
                                            splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'ver_vcf_filter'};
                                            # insert tumor_var_ratio before norm_ref_count
                                            push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'norm_ref_count'} } @maf_col_headers;
                                            splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'tumor_var_ratio'};
                                            # insert norm_var_ratio at end
                                            push @splice_col_offsets, scalar(@maf_col_headers);
                                            splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'norm_var_ratio'};
                                            %maf_col_idx_by_name = map { $maf_col_headers[$_] => $_ } 0 .. $#maf_col_headers;
                                            if ($debug{all} or $debug{maf_parse}) {
                                                print STDERR "\@maf_col_headers:\n", Dumper(\@maf_col_headers), "\n",
                                                             "\%maf_col_idx_by_name:\n", Dumper(\%maf_col_idx_by_name);
                                            }
                                        }
                                        elsif (@maf_col_headers) {
                                            my @maf_row_data = split /\t/;
                                            for (@maf_row_data) {
                                                s/^\s+//;
                                                s/\s+$//;
                                            }
                                            # make sure data matrix is rectangular by appending blank missing fields if necessary
                                            if (scalar(@maf_row_data) < $maf_num_orig_cols) {
                                                push @maf_row_data, ($maf_conf{$maf_type}{'blank_val'}) x ( $maf_num_orig_cols - scalar(@maf_row_data) );
                                            }
                                            elsif (scalar(@maf_row_data) > $maf_num_orig_cols) {
                                                die "ERROR: ", scalar(@maf_row_data), " data fields more than ",
                                                               $maf_num_orig_cols, " column headers at line $.";
                                            }
                                            # insert new blank data fields
                                            for my $splice_col_offset (@splice_col_offsets) {
                                                splice @maf_row_data, $splice_col_offset, 0, ($maf_conf{$maf_type}{'blank_val'}) x 1;
                                            }
                                            # skip any mutations without a gene symbol
                                            #next unless defined $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'gene_symbol'}}] and
                                            #                    $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'gene_symbol'}}] ne $maf_conf{$maf_type}{'blank_val'};
                                            # skip any INTRON/UTR/UTR3/UTR5/TSS-UPSTREAM mutations
                                            #next unless defined $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'variant_class'}}] and
                                            #                    $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'variant_class'}}] ne $maf_conf{$maf_type}{'blank_val'};
                                            #my $valid_variant_classification;
                                            #for my $variant_classification (split /[|,]/, $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'variant_class'}}]) {
                                            #    $variant_classification =~ s/\s+//g;
                                            #    if ($variant_classification !~ /^(INTRON|UTR(3|5)?|TSS-UPSTREAM)$/i) {
                                            #        $valid_variant_classification++;
                                            #        last;
                                            #    }
                                            #}
                                            #next unless $valid_variant_classification;
                                            if (verify_maf_line($maf_type, \@maf_row_data, \%maf_col_idx_by_name, $ver_data_hashref)) {
                                                push @{$maf_out_data_by_type{verified}}, \@maf_row_data;
                                            }
                                            elsif (!$no_unverified) {
                                                push @{$maf_out_data_by_type{unverified}}, \@maf_row_data;
                                            }
                                        }
                                        else {
                                            die "ERROR: invalid MAF line $.";
                                        }
                                    }
                                    close($maf_in_fh);
                                    my $case_id = get_barcode_info($disease_barcode)->{case_id};
                                    if ($case_dir_name =~ /(?:-|_)(\d+)$/) {
                                        $case_id .= "-$1";
                                    }
                                    my $disease_tissue_type = get_barcode_info($disease_barcode)->{tissue_type};
                                    my $normal_tissue_type = get_barcode_info($normal_barcode)->{tissue_type};
                                    if (!-d $dataset_output_dir) {
                                        make_path($dataset_output_dir, { chmod => 0700 })
                                            or die "ERROR: could not create $dataset_output_dir: $!\n";
                                    }
                                    for my $type (qw(verified unverified)) {
                                        next if $type eq 'unverified' and $no_unverified;
                                        if (defined $maf_out_data_by_type{$type}) {
                                            my $maf_out_file_name = 
                                                "${type}Somatic" . 
                                                ($use_cgi_filtered_mafs ? 'Filtered' : '') .
                                                "Maf_${case_id}_${normal_tissue_type}Vs${disease_tissue_type}.maf.txt";
                                            if (!-f "$dataset_output_dir/$maf_out_file_name") {
                                                push @{$maf_out_file_names_by_type{$type}}, $maf_out_file_name;
                                                if ($verbose) {
                                                    print "Writing $maf_out_file_name\n";
                                                }
                                                open(my $maf_out_fh, '>', "$dataset_output_dir/$maf_out_file_name")
                                                    or die "ERROR: could not create $dataset_output_dir/$maf_out_file_name: $!";
                                                print $maf_out_fh join("\t", @maf_col_headers), "\n";
                                                for my $data_row_arrayref (@{$maf_out_data_by_type{$type}}) {
                                                    print $maf_out_fh join("\t", @{$data_row_arrayref}), "\n";
                                                }
                                                close($maf_out_fh);
                                            }
                                            else {
                                                die "ERROR: $dataset_output_dir/$maf_out_file_name already exists";
                                            }
                                        }
                                        elsif ($verbose) {
                                            print "No $type data\n";
                                        }
                                    }
                                }
                            }
                        },
                    }, @cgi_data_dirs);
                    my %merged_maf_out_data_by_type;
                    for my $type (qw(verified unverified)) {
                        next if $type eq 'unverified' and $no_unverified;
                        if (defined $maf_out_file_names_by_type{$type}) {
                            my $merged_maf_out_file_name = 
                                "${type}Somatic" . 
                                ($use_cgi_filtered_mafs ? 'Filtered' : '') .
                                "Maf_${program_name}_${project_name}_${data_type}_${cgi_dir_name}.maf.txt";
                            if ($verbose and ($type eq 'verified' or $use_cgi_filtered_mafs)) {
                                print "Generating $merged_maf_out_file_name\n";
                            }
                            my (@maf_col_headers, %maf_col_idx_by_name);
                            for my $maf_file_name (@{$maf_out_file_names_by_type{$type}}) {
                                # case ID is 2nd term in file name (above)
                                my $case_id = (split('_', $maf_file_name))[1];
                                open(my $maf_in_fh, '<', "$dataset_output_dir/$maf_file_name")
                                    or die "ERROR: could not open $dataset_output_dir/$maf_file_name";
                                if (!@maf_col_headers) {
                                    chomp(@maf_col_headers = split /\t/, <$maf_in_fh>);
                                    %maf_col_idx_by_name = map { $maf_col_headers[$_] => $_ } 0 .. $#maf_col_headers;
                                }
                                else {
                                    <$maf_in_fh>;
                                }
                                while (<$maf_in_fh>) {
                                    chomp;
                                    my @maf_row_data = split /\t/;
                                    if ($type eq 'verified') {
                                        my $tumor_barcode  = $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'tumor_barcode'}}];
                                        my $normal_barcode = $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'norm_barcode'}}];
                                        my $chr            = $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'chr'}}];
                                        my $start_pos      = $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'pos'}}];
                                        my $end_pos        = $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'end_pos'}}];
                                        if (!exists $merged_maf_out_data_by_type{$type}{"$tumor_barcode:$normal_barcode:$chr:$start_pos:$end_pos"}) {
                                            $merged_maf_out_data_by_type{$type}{"$tumor_barcode:$normal_barcode:$chr:$start_pos:$end_pos"} = \@maf_row_data;
                                        }
                                        # handle duplicate CGI mutation data
                                        else {
                                            my @new_ver_methods = split(
                                                $maf_sep_char, 
                                                $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'ver_method'}}]
                                            );
                                            my @existing_ver_methods = split(
                                                $maf_sep_char,
                                                $merged_maf_out_data_by_type{$type}{
                                                    "$tumor_barcode:$normal_barcode:$chr:$start_pos:$end_pos"
                                                }[$maf_col_idx_by_name{$maf_conf{$maf_type}{'ver_method'}}]
                                            );
                                            # replace with new row if has more verification methods or if same 
                                            # replace with new row if from CGI case directory with extension (newer)
                                            if (
                                                (
                                                    scalar(@new_ver_methods) > scalar(@existing_ver_methods)
                                                ) or
                                                (
                                                    scalar(@new_ver_methods) == scalar(@existing_ver_methods) and
                                                    $case_id =~ /-\d+$/
                                                )
                                            ) {
                                                $merged_maf_out_data_by_type{$type}{"$tumor_barcode:$normal_barcode:$chr:$start_pos:$end_pos"} = \@maf_row_data;
                                            }
                                        }
                                    }
                                    elsif ($use_cgi_filtered_mafs) {
                                        push @{$merged_maf_out_data_by_type{$type}}, \@maf_row_data;
                                    }
                                }
                                close($maf_in_fh);
                                my $merged_maf_out_fh;
                                if ($type eq 'verified' or $use_cgi_filtered_mafs) {
                                    open($merged_maf_out_fh, '>', "$dataset_output_dir/$merged_maf_out_file_name")
                                        or die "ERROR: could not create $dataset_output_dir/$merged_maf_out_file_name: $!";
                                    print $merged_maf_out_fh join("\t", @maf_col_headers), "\n";
                                }
                                if ($type eq 'verified') {
                                    for my $maf_key (natsort keys %{$merged_maf_out_data_by_type{$type}}) {
                                        print $merged_maf_out_fh join("\t", @{$merged_maf_out_data_by_type{$type}{$maf_key}}), "\n";
                                    }
                                }
                                elsif ($use_cgi_filtered_mafs) {
                                    for my $data_row_arrayref (@{$merged_maf_out_data_by_type{$type}}) {
                                        print $merged_maf_out_fh join("\t", @{$data_row_arrayref}), "\n";
                                    }
                                }
                                close($merged_maf_out_fh) if defined $merged_maf_out_fh;
                            }
                        }
                    }
                }
                # BCCA WGS
                else {
                    
                }
            }
            # WXS
            elsif ($data_type eq 'WXS') {
                my %maf_out_file_names_by_type;
                print "Scanning $disc_dataset_dir/L3\n";
                find({
                    follow => 1,
                    wanted => sub {
                        # files only
                        return unless -f;
                        my $file_name = $_;
                        if (any { $file_name eq $_ } @{$program_project_conf{$program_name}{$project_name}{$data_type}{L3}{parse_files}}) {
                            my $maf_type = 'BCM';
                            my ($ver_data_hashref, %maf_out_data_by_type, @maf_col_headers, 
                                %maf_col_idx_by_name, @splice_col_offsets, $maf_num_orig_cols);
                            print "Parsing ", File::Spec->abs2rel($File::Find::name, "$disc_dataset_dir/L3"), "\n" if $verbose;
                            # txt maf
                            if ($file_name =~ /\.txt$/i) {
                                open(my $maf_in_fh, '<', $File::Find::name)
                                    or die "ERROR: could not open $File::Find::name";
                                while (<$maf_in_fh>) {
                                    s/\s+$//;
                                    if (!m/^#/ and !@maf_col_headers) {
                                        @maf_col_headers = split /\t/;
                                        for (@maf_col_headers) {
                                            s/^\s+//;
                                            s/\s+$//;
                                        }
                                        $maf_num_orig_cols = scalar(@maf_col_headers);
                                        # insert ver_ref_allele column before ver_tumor_allele_1 column
                                        push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'ver_tumor_allele_1'} } @maf_col_headers;
                                        splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'ver_ref_allele'};
                                        # insert ver_vcf_filter column before ver_status column
                                        push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'ver_status'} } @maf_col_headers;
                                        splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'ver_vcf_filter'};
                                        # insert tumor_ref_count column before tumor_var_count column
                                        push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'tumor_var_count'} } @maf_col_headers;
                                        splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'tumor_ref_count'};
                                        # insert norm_ref_count column before norm_var_count column
                                        push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'norm_var_count'} } @maf_col_headers;
                                        splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'norm_ref_count'};
                                        %maf_col_idx_by_name = map { $maf_col_headers[$_] => $_ } 0 .. $#maf_col_headers;
                                        if ($debug{all} or $debug{maf_parse}) {
                                            print STDERR "\@maf_col_headers:\n", Dumper(\@maf_col_headers), "\n",
                                                         "\%maf_col_idx_by_name:\n", Dumper(\%maf_col_idx_by_name);
                                        }
                                    }
                                    elsif (@maf_col_headers) {
                                        my @maf_row_data = split /\t/;
                                        for (@maf_row_data) {
                                            s/^\s+//;
                                            s/\s+$//;
                                        }
                                        # make sure data matrix is rectangular by adding blank missing fields if necessary
                                        if (scalar(@maf_row_data) < $maf_num_orig_cols) {
                                            push @maf_row_data, ($maf_conf{$maf_type}{'blank_val'}) x ( $maf_num_orig_cols - scalar(@maf_row_data) );
                                        }
                                        elsif (scalar(@maf_row_data) > $maf_num_orig_cols) {
                                            die "ERROR: ", scalar(@maf_row_data), " data fields more than ",
                                                           $maf_num_orig_cols, " column headers at line $.";
                                        }
                                        # insert new blank data fields
                                        for my $splice_col_offset (@splice_col_offsets) {
                                            splice @maf_row_data, $splice_col_offset, 0, ($maf_conf{$maf_type}{'blank_val'}) x 1;
                                        }
                                        my $disease_barcode = $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'tumor_barcode'}}];
                                        my $normal_barcode = $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'norm_barcode'}}];
                                        # if analyzing specific cases skip case if not in list
                                        if (defined $user_params{cases} and 
                                           !exists $user_params{cases}{uc(get_barcode_info($disease_barcode)->{s_case_id})}) {
                                            next;
                                        }
                                        if (!defined $ver_data_hashref or 
                                            $disease_barcode ne $ver_data_hashref->{disease_barcode} or
                                            $normal_barcode ne $ver_data_hashref->{normal_barcode}) {
                                            # free up memory
                                            $ver_data_hashref = undef;
                                            $ver_data_hashref = get_verification_data(
                                                $disease_barcode, $normal_barcode,
                                                $disc_tcs_data_dir, $vald_tcs_data_dir, $disc_rna_data_dir,
                                            );
                                        }
                                        if (verify_maf_line($maf_type, \@maf_row_data, \%maf_col_idx_by_name, $ver_data_hashref)) {
                                            push @{$maf_out_data_by_type{verified}}, \@maf_row_data;
                                        }
                                        else {
                                            push @{$maf_out_data_by_type{unverified}}, \@maf_row_data;
                                        }
                                    }
                                    else {
                                        die "ERROR: invalid MAF line $.";
                                    }
                                }
                                close($maf_in_fh);
                            }
                            # xls/xlsx maf
                            elsif ($file_name =~ /\.xlsx?$/i) {
                                my $maf_workbook = ReadData(
                                    $File::Find::name, 
                                    cells => 0, attr => 0, strip => 3,
                                ) or die "ERROR: could not open $File::Find::name: $!";
                                if ($maf_workbook->[0]->{sheets} != 1) {
                                    die "ERROR: xls/xlsx data file doesn't have one worksheet";
                                }
                                if ($debug{all} or $debug{maf_xls}) {
                                    print STDERR "\$maf_workbook:\n", Dumper($maf_workbook);
                                }
                                my $maf_sheet = $maf_workbook->[$maf_workbook->[0]->{sheets}];
                                # Spreadsheet::Read row/col cell numbers start at 1
                                @maf_col_headers = cellrow($maf_sheet, 1);
                                $maf_num_orig_cols = scalar(@maf_col_headers);
                                # insert ver_ref_allele column header before ver_tumor_allele_1 column
                                push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'ver_tumor_allele_1'} } @maf_col_headers;
                                splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'ver_ref_allele'};
                                # insert ver_vcf_filter column header before ver_status column
                                push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'ver_status'} } @maf_col_headers;
                                splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'ver_vcf_filter'};
                                # insert tumor_ref_count column header before tumor_var_count column
                                push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'tumor_var_count'} } @maf_col_headers;
                                splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'tumor_ref_count'};
                                # insert norm_ref_count column header before norm_var_count column
                                push @splice_col_offsets, firstidx { $_ eq $maf_conf{$maf_type}{'norm_var_count'} } @maf_col_headers;
                                splice @maf_col_headers, $splice_col_offsets[$#splice_col_offsets], 0, $maf_conf{$maf_type}{'norm_ref_count'};
                                %maf_col_idx_by_name = map { $maf_col_headers[$_] => $_ } 0 .. $#maf_col_headers;
                                if ($debug{all} or $debug{maf_parse}) {
                                    print STDERR "\@maf_col_headers:\n", Dumper(\@maf_col_headers), "\n",
                                                 "\%maf_col_idx_by_name:\n", Dumper(\%maf_col_idx_by_name);
                                }
                                # get last row num
                                my $last_row_num;
                                for my $col_arrayref (@{$maf_sheet->{cell}}[1 .. $#{$maf_sheet->{cell}}]) {
                                    if (defined $last_row_num and $last_row_num != $#{$col_arrayref}) {
                                        die "ERROR: MAF has unequal row count";
                                    }
                                    else {
                                        $last_row_num = $#{$col_arrayref};
                                    }
                                }
                                # Spreadsheet::Read data rows start at 2 (after header row 1)
                                for my $row_num (2 .. $last_row_num) {
                                    # Spreadsheet::Read stores empty cells as undef so change to ''
                                    my @maf_row_data = map { defined() ? $_ : '' } cellrow($maf_sheet, $row_num);
                                    # make sure data matrix is rectangular by adding blank missing fields if necessary
                                    if (scalar(@maf_row_data) < $maf_num_orig_cols) {
                                        push @maf_row_data, ($maf_conf{$maf_type}{'blank_val'}) x ( $maf_num_orig_cols - scalar(@maf_row_data) );
                                    }
                                    elsif (scalar(@maf_row_data) > $maf_num_orig_cols) {
                                        die "ERROR: ", scalar(@maf_row_data), " data fields more than ",
                                                       $maf_num_orig_cols, " column headers at line $.";
                                    }
                                    # insert new blank data fields
                                    for my $splice_col_offset (@splice_col_offsets) {
                                        splice @maf_row_data, $splice_col_offset, 0, ($maf_conf{$maf_type}{'blank_val'}) x 1;
                                    }
                                    my $disease_barcode = $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'tumor_barcode'}}];
                                    my $normal_barcode = $maf_row_data[$maf_col_idx_by_name{$maf_conf{$maf_type}{'norm_barcode'}}];
                                    # if analyzing specific cases skip case if not in list
                                    if (defined $user_params{cases} and 
                                       !exists $user_params{cases}{uc(get_barcode_info($disease_barcode)->{s_case_id})}) {
                                        next;
                                    }
                                    if (!defined $ver_data_hashref or 
                                        $disease_barcode ne $ver_data_hashref->{disease_barcode} or
                                        $normal_barcode ne $ver_data_hashref->{normal_barcode}) {
                                        # free up memory
                                        $ver_data_hashref = undef;
                                        $ver_data_hashref = get_verification_data(
                                            $disease_barcode, $normal_barcode,
                                            $disc_tcs_data_dir, $vald_tcs_data_dir, $disc_rna_data_dir,
                                        );
                                    }
                                    if (verify_maf_line($maf_type, \@maf_row_data, \%maf_col_idx_by_name, $ver_data_hashref)) {
                                        push @{$maf_out_data_by_type{verified}}, \@maf_row_data;
                                    }
                                    else {
                                        push @{$maf_out_data_by_type{unverified}}, \@maf_row_data;
                                    }
                                }
                            }
                            else {
                                die "ERROR: invalid file type";
                            }
                            if (!-d $dataset_output_dir) {
                                make_path($dataset_output_dir, { chmod => 0700 }) 
                                    or die "ERROR: could not create $dataset_output_dir: $!\n";
                            }
                            my ($maf_basename, undef, $maf_ext) = fileparse($file_name, qr/\.\D*/);
                            $maf_ext =~ s/\.xlsx?$/.txt/;
                            my $sep_char = $file_name =~ /-/ ? '-' : '_';
                            for my $type (qw(verified unverified)) {
                                next if $type eq 'unverified' and $no_unverified;
                                if (defined $maf_out_data_by_type{$type}) {
                                    my $maf_out_file_name = "${maf_basename}${sep_char}${type}${maf_ext}";
                                    if (!-f "$dataset_output_dir/$maf_out_file_name") {
                                        push @{$maf_out_file_names_by_type{$type}}, $maf_out_file_name;
                                        if ($verbose) {
                                            print "Writing $maf_out_file_name\n";
                                        }
                                        open(my $maf_out_fh, '>', "$dataset_output_dir/$maf_out_file_name")
                                            or die "ERROR: could not create $dataset_output_dir/$maf_out_file_name: $!";
                                        print $maf_out_fh join("\t", @maf_col_headers), "\n";
                                        for my $data_row_arrayref (@{$maf_out_data_by_type{$type}}) {
                                            print $maf_out_fh join("\t", @{$data_row_arrayref}), "\n";
                                        }
                                        close($maf_out_fh);
                                    }
                                    else {
                                        die "ERROR: $dataset_output_dir/$maf_out_file_name already exists";
                                    }
                                }
                                elsif ($verbose) {
                                    print "No $type data\n";
                                }
                            }
                        }
                    },
                }, "$disc_dataset_dir/L3");
            }
        }
    }
}
exit;

sub get_verification_data {
    my ($disease_barcode, $normal_barcode,
        $disc_tcs_data_dir, $vald_tcs_data_dir, $disc_rna_data_dir) = @_;
    my ($case_id, $disease_tissue_code, $disease_tissue_type) =
        @{get_barcode_info($disease_barcode)}{qw( case_id tissue_code tissue_type )};
    my ($normal_tissue_code, $normal_tissue_type) =
        @{get_barcode_info($normal_barcode)}{qw( tissue_code tissue_type )};
    print "-> $case_id $disease_tissue_code vs $normal_tissue_code\n" if $verbose;
    my $disease_tissue_code_regexp = $disease_tissue_type eq 'Primary'
                                   ? qr/(?:01|03|05|06|09)/
                                   : $disease_tissue_type eq 'Recurrent'
                                   ? qr/(?:02|04|40|41|42)/
                                   : $disease_tissue_type =~ /Normal/
                                   ? qr/(?:10|11|13|14|15|16)/
                                   : die "ERROR: disease barcode $disease_barcode not valid";
    my $normal_tissue_code_regexp = $normal_tissue_type =~ /Normal/
                                   ? qr/(?:10|11|13|14|15|16)/
                                   : die "ERROR: normal barcode $normal_barcode not valid";
    my (@tcs_data_dirs, @rna_data_dirs);
    for my $tcs_data_dir ($disc_tcs_data_dir, $vald_tcs_data_dir) {
        push @tcs_data_dirs, $tcs_data_dir if -d $tcs_data_dir;
    }
    for my $rna_data_dir ($disc_rna_data_dir) {
        push @rna_data_dirs, $rna_data_dir if -d $rna_data_dir;
    }
    my $cache_file_suffix = !$conserve_memory ? '_i' : '';
    my $ver_data_hashref = {
        disease_barcode => $disease_barcode,
        normal_barcode => $normal_barcode,
    };
    for my $ver_data_file_type (@ver_data_file_types) {
        # do not load tcs snv maf data if tcs snv vcf data exists (saves memory)
        next if $ver_data_file_type =~ /^tcs_(tumor|normal)_snv_maf$/ and 
                defined $ver_data_hashref->{"tcs_$1_snv_vcf"};
        my $cache_file_prefix = $ver_data_file_type =~ /strelka/ 
                              ? "${disease_barcode}_${normal_barcode}" 
                              : $ver_data_file_type =~ /tumor/
                              ? $disease_barcode
                              : $ver_data_file_type =~ /normal/
                              ? $normal_barcode
                              : die "ERROR invalid data type $ver_data_file_type";
        my @search_dirs = $ver_data_file_type =~ /^tcs/
                        ? @tcs_data_dirs
                        : $ver_data_file_type =~ /^rna/
                        ? @rna_data_dirs
                        : die "ERROR invalid data type $ver_data_file_type";
        my $cache_file_name = "${cache_file_prefix}_${ver_data_file_type}${cache_file_suffix}.pls";
        if (!-f "$cache_dir/$cache_file_name" or $rebuild_cache) {
            my $tissue_code_regexp = $ver_data_file_type =~ /strelka/
                                   ? qr/(?:$disease_tissue_code|$normal_tissue_code)/
                                   : $ver_data_file_type =~ /tumor/
                                   ? qr/$disease_tissue_code/
                                   : $ver_data_file_type =~ /normal/
                                   ? qr/$normal_tissue_code/
                                   : die "ERROR: invalid data type $ver_data_file_type";
            my $tissue_code_expanded_regexp = $ver_data_file_type =~ /strelka/
                                            ? qr/(?:$disease_tissue_code_regexp|$normal_tissue_code_regexp)/
                                            : $ver_data_file_type =~ /tumor/
                                            ? qr/$disease_tissue_code_regexp/
                                            : $ver_data_file_type =~ /normal/
                                            ? qr/$normal_tissue_code_regexp/
                                            : die "ERROR: invalid data type $ver_data_file_type";
            my $ver_data_file_suffix_regexp = $ver_data_file_type =~ /^tcs_strelka_(snv|indel)_vcf$/
                                            ? qr/.+?\.somatic\.$1\.vcf(\.txt)?/
                                            : $ver_data_file_type =~ /^tcs_(tumor|normal)_(snv|indel)_vcf$/
                                            ? qr/.+?\.vcf(\.txt)?/
                                            : $ver_data_file_type =~ /maf$/
                                            ? qr/.+?\.maf(\.txt)?/
                                            : $ver_data_file_type =~ /rna_(tumor|normal)_indel_vcf$/
                                            ? qr/\.indel\.vcf(\.txt)?/
                                            : die "ERROR invalid data type $ver_data_file_type";
            my $ver_data_file_regexp = 
                $ver_data_file_type =~ /strelka/
                    ? qr/
                          $case_id-
                          $tissue_code_regexp
                          $BARCODE_END_REGEXP
                          _
                          $case_id-
                          $tissue_code_regexp
                          $BARCODE_END_REGEXP
                          $ver_data_file_suffix_regexp
                      /ix
                    : qr/
                          $case_id-
                          $tissue_code_regexp
                          $BARCODE_END_REGEXP
                          $ver_data_file_suffix_regexp
                      /ix;
            my $ver_data_file_expanded_regexp = 
                $ver_data_file_type =~ /strelka/
                    ? qr/
                          $case_id-
                          $tissue_code_expanded_regexp
                          $BARCODE_END_REGEXP
                          _
                          $case_id-
                          $tissue_code_expanded_regexp
                          $BARCODE_END_REGEXP
                          $ver_data_file_suffix_regexp
                      /ix
                    : qr/
                          $case_id-
                          $tissue_code_expanded_regexp
                          $BARCODE_END_REGEXP
                          $ver_data_file_suffix_regexp
                      /ix;
            my @ver_data_files = Path::Iterator::Rule->new->file->name(
                $ver_data_file_regexp
            )->all_fast(@search_dirs);
            if (!@ver_data_files) {
                @ver_data_files = Path::Iterator::Rule->new->file->name(
                    $ver_data_file_expanded_regexp
                )->all_fast(@search_dirs);
            }
            if (@ver_data_files) {
                # init
                $ver_data_hashref->{$ver_data_file_type} = {};
                for my $ver_data_file (@ver_data_files) {
                    add_mutation_file_data($ver_data_hashref, $ver_data_file_type, $ver_data_file);
                    if ($debug{all} or $debug{ver_data}) {
                        my $ver_data_file_name = fileparse($ver_data_file);
                        print STDERR "$ver_data_file_name\n" if -f STDERR;
                    }
                }
                if (!$no_cache) {
                    print "Caching $cache_file_name\n";
                    lock_nstore($ver_data_hashref->{$ver_data_file_type}, "$cache_dir/$cache_file_name")
                        or die "ERROR: could not serialize $cache_dir/$cache_file_name: $!";
                }
                if ($debug{all} or $debug{ver_data}) {
                    print STDERR Dumper($ver_data_hashref->{$ver_data_file_type});
                }
            }
            elsif ($verbose) {
                (my $ver_data_file_type_phrase = $ver_data_file_type) =~ s/_/ /g;
                $ver_data_file_type_phrase =~ s/(tcs|rna|maf|vcf)/\U$1/g;
                print "No $ver_data_file_type_phrase\n";
            }
        }
        else {
            print "Loading $cache_file_name\n";
            $ver_data_hashref->{$ver_data_file_type} = lock_retrieve("$cache_dir/$cache_file_name")
                or die "ERROR: could not deserialize $cache_dir/$cache_file_name: $!";
        }
    }
    return $ver_data_hashref;
}

sub verify_maf_line {
    my ($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $ver_data_hashref) = @_;
    my $save_line;
    # already verified somatic mutations
    if (
        (
         $maf_type eq 'CGI' and
         defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_status'}}] and
         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_status'}}]) eq lc($maf_conf{$maf_type}{'ver_status_val'})
        )
        or
        (
         defined $maf_conf{$maf_type}{'val_status'} and
         defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'val_status'}}] and
         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'val_status'}}]) eq lc($maf_conf{$maf_type}{'val_status_val'}) and
         defined $maf_conf{$maf_type}{'mut_status'} and
         defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'mut_status'}}] and
         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'mut_status'}}]) eq lc($maf_conf{$maf_type}{'mut_status_val'})
        )
    ) {
        $save_line++;
        if (
            defined $maf_conf{$maf_type}{'tumor_var_ratio'} and 
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_var_ratio'}}] eq $maf_conf{$maf_type}{'blank_val'} and
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}] ne $maf_conf{$maf_type}{'blank_val'} and
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}] ne $maf_conf{$maf_type}{'blank_val'}
        ) {
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_var_ratio'}}] =
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}] > 0
                    ? sprintf(
                        $count_ratio_format, 
                        $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}] /
                        $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}]
                      )
                    : 0;
        }
        if (
            defined $maf_conf{$maf_type}{'norm_var_ratio'} and
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'norm_var_ratio'}}] eq $maf_conf{$maf_type}{'blank_val'} and
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}] ne $maf_conf{$maf_type}{'blank_val'} and
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}] ne $maf_conf{$maf_type}{'blank_val'}
        ) {
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'norm_var_ratio'}}] =
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}] > 0
                    ? sprintf(
                        $count_ratio_format, 
                        $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}] /
                        $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}]
                      )
                    : 0;
        }
    }
    my $chr = $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'chr'}}];
    my $pos = $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'pos'}}];
    # snv
    if (uc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'variant_type'}}]) eq 'SNP') {
        #if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ref_allele'}}] or
        #             $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ref_allele'}}] eq $maf_conf{$maf_type}{'blank_val'}) {
        #    die 'ERROR: Reference_Allele field is empty';
        #}
        #elsif ($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ref_allele'}}] !~ /^(A|C|G|T)$/) {
        #    die "ERROR: Reference_Allele bad value '$maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ref_allele'}}]'";
        #}
        #for my $tumor_seq ($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_allele_1'}}],
        #                   $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{'$maf_conf{$maf_type}{'tumor_allele_2'}}]) {
        #    if (defined $tumor_seq and $tumor_seq ne $maf_conf{$maf_type}{'blank_val'} and $tumor_seq ne '?') {
        #        
        #    }
        #}
        #my $maf_snv;
        #if (defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_allele_1'}}] and
        #    $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_allele_1'}}] ne $maf_conf{$maf_type}{'blank_val'} and
        #    $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ref_allele'}}] ne '?'
        #    $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_allele_1'}}]) {
        #    $maf_snv = $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_allele_1'}}];
        #}
        #elsif (defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_allele_2'}}] and
        #       $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_allele_2'}}] ne $maf_conf{$maf_type}{'blank_val'} and
        #       $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ref_allele'}}] ne 
        #       $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_allele_2'}}]) {
        #    $maf_snv = $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'tumor_allele_2'}}];
        #}
        #else {
        #    die 'ERROR: could not determine SNV';
        #}
        # tcs strelka snv vcf
        if (
            my @tcs_strelka_snvs = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_strelka_snv_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_strelka_snv_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_strelka_snv_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_strelka_snv_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{tcs_strelka_snv_vcf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] eq $maf_conf{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] = "TCS";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] .= "${maf_sep_char}TCS";
            }
            my $data_to_insert_hashref;
            my $tcs_strelka_snv_col_idx_by_name_hashref = $ver_data_hashref->{tcs_strelka_snv_vcf}->{col_idx_by_name};
            for my $tcs_strelka_snv_arrayref (@tcs_strelka_snvs) {
                my @format_fields = split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'FORMAT'}]);
                my $tot_format_idx = firstidx { $_ eq 'DP' } @format_fields;
                die "ERROR: could not find format index for DP" if $tot_format_idx < 0;
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}, 
                    (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'TUMOR'}]))[$tot_format_idx];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}, 
                    (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'NORMAL'}]))[$tot_format_idx];
                my $ref_allele = $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'REF'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                if ($ref_allele =~ /,/) {
                    my ($tumor_ref_count, $normal_ref_count);
                    for my $ref_allele (split(',', $ref_allele)) {
                        my $ref_format_idx = firstidx { $_ eq "${ref_allele}U" } @format_fields;
                        die "ERROR: could not find format index for ${ref_allele}U" if $ref_format_idx < 0;
                        $tumor_ref_count += (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'TUMOR'}]))[$ref_format_idx]))[0];
                        $normal_ref_count += (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'NORMAL'}]))[$ref_format_idx]))[0];
                    }
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_ref_count'}}}, $tumor_ref_count;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_ref_count'}}}, $normal_ref_count;
                }
                else {
                    my $ref_format_idx = firstidx { $_ eq "${ref_allele}U" } @format_fields;
                    die "ERROR: could not find format index for ${ref_allele}U" if $ref_format_idx < 0;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_ref_count'}}}, 
                        (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'TUMOR'}]))[$ref_format_idx]))[0];
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_ref_count'}}}, 
                        (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'NORMAL'}]))[$ref_format_idx]))[0];
                }
                my $alt_allele = $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'ALT'}];
                if ($alt_allele ne '.') {
                    if ($alt_allele =~ /,/) {
                        my ($tumor_alt_count, $normal_alt_count);
                        for my $alt_allele (split(',', $alt_allele)) {
                            my $alt_format_idx = firstidx { $_ eq "${alt_allele}U" } @format_fields;
                            die "ERROR: could not find format index for ${alt_allele}U" if $alt_format_idx < 0;
                            $tumor_alt_count += (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'TUMOR'}]))[$alt_format_idx]))[0];
                            $normal_alt_count += (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'NORMAL'}]))[$alt_format_idx]))[0];
                        }
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}, $tumor_alt_count;
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}, $normal_alt_count;
                    }
                    else {
                        my $alt_format_idx = firstidx { $_ eq "${alt_allele}U" } @format_fields;
                        die "ERROR: could not find format index for ${alt_allele}U" if $alt_format_idx < 0;
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}, 
                            (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'TUMOR'}]))[$alt_format_idx]))[0];
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}, 
                            (split(',', (split(':', $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'NORMAL'}]))[$alt_format_idx]))[0];
                    }
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                }
                else {
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}, 0;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}, 0;
                }
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_vcf_filter'}}}, $tcs_strelka_snv_arrayref->[$tcs_strelka_snv_col_idx_by_name_hashref->{'FILTER'}];
                if (defined $maf_conf{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format, 
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
                if (defined $maf_conf{$maf_type}{'norm_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}]
                              )
                            : 0;
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
        # tcs tumor snv vcf
        if (
            my @tcs_tumor_snvs = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_tumor_snv_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_tumor_snv_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_tumor_snv_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_tumor_snv_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{tcs_tumor_snv_vcf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] eq $maf_conf{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] = "TCM";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] .= "${maf_sep_char}TCM";
            }
            my $data_to_insert_hashref;
            my $tcs_tumor_snv_col_idx_by_name_hashref = $ver_data_hashref->{tcs_tumor_snv_vcf}->{col_idx_by_name};
            for my $tcs_tumor_snv_arrayref (@tcs_tumor_snvs) {
                my %info_fields = map {
                    m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                } split(';', $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'INFO'}]);
                my @dp4_values = split(',', $info_fields{'DP4'});
                die 'ERROR: INFO field DP4 has only ', scalar(@dp4_values), ' values but should be 4' if scalar(@dp4_values) != 4;
                my $tumor_ref_count = sum(@dp4_values[0..1]);
                my $tumor_alt_count = sum(@dp4_values[2..3]);
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_ref_count'}}}, $tumor_ref_count;
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}, $tumor_alt_count;
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}, $tumor_ref_count + $tumor_alt_count;
                my $ref_allele = $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'REF'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                my $alt_allele = $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'ALT'}];
                if ($alt_allele ne '.') {
                    my @format_fields = split(':', $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'FORMAT'}]);
                    my $genotype_format_idx = firstidx { $_ eq 'GT' } @format_fields;
                    die "ERROR: could not find format index for GT" if $genotype_format_idx < 0;
                    # column name with genotype data is verification barcode (not fixed and not source barcode) 
                    # so can be messy so since we know it's last column just use array index
                    my $genotype = (split(':', $tcs_tumor_snv_arrayref->[$#{$tcs_tumor_snv_arrayref}]))[0];
                    if ($genotype eq '1/1') {
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_1'}}}, $alt_allele;
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                    }
                    elsif ($genotype eq '0/1') {
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_1'}}}, $ref_allele;
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                    }
                    else {
                        die "ERROR: genotype '$genotype' not supported";
                    }
                }
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_vcf_filter'}}}, $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'FILTER'}];
                if (defined $maf_conf{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
            }
            # tcs normal snv vcf
            if (
                my @tcs_normal_snvs = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_normal_snv_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_normal_snv_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_normal_snv_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_normal_snv_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{tcs_normal_snv_vcf}->{data}}
            ) {
                my $tcs_normal_snv_col_idx_by_name_hashref = $ver_data_hashref->{tcs_normal_snv_vcf}->{col_idx_by_name};
                for my $tcs_normal_snv_arrayref (@tcs_normal_snvs) {
                    my %info_fields = map {
                        m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                    } split(';', $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'INFO'}]);
                    my @dp4_values = split(',', $info_fields{'DP4'});
                    die 'ERROR: INFO field DP4 has only ', scalar(@dp4_values), ' values but should be 4' if scalar(@dp4_values) != 4;
                    my $norm_ref_count = sum(@dp4_values[0..1]);
                    my $norm_alt_count = sum(@dp4_values[2..3]);
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_ref_count'}}}, $norm_ref_count;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}, $norm_alt_count;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}, $norm_ref_count + $norm_alt_count;
                    my $ref_allele = $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'REF'}];
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                    my $alt_allele = $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'ALT'}];
                    if ($alt_allele ne '.') {
                        my @format_fields = split(':', $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'FORMAT'}]);
                        my $genotype_format_idx = firstidx { $_ eq 'GT' } @format_fields;
                        die "ERROR: could not find format index for GT" if $genotype_format_idx < 0;
                        # column name with genotype data is verification barcode (not fixed and not source barcode) 
                        # so can be messy so since we know it's last column just use array index
                        my $genotype = (split(':', $tcs_normal_snv_arrayref->[$#{$tcs_normal_snv_arrayref}]))[0];
                        if ($genotype eq '1/1') {
                            push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_1'}}}, $alt_allele;
                            push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_2'}}}, $alt_allele;
                        }
                        elsif ($genotype eq '0/1') {
                            push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_1'}}}, $ref_allele;
                            push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_2'}}}, $alt_allele;
                        }
                        else {
                            die "ERROR: genotype '$genotype' not supported";
                        }
                    }
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_vcf_filter'}}}, $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'FILTER'}];
                    if (defined $maf_conf{$maf_type}{'norm_var_ratio'}) {
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_ratio'}}},
                            $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}] > 0
                                ? sprintf(
                                    $count_ratio_format,
                                    $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}] /
                                    $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}]
                                  )
                                : 0;
                    }
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
        # tcs tumor snv maf
        elsif (
            @tcs_tumor_snvs = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_tumor_snv_maf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_tumor_snv_maf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_tumor_snv_maf}->{col_idx_by_name}->{'Chromosome'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_tumor_snv_maf}->{col_idx_by_name}->{'Start_Position'}]
                  } @{$ver_data_hashref->{tcs_tumor_snv_maf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] eq $maf_conf{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] = "TCM";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] .= "${maf_sep_char}TCM";
            }
            my $data_to_insert_hashref;
            my $tcs_tumor_snv_col_idx_by_name_hashref = $ver_data_hashref->{tcs_tumor_snv_maf}->{col_idx_by_name};
            for my $tcs_tumor_snv_arrayref (@tcs_tumor_snvs) {
                my $tumor_ref_count = $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Ref_Allele_Coverage'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_ref_count'}}}, $tumor_ref_count;
                my $tumor_alt_count =
                    $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Ref_Allele_Coverage'}] != 
                    $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele1_Coverage'}]
                        ? $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele1_Coverage'}]
                        : $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele2_Coverage'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}, $tumor_alt_count;
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}, $tumor_ref_count + $tumor_alt_count;
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_ref_allele'}}}, $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Reference_Allele'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_1'}}}, $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele1'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_2'}}}, $tcs_tumor_snv_arrayref->[$tcs_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele2'}];
                if (defined $maf_conf{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
            }
            # tcs normal snv maf
            if (
                my @tcs_normal_snvs = !$conserve_memory
                    ? exists $ver_data_hashref->{tcs_normal_snv_maf}->{data}->{"$chr:$pos"}
                        ? @{$ver_data_hashref->{tcs_normal_snv_maf}->{data}->{"$chr:$pos"}}
                        : ()
                    : grep {
                          $chr eq $_->[$ver_data_hashref->{tcs_normal_snv_maf}->{col_idx_by_name}->{'Chromosome'}] and 
                          $pos eq $_->[$ver_data_hashref->{tcs_normal_snv_maf}->{col_idx_by_name}->{'Start_Position'}]
                      } @{$ver_data_hashref->{tcs_normal_snv_maf}->{data}}
            ) {
                my $tcs_normal_snv_col_idx_by_name_hashref = $ver_data_hashref->{tcs_normal_snv_maf}->{col_idx_by_name};
                for my $tcs_normal_snv_arrayref (@tcs_normal_snvs) {
                    my $normal_ref_count = $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Normal_Ref_Allele_Coverage'}];
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_ref_count'}}}, $normal_ref_count;
                    my $normal_alt_count =
                        $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Normal_Ref_Allele_Coverage'}] != 
                        $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Normal_Seq_Allele1_Coverage'}]
                            ? $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Normal_Seq_Allele1_Coverage'}]
                            : $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Normal_Seq_Allele2_Coverage'}];
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}, $normal_alt_count;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}, $normal_ref_count + $normal_alt_count;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_1'}}}, $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Match_Norm_Seq_Allele1'}];
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_2'}}}, $tcs_normal_snv_arrayref->[$tcs_normal_snv_col_idx_by_name_hashref->{'Match_Norm_Seq_Allele2'}];
                    if (defined $maf_conf{$maf_type}{'norm_var_ratio'}) {
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_ratio'}}},
                            $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}] > 0
                                ? sprintf(
                                    $count_ratio_format,
                                    $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}] /
                                    $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}]
                                  )
                                : 0;
                    }
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
        # rna tumor snv maf
        if (
            my @rna_tumor_snvs = !$conserve_memory
                ? exists $ver_data_hashref->{rna_tumor_snv_maf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{rna_tumor_snv_maf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{rna_tumor_snv_maf}->{col_idx_by_name}->{'Chromosome'}] and 
                      $pos eq $_->[$ver_data_hashref->{rna_tumor_snv_maf}->{col_idx_by_name}->{'Start_Position'}]
                  } @{$ver_data_hashref->{rna_tumor_snv_maf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] eq $maf_conf{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] = "RNA";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] .= "${maf_sep_char}RNA";
            }
            my $data_to_insert_hashref;
            my $rna_tumor_snv_col_idx_by_name_hashref = $ver_data_hashref->{rna_tumor_snv_maf}->{col_idx_by_name};
            for my $rna_tumor_snv_arrayref (@rna_tumor_snvs) {
                my $tumor_ref_count = $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Ref_Allele_Coverage'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_ref_count'}}}, $tumor_ref_count;
                my $tumor_alt_count =
                    $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Ref_Allele_Coverage'}] != 
                    $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele1_Coverage'}]
                        ? $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele1_Coverage'}]
                        : $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele2_Coverage'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}, $tumor_alt_count;
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}, $tumor_ref_count + $tumor_alt_count;
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_ref_allele'}}}, $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Reference_Allele'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_1'}}}, $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele1'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_2'}}}, $rna_tumor_snv_arrayref->[$rna_tumor_snv_col_idx_by_name_hashref->{'Tumor_Seq_Allele2'}];
                if (defined $maf_conf{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
            }
            # rna normal snv maf
            if (
                my @rna_normal_snvs = !$conserve_memory
                    ? exists $ver_data_hashref->{rna_normal_snv_maf}->{data}->{"$chr:$pos"}
                        ? @{$ver_data_hashref->{rna_normal_snv_maf}->{data}->{"$chr:$pos"}}
                        : ()
                    : grep {
                          $chr eq $_->[$ver_data_hashref->{rna_normal_snv_maf}->{col_idx_by_name}->{'Chromosome'}] and 
                          $pos eq $_->[$ver_data_hashref->{rna_normal_snv_maf}->{col_idx_by_name}->{'Start_Position'}]
                      } @{$ver_data_hashref->{rna_normal_snv_maf}->{data}}
            ) {
                my $rna_normal_snv_col_idx_by_name_hashref = $ver_data_hashref->{rna_normal_snv_maf}->{col_idx_by_name};
                for my $rna_normal_snv_arrayref (@rna_normal_snvs) {
                    my $normal_ref_count = $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Normal_Ref_Allele_Coverage'}];
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_ref_count'}}}, $normal_ref_count;
                    my $normal_alt_count =
                        $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Normal_Ref_Allele_Coverage'}] != 
                        $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Normal_Seq_Allele1_Coverage'}]
                            ? $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Normal_Seq_Allele1_Coverage'}]
                            : $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Normal_Seq_Allele2_Coverage'}];
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}, $normal_alt_count;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}, $normal_ref_count + $normal_alt_count;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_1'}}}, $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Match_Norm_Seq_Allele1'}];
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_2'}}}, $rna_normal_snv_arrayref->[$rna_normal_snv_col_idx_by_name_hashref->{'Match_Norm_Seq_Allele2'}];
                    if (defined $maf_conf{$maf_type}{'norm_var_ratio'}) {
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_ratio'}}},
                            $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}] > 0
                                ? sprintf(
                                    $count_ratio_format,
                                    $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}] /
                                    $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}]
                                  )
                                : 0;
                    }
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
    }
    # indel
    elsif (uc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'variant_type'}}]) eq 'INS' or
           uc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'variant_type'}}]) eq 'DEL' or
           uc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'variant_type'}}]) eq 'SUB') {
        # tcs strelka indel vcf
        if (
            my @tcs_strelka_indels = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_strelka_indel_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_strelka_indel_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_strelka_indel_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_strelka_indel_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{tcs_strelka_indel_vcf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] eq $maf_conf{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] = "TCS";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] .= "${maf_sep_char}TCS";
            }
            my $data_to_insert_hashref;
            my $tcs_strelka_indel_col_idx_by_name_hashref = $ver_data_hashref->{tcs_strelka_indel_vcf}->{col_idx_by_name};
            for my $tcs_strelka_indel_arrayref (@tcs_strelka_indels) {
                my @format_fields = split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'FORMAT'}]);
                my $tot_format_idx = firstidx { $_ eq 'DP' } @format_fields;
                die "ERROR: could not find format index for DP" if $tot_format_idx < 0;
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}, 
                    (split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'TUMOR'}]))[$tot_format_idx];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}, 
                    (split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'NORMAL'}]))[$tot_format_idx];
                my $ref_allele = $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'REF'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                my $ref_format_idx = firstidx { $_ eq 'TAR' } @format_fields;
                die "ERROR: could not find format index for TAR" if $ref_format_idx < 0;
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_ref_count'}}}, 
                    (split(',', (split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'TUMOR'}]))[$ref_format_idx]))[0];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_ref_count'}}}, 
                    (split(',', (split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'NORMAL'}]))[$ref_format_idx]))[0];
                my $alt_allele = $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'ALT'}];
                if ($alt_allele ne '.') {
                    my $alt_format_idx = firstidx { $_ eq 'TIR' } @format_fields;
                    die "ERROR: could not find format index for TAR" if $alt_format_idx < 0;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}, 
                        (split(',', (split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'TUMOR'}]))[$alt_format_idx]))[0];
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}, 
                        (split(',', (split(':', $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'NORMAL'}]))[$alt_format_idx]))[0];
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                }
                else {
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}, 0;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}, 0;
                }
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_vcf_filter'}}}, $tcs_strelka_indel_arrayref->[$tcs_strelka_indel_col_idx_by_name_hashref->{'FILTER'}];
                if (defined $maf_conf{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
                if (defined $maf_conf{$maf_type}{'norm_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}]
                              )
                            : 0;
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
        # tcs tumor indel vcf
        if (
            my @tcs_tumor_indels = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_tumor_indel_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_tumor_indel_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_tumor_indel_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_tumor_indel_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{tcs_tumor_indel_vcf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] eq $maf_conf{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] = "TCM";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] .= "${maf_sep_char}TCM";
            }
            my $data_to_insert_hashref;
            my $tcs_tumor_indel_col_idx_by_name_hashref = $ver_data_hashref->{tcs_tumor_indel_vcf}->{col_idx_by_name};
            for my $tcs_tumor_indel_arrayref (@tcs_tumor_indels) {
                my %info_fields = map {
                    m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                } split(';', $tcs_tumor_indel_arrayref->[$tcs_tumor_indel_col_idx_by_name_hashref->{'INFO'}]);
                my @dp4_values = split(',', $info_fields{'DP4'});
                die 'ERROR: INFO field DP4 has only ', scalar(@dp4_values), ' values but should be 4' if scalar(@dp4_values) != 4;
                my $tumor_ref_count = sum(@dp4_values[0..1]);
                my $tumor_alt_count = sum(@dp4_values[2..3]);
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_ref_count'}}}, $tumor_ref_count;
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}, $tumor_alt_count;
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}, $tumor_ref_count + $tumor_alt_count;
                my $ref_allele = $tcs_tumor_indel_arrayref->[$tcs_tumor_indel_col_idx_by_name_hashref->{'REF'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                my $alt_allele = $tcs_tumor_indel_arrayref->[$tcs_tumor_indel_col_idx_by_name_hashref->{'ALT'}];
                if ($alt_allele ne '.') {
                    my @format_fields = split(':', $tcs_tumor_indel_arrayref->[$tcs_tumor_indel_col_idx_by_name_hashref->{'FORMAT'}]);
                    my $genotype_format_idx = firstidx { $_ eq 'GT' } @format_fields;
                    die "ERROR: could not find format index for GT" if $genotype_format_idx < 0;
                    # column name with genotype data is verification barcode (not fixed and not source barcode) 
                    # so can be messy so since we know it's last column just use array index
                    my $genotype = (split(':', $tcs_tumor_indel_arrayref->[$#{$tcs_tumor_indel_arrayref}]))[0];
                    if ($genotype eq '1/1') {
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_1'}}}, $alt_allele;
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                    }
                    elsif ($genotype eq '0/1') {
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_1'}}}, $ref_allele;
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                    }
                    else {
                        die "ERROR: genotype '$genotype' not supported";
                    }
                }
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_vcf_filter'}}}, $tcs_tumor_indel_arrayref->[$tcs_tumor_indel_col_idx_by_name_hashref->{'FILTER'}];
                if (defined $maf_conf{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
            }
            # tcs normal indel vcf
            if (
                my @tcs_normal_indels = !$conserve_memory
                ? exists $ver_data_hashref->{tcs_normal_indel_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{tcs_normal_indel_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{tcs_normal_indel_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{tcs_normal_indel_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{tcs_normal_indel_vcf}->{data}}
            ) {
                my $tcs_normal_indel_col_idx_by_name_hashref = $ver_data_hashref->{tcs_normal_indel_vcf}->{col_idx_by_name};
                for my $tcs_normal_indel_arrayref (@tcs_normal_indels) {
                    my %info_fields = map {
                        m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                    } split(';', $tcs_normal_indel_arrayref->[$tcs_normal_indel_col_idx_by_name_hashref->{'INFO'}]);
                    my @dp4_values = split(',', $info_fields{'DP4'});
                    die 'ERROR: INFO field DP4 has only ', scalar(@dp4_values), ' values but should be 4' if scalar(@dp4_values) != 4;
                    my $norm_ref_count = sum(@dp4_values[0..1]);
                    my $norm_alt_count = sum(@dp4_values[2..3]);
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_ref_count'}}}, $norm_ref_count;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}, $norm_alt_count;
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}, $norm_ref_count + $norm_alt_count;
                    my $ref_allele = $tcs_normal_indel_arrayref->[$tcs_normal_indel_col_idx_by_name_hashref->{'REF'}];
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                    my $alt_allele = $tcs_normal_indel_arrayref->[$tcs_normal_indel_col_idx_by_name_hashref->{'ALT'}];
                    if ($alt_allele ne '.') {
                        my @format_fields = split(':', $tcs_normal_indel_arrayref->[$tcs_normal_indel_col_idx_by_name_hashref->{'FORMAT'}]);
                        my $genotype_format_idx = firstidx { $_ eq 'GT' } @format_fields;
                        die "ERROR: could not find format index for GT" if $genotype_format_idx < 0;
                        # vcf column name is the verification barcode (not source barcode) can be messy so since we know it's last column just use array index
                        my $genotype = (split(':', $tcs_normal_indel_arrayref->[$#{$tcs_normal_indel_arrayref}]))[0];
                        if ($genotype eq '1/1') {
                            push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_1'}}}, $alt_allele;
                            push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_2'}}}, $alt_allele;
                        }
                        elsif ($genotype eq '0/1') {
                            push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_1'}}}, $ref_allele;
                            push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_2'}}}, $alt_allele;
                        }
                        else {
                            die "ERROR: genotype '$genotype' not supported";
                        }
                    }
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_vcf_filter'}}}, $tcs_normal_indel_arrayref->[$tcs_normal_indel_col_idx_by_name_hashref->{'FILTER'}];
                    if (defined $maf_conf{$maf_type}{'norm_var_ratio'}) {
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_ratio'}}},
                            $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}] > 0
                                ? sprintf(
                                    $count_ratio_format,
                                    $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}] /
                                    $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}]
                                  )
                                : 0;
                    }
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
        # rna tumor indel vcf
        if (
            my @rna_tumor_indels = !$conserve_memory
                ? exists $ver_data_hashref->{rna_tumor_indel_vcf}->{data}->{"$chr:$pos"}
                    ? @{$ver_data_hashref->{rna_tumor_indel_vcf}->{data}->{"$chr:$pos"}}
                    : ()
                : grep {
                      $chr eq $_->[$ver_data_hashref->{rna_tumor_indel_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                      $pos eq $_->[$ver_data_hashref->{rna_tumor_indel_vcf}->{col_idx_by_name}->{'POS'}]
                  } @{$ver_data_hashref->{rna_tumor_indel_vcf}->{data}}
        ) {
            $save_line++;
            if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] eq $maf_conf{$maf_type}{'blank_val'} or
                         lc($maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}]) eq 'none') {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] = "RNA";
            }
            else {
                $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_method'}}] .= "${maf_sep_char}RNA";
            }
            my $data_to_insert_hashref;
            my $rna_tumor_indel_col_idx_by_name_hashref = $ver_data_hashref->{rna_tumor_indel_vcf}->{col_idx_by_name};
            for my $rna_tumor_indel_arrayref (@rna_tumor_indels) {
                my %info_fields = map {
                    m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                } split(';', $rna_tumor_indel_arrayref->[$rna_tumor_indel_col_idx_by_name_hashref->{'INFO'}]);
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}, $info_fields{'MAX_SUPPORT'};
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}, $info_fields{'MAX_SUPPORT'};
                my $ref_allele = $rna_tumor_indel_arrayref->[$rna_tumor_indel_col_idx_by_name_hashref->{'REF'}];
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_ref_allele'}}}, $ref_allele;
                my $alt_allele = $rna_tumor_indel_arrayref->[$rna_tumor_indel_col_idx_by_name_hashref->{'ALT'}];
                if ($alt_allele ne '.') {
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_tumor_allele_2'}}}, $alt_allele;
                }
                push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_vcf_filter'}}}, $rna_tumor_indel_arrayref->[$rna_tumor_indel_col_idx_by_name_hashref->{'FILTER'}];
                if (defined $maf_conf{$maf_type}{'tumor_var_ratio'}) {
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_ratio'}}},
                        $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}] > 0
                            ? sprintf(
                                $count_ratio_format,
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_var_count'}}}] /
                                $data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'tumor_tot_count'}}}]
                              )
                            : 0;
                }
            }
            # rna normal indel vcf
            if (
                my @rna_normal_indels = !$conserve_memory
                    ? exists $ver_data_hashref->{rna_normal_indel_vcf}->{data}->{"$chr:$pos"}
                        ? @{$ver_data_hashref->{rna_normal_indel_vcf}->{data}->{"$chr:$pos"}}
                        : ()
                    : grep {
                          $chr eq $_->[$ver_data_hashref->{rna_normal_indel_vcf}->{col_idx_by_name}->{'CHROM'}] and 
                          $pos eq $_->[$ver_data_hashref->{rna_normal_indel_vcf}->{col_idx_by_name}->{'POS'}]
                      } @{$ver_data_hashref->{rna_normal_indel_vcf}->{data}}
            ) {
                my $rna_normal_indel_col_idx_by_name_hashref = $ver_data_hashref->{rna_normal_indel_vcf}->{col_idx_by_name};
                for my $rna_normal_indel_arrayref (@rna_normal_indels) {
                    my %info_fields = map {
                        m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                    } split(';', $rna_normal_indel_arrayref->[$rna_normal_indel_col_idx_by_name_hashref->{'INFO'}]);
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}, $info_fields{'MAX_SUPPORT'};
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}, $info_fields{'MAX_SUPPORT'};
                    my $alt_allele = $rna_normal_indel_arrayref->[$rna_normal_indel_col_idx_by_name_hashref->{'ALT'}];
                    if ($alt_allele ne '.') {
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_norm_allele_2'}}}, $alt_allele;
                    }
                    push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'ver_vcf_filter'}}}, $rna_normal_indel_arrayref->[$rna_normal_indel_col_idx_by_name_hashref->{'FILTER'}];
                    if (defined $maf_conf{$maf_type}{'norm_var_ratio'}) {
                        push @{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_ratio'}}},
                            $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}] > 0
                                ? sprintf(
                                    $count_ratio_format,
                                    $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_var_count'}}}] /
                                    $data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}[$#{$data_to_insert_hashref->{$maf_conf{$maf_type}{'norm_tot_count'}}}]
                                  )
                                : 0;
                    }
                }
            }
            insert_maf_data($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref);
        }
    }
    else {
        die "ERROR: unsupported variant type '$maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'variant_type'}}]'";
    }
    if ($save_line) {
        if (
            !defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_status'}}] or
                     $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_status'}}] eq $maf_conf{$maf_type}{'blank_val'} or
                     $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_status'}}] =~ /un(known|tested)/i
        ) {
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'ver_status'}}] = 
                $maf_conf{$maf_type}{'ver_status_val'};
        }
        if (
            defined $maf_conf{$maf_type}{'val_status'} and (
                !defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'val_status'}}] or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'val_status'}}] eq $maf_conf{$maf_type}{'blank_val'} or
                         $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'val_status'}}] =~ /un(known|tested)/i
                )
        ) {
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$maf_conf{$maf_type}{'val_status'}}] = 
                $maf_conf{$maf_type}{'val_status_val'};
        }
        if ($debug{ver_step}) {
            local $Data::Dumper::Indent = 0;
            print Dumper($maf_row_data_arrayref), "\n";
            <STDIN>;
        }
    }
    return $save_line;
}

sub get_barcode_info {
    my ($barcode) = @_;
    die "ERROR: invalid barcode '$barcode'" unless $barcode =~ /^$BARCODE_REGEXP$/;
    my ($case_id, $s_case_id, $sample_id, $disease_code, $tissue_code);
    my @barcode_parts = split('-', $barcode);
    # TARGET sample ID/barcode
    if (scalar(@barcode_parts) == 5) {
        $case_id = join('-', @barcode_parts[0..2]);
        $s_case_id = $barcode_parts[2];
        $sample_id = join('-', @barcode_parts[0..3]);
        ($disease_code, $tissue_code) = @barcode_parts[1,3];
    }
    # CGCI sample ID/barcode
    elsif (scalar(@barcode_parts) == 6) {
        $case_id = join('-', @barcode_parts[0..3]);
        $s_case_id = $barcode_parts[3];
        $sample_id = join('-', @barcode_parts[0..4]);
        ($disease_code, $tissue_code) = @barcode_parts[1,4];
    }
    else {
        die "ERROR: invalid sample ID/barcode $barcode";
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
                      # 06 is Metastatic but Primary for our purposes
                      $tissue_code eq '06' ? 'Primary' :
                      $tissue_code eq '09' ? 'Primary' :
                      $tissue_code eq '10' ? 'Normal' :
                      $tissue_code eq '11' ? 'Normal' :
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
    die "ERROR: unknown tissue code $tissue_code" unless defined $tissue_type;
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
    return {
        case_id => $case_id,
        s_case_id => $s_case_id,
        sample_id => $sample_id,
        disease_code => $disease_code,
        tissue_code => $tissue_code,
        tissue_type => $tissue_type,
        xeno_cell_line_code => $xeno_cell_line_code,
    };
}

sub add_mutation_file_data {
    my ($ver_data_hashref, $ver_data_file_type, $data_file) = @_;
    my $file_name = fileparse($data_file);
    my ($file_type) = $file_name =~ /\.(vcf|maf)(?:\.txt)?$/i;
    die "ERROR: invalid file type $file_name" unless $file_type;
    $file_type = lc($file_type);
    my $chr_col_name = $file_type eq 'maf' ? 'Chromosome'     : 'CHROM';
    my $pos_col_name = $file_type eq 'maf' ? 'Start_Position' : 'POS';
    my %col_idx_by_name;
    print "Loading $file_name\n" if $verbose;
    open(my $fh, '<', $data_file) or die "ERROR: could not open $data_file";
    while (<$fh>) {
        s/\s+$//;
        if (!%col_idx_by_name and (
            ($file_type eq 'maf' and !m/^#/) or
            ($file_type eq 'vcf' and m/^#(?!#)/) 
        )) {
            if ($file_type eq 'vcf') {
                s/^#//;
                if (!m/^CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO/) {
                    die "ERROR: invalid VCF column header:\n$_";
                }
            }
            my @col_headers = split /\t/;
            for (@col_headers) {
                s/^\s+//;
                s/\s+$//;
            }
            %col_idx_by_name = map { $col_headers[$_] => $_ } 0 .. $#col_headers;
            if (!defined $ver_data_hashref->{$ver_data_file_type} or
                !defined $ver_data_hashref->{$ver_data_file_type}->{col_idx_by_name}) {
                $ver_data_hashref->{$ver_data_file_type}->{col_idx_by_name} = \%col_idx_by_name;
            }
        }
        elsif (%col_idx_by_name) {
            my @row_data = split /\t/;
            for (@row_data) {
                s/^\s+//;
                s/\s+$//;
            }
            # for tcs mpileup vcfs with snv and indel data
            # in same file split up storage of variants
            if ($ver_data_file_type =~ /^tcs_(tumor|normal)_(snv|indel)_vcf$/) {
                my %info_fields = map {
                    m/=/ ? split('=', $_, 2) : ( $_ => 1 ) 
                } split(';', $row_data[$ver_data_hashref->{$ver_data_file_type}->{col_idx_by_name}->{'INFO'}]);
                next if (!exists $info_fields{'INDEL'} and $ver_data_file_type =~ /^tcs_(tumor|normal)_indel_vcf$/) or
                        ( exists $info_fields{'INDEL'} and $ver_data_file_type =~ /^tcs_(tumor|normal)_snv_vcf$/);
            }
            if (!$conserve_memory) {
                push @{$ver_data_hashref->{$ver_data_file_type}->{data}->{
                    "$row_data[$col_idx_by_name{$chr_col_name}]:$row_data[$col_idx_by_name{$pos_col_name}]"
                }}, \@row_data;
            }
            else {
                push @{$ver_data_hashref->{$ver_data_file_type}->{data}}, \@row_data;
            }
        }
        elsif (
            $file_type eq 'maf' or
            ($file_type eq 'vcf' and !m/^##/)
        ) {
            die "ERROR: invalid \U$file_type\E line $.";
        }
    }
    close($fh);
}

sub insert_maf_data {
    my ($maf_type, $maf_row_data_arrayref, $maf_col_idx_by_name_hashref, $data_to_insert_hashref) = @_;
    for my $col_name (keys %{$data_to_insert_hashref}) {
        my $field_str = 
            $col_name eq $maf_conf{$maf_type}{'ver_ref_allele'}
                ? (
                  scalar(@{$data_to_insert_hashref->{$col_name}}) > 1 and
                  scalar(keys(%{{ map { $_ => 1 } @{$data_to_insert_hashref->{$col_name}} }})) > 1
                )
                    ? join('/', @{$data_to_insert_hashref->{$col_name}})
                    : $data_to_insert_hashref->{$col_name}->[0]
                : scalar(@{$data_to_insert_hashref->{$col_name}}) > 1
                    ? join('/', @{$data_to_insert_hashref->{$col_name}})
                    : $data_to_insert_hashref->{$col_name}->[0];
        if (!defined $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$col_name}] or
                     $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$col_name}] eq $maf_conf{$maf_type}{'blank_val'}) {
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$col_name}] = $field_str;
        }
        else {
            $maf_row_data_arrayref->[$maf_col_idx_by_name_hashref->{$col_name}] .= "${maf_sep_char}${field_str}";
        }
    }
}

__END__

=head1 NAME 

generate_verified_somatic_mafs.pl - Generate Verified Somatic MAFs

=head1 SYNOPSIS

 generate_verified_somatic_mafs.pl [options] <program name(s)> <project name(s)> <data type(s)> <case(s)>
 
 Parameters:
    <program name(s)>           Comma-separated list of program name(s): TARGET, CGCI (optional, default: all programs)
    <project name(s)>           Comma-separated list of disease project name(s) (optional, default: all program projects)
    <data type(s)>              Comma-separated list of data type(s) (optional, default: all project data types)
    <case(s)>                   Comma-separated list of case IDs to analyze (optional, default: all cases)
 
 Options:
    --output-dir=<path>         Alternate output directory (default: $PWD)
    --cache-dir=<path>          Alternate cache directory location (default: $HOME/.ocg_dcc/verified_mafs)
    --rebuild-cache             Rebuild verification data cache
    --no-cache                  Do not cache verification data
    --conserve-memory           Use less memory
    --use-cgi-filtered-mafs     Use CGI somatic filtered MAFs (only applicable when verifying a CGI WGS dataset)
    --verbose                   Be verbose
    --help                      Display usage message and exit
    --version                   Display program version and exit

=cut
