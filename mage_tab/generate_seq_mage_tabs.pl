#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../common/lib/perl5";
use Clone qw( clone );
use Config::Any;
use Cwd qw( realpath );
use File::Basename qw( dirname fileparse );
use File::Copy qw( copy move );
use File::Find;
use File::Path 2.11 qw( make_path );
use Getopt::Long qw( :config auto_help auto_version );
use List::Util qw( first max );
use List::MoreUtils qw( any all none uniq one firstidx );
use LWP::UserAgent;
use Math::Round qw( round );
use NCI::OCGDCC::Config qw( :all );
use Pod::Usage qw( pod2usage );
use POSIX qw( strftime );
use Sort::Key qw( nkeysort );
use Sort::Key::Natural qw( natsort natkeysort mkkey_natural );
use Spreadsheet::Read qw( ReadData cellrow );
use Storable qw( lock_nstore lock_retrieve );
use Term::ANSIColor;
use Text::CSV;
use Text::ANSITable;
use XML::Simple qw( :strict );
use Data::Dumper;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;
#$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = sub {
    my ($hashref) = @_;
    my @sorted_keys = natsort keys %{$hashref};
    return \@sorted_keys;
};

# config
my %config_file_info = (
    'common' => {
        file => "$FindBin::Bin/../common/conf/common_conf.pl",
        plugin => 'Config::Any::Perl',
    },
    'mage-tab' => {
        file => "$FindBin::Bin/conf/mage_tab_conf.pl",
        plugin => 'Config::Any::Perl',
    },
);
my @config_files = map { $_->{file} } values %config_file_info;
my @config_file_plugins = map { $_->{plugin} } values %config_file_info;
my $config_hashref = Config::Any->load_files({
    files => \@config_files,
    force_plugins => \@config_file_plugins,
    flatten_to_hash => 1,
});
# use %config_file_info key instead of file path (saves typing)
for my $config_file (keys %{$config_hashref}) {
    $config_hashref->{
        first {
            $config_file_info{$_}{file} eq $config_file
        } keys %config_file_info
    } = $config_hashref->{$config_file};
    delete $config_hashref->{$config_file};
}
my @program_names = @{$config_hashref->{'common'}->{'program_names'}};
my %program_project_names = %{$config_hashref->{'common'}->{'program_project_names'}};
my @data_types = @{$config_hashref->{'common'}->{'seq_data_types'}};
my $protocol_data_store = "$FindBin::Bin/data/protocols";
my %sra2dcc_data_type = (
    'Bisulfite-Seq' => 'Bisulfite-seq',
    'ChIP-Seq' => 'ChIP-seq',
    'miRNA-Seq' => 'miRNA-seq',
    'RNA-Seq' => 'mRNA-seq',
    'Targeted-Capture' => 'Targeted-Capture',
    'WGS' => 'WGS',
    'WXS' => 'WXS',
);
my %protocol_base_types = (
    'Extraction' => {
        data => {
            idf_type => 'nucleic acid extraction protocol',
            term_source_ref => 'EFO',
        },
        idf_order_num => 1,
    },
    'LibraryPrep' => {
        data => {
            idf_type => 'nucleic acid library construction protocol',
            term_source_ref => 'EFO',
        },
        idf_order_num => 2,
    },
    'ExomeCapture' => {
        data => {
            idf_type => 'nucleic acid library construction protocol',
            term_source_ref => 'EFO',
        },
        idf_order_num => 3,
    },
    'Sequence' => {
        data => {
            idf_type => 'nucleic acid sequencing protocol',
            term_source_ref => 'EFO',
        },
        idf_order_num => 4,
    },
    'BaseCall' => {
        data => {
            idf_type => 'data transformation protocol',
            term_source_ref => 'EFO',
        },
        idf_order_num => 5,
    },
    'ReadAlign' => {
        data => {
            idf_type => 'data transformation protocol',
            term_source_ref => 'EFO',
        },
        idf_order_num => 6,
    },
);
my %center_info = (
    'BCCA' => {
        authority => 'bcgsc.ca',
    },
    'BCG-Danvers' => {
        authority => 'beckmangenomics.com',
    },
    'BCM' => {
        authority => 'bcm.edu',
    },
    'Broad' => {
        authority => 'broadinstitute.org',
    },
    'CGI' => {
        authority => 'completegenomics.com',
    },
    'HAIB' => {
        authority => 'hudsonalpha.org',
    },
    'NCI-Khan' => {
        authority => 'nci.nih.gov',
        namespace_prefix => 'CCR.Khan',
    },
    'NCI-Meltzer' => {
        authority => 'nci.nih.gov',
        namespace_prefix => 'CCR.Meltzer',
    },
    'NCI-Meerzaman' => {
        authority => 'nci.nih.gov',
        namespace_prefix => 'CBIIT.Meerzaman',
    },
    'StJude' => {
        authority => 'stjude.org',
    },
    'UHN' => {
        authority => 'uhnresearch.ca',
    },
);
my %sra2dcc_center_name = (
    'BCCAGSC' => 'BCCA',
    'BCG-DANVERS' => 'BCG-Danvers',
    'BI' => 'Broad',
    'COMPLETEGENOMICS' => 'CGI',
    'NCI-KHAN' => 'NCI-Khan',
    'NCI-MELTZER' => 'NCI-Meltzer',
    'STJUDE' => 'StJude',
);
my %sra2dcc_platform = (
    'COMPLETE_GENOMICS' => 'CGI',
    'ILLUMINA' => 'Illumina',
    'ION_TORRENT' => 'IonTorrent',
);
my @mage_tab_idf_row_names = (
    'MAGE-TAB Version',
    'Investigation Title',
    'Experimental Design',
    'Experimental Design Term Source REF',
    'Experimental Factor Name',
    'Experimental Factor Type',
    'Experimental Factor Term Source REF',
    'Person Last Name',
    'Person First Name',
    'Person Mid Initials',
    'Person Email',
    'Person Phone',
    'Person Fax',
    'Person Address',
    'Person Affiliation',
    'Person Roles',
    'Person Roles Term Source REF',
    'Quality Control Type',
    'Quality Control Term Source REF',
    'Replicate Type',
    'Replicate Term Source REF',
    'Normalization Type',
    'Normalization Term Source REF',
    'Date of Experiment',
    'Public Release Date',
    'PubMed ID',
    'Publication DOI',
    'Publication Author List',
    'Publication Title',
    'Publication Status',
    'Publication Status Term Source REF',
    'Experiment Description',
    'Protocol Name',
    'Protocol Type',
    'Protocol Term Source REF',
    'Protocol Description',
    'Protocol Parameters',
    'Protocol Hardware',
    'Protocol Software',
    'Protocol Contact',
    'SDRF File',
    'Term Source Name',
    'Term Source File',
    'Term Source Version',
    'Comment[SRA_STUDY]',
    'Comment[BioProject]',
    'Comment[dbGaP Study]',
);
my %mage_tab_sdrf_base_col_names_by_type = (
    'exp' => [
        'Source Name',
        'Provider',
        'Material Type',
        'Term Source REF',
        'Characteristics[Organism]',
        'Term Source REF',
        'Characteristics[Sex]',
        'Term Source REF',
        'Characteristics[DiseaseState]',
        'Term Source REF',
        'Comment[OCG Cohort]',
        'Comment[dbGaP Study]',
        'Comment[Alternate ID]',
        'Sample Name',
        'Material Type',
        'Term Source REF',
        'Characteristics[OrganismPart]',
        'Term Source REF',
        'Characteristics[PassageNumber]',
        'Description',
        'Protocol REF',
        'Performer',
        'Extract Name',
        'Material Type',
        'Term Source REF',
        'Comment[SRA_SAMPLE]',
        'Comment[Alternate ID]',
        'Description',
    ],
    'lib' => [
        'Protocol REF',
        'Protocol REF',
        'Performer',
        'Extract Name',
        'Comment[LIBRARY_LAYOUT]',
        'Comment[LIBRARY_SOURCE]',
        'Comment[LIBRARY_STRATEGY]',
        'Comment[LIBRARY_SELECTION]',
        'Comment[LIBRARY_STRAND]',
        'Comment[ORIENTATION]',
        'Comment[NOMINAL_LENGTH]',
        'Comment[NOMINAL_SDEV]',
        'Comment[LIBRARY_NAME]',
        'Comment[SRA_EXPERIMENT]',
        'Comment[Library Batch]',
        'Description',
    ],
    'run' => [
        'Protocol REF',
        'Performer',
        'Date',
        'Assay Name',
        'Technology Type',
        'Term Source REF',
        'Comment[SPOT_LENGTH]',
        'Protocol REF',
        'Parameter Value[Software Versions]',
    ],
    'run_fastq' => [
        'Scan Name',
        'Comment[SUBMITTED_FILE_NAME]',
        'Comment[SRA_RUN]',
        'Comment[SRA_FILE_URI]',
        'Comment[OCG Data Level]',
        'Comment[QC Warning]',
    ],
    'run_bam' => [
        'Protocol REF',
        'Parameter Value[Software Versions]',
        'Derived Array Data File',
        'Comment[SUBMITTED_FILE_NAME]',
        'Comment[SRA_RUN]',
        'Comment[SRA_FILE_URI]',
        'Comment[OCG Data Level]',
        'Comment[ASSEMBLY_NAME]',
        'Comment[QC Warning]',
    ],
);
my @mage_tab_sdrf_dcc_col_conf = (
    {
        name => 'Derived Array Data File',
        key => 'file_name',
    },
    {
        name => 'Comment[OCG Data Level]',
        key => 'data_level',
    },
    {
        name => 'Comment[miRBase Version]',
        key => 'mirbase_version',
    },
);
my %dcc_scanned_file_protocol_dag_conf = (
    # data type
    'Bisulfite-seq' => {
        # run center
        '_default' => {
            # analysis center
            'BCCA' => [
                {
                    type => 'Methylation',
                },
            ],
        },
    },
    'ChIP-seq' => {
        '_default' => {
            'BCCA' => [
                {
                    type => 'PeakCall',
                },
            ],
        },
    },
    'miRNA-seq' => {
        '_default' => {
            'BCCA' => [
                {
                    type => 'Expression',
                },
            ],
        },
    },
    'mRNA-seq' => {
        '_default' => {
            'BCCA' => [
                {
                    type => 'VariantCall',
                },
                {
                    type => 'VariantCall-StrandSpecific',
                    children => [
                        {
                            type => 'Vcf2Maf',
                        },
                    ],
                },
                {
                    type => 'Expression',
                },
                {
                    type => 'Fusion',
                },
                {
                    type => 'Indel',
                },
            ],
            'NCI-Khan' => [
                {
                    type => 'Expression',
                },
                {
                    type => 'Fusion',
                },
            ],
            'NCI-Meerzaman' => [
                {
                    type => 'Expression',
                },
                {
                    type => 'Fusion-Defuse',
                    children => [
                        {
                            type => 'Fusion-Summary',
                        },
                    ],
                },
                {
                    type => 'Fusion-FusionMap',
                    children => [
                        {
                            type => 'Fusion-Summary',
                        },
                    ],
                },
                {
                    type => 'Fusion-SnowShoes',
                    children => [
                        {
                            type => 'Fusion-Summary',
                        },
                    ],
                },
                {
                    type => 'Fusion-TopHat',
                    children => [
                        {
                            type => 'Fusion-Summary',
                        },
                    ],
                },
            ],
            'NCI-Meltzer' => [
                {
                    type => 'Expression',
                },
            ],
            'StJude' => [
                {
                    type => 'VariantCall',
                },
                {
                    type => 'Expression',
                },
                {
                    type => 'Fusion',
                },
            ],
        },
    },
    'Targeted-Capture' => {
        '_default' => {
            'BCCA' => [
                {
                    type => 'VariantCall-Mpileup',
                    children => [
                        {
                            type => 'Vcf2Maf',
                        },
                    ],
                },
                {
                    type => 'VariantCall-Strelka',
                },
            ],
            'UHN' => [
                {
                    type => 'CnvSegment-VisCap',
                },
            ],
        },
        'BCM' => {
            'BCM' => [
                {
                    type => 'VariantCall-AtlasPindel',
                    children => [
                        {
                            type => 'FilterVerified',
                        },
                    ],
                },
            ],
        },
    },
    'WGS' => {
        '_default' => {
            'BCCA' => [
                {
                    type => 'VariantCall-Mpileup',
                    children => [
                        {
                            type => 'Vcf2Maf',
                        },
                    ],
                },
                {
                    type => 'VariantCall-Strelka',
                },
                {
                    type => 'Fusion',
                },
                {
                    type => 'Indel',
                },
                {
                    type => 'VariantCall',
                },
            ],
            'CGI' => [
                {
                    type => 'CnvSegment',
                    children => [
                        {
                            type => 'Circos',
                            constraint_regexp => qr/(${OCG_CASE_REGEXP}_\w+Vs\w+)/i,
                        },
                    ],
                },
                {
                    type => 'VariantCall',
                    children => [
                        {
                            type => 'Vcf2Maf',
                            constraint_regexp => qr/(${OCG_CASE_REGEXP}_\w+Vs\w+)/i,
                            children => [
                                {
                                    type => 'FilterSomatic',
                                    constraint_regexp => qr/(${OCG_CASE_REGEXP}_\w+Vs\w+)/i,
                                },
                                {
                                    type => 'HigherLevelSummary',
                                },
                            ],
                        },
                        {
                            type => 'Circos',
                            constraint_regexp => qr/(${OCG_CASE_REGEXP}_\w+Vs\w+)/i,
                        },
                    ],
                },
                {
                    type => 'Junction',
                    children => [
                        {
                            type => 'Circos',
                        },
                    ],
                },
            ],
            'StJude' => [
                {
                    type => 'CnvSegment',
                },
                {
                    type => 'VariantCall',
                },
                {
                    type => 'Fusion',
                },
            ],
        },
        'BCCA' => {
            'CGI' => [
                {
                    type => 'VariantCall',
                    children => [
                        {
                            type => 'FilterSomatic',
                        },
                    ],
                },
            ],
        },
    },
    'WXS' => {
        '_default' => {
            'BCCA' => [
                {
                    type => 'VariantCall',
                },
            ],
            'BCM' => [
                {
                    type => 'VariantCall-AtlasPindel',
                    children => [
                        {
                            type => 'FilterVerified',
                        },
                    ],
                },
                {
                    type => 'CnvSegment',
                },
            ],
            'Broad' => [
                {
                    type => 'VariantCall',
                    children => [
                        {
                            type => 'FilterVerified',
                        },
                    ],
                },
                {
                    type => 'CnvSegment',
                },
            ],
            'NCI-Meerzaman' => [
                {
                    type => 'VariantCall',
                    children => [
                        {
                            type => 'FilterVerified',
                        },
                    ],
                },
            ],
            'NCI-Meltzer' => [
                {
                    type => 'VariantCall-Strelka',
                },
            ],
            'StJude' => [
                {
                    type => 'VariantCall',
                    children => [
                        {
                            type => 'FilterVerified',
                        },
                    ],
                },
            ],
        },
    },
);
my %list_types = map { $_ => 1 } qw(
    all
    data_types
    center_platforms
);
my %debug_types = map { $_ => 1 } qw(
    all
    params
    conf
    run_info
    barcode_info
    cgi
    file_parse
    file_info
    xml
    idf
    sdrf
    sdrf_step
);
my $sra_exp_library_name_delimiter = ',';
my @data_level_dir_names = qw(
    L3
    L4
);
my $cgi_dir_name = 'CGI';
my @cgi_analysis_dir_names = qw(
    PilotAnalysisPipeline2
    OptionAnalysisPipeline2
);
my @maf_barcode_col_names = qw(
    Tumor_Sample_Barcode
    Matched_Norm_Sample_Barcode
);
my @param_groups = qw(
    programs
    projects
    data_types
    data_sets
);

# options
my @list = ();
my $dist = 0;
my $clean = 0;
my $rescan_cgi = 0;
my $use_cached_run_info = 0;
my $use_cached_xml = 0;
my $verbose = 0;
my @debug = ();
GetOptions(
    'list:s' => \@list,
    'dist' => \$dist,
    'clean' => \$clean,
    'rescan-cgi' => \$rescan_cgi,
    'use-cached-run-info' => \$use_cached_run_info,
    'use-cached-xml' => \$use_cached_xml,
    'verbose' => \$verbose,
    'debug:s' => \@debug,
) || pod2usage(-verbose => 0);
my %user_params;
if (@ARGV) {
    for my $i (0 .. $#param_groups) {
        next unless defined($ARGV[$i]) and $ARGV[$i] !~ /^\s*$/;
        my (@valid_user_params, @invalid_user_params, @valid_choices);
        my @user_params = split(',', $ARGV[$i]);
        if ($param_groups[$i] eq 'programs') {
            for my $program_name (@program_names) {
                push @valid_user_params, $program_name if any { m/^$program_name$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @program_names;
            }
            @valid_choices = @program_names;
        }
        elsif ($param_groups[$i] eq 'projects') {
            my @program_projects = uniq(
                defined($user_params{programs})
                    ? map { @{$program_project_names{$_}} } @{$user_params{programs}}
                    : map { @{$program_project_names{$_}} } @program_names
            );
            for my $project_name (@program_projects) {
                push @valid_user_params, $project_name if any { m/^$project_name$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @program_projects;
            }
            @valid_choices = @program_projects;
        }
        elsif ($param_groups[$i] eq 'data_types') {
            for my $user_param (@user_params) {
                if ($user_param =~ /^RNA-seq$/i) {
                    $user_param = 'mRNA-seq';
                }
                elsif ($user_param =~ /^targeted_capture_seq/i) {
                    $user_param = 'Targeted-Capture';
                }
            }
            for my $data_type (@data_types) {
                push @valid_user_params, $data_type if any { m/^$data_type$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @data_types;
            }
            @valid_choices = @data_types;
        }
        else {
            @valid_user_params = @user_params;
        }
        if (@invalid_user_params) {
            (my $type = $param_groups[$i]) =~ s/s$//;
            $type =~ s/_/ /g;
            pod2usage(
                -message => 
                    "Invalid $type" . ( scalar(@invalid_user_params) > 1 ? 's' : '' ) . ': ' .
                    join(', ', @invalid_user_params) . "\n" .
                    'Choose from: ' . join(', ', @valid_choices),
                -verbose => 0,
            );
        }
        $user_params{$param_groups[$i]} = \@valid_user_params;
    }
}
my %list = map { $_ => 1 } split(',', join(',', map { lc($_) || 'all' } @list));
for my $list_type (natsort keys %list) {
    if (!$list_types{$list_type}) {
        pod2usage(
            -message => "Invalid list type: $list_type\nAllowed list types: " . join(', ', sort keys %list_types), 
            -verbose => 0,
        );
    }
}
my %debug = map { $_ => 1 } split(',', join(',', map { lc($_) || 'all' } @debug));
for my $debug_type (natsort keys %debug) {
    if (!$debug_types{$debug_type}) {
        pod2usage(
            -message => "Invalid debug type: $debug_type\nAllowed debug types: " . join(', ', sort keys %debug_types), 
            -verbose => 0,
        );
    }
}
if ($debug{all} or $debug{params}) {
    print STDERR 
        +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
        ": \%user_params:\n", Dumper(\%user_params);
}
my %mage_tab_idf_row_idx_by_name = map { $mage_tab_idf_row_names[$_] => $_ } 0 .. $#mage_tab_idf_row_names;
my %mage_tab_sdrf_base_col_idx_by_type_key;
for my $type (keys %mage_tab_sdrf_base_col_names_by_type) {
    for my $col_idx (0 .. $#{$mage_tab_sdrf_base_col_names_by_type{$type}}) {
        if (
            exists($mage_tab_sdrf_base_col_idx_by_type_key{$type}{$mage_tab_sdrf_base_col_names_by_type{$type}[$col_idx]}) or 
            exists($mage_tab_sdrf_base_col_idx_by_type_key{$type}{"$mage_tab_sdrf_base_col_names_by_type{$type}[$col_idx] 1"})
        ) {
            if (exists($mage_tab_sdrf_base_col_idx_by_type_key{$type}{$mage_tab_sdrf_base_col_names_by_type{$type}[$col_idx]})) {
                $mage_tab_sdrf_base_col_idx_by_type_key{$type}{"$mage_tab_sdrf_base_col_names_by_type{$type}[$col_idx] 1"} = 
                    $mage_tab_sdrf_base_col_idx_by_type_key{$type}{$mage_tab_sdrf_base_col_names_by_type{$type}[$col_idx]};
                delete($mage_tab_sdrf_base_col_idx_by_type_key{$type}{$mage_tab_sdrf_base_col_names_by_type{$type}[$col_idx]});
            }
            for (my $col_header_num = 2; ; $col_header_num++) {
                if (!exists($mage_tab_sdrf_base_col_idx_by_type_key{$type}{"$mage_tab_sdrf_base_col_names_by_type{$type}[$col_idx] $col_header_num"})) {
                    $mage_tab_sdrf_base_col_idx_by_type_key{$type}{"$mage_tab_sdrf_base_col_names_by_type{$type}[$col_idx] $col_header_num"} = $col_idx;
                    last;
                }
            }
        }
        else {
            $mage_tab_sdrf_base_col_idx_by_type_key{$type}{$mage_tab_sdrf_base_col_names_by_type{$type}[$col_idx]} = $col_idx;
        }
    }
}
my @mage_tab_sdrf_base_col_headers = map { @{$_} } @mage_tab_sdrf_base_col_names_by_type{qw( exp lib run run_fastq run_bam )};
if (!-d $protocol_data_store) {
    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
        ": protocols data store $protocol_data_store not found\n";
}
# mage-tab config refactored for convenience where current project and 
# dataset config get dynamically loaded below, saves a lot on typing
my $mt_config_hashref = clone($config_hashref->{'mage-tab'});
delete @{$mt_config_hashref}{qw( project dataset )};
my $ua = LWP::UserAgent->new();
for my $program_name (@program_names) {
    next if defined($user_params{programs}) and none { $program_name eq $_ } @{$user_params{programs}};
    PROJECT: for my $project_name (@{$program_project_names{$program_name}}) {
        next if defined($user_params{projects}) and none { $project_name eq $_ } @{$user_params{projects}};
        # skip Resources project
        next if $project_name eq 'Resources';
        my ($disease_proj, $subproject) = split /-(?=NBL|PPTP|Toronto|Brazil)/, $project_name, 2;
        my $project_dir = $disease_proj;
        if (defined $subproject) {
            if ($disease_proj eq 'MDLS') {
                if ($subproject eq 'NBL') {
                    $project_dir = "$project_dir/NBL";
                }
                elsif ($subproject eq 'PPTP') {
                    $project_dir = "$project_dir/PPTP";
                }
                else {
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                        ": invalid subproject '$subproject'\n";
                }
            }
            elsif ($disease_proj eq 'OS') {
                if ($subproject eq 'Toronto') {
                    $project_dir = "$project_dir/Toronto";
                }
                elsif ($subproject eq 'Brazil') {
                    $project_dir = "$project_dir/Brazil";
                }
                else {
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                        ": invalid subproject '$subproject'\n";
                }
            }
            else {
                die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                    ": invalid disease project '$disease_proj'\n";
            }
        }
        # current project mage-tab config hashref (saves typing)
        if (
            defined($config_hashref->{'mage-tab'}->{project}->{$program_name}) and
            defined($config_hashref->{'mage-tab'}->{project}->{$program_name}->{$project_name})
        ) {
            $mt_config_hashref->{project} = $config_hashref->{'mage-tab'}->{project}->{$program_name}->{$project_name};
        }
        else {
            $mt_config_hashref->{project} = undef;
        }
        my ($merged_run_info_hashref, $run_info_by_study_hashref);
        my $run_info_debug_dumped = 0 if $debug{all} or $debug{run_info};
        DATA_TYPE: for my $data_type (@data_types) {
            next if defined($user_params{data_types}) and none { $data_type eq $_ } @{$user_params{data_types}};
            my $data_type_dir_name = $data_type;
            if ($data_type eq 'Targeted-Capture') {
                $data_type_dir_name = 'targeted_capture_sequencing';
            }
            my @datasets;
            my $data_type_dir = "/local/\L$program_name\E/data/$project_dir/$data_type_dir_name";
            if (-d $data_type_dir) {
                opendir(my $data_type_dh, $data_type_dir) 
                    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $data_type_dir: $!";
                my @data_type_sub_dir_names = grep { -d "$data_type_dir/$_" and !m/^\./ } readdir($data_type_dh);
                closedir($data_type_dh);
                if (all { m/^(current|old)$/ } @data_type_sub_dir_names) {
                    push @datasets, '_default';
                }
                elsif (none { m/^(current|old)$/ } @data_type_sub_dir_names) {
                    for my $data_type_sub_dir_name (@data_type_sub_dir_names) {
                        my $data_type_sub_dir = "$data_type_dir/$data_type_sub_dir_name";
                        opendir(my $data_type_sub_dh, $data_type_sub_dir) 
                            or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $data_type_sub_dir: $!";
                        my @sub_dir_names = grep { -d "$data_type_sub_dir/$_" and !m/^\./ } readdir($data_type_sub_dh);
                        closedir($data_type_sub_dh);
                        if (all { m/^(current|old)$/ } @sub_dir_names) {
                            push @datasets, $data_type_sub_dir_name;
                        }
                        else {
                            warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": $data_type_dir subdirectory structure is invalid\n";
                            next DATA_TYPE;
                        }
                    }
                }
                else {
                    warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": $data_type_dir subdirectory structure is invalid\n";
                    next DATA_TYPE;
                }
            }
            for my $dataset (@datasets) {
                next if defined($user_params{data_sets}) and none { $dataset eq $_ } @{$user_params{data_sets}};
                # current dataset mage-tab config hashref (saves typing)
                if (
                    defined($config_hashref->{'mage-tab'}->{dataset}->{$program_name}) and
                    defined($config_hashref->{'mage-tab'}->{dataset}->{$program_name}->{$project_name}) and
                    defined($config_hashref->{'mage-tab'}->{dataset}->{$program_name}->{$project_name}->{$data_type}) and
                    defined($config_hashref->{'mage-tab'}->{dataset}->{$program_name}->{$project_name}->{$data_type}->{$dataset})
                ) {
                    $mt_config_hashref->{dataset} =
                        $config_hashref->{'mage-tab'}->{dataset}->{$program_name}->{$project_name}->{$data_type}->{$dataset};
                }
                else {
                    $mt_config_hashref->{dataset} = undef;
                }
                if (!defined $merged_run_info_hashref) {
                    my @run_info_errors;
                    # get project SRA run info
                    print "[$program_name $project_name]\n";
                    for my $dbgap_study_id (natsort @{$mt_config_hashref->{project}->{'dbGaP_study_ids'}}) {
                        print "Getting SRA run info for $dbgap_study_id\n";
                        my $run_info_storable_file = "$CACHE_DIR/sra/${dbgap_study_id}_run_info_hashref.pls";
                        if (!-f $run_info_storable_file or !$use_cached_run_info) {
                            my $response = $ua->get(
                                #"http://trace.ncbi.nlm.nih.gov/Traces/study/?acc=$dbgap_study_id&get=csv"
                                #"http://trace.ncbi.nlm.nih.gov/Traces/study/be/nph-run_selector.cgi?&acc=$dbgap_study_id&get=csv"
                                "http://trace.ncbi.nlm.nih.gov/Traces/sra/?sp=runinfo&acc=$dbgap_study_id"
                            );
                            if ($response->is_success) {
                                if ($response->decoded_content ne '') {
                                    if (my $csv = Text::CSV->new({
                                        binary => 1,
                                        #sep_char => "\t",
                                    })) {
                                        if (open(my $run_table_csv_fh, '<:encoding(utf8)', \$response->decoded_content)) {
                                            my $col_header_row_arrayref = $csv->getline($run_table_csv_fh);
                                            my %col_header_idxs = map { $col_header_row_arrayref->[$_] => $_ } 0 .. $#{$col_header_row_arrayref};
                                            while (my $table_row_arrayref = $csv->getline($run_table_csv_fh)) {
                                                my $data_type = $table_row_arrayref->[$col_header_idxs{'LibraryStrategy'}];
                                                if (exists $sra2dcc_data_type{$data_type}) {
                                                    $data_type = $sra2dcc_data_type{$data_type};
                                                }
                                                else {
                                                    push @run_info_errors, "unrecognized SRA data type '$data_type'";
                                                }
                                                my $exp_id = $table_row_arrayref->[$col_header_idxs{'Experiment'}];
                                                my $run_id = $table_row_arrayref->[$col_header_idxs{'Run'}];
                                                my $barcode = $table_row_arrayref->[$col_header_idxs{'SampleName'}];
                                                my $exp_library_name = $table_row_arrayref->[$col_header_idxs{'LibraryName'}];
                                                my $run_center_name = defined($sra2dcc_center_name{uc($table_row_arrayref->[$col_header_idxs{'CenterName'}])})
                                                                    ? $sra2dcc_center_name{uc($table_row_arrayref->[$col_header_idxs{'CenterName'}])}
                                                                    : $table_row_arrayref->[$col_header_idxs{'CenterName'}];
                                                my $platform = defined($sra2dcc_platform{uc($table_row_arrayref->[$col_header_idxs{'Platform'}])})
                                                             ? $sra2dcc_platform{uc($table_row_arrayref->[$col_header_idxs{'Platform'}])}
                                                             : $table_row_arrayref->[$col_header_idxs{'Platform'}];
                                                $run_info_by_study_hashref->{$dbgap_study_id}->{$data_type}->{$run_center_name}->{exp_ids}->{$exp_id}++;
                                                $run_info_by_study_hashref->{$dbgap_study_id}->{$data_type}->{$run_center_name}->{run_ids}->{$run_id}++;
                                                $run_info_by_study_hashref->{$dbgap_study_id}->{$data_type}->{$run_center_name}->{barcodes}->{$barcode}++;
                                                $run_info_by_study_hashref->{$dbgap_study_id}->{$data_type}->{$run_center_name}->{platforms}->{$platform}++;
                                                my @exp_library_names;
                                                if ($exp_library_name =~ /\S/) {
                                                    if ($exp_library_name =~ /$sra_exp_library_name_delimiter/o) {
                                                        @exp_library_names = map { s/\s+//g; $_ } split($sra_exp_library_name_delimiter, $exp_library_name);
                                                    }
                                                    else {
                                                        push @exp_library_names, $exp_library_name;
                                                    }
                                                    for my $exp_library_name (@exp_library_names) {
                                                        if (
                                                            !exists($run_info_by_study_hashref->{$dbgap_study_id}->{$data_type}->{$run_center_name}->{library_name_barcode}->{$exp_library_name}) or
                                                            $run_info_by_study_hashref->{$dbgap_study_id}->{$data_type}->{$run_center_name}->{library_name_barcode}->{$exp_library_name} eq $barcode
                                                        ) {
                                                            $run_info_by_study_hashref->{$dbgap_study_id}->{$data_type}->{$run_center_name}->{library_name_barcode}->{$exp_library_name} = $barcode
                                                        }
                                                        else {
                                                            push @run_info_errors, 
                                                                "different barcodes for same library $exp_library_name: " .
                                                                $run_info_by_study_hashref->{$dbgap_study_id}->{$data_type}->{$run_center_name}->{library_name_barcode}->{$exp_library_name} .
                                                                ", $barcode";
                                                        }
                                                    }
                                                }
                                            }
                                            close($run_table_csv_fh);
                                            print "Serializing run info $run_info_storable_file\n" if $verbose;
                                            my $run_info_storable_dir = dirname($run_info_storable_file);
                                            if (!-d $run_info_storable_dir) {
                                                make_path($run_info_storable_dir, { chmod => 0700 }) 
                                                    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                                           ": could not create $run_info_storable_dir: $!";
                                            }
                                            lock_nstore($run_info_by_study_hashref->{$dbgap_study_id}, $run_info_storable_file)
                                                or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                                       ": could not serialize and store $run_info_storable_file: $!";
                                            if (defined $merged_run_info_hashref) {
                                                $merged_run_info_hashref = merge_run_info_hash(
                                                    $merged_run_info_hashref, 
                                                    $run_info_by_study_hashref->{$dbgap_study_id},
                                                );
                                            }
                                            else {
                                                $merged_run_info_hashref = $run_info_by_study_hashref->{$dbgap_study_id};
                                            }
                                        }
                                        else {
                                            push @run_info_errors, "could not open SRA $dbgap_study_id RunSelector CSV table in-memory filehandle: $!";
                                        }
                                    }
                                    else {
                                        push @run_info_errors, "cannot create Text::CSV object: " . Text::CSV->error_diag();
                                    }
                                }
                                else {
                                    push @run_info_errors, "no SRA data exists for $dbgap_study_id";
                                }
                            }
                            else {
                                push @run_info_errors, "failed to download SRA $dbgap_study_id RunSelector CSV table: " . $response->status_line;
                            }
                        }
                        else {
                            print "Loading cached run info $run_info_storable_file\n" if $verbose;
                            $run_info_by_study_hashref->{$dbgap_study_id} = lock_retrieve($run_info_storable_file)
                                or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                       ": could not deserialize and retrieve $run_info_storable_file: $!";
                            if (defined $merged_run_info_hashref) {
                                $merged_run_info_hashref = merge_run_info_hash(
                                    $merged_run_info_hashref, 
                                    $run_info_by_study_hashref->{$dbgap_study_id},
                                );
                            }
                            else {
                                $merged_run_info_hashref = $run_info_by_study_hashref->{$dbgap_study_id};
                            }
                        }
                    }
                    if (@run_info_errors) {
                        warn map { (-t STDERR ? colored('ERROR', 'red') : 'ERROR') . ": $_\n" } @run_info_errors;
                        next PROJECT;
                    }
                }
                if ($debug{all} or $debug{run_info} and !$run_info_debug_dumped) {
                    print STDERR 
                        +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                        ": \$merged_run_info_hashref:\n", Dumper($merged_run_info_hashref),
                        +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                        ": \$run_info_by_study_hashref:\n", Dumper($run_info_by_study_hashref),
                    $run_info_debug_dumped++;
                }
                if (%list) {
                    for my $data_type (natsort keys %{$merged_run_info_hashref}) {
                        print "$data_type\n";
                        if ($list{all} or $list{center_platforms}) {
                            for my $run_center_name (natsort keys %{$merged_run_info_hashref->{$data_type}}) {
                                print "  $run_center_name: ", 
                                      join(',', 
                                          natsort keys %{$merged_run_info_hashref->{$data_type}->{$run_center_name}->{platforms}}
                                      ), "\n";
                            }
                        }
                    }
                    next PROJECT;
                }
                print "[$program_name $project_name $data_type", 
                      ($dataset ne '_default' ? " $dataset" : ''),
                      "]\n";
                my $dataset_dir = $data_type_dir . ( $dataset ne '_default' ? "/$dataset" : '' ) . '/current';
                # preprocess barcode info and load special configs
                my $barcodes_by_run_center_case_tissue_type_hashref;
                # CGCI NHL project doesn't have proper sample barcodes
                if ($program_name ne 'CGCI' or $project_name ne 'NHL') {
                    print "Processing SRA barcode information\n";
                    for my $run_center_name (keys %{$merged_run_info_hashref->{$data_type}}) {
                        for my $barcode (keys %{$merged_run_info_hashref->{$data_type}->{$run_center_name}->{barcodes}}) {
                            my ($case_id, $tissue_type) = @{get_barcode_info($barcode)}{qw( case_id tissue_type )};
                            if (none { $barcode eq $_ } @{$barcodes_by_run_center_case_tissue_type_hashref->{$run_center_name}->{$case_id}->{$tissue_type}}) {
                                push @{$barcodes_by_run_center_case_tissue_type_hashref->{$run_center_name}->{$case_id}->{$tissue_type}}, $barcode;
                            }
                        }
                    }
                    if (defined $mt_config_hashref->{dataset}->{'add_run_center_barcodes'}) {
                        for my $run_center_name (keys %{$mt_config_hashref->{dataset}->{'add_run_center_barcodes'}}) {
                            for my $barcode (@{$mt_config_hashref->{dataset}->{'add_run_center_barcodes'}->{$run_center_name}}) {
                                my ($case_id, $tissue_type) = @{get_barcode_info($barcode)}{qw( case_id tissue_type )};
                                if (none { $barcode eq $_ } @{$barcodes_by_run_center_case_tissue_type_hashref->{$run_center_name}->{$case_id}->{$tissue_type}}) {
                                    push @{$barcodes_by_run_center_case_tissue_type_hashref->{$run_center_name}->{$case_id}->{$tissue_type}}, $barcode;
                                }
                            }
                        }
                    }
                    if ($debug{all} or $debug{barcode_info}) {
                        print STDERR 
                            +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                            ": \$barcodes_by_run_center_case_tissue_type_hashref:\n", Dumper($barcodes_by_run_center_case_tissue_type_hashref);
                    }
                }
                # scan CGI data tree and build analysis info
                my $cgi_analysis_info_by_case_hashref;
                if (
                    $data_type eq 'WGS' and 
                    exists($merged_run_info_hashref->{$data_type}->{'CGI'}) and
                    -d "$dataset_dir/$cgi_dir_name"
                ) {
                    my $cgi_dataset_dir = realpath("$dataset_dir/$cgi_dir_name");
                    my $cgi_storable_file = "$CACHE_DIR/mage_tab/\L${program_name}_${project_name}\E_cgi_analysis_info_by_case_hashref.pls";
                    print "Getting CGI analysis information $cgi_dataset_dir\n";
                    if (!-f $cgi_storable_file or $rescan_cgi) {
                        my @cgi_analysis_dirs;
                        for my $cgi_analysis_dir_name (@cgi_analysis_dir_names) {
                            if (-d "$cgi_dataset_dir/$cgi_analysis_dir_name") {
                                push @cgi_analysis_dirs, "$cgi_dataset_dir/$cgi_analysis_dir_name";
                                print "Found $cgi_dataset_dir/$cgi_analysis_dir_name\n" if $verbose;
                            }
                            else {
                                print "Missing $cgi_dataset_dir/$cgi_analysis_dir_name\n" if $verbose;
                            }
                        }
                        my $num_barcodes_processed = 0;
                        my @cgi_data_errors;
                        for my $cgi_analysis_dir (@cgi_analysis_dirs) {
                            opendir(my $cgi_analysis_dh, $cgi_analysis_dir)
                                or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                       ": couldn't opendir $cgi_analysis_dir: $!";
                            my @case_analysis_dir_names = natsort grep {
                                !m/^\./ and (
                                    -d "$cgi_analysis_dir/$_" or (
                                        -l "$cgi_analysis_dir/$_" and 
                                        -d readlink "$cgi_analysis_dir/$_"
                                    )
                                )
                            } readdir($cgi_analysis_dh);
                            closedir($cgi_analysis_dh);
                            for my $case_analysis_dir_name (@case_analysis_dir_names) {
                                if ($case_analysis_dir_name !~ /^$OCG_CGI_CASE_DIR_REGEXP$/) {
                                    push @cgi_data_errors, 
                                         "invalid CGI case analysis dir: $cgi_analysis_dir/$case_analysis_dir_name";
                                    next;
                                }
                                my $case_analysis_dir;
                                if (-d "$cgi_analysis_dir/$case_analysis_dir_name/EXP") {
                                    $case_analysis_dir = "$cgi_analysis_dir/$case_analysis_dir_name/EXP";
                                }
                                elsif ($disease_proj eq 'OS') {
                                    $case_analysis_dir = "$cgi_analysis_dir/$case_analysis_dir_name";
                                }
                                else {
                                    push @cgi_data_errors, 
                                         "invalid CGI case analysis dir: $cgi_analysis_dir/$case_analysis_dir_name";
                                    next;
                                }
                                opendir(my $case_analysis_dh, $case_analysis_dir)
                                    or die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                           ": couldn't opendir $case_analysis_dir: $!";
                                my @barcode_dir_names = grep {
                                    -d "$case_analysis_dir/$_" and 
                                    m/^$OCG_BARCODE_REGEXP$/
                                } readdir($case_analysis_dh);
                                close($case_analysis_dh);
                                my (
                                    $case_id,
                                    $cmp_barcode_analysis_info_hashref,
                                    @other_barcode_analysis_info_hashrefs,
                                );
                                for my $barcode (@barcode_dir_names) {
                                    my $is_cmp_barcode;
                                    my $barcode_info_hashref = get_barcode_info($barcode);
                                    $case_id = $barcode_info_hashref->{case_id} unless defined $case_id;
                                    my $barcode_dir = "$case_analysis_dir/$barcode";
                                    if (-d "$barcode_dir/ASM") {
                                        my $barcode_asm_dir = "$barcode_dir/ASM";
                                        opendir(my $barcode_asm_dh, $barcode_asm_dir)
                                            or die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                                   ": couldn't opendir $barcode_asm_dir: $!";
                                        if (none { m/^somaticVcfBeta/ } readdir($barcode_asm_dh)) {
                                            if (!defined $cmp_barcode_analysis_info_hashref) {
                                                $is_cmp_barcode++;
                                            }
                                            else {
                                                push @cgi_data_errors,
                                                     "CGI case analysis dir has multiple $barcode_info_hashref->{cgi_tissue_type}: $case_analysis_dir";
                                                next;
                                            }
                                        }
                                        closedir($barcode_asm_dh);
                                    }
                                    elsif ($disease_proj eq 'OS') {
                                        if ($barcode_info_hashref->{cgi_tissue_type} =~ /Normal/) {
                                            if (!defined $cmp_barcode_analysis_info_hashref) {
                                                $is_cmp_barcode++;
                                            }
                                            else {
                                                push @cgi_data_errors,
                                                     "CGI case analysis dir has multiple $barcode_info_hashref->{cgi_tissue_type}: $case_analysis_dir";
                                                next;
                                            }
                                        }
                                    }
                                    else {
                                        push @cgi_data_errors, "invalid CGI barcode directory: $barcode_dir";
                                        next;
                                    }
                                    my @barcode_library_names;
                                    if (-d "$barcode_dir/LIB") {
                                        my $barcode_lib_dir = "$barcode_dir/LIB";
                                        opendir(my $barcode_lib_dh, $barcode_lib_dir)
                                            or die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                                   ": couldn't opendir $barcode_lib_dir: $!";
                                        @barcode_library_names = grep {
                                            -d "$barcode_lib_dir/$_" and
                                            !m/^\./
                                        } readdir($barcode_lib_dh);
                                        closedir($barcode_lib_dh);
                                    }
                                    elsif ($disease_proj eq 'OS') {
                                        opendir(my $barcode_dh, $barcode_dir)
                                            or die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                                   ": couldn't opendir $barcode_dir: $!";
                                        if (
                                            my $vcf_file_name = first {
                                                -f "$barcode_dir/$_" and
                                                m/\.vcf\.bz2$/
                                            } readdir($barcode_dh)
                                        ) {
                                            my ($barcode_lib_name) = split('_', $vcf_file_name);
                                            push @barcode_library_names, $barcode_lib_name;
                                        }
                                        else {
                                            push @cgi_data_errors, "invalid OS CGI BCCA directory: $barcode_dir";
                                            next;
                                        }
                                        closedir($barcode_dh);
                                    }
                                    else {
                                        push @cgi_data_errors, "invalid CGI barcode directory: $barcode_dir";
                                        next;
                                    }
                                    if ($is_cmp_barcode) {
                                        $cmp_barcode_analysis_info_hashref = {
                                            barcode => $barcode,
                                            cgi_tissue_type => $barcode_info_hashref->{cgi_tissue_type},
                                            library_names => \@barcode_library_names,
                                        };
                                    }
                                    else {
                                        push @other_barcode_analysis_info_hashrefs, {
                                            barcode => $barcode,
                                            cgi_tissue_type => $barcode_info_hashref->{cgi_tissue_type},
                                            library_names => \@barcode_library_names,
                                        };
                                    }
                                    $num_barcodes_processed++;
                                    print "\r$num_barcodes_processed processed" if -t STDOUT;
                                }
                                if (!defined $cmp_barcode_analysis_info_hashref) {
                                    push @cgi_data_errors, 
                                         "couldn't determine comparator barcode: $case_analysis_dir";
                                    next;
                                }
                                for my $barcode_analysis_info_hashref (@other_barcode_analysis_info_hashrefs) {
                                    my $cmp_analysis_str = 
                                        "$cmp_barcode_analysis_info_hashref->{cgi_tissue_type}Vs$barcode_analysis_info_hashref->{cgi_tissue_type}";
                                    if (
                                        !exists($cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str}) or 
                                        (
                                            $project_name eq 'AML' and
                                            $case_analysis_dir_name =~ /_2$/
                                        )
                                    ) {
                                        $cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str} = {
                                            $cmp_barcode_analysis_info_hashref->{cgi_tissue_type} => {
                                                barcode => $cmp_barcode_analysis_info_hashref->{barcode},
                                                library_names => $cmp_barcode_analysis_info_hashref->{library_names},
                                            },
                                            $barcode_analysis_info_hashref->{cgi_tissue_type} => {
                                                barcode => $barcode_analysis_info_hashref->{barcode},
                                                library_names => $barcode_analysis_info_hashref->{library_names},
                                            },
                                        };
                                    }
                                    else {
                                        push @cgi_data_errors, 
                                             "CGI dataset has multiple $case_id $cmp_analysis_str: $case_analysis_dir";
                                    }
                                }
                            }
                        }
                        print "$num_barcodes_processed processed" unless -t STDOUT and $num_barcodes_processed;
                        print "\n";
                        if (!@cgi_data_errors) {
                            print "Serializing CGI analysis info $cgi_storable_file\n" if $verbose;
                            my $cgi_storable_dir = dirname($cgi_storable_file);
                            if (!-d $cgi_storable_dir) {
                                make_path($cgi_storable_dir, { chmod => 0700 }) 
                                    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                           ": could not create $cgi_storable_dir: $!";
                            }
                            lock_nstore($cgi_analysis_info_by_case_hashref, $cgi_storable_file)
                                or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                       " could not serialize and store $cgi_storable_file: $!";
                        }
                        else {
                            die map { (-t STDERR ? colored('ERROR', 'red') : 'ERROR') . ": $_\n" } natsort @cgi_data_errors;
                        }
                    }
                    else {
                        print "Loading cached CGI analysis info $cgi_storable_file\n" if $verbose;
                        $cgi_analysis_info_by_case_hashref = lock_retrieve($cgi_storable_file)
                            or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                   ": could not deserialize and retrieve $cgi_storable_file: $!";
                    }
                    if ($debug{all} or $debug{cgi}) {
                        print STDERR 
                            +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                            ": \$cgi_analysis_info_by_case_hashref:\n", Dumper($cgi_analysis_info_by_case_hashref);
                    }
                }
                # scan DCC data tree and build data file info
                my (
                    %dcc_scanned_file_info,
                    %dcc_parsed_file_names_by_barcode,
                    @dcc_marked_file_info,
                    @dcc_file_errors, 
                    @dcc_skipped_files, 
                    @dcc_missing_data_level_dirs,
                );
                my $num_files_processed = 0;
                print "Getting data file information $dataset_dir\n";
                for my $data_level_dir_name (@data_level_dir_names) {
                    my $data_level_dir = "$dataset_dir/$data_level_dir_name";
                    if (!-d $data_level_dir) {
                        push @dcc_missing_data_level_dirs, $data_level_dir;
                        next;
                    }
                    (my $data_level = $data_level_dir_name) =~ s/\D//g;
                    my %files_to;
                    for my $ps_type (qw( parse skip configured )) {
                        if (
                            defined($mt_config_hashref->{dataset}) and
                            defined($mt_config_hashref->{dataset}->{"${ps_type}_files"})
                        ) {
                            for my $file_rel_path (
                                @{$mt_config_hashref->{dataset}->{"${ps_type}_files"}->{$data_level_dir_name}}
                            ) {
                                push @{$files_to{$ps_type}}, "$data_level_dir/$file_rel_path";
                            }
                        }
                    }
                    # files to parse
                    for my $file (@{$files_to{parse}}) {
                        my $file_name = fileparse($file);
                        for my $barcode (get_barcodes_from_data_file($file, $program_name, $project_name, $data_type)) {
                            push @{$dcc_parsed_file_names_by_barcode{$barcode}}, $file_name;
                        }
                    }
                    find({
                        follow => 1,
                        wanted => sub {
                            # files only
                            return unless -f;
                            my $file_name = $_;
                            my $file = $File::Find::name;
                            my $parent_dir = $File::Find::dir;
                            # skip manifest files
                            return if $file_name eq $config_hashref->{'common'}->{'default_manifest_file_name'};
                            # skip configured, parsed files
                            if (any { $file eq $_ } map { @{$_} } grep(defined, @files_to{qw( configured parse )})) {
                                # do nothing
                            }
                            # WGS
                            elsif ($data_type eq 'WGS') {
                                # CGI copy number
                                if ($file =~ /copy_number\/CGI\/somaticCnvSegmentsDiploidBeta_($OCG_CASE_REGEXP)_(\w+Vs\w+)\.(?:tsv|txt)$/i) {
                                    my ($case_id, $cmp_analysis_str) = ($1, $2);
                                    if (
                                        defined($cgi_analysis_info_by_case_hashref->{$case_id}) and
                                        defined($cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str})
                                    ) {
                                        for my $barcode_analysis_info_hashref (
                                            values %{$cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str}}
                                        ) {
                                            my $barcode = $barcode_analysis_info_hashref->{barcode};
                                            for my $library_name (@{$barcode_analysis_info_hashref->{library_names}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'CGI'}{'CnvSegment'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "could not lookup CGI analysis info: $file";
                                    }
                                }
                                # CGI circos
                                elsif ($file =~ /circos\/CGI\/somaticCircos_($OCG_CASE_REGEXP)_(\w+Vs\w+)\.png$/i) {
                                    my ($case_id, $cmp_analysis_str) = ($1, $2);
                                    if (
                                        defined($cgi_analysis_info_by_case_hashref->{$case_id}) and
                                        defined($cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str})
                                    ) {
                                        for my $barcode_analysis_info_hashref (
                                            values %{$cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str}}
                                        ) {
                                            my $barcode = $barcode_analysis_info_hashref->{barcode};
                                            for my $library_name (@{$barcode_analysis_info_hashref->{library_names}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'CGI'}{'Circos'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "could not lookup CGI analysis info: $file";
                                    }
                                }
                                # CGI full vcfs
                                elsif ($file =~ /mutation\/CGI\/FullMafsVcfs\/fullVcf_($OCG_CASE_REGEXP)_(\w+Vs\w+)\.vcf\.bz2$/i) {
                                    my ($case_id, $cmp_analysis_str) = ($1, $2);
                                    if (
                                        defined($cgi_analysis_info_by_case_hashref->{$case_id}) and
                                        defined($cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str})
                                    ) {
                                        for my $barcode_analysis_info_hashref (
                                            values %{$cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str}}
                                        ) {
                                            my $barcode = $barcode_analysis_info_hashref->{barcode};
                                            for my $library_name (@{$barcode_analysis_info_hashref->{library_names}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'CGI'}{'VariantCall'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "could not lookup CGI analysis info: $file";
                                    }
                                }
                                # CGI full mafs
                                elsif ($file =~ /mutation\/CGI\/FullMafsVcfs\/fullMaf_($OCG_CASE_REGEXP)_(\w+Vs\w+)\.maf\.txt$/i) {
                                    my ($case_id, $cmp_analysis_str) = ($1, $2);
                                    if (
                                        defined($cgi_analysis_info_by_case_hashref->{$case_id}) and
                                        defined($cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str})
                                    ) {
                                        for my $barcode_analysis_info_hashref (
                                            values %{$cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str}}
                                        ) {
                                            my $barcode = $barcode_analysis_info_hashref->{barcode};
                                            for my $library_name (@{$barcode_analysis_info_hashref->{library_names}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'CGI'}{'Vcf2Maf'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "could not lookup CGI analysis info: $file";
                                    }
                                }
                                # CGI BCCA full vcfs
                                elsif ($file =~ /mutation\/CGI\/FullMafsVcfs\/fullVcf_($OCG_BARCODE_REGEXP)\.vcf\.bz2$/i) {
                                    my $barcode = $1;
                                    my ($case_id, $cgi_tissue_type) = @{get_barcode_info($barcode)}{qw( case_id cgi_tissue_type )};
                                    for my $library_name (
                                        @{$cgi_analysis_info_by_case_hashref->{$case_id}->{'NormalVsPrimary'}->{$cgi_tissue_type}->{library_names}}
                                    ) {
                                        push @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'BCCA'}{'CGI'}{'VariantCall'}}, {
                                            data_level => $data_level,
                                            file_name => $file_name,
                                        };
                                    }
                                }
                                # CGI BCCA somatic vcfs
                                elsif ($file =~ /mutation\/CGI\/SomaticVcfs\/somaticVcf_($OCG_CASE_REGEXP)_(\w+Vs\w+)\.vcf$/i) {
                                    my ($case_id, $cmp_analysis_str) = ($1, $2);
                                    if (
                                        defined($cgi_analysis_info_by_case_hashref->{$case_id}) and
                                        defined($cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str})
                                    ) {
                                        for my $barcode_analysis_info_hashref (
                                            values %{$cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str}}
                                        ) {
                                            my $barcode = $barcode_analysis_info_hashref->{barcode};
                                            for my $library_name (@{$barcode_analysis_info_hashref->{library_names}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'BCCA'}{'CGI'}{'FilterSomatic'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "could not lookup CGI analysis info: $file";
                                    }
                                }
                                # CGI somatic mafs
                                elsif ($file =~ /mutation\/CGI\/SomaticFilteredMafs\/somaticFilteredMaf_($OCG_CASE_REGEXP)_(\w+Vs\w+)\.(tsv|maf\.txt)$/i) {
                                    my ($case_id, $cmp_analysis_str) = ($1, $2);
                                    if (
                                        defined($cgi_analysis_info_by_case_hashref->{$case_id}) and
                                        defined($cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str})
                                    ) {
                                        for my $barcode_analysis_info_hashref (
                                            values %{$cgi_analysis_info_by_case_hashref->{$case_id}->{$cmp_analysis_str}}
                                        ) {
                                            my $barcode = $barcode_analysis_info_hashref->{barcode};
                                            for my $library_name (@{$barcode_analysis_info_hashref->{library_names}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'CGI'}{'FilterSomatic'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "could not lookup CGI analysis info: $file";
                                    }
                                }
                                # CGI analysis
                                elsif ($file =~ /mutation\/CGI\/Analysis\/.+?\.(tsv|txt)$/i) {
                                    # special filtering for TARGET ALL Xenografts
                                    my $is_all_xeno_file++ if $project_name eq 'ALL' and $file_name =~ /xenografts/i;
                                    for my $case_id (keys %{$cgi_analysis_info_by_case_hashref}) {
                                        next if $is_all_xeno_file and none { m/Xenograft/i } keys %{$cgi_analysis_info_by_case_hashref->{$case_id}} or
                                               !$is_all_xeno_file and  any { m/Xenograft/i } keys %{$cgi_analysis_info_by_case_hashref->{$case_id}};
                                        for my $case_cmp_analysis_info_hashref (values %{$cgi_analysis_info_by_case_hashref->{$case_id}}) {
                                            for my $cgi_tissue_type (keys %{$case_cmp_analysis_info_hashref}) {
                                                my $barcode = $case_cmp_analysis_info_hashref->{$cgi_tissue_type}->{barcode};
                                                # special exclusion for TARGET OS CGI BCCA data
                                                next if $disease_proj eq 'OS' and 
                                                        !exists($merged_run_info_hashref->{$data_type}->{'CGI'}->{barcodes}->{$barcode});
                                                for my $library_name (@{$case_cmp_analysis_info_hashref->{$cgi_tissue_type}->{library_names}}) {
                                                    if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'CGI'}{'HigherLevelSummary'}}) {
                                                        push @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'CGI'}{'HigherLevelSummary'}}, {
                                                            data_level => $data_level,
                                                            file_name => $file_name,
                                                        };
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                # CGI junction
                                elsif ($file =~ /structural\/CGI\/ConcatenatedJunction.+?\.(tsv|txt)$/i) {
                                    # special filtering for TARGET ALL Xenografts
                                    my $is_all_xeno_file++ if $project_name eq 'ALL' and $file_name =~ /xenografts/i;
                                    for my $case_id (keys %{$cgi_analysis_info_by_case_hashref}) {
                                        next if $is_all_xeno_file and none { m/Xenograft/i } keys %{$cgi_analysis_info_by_case_hashref->{$case_id}} or
                                               !$is_all_xeno_file and  any { m/Xenograft/i } keys %{$cgi_analysis_info_by_case_hashref->{$case_id}};
                                        for my $case_cmp_analysis_info_hashref (values %{$cgi_analysis_info_by_case_hashref->{$case_id}}) {
                                            for my $cgi_tissue_type (keys %{$case_cmp_analysis_info_hashref}) {
                                                my $barcode = $case_cmp_analysis_info_hashref->{$cgi_tissue_type}->{barcode};
                                                # special exclusion for TARGET OS CGI BCCA data
                                                next if $disease_proj eq 'OS' and 
                                                        !exists($merged_run_info_hashref->{$data_type}->{'CGI'}->{barcodes}->{$barcode});
                                                for my $library_name (@{$case_cmp_analysis_info_hashref->{$cgi_tissue_type}->{library_names}}) {
                                                    if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'CGI'}{'Junction'}}) {
                                                        push @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'CGI'}{'Junction'}}, {
                                                            data_level => $data_level,
                                                            file_name => $file_name,
                                                        };
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                # BCCA strelka vcfs
                                elsif ($file =~ /mutation\/BCCA\/($OCG_BARCODE_REGEXP)_($OCG_BARCODE_REGEXP)\.somatic\.(snv|indel)\.vcf$/i) {
                                    for my $barcode ($1, $2) {
                                        push @{$dcc_scanned_file_info{$data_type}{$barcode}{'BCCA'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall-Strelka'}}, {
                                            data_level => $data_level,
                                            file_name => $file_name,
                                        };
                                    }
                                }
                                # BCCA strelka mafs
                                elsif ($file =~ /mutation\/BCCA\/($OCG_BARCODE_REGEXP)_($OCG_BARCODE_REGEXP)\..+?\.somatic\.maf(\.txt)?$/i) {
                                    for my $barcode ($1, $2) {
                                        push @{$dcc_scanned_file_info{$data_type}{$barcode}{'BCCA'}{'_default'}{'BCCA'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall-Strelka'}}, {
                                            data_level => $data_level,
                                            file_name => $file_name,
                                        };
                                    }
                                }
                                # BCCA mpileup vcfs
                                elsif ($file =~ /mutation\/BCCA\/($OCG_BARCODE_REGEXP)\.dna_(tumor|normal)\.vcf$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'BCCA'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall-Mpileup'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # BCCA mpileup mafs
                                elsif ($file =~ /mutation\/BCCA\/($OCG_BARCODE_REGEXP)\..+?\.dna_(tumor|normal)\.maf(\.txt)?$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'BCCA'}{'_default'}{'BCCA'}{'BCCA'}{'Vcf2Maf'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # BCCA indel vcfs
                                elsif ($file =~ /mutation\/BCCA\/($OCG_BARCODE_REGEXP)\.indel\.vcf$/i) {
                                    my ($barcode, $file_type) = ($1, $2);
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'BCCA'}{'_default'}{'BCCA'}{'BCCA'}{'Indel'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # BCCA fusion vcfs
                                elsif ($file =~ /structural\/BCCA\/($OCG_BARCODE_REGEXP)\.fusion\.vcf$/i) {
                                    my ($barcode, $file_type) = ($1, $2);
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'BCCA'}{'_default'}{'BCCA'}{'BCCA'}{'Fusion'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # BCCA older mafs
                                elsif ($file =~ /mutation\/BCCA\/.+?\.maf(\.txt)?$/i) {
                                    # extract barcode(s) out of file basename
                                    if (my @barcodes = $file_name =~ /($OCG_BARCODE_REGEXP)/g) {
                                        for my $barcode (@barcodes) {
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                    }
                                    else {
                                        my $barcode_found;
                                        for my $exp_library_name (keys %{$merged_run_info_hashref->{$data_type}->{'BCCA'}->{library_name_barcode}}) {
                                            if ($file =~ /mutation\/BCCA\/.*?_?${exp_library_name}_?.*?\.maf(\.txt)?$/i) {
                                                my $barcode = $merged_run_info_hashref->{$data_type}->{'BCCA'}->{library_name_barcode}->{$exp_library_name};
                                                if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}) {
                                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}, {
                                                        data_level => $data_level,
                                                        file_name => $file_name,
                                                    };
                                                }
                                                $barcode_found++;
                                            }
                                        }
                                        if (!$barcode_found) {
                                            push @dcc_marked_file_info, {
                                                data_level => $data_level,
                                                file => $file,
                                            };
                                        }
                                    }
                                }
                                # StJude copy number
                                elsif ($file =~ /copy_number\/StJude\/.*?\.tsv$/i) {
                                    for my $case_id (keys %{$cgi_analysis_info_by_case_hashref}) {
                                        for my $case_cmp_analysis_info_hashref (values %{$cgi_analysis_info_by_case_hashref->{$case_id}}) {
                                            # special filtering for TARGET ALL Xenografts
                                            next if $project_name eq 'ALL' and any { m/Xenograft/i } keys %{$case_cmp_analysis_info_hashref};
                                            for my $cgi_tissue_type (keys %{$case_cmp_analysis_info_hashref}) {
                                                my $barcode = $case_cmp_analysis_info_hashref->{$cgi_tissue_type}->{barcode};
                                                for my $library_name (@{$case_cmp_analysis_info_hashref->{$cgi_tissue_type}->{library_names}}) {
                                                    if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'StJude'}{'CnvSegment'}}) {
                                                        push @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'StJude'}{'CnvSegment'}}, {
                                                            data_level => $data_level,
                                                            file_name => $file_name,
                                                        };
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    # special inclusion OS WGS StJude
                                    if (
                                        $project_name eq 'OS' and
                                        exists($merged_run_info_hashref->{$data_type}->{'NCI-Meltzer'}) and
                                        exists($merged_run_info_hashref->{$data_type}->{'NCI-Meltzer'}->{barcodes})
                                    ) {
                                        for my $barcode (keys %{$merged_run_info_hashref->{$data_type}->{'NCI-Meltzer'}->{barcodes}}) {
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Meltzer'}{'StJude'}{'CnvSegment'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                    }
                                }
                                # StJude mafs
                                elsif ($file =~ /mutation\/StJude\/.*?\.maf(\.txt)?$/i) {
                                    if (my ($file_tissue_type) = $file_name =~ /(diagnosis|relapse)/i) {
                                        $file_tissue_type = lc($file_tissue_type) eq 'diagnosis' ? 'Primary' : 'Recurrent';
                                        for my $case_id (keys %{$cgi_analysis_info_by_case_hashref}) {
                                            for my $case_cmp_analysis_info_hashref (values %{$cgi_analysis_info_by_case_hashref->{$case_id}}) {
                                                # special filtering for TARGET ALL Xenografts
                                                next if $project_name eq 'ALL' and any { m/Xenograft/i } keys %{$case_cmp_analysis_info_hashref} or
                                                        none { m/^$file_tissue_type$/i } keys %{$case_cmp_analysis_info_hashref};
                                                for my $cgi_tissue_type (keys %{$case_cmp_analysis_info_hashref}) {
                                                    my $barcode = $case_cmp_analysis_info_hashref->{$cgi_tissue_type}->{barcode};
                                                    for my $library_name (@{$case_cmp_analysis_info_hashref->{$cgi_tissue_type}->{library_names}}) {
                                                        if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'StJude'}{'VariantCall'}}) {
                                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'StJude'}{'VariantCall'}}, {
                                                                data_level => $data_level,
                                                                file_name => $file_name,
                                                            };
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "could not determine tumor type from file name: $file";
                                    }
                                    # special inclusion OS WGS StJude
                                    if (
                                        $project_name eq 'OS' and
                                        exists($merged_run_info_hashref->{$data_type}->{'NCI-Meltzer'}) and
                                        exists($merged_run_info_hashref->{$data_type}->{'NCI-Meltzer'}->{barcodes})
                                    ) {
                                        for my $barcode (keys %{$merged_run_info_hashref->{$data_type}->{'NCI-Meltzer'}->{barcodes}}) {
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Meltzer'}{'StJude'}{'VariantCall'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                    }
                                }
                                # StJude structural
                                elsif ($file =~ /structural\/StJude\/.*?\.tsv$/i) {
                                    for my $case_id (keys %{$cgi_analysis_info_by_case_hashref}) {
                                        for my $case_cmp_analysis_info_hashref (values %{$cgi_analysis_info_by_case_hashref->{$case_id}}) {
                                            # special filtering for TARGET ALL Xenografts
                                            next if $project_name eq 'ALL' and any { m/Xenograft/i } keys %{$case_cmp_analysis_info_hashref};
                                            for my $cgi_tissue_type (keys %{$case_cmp_analysis_info_hashref}) {
                                                my $barcode = $case_cmp_analysis_info_hashref->{$cgi_tissue_type}->{barcode};
                                                for my $library_name (@{$case_cmp_analysis_info_hashref->{$cgi_tissue_type}->{library_names}}) {
                                                    if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'StJude'}{'Fusion'}}) {
                                                        push @{$dcc_scanned_file_info{$data_type}{$barcode}{'CGI'}{$library_name}{'CGI'}{'StJude'}{'Fusion'}}, {
                                                            data_level => $data_level,
                                                            file_name => $file_name,
                                                        };
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    # special inclusion OS WGS StJude
                                    if (
                                        $project_name eq 'OS' and
                                        exists($merged_run_info_hashref->{$data_type}->{'NCI-Meltzer'}) and
                                        exists($merged_run_info_hashref->{$data_type}->{'NCI-Meltzer'}->{barcodes})
                                    ) {
                                        for my $barcode (keys %{$merged_run_info_hashref->{$data_type}->{'NCI-Meltzer'}->{barcodes}}) {
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Meltzer'}{'StJude'}{'Fusion'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                    }
                                }
                                elsif (
                                    $file_name =~ /^((.*?README.*?|MANIFEST)\.(txt|pdf)|somaticCircosLegend\.png|.+?\.(xls|doc)x?)$/ or
                                    any { $file eq $_ } @{$files_to{skip}}
                                ) {
                                    push @dcc_skipped_files, $file;
                                }
                                else {
                                    push @dcc_file_errors, "unrecognized $data_type data file: $file";
                                }
                            }
                            # WXS
                            elsif ($data_type eq 'WXS') {
                                # Broad copy number
                                if ($file =~ /copy_number\/Broad\/($OCG_CASE_REGEXP).*?\.txt$/i) {
                                    my $case_id = $1;
                                    if (
                                        defined($barcodes_by_run_center_case_tissue_type_hashref->{'Broad'}) and
                                        defined($barcodes_by_run_center_case_tissue_type_hashref->{'Broad'}->{$case_id})
                                    ) {
                                        for my $tissue_type (keys %{$barcodes_by_run_center_case_tissue_type_hashref->{'Broad'}->{$case_id}}) {
                                            next if $tissue_type !~ /Primary|Normal/i;
                                            for my $barcode (@{$barcodes_by_run_center_case_tissue_type_hashref->{'Broad'}->{$case_id}->{$tissue_type}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'Broad'}{'Broad'}{'CnvSegment'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "could not lookup barcode info: $file";
                                    }
                                }
                                # AML MSS copy number
                                elsif (
                                    $project_name eq 'AML' and
                                    $file =~ /copy_number\/MSS\/.+?\.(target_aml\.txt|zip)$/i
                                ) {
                                    for my $barcode (keys %{$merged_run_info_hashref->{$data_type}->{'BCM'}->{barcodes}}) {
                                        push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCM'}{'BCM'}{'CnvSegment'}}, {
                                            data_level => $data_level,
                                            file_name => $file_name,
                                        };
                                    }
                                }
                                # NCI-Meltzer strelka vcfs
                                elsif ($file =~ /mutation\/NCI-Meltzer\/($OCG_CASE_REGEXP)\.somatic\.(snv|indel)\.vcf$/i) {
                                    my $case_id = $1;
                                    if (
                                        defined($barcodes_by_run_center_case_tissue_type_hashref->{'NCI-Meltzer'}) and
                                        defined($barcodes_by_run_center_case_tissue_type_hashref->{'NCI-Meltzer'}->{$case_id})
                                    ) {
                                        for my $tissue_type (keys %{$barcodes_by_run_center_case_tissue_type_hashref->{'NCI-Meltzer'}->{$case_id}}) {
                                            next if $tissue_type !~ /Primary|Normal/i;
                                            for my $barcode (@{$barcodes_by_run_center_case_tissue_type_hashref->{'NCI-Meltzer'}->{$case_id}->{$tissue_type}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Meltzer'}{'NCI-Meltzer'}{'VariantCall-Strelka'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "could not lookup barcode info: $file";
                                    }
                                }
                                # OS NCI-Meltzer StJude mafs
                                # StJude didn't use correct barcodes in file so cannot parse, will grab barcodes from run info
                                elsif (
                                    $project_name eq 'OS' and
                                    $file =~ /mutation\/StJude\/CandidateSomatic\/.+?\.maf(\.txt)?$/i
                                ) {
                                    for my $barcode (keys %{$merged_run_info_hashref->{$data_type}->{'NCI-Meltzer'}->{barcodes}}) {
                                        push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Meltzer'}{'StJude'}{'VariantCall'}}, {
                                            data_level => $data_level,
                                            file_name => $file_name,
                                        };
                                    }
                                }
                                elsif (
                                    $file_name =~ /^(README|MANIFEST)\.txt$/i or
                                    any { $file eq $_ } @{$files_to{skip}}
                                ) {
                                    push @dcc_skipped_files, $file;
                                }
                                # BCCA older mafs
                                elsif ($file =~ /mutation\/BCCA\/.+?\.maf(\.txt)?$/i) {
                                    my $barcode_found;
                                    for my $exp_library_name (keys %{$merged_run_info_hashref->{$data_type}->{'BCCA'}->{library_name_barcode}}) {
                                        if ($file =~ /mutation\/BCCA\/.*?_?${exp_library_name}_?.*?\.maf(\.txt)?$/i) {
                                            my $barcode = $merged_run_info_hashref->{$data_type}->{'BCCA'}->{library_name_barcode}->{$exp_library_name};
                                            if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                            $barcode_found++;
                                        }
                                    }
                                    if (!$barcode_found) {
                                        push @dcc_marked_file_info, {
                                            data_level => $data_level,
                                            file => $file,
                                        };
                                    }
                                }
                                else {
                                    push @dcc_file_errors, "unrecognized $data_type data file: $file";
                                }
                            }
                            # mRNA-seq
                            elsif ($data_type eq 'mRNA-seq') {
                                # AML HAIB NCI-Meerzaman gene quantification
                                if (
                                    $project_name eq 'AML' and
                                    $file =~ /expression\/NCI-Meerzaman\/(AML_\d+)\.(?:gene|exon|isoform)\.quantification\.txt$/i
                                ) {
                                    if (
                                        defined($mt_config_hashref->{dataset}) and
                                        defined($mt_config_hashref->{dataset}->{barcode_by_alt_id}) and
                                        defined($mt_config_hashref->{dataset}->{barcode_by_alt_id}->{'HAIB'})
                                    ) {
                                        my $external_id = $1;
                                        if (
                                            my $barcode = $mt_config_hashref->{dataset}->{barcode_by_alt_id}->{'HAIB'}->{$external_id}
                                        ) {
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'HAIB'}{'NCI-Meerzaman'}{'Expression'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                        else {
                                            push @dcc_file_errors, "could not lookup config barcode info for $external_id";
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "'barcode_by_alt_id' HAIB configuration missing";
                                    }
                                }
                                # AML HAIB NCI-Meerzaman fusion
                                elsif (
                                    $project_name eq 'AML' and
                                    $file =~ /structural\/NCI-Meerzaman\/summary\/fusion_(?:breakpoint_seq|report)\.txt$/i
                                ) {
                                    if (
                                        defined($mt_config_hashref->{dataset}) and
                                        defined($mt_config_hashref->{dataset}->{barcode_by_alt_id}) and
                                        defined($mt_config_hashref->{dataset}->{barcode_by_alt_id}->{'HAIB'})
                                    ) {
                                        for my $barcode (values %{$mt_config_hashref->{dataset}->{barcode_by_alt_id}->{'HAIB'}}) {
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'HAIB'}{'NCI-Meerzaman'}{'Fusion-Summary'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "'barcode_by_alt_id' HAIB configuration missing";
                                    }
                                }
                                elsif (
                                    $project_name eq 'AML' and
                                    $file =~ /structural\/NCI-Meerzaman\/(df|fm|th)\/(AML_\d+)_(?:results_filtered|FusionReport|potential_fusion)\.(?:tsv|txt)$/i
                                ) {
                                    if (
                                        defined($mt_config_hashref->{dataset}) and
                                        defined($mt_config_hashref->{dataset}->{barcode_by_alt_id}) and
                                        defined($mt_config_hashref->{dataset}->{barcode_by_alt_id}->{'HAIB'})
                                    ) {
                                        my ($method_id, $external_id) = ($1, $2);
                                        my ($method) = map {
                                            $_ eq 'df' ? 'Defuse' :
                                            $_ eq 'fm' ? 'FusionMap'    :
                                            $_ eq 'th' ? 'TopHat' : 
                                            undef
                                        } ($method_id);
                                        if (
                                            my $barcode = $mt_config_hashref->{dataset}->{barcode_by_alt_id}->{'HAIB'}->{$external_id}
                                        ) {
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'HAIB'}{'NCI-Meerzaman'}{"Fusion-${method}"}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                        else {
                                            push @dcc_file_errors, "could not lookup config barcode info for $external_id";
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "'barcode_by_alt_id' HAIB configuration missing";
                                    }
                                }
                                elsif (
                                    $project_name eq 'AML' and
                                    $file =~ /structural\/NCI-Meerzaman\/ss\/(?:final_fusion_report_.+?|fusion_protein_results|mapping_good_for_primer_sequence_design)\.txt$/i
                                ) {
                                    if (
                                        defined($mt_config_hashref->{dataset}) and
                                        defined($mt_config_hashref->{dataset}->{barcode_by_alt_id}) and
                                        defined($mt_config_hashref->{dataset}->{barcode_by_alt_id}->{'HAIB'})
                                    ) {
                                        for my $barcode (values %{$mt_config_hashref->{dataset}->{barcode_by_alt_id}->{'HAIB'}}) {
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'HAIB'}{'NCI-Meerzaman'}{'Fusion-SnowShoes'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "'barcode_by_alt_id' HAIB configuration missing";
                                    }
                                }
                                elsif (
                                    $project_name eq 'AML' and
                                    $file =~ /structural\/NCI-Meerzaman\/ss\/(AML_\d+)_fusion_summary\.txt$/i
                                ) {
                                    if (
                                        defined($mt_config_hashref->{dataset}) and
                                        defined($mt_config_hashref->{dataset}->{barcode_by_alt_id}) and
                                        defined($mt_config_hashref->{dataset}->{barcode_by_alt_id}->{'HAIB'})
                                    ) {
                                        my $external_id = $1;
                                        if (
                                            my $barcode = $mt_config_hashref->{dataset}->{barcode_by_alt_id}->{'HAIB'}->{$external_id}
                                        ) {
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'HAIB'}{'NCI-Meerzaman'}{'Fusion-SnowShoes'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                        else {
                                            push @dcc_file_errors, "could not lookup config barcode info for $external_id";
                                        }
                                    }
                                    else {
                                        push @dcc_file_errors, "'barcode_by_alt_id' HAIB configuration missing";
                                    }
                                }
                                # NCI-Khan gene, exon, isoform quantification
                                elsif ($file =~ /expression\/NCI-Khan\/($OCG_BARCODE_REGEXP)\.(?:gene|exon|isoform)\.quantification\.txt$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Khan'}{'NCI-Khan'}{'Expression'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # NCI-Meltzer gene, exon, isoform quantification
                                elsif ($file =~ /expression\/NCI-Meltzer\/($OCG_BARCODE_REGEXP)\.(?:gene|exon|isoform)\.quantification\.txt$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Meltzer'}{'NCI-Meltzer'}{'Expression'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # BCCA gene, exon, isoform quantification
                                elsif ($file =~ /expression\/BCCA\/($OCG_BARCODE_REGEXP)\.(?:gene|exon|isoform)\.quantification\.txt$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'Expression'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # BCCA tumor/normal maf
                                elsif ($file =~ /mutation\/BCCA\/($OCG_BARCODE_REGEXP)\..+?\.rna_(?:tumor|normal)\.maf(\.txt)?$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'Vcf2Maf'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # BCCA tumor/normal vcf
                                elsif ($file =~ /mutation\/BCCA\/($OCG_BARCODE_REGEXP)\.rna_(?:tumor|normal)\.vcf$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall-StrandSpecific'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # BCCA indel vcf
                                elsif ($file =~ /mutation\/BCCA\/($OCG_BARCODE_REGEXP)\.indel\.vcf$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'Indel'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # BCCA fusion vcf
                                elsif ($file =~ /structural\/BCCA\/($OCG_BARCODE_REGEXP)\.fusion\.vcf$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'Fusion'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # StJude expression
                                elsif ($file =~ /expression\/StJude\/($OCG_BARCODE_REGEXP)\.expression\.txt$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'StJude'}{'StJude'}{'Expression'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # StJude structural
                                elsif ($file =~ /structural\/StJude\/.*?\.tsv$/i) {
                                    # only Phase2
                                    for my $barcode (keys %{$run_info_by_study_hashref->{'phs000464'}->{$data_type}->{'StJude'}->{barcodes}}) {
                                        push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'StJude'}{'StJude'}{'Fusion'}}, {
                                            data_level => $data_level,
                                            file_name => $file_name,
                                        };
                                    }
                                }
                                # StJude older gene, exon, spljxn quantification and maf files
                                elsif ($file =~ /StJude\/.+?\.((gene|exon|spljxn)\.quantification\.txt|maf(\.txt)?)$/i) {
                                    my $barcode_found;
                                    for my $exp_library_name (keys %{$merged_run_info_hashref->{$data_type}->{'StJude'}->{library_name_barcode}}) {
                                        my $barcode = $merged_run_info_hashref->{$data_type}->{'StJude'}->{library_name_barcode}->{$exp_library_name};
                                        if ($file =~ /expression\/StJude\/.*?_?${exp_library_name}_?.*?\.((gene|exon|spljxn)\.quantification\.txt)$/i) {
                                            if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'StJude'}{'StJude'}{'Expression'}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'StJude'}{'StJude'}{'Expression'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                            $barcode_found++;
                                        }
                                        elsif ($file =~ /mutation\/StJude\/.*?_?${exp_library_name}_?.*?\.maf(\.txt)?$/i) {
                                            if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'StJude'}{'StJude'}{'VariantCall'}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'StJude'}{'StJude'}{'VariantCall'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                            $barcode_found++;
                                        }
                                    }
                                    if (!$barcode_found) {
                                        push @dcc_marked_file_info, {
                                            data_level => $data_level,
                                            file => $file,
                                        };
                                    }
                                }
                                # BCCA older gene, exon, spljxn quantification and maf files
                                elsif ($file =~ /BCCA\/.+?\.((gene|exon|spljxn)\.quantification\.txt|maf(\.txt)?)$/i) {
                                    my $barcode_found;
                                    for my $exp_library_name (keys %{$merged_run_info_hashref->{$data_type}->{'BCCA'}->{library_name_barcode}}) {
                                        my $barcode = $merged_run_info_hashref->{$data_type}->{'BCCA'}->{library_name_barcode}->{$exp_library_name};
                                        if ($file =~ /expression\/BCCA\/.*?_?${exp_library_name}_?.*?\.((gene|exon|spljxn)\.quantification\.txt)$/i) {
                                            if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'Expression'}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'Expression'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                            $barcode_found++;
                                        }
                                        elsif ($file =~ /mutation\/BCCA\/.*?_?${exp_library_name}_?.*?\.maf(\.txt)?$/i) {
                                            if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                            $barcode_found++;
                                        }
                                    }
                                    if (!$barcode_found) {
                                        push @dcc_marked_file_info, {
                                            data_level => $data_level,
                                            file => $file,
                                        };
                                    }
                                }
                                # NCI-Khan other gene, isoform, exon and fusion files
                                elsif ($file =~ /NCI-Khan\/.+?\.(((gene|isoform)\.fpkm|exon\.(count|rpkm))\.txt|fusion(\.results\.filtered)?\.tsv)$/i) {
                                    my $barcode_found;
                                    for my $exp_library_name (keys %{$merged_run_info_hashref->{$data_type}->{'NCI-Khan'}->{library_name_barcode}}) {
                                        # fix for NCI-Khan TARGET CCSK,NBL mRNA-seq
                                        my $search_library_name = $exp_library_name;
                                        if ($program_name eq 'TARGET' and $project_name eq 'CCSK' and $data_type eq 'mRNA-seq') {
                                            ($search_library_name) = $search_library_name =~ /^(CCSK\d+)/i;
                                        }
                                        elsif ($program_name eq 'TARGET' and $project_name eq 'NBL' and $data_type eq 'mRNA-seq') {
                                            ($search_library_name) = $search_library_name =~ /^(NB\d+)/i;
                                        }
                                        my $barcode = $merged_run_info_hashref->{$data_type}->{'NCI-Khan'}->{library_name_barcode}->{$exp_library_name};
                                        if ($file =~ /expression\/NCI-Khan\/.*?_?${search_library_name}_?.*?\.(((gene|isoform)\.fpkm|exon\.(count|rpkm))\.txt)$/i) {
                                            if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Khan'}{'NCI-Khan'}{'Expression'}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Khan'}{'NCI-Khan'}{'Expression'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                            $barcode_found++;
                                        }
                                        elsif ($file =~ /structural\/NCI-Khan\/.*?_?${search_library_name}_?.*?\.fusion(\.results\.filtered)?\.tsv$/i) {
                                            if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Khan'}{'NCI-Khan'}{'Fusion'}}) {
                                                push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Khan'}{'NCI-Khan'}{'Fusion'}}, {
                                                    data_level => $data_level,
                                                    file_name => $file_name,
                                                };
                                            }
                                            $barcode_found++;
                                        }
                                    }
                                    if (!$barcode_found) {
                                        push @dcc_marked_file_info, {
                                            data_level => $data_level,
                                            file => $file,
                                        };
                                    }
                                }
                                elsif ($file_name =~ /^((README|MANIFEST)\.txt|.+?\.tar\.gz)$/i) {
                                    push @dcc_skipped_files, $file;
                                }
                                else {
                                    push @dcc_file_errors, "unrecognized $data_type data file: $file";
                                }
                            }
                            # miRNA-seq
                            elsif ($data_type eq 'miRNA-seq') {
                                # BCCA mirna, isoform quantification
                                if ($file =~ /expression\/BCCA\/($OCG_BARCODE_REGEXP)\.(mirna|isoform)\.quantification\.txt$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'Expression'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                        mirbase_version => '20',
                                    };
                                }
                                elsif ($file_name =~ /^(README|MANIFEST)\.txt$/i) {
                                    push @dcc_skipped_files, $file;
                                }
                                else {
                                    push @dcc_file_errors, "unrecognized $data_type data file: $file";
                                }
                            }
                            # Targeted-Capture
                            elsif ($data_type eq 'Targeted-Capture') {
                                # BCCA full vcfs
                                if ($file =~ /mutation\/BCCA\/($OCG_BARCODE_REGEXP)\.capture_dna_(tumor|normal)\.vcf?$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall-Mpileup'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # BCCA full mafs
                                elsif ($file =~ /mutation\/BCCA\/($OCG_BARCODE_REGEXP)\..+?\.capture_dna_(tumor|normal)\.maf(\.txt)?$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'Vcf2Maf'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                # BCCA strelka vcfs
                                elsif ($file =~ /mutation\/BCCA\/($OCG_BARCODE_REGEXP)_($OCG_BARCODE_REGEXP)\.capture_dna\.somatic\.(snv|indel)\.vcf$/i) {
                                    for my $barcode ($1, $2) {
                                        push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall-Strelka'}}, {
                                            data_level => $data_level,
                                            file_name => $file_name,
                                        };
                                    }
                                }
                                # UHN copy number (VisCap)
                                elsif (
                                    $file =~ /copy_number\/UHN\/VisCap_(?:Female|Male)_(?:Germline|Somatic)\/($OCG_BARCODE_REGEXP)\.bam\.cov\/.*?$OCG_BARCODE_REGEXP\.bam\.cov\.(cnvs\.xls|plot\.pdf|segments\.seg)$/i
                                ) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'UHN'}{'CnvSegment-VisCap'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                elsif (
                                    $file_name =~ /^(README|MANIFEST)\.txt$/i or
                                    any { $file eq $_ } @{$files_to{skip}}
                                ) {
                                    push @dcc_skipped_files, $file;
                                }
                                # special skip without logging for rest of UHN copy number (VisCap) files
                                elsif ($file =~ /copy_number\/UHN\/VisCap_(?:Female|Male)_(?:Germline|Somatic)\/.+?$/) {
                                    # do nothing
                                }
                                else {
                                    push @dcc_file_errors, "unrecognized $data_type data file: $file";
                                }
                            }
                            # Bisulfite-seq
                            elsif ($data_type eq 'Bisulfite-seq') {
                                # Methylation
                                if ($file_name =~ /^($OCG_BARCODE_REGEXP)\..+?\.bw?$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'Methylation'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                elsif (
                                    $file_name =~ /^(README|MANIFEST)\.txt$/i or 
                                    $file_name =~ /\.gz$/i
                                ) {
                                    push @dcc_skipped_files, $file;
                                }
                                else {
                                    push @dcc_file_errors, "unrecognized data file: $file";
                                }
                            }
                            # Bisulfite-seq
                            elsif ($data_type eq 'ChIP-seq') {
                                # PeakCall
                                if ($file_name =~ /^($OCG_BARCODE_REGEXP)\..+?\.bw?$/i) {
                                    my $barcode = $1;
                                    push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'PeakCall'}}, {
                                        data_level => $data_level,
                                        file_name => $file_name,
                                    };
                                }
                                elsif (
                                    $file_name =~ /^(README|MANIFEST)\.txt$/i or 
                                    $file_name =~ /\.gz$/i
                                ) {
                                    push @dcc_skipped_files, $file;
                                }
                                else {
                                    push @dcc_file_errors, "unrecognized data file: $file";
                                }
                            }
                            else {
                                push @dcc_file_errors, "unrecognized data type: $data_type";
                            }
                            $num_files_processed++;
                            print "\r$num_files_processed processed" if -t STDOUT and $data_type ne 'WXS';
                        },
                    },
                    $data_level_dir);
                }
                print "\n" if -t STDOUT and $num_files_processed and $data_type ne 'WXS';
                if (@dcc_missing_data_level_dirs and $verbose) {
                    print map { "Missing $_\n" } natsort @dcc_missing_data_level_dirs;
                }
                if (@dcc_skipped_files and $verbose) {
                    print map { "Skipped $_\n" } natsort @dcc_skipped_files;
                }
                if (@dcc_marked_file_info and $verbose) {
                    print map { "Marked $_->{file}\n" } natkeysort { $_->{file} } @dcc_marked_file_info;
                }
                if (@dcc_file_errors) {
                    die map { (-t STDERR ? colored('ERROR', 'red') : 'ERROR') . ": $_\n" } natsort @dcc_file_errors;
                }
                print "$num_files_processed processed\n" unless -t STDOUT and $num_files_processed and $data_type ne 'WXS';
                if ($debug{all} or $debug{file_info}) {
                    print STDERR 
                        +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                        ": \%dcc_scanned_file_info:\n", Dumper(\%dcc_scanned_file_info);
                }
                my (
                    %dcc_sdrf_dag_info,
                    %dcc_protocol_idf_order_info,
                );
                # add parsed file sdrf dag info
                if (
                    defined($mt_config_hashref->{dataset}) and
                    defined($mt_config_hashref->{dataset}->{'sdrf_dag_info'})
                ) {
                    for my $barcode (
                        natsort keys %dcc_parsed_file_names_by_barcode
                    ) {
                        for my $exp_center_name (
                            sort by_dag_center_name keys %{$mt_config_hashref->{dataset}->{'sdrf_dag_info'}}
                        ) {
                            for my $run_center_name (
                                sort by_dag_center_name keys %{$mt_config_hashref->{dataset}->{'sdrf_dag_info'}->{$exp_center_name}}
                            ) {
                                for my $analysis_center_name (
                                    sort by_dag_center_name keys %{$mt_config_hashref->{dataset}->{'sdrf_dag_info'}->{$exp_center_name}->{$run_center_name}}
                                ) {
                                    # init
                                    my $sdrf_dag_node_hashref = {};
                                    $dcc_protocol_idf_order_info{$analysis_center_name} = []
                                        unless defined $dcc_protocol_idf_order_info{$analysis_center_name};
                                    add_dcc_parsed_file_sdrf_dag_info({
                                        conf_sdrf_dag_node => $mt_config_hashref->{dataset}->{'sdrf_dag_info'}->{$exp_center_name}->{$run_center_name}->{$analysis_center_name},
                                        sdrf_dag_node => $sdrf_dag_node_hashref,
                                        file_names => $dcc_parsed_file_names_by_barcode{$barcode},
                                        protocol_idf_order_info => $dcc_protocol_idf_order_info{$analysis_center_name},
                                    });
                                    if (%{$sdrf_dag_node_hashref}) {
                                        $dcc_sdrf_dag_info{$data_type}{$barcode}{$exp_center_name}{'_default'}{$run_center_name}{$analysis_center_name} = $sdrf_dag_node_hashref;
                                    }
                                }
                            }
                        }
                    }
                }
                # add additional data types file sdrf dag info
                if (
                    defined($mt_config_hashref->{dataset}) and
                    defined($mt_config_hashref->{dataset}->{'add_data_types'})
                ) {
                    for my $data_type (
                        natsort keys %{$mt_config_hashref->{dataset}->{'add_data_types'}}
                    ) {
                        if (defined $mt_config_hashref->{dataset}->{'add_data_types'}->{$data_type}->{'sdrf_dag_info'}) {
                            for my $barcode (
                                natsort keys %dcc_parsed_file_names_by_barcode
                            ) {
                                for my $exp_center_name (
                                    sort by_dag_center_name keys %{$mt_config_hashref->{dataset}->{'add_data_types'}->{$data_type}->{'sdrf_dag_info'}}
                                ) {
                                    for my $run_center_name (
                                        sort by_dag_center_name keys %{$mt_config_hashref->{dataset}->{'add_data_types'}->{$data_type}->{'sdrf_dag_info'}->{$exp_center_name}}
                                    ) {
                                        for my $analysis_center_name (
                                            sort by_dag_center_name keys %{$mt_config_hashref->{dataset}->{'add_data_types'}->{$data_type}->{'sdrf_dag_info'}->{$exp_center_name}->{$run_center_name}}
                                        ) {
                                            # init
                                            my $sdrf_dag_node_hashref = {};
                                            $dcc_protocol_idf_order_info{$analysis_center_name} = []
                                                unless defined $dcc_protocol_idf_order_info{$analysis_center_name};
                                            add_dcc_parsed_file_sdrf_dag_info({
                                                conf_sdrf_dag_node => $mt_config_hashref->{dataset}->{'add_data_types'}->{$data_type}->{'sdrf_dag_info'}->{$exp_center_name}->{$run_center_name}->{$analysis_center_name},
                                                sdrf_dag_node => $sdrf_dag_node_hashref,
                                                file_names => $dcc_parsed_file_names_by_barcode{$barcode},
                                                protocol_idf_order_info => $dcc_protocol_idf_order_info{$analysis_center_name},
                                            });
                                            if (%{$sdrf_dag_node_hashref}) {
                                                $dcc_sdrf_dag_info{$data_type}{$barcode}{$exp_center_name}{'_default'}{$run_center_name}{$analysis_center_name} = $sdrf_dag_node_hashref;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                # add scanned file sdrf dag info
                for my $data_type (
                    natsort keys %dcc_scanned_file_info
                ) {
                    for my $barcode (
                        natsort keys %{$dcc_scanned_file_info{$data_type}}
                    ) {
                        for my $exp_center_name (
                            sort by_dag_center_name keys %{$dcc_scanned_file_info{$data_type}{$barcode}}
                        ) {
                            for my $library_name (
                                sort by_dag_center_name keys %{$dcc_scanned_file_info{$data_type}{$barcode}{$exp_center_name}}
                            ) {
                                for my $run_center_name (
                                    sort by_dag_center_name keys %{$dcc_scanned_file_info{$data_type}{$barcode}{$exp_center_name}{$library_name}}
                                ) {
                                    for my $analysis_center_name (
                                        sort by_dag_center_name keys %{$dcc_scanned_file_info{$data_type}{$barcode}{$exp_center_name}{$library_name}{$run_center_name}}
                                    ) {
                                        # init
                                        my $sdrf_dag_node_hashref = {};
                                        $dcc_protocol_idf_order_info{$analysis_center_name} = []
                                            unless defined $dcc_protocol_idf_order_info{$analysis_center_name};
                                        my $protocol_dag_custom_run_center = (
                                            exists($dcc_scanned_file_protocol_dag_conf{$data_type}{$run_center_name}) and
                                            exists($dcc_scanned_file_protocol_dag_conf{$data_type}{$run_center_name}{$analysis_center_name})
                                        ) ? $run_center_name
                                          : '_default';
                                        add_dcc_scanned_file_sdrf_dag_info({
                                            protocol_dag_nodes => $dcc_scanned_file_protocol_dag_conf{$data_type}{$protocol_dag_custom_run_center}{$analysis_center_name},
                                            file_info => $dcc_scanned_file_info{$data_type}{$barcode}{$exp_center_name}{$library_name}{$run_center_name}{$analysis_center_name},
                                            sdrf_dag_node => $sdrf_dag_node_hashref,
                                            protocol_idf_order_info => $dcc_protocol_idf_order_info{$analysis_center_name},
                                        });
                                        if (%{$sdrf_dag_node_hashref}) {
                                            $dcc_sdrf_dag_info{$data_type}{$barcode}{$exp_center_name}{$library_name}{$run_center_name}{$analysis_center_name} = $sdrf_dag_node_hashref;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if ($debug{all} or $debug{file_info}) {
                    print STDERR 
                        +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                        ": \%dcc_sdrf_dag_info:\n", Dumper(\%dcc_sdrf_dag_info);
                }
                my @exp_ids = map { keys %{$_->{exp_ids}} } values %{$merged_run_info_hashref->{$data_type}};
                my @library_names = map { keys %{$_->{library_name_barcode}} } values %{$merged_run_info_hashref->{$data_type}};
                my @run_ids = map { keys %{$_->{run_ids}} } values %{$merged_run_info_hashref->{$data_type}};
                if (
                    defined($mt_config_hashref->{dataset}) and
                    defined($mt_config_hashref->{dataset}->{'add_data_types'})
                ) {
                    for my $data_type (keys %{$mt_config_hashref->{dataset}->{'add_data_types'}}) {
                        for my $exp_center_name (keys %{$mt_config_hashref->{dataset}->{'add_data_types'}->{$data_type}->{'sdrf_dag_info'}}) {
                            for my $run_center_name (keys %{$mt_config_hashref->{dataset}->{'add_data_types'}->{$data_type}->{'sdrf_dag_info'}->{$exp_center_name}}) {
                                push @exp_ids, keys %{$merged_run_info_hashref->{$data_type}->{$run_center_name}->{exp_ids}};
                                push @library_names, keys %{$merged_run_info_hashref->{$data_type}->{$run_center_name}->{library_name_barcode}};
                                push @run_ids, keys %{$merged_run_info_hashref->{$data_type}->{$run_center_name}->{run_ids}};
                            }
                        }
                    }
                }
                @exp_ids = natsort uniq(@exp_ids);
                @library_names = natsort uniq(@library_names);
                @run_ids = natsort uniq(@run_ids);
                print scalar(@exp_ids), ' experiments / ', 
                      scalar(@library_names), ' libraries / ',
                      scalar(@run_ids), " runs\n";
                # get experiment package SRA-XML for each experiment and build MAGE-TAB IDF and SDRF data
                print "Getting XMLs and processing metadata\n";
                my (
                    @mage_tab_idf_data,
                    @mage_tab_sdrf_data,
                    @mage_tab_sdrf_dcc_col_headers,
                    @protocol_data,
                );
                my @mage_tab_file_basename_parts = (
                    $program_name,
                    $project_name,
                    $data_type,
                );
                push @mage_tab_file_basename_parts, $dataset if $dataset ne '_default';
                push @mage_tab_file_basename_parts, strftime('%Y%m%d', localtime);
                my $mage_tab_file_basename = join('_', @mage_tab_file_basename_parts);
                my $num_exps_processed = 0;
                my $num_exps_skipped = 0;
                for my $exp_id (@exp_ids) {
                    my $exp_pkg_set_xml;
                    my $exp_pkg_set_storable_file = "$CACHE_DIR/sra/xml/${exp_id}.pls";
                    if (!-f $exp_pkg_set_storable_file or !$use_cached_xml) {
                        my $response = $ua->get(
                            "http://trace.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?save=efetch&db=sra&rettype=xml&term=$exp_id"
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
                            my $exp_pkg_set_storable_dir = dirname($exp_pkg_set_storable_file);
                            if (!-d $exp_pkg_set_storable_dir) {
                                make_path($exp_pkg_set_storable_dir, { chmod => 0700 }) 
                                    or die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                           ": could not create $exp_pkg_set_storable_dir: $!";
                            }
                            lock_nstore($exp_pkg_set_xml, $exp_pkg_set_storable_file)
                                or die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                       ": could not serialize and store $exp_pkg_set_storable_file: $!";
                        }
                        else {
                            die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                  ": failed to get SRA $exp_id experiment package XML: ", $response->status_line, "\n";
                            next;
                        }
                    }
                    else {
                        $exp_pkg_set_xml = lock_retrieve($exp_pkg_set_storable_file)
                            or die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                   ": could not deserialize and retrieve $exp_pkg_set_storable_file: $!";
                    }
                    if ($exp_pkg_set_xml->{Error}) {
                        die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                              ": failed to get SRA $exp_id experiment package XML: $exp_pkg_set_xml->{Error}\n";
                        next;
                    }
                    # only one experiment package in each set since querying by experiment ID so to save some typing later
                    my $exp_pkg_xml = $exp_pkg_set_xml->{EXPERIMENT_PACKAGE};
                    # reorganize SAMPLE_ATTRIBUTES
                    my $new_sample_attrs_hashref;
                    if (ref($exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}) eq 'ARRAY') {
                        for my $sample_attr_hashref (@{$exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}}) {
                            if (!exists $new_sample_attrs_hashref->{$sample_attr_hashref->{TAG}}) {
                                $new_sample_attrs_hashref->{$sample_attr_hashref->{TAG}} = $sample_attr_hashref->{VALUE};
                            }
                            elsif (ref($new_sample_attrs_hashref->{$sample_attr_hashref->{TAG}}) eq 'ARRAY') {
                                push @{$new_sample_attrs_hashref->{$sample_attr_hashref->{TAG}}}, $sample_attr_hashref->{VALUE};
                            }
                            else {
                                $new_sample_attrs_hashref->{$sample_attr_hashref->{TAG}} = [
                                    $new_sample_attrs_hashref->{$sample_attr_hashref->{TAG}},
                                    $sample_attr_hashref->{VALUE},
                                ]
                            }
                        }
                    }
                    else {
                        $new_sample_attrs_hashref->{$exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{TAG}} = 
                            $exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{VALUE};
                    }
                    $exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES} = $new_sample_attrs_hashref;
                    # fix PROCESSING PIPELINEs
                    for my $xml_section ($exp_pkg_xml->{EXPERIMENT}, @{$exp_pkg_xml->{RUN_SET}}) {
                        if (
                            defined($xml_section->{PROCESSING}) and
                            defined($xml_section->{PROCESSING}->{PIPELINE}) and
                            defined($xml_section->{PROCESSING}->{PIPELINE}->{PIPE_SECTION}) and
                            ref($xml_section->{PROCESSING}->{PIPELINE}->{PIPE_SECTION}) eq 'HASH'
                        ) {
                            $xml_section->{PROCESSING}->{PIPELINE}->{PIPE_SECTION} = [
                                $xml_section->{PROCESSING}->{PIPELINE}->{PIPE_SECTION},
                            ]
                        }
                    }
                    # fix EXPERIMENT_ATTRIBUTES
                    if (
                        defined($exp_pkg_xml->{EXPERIMENT}->{EXPERIMENT_ATTRIBUTES}) and
                        ref($exp_pkg_xml->{EXPERIMENT}->{EXPERIMENT_ATTRIBUTES}) eq 'HASH'
                    ) {
                        $exp_pkg_xml->{EXPERIMENT}->{EXPERIMENT_ATTRIBUTES} = [
                            $exp_pkg_xml->{EXPERIMENT}->{EXPERIMENT_ATTRIBUTES},
                        ];
                    }
                    if ($debug{all} or $debug{xml}) {
                        print STDERR "\n",
                            +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                            ": \$exp_pkg_xml:\n", Dumper($exp_pkg_xml);
                    }
                    if (scalar(keys(%{$exp_pkg_xml->{EXPERIMENT}->{PLATFORM}})) > 1) {
                        die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": unexpected multiple experiment platforms: ", 
                            join(', ',  natsort keys(%{$exp_pkg_xml->{EXPERIMENT}->{PLATFORM}})), 
                            "\n"; 
                    }
                    my $exp_data_type;
                    if (exists $sra2dcc_data_type{$exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_STRATEGY}}) {
                        $exp_data_type = $sra2dcc_data_type{$exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_STRATEGY}};
                    }
                    else {
                        die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                            ": unrecognized data type $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_STRATEGY}";
                    }
                    (my $protocol_exp_data_type = $exp_data_type) =~ s/-//g;
                    my ($platform) = keys %{$exp_pkg_xml->{EXPERIMENT}->{PLATFORM}};
                    my $hardware_model = $exp_pkg_xml->{EXPERIMENT}->{PLATFORM}->{$platform}->{INSTRUMENT_MODEL};
                    $platform = defined($sra2dcc_platform{uc($platform)})
                              ? $sra2dcc_platform{uc($platform)}
                              : $platform;
                    if ($platform eq 'CGI' and (!defined($hardware_model) or $hardware_model =~ /^(unspecified|\s*)$/i)) {
                        $hardware_model = 'Complete Genomics';
                    }
                    my $protocol_hardware_model =
                        $hardware_model =~ /complete genomics/i   ? 'CGI'       :
                        $hardware_model =~ /genome analyzer IIx/i ? 'GAIIx'     :
                        $hardware_model =~ /genome analyzer II/i  ? 'GAII'      :
                        $hardware_model =~ /hiseq 2500/i          ? 'HiSeq2500' :
                        $hardware_model =~ /hiseq 2000/i          ? 'HiSeq2000' :
                        $hardware_model =~ /miseq/i               ? 'MiSeq'     :
                        $hardware_model =~ /ion(_| )torrent/i     ? 'IonPGM'    :
                        die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                            ": unknown hardware model $hardware_model";
                    # special experiment/run exclusions
                    if (
                        # TARGET ALLP1 and ALLP2 mRNA-seq
                        (
                            $program_name eq 'TARGET' and
                            $project_name eq 'ALL' and 
                            $data_type eq 'mRNA-seq' and
                            (
                                ( $dataset eq 'Phase1' and $exp_pkg_xml->{STUDY}->{alias} ne 'phs000463' ) or 
                                ( $dataset eq 'Phase2' and $exp_pkg_xml->{STUDY}->{alias} ne 'phs000464' )
                            )
                        ) or
                        # TARGET MDLS-PPTP
                        (
                            $program_name eq 'TARGET' and
                            $project_name eq 'MDLS-PPTP' and
                            defined($exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'histological type'}) and
                            uc($exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'histological type'}) ne 'PPTP'
                        ) or
                        # TARGET MDLS-NBL
                        (
                            $program_name eq 'TARGET' and
                            $project_name eq 'MDLS-NBL' and
                            defined($exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'histological type'}) and
                            uc($exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'histological type'}) ne 'NBL'
                        ) or
                        # TARGET OS-Toronto
                        (
                            $program_name eq 'TARGET' and
                            $project_name eq 'OS-Toronto' and
                            (
                                !exists($dcc_sdrf_dag_info{$data_type}) or
                                !exists($dcc_sdrf_dag_info{$data_type}{uc($exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'submitted sample id'})})
                            )
                        ) or
                        # TARGET RT
                        (
                            $program_name eq 'TARGET' and
                            $project_name eq 'RT' and
                            (
                                !exists($dcc_sdrf_dag_info{$data_type}) or
                                !exists($dcc_sdrf_dag_info{$data_type}{uc($exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'submitted sample id'})})
                            )
                        ) or
                        # TARGET Targeted-Capture IonTorrent verification (belongs with WXS)
                        (
                            $program_name eq 'TARGET' and
                            $data_type eq 'Targeted-Capture' and
                            $platform eq 'IonTorrent'
                        )
                    ) {
                        $num_exps_skipped++;
                        next;
                    }
                    my $exp_center_name = 
                        defined($exp_pkg_xml->{EXPERIMENT}->{center_name})
                            ? defined($sra2dcc_center_name{uc($exp_pkg_xml->{EXPERIMENT}->{center_name})})
                                ? $sra2dcc_center_name{uc($exp_pkg_xml->{EXPERIMENT}->{center_name})}
                                : $exp_pkg_xml->{EXPERIMENT}->{center_name}
                            : defined($exp_pkg_xml->{SUBMISSION}->{center_name})
                                ? defined($sra2dcc_center_name{uc($exp_pkg_xml->{SUBMISSION}->{center_name})})
                                    ? $sra2dcc_center_name{uc($exp_pkg_xml->{SUBMISSION}->{center_name})}
                                    : $exp_pkg_xml->{SUBMISSION}->{center_name}
                                : die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                      ": could not extract experiment center name from XML: $exp_id"; 
                    # build IDF data
                    for my $row_name (
                        nkeysort { $mage_tab_idf_row_idx_by_name{$_} } keys %mage_tab_idf_row_idx_by_name
                    ) {
                        # set IDF row value(s) only if haven't already been set
                        # special exception for configured dataset IDF merge rows
                        next unless !defined($mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{$row_name}]) or
                                    !@{$mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{$row_name}]} or
                                    ( 
                                        defined($mt_config_hashref->{dataset}) and
                                        defined($mt_config_hashref->{dataset}->{'merge_idf_row_names'}) and
                                        any { $row_name eq $_ } @{$mt_config_hashref->{dataset}->{'merge_idf_row_names'}}
                                    );
                        my @row_values;
                        if ($row_name eq 'MAGE-TAB Version') {
                            if (defined($mt_config_hashref->{idf}->{'mage_tab_version'})) {
                                push @row_values, $mt_config_hashref->{idf}->{'mage_tab_version'};
                            }
                        }
                        elsif ($row_name eq 'Investigation Title') {
                            push @row_values, (
                                defined($mt_config_hashref->{dataset}) and
                                defined($mt_config_hashref->{dataset}->{'investigation_title'})
                            ) ? $mt_config_hashref->{dataset}->{'investigation_title'}
                              : "$exp_pkg_xml->{STUDY}->{DESCRIPTOR}->{STUDY_TITLE} $data_type";
                        }
                        elsif ($row_name eq 'Experimental Design') {
                            if (
                                defined($mt_config_hashref->{dataset}) and
                                defined($mt_config_hashref->{dataset}->{'exp_design'})
                            ) {
                                push @row_values, @{$mt_config_hashref->{dataset}->{'exp_design'}};
                            }
                            elsif (
                                defined($mt_config_hashref->{idf}->{'exp_design'}) and
                                defined($mt_config_hashref->{idf}->{'exp_design'}->{$data_type})
                            ) {
                                push @row_values, @{$mt_config_hashref->{idf}->{'exp_design'}->{$data_type}};
                            }
                        }
                        elsif ($row_name eq 'Experimental Design Term Source REF') {
                            if (
                                defined($mt_config_hashref->{dataset}) and
                                defined($mt_config_hashref->{dataset}->{'exp_design'})
                            ) {
                                push @row_values, (
                                    $mt_config_hashref->{default}->{'term_source_ref'}
                                ) x scalar(@{$mt_config_hashref->{dataset}->{'exp_design'}});
                            }
                            elsif (
                                defined($mt_config_hashref->{idf}->{'exp_design'}) and
                                defined($mt_config_hashref->{idf}->{'exp_design'}->{$data_type})
                            ) {
                                push @row_values, (
                                    $mt_config_hashref->{default}->{'term_source_ref'}
                                ) x scalar(@{$mt_config_hashref->{idf}->{'exp_design'}->{$data_type}}); 
                            }
                        }
                        elsif ($row_name eq 'Person Last Name') {
                            for my $contacts_arrayref (
                                grep(defined, 
                                    $mt_config_hashref->{idf}->{'contacts'},
                                    $mt_config_hashref->{project}->{idf}->{'contacts'},
                                    $mt_config_hashref->{dataset}->{idf}->{'contacts'},
                                )
                            ) {
                                push @row_values, map {
                                    defined($_->{'last_name'}) ? $_->{'last_name'} : ''
                                } @{$contacts_arrayref};
                            }
                        }
                        elsif ($row_name eq 'Person First Name') {
                            for my $contacts_arrayref (
                                grep(defined, 
                                    $mt_config_hashref->{idf}->{'contacts'},
                                    $mt_config_hashref->{project}->{idf}->{'contacts'},
                                    $mt_config_hashref->{dataset}->{idf}->{'contacts'},
                                )
                            ) {
                                push @row_values, map {
                                    defined($_->{'first_name'}) ? $_->{'first_name'} : ''
                                } @{$contacts_arrayref};
                            }
                        }
                        elsif ($row_name eq 'Person Mid Initials') {
                            for my $contacts_arrayref (
                                grep(defined, 
                                    $mt_config_hashref->{idf}->{'contacts'},
                                    $mt_config_hashref->{project}->{idf}->{'contacts'},
                                    $mt_config_hashref->{dataset}->{idf}->{'contacts'},
                                )
                            ) {
                                push @row_values, map {
                                    defined($_->{'mid_initials'}) ? $_->{'mid_initials'} : ''
                                } @{$contacts_arrayref};
                            }
                        }
                        elsif ($row_name eq 'Person Email') {
                            for my $contacts_arrayref (
                                grep(defined, 
                                    $mt_config_hashref->{idf}->{'contacts'},
                                    $mt_config_hashref->{project}->{idf}->{'contacts'},
                                    $mt_config_hashref->{dataset}->{idf}->{'contacts'},
                                )
                            ) {
                                push @row_values, map {
                                    defined($_->{'email'}) ? $_->{'email'} : ''
                                } @{$contacts_arrayref};
                            }
                        }
                        elsif ($row_name eq 'Person Phone') {
                            for my $contacts_arrayref (
                                grep(defined, 
                                    $mt_config_hashref->{idf}->{'contacts'},
                                    $mt_config_hashref->{project}->{idf}->{'contacts'},
                                    $mt_config_hashref->{dataset}->{idf}->{'contacts'},
                                )
                            ) {
                                push @row_values, map {
                                    defined($_->{'phone'}) ? $_->{'phone'} : ''
                                } @{$contacts_arrayref};
                            }
                        }
                        elsif ($row_name eq 'Person Fax') {
                            for my $contacts_arrayref (
                                grep(defined, 
                                    $mt_config_hashref->{idf}->{'contacts'},
                                    $mt_config_hashref->{project}->{idf}->{'contacts'},
                                    $mt_config_hashref->{dataset}->{idf}->{'contacts'},
                                )
                            ) {
                                push @row_values, map {
                                    defined($_->{'fax'}) ? $_->{'fax'} : ''
                                } @{$contacts_arrayref};
                            }
                        }
                        elsif ($row_name eq 'Person Address') {
                            for my $contacts_arrayref (
                                grep(defined, 
                                    $mt_config_hashref->{idf}->{'contacts'},
                                    $mt_config_hashref->{project}->{idf}->{'contacts'},
                                    $mt_config_hashref->{dataset}->{idf}->{'contacts'}
                                )
                            ) {
                                push @row_values, map {
                                    defined($_->{'address'}) ? $_->{'address'} : ''
                                } @{$contacts_arrayref};
                            }
                        }
                        elsif ($row_name eq 'Person Affiliation') {
                            for my $contacts_arrayref (
                                grep(defined, 
                                    $mt_config_hashref->{idf}->{'contacts'},
                                    $mt_config_hashref->{project}->{idf}->{'contacts'},
                                    $mt_config_hashref->{dataset}->{idf}->{'contacts'},
                                )
                            ) {
                                push @row_values, map {
                                    defined($_->{'affiliation'}) ? $_->{'affiliation'} : ''
                                } @{$contacts_arrayref};
                            }
                        }
                        elsif ($row_name eq 'Person Roles') {
                            for my $contacts_arrayref (
                                grep(defined, 
                                    $mt_config_hashref->{idf}->{'contacts'},
                                    $mt_config_hashref->{project}->{idf}->{'contacts'},
                                    $mt_config_hashref->{dataset}->{idf}->{'contacts'},
                                )
                            ) {
                                push @row_values, map {
                                    defined($_->{'roles'}) ? join(';', @{$_->{'roles'}}) : ''
                                } @{$contacts_arrayref};
                            }
                        }
                        elsif ($row_name eq 'Person Roles Term Source REF') {
                            for my $contacts_arrayref (
                                grep(defined, 
                                    $mt_config_hashref->{idf}->{'contacts'},
                                    $mt_config_hashref->{project}->{idf}->{'contacts'},
                                    $mt_config_hashref->{dataset}->{idf}->{'contacts'},
                                )
                            ) {
                                push @row_values, map {
                                    defined($_->{'roles'}) 
                                        ? join(';', 
                                            (
                                                $mt_config_hashref->{default}->{'term_source_ref'}
                                            ) x @{$_->{'roles'}}
                                        )
                                        : ''
                                } @{$contacts_arrayref};
                            }
                        }
                        elsif ($row_name eq 'Experiment Description') {
                            push @row_values, $exp_pkg_xml->{STUDY}->{DESCRIPTOR}->{STUDY_ABSTRACT};
                        }
                        elsif ($row_name eq 'SDRF File') {
                            push @row_values, "$mage_tab_file_basename.sdrf.txt";
                        }
                        elsif ($row_name eq 'Term Source Name') {
                            for my $term_sources_arrayref (
                                grep(defined, 
                                    $mt_config_hashref->{idf}->{'term_sources'},
                                    $mt_config_hashref->{project}->{'term_sources'},
                                    $mt_config_hashref->{dataset}->{'term_sources'},
                                )
                            ) {
                                push @row_values, map {
                                    defined($_->{'name'}) ? $_->{'name'} : ''
                                } @{$term_sources_arrayref};
                                last;
                            }
                        }
                        elsif ($row_name eq 'Term Source File') {
                            for my $term_sources_arrayref (
                                grep(defined, 
                                    $mt_config_hashref->{idf}->{'term_sources'},
                                    $mt_config_hashref->{project}->{'term_sources'},
                                    $mt_config_hashref->{dataset}->{'term_sources'},
                                )
                            ) {
                                push @row_values, map {
                                    defined($_->{'file'}) ? $_->{'file'} : ''
                                } @{$term_sources_arrayref};
                                last;
                            }
                        }
                        elsif ($row_name eq 'Comment[SRA_STUDY]') {
                            push @row_values, $exp_pkg_xml->{STUDY}->{accession};
                        }
                        elsif ($row_name eq 'Comment[BioProject]') {
                            for my $external_id_hashref (@{$exp_pkg_xml->{STUDY}->{IDENTIFIERS}->{EXTERNAL_ID}}) {
                                if ($external_id_hashref->{namespace} =~ /bioproject/i) {
                                    push @row_values, $external_id_hashref->{content};
                                    last;
                                }
                            }
                            # alternate
                            if (!@row_values) {
                                for my $related_studies_hashref (@{$exp_pkg_xml->{STUDY}->{DESCRIPTOR}->{RELATED_STUDIES}}) {
                                    if ($related_studies_hashref->{IS_PRIMARY} =~ /true/i and 
                                        $related_studies_hashref->{RELATED_LINK}->{DB} =~ /bioproject/i) {
                                        push @row_values, $related_studies_hashref->{RELATED_LINK}->{LABEL};
                                        last;
                                    }
                                }
                            }
                        }
                        elsif ($row_name eq 'Comment[dbGaP Study]') {
                            for my $external_id_hashref (@{$exp_pkg_xml->{STUDY}->{IDENTIFIERS}->{EXTERNAL_ID}}) {
                                if ($external_id_hashref->{'namespace'} =~ /dbgap/i) {
                                    push @row_values, $external_id_hashref->{'content'};
                                    last;
                                }
                            }
                            # alternate
                            if (!@row_values) {
                                push @row_values, join(';', natsort @{$mt_config_hashref->{project}->{'dbGaP_study_ids'}});
                            }
                        }
                        if (
                            defined($mt_config_hashref->{dataset}) and
                            defined($mt_config_hashref->{dataset}->{'merge_idf_row_names'}) and
                            any { $row_name eq $_ } @{$mt_config_hashref->{dataset}->{'merge_idf_row_names'}} and
                            defined($mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{$row_name}]) and
                            @{$mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{$row_name}]}
                        ) {
                            for my $row_value (@row_values) {
                                if (none { $row_value eq $_ } @{$mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{$row_name}]}) {
                                    push @{$mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{$row_name}]}, $row_value;
                                }
                            }
                        }
                        else {
                            $mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{$row_name}] = \@row_values;
                        }
                    }
                    my $barcode = defined($exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'submitted sample id'})
                                ? uc($exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'submitted sample id'})
                                : defined($exp_pkg_xml->{SAMPLE}->{IDENTIFIERS}->{SUBMITTER_ID}->{'content'})
                                ? uc($exp_pkg_xml->{SAMPLE}->{IDENTIFIERS}->{SUBMITTER_ID}->{'content'})
                                : defined($exp_pkg_xml->{SAMPLE}->{'alias'})
                                ? uc($exp_pkg_xml->{SAMPLE}->{'alias'})
                                : die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                      ": could not determine sample ID/barcode from SRA-XML";
                    my (
                        $case_id, 
                        $true_sample_id, 
                        $disease_code, 
                        $tissue_code, 
                        $tissue_type, 
                        $xeno_cell_line_code, 
                        $nucleic_acid_ltr,
                    );
                    if ($barcode =~ /^$OCG_BARCODE_REGEXP$/) {
                        (
                            $case_id, 
                            $true_sample_id, 
                            $disease_code, 
                            $tissue_code, 
                            $tissue_type, 
                            $xeno_cell_line_code,
                            $nucleic_acid_ltr,
                        ) = @{get_barcode_info($barcode)}{qw(
                            case_id
                            sample_id
                            disease_code
                            tissue_code
                            tissue_type
                            xeno_cell_line_code
                            nucleic_acid_ltr
                        )};
                    }
                    # older projects that didn't have proper barcodes
                    elsif ($program_name eq 'CGCI' and $disease_proj eq 'NHL') {
                        $true_sample_id = $barcode;
                        if (defined $exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'histological type'}) {
                            if (uc($exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'histological type'}) eq 'DLBCL') {
                                $disease_code = 100;
                            }
                            elsif (uc($exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'histological type'}) eq 'FL') {
                                $disease_code = 101;
                            }
                        }
                        if (
                            defined($mt_config_hashref->{project}) and
                            defined($mt_config_hashref->{project}->{sample_info_by_old_id})
                        ) {
                            my $sample_info_hashref = $mt_config_hashref->{project}->{sample_info_by_old_id};
                            if (defined $sample_info_hashref->{$true_sample_id}) {
                                if (uc($sample_info_hashref->{$true_sample_id}->{disease}) eq 'DLBCL') {
                                    if (!defined $disease_code) {
                                        $disease_code = 100;
                                    }
                                    elsif ($disease_code != 100) {
                                        die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                            ": SRA-XML histological type '$exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'histological type'}' doesn't match sample data";
                                    }
                                }
                                elsif (uc($sample_info_hashref->{$true_sample_id}->{disease}) eq 'FL') {
                                    if (!defined $disease_code) {
                                        $disease_code = 101;
                                    }
                                    elsif ($disease_code != 101) {
                                        die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                            ": SRA-XML histological type '$exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'histological type'}' doesn't match sample data";
                                    }
                                }
                                if (defined $sample_info_hashref->{$true_sample_id}->{tissue_type}) {
                                    if ($sample_info_hashref->{$true_sample_id}->{tissue_type} eq 'Tumor') {
                                        $tissue_code = '01';
                                    }
                                    elsif ($sample_info_hashref->{$true_sample_id}->{tissue_type} eq 'Normal') {
                                        $tissue_code = '11';
                                    }
                                    elsif ($sample_info_hashref->{$true_sample_id}->{tissue_type} eq 'Cell Line') {
                                        $tissue_code = '50';
                                    }
                                }
                            }
                            else {
                                warn "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                     ": sample $true_sample_id not found in config\n";
                            }
                        }
                        else {
                            warn "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                                 ": 'sample_info_by_old_id' config missing\n";
                        }
                        $tissue_code = '' unless defined $tissue_code;
                        $nucleic_acid_ltr = '';
                    }
                    # build SDRF data
                    my @sdrf_exp_data;
                    for my $col_key (
                        nkeysort { $mage_tab_sdrf_base_col_idx_by_type_key{exp}{$_} } keys %{$mage_tab_sdrf_base_col_idx_by_type_key{exp}}
                    ) {
                        my $field_value = '';
                        if ($col_key eq 'Source Name') {
                            $field_value = $exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'submitted subject id'};
                        }
                        elsif ($col_key eq 'Provider') {
                            $field_value = 'Children\'s Oncology Group';
                        }
                        elsif ($col_key eq 'Material Type 1') {
                            $field_value = 'whole organism';
                        }
                        elsif ($col_key eq 'Term Source REF 1') {
                            $field_value = $mt_config_hashref->{default}->{'term_source_ref'};
                        }
                        elsif ($col_key eq 'Characteristics[Organism]') {
                            $field_value = $exp_pkg_xml->{SAMPLE}->{SAMPLE_NAME}->{SCIENTIFIC_NAME};
                        }
                        elsif ($col_key eq 'Term Source REF 2') {
                            $field_value = 'NCBITaxon';
                        }
                        elsif ($col_key eq 'Characteristics[Sex]') {
                            if (defined $exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'sex'}) {
                                $field_value = $exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'sex'};
                            }
                        }
                        elsif ($col_key eq 'Term Source REF 3') {
                            $field_value = 'NCIt';
                        }
                        elsif ($col_key eq 'Characteristics[DiseaseState]') {
                            my $ncit_disease = $disease_code eq '00' ? 'Normal' : 
                                               $disease_code eq '01' ? 'Diffuse Large B-Cell Lymphoma' :
                                               $disease_code eq '02' ? 'Lung Cancer' :
                                               $disease_code eq '10' ? 'Acute Lymphoblastic Leukemia' :
                                               $disease_code eq '20' ? 'Acute Myeloid Leukemia' :
                                               $disease_code eq '21' ? 'Acute Myeloid Leukemia' :
                                               $disease_code eq '30' ? 'Neuroblastoma' :
                                               $disease_code eq '40' ? 'Osteosarcoma' :
                                               $disease_code eq '41' ? 'Ewing Sarcoma' :
                                               $disease_code eq '50' ? 'Kidney Wilms Tumor' :
                                               $disease_code eq '51' ? 'Clear Cell Sarcoma of the Kidney' :
                                               $disease_code eq '52' ? 'Rhabdoid Tumor of the Kidney' :
                                               $disease_code eq '60' ? 'Ependymoma' :
                                               $disease_code eq '61' ? 'Glioblastoma' :
                                               $disease_code eq '62' ? 'Rhabdoid Tumor of the Kidney' :
                                               $disease_code eq '63' ? 'Low Grade Glioma' :
                                               $disease_code eq '64' ? 'Medulloblastoma' : 
                                               $disease_code eq '65' ? 'CNS Disease Other' : 
                                               $disease_code eq '70' ? 'Anaplastic Large Cell Lymphoma' :
                                               $disease_code eq '71' ? 'Burkitt Lymphoma' : 
                                               $disease_code eq '80' ? 'Rhabdomyosarcoma' :
                                               $disease_code eq '81' ? 'Non-Rhabdomyosarcoma Soft Tissue Sarcoma' :
                                               # special disease codes
                                               $disease_code eq '100' ? 'Diffuse Large B-Cell Lymphoma' :
                                               $disease_code eq '101' ? 'Follicular Lymphoma' :
                                               undef;
                            die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                ": unknown disease code $disease_code\n" unless $ncit_disease;
                            # special TARGET adjustments to NCIT disease ontology term
                            if ($program_name eq 'TARGET') {
                                if ($disease_code eq '10') {
                                    $ncit_disease = "Childhood $ncit_disease";
                                    if ($project_name eq 'ALL') {
                                        if (
                                            defined($mt_config_hashref->{project}) and
                                            defined($mt_config_hashref->{project}->{cases_by_disease})
                                        ) {
                                            my $cases_by_disease_hashref = $mt_config_hashref->{project}->{cases_by_disease};
                                            for my $disease_name (natsort keys %{$cases_by_disease_hashref}) {
                                                if (any { $case_id eq $_ } @{$cases_by_disease_hashref->{$disease_name}}) {
                                                    if ($disease_name eq 'B-ALL') {
                                                        $ncit_disease = 'Childhood B Acute Lymphoblastic Leukemia';
                                                        last;
                                                    }
                                                    elsif ($disease_name eq 'T-ALL') {
                                                        $ncit_disease = 'Childhood T Acute Lymphoblastic Leukemia';
                                                        last;
                                                    }
                                                    else {
                                                        warn "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                                             ": $case_id not found in cases_by_disease config\n";
                                                    }
                                                }
                                            }
                                        }
                                        else {
                                            warn "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                                 ": cases_by_disease config missing\n";
                                        }
                                    }
                                }
                                elsif (
                                    $disease_code eq '20' or
                                    $disease_code eq '21' or
                                    $disease_code eq '30' or
                                    $disease_code eq '40' or
                                    $disease_code eq '50'
                                ) {
                                    $ncit_disease = "Childhood $ncit_disease";
                                }
                            }
                            my $ncit_disease_state = $tissue_code eq '01' ? $ncit_disease :
                                                     $tissue_code eq '02' ? "Recurrent $ncit_disease" :
                                                     $tissue_code eq '03' ? $ncit_disease :
                                                     $tissue_code eq '04' ? "Recurrent $ncit_disease" :
                                                     $tissue_code eq '05' ? $ncit_disease :
                                                     $tissue_code eq '06' ? "Metastatic $ncit_disease" :
                                                     $tissue_code eq '09' ? $ncit_disease :
                                                     $tissue_code eq '10' ? $ncit_disease :
                                                     $tissue_code eq '11' ? $ncit_disease :
                                                     $tissue_code eq '12' ? $ncit_disease :
                                                     $tissue_code eq '13' ? $ncit_disease :
                                                     $tissue_code eq '14' ? $ncit_disease :
                                                     $tissue_code eq '15' ? $ncit_disease :
                                                     $tissue_code eq '16' ? $ncit_disease :
                                                     $tissue_code eq '20' ? $ncit_disease : 
                                                     $tissue_code eq '40' ? "Recurrent $ncit_disease" :
                                                     $tissue_code eq '41' ? $ncit_disease :
                                                     $tissue_code eq '42' ? $ncit_disease : 
                                                     $tissue_code eq '50' ? $ncit_disease :
                                                     $tissue_code eq '60' ? $ncit_disease :
                                                     $tissue_code eq '61' ? $ncit_disease :
                                                     # special exceptions
                                                     $disease_code eq '100' ? '' :
                                                     $disease_code eq '101' ? '' :
                                                     undef;
                            die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                ": unknown tissue code $tissue_code\n" unless defined $ncit_disease_state;
                            $field_value = $ncit_disease_state;
                        }
                        elsif ($col_key eq 'Term Source REF 4') {
                            $field_value = 'NCIt';
                        }
                        elsif ($col_key eq 'Comment[OCG Cohort]') {
                            if (
                                defined($mt_config_hashref->{project}) and
                                defined($mt_config_hashref->{project}->{cases_by_cohort})
                            ) {
                                my $cases_by_cohort_hashref = $mt_config_hashref->{project}->{cases_by_cohort};
                                for my $cohort_name (natsort keys %{$cases_by_cohort_hashref}) {
                                    if (any { $case_id eq $_ } @{$cases_by_cohort_hashref->{$cohort_name}}) {
                                        $field_value = ucfirst(lc($cohort_name));
                                        last;
                                    }
                                }
                            }
                            #else {
                            #    warn "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                            #         ": 'cases_by_cohort' config missing\n";
                            #}
                        }
                        elsif ($col_key eq 'Comment[dbGaP Study]') {
                            # only for datasets with runs from multiple dbGaP studies
                            if (
                                defined($mt_config_hashref->{dataset}) and
                                defined($mt_config_hashref->{dataset}->{incl_dbgap_study_sdrf})
                            ) {
                                for my $external_id_hashref (@{$exp_pkg_xml->{STUDY}->{IDENTIFIERS}->{EXTERNAL_ID}}) {
                                    if ($external_id_hashref->{'namespace'} =~ /dbgap/i) {
                                        $field_value = $external_id_hashref->{'content'};
                                        last;
                                    }
                                }
                            }
                        }
                        elsif ($col_key eq 'Comment[Alternate ID] 1') {
                            if (
                                defined($mt_config_hashref->{dataset}) and
                                defined($mt_config_hashref->{dataset}->{alt_id_by_case})
                            ) {
                                if (defined($mt_config_hashref->{dataset}->{alt_id_by_case}->{$case_id})) {
                                    $field_value = $mt_config_hashref->{dataset}->{alt_id_by_case}->{$case_id};
                                }
                            }
                            elsif (
                                defined($mt_config_hashref->{dataset}) and
                                defined($mt_config_hashref->{dataset}->{case_by_alt_id})
                            ) {
                                my $case_by_alt_id_hashref = $mt_config_hashref->{dataset}->{case_by_alt_id};
                                $field_value = first { $case_by_alt_id_hashref->{$_} eq $case_id } keys %{$case_by_alt_id_hashref};
                            }
                            elsif (
                                defined($mt_config_hashref->{project}) and
                                defined($mt_config_hashref->{project}->{alt_id_by_case})
                            ) {
                                if (defined($mt_config_hashref->{project}->{alt_id_by_case}->{$case_id})) {
                                    $field_value = $mt_config_hashref->{project}->{alt_id_by_case}->{$case_id};
                                }
                            }
                            elsif (
                                defined($mt_config_hashref->{project}) and
                                defined($mt_config_hashref->{project}->{case_by_alt_id})
                            ) {
                                my $case_by_alt_id_hashref = $mt_config_hashref->{project}->{case_by_alt_id};
                                $field_value = first { $case_by_alt_id_hashref->{$_} eq $case_id } keys %{$case_by_alt_id_hashref};
                            }
                        }
                        elsif ($col_key eq 'Sample Name') {
                            $field_value = $true_sample_id;
                        }
                        elsif ($col_key eq 'Material Type 2') {
                            $field_value = $tissue_code eq '20' ? 'cell line' :
                                           $tissue_code eq '50' ? 'cell line' :
                                                                  'organism part';
                        }
                        elsif ($col_key eq 'Term Source REF 5') {
                            $field_value = $mt_config_hashref->{default}->{'term_source_ref'};
                        }
                        elsif ($col_key eq 'Characteristics[OrganismPart]') {
                            my $ncit_organism_part = $tissue_code eq '01' ? 'Solid Tumor' :
                                                     $tissue_code eq '02' ? 'Solid Tumor' :
                                                     $tissue_code eq '03' ? 'Peripheral Blood' :
                                                     $tissue_code eq '04' ? 'Bone Marrow' :
                                                     $tissue_code eq '06' ? 'Metastatic Tumor' :
                                                     $tissue_code eq '09' ? 'Bone Marrow' :
                                                     $tissue_code eq '10' ? 'Peripheral Blood' :
                                                     $tissue_code eq '11' ? 'Normal Tissue' :
                                                     $tissue_code eq '13' ? 'EBV Immortalized Normal' :
                                                     $tissue_code eq '14' ? 'Bone Marrow' :
                                                     $tissue_code eq '15' ? 'Bone Marrow' :
                                                     $tissue_code eq '20' ? 'Cell Line' :
                                                     $tissue_code eq '40' ? 'Peripheral Blood' :
                                                     $tissue_code eq '41' ? 'Bone Marrow' :
                                                     $tissue_code eq '42' ? 'Peripheral Blood' :
                                                     $tissue_code eq '50' ? 'Cell Line' :
                                                     $tissue_code eq '60' ? 'Xenograft' :
                                                     $tissue_code eq '61' ? 'Xenograft' :
                                                     # special exceptions
                                                     $disease_code eq '100' ? '' :
                                                     $disease_code eq '101' ? '' :
                                                     undef;
                            die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                ": unknown tissue code $tissue_code\n" unless defined $ncit_organism_part;
                            $field_value = $ncit_organism_part;
                        }
                        elsif ($col_key eq 'Term Source REF 6') {
                            $field_value = 'NCIt';
                        }
                        elsif ($col_key eq 'Characteristics[PassageNumber]') {
                            if (
                                defined($mt_config_hashref->{dataset}) and
                                defined($mt_config_hashref->{dataset}->{exp_center_barcode_passage_number}) and
                                defined($mt_config_hashref->{dataset}->{exp_center_barcode_passage_number}->{$exp_center_name}) and
                                defined($mt_config_hashref->{dataset}->{exp_center_barcode_passage_number}->{$exp_center_name}->{$barcode})
                            ) {
                                $field_value = $mt_config_hashref->{dataset}->{exp_center_barcode_passage_number}->{$exp_center_name}->{$barcode};
                            }
                        }
                        elsif ($col_key eq 'Description 1') {
                            if (defined($exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'body site'})) {
                                $field_value = $exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'body site'};
                            }
                            if (
                                defined($mt_config_hashref->{sdrf}->{'nucleic_acid_ltr_sample_desc'}) and
                                defined($mt_config_hashref->{sdrf}->{'nucleic_acid_ltr_sample_desc'}->{$nucleic_acid_ltr})
                            ) {
                                my $sample_desc = $mt_config_hashref->{sdrf}->{'nucleic_acid_ltr_sample_desc'}->{$nucleic_acid_ltr};
                                if ($field_value ne '') {
                                    $field_value .= "; $sample_desc";
                                }
                                else {
                                    $field_value = $sample_desc;
                                }
                            }
                            $field_value = quote_for_mage_tab($field_value);
                        }
                        elsif ($col_key eq 'Protocol REF') {
                            my $protocol_type = 'Extraction';
                            my $protocol_hashref;
                            if (
                                defined($mt_config_hashref->{dataset}) and
                                defined($mt_config_hashref->{dataset}->{protocol_info}) and
                                defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}) and
                                defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name})
                            ) {
                                if (
                                    defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{filter}) and
                                    any { $barcode eq $_ } @{$mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{filter}->{barcodes}}
                                ) {
                                    $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{filter}->{data});
                                }
                                elsif (
                                    defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{default})
                                ) {
                                    $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{default}->{data});
                                }
                                if (defined $protocol_hashref) {
                                    # set default values if not specified in override
                                    for my $field (qw( idf_type term_source_ref )) {
                                        if (!defined($protocol_hashref->{$field})) {
                                            $protocol_hashref->{$field} = $protocol_base_types{$protocol_type}{data}{$field};
                                        }
                                    }
                                }
                            }
                            if (!defined $protocol_hashref) {
                                my $nucleic_acid_type = 
                                    uc($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_SOURCE}) eq 'GENOMIC' ? 'DNA' :
                                    uc($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_SOURCE}) eq 'TRANSCRIPTOMIC' ? 'RNA' :
                                    '';
                                $protocol_hashref = clone(
                                    $protocol_base_types{$protocol_type}{data}
                                );
                                my $protocol_object_name = $protocol_type;
                                $protocol_object_name = "${nucleic_acid_type}-${protocol_type}" if $nucleic_acid_type;
                                $protocol_hashref->{name} = get_lsid(
                                    authority => $center_info{$exp_center_name}{authority},
                                    namespace_prefix => $center_info{$exp_center_name}{namespace_prefix},
                                    namespace => 'Protocol',
                                    object => $protocol_object_name,
                                    revision => '01',
                                );
                            }
                            if (none { $protocol_hashref->{name} eq $_->{name} } @protocol_data) {
                                @{$protocol_hashref}{qw( type data_type center_name )} = ( $protocol_type, $exp_data_type, $exp_center_name );
                                push @protocol_data, $protocol_hashref;
                            }
                            $field_value = $protocol_hashref->{name};
                        }
                        elsif ($col_key eq 'Performer') {
                            $field_value = (
                                defined($exp_pkg_xml->{Organization}) and
                                defined($exp_pkg_xml->{Organization}->{type}) and 
                                lc($exp_pkg_xml->{Organization}->{type}) eq 'center' and
                                defined($exp_pkg_xml->{Organization}->{Name}) and
                                defined($exp_pkg_xml->{Organization}->{Name}->{content})
                            ) ? $exp_pkg_xml->{Organization}->{Name}->{content}
                              : $exp_center_name;
                        }
                        elsif ($col_key eq 'Extract Name') {
                            $field_value = $barcode;
                        }
                        elsif ($col_key eq 'Material Type 3') {
                            $field_value = $exp_pkg_xml->{SAMPLE}->{SAMPLE_ATTRIBUTES}->{'analyte type'};
                            if (!$field_value and $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_STRATEGY}) {
                                $field_value = 
                                    uc($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_SOURCE}) eq 'GENOMIC' ? 'DNA' :
                                    uc($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_SOURCE}) eq 'TRANSCRIPTOMIC' ? 'RNA' : 
                                    '';
                            }
                        }
                        elsif ($col_key eq 'Term Source REF 7') {
                            $field_value = $mt_config_hashref->{default}->{'term_source_ref'};
                        }
                        elsif ($col_key eq 'Comment[SRA_SAMPLE]') {
                            $field_value = $exp_pkg_xml->{SAMPLE}->{accession};
                        }
                        elsif ($col_key eq 'Comment[Alternate ID] 2') {
                            if (
                                defined($mt_config_hashref->{dataset}) and
                                defined($mt_config_hashref->{dataset}->{alt_id_by_barcode})
                            ) {
                                if (defined($mt_config_hashref->{dataset}->{alt_id_by_barcode}->{$barcode})) {
                                    $field_value = $mt_config_hashref->{dataset}->{alt_id_by_barcode}->{$barcode};
                                }
                            }
                            elsif (
                                defined($mt_config_hashref->{dataset}) and
                                defined($mt_config_hashref->{dataset}->{barcode_by_alt_id})
                            ) {
                                my $barcode_by_alt_id_hashref = 
                                    defined($mt_config_hashref->{dataset}->{barcode_by_alt_id}->{$exp_center_name})
                                        ? $mt_config_hashref->{dataset}->{barcode_by_alt_id}->{$exp_center_name}
                                        : $mt_config_hashref->{dataset}->{barcode_by_alt_id}->{'_default'};
                                $field_value = first { $barcode_by_alt_id_hashref->{$_} eq $barcode } keys %{$barcode_by_alt_id_hashref};
                            }
                            elsif (
                                defined($mt_config_hashref->{project}) and
                                defined($mt_config_hashref->{project}->{alt_id_by_barcode})
                            ) {
                                if (defined($mt_config_hashref->{project}->{alt_id_by_barcode}->{$barcode})) {
                                    $field_value = $mt_config_hashref->{project}->{alt_id_by_barcode}->{$barcode};
                                }
                            }
                            elsif (
                                defined($mt_config_hashref->{project}) and
                                defined($mt_config_hashref->{project}->{barcode_by_alt_id})
                            ) {
                                my $barcode_by_alt_id_hashref = $mt_config_hashref->{project}->{barcode_by_alt_id};
                                $field_value = first { $barcode_by_alt_id_hashref->{$_} eq $barcode } keys %{$barcode_by_alt_id_hashref};
                            }
                        }
                        elsif ($col_key eq 'Description 2') {
                            if (
                                defined($mt_config_hashref->{sdrf}->{'nucleic_acid_ltr_extract_desc'}) and
                                defined($mt_config_hashref->{sdrf}->{'nucleic_acid_ltr_extract_desc'}->{$nucleic_acid_ltr})
                            ) {
                                $field_value = quote_for_mage_tab(
                                    $mt_config_hashref->{sdrf}->{'nucleic_acid_ltr_extract_desc'}->{$nucleic_acid_ltr}
                                );
                            }
                        }
                        $sdrf_exp_data[$mage_tab_sdrf_base_col_idx_by_type_key{exp}{$col_key}] = defined($field_value) ? $field_value : '';
                    }
                    # library name can rarely be blank
                    my $exp_library_name = !ref($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_NAME})
                                         ? $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_NAME}
                                         : '';
                    my @exp_library_names;
                    if ($exp_library_name =~ /$sra_exp_library_name_delimiter/o) {
                        @exp_library_names = map { s/\s+//g; $_ } split($sra_exp_library_name_delimiter, $exp_library_name);
                    }
                    else {
                        push @exp_library_names, $exp_library_name;
                    }
                    for my $exp_library_name (@exp_library_names) {
                        # extract library prep protocol if exists
                        if (
                            (
                                (
                                    !defined($mt_config_hashref->{dataset}) or
                                    !defined($mt_config_hashref->{dataset}->{exp_centers_excl_lib_const_protocol}) or
                                    none { $exp_center_name eq $_ } @{$mt_config_hashref->{dataset}->{exp_centers_excl_lib_const_protocol}}
                                ) and
                                exists($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_CONSTRUCTION_PROTOCOL}) and
                                !ref($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_CONSTRUCTION_PROTOCOL}) and
                                # XXX: improve this
                                length($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_CONSTRUCTION_PROTOCOL}) >= 50
                            )
                            or
                            (
                                defined($mt_config_hashref->{dataset}) and
                                defined($mt_config_hashref->{dataset}->{exp_centers_incl_design_desc_protocol}) and
                                any { $exp_center_name eq $_ } @{$mt_config_hashref->{dataset}->{exp_centers_incl_design_desc_protocol}} and
                                !ref($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{DESIGN_DESCRIPTION})
                            )
                        ) {
                            my $protocol_type = 'LibraryPrep';
                            my $protocol_hashref;
                            if (
                                defined($mt_config_hashref->{dataset}) and
                                defined($mt_config_hashref->{dataset}->{protocol_info}) and
                                defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}) and
                                defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name})
                            ) {
                                if (
                                    defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{filter}) and
                                    any { $exp_library_name eq $_ } @{$mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{filter}->{library_names}}
                                ) {
                                    $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{filter}->{data});
                                }
                                elsif (
                                    defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{default})
                                ) {
                                    $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{default}->{data});
                                }
                                if (defined $protocol_hashref) {
                                    # set default values if not specified in override
                                    for my $field (qw( idf_type term_source_ref )) {
                                        if (!defined($protocol_hashref->{$field})) {
                                            $protocol_hashref->{$field} = $protocol_base_types{$protocol_type}{data}{$field};
                                        }
                                    }
                                }
                            }
                            if (!defined $protocol_hashref) {
                                $protocol_hashref = clone(
                                    $protocol_base_types{$protocol_type}{data}
                                );
                                $protocol_hashref->{name} = get_lsid(
                                    authority => $center_info{$exp_center_name}{authority},
                                    namespace_prefix => $center_info{$exp_center_name}{namespace_prefix},
                                    namespace => 'Protocol',
                                    object => "${protocol_exp_data_type}-${protocol_type}-${platform}",
                                    revision => '01',
                                );
                            }
                            $protocol_hashref->{description} = 
                                exists($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_CONSTRUCTION_PROTOCOL})
                                    ? $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_CONSTRUCTION_PROTOCOL}
                                    : $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{DESIGN_DESCRIPTION};
                            $protocol_hashref->{description} =~ s/^\s+//;
                            $protocol_hashref->{description} =~ s/\s+$//;
                            $protocol_hashref->{description} =~ s/\s+/ /g;
                            if (none { $protocol_hashref->{name} eq $_->{name} } @protocol_data) {
                                @{$protocol_hashref}{qw( type data_type center_name )} = ( $protocol_type, $exp_data_type, $exp_center_name );
                                push @protocol_data, $protocol_hashref;
                            }
                            else {
                                my $existing_protocol_hashref = first { $protocol_hashref->{name} eq $_->{name} } @protocol_data;
                                $existing_protocol_hashref->{description} = $protocol_hashref->{description} unless exists $existing_protocol_hashref->{description};
                            }
                        }
                        my @sdrf_lib_data;
                        for my $col_key (
                            nkeysort { $mage_tab_sdrf_base_col_idx_by_type_key{lib}{$_} } keys %{$mage_tab_sdrf_base_col_idx_by_type_key{lib}}
                        ) {
                            my $field_value = '';
                            if ($col_key eq 'Protocol REF 1') {
                                my $protocol_type = 'LibraryPrep';
                                my $protocol_hashref;
                                if (
                                    defined($mt_config_hashref->{dataset}) and
                                    defined($mt_config_hashref->{dataset}->{protocol_info}) and
                                    defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}) and
                                    defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name})
                                ) {
                                    if (
                                        defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{filter}) and
                                        any { $exp_library_name eq $_ } @{$mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{filter}->{library_names}}
                                    ) {
                                        $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{filter}->{data});
                                    }
                                    elsif (
                                        defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{default})
                                    ) {
                                        $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{default}->{data});
                                    }
                                    if (defined $protocol_hashref) {
                                        # set default values if not specified in override
                                        for my $field (qw( idf_type term_source_ref )) {
                                            if (!defined($protocol_hashref->{$field})) {
                                                $protocol_hashref->{$field} = $protocol_base_types{$protocol_type}{data}{$field};
                                            }
                                        }
                                    }
                                }
                                if (!defined $protocol_hashref) {
                                    $protocol_hashref = clone(
                                        $protocol_base_types{$protocol_type}{data}
                                    );
                                    $protocol_hashref->{name} = get_lsid(
                                        authority => $center_info{$exp_center_name}{authority},
                                        namespace_prefix => $center_info{$exp_center_name}{namespace_prefix},
                                        namespace => 'Protocol',
                                        object => "${protocol_exp_data_type}-${protocol_type}-${platform}",
                                        revision => '01',
                                    );
                                }
                                if (none { $protocol_hashref->{name} eq $_->{name} } @protocol_data) {
                                    @{$protocol_hashref}{qw( type data_type center_name )} = ( $protocol_type, $exp_data_type, $exp_center_name );
                                    push @protocol_data, $protocol_hashref;
                                }
                                $field_value = $protocol_hashref->{name};
                            }
                            elsif ($col_key eq 'Protocol REF 2') {
                                if ($exp_data_type eq 'WXS') {
                                    my $protocol_type = 'ExomeCapture';
                                    my $protocol_hashref;
                                    if (
                                        defined($mt_config_hashref->{dataset}) and
                                        defined($mt_config_hashref->{dataset}->{protocol_info}) and
                                        defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}) and
                                        defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name})
                                    ) {
                                        if (
                                            defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{filter}) and
                                            any { $exp_library_name eq $_ } @{$mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{filter}->{library_names}}
                                        ) {
                                            $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{filter}->{data});
                                        }
                                        elsif (
                                            defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{default})
                                        ) {
                                            $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$exp_center_name}->{default}->{data});
                                        }
                                        if (defined $protocol_hashref) {
                                            # set default values if not specified in override
                                            for my $field (qw( idf_type term_source_ref )) {
                                                if (!defined($protocol_hashref->{$field})) {
                                                    $protocol_hashref->{$field} = $protocol_base_types{$protocol_type}{data}{$field};
                                                }
                                            }
                                        }
                                    }
                                    if (!defined $protocol_hashref) {
                                        $protocol_hashref = clone(
                                            $protocol_base_types{$protocol_type}{data}
                                        );
                                        $protocol_hashref->{name} = get_lsid(
                                            authority => $center_info{$exp_center_name}{authority},
                                            namespace_prefix => $center_info{$exp_center_name}{namespace_prefix},
                                            namespace => 'Protocol',
                                            object => "${protocol_exp_data_type}-${protocol_type}-${platform}",
                                            revision => '01',
                                        );
                                    }
                                    if (none { $protocol_hashref->{name} eq $_->{name} } @protocol_data) {
                                        @{$protocol_hashref}{qw( type data_type center_name )} = ( $protocol_type, $exp_data_type, $exp_center_name );
                                        push @protocol_data, $protocol_hashref;
                                    }
                                    $field_value = $protocol_hashref->{name};
                                }
                            }
                            elsif ($col_key eq 'Performer') {
                                $field_value = (
                                    defined($exp_pkg_xml->{Organization}) and
                                    defined($exp_pkg_xml->{Organization}->{type}) and 
                                    lc($exp_pkg_xml->{Organization}->{type}) eq 'center' and
                                    defined($exp_pkg_xml->{Organization}->{Name}) and
                                    defined($exp_pkg_xml->{Organization}->{Name}->{content})
                                ) ? $exp_pkg_xml->{Organization}->{Name}->{content}
                                  : $exp_center_name;
                            }
                            elsif ($col_key eq 'Extract Name') {
                                $field_value = "$barcode " . ( $exp_library_name ? "$exp_library_name " : '' ) . 'library';
                            }
                            elsif ($col_key eq 'Comment[LIBRARY_LAYOUT]') {
                                ($field_value) = keys %{$exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_LAYOUT}};
                            }
                            elsif ($col_key eq 'Comment[LIBRARY_SOURCE]') {
                                $field_value = $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_SOURCE};
                            }
                            elsif ($col_key eq 'Comment[LIBRARY_STRATEGY]') {
                                $field_value = $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_STRATEGY};
                            }
                            elsif ($col_key eq 'Comment[LIBRARY_SELECTION]') {
                                $field_value = $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_SELECTION};
                            }
                            elsif ($col_key eq 'Comment[LIBRARY_STRAND]') {
                                if ($data_type eq 'mRNA-seq') {
                                    # todo
                                }
                            }
                            elsif ($col_key eq 'Comment[NOMINAL_LENGTH]') {
                                if (
                                    defined($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_LAYOUT}->{PAIRED}) and
                                    defined($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_LAYOUT}->{PAIRED}->{NOMINAL_LENGTH})
                                ) {
                                    $field_value = $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_LAYOUT}->{PAIRED}->{NOMINAL_LENGTH};
                                }
                            }
                            elsif ($col_key eq 'Comment[NOMINAL_SDEV]') {
                                if (
                                    defined($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_LAYOUT}->{PAIRED}) and
                                    defined($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_LAYOUT}->{PAIRED}->{NOMINAL_SDEV}) and
                                    $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_LAYOUT}->{PAIRED}->{NOMINAL_SDEV} != 0
                                ) {
                                    $field_value = $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_LAYOUT}->{PAIRED}->{NOMINAL_SDEV};
                                }
                            }
                            elsif ($col_key eq 'Comment[LIBRARY_NAME]') {
                                $field_value = $exp_library_name;
                            }
                            elsif ($col_key eq 'Comment[SRA_EXPERIMENT]') {
                                $field_value = $exp_pkg_xml->{EXPERIMENT}->{accession};
                            }
                            elsif ($col_key eq 'Comment[Library Batch]') {
                                if (
                                    defined($exp_pkg_xml->{EXPERIMENT}->{EXPERIMENT_ATTRIBUTES}) and
                                    any { $_->{TAG} =~ /batch/i } @{$exp_pkg_xml->{EXPERIMENT}->{EXPERIMENT_ATTRIBUTES}}
                                ) {
                                    my $exp_attr = first { $_->{TAG} =~ /batch/i } @{$exp_pkg_xml->{EXPERIMENT}->{EXPERIMENT_ATTRIBUTES}};
                                    $field_value = $exp_attr->{VALUE};
                                }
                            }
                            elsif ($col_key eq 'Description') {
                                if (
                                    !defined($mt_config_hashref->{dataset}) or
                                    (
                                        !defined($mt_config_hashref->{dataset}->{exp_centers_excl_exp_desc}) or
                                        none { $exp_center_name eq $_ } @{$mt_config_hashref->{dataset}->{exp_centers_excl_exp_desc}}
                                    ) and 
                                    (
                                        !defined($mt_config_hashref->{dataset}->{exp_centers_incl_design_desc_protocol}) or
                                        none { $exp_center_name eq $_ } @{$mt_config_hashref->{dataset}->{exp_centers_incl_design_desc_protocol}}
                                    )
                                ) {
                                    if (!ref($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{DESIGN_DESCRIPTION})) {
                                        $field_value = quote_for_mage_tab($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{DESIGN_DESCRIPTION});
                                    }
                                    elsif (
                                        ref($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{DESIGN_DESCRIPTION}) ne 'HASH' or
                                        %{$exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{DESIGN_DESCRIPTION}}
                                    ) {
                                        warn "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid design description:\n", 
                                             Dumper($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{DESIGN_DESCRIPTION});
                                    }
                                }
                            }
                            $sdrf_lib_data[$mage_tab_sdrf_base_col_idx_by_type_key{lib}{$col_key}] = defined($field_value) ? $field_value : '';
                        }
                        my @sdrf_run_set_data;
                        for my $run_xml (@{$exp_pkg_xml->{RUN_SET}}) {
                            my $run_center_name = 
                                defined($run_xml->{run_center})
                                    ? defined($sra2dcc_center_name{uc($run_xml->{run_center})})
                                        ? $sra2dcc_center_name{uc($run_xml->{run_center})}
                                        : $run_xml->{run_center}
                                    : defined($run_xml->{center_name})
                                        ? defined($sra2dcc_center_name{uc($run_xml->{center_name})})
                                            ? $sra2dcc_center_name{uc($run_xml->{center_name})}
                                            : $run_xml->{center_name}
                                        : defined($exp_pkg_xml->{SUBMISSION}->{center_name})
                                            ? defined($sra2dcc_center_name{uc($exp_pkg_xml->{SUBMISSION}->{center_name})})
                                                ? $sra2dcc_center_name{uc($exp_pkg_xml->{SUBMISSION}->{center_name})}
                                                : $exp_pkg_xml->{SUBMISSION}->{center_name}
                                            : die "\n", +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                                  ": could not extract run center name from XML: $run_xml->{accession}";
                            my @sdrf_run_data;
                            for my $col_key (
                                nkeysort { $mage_tab_sdrf_base_col_idx_by_type_key{run}{$_} } keys %{$mage_tab_sdrf_base_col_idx_by_type_key{run}}
                            ) {
                                my $field_value = '';
                                if ($col_key eq 'Protocol REF 1') {
                                    my $protocol_type = 'Sequence';
                                    my $protocol_hashref;
                                    if (
                                        defined($mt_config_hashref->{dataset}) and
                                        defined($mt_config_hashref->{dataset}->{protocol_info}) and
                                        defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}) and
                                        defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name})
                                    ) {
                                        if (
                                            defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{filter}) and
                                            any { $run_xml->{accession} eq $_ } @{$mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{filter}->{run_ids}}
                                        ) {
                                            $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{filter}->{data});
                                        }
                                        elsif (
                                            defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{default})
                                        ) {
                                            $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{default}->{data});
                                        }
                                        if (defined $protocol_hashref) {
                                            # set default values if not specified in override
                                            for my $field (qw( idf_type term_source_ref )) {
                                                if (!defined($protocol_hashref->{$field})) {
                                                    $protocol_hashref->{$field} = $protocol_base_types{$protocol_type}{data}{$field};
                                                }
                                            }
                                        }
                                    }
                                    if (!defined $protocol_hashref) {
                                        $protocol_hashref = clone(
                                            $protocol_base_types{$protocol_type}{data}
                                        );
                                        $protocol_hashref->{name} = get_lsid(
                                            authority => $center_info{$run_center_name}{authority},
                                            namespace_prefix => $center_info{$run_center_name}{namespace_prefix},
                                            namespace => 'Protocol',
                                            object => "${protocol_exp_data_type}-${protocol_type}-${platform}-${protocol_hardware_model}",
                                            revision => '01',
                                        );
                                        $protocol_hashref->{hardware} = $hardware_model;
                                    }
                                    if (none { $protocol_hashref->{name} eq $_->{name} } @protocol_data) {
                                        @{$protocol_hashref}{qw( type data_type center_name )} = ( $protocol_type, $exp_data_type, $run_center_name );
                                        push @protocol_data, $protocol_hashref;
                                    }
                                    $field_value = $protocol_hashref->{name};
                                }
                                elsif ($col_key eq 'Performer') {
                                    $field_value = $run_center_name;
                                }
                                elsif ($col_key eq 'Date') {
                                    if (defined $run_xml->{run_date}) {
                                        $field_value = substr($run_xml->{run_date}, 0, 10);
                                    }
                                    elsif (
                                        defined($run_xml->{RUN_ATTRIBUTES}) and
                                        any { $_->{TAG} =~ /^sequencing(\s+|_|-)date$/i } @{$run_xml->{RUN_ATTRIBUTES}}
                                    ) {
                                        my $run_attr = first { $_->{TAG} =~ /^sequencing(\s+|_|-)date$/i } @{$run_xml->{RUN_ATTRIBUTES}};
                                        $field_value = substr($run_attr->{VALUE}, 0, 10);
                                    }
                                }
                                elsif ($col_key eq 'Assay Name') {
                                    $field_value = "$barcode " . ( $exp_library_name ? "$exp_library_name " : '' ) . 'run';
                                }
                                elsif ($col_key eq 'Technology Type') {
                                    $field_value = 'sequencing assay';
                                }
                                elsif ($col_key eq 'Term Source REF') {
                                    $field_value = $mt_config_hashref->{default}->{'term_source_ref'};
                                }
                                elsif ($col_key eq 'Comment[SPOT_LENGTH]') {
                                    if (
                                        defined($run_xml->{total_bases}) and
                                        defined($run_xml->{total_spots})
                                    ) {
                                        $field_value = round($run_xml->{total_bases} / $run_xml->{total_spots});
                                    }
                                    elsif (
                                        defined($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{SPOT_DESCRIPTOR}) and
                                        defined($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{SPOT_DESCRIPTOR}->{SPOT_DECODE_SPEC}) and
                                        defined($exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{SPOT_DESCRIPTOR}->{SPOT_DECODE_SPEC}->{SPOT_LENGTH})
                                    ) {
                                        $field_value = $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{SPOT_DESCRIPTOR}->{SPOT_DECODE_SPEC}->{SPOT_LENGTH};
                                    }
                                }
                                elsif ($col_key eq 'Protocol REF 2') {
                                    my $protocol_type = 'BaseCall';
                                    my $protocol_hashref;
                                    if (
                                        defined($mt_config_hashref->{dataset}) and
                                        defined($mt_config_hashref->{dataset}->{protocol_info}) and
                                        defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}) and
                                        defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name})
                                    ) {
                                        if (
                                            defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{filter}) and
                                            any { $run_xml->{accession} eq $_ } @{$mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{filter}->{run_ids}}
                                        ) {
                                            $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{filter}->{data});
                                        }
                                        elsif (
                                            defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{default})
                                        ) {
                                            $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{default}->{data});
                                        }
                                        if (defined $protocol_hashref) {
                                            # set default values if not specified in override
                                            for my $field (qw( idf_type term_source_ref )) {
                                                if (!defined($protocol_hashref->{$field})) {
                                                    $protocol_hashref->{$field} = $protocol_base_types{$protocol_type}{data}{$field};
                                                }
                                            }
                                        }
                                    }
                                    if (!defined $protocol_hashref) {
                                        $protocol_hashref = clone(
                                            $protocol_base_types{$protocol_type}{data}
                                        );
                                        $protocol_hashref->{name} = get_lsid(
                                            authority => $center_info{$run_center_name}{authority},
                                            namespace_prefix => $center_info{$run_center_name}{namespace_prefix},
                                            namespace => 'Protocol',
                                            object => "${protocol_exp_data_type}-${protocol_type}-${platform}",
                                            revision => '01',
                                        );
                                    }
                                    if (none { $protocol_hashref->{name} eq $_->{name} } @protocol_data) {
                                        @{$protocol_hashref}{qw( type data_type center_name )} = ( $protocol_type, $exp_data_type, $run_center_name );
                                        push @protocol_data, $protocol_hashref;
                                    }
                                    $field_value = $protocol_hashref->{name};
                                    my $stored_protocol_hashref = first { $protocol_hashref->{name} eq $_->{name} } @protocol_data;
                                    for my $xml_section ($exp_pkg_xml->{EXPERIMENT}, $run_xml) {
                                        if (
                                            defined($xml_section->{PROCESSING}) and
                                            defined($xml_section->{PROCESSING}->{PIPELINE}) and
                                            defined($xml_section->{PROCESSING}->{PIPELINE}->{PIPE_SECTION})
                                        ) {
                                            for my $pipe_section_hashref (natkeysort { $_->{STEP_INDEX} } @{$xml_section->{PROCESSING}->{PIPELINE}->{PIPE_SECTION}}) {
                                                if (
                                                    defined($pipe_section_hashref->{section_name}) and
                                                    # matching BaseCall pipeline sections
                                                    $pipe_section_hashref->{section_name} =~ /^(BASE(_|-|\s+)CALL|QUALITY(_|-|\s+)SCORE|Bcl-to-Fastq)/i and
                                                    !ref($pipe_section_hashref->{PROGRAM}) and
                                                    (
                                                        !defined($stored_protocol_hashref->{software}) or
                                                        none { $pipe_section_hashref->{PROGRAM} eq $_ } @{$stored_protocol_hashref->{software}}
                                                    )
                                                ) {
                                                    push @{$stored_protocol_hashref->{software}}, $pipe_section_hashref->{PROGRAM};
                                                    if (
                                                        !defined($stored_protocol_hashref->{parameters}) or
                                                        !@{$stored_protocol_hashref->{parameters}}
                                                    ) {
                                                        push @{$stored_protocol_hashref->{parameters}}, 'Software Versions';
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                elsif ($col_key eq 'Parameter Value[Software Versions]') {
                                    my @software_versions;
                                    for my $xml_section ($exp_pkg_xml->{EXPERIMENT}, $run_xml) {
                                        if (
                                            defined($xml_section->{PROCESSING}) and
                                            defined($xml_section->{PROCESSING}->{PIPELINE}) and
                                            defined($xml_section->{PROCESSING}->{PIPELINE}->{PIPE_SECTION})
                                        ) {
                                            for my $pipe_section_hashref (natkeysort { $_->{STEP_INDEX} } @{$xml_section->{PROCESSING}->{PIPELINE}->{PIPE_SECTION}}) {
                                                if (
                                                    defined($pipe_section_hashref->{section_name}) and
                                                    # matching BaseCall pipeline sections
                                                    $pipe_section_hashref->{section_name} =~ /^(BASE(_|-|\s+)CALL|QUALITY(_|-|\s+)SCORE|Bcl-to-Fastq)/i and
                                                    !ref($pipe_section_hashref->{VERSION}) and
                                                    none { "$pipe_section_hashref->{PROGRAM} $pipe_section_hashref->{VERSION}" eq $_ } @software_versions
                                                ) {
                                                    push @software_versions, "$pipe_section_hashref->{PROGRAM} $pipe_section_hashref->{VERSION}";
                                                }
                                            }
                                        }
                                    }
                                    if (@software_versions) {
                                        $field_value = join(';', @software_versions);
                                    }
                                }
                                $sdrf_run_data[$mage_tab_sdrf_base_col_idx_by_type_key{run}{$col_key}] = defined($field_value) ? $field_value : '';
                            }
                            my $is_bam_run = (
                                defined($run_xml->{Databases}) and
                                defined($run_xml->{Databases}->{Table}) and
                                defined($run_xml->{Databases}->{Table}->{PRIMARY_ALIGNMENT})
                            ) ? 1 : 0;
                            if (!$is_bam_run) {
                                my @sdrf_run_fastq_data;
                                for my $col_key (
                                    nkeysort { $mage_tab_sdrf_base_col_idx_by_type_key{run_fastq}{$_} } keys %{$mage_tab_sdrf_base_col_idx_by_type_key{run_fastq}}
                                ) {
                                    my $field_value = '';
                                    if ($col_key eq 'Scan Name') {
                                        if (defined $run_xml->{alias}) {
                                            $field_value = $run_xml->{alias} =~ /\.fastq(\.gz)?$/i
                                                         ? $run_xml->{alias}
                                                         : "$run_xml->{alias}.fastq";
                                        }
                                        elsif (defined $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_NAME}) {
                                            $field_value = "$exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_NAME}.fastq";
                                        }
                                    }
                                    elsif ($col_key eq 'Comment[SUBMITTED_FILE_NAME]') {
                                        if (
                                            defined($run_xml->{alias}) and
                                            $run_xml->{alias} =~ /\.fastq(\.gz)?$/i and
                                            $run_xml->{alias} ne $sdrf_run_fastq_data[$mage_tab_sdrf_base_col_idx_by_type_key{run_fastq}{'Scan Name'}]
                                        ) {
                                            $field_value = $run_xml->{alias};
                                        }
                                    }
                                    elsif ($col_key eq 'Comment[SRA_RUN]') {
                                        $field_value = $run_xml->{accession};
                                    }
                                    elsif ($col_key eq 'Comment[SRA_FILE_URI]') {
                                        my $study_acc  = $exp_pkg_xml->{STUDY}->{accession};
                                        my $sample_acc = $exp_pkg_xml->{SAMPLE}->{accession};
                                        my $exp_acc    = $exp_pkg_xml->{EXPERIMENT}->{accession};
                                        my $run_acc    = $run_xml->{accession};
                                        $field_value = "\@dbgap\@:reads/$study_acc/$sample_acc/$exp_acc/$run_acc/$run_acc.sra";
                                    }
                                    elsif ($col_key eq 'Comment[OCG Data Level]') {
                                        $field_value = '1';
                                    }
                                    elsif ($col_key eq 'Comment[QC Warning]') {
                                        if (
                                            defined($mt_config_hashref->{dataset}) and
                                            defined($mt_config_hashref->{dataset}->{exp_center_library_data_qc_warning}) and
                                            defined($mt_config_hashref->{dataset}->{exp_center_library_data_qc_warning}->{$exp_center_name}) and
                                            defined($mt_config_hashref->{dataset}->{exp_center_library_data_qc_warning}->{$exp_center_name}->{$exp_library_name})
                                        ) {
                                            $field_value = $mt_config_hashref->{dataset}->{exp_center_library_data_qc_warning}->{$exp_center_name}->{$exp_library_name};
                                        }
                                    }
                                    $sdrf_run_fastq_data[$mage_tab_sdrf_base_col_idx_by_type_key{run_fastq}{$col_key}] = defined($field_value) ? $field_value : '';
                                }
                                push @sdrf_run_set_data, {
                                    run => \@sdrf_run_data,
                                    data => \@sdrf_run_fastq_data,
                                    is_bam_run => $is_bam_run,
                                    run_center_name => $run_center_name,
                                };
                            }
                            else {
                                my @sdrf_run_bam_data;
                                for my $col_key (
                                    nkeysort { $mage_tab_sdrf_base_col_idx_by_type_key{run_bam}{$_} } keys %{$mage_tab_sdrf_base_col_idx_by_type_key{run_bam}}
                                ) {
                                    my $field_value = '';
                                    if ($col_key eq 'Protocol REF') {
                                        my $protocol_type = 'ReadAlign';
                                        my $protocol_hashref;
                                        if (
                                            defined($mt_config_hashref->{dataset}) and
                                            defined($mt_config_hashref->{dataset}->{protocol_info}) and
                                            defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}) and
                                            defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name})
                                        ) {
                                            if (
                                                defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{filter}) and
                                                any { $run_xml->{accession} eq $_ } @{$mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{filter}->{run_ids}}
                                            ) {
                                                $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{filter}->{data});
                                            }
                                            elsif (
                                                defined($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{default})
                                            ) {
                                                $protocol_hashref = clone($mt_config_hashref->{dataset}->{protocol_info}->{$protocol_type}->{$run_center_name}->{default}->{data});
                                            }
                                            if (defined $protocol_hashref) {
                                                # set default values if not specified in override
                                                for my $field (qw( idf_type term_source_ref )) {
                                                    if (!defined($protocol_hashref->{$field})) {
                                                        $protocol_hashref->{$field} = $protocol_base_types{$protocol_type}{data}{$field};
                                                    }
                                                }
                                            }
                                        }
                                        if (!defined $protocol_hashref) {
                                            $protocol_hashref = clone(
                                                $protocol_base_types{$protocol_type}{data}
                                            );
                                            $protocol_hashref->{name} = get_lsid(
                                                authority => $center_info{$run_center_name}{authority},
                                                namespace_prefix => $center_info{$run_center_name}{namespace_prefix},
                                                namespace => 'Protocol',
                                                object => "${protocol_exp_data_type}-${protocol_type}",
                                                revision => '01',
                                            );
                                        }
                                        if (none { $protocol_hashref->{name} eq $_->{name} } @protocol_data) {
                                            @{$protocol_hashref}{qw( type data_type center_name )} = ( $protocol_type, $exp_data_type, $run_center_name );
                                            push @protocol_data, $protocol_hashref;
                                        }
                                        $field_value = $protocol_hashref->{name};
                                        my $stored_protocol_hashref = first { $protocol_hashref->{name} eq $_->{name} } @protocol_data;
                                        for my $xml_section ($exp_pkg_xml->{EXPERIMENT}, $run_xml) {
                                            if (
                                                defined($xml_section->{PROCESSING}) and
                                                defined($xml_section->{PROCESSING}->{PIPELINE}) and
                                                defined($xml_section->{PROCESSING}->{PIPELINE}->{PIPE_SECTION})
                                            ) {
                                                for my $pipe_section_hashref (natkeysort { $_->{STEP_INDEX} } @{$xml_section->{PROCESSING}->{PIPELINE}->{PIPE_SECTION}}) {
                                                    if (
                                                        defined($pipe_section_hashref->{section_name}) and
                                                        # not matching BaseCall pipeline sections
                                                        $pipe_section_hashref->{section_name} !~ /^(BASE(_|-|\s+)CALL|QUALITY(_|-|\s+)SCORE|Bcl-to-Fastq)/i and
                                                        !ref($pipe_section_hashref->{PROGRAM}) and
                                                        (
                                                            !defined($stored_protocol_hashref->{software}) or
                                                            none { $pipe_section_hashref->{PROGRAM} eq $_ } @{$stored_protocol_hashref->{software}}
                                                        )
                                                    ) {
                                                        push @{$stored_protocol_hashref->{software}}, $pipe_section_hashref->{PROGRAM};
                                                        if (
                                                            !defined($stored_protocol_hashref->{parameters}) or
                                                            !@{$stored_protocol_hashref->{parameters}}
                                                        ) {
                                                            push @{$stored_protocol_hashref->{parameters}}, 'Software Versions';
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    elsif ($col_key eq 'Parameter Value[Software Versions]') {
                                        my @software_versions;
                                        for my $xml_section ($exp_pkg_xml->{EXPERIMENT}, $run_xml) {
                                            if (
                                                defined($xml_section->{PROCESSING}) and
                                                defined($xml_section->{PROCESSING}->{PIPELINE}) and
                                                defined($xml_section->{PROCESSING}->{PIPELINE}->{PIPE_SECTION})
                                            ) {
                                                for my $pipe_section_hashref (natkeysort { $_->{STEP_INDEX} } @{$xml_section->{PROCESSING}->{PIPELINE}->{PIPE_SECTION}}) {
                                                    if (
                                                        defined($pipe_section_hashref->{section_name}) and
                                                        # not matching BaseCall pipeline sections
                                                        $pipe_section_hashref->{section_name} !~ /^(BASE(_|-|\s+)CALL|QUALITY(_|-|\s+)SCORE|Bcl-to-Fastq)/i and
                                                        !ref($pipe_section_hashref->{VERSION}) and
                                                        none { "$pipe_section_hashref->{PROGRAM} $pipe_section_hashref->{VERSION}" eq $_ } @software_versions
                                                    ) {
                                                        push @software_versions, "$pipe_section_hashref->{PROGRAM} $pipe_section_hashref->{VERSION}";
                                                    }
                                                }
                                            }
                                        }
                                        if (@software_versions) {
                                            $field_value = join(';', @software_versions);
                                        }
                                    }
                                    elsif ($col_key eq 'Derived Array Data File') {
                                        if (defined $run_xml->{alias}) {
                                            $field_value = $run_xml->{alias} =~ /\.bam$/i
                                                         ? $run_xml->{alias}
                                                         : "$run_xml->{alias}.bam";
                                        }
                                        elsif (defined $exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_NAME}) {
                                            $field_value = "$exp_pkg_xml->{EXPERIMENT}->{DESIGN}->{LIBRARY_DESCRIPTOR}->{LIBRARY_NAME}.bam";
                                        }
                                    }
                                    elsif ($col_key eq 'Comment[SUBMITTED_FILE_NAME]') {
                                        if (
                                            defined($run_xml->{alias}) and
                                            $run_xml->{alias} =~ /\.bam$/i and
                                            $run_xml->{alias} ne $sdrf_run_bam_data[$mage_tab_sdrf_base_col_idx_by_type_key{run_bam}{'Derived Array Data File'}]
                                        ) {
                                            $field_value = $run_xml->{alias};
                                        }
                                    }
                                    elsif ($col_key eq 'Comment[SRA_RUN]') {
                                        $field_value = $run_xml->{accession};
                                    }
                                    elsif ($col_key eq 'Comment[SRA_FILE_URI]') {
                                        my $study_acc  = $exp_pkg_xml->{STUDY}->{accession};
                                        my $sample_acc = $exp_pkg_xml->{SAMPLE}->{accession};
                                        my $exp_acc    = $exp_pkg_xml->{EXPERIMENT}->{accession};
                                        my $run_acc    = $run_xml->{accession};
                                        $field_value = "\@dbgap\@:reads/$study_acc/$sample_acc/$exp_acc/$run_acc/$run_acc.sra";
                                    }
                                    elsif ($col_key eq 'Comment[OCG Data Level]') {
                                            $field_value = '2';
                                    }
                                    elsif ($col_key eq 'Comment[ASSEMBLY_NAME]') {
                                            $field_value = $run_xml->{assembly};
                                    }
                                    elsif ($col_key eq 'Comment[QC Warning]') {
                                        if (
                                            defined($mt_config_hashref->{dataset}) and
                                            defined($mt_config_hashref->{dataset}->{exp_center_library_data_qc_warning}) and
                                            defined($mt_config_hashref->{dataset}->{exp_center_library_data_qc_warning}->{$exp_center_name}) and
                                            defined($mt_config_hashref->{dataset}->{exp_center_library_data_qc_warning}->{$exp_center_name}->{$exp_library_name})
                                        ) {
                                            $field_value = $mt_config_hashref->{dataset}->{exp_center_library_data_qc_warning}->{$exp_center_name}->{$exp_library_name};
                                        }
                                    }
                                    $sdrf_run_bam_data[$mage_tab_sdrf_base_col_idx_by_type_key{run_bam}{$col_key}] = defined($field_value) ? $field_value : '';
                                }
                                push @sdrf_run_set_data, {
                                    run => \@sdrf_run_data,
                                    data => \@sdrf_run_bam_data,
                                    is_bam_run => $is_bam_run,
                                    run_center_name => $run_center_name,
                                };
                            }
                            # scan marked DCC data using exp library name or run submitted file basename (barcode/sample ID already scanned)
                            # fix for NCI-Khan TARGET CCSK,NBL mRNA-seq
                            my $search_library_name = $exp_library_name;
                            if ($program_name eq 'TARGET' and $project_name eq 'CCSK' and $data_type eq 'mRNA-seq') {
                                ($search_library_name) = $search_library_name =~ /^(CCSK\d+)/i;
                            }
                            elsif ($program_name eq 'TARGET' and $project_name eq 'NBL' and $data_type eq 'mRNA-seq') {
                                ($search_library_name) = $search_library_name =~ /^(NB\d+)/i;
                            }
                            my $run_data_file_basename;
                            if (defined $run_xml->{alias}) {
                                $run_data_file_basename = fileparse($run_xml->{alias}, qr/\.[^.]*/);
                            }
                            my %add_dcc_scanned_file_info;
                            for my $dcc_marked_file_info_hashref (@dcc_marked_file_info) {
                                my $file = $dcc_marked_file_info_hashref->{file};
                                my $data_level = $dcc_marked_file_info_hashref->{data_level};
                                my $file_name = fileparse($file);
                                # WGS
                                if ($data_type eq 'WGS') {
                                    # BCCA older mafs
                                    if ($file =~ /mutation\/BCCA\/.*?_?($search_library_name|$run_data_file_basename)_?.*?\.maf(\.txt)?$/i) {
                                        if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}) {
                                            push @{$add_dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                    }
                                }
                                # WXS
                                elsif ($data_type eq 'WXS') {
                                    # BCCA older mafs
                                    if ($file =~ /mutation\/BCCA\/.*?_?($search_library_name|$run_data_file_basename)_?.*?\.maf(\.txt)?$/i) {
                                        if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}) {
                                            push @{$add_dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                    }
                                }
                                # mRNA-seq
                                elsif ($data_type eq 'mRNA-seq') {
                                    # older BCCA gene, exon, spljxn quantification files
                                    if ($file =~ /expression\/BCCA\/.*?_?($search_library_name|$run_data_file_basename)_?.*?\.((gene|exon|spljxn)\.quantification\.txt)$/i) {
                                        if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'Expression'}}) {
                                            push @{$add_dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'Expression'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'Expression'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                    }
                                    # older BCCA mafs
                                    elsif ($file =~ /mutation\/BCCA\/.*?_?($search_library_name|$run_data_file_basename)_?.*?\.maf(\.txt)?$/i) {
                                        if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}) {
                                            push @{$add_dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'BCCA'}{'BCCA'}{'VariantCall'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                    }
                                    # NCI-Khan gene, isoform, exon files
                                    elsif ($file =~ /expression\/NCI-Khan\/.*?_?($search_library_name|$run_data_file_basename)_?.*?\.(((gene|isoform)\.fpkm|exon\.(count|rpkm))\.txt)$/i) {
                                        if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Khan'}{'NCI-Khan'}{'Expression'}}) {
                                            push @{$add_dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Khan'}{'NCI-Khan'}{'Expression'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Khan'}{'NCI-Khan'}{'Expression'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                    }
                                    # NCI-Khan fusion files
                                    elsif ($file =~ /structural\/NCI-Khan\/.*?_?($search_library_name|$run_data_file_basename)_?.*?\.fusion(\.results\.filtered)?\.tsv$/i) {
                                        if (none { $file_name eq $_->{file_name} } @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Khan'}{'NCI-Khan'}{'Fusion'}}) {
                                            push @{$add_dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Khan'}{'NCI-Khan'}{'Fusion'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                            push @{$dcc_scanned_file_info{$data_type}{$barcode}{'_default'}{'_default'}{'NCI-Khan'}{'NCI-Khan'}{'Fusion'}}, {
                                                data_level => $data_level,
                                                file_name => $file_name,
                                            };
                                        }
                                    }
                                }
                            }
                            if (%add_dcc_scanned_file_info and ($debug{all} or $debug{file_info})) {
                                print STDERR "\n",
                                    +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                                    ": \%add_dcc_scanned_file_info:\n", Dumper(\%add_dcc_scanned_file_info);
                            }
                            for my $data_type (
                                natsort keys %add_dcc_scanned_file_info
                            ) {
                                for my $barcode (
                                    natsort keys %{$add_dcc_scanned_file_info{$data_type}}
                                ) {
                                    for my $exp_center_name (
                                        sort by_dag_center_name keys %{$add_dcc_scanned_file_info{$data_type}{$barcode}}
                                    ) {
                                        for my $library_name (
                                            natsort keys %{$add_dcc_scanned_file_info{$data_type}{$barcode}{$exp_center_name}}
                                        ) {
                                            for my $run_center_name (
                                                sort by_dag_center_name keys %{$add_dcc_scanned_file_info{$data_type}{$barcode}{$exp_center_name}{$library_name}}
                                            ) {
                                                for my $analysis_center_name (
                                                    sort by_dag_center_name keys %{$add_dcc_scanned_file_info{$data_type}{$barcode}{$exp_center_name}{$library_name}{$run_center_name}}
                                                ) {
                                                    # init
                                                    my $sdrf_dag_node_hashref = {};
                                                    $dcc_protocol_idf_order_info{$analysis_center_name} = []
                                                        unless defined $dcc_protocol_idf_order_info{$analysis_center_name};
                                                    my $protocol_dag_custom_run_center = (
                                                        exists($dcc_scanned_file_protocol_dag_conf{$data_type}{$run_center_name}) and
                                                        exists($dcc_scanned_file_protocol_dag_conf{$data_type}{$run_center_name}{$analysis_center_name})
                                                    ) ? $run_center_name
                                                      : '_default';
                                                    add_dcc_scanned_file_sdrf_dag_info({
                                                        protocol_dag_nodes => $dcc_scanned_file_protocol_dag_conf{$data_type}{$protocol_dag_custom_run_center}{$analysis_center_name},
                                                        file_info => $add_dcc_scanned_file_info{$data_type}{$barcode}{$exp_center_name}{$library_name}{$run_center_name}{$analysis_center_name},
                                                        sdrf_dag_node => $sdrf_dag_node_hashref,
                                                        protocol_idf_order_info => $dcc_protocol_idf_order_info{$analysis_center_name},
                                                    });
                                                    if (%{$sdrf_dag_node_hashref}) {
                                                        $dcc_sdrf_dag_info{$data_type}{$barcode}{$exp_center_name}{$library_name}{$run_center_name}{$analysis_center_name} = $sdrf_dag_node_hashref;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            #if ($debug{all} or $debug{file_info}) {
                            #    print STDERR 
                            #        +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                            #        ": \%dcc_sdrf_dag_info:\n", Dumper(\%dcc_sdrf_dag_info);
                            #}
                        }
                        # special case mRNA-seq run set with one or more FASTQ + one BAM run needs to be collapsed properly
                        if (
                            $data_type eq 'mRNA-seq' and
                            any {
                                !defined($_->{Databases}) or
                                !defined($_->{Databases}->{Table}) or
                                !defined($_->{Databases}->{Table}->{PRIMARY_ALIGNMENT})
                            } @{$exp_pkg_xml->{RUN_SET}} and
                            one {
                                defined($_->{Databases}) and
                                defined($_->{Databases}->{Table}) and
                                defined($_->{Databases}->{Table}->{PRIMARY_ALIGNMENT})
                            } @{$exp_pkg_xml->{RUN_SET}}
                        ) {
                            my $sdrf_run_bam_data_idx = firstidx { $_->{is_bam_run} } @sdrf_run_set_data;
                            my $sdrf_run_bam_data_hashref = $sdrf_run_set_data[$sdrf_run_bam_data_idx];
                            splice(@sdrf_run_set_data, $sdrf_run_bam_data_idx, 1);
                            for my $sdrf_run_data_hashref (@sdrf_run_set_data) {
                                # remove redudant BAM Comment[QC Warning] if needed
                                if (
                                    $sdrf_run_data_hashref->{data}->[$mage_tab_sdrf_base_col_idx_by_type_key{run_fastq}{'Comment[QC Warning]'}] ne '' and
                                    $sdrf_run_bam_data_hashref->{data}->[$mage_tab_sdrf_base_col_idx_by_type_key{run_bam}{'Comment[QC Warning]'}] ne ''
                                ) {
                                    $sdrf_run_bam_data_hashref->{data}->[$mage_tab_sdrf_base_col_idx_by_type_key{run_bam}{'Comment[QC Warning]'}] = '';
                                }
                                push @{$sdrf_run_data_hashref->{data}}, @{$sdrf_run_bam_data_hashref->{data}};
                            }
                        }
                        # standard run set
                        else {
                            for my $sdrf_run_data_hashref (@sdrf_run_set_data) {
                                if ($sdrf_run_data_hashref->{is_bam_run}) {
                                    unshift @{$sdrf_run_data_hashref->{data}}, ('') x @{$mage_tab_sdrf_base_col_names_by_type{run_fastq}};
                                }
                                else {
                                    push @{$sdrf_run_data_hashref->{data}}, ('') x @{$mage_tab_sdrf_base_col_names_by_type{run_bam}};
                                }
                            }
                        }
                        for my $sdrf_run_data_hashref (@sdrf_run_set_data) {
                            my @sdrf_row_data = (
                                @sdrf_exp_data,
                                @sdrf_lib_data,
                                @{$sdrf_run_data_hashref->{run}},
                                @{$sdrf_run_data_hashref->{data}},
                            );
                            #if ($debug{sdrf_step}) {
                            #    local $Data::Dumper::Indent = 0;
                            #    print STDERR "\n", Dumper(\@sdrf_row_data);
                            #    <STDIN>;
                            #}
                            # incorporate higher-level DCC file metadata into SDRF graph
                            # here we use exp_data_type (instead of data_type) 
                            my $added_dcc_metadata;
                            my $run_center_name = $sdrf_run_data_hashref->{run_center_name};
                            if (
                                exists($dcc_sdrf_dag_info{$exp_data_type}) and
                                exists($dcc_sdrf_dag_info{$exp_data_type}{$barcode})
                            ) {
                                for my $dcc_exp_center_name (
                                    sort by_dag_center_name keys %{$dcc_sdrf_dag_info{$exp_data_type}{$barcode}}
                                ) {
                                    next unless $dcc_exp_center_name eq '_default' or 
                                                $dcc_exp_center_name eq $exp_center_name;
                                    for my $dcc_exp_library_name (
                                        sort by_dag_center_name keys %{$dcc_sdrf_dag_info{$exp_data_type}{$barcode}{$dcc_exp_center_name}}
                                    ) {
                                        next unless $dcc_exp_library_name eq '_default' or 
                                                    $dcc_exp_library_name eq $exp_library_name or
                                                    $exp_library_name eq '';
                                        for my $dcc_run_center_name (
                                            sort by_dag_center_name keys %{$dcc_sdrf_dag_info{$exp_data_type}{$barcode}{$dcc_exp_center_name}{$dcc_exp_library_name}}
                                        ) {
                                            next unless $dcc_run_center_name eq '_default' or 
                                                        $dcc_run_center_name eq $run_center_name;
                                            for my $dcc_analysis_center_name (
                                                sort by_dag_center_name keys %{$dcc_sdrf_dag_info{$exp_data_type}{$barcode}{$dcc_exp_center_name}{$dcc_exp_library_name}{$dcc_run_center_name}}
                                            ) {
                                                add_dcc_sdrf_data({
                                                    mage_tab_sdrf_data => \@mage_tab_sdrf_data,
                                                    mage_tab_sdrf_dcc_col_headers => \@mage_tab_sdrf_dcc_col_headers,
                                                    sdrf_row_data => \@sdrf_row_data,
                                                    sdrf_dag_node => $dcc_sdrf_dag_info{$exp_data_type}{$barcode}{$dcc_exp_center_name}{$dcc_exp_library_name}{$dcc_run_center_name}{$dcc_analysis_center_name},
                                                    protocol_data => \@protocol_data,
                                                    protocol_info => {
                                                        program_name => $program_name,
                                                        project_name => $project_name,
                                                        data_type => $exp_data_type,
                                                        dataset => $dataset,
                                                        platform => $platform,
                                                        run_center_name => $run_center_name,
                                                        analysis_center_name => $dcc_analysis_center_name,
                                                        config => $exp_data_type eq $data_type
                                                            ? $mt_config_hashref->{dataset}->{protocol_info}
                                                            : $mt_config_hashref->{dataset}->{'add_data_types'}->{protocol_info},
                                                    },
                                                    mt_config => $mt_config_hashref,
                                                });
                                                $added_dcc_metadata++;
                                                $dcc_sdrf_dag_info{$exp_data_type}{$barcode}{$dcc_exp_center_name}{$dcc_exp_library_name}{$dcc_run_center_name}{$dcc_analysis_center_name}{'_linked_to_sra'}++;
                                            }
                                        }
                                    }
                                }
                            }
                            if (!$added_dcc_metadata) {
                                push @mage_tab_sdrf_data, \@sdrf_row_data;
                            }
                        }
                    }
                    $num_exps_processed++;
                    print "\r$num_exps_processed processed" if -t STDOUT;
                }
                print "$num_exps_processed processed" unless -t STDOUT and $num_exps_processed;
                print " / $num_exps_skipped skipped" if $num_exps_skipped;
                print "\n";
                # report DCC data not linked to SRA
                my @dcc_data_no_link_sra;
                for my $data_type (
                    natsort keys %dcc_sdrf_dag_info
                ) {
                    for my $barcode (
                        natsort keys %{$dcc_sdrf_dag_info{$data_type}}
                    ) {
                        for my $exp_center_name (
                            natsort keys %{$dcc_sdrf_dag_info{$data_type}{$barcode}}
                        ) {
                            for my $library_name (
                                natsort keys %{$dcc_sdrf_dag_info{$data_type}{$barcode}{$exp_center_name}}
                            ) {
                                for my $run_center_name (
                                    natsort keys %{$dcc_sdrf_dag_info{$data_type}{$barcode}{$exp_center_name}{$library_name}}
                                ) {
                                    for my $analysis_center_name (
                                        natsort keys %{$dcc_sdrf_dag_info{$data_type}{$barcode}{$exp_center_name}{$library_name}{$run_center_name}}
                                    ) {
                                        if (
                                            !exists($dcc_sdrf_dag_info{$data_type}{$barcode}{$exp_center_name}{$library_name}{$run_center_name}{$analysis_center_name}{'_linked_to_sra'})
                                        ) {
                                            my @file_names;
                                            get_file_names_from_sdrf_dag_node({
                                                sdrf_dag_node => $dcc_sdrf_dag_info{$data_type}{$barcode}{$exp_center_name}{$library_name}{$run_center_name}{$analysis_center_name},
                                                file_names => \@file_names,
                                            });
                                            push @dcc_data_no_link_sra, [
                                                $data_type,
                                                $barcode,
                                                $exp_center_name,
                                                $library_name,
                                                $run_center_name,
                                                $analysis_center_name,
                                                join("\n", @file_names),
                                            ];
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if (@dcc_data_no_link_sra) {
                    my $tb = Text::ANSITable->new(
                        border_style => 'Default::single_ascii',
                        show_row_separator => 1,
                        column_wrap => 0,
                        columns => [
                            'Data Type', 'Barcode', 'Exp Center Name', 'Library Name', 'Run Center Name', 'Analysis Center Name', 'File Names',
                        ],
                        use_utf8 => 0,
                        use_box_chars => 0,
                        use_color => 0,
                    );
                    $tb->add_rows(\@dcc_data_no_link_sra);
                    warn +(-t STDERR ? colored('WARN', 'red') : 'WARN'), ": DCC data not linked to SRA:\n", $tb->draw();
                }
                # generate IDF Protocol metadata rows (that are compiled and known only after going through all run metadata)
                for my $protocol_hashref (natkeysort { $_->{name} } @protocol_data) {
                    my $protocol_desc_file = "$protocol_data_store/$protocol_hashref->{name}.txt";
                    if (-f $protocol_desc_file) {
                        if (!defined $protocol_hashref->{description}) {
                            local $/;
                            open(my $p_fh, '<:encoding(utf8)', $protocol_desc_file) 
                                or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $protocol_desc_file: $!";
                            $protocol_hashref->{description} = <$p_fh>;
                            close($p_fh);
                        }
                        else {
                            warn +(-t STDERR ? colored('WARN', 'red') : 'WARN'),
                                 ": SRA-XML protocol overriding DCC $protocol_hashref->{name}\n";
                        }
                    }
                    elsif (!defined $protocol_hashref->{description}) {
                        warn +(-t STDERR ? colored('WARN', 'red') : 'WARN'), 
                             ": missing protocol $protocol_hashref->{name}\n";
                    }
                    if (defined $protocol_hashref->{description}) {
                        $protocol_hashref->{description} = quote_for_mage_tab($protocol_hashref->{description});
                    }
                }
                # sort protocol data for IDF
                @protocol_data = sort {
                    (
                        defined($protocol_base_types{$a->{type}}) and
                        defined($protocol_base_types{$b->{type}})
                    ) ? (
                        $protocol_base_types{$a->{type}}{idf_order_num} <=> $protocol_base_types{$b->{type}}{idf_order_num}
                            ||
                        (
                            (
                                $a->{data_type} eq $data_type and
                                $b->{data_type} ne $data_type
                            ) ? -1
                              : (
                                $a->{data_type} ne $data_type and
                                $b->{data_type} eq $data_type
                            ) ? 1
                              : mkkey_natural(lc($a->{name})) cmp mkkey_natural(lc($b->{name}))
                        )
                    ) : (
                         defined($protocol_base_types{$a->{type}}) and
                        !defined($protocol_base_types{$b->{type}})
                    ) ? -1
                      : (
                        !defined($protocol_base_types{$a->{type}}) and
                         defined($protocol_base_types{$b->{type}})
                    ) ? 1
                      : mkkey_natural(lc($a->{center_name})) cmp mkkey_natural(lc($b->{center_name}))
                            ||
                        ( 
                            firstidx { $a->{type} eq $_ } @{$dcc_protocol_idf_order_info{$a->{center_name}}}
                                cmp
                            firstidx { $b->{type} eq $_ } @{$dcc_protocol_idf_order_info{$b->{center_name}}}
                        )
                } @protocol_data;
                my @protocol_names = map { $_->{name} } @protocol_data;
                $mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{'Protocol Name'}] = \@protocol_names;
                my @protocol_types = map { $_->{idf_type} } @protocol_data;
                $mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{'Protocol Type'}] = \@protocol_types;
                my @protocol_term_source_refs = map { $_->{term_source_ref} } @protocol_data;
                $mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{'Protocol Term Source REF'}] = \@protocol_term_source_refs;
                my @protocol_descriptions = map { $_->{description} || '' } @protocol_data;
                $mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{'Protocol Description'}] = \@protocol_descriptions;
                my @protocol_hardwares = map { $_->{hardware} || '' } @protocol_data;
                $mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{'Protocol Hardware'}] = \@protocol_hardwares;
                my @protocol_softwares = map { defined($_->{software}) ? join(';', @{$_->{software}}) : '' } @protocol_data;
                $mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{'Protocol Software'}] = \@protocol_softwares;
                my @protocol_parameters = map { defined($_->{parameters}) ? join(';', @{$_->{parameters}}) : '' } @protocol_data;
                $mage_tab_idf_data[$mage_tab_idf_row_idx_by_name{'Protocol Parameters'}] = \@protocol_parameters;
                # prepare MAGE-TAB
                if (@mage_tab_idf_data and @mage_tab_sdrf_data) {
                    if ($debug{all} or $debug{idf}) {
                        print STDERR 
                            +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                            ": \%dcc_protocol_idf_order_info:\n", Dumper(\%dcc_protocol_idf_order_info),
                            +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                            ": \@protocol_data:\n", Dumper(\@protocol_data),
                            +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                            ": \@mage_tab_idf_data:\n", Dumper(\@mage_tab_idf_data);
                    }
                    my @mage_tab_sdrf_col_headers = (
                        @mage_tab_sdrf_base_col_headers,
                        @mage_tab_sdrf_dcc_col_headers,
                    );
                    # pad empty fields at end of SDRF rows as necessary to box out
                    for my $row_idx (0 .. $#mage_tab_sdrf_data) {
                        my $num_cols_diff = scalar(@mage_tab_sdrf_col_headers) - scalar(@{$mage_tab_sdrf_data[$row_idx]});
                        if ($num_cols_diff > 0) {
                            push @{$mage_tab_sdrf_data[$row_idx]}, ('') x $num_cols_diff;
                        }
                        elsif ($num_cols_diff < 0) {
                            local $Data::Dumper::Indent = 0;
                            die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                ": SDRF row has more fields than there are column headers:\n",
                                "\@mage_tab_sdrf_col_headers:\n", Dumper(\@mage_tab_sdrf_col_headers), "\n",
                                "\@{\$mage_tab_sdrf_data[$row_idx]}:\n", Dumper($mage_tab_sdrf_data[$row_idx]), "\n";
                        }
                    }
                    if ($debug{all} or $debug{sdrf}) {
                        local $Data::Dumper::Indent = 0;
                        print STDERR 
                            +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                            ": \@mage_tab_sdrf_col_headers:\n", Dumper(\@mage_tab_sdrf_col_headers), "\n",
                            +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                            ": \@mage_tab_sdrf_data:\n";
                        for my $arrayref (@mage_tab_sdrf_data) {
                            print STDERR Dumper($arrayref), "\n";
                        }
                    }
                    # get SDRF non-empty column indexes
                    my @mage_tab_sdrf_col_idxs_with_data;
                    for my $col_idx (0 .. $#mage_tab_sdrf_col_headers) {
                        for my $sdrf_row_data_arrayref (@mage_tab_sdrf_data) {
                            if ($sdrf_row_data_arrayref->[$col_idx] !~ /^\s*$/) {
                                push @mage_tab_sdrf_col_idxs_with_data, $col_idx;
                                last;
                            }
                        }
                    }
                    my %mage_tab_sdrf_col_idx_by_key;
                    for my $col_idx (0 .. $#mage_tab_sdrf_col_headers) {
                        if (
                            exists($mage_tab_sdrf_col_idx_by_key{$mage_tab_sdrf_col_headers[$col_idx]}) or 
                            exists($mage_tab_sdrf_col_idx_by_key{"$mage_tab_sdrf_col_headers[$col_idx] 1"})
                        ) {
                            if (exists($mage_tab_sdrf_col_idx_by_key{$mage_tab_sdrf_col_headers[$col_idx]})) {
                                $mage_tab_sdrf_col_idx_by_key{"$mage_tab_sdrf_col_headers[$col_idx] 1"} = 
                                    $mage_tab_sdrf_col_idx_by_key{$mage_tab_sdrf_col_headers[$col_idx]};
                                delete($mage_tab_sdrf_col_idx_by_key{$mage_tab_sdrf_col_headers[$col_idx]});
                            }
                            for (my $col_header_num = 2; ; $col_header_num++) {
                                if (!exists($mage_tab_sdrf_col_idx_by_key{"$mage_tab_sdrf_col_headers[$col_idx] $col_header_num"})) {
                                    $mage_tab_sdrf_col_idx_by_key{"$mage_tab_sdrf_col_headers[$col_idx] $col_header_num"} = $col_idx;
                                    last;
                                }
                            }
                        }
                        else {
                            $mage_tab_sdrf_col_idx_by_key{$mage_tab_sdrf_col_headers[$col_idx]} = $col_idx;
                        }
                    }
                    # write MAGE-TAB IDF
                    print "Writing $mage_tab_file_basename.idf.txt\n";
                    open(my $idf_out_fh, '>:encoding(utf8)', "$mage_tab_file_basename.idf.txt")
                        or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not create IDF: $!";
                    for my $row_idx (0 .. $#mage_tab_idf_row_names) {
                        my $row_name = $mage_tab_idf_row_names[$row_idx];
                        # merge possible configured IDF row values
                        if (
                            defined($mt_config_hashref->{dataset}) and
                            defined($mt_config_hashref->{dataset}->{'merge_idf_row_names'}) and
                            any { $row_name eq $_ } @{$mt_config_hashref->{dataset}->{'merge_idf_row_names'}}
                        ) {
                            my $delimiter = ( $row_name eq 'Experiment Description' ? '. ' : '; ' );
                            $mage_tab_idf_data[$row_idx] = [ join($delimiter, @{$mage_tab_idf_data[$row_idx]}) ];
                        }
                        if ($row_name eq 'Experiment Description') {
                            for my $row_value (@{$mage_tab_idf_data[$row_idx]}) {
                                $row_value = quote_for_mage_tab($row_value);
                            }
                        }
                        print $idf_out_fh join("\t", $row_name, @{$mage_tab_idf_data[$row_idx]}), "\n";
                    }
                    close($idf_out_fh);
                    # write MAGE-TAB SDRF
                    print "Writing $mage_tab_file_basename.sdrf.txt\n";
                    open(my $sdrf_out_fh, '>:encoding(utf8)', "$mage_tab_file_basename.sdrf.txt") 
                        or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not create SDRF: $!";
                    print $sdrf_out_fh join("\t", map { $mage_tab_sdrf_col_headers[$_] } @mage_tab_sdrf_col_idxs_with_data), "\n";
                    for my $sdrf_row_data_arrayref (
                        sort {
                            mkkey_natural($a->[$mage_tab_sdrf_col_idx_by_key{'Extract Name 1'}]) cmp 
                            mkkey_natural($b->[$mage_tab_sdrf_col_idx_by_key{'Extract Name 1'}])
                                ||
                            (
                                (
                                    $sra2dcc_data_type{$a->[$mage_tab_sdrf_col_idx_by_key{'Comment[LIBRARY_STRATEGY]'}]} eq $data_type and
                                    $sra2dcc_data_type{$b->[$mage_tab_sdrf_col_idx_by_key{'Comment[LIBRARY_STRATEGY]'}]} ne $data_type
                                ) ? -1 
                                  : (
                                    $sra2dcc_data_type{$a->[$mage_tab_sdrf_col_idx_by_key{'Comment[LIBRARY_STRATEGY]'}]} ne $data_type and
                                    $sra2dcc_data_type{$b->[$mage_tab_sdrf_col_idx_by_key{'Comment[LIBRARY_STRATEGY]'}]} eq $data_type
                                ) ? 1
                                  : 0
                            )
                        } @mage_tab_sdrf_data
                    ) {
                        for my $col_idx (0 .. $#mage_tab_sdrf_col_idxs_with_data) {
                            print $sdrf_out_fh
                                $sdrf_row_data_arrayref->[$mage_tab_sdrf_col_idxs_with_data[$col_idx]],
                                $col_idx != $#mage_tab_sdrf_col_idxs_with_data ? "\t" : "\n";
                        }
                    }
                    close($sdrf_out_fh);
                    # distribute files
                    if ($dist) {
                        my $metadata_dir = "$dataset_dir/METADATA";
                        if (!-d $metadata_dir) {
                            print "Creating $metadata_dir\n" if $verbose;
                            make_path($metadata_dir, { chmod => 0770 }) 
                                or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not create directory: $!";
                        }
                        my @old_files = <"$metadata_dir/*.{idf,sdrf}.txt">;
                        for my $old_file (@old_files) {
                            if ($clean) {
                                print "Removing $old_file\n" if $verbose;
                                unlink($old_file) 
                                    or warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not unlink $old_file: $!";
                            }
                            else {
                                (my $archive_metadata_dir = $metadata_dir) =~ s/\/current\//\/old\//;
                                if (!-d $archive_metadata_dir) {
                                    print "Creating $archive_metadata_dir\n" if $verbose;
                                    make_path($archive_metadata_dir, { chmod => 0770 }) 
                                        or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not create directory: $!";
                                }
                                (my $archive_file = $old_file) =~ s/\/current\//\/old\//;
                                print "Archiving $old_file -->\n",
                                      "          $archive_file\n" if $verbose;
                                move($old_file, $archive_file) 
                                    or warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not move $old_file: $!";
                            }
                        }
                        for my $ext (qw( idf sdrf )) {
                            print "Copying $metadata_dir/$mage_tab_file_basename.$ext.txt\n" if $verbose;
                            copy("$mage_tab_file_basename.$ext.txt", $metadata_dir)
                                or warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                        ": could not copy $mage_tab_file_basename.$ext.txt to $metadata_dir: $!";
                        }
                    }
                }
            }
        }
    }
}
exit;

sub merge_run_info_hash {
    my ($merged_run_info_hashref, $study_run_info_hashref) = @_;
    for my $data_type (keys %{$study_run_info_hashref}) {
        for my $run_center_name (keys %{$study_run_info_hashref->{$data_type}}) {
            for my $type (keys %{$study_run_info_hashref->{$data_type}->{$run_center_name}}) {
                for my $key (keys %{$study_run_info_hashref->{$data_type}->{$run_center_name}->{$type}}) {
                    if (exists $merged_run_info_hashref->{$data_type}->{$run_center_name}->{$type}->{$key}) {
                        if ($type ne 'library_name_barcode') {
                            $merged_run_info_hashref->{$data_type}->{$run_center_name}->{$type}->{$key} +=
                                $study_run_info_hashref->{$data_type}->{$run_center_name}->{$type}->{$key};
                        }
                        elsif (
                            $merged_run_info_hashref->{$data_type}->{$run_center_name}->{$type}->{$key} ne
                            $study_run_info_hashref->{$data_type}->{$run_center_name}->{$type}->{$key}
                        ) {
                            die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                ": different barcodes for same library $key: " ,
                                $merged_run_info_hashref->{$data_type}->{$run_center_name}->{$type}->{$key},
                                ", $study_run_info_hashref->{$data_type}->{$run_center_name}->{$type}->{$key}";
                        }
                    }
                    else {
                        $merged_run_info_hashref->{$data_type}->{$run_center_name}->{$type}->{$key} =
                            $study_run_info_hashref->{$data_type}->{$run_center_name}->{$type}->{$key};
                    }
                }
            }
        }
    }
    return $merged_run_info_hashref;
}

sub get_barcode_info {
    my ($barcode) = @_;
    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid barcode '$barcode'" 
        unless $barcode =~ /^$OCG_BARCODE_REGEXP$/;
    my ($case_id, $s_case_id, $sample_id, $disease_code, $tissue_code, $nucleic_acid_code);
    my @barcode_parts = split('-', $barcode);
    # TARGET sample ID/barcode
    if (scalar(@barcode_parts) == 5) {
        $case_id = join('-', @barcode_parts[0..2]);
        $s_case_id = $barcode_parts[2];
        $sample_id = join('-', @barcode_parts[0..3]);
        ($disease_code, $tissue_code, $nucleic_acid_code) = @barcode_parts[1,3,4];
    }
    # CGCI sample ID/barcode
    elsif (scalar(@barcode_parts) == 6) {
        $case_id = join('-', @barcode_parts[0..3]);
        $s_case_id = $barcode_parts[3];
        $sample_id = join('-', @barcode_parts[0..4]);
        ($disease_code, $tissue_code, $nucleic_acid_code) = @barcode_parts[1,4,5];
    }
    else {
        die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
            ": invalid sample ID/barcode $barcode\n";
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
    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
        ": unknown tissue code $tissue_code\n" unless defined $tissue_type;
    my $cgi_tissue_type = $tissue_type;
    # special fix for TARGET-10-PANKMB
    if ($case_id eq 'TARGET-10-PANKMB' and $tissue_type eq 'Primary') {
        $cgi_tissue_type .= "${tissue_code}${tissue_ltr}";
    }
    # special fix for TARGET-10-PAKKCA
    elsif ($case_id eq 'TARGET-10-PAKKCA' and $tissue_type eq 'Primary') {
        $cgi_tissue_type .= "${tissue_code}${tissue_ltr}";
    }
    # special fix for TARGET-30-PARKGJ
    elsif ($case_id eq 'TARGET-30-PARKGJ' and ($tissue_type eq 'Primary' or $tissue_type eq 'Normal')) {
        $cgi_tissue_type .= $barcode_parts[$#barcode_parts];
    }
    # special fix for TARGET-50-PAKJGM
    elsif ($case_id eq 'TARGET-50-PAKJGM' and $tissue_type eq 'Normal') {
        $cgi_tissue_type .= $barcode_parts[$#barcode_parts];
    }
    $cgi_tissue_type .= ( defined($xeno_cell_line_code) ? $xeno_cell_line_code : '' );
    my $nucleic_acid_ltr = substr($nucleic_acid_code, -1);
    #$nucleic_acid_code =~ s/\D//g;
    $nucleic_acid_code = substr($nucleic_acid_code, 0, 2);
    return {
        case_id => $case_id,
        s_case_id => $s_case_id,
        sample_id => $sample_id,
        disease_code => $disease_code,
        tissue_code => $tissue_code,
        tissue_ltr => $tissue_ltr,
        tissue_type => $tissue_type,
        cgi_tissue_type => $cgi_tissue_type,
        xeno_cell_line_code => $xeno_cell_line_code,
        nucleic_acid_code => $nucleic_acid_code,
        nucleic_acid_ltr => $nucleic_acid_ltr,
    };
}

sub get_barcodes_from_data_file {
    my ($file_path, $program_name, $project_name, $data_type) = @_;
    my @uniq_barcodes;
    print "Parsing $file_path\n" if $verbose;
    # not using Spreadsheet::Read to parse txt/csv files because it 
    # loads entire file into data structure and some files are large
    # plus some files have metadata/comments at top and Spreadsheet::Read
    # makes it more difficult to handle these
    # txt maf
    if ($file_path =~ /\.txt$/i) {
        my $csv = Text::CSV->new({
            binary => 1,
            sep_char => "\t",
        }) or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                  ": cannot create Text::CSV object: ", Text::CSV->error_diag();
        open(my $csv_fh, '<:encoding(utf8)', $file_path) 
            or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $file_path: $!";
        my (%data_file_col_header_idx_by_name, %uniq_barcodes);
        my $read_col_header_line = 0;
        while (my $csv_line_arrayref = $csv->getline($csv_fh)) {
            if (!$read_col_header_line) {
                if ($csv_line_arrayref->[0] !~ /^#/) {
                    $read_col_header_line++;
                    my @data_file_col_headers = @{$csv_line_arrayref};
                    if ($debug{all} or $debug{file_parse}) {
                        print STDERR 
                            +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                            ": \@data_file_col_headers:\n", Dumper(\@data_file_col_headers);
                    }
                    # create %data_file_col_header_idx_by_name data structure
                    %data_file_col_header_idx_by_name = map { $data_file_col_headers[$_] => $_ } 0 .. $#data_file_col_headers;
                    if ($debug{all} or $debug{file_parse}) {
                        print STDERR 
                            +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                            ": \%data_file_col_header_idx_by_name:\n", Dumper(\%data_file_col_header_idx_by_name);
                    }
                    if (!@data_file_col_header_idx_by_name{@maf_barcode_col_names}) {
                        warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                             ": couldn't load $file_path: couldn't find any barcode columns\n";
                        last;
                    }
                }
            }
            else {
                for my $col_idx (@data_file_col_header_idx_by_name{@maf_barcode_col_names}) {
                    $uniq_barcodes{$csv_line_arrayref->[$col_idx]}++;
                }
            }
        }
        close($csv_fh);
        for my $barcode (natsort keys %uniq_barcodes) {
            # skip empty barcodes
            next if $barcode =~ /^\s*$/ or $barcode eq '.';
            if ($barcode =~ /^$OCG_BARCODE_REGEXP$/) {
                push @uniq_barcodes, $barcode;
            }
            # special fix for bad TARGET WT WXS mafs
            elsif ($program_name eq 'TARGET' and $project_name eq 'WT' and $data_type eq 'WXS') {
                my $new_barcode = "${barcode}-01D";
                if ($new_barcode =~ /^$OCG_BARCODE_REGEXP$/) {
                    push @uniq_barcodes, $new_barcode;
                }
                else {
                    warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid barcode: $barcode\n";
                }
            }
            else {
                warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid barcode: $barcode\n";
            }
        }
    }
    # vcf
    elsif ($file_path =~ /\.vcf$/i) {
        my @data_file_col_headers;
        open(my $vcf_fh, '<', $file_path) 
            or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $file_path: $!";
        while (<$vcf_fh>) {
            if (m/^#(?!#)/) {
                s/^#//;
                s/\s+$//;
                if (m/^CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t/) {
                    @data_file_col_headers = split /\t/;
                    last;
                }
                else {
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid VCF column header:\n$_\n";
                }
            }
        }
        close($vcf_fh);
        splice(@data_file_col_headers, 0, 9);
        for my $col_header (@data_file_col_headers) {
            if ($col_header !~ /^$OCG_BARCODE_REGEXP$/) {
                warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid barcode: $col_header\n";
            }
        }
        @uniq_barcodes = natsort uniq(@data_file_col_headers);
    }
    # xls/xlsx maf
    elsif ($file_path =~ /\.xlsx?$/i) {
        my $data_file_workbook = ReadData(
            $file_path, 
            cells => 0, attr => 0, strip => 3,
        ) or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open data file $file_path: $!";
        if ($data_file_workbook->[0]->{sheets} != 1) {
            die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": xls/xlsx data file doesn't have one worksheet";
        }
        my $data_file_sheet = $data_file_workbook->[$data_file_workbook->[0]->{sheets}];
        #if ($debug{all} or $debug{file_parse}) {
        #    print STDERR 
        #        +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
        #        ": \$data_file_workbook:\n", Dumper($data_file_workbook);
        #}
        my @data_file_col_headers = cellrow($data_file_sheet, 1);
        if ($debug{all} or $debug{file_parse}) {
            print STDERR 
                +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                ": \@data_file_col_headers:\n", Dumper(\@data_file_col_headers);
        }
        # create %data_file_col_header_num_by_name data structure
        # Spreadsheet::Read has row/col cell numbers starting with 1
        my %data_file_col_header_num_by_name = map { $data_file_col_headers[$_] => $_ + 1 } 0 .. $#data_file_col_headers;
        if ($debug{all} or $debug{file_parse}) {
            print STDERR 
                +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                ": \%data_file_col_header_num_by_name:\n", Dumper(\%data_file_col_header_num_by_name);
        }
        if (@data_file_col_header_num_by_name{@maf_barcode_col_names}) {
            my %uniq_barcodes;
            for my $col_num (@data_file_col_header_num_by_name{@maf_barcode_col_names}) {
                for my $row_num (2 .. $#{$data_file_sheet->{cell}->[$col_num]}) {
                    $uniq_barcodes{$data_file_sheet->{cell}->[$col_num]->[$row_num]}++;
                }
            }
            for my $barcode (natsort keys %uniq_barcodes) {
                # skip empty barcodes
                next if $barcode =~ /^\s*$/ or $barcode eq '.';
                if ($barcode =~ /^$OCG_BARCODE_REGEXP$/) {
                    push @uniq_barcodes, $barcode;
                }
                else {
                    warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid barcode: $barcode\n";
                }
            }
        }
        else {
            warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                 ": couldn't load $file_path: couldn't find any barcode columns\n";
        }
    }
    else {
        die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid file type";
    }
    if (@uniq_barcodes) {
        if ($debug{all} or $debug{file_parse}) {
            print STDERR 
                +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), 
                ": \@uniq_barcodes:\n", Dumper(\@uniq_barcodes);
        }
        return @uniq_barcodes;
    }
    else {
        return;
    }
}

sub add_dcc_parsed_file_sdrf_dag_info {
    my ($params_hashref) = @_;
    for my $protocol_type (
        natsort keys %{$params_hashref->{conf_sdrf_dag_node}->{child_data_by_protocol_type}}
    ) {
        push @{$params_hashref->{protocol_idf_order_info}}, $protocol_type
            unless any { $protocol_type eq $_ } @{$params_hashref->{protocol_idf_order_info}};
        for my $conf_sdrf_dag_node_hashref (
            natkeysort { $_->{file_name} } @{$params_hashref->{conf_sdrf_dag_node}->{child_data_by_protocol_type}->{$protocol_type}}
        ) {
            if (any { $conf_sdrf_dag_node_hashref->{file_name} eq $_ } @{$params_hashref->{file_names}}) {
                # make copy
                my $sdrf_dag_node_hashref = {
                    data_level => $conf_sdrf_dag_node_hashref->{data_level},
                    file_name => $conf_sdrf_dag_node_hashref->{file_name},
                };
                push @{$params_hashref->{sdrf_dag_node}->{child_data_by_protocol_type}->{$protocol_type}}, 
                     $sdrf_dag_node_hashref;
                if (exists $conf_sdrf_dag_node_hashref->{child_data_by_protocol_type}) {
                    add_dcc_parsed_file_sdrf_dag_info({
                        conf_sdrf_dag_node => $conf_sdrf_dag_node_hashref,
                        sdrf_dag_node => $sdrf_dag_node_hashref,
                        file_names => $params_hashref->{file_names},
                        protocol_idf_order_info => $params_hashref->{protocol_idf_order_info},
                    });
                }
            }
        }
    }
}

sub add_dcc_scanned_file_sdrf_dag_info {
    my ($params_hashref) = @_;
    for my $protocol_dag_node_hashref (@{$params_hashref->{protocol_dag_nodes}}) {
        if (exists($params_hashref->{file_info}->{$protocol_dag_node_hashref->{type}})) {
            push @{$params_hashref->{protocol_idf_order_info}}, $protocol_dag_node_hashref->{type}
                unless any { $protocol_dag_node_hashref->{type} eq $_ } @{$params_hashref->{protocol_idf_order_info}};
            for my $file_info_hashref (@{$params_hashref->{file_info}->{$protocol_dag_node_hashref->{type}}}) {
                # file constraint
                if (exists $protocol_dag_node_hashref->{constraint_regexp}) {
                    my ($capture_str) = $file_info_hashref->{file_name} =~ /$protocol_dag_node_hashref->{constraint_regexp}/;
                    if ($params_hashref->{sdrf_dag_node}->{file_name} =~ /$capture_str/i) {
                        # make copy
                        my $sdrf_dag_node_hashref = clone($file_info_hashref);
                        push @{$params_hashref->{sdrf_dag_node}->{child_data_by_protocol_type}->{$protocol_dag_node_hashref->{type}}}, 
                             $sdrf_dag_node_hashref;
                        if (exists($protocol_dag_node_hashref->{children})) {
                            add_dcc_scanned_file_sdrf_dag_info({
                                protocol_dag_nodes => $protocol_dag_node_hashref->{children},
                                file_info => $params_hashref->{file_info},
                                sdrf_dag_node => $sdrf_dag_node_hashref,
                                protocol_idf_order_info => $params_hashref->{protocol_idf_order_info},
                            });
                        }
                    }
                }
                else {
                    # make copy
                    my $sdrf_dag_node_hashref = clone($file_info_hashref);
                    push @{$params_hashref->{sdrf_dag_node}->{child_data_by_protocol_type}->{$protocol_dag_node_hashref->{type}}}, 
                         $sdrf_dag_node_hashref;
                    if (exists($protocol_dag_node_hashref->{children})) {
                        add_dcc_scanned_file_sdrf_dag_info({
                            protocol_dag_nodes => $protocol_dag_node_hashref->{children},
                            file_info => $params_hashref->{file_info},
                            sdrf_dag_node => $sdrf_dag_node_hashref,
                            protocol_idf_order_info => $params_hashref->{protocol_idf_order_info},
                        });
                    }
                }
            }
        }
    }
}

sub get_lsid {
    my %params = @_;
    $params{namespace} = "$params{namespace_prefix}.$params{namespace}" if defined $params{namespace_prefix};
    return join(':', @params{qw( authority namespace object revision )});
}

sub quote_for_mage_tab {
    my ($str) = @_;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $str =~ s/\s+/ /g;
    $str =~ s/"/\"/g;
    return "\"$str\"";
}

sub add_dcc_sdrf_data {
    my ($params_hashref) = @_;
    # init
    $params_hashref->{sdrf_row_dcc_data} = []
        unless defined $params_hashref->{sdrf_row_dcc_data};
    $params_hashref->{sdrf_row_dcc_col_headers} = []
        unless defined $params_hashref->{sdrf_row_dcc_col_headers};
    my (
        $program_name,
        $project_name,
        $data_type,
        $dataset,
        $analysis_center_name,
        $protocol_config_hashref,
    ) = @{$params_hashref->{protocol_info}}{qw(
        program_name
        project_name
        data_type
        dataset
        analysis_center_name
        config
    )};
    (my $protocol_data_type = $data_type) =~ s/-//g;
    for my $protocol_type (
        natsort keys %{$params_hashref->{sdrf_dag_node}->{child_data_by_protocol_type}}
    ) {
        for my $sdrf_dag_node_hashref (
            natkeysort { $_->{file_name} } @{$params_hashref->{sdrf_dag_node}->{child_data_by_protocol_type}->{$protocol_type}}
        ) {
            my $protocol_hashref;
            if (
                defined($protocol_config_hashref) and
                defined($protocol_config_hashref->{$protocol_type}) and
                defined($protocol_config_hashref->{$protocol_type}->{$analysis_center_name})
            ) {
                $protocol_hashref = clone(
                    $protocol_config_hashref->{$protocol_type}->{$analysis_center_name}->{default}->{data}
                );
                # set default values if not specified in override
                $protocol_hashref->{idf_type} = 'data transformation protocol'
                    unless defined $protocol_hashref->{idf_type};
                $protocol_hashref->{term_source_ref} = $mt_config_hashref->{default}->{'term_source_ref'}
                    unless defined $protocol_hashref->{term_source_ref};
            }
            else {
                $protocol_hashref = {
                    name => $protocol_type,
                    idf_type => (
                        $data_type eq 'mRNA-seq' and
                        $protocol_type =~ /^Expression/i
                    ) ? 'normalization data transformation protocol'
                      : 'data transformation protocol',
                    term_source_ref => $mt_config_hashref->{default}->{'term_source_ref'},
                };
                $protocol_hashref->{name} = get_lsid(
                    authority => $center_info{$analysis_center_name}{authority},
                    namespace_prefix => $center_info{$analysis_center_name}{namespace_prefix},
                    namespace => 'Protocol',
                    object => "${protocol_data_type}-${protocol_type}",
                    revision => '01',
                );
            }
            if (none { $protocol_hashref->{name} eq $_->{name} } @{$params_hashref->{protocol_data}}) {
                @{$protocol_hashref}{qw( type data_type center_name )} = ( $protocol_type, $data_type, $analysis_center_name );
                push @{$params_hashref->{protocol_data}}, $protocol_hashref;
            }
            my @sdrf_dcc_col_w_data_conf = grep {
                exists $sdrf_dag_node_hashref->{$_->{key}}
            } @{$params_hashref->{mt_config}->{sdrf}->{dcc_col_info}};
            my @new_sdrf_row_dcc_data = (
                @{$params_hashref->{sdrf_row_dcc_data}},
                $protocol_hashref->{name},
                @{$sdrf_dag_node_hashref}{ map { $_->{key} } @sdrf_dcc_col_w_data_conf },
            );
            my @new_sdrf_row_dcc_col_headers = (
                @{$params_hashref->{sdrf_row_dcc_col_headers}},
                'Protocol REF',
                map { $_->{name} } @sdrf_dcc_col_w_data_conf,
            );
            if (exists($sdrf_dag_node_hashref->{child_data_by_protocol_type})) {
                add_dcc_sdrf_data({
                    mage_tab_sdrf_data => $params_hashref->{mage_tab_sdrf_data},
                    mage_tab_sdrf_dcc_col_headers => $params_hashref->{mage_tab_sdrf_dcc_col_headers},
                    sdrf_row_data => $params_hashref->{sdrf_row_data},
                    sdrf_dag_node => $sdrf_dag_node_hashref,
                    protocol_data => $params_hashref->{protocol_data},
                    protocol_info => $params_hashref->{protocol_info},
                    mt_config => $params_hashref->{mt_config},
                    sdrf_row_dcc_data => \@new_sdrf_row_dcc_data,
                    sdrf_row_dcc_col_headers => \@new_sdrf_row_dcc_col_headers,
                });
            }
            else {
                push @{$params_hashref->{mage_tab_sdrf_data}}, [
                    @{$params_hashref->{sdrf_row_data}},
                    @new_sdrf_row_dcc_data,
                ];
                if (
                    !@{$params_hashref->{mage_tab_sdrf_dcc_col_headers}} or 
                    (
                        @{$params_hashref->{mage_tab_sdrf_dcc_col_headers}} and 
                        scalar(@new_sdrf_row_dcc_col_headers) > scalar(@{$params_hashref->{mage_tab_sdrf_dcc_col_headers}})
                    )
                ) {
                    @{$params_hashref->{mage_tab_sdrf_dcc_col_headers}} = @new_sdrf_row_dcc_col_headers;
                }
                if ($debug{sdrf_step}) {
                    local $Data::Dumper::Indent = 0;
                    print STDERR 
                        "\n", +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), ': ',
                        Dumper(\@new_sdrf_row_dcc_col_headers),
                        "\n", +(-t STDERR ? colored('DEBUG', 'red') : 'DEBUG'), ': ',
                        Dumper(\@new_sdrf_row_dcc_data);
                    print "\nPress Enter to Continue...";
                    <STDIN>;
                }
            }
        }
    }
}

sub get_file_names_from_sdrf_dag_node {
    my ($params_hashref) = @_;
    for my $protocol_type (
        natsort keys %{$params_hashref->{sdrf_dag_node}->{child_data_by_protocol_type}}
    ) {
        for my $sdrf_dag_node_hashref (
            natkeysort { $_->{file_name} } @{$params_hashref->{sdrf_dag_node}->{child_data_by_protocol_type}->{$protocol_type}}
        ) {
            if (
                !defined($params_hashref->{file_names}) or
                none { $sdrf_dag_node_hashref->{file_name} eq $_ } @{$params_hashref->{file_names}}
            ) {
                push @{$params_hashref->{file_names}}, $sdrf_dag_node_hashref->{file_name};
                if (exists($sdrf_dag_node_hashref->{child_data_by_protocol_type})) {
                    get_file_names_from_sdrf_dag_node({
                        sdrf_dag_node => $sdrf_dag_node_hashref,
                        file_names => $params_hashref->{file_names},
                    });
                }
            }
        }
    }
}

sub by_dag_center_name {
    (
        $a ne '_default' and $b ne '_default'
    )
    ? mkkey_natural(lc($a)) cmp mkkey_natural(lc($b))
    : $a eq '_default'
    ? -1 
    : $b eq '_default'
    ? 1 
    : 0;
}

__END__

=head1 NAME 

generate_seq_mage_tabs.pl - Sequencing Dataset MAGE-TAB Generator

=head1 SYNOPSIS

 generate_seq_mage_tabs.pl <program name(s)> <project name(s)> <data type(s)> <data set(s)> [options] 
 
 Parameters:
    <program name(s)>       Comma-separated list of program name(s) (optional, default: all programs)
    <project name(s)>       Comma-separated list of project name(s) (optional, default: all program projects)
    <data type(s)>          Comma-separated list of data type(s) (optional, default: all project data types)
    <data set(s)>           Comma-separated list of data set(s) (optional, default: all data type data sets)
 
 Options:
    --list=<...>,<...>      List information and exit (possible values: 'all', 'data_types', 'center_platforms')
    --dist                  Distribute generated MAGE-TAB archives to DCC master data area
    --clean                 Clean up older versions of MAGE-TAB archives in DCC master data area (only works with --dist)
    --rescan-cgi            Rescan CGI data tree (default: use cached data store if it exists)
    --use-cached-run-info   Use cached SRA run info (default: download latest run info table from SRA)
    --use-cached-xml        Use cached SRA-XML files (default: download latest SRA-XML from SRA)
    --verbose               Be verbose
    --help                  Display usage message and exit
    --version               Display program version and exit

=cut
