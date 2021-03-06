use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib/perl5";
use NCI::OCGDCC::Config qw( :all );

# mage-tab generator config
{
    'data' => {
        'seq_data_types' => [qw(
            Bisulfite-seq
            ChIP-seq
            miRNA-seq
            mRNA-seq
            Targeted-Capture
            WGS
            WXS
        )],
        'search_data_level_dir_names' => [qw(
            L3
            L4
        )],
        'maf_barcode_col_names' => [qw(
            Tumor_Sample_Barcode
            Matched_Norm_Sample_Barcode
        )],
    },
    'sra' => {
        'sra2dcc_center_name' => {
            'BCCAGSC' => 'BCCA',
            'BCG-DANVERS' => 'BCG-Danvers',
            'BI' => 'Broad',
            'COMPLETEGENOMICS' => 'CGI',
            'NCI-KHAN' => 'NCI-Khan',
            'NCI-MELTZER' => 'NCI-Meltzer',
	    'NCI-PHS000468' => 'NCI-Meltzer',
            'STJUDE' => 'StJude',
        },
        'sra2dcc_data_type' => {
            'Bisulfite-Seq' => 'Bisulfite-seq',
            'ChIP-Seq' => 'ChIP-seq',
            'miRNA-Seq' => 'miRNA-seq',
            'RNA-Seq' => 'mRNA-seq',
            'Targeted-Capture' => 'Targeted-Capture',
            'WGS' => 'WGS',
            'WXS' => 'WXS',
        },
        'sra2dcc_platform' => {
            'COMPLETE_GENOMICS' => 'CGI',
            'ILLUMINA' => 'Illumina',
            'ION_TORRENT' => 'IonTorrent',
        },
        'exp_library_name_delimiter' => ',',
    },
    'default' => {
        'term_source_ref' => 'EFO',
        'protocol_revision' => '01',
    },
    'idf' => {
        'mage_tab_version' => '1.1',
        'row_names' => [
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
        ],
        'contacts' => [
            {
                'last_name' => 'NCI Office of Cancer Genomics (OCG)',
                'first_name' => '',
                'mid_initials' => '',
                'email' => 'ocg@mail.nih.gov',
                'phone' => '+1 301 451 8027',
                'fax' => '+1 301 480 4368',
                'address' => '31 Center Dr, Rm 10A07, Bethesda, MD 20892',
                'affiliation' => 'National Cancer Institute',
                'roles' => [
                    'funder',
                    'investigator',
                ],
            },
            {
                'last_name' => 'NCI Center for Biomedical Informatics and Information Technology (CBIIT)',
                'first_name' => '',
                'mid_initials' => '',
                'email' => 'ncicbiit@mail.nih.gov',
                'phone' => '+1 888 478 4423',
                'fax' => '',
                'address' => '9609 Medical Center Dr, Rockville, MD 20850',
                'affiliation' => 'National Cancer Institute',
                'roles' => [
                    'data coder',
                    'curator',
                ],
            },
        ],
        'exp_design' => {
            'miRNA-seq' => [
                'disease state design',
                'transcript identification design',
                'is expressed design',
            ],
            'mRNA-seq' => [
                'disease state design',
                'transcript identification design',
                'is expressed design',
            ],
            'WGS' => [
                'disease state design',
            ],
            'WXS' => [
                'disease state design',
            ],
        },
        'protocol_base_types' => {
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
        },
        'protocol_center_info_by_name' => {
            'BCCA' => {
                authority => 'bcgsc.ca',
                full_name => 'BC Cancer Agency Michael Smith Genome Sciences Centre',
            },
            'BCG-Danvers' => {
                authority => 'beckmangenomics.com',
                full_name => 'Beckman Coulter Genomics',
            },
            'BCM' => {
                authority => 'bcm.edu',
                full_name => 'Baylor College of Medicine',
            },
            'Broad' => {
                authority => 'broadinstitute.org',
                full_name => 'The Broad Institute',
            },
            'CGI' => {
                authority => 'completegenomics.com',
                full_name => 'Complete Genomics Inc.',
            },
            'FHCRC' => {
                authority => 'fredhutch.org',
                full_name => 'Fred Hutchinson Cancer Research Center',
            },
            'HAIB' => {
                authority => 'hudsonalpha.org',
                full_name => 'Hudson Alpha Institute for Biotechnology',
            },
            'NCH' => {
                authority => 'nationwidechildrens.org',
                full_name => 'Nationwide Children\'s Hospital Biospecimen Core Repository',
            },
            'NCI-Khan' => {
                authority => 'nci.nih.gov',
                namespace_prefix => 'CCR.Khan',
                full_name => 'NCI Center for Cancer Research Khan Lab',
            },
            'NCI-Meltzer' => {
                authority => 'nci.nih.gov',
                namespace_prefix => 'CCR.Meltzer',
                full_name => 'NCI Center for Cancer Research Meltzer Lab',
            },
            'NCI-Meerzaman' => {
                authority => 'nci.nih.gov',
                namespace_prefix => 'CBIIT.Meerzaman',
                full_name => 'NCI Center for Biomedical Informatics Meerzaman Lab',
            },
            'StJude' => {
                authority => 'stjude.org',
                full_name => 'St. Jude Children\'s Research Hospital',
            },
            'UHN' => {
                authority => 'uhnresearch.ca',
                full_name => 'University Health Network Princess Margaret Cancer Centre',
            },
        },
        'term_sources' => [
            {
                'name' => 'NCBITaxon',
                'file' => 'http://www.ncbi.nlm.nih.gov/taxonomy',
            },
            {
                'name' => 'NCIt',
                'file' => 'http://ncit.nci.nih.gov/',
            },
            {
                'name' => 'MO',
                'file' => 'http://mged.sourceforge.net/ontologies/MGEDontology.php',
            },
            {
                'name' => 'EFO',
                'file' => 'http://www.ebi.ac.uk/efo',
            },
            {
                'name' => 'OBI',
                'file' => 'http://purl.obolibrary.org/obo/obi',
            },
        ],
    },
    'sdrf' => {
        'base_col_names_by_type' => {
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
        },
        'dcc_col_types' => {
            'protocol' => {
                name => 'Protocol REF',
                key => 'protocol_ref',
                attrs => [
                    
                ],
            },
            'file' => {
                name => 'Derived Array Data File',
                key => 'file_name',
                attrs => [
                    {
                        name => 'Comment[OCG Data Level]',
                        key => 'data_level',
                    },
                    {
                        name => 'Comment[miRBase Version]',
                        key => 'mirbase_version',
                    },
                ],
            },
        },
        'dcc_scanned_file_protocol_dag' => {
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
                            type => 'VariantCall-SNVMix2',
                            children => [
                                {
                                    type => 'SNVMix2-Vcf2Maf',
                                },
                                {
                                    type => 'SNVMix2-Vcf2Tab',
                                },
                            ],
                        },
                        {
                            type => 'Expression',
                        },
                        {
                            type => 'StructVariant-TransABySS',
                            children => [
                                {
                                    type => 'StructVariant-GenomeValidator',
                                    constraint_regexp =>
                                        qr/$OCG_BARCODE_REGEXP(?:\..+?)?\.fusion\.vcf/i,
                                    constraint_parent_only => 1,
                                },
                            ],
                        },
                        {
                            type => 'Fusion-DeFuse',
                        },
                    ],
                    'NCI-Khan' => [
                        {
                            type => 'Expression',
                        },
                        {
                            type => 'Fusion-DeFuse',
                        },
                    ],
                    'NCI-Meerzaman' => [
                        {
                            type => 'Expression',
                        },
                        {
                            type => 'Fusion-DeFuse',
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
                            type => 'Expression-Kallisto',
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
                            type => 'Expression-HTSeq',
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
                                    type => 'Mpileup-Vcf2Maf',
                                },
                                {
                                    type => 'Mpileup-Vcf2Tab',
                                },
                            ],
                        },
                        {
                            type => 'VariantCall-Strelka',
                            children => [
                                {
                                    type => 'Strelka-Vcf2Maf',
                                },
                                {
                                    type => 'Strelka-Vcf2Tab-Snv',
                                    constraint_regexp =>
                                        qr/${OCG_BARCODE_REGEXP}_${OCG_BARCODE_REGEXP}\.capture_dna\.somatic\.snv/i,
                                    children => [
                                        {
                                            type => 'CombineSomaticSnvs',
                                        },
                                    ],
                                },
                                {
                                    type => 'Strelka-Vcf2Tab-Indel',
                                    constraint_regexp =>
                                        qr/${OCG_BARCODE_REGEXP}_${OCG_BARCODE_REGEXP}\.capture_dna\.somatic\.indel/i,
                                },
                            ],
                        },
                        {
                            type => 'VariantCall-Mpileup-MutationSeq',
                            children => [
                                {
                                    type => 'CombineSomaticSnvs',
                                },
                            ],
                        },
                        {
                            type => 'CombineSomaticSnvs',
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
                                    type => 'Mpileup-Vcf2Maf',
                                },
                                {
                                    type => 'Mpileup-Vcf2Tab',
                                },
                            ],
                        },
                        {
                            type => 'VariantCall-Strelka',
                            children => [
                                {
                                    type => 'Strelka-Vcf2Maf',
                                },
                                {
                                    type => 'Strelka-Vcf2Tab-Snv',
                                    constraint_regexp =>
                                        qr/${OCG_BARCODE_REGEXP}_${OCG_BARCODE_REGEXP}\.somatic\.snv/i,
                                    children => [
                                        {
                                            type => 'CombineSomaticSnvs',
                                        },
                                    ],
                                },
                                {
                                    type => 'Strelka-Vcf2Tab-Indel',
                                    constraint_regexp =>
                                        qr/${OCG_BARCODE_REGEXP}_${OCG_BARCODE_REGEXP}\.somatic\.indel/i,
                                },
                            ],
                        },
                        {
                            type => 'VariantCall-Mpileup-MutationSeq',
                            children => [
                                {
                                    type => 'CombineSomaticSnvs',
                                },
                            ],
                        },
                        {
                            type => 'CombineSomaticSnvs',
                        },
                        {
                            type => 'StructVariant-ABySS',
                            children => [
                                {
                                    type => 'StructVariant-GenomeValidator',
                                    constraint_regexp =>
                                        qr/$OCG_BARCODE_REGEXP(?:\..+?)?\.fusion\.vcf/i,
                                    constraint_parent_only => 1,
                                },
                            ],
                        },
                        {
                            type => 'StructVariant-DELLY',
                        },
                        {
                            type => 'VariantCall',
                        },
                    ],
                    'CGI' => [
                        {
                            type => 'CnvSegment-CGI',
                            children => [
                                {
                                    type => 'Circos-CGI',
                                    constraint_regexp => qr/${OCG_CASE_REGEXP}_\w+Vs\w+/i,
                                },
                            ],
                        },
                        {
                            type => 'VariantCall-CGI',
                            children => [
                                {
                                    type => 'Vcf2Maf-CGI',
                                    constraint_regexp => qr/${OCG_CASE_REGEXP}_\w+Vs\w+/i,
                                    children => [
                                        {
                                            type => 'FilterSomatic-CGI',
                                            constraint_regexp => qr/${OCG_CASE_REGEXP}_\w+Vs\w+/i,
                                        },
                                        {
                                            type => 'HigherLevelSummary-CGI',
                                        },
                                    ],
                                },
                                {
                                    type => 'Circos-CGI',
                                    constraint_regexp => qr/${OCG_CASE_REGEXP}_\w+Vs\w+/i,
                                },
                            ],
                        },
                        {
                            type => 'Junction-CGI',
                            children => [
                                {
                                    type => 'Circos-CGI',
                                },
                            ],
                        },
                    ],
                    'StJude' => [
                        {
                            type => 'CnvSegment-CONCERTING-CGI',
                        },
                        {
                            type => 'VariantCall-CGI',
                        },
                        {
                            type => 'StructVariant-CGI',
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
                            type => 'CnvSegment-LOHcate',
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
                            type => 'VariantCall-Bambino-DToxoG',
                        },
                    ],
                },
            },
        },
        'nucleic_acid_ltr_sample_desc' => {
            'E' => 'Formalin-fixed, paraffin-embedded (FFPE) tissue',
            'S' => 'Formalin-fixed, paraffin-embedded (FFPE) tissue',
        },
        'nucleic_acid_ltr_extract_desc' => {
            'W' => 'Whole genome amplified (WGA) extract, 1st independent reaction',
            'X' => 'Whole genome amplified (WGA) extract, 2nd independent reaction',
            'Y' => 'Whole genome amplified (WGA) extract, pool of 1st and 2nd independent reactions',
        },
    },
    'project' => {
        'TARGET' => {
            'ALL' => {
                'dbGaP_study_ids' => [qw(
                    phs000463
                    phs000464
                )],
                'idf' => {
                    'contacts' => [
                        {
                            'last_name' => 'Hunger',
                            'first_name' => 'Stephen',
                            'mid_initials' => 'P',
                            'email' => 'hungers@chop.edu',
                            'phone' => '',
                            'fax' => '',
                            'address' => '3401 Civic Center Blvd Philadelphia, PA 19104',
                            'affiliation' => 'Children\'s Hospital of Philadelphia',
                            'roles' => [
                                'investigator',
                            ],
                        },
                        {
                            'last_name' => 'Mullighan',
                            'first_name' => 'Charles',
                            'mid_initials' => '',
                            'email' => 'charles.mullighan@stjude.org',
                            'phone' => '+1 901 595 3387',
                            'fax' => '+1 901 595 5947',
                            'address' => '262 Danny Thomas Place, Mail Stop 342, Memphis TN 38105',
                            'affiliation' => 'St Jude Children\'s Research Hospital',
                            'roles' => [
                                'investigator',
                            ],
                        },
                        {
                            'last_name' => 'Loh',
                            'first_name' => 'Mignon',
                            'mid_initials' => '',
                            'email' => 'lohm@peds.ucsf.edu',
                            'phone' => '+1 415 476 3831',
                            'fax' => '',
                            'address' => 'Box 0106, UCSF',
                            'affiliation' => 'UCSF Benioff Children\'s Hospital',
                            'roles' => [
                                'investigator',
                            ],
                        },
                    ],
                },
                'cases_by_cohort' => {
                    'Discovery' => [qw(
                        TARGET-10-CAAABC        TARGET-10-CAAABD        TARGET-10-CAAABF        TARGET-10-DCC001
                        TARGET-10-DCC002        TARGET-10-PAIXPH        TARGET-10-PAIXSD        TARGET-10-PAKHZT
                        TARGET-10-PAKKCA        TARGET-10-PAKKXB        TARGET-10-PAKMJF        TARGET-10-PAKMVD
                        TARGET-10-PAKMZM        TARGET-10-PAKRSL        TARGET-10-PAKSWW        TARGET-10-PAKTAL
                        TARGET-10-PAKVKK        TARGET-10-PAKYEP        TARGET-10-PAKYKZ        TARGET-10-PALETF
                        TARGET-10-PALIBN        TARGET-10-PALIYC        TARGET-10-PALJCF        TARGET-10-PALJDL
                        TARGET-10-PALKMM        TARGET-10-PALKTY        TARGET-10-PALLSD        TARGET-10-PALNTB
                        TARGET-10-PALTWS        TARGET-10-PALUAH        TARGET-10-PALULW        TARGET-10-PALZVV
                        TARGET-10-PAMDKS        TARGET-10-PAMDRM        TARGET-10-PAMKZB        TARGET-10-PAMXHJ
                        TARGET-10-PAMXSP        TARGET-10-PANATY        TARGET-10-PANCVR        TARGET-10-PANDBX
                        TARGET-10-PANDWE        TARGET-10-PANEBL        TARGET-10-PANEHF        TARGET-10-PANEPX
                        TARGET-10-PANEUH        TARGET-10-PANFNZ        TARGET-10-PANGIF        TARGET-10-PANIEU
                        TARGET-10-PANJPG        TARGET-10-PANJWJ        TARGET-10-PANKAK        TARGET-10-PANKDT
                        TARGET-10-PANKGK        TARGET-10-PANKMB        TARGET-10-PANKRG        TARGET-10-PANLGK
                        TARGET-10-PANLIC        TARGET-10-PANNGL        TARGET-10-PANPJI        TARGET-10-PANPJW
                        TARGET-10-PANRAL        TARGET-10-PANRDC        TARGET-10-PANRWG        TARGET-10-PANRYM
                        TARGET-10-PANSBK        TARGET-10-PANSBR        TARGET-10-PANSDA        TARGET-10-PANSFD
                        TARGET-10-PANSHK        TARGET-10-PANSIA        TARGET-10-PANSPW        TARGET-10-PANSUL
                        TARGET-10-PANSXG        TARGET-10-PANTSM        TARGET-10-PANTTZ        TARGET-10-PANUHA
                        TARGET-10-PANUKN        TARGET-10-PANURW        TARGET-10-PANUSN        TARGET-10-PANUUF
                        TARGET-10-PANVYR        TARGET-10-PANWEZ        TARGET-10-PANWFB        TARGET-10-PANWFL
                        TARGET-10-PANWHJ        TARGET-10-PANWHW        TARGET-10-PANWJB        TARGET-10-PANWVW
                        TARGET-10-PANWYH        TARGET-10-PANWYK        TARGET-10-PANXDB        TARGET-10-PANXDR
                        TARGET-10-PANXPE        TARGET-10-PANYEJ        TARGET-10-PANYGB        TARGET-10-PANYYV
                        TARGET-10-PANYZE        TARGET-10-PANZPJ        TARGET-10-PANZXC        TARGET-10-PANZXZ
                        TARGET-10-PAPACP        TARGET-10-PAPAGK        TARGET-10-PAPAIZ        TARGET-10-PAPAXK
                        TARGET-10-PAPBCI        TARGET-10-PAPBES        TARGET-10-PAPBFN        TARGET-10-PAPBSE
                        TARGET-10-PAPBSY        TARGET-10-PAPBZK        TARGET-10-PAPCUR        TARGET-10-PAPCVZ
                        TARGET-10-PAPCXR        TARGET-10-PAPDFU        TARGET-10-PAPDJM        TARGET-10-PAPDKJ
                        TARGET-10-PAPDNB        TARGET-10-PAPDUF        TARGET-10-PAPDUV        TARGET-10-PAPDWT
                        TARGET-10-PAPEAB        TARGET-10-PAPECF        TARGET-10-PAPEFH        TARGET-10-PAPEJN
                        TARGET-10-PAPESW        TARGET-10-PAPEWB        TARGET-10-PAPFWH        TARGET-10-PAPFXN
                        TARGET-10-PAPGFP        TARGET-10-PAPGGT        TARGET-10-PAPGMV        TARGET-10-PAPGNC
                        TARGET-10-PAPGYC        TARGET-10-PAPHCJ        TARGET-10-PAPHEK        TARGET-10-PAPHGD
                        TARGET-10-PAPHJF        TARGET-10-PAPHMH        TARGET-10-PAPHPX        TARGET-10-PAPHRT
                        TARGET-10-PAPHWH        TARGET-10-PAPHYN        TARGET-10-PAPHZT        TARGET-10-PAPIDY
                        TARGET-10-PAPIGX        TARGET-10-PAPIJB        TARGET-10-PAPIJM        TARGET-10-PAPIKG
                        TARGET-10-PAPIRZ        TARGET-10-PAPISG        TARGET-10-PAPIYG        TARGET-10-PAPJHB
                        TARGET-10-PAPJHR        TARGET-10-PAPJIB        TARGET-10-PAPJRR        TARGET-10-PAPJXI
                        TARGET-10-PAPKNC        TARGET-10-PAPKNJ        TARGET-10-PAPLDL        TARGET-10-PAPLDM
                        TARGET-10-PAPLTZ        TARGET-10-PAPLUG        TARGET-10-PAPMFI        TARGET-10-PAPMVB
                        TARGET-10-PAPMYD        TARGET-10-PAPNFY        TARGET-10-PAPNMY        TARGET-10-PAPNNX
                        TARGET-10-PAPPGN        TARGET-10-PAPRCS        TARGET-10-PAPRFE        TARGET-10-PAPRMM
                        TARGET-10-PAPSPG        TARGET-10-PAPSPN        TARGET-10-PAPTAT        TARGET-10-PAPTHJ
                        TARGET-10-PAPTLM        TARGET-10-PAPVNW        TARGET-10-PAPVTA        TARGET-10-PAPZNK
                        TARGET-10-PAPZST        TARGET-10-PARACA        TARGET-10-PARAKF        TARGET-10-PARAPE
                        TARGET-10-PARARJ        TARGET-10-PARBGL        TARGET-10-PARBRK        TARGET-10-PARBVI
                        TARGET-10-PARCHB        TARGET-10-PARDWE        TARGET-10-PARDWN        TARGET-10-PARELH
                        TARGET-10-PARFLV        TARGET-10-PARFTR        TARGET-10-PARFWD        TARGET-10-PARGFV
                        TARGET-10-PARGHW        TARGET-10-PARGML        TARGET-10-PARGVZ        TARGET-10-PARHUM
                        TARGET-10-PARIAD        TARGET-10-PARIKN        TARGET-10-PARIPA        TARGET-10-PARJLA
                        TARGET-10-PARJSR        TARGET-10-PARJZZ        TARGET-10-PARLAF        TARGET-10-PARLEK
                        TARGET-10-PARLZG        TARGET-10-PARMSP        TARGET-10-PARMXF        TARGET-10-PARNMF
                        TARGET-10-PARNSH        TARGET-10-PARPCA        TARGET-10-PARPNM        TARGET-10-PARPRW
                        TARGET-10-PARPZJ        TARGET-10-PARRAF        TARGET-10-PARRPK        TARGET-10-PARSGC
                        TARGET-10-PARSLL        TARGET-10-PARSZH        TARGET-10-PARTJL        TARGET-10-PARTKL
                        TARGET-10-PARTRW        TARGET-10-PARTYT        TARGET-10-PARUAT        TARGET-10-PARUBK
                        TARGET-10-PARUFL        TARGET-10-PARUGP        TARGET-10-PARUIW        TARGET-10-PARUNW
                        TARGET-10-PARUYU        TARGET-10-PARVBS        TARGET-10-PARVWD        TARGET-10-PARWRJ
                        TARGET-10-PARWVN        TARGET-10-PARWXF        TARGET-10-PARXCD        TARGET-10-PARXMC
                        TARGET-10-PARYAJ        TARGET-10-PARZYX        TARGET-10-PASCIU        TARGET-10-PASDYK
                        TARGET-10-PASDYM        TARGET-10-PASEVJ        TARGET-10-PASFGA        TARGET-10-PASFTL
                        TARGET-10-PASFXA        TARGET-10-PASHUI        TARGET-10-PASIGB        TARGET-10-PASIIK
                        TARGET-10-PASILP        TARGET-10-PASIZE        TARGET-10-PASKAY        TARGET-10-PASKHT
                        TARGET-10-PASLCJ        TARGET-10-PASLMB        TARGET-10-PASLZM        TARGET-10-PASMGZ
                        TARGET-10-PASMVF        TARGET-10-PASNJI        TARGET-10-PASREU        TARGET-10-PASRSV
                        TARGET-10-PASRWZ        TARGET-10-PASRXC        TARGET-10-PASRYW        TARGET-10-PASSXJ
                        TARGET-10-PASTLM        TARGET-10-PASTSR        TARGET-10-PASTYT        TARGET-10-PASUBW
                        TARGET-10-PASUWG        TARGET-10-PASWUH        TARGET-10-PASXFY        TARGET-10-PASXZH
                        TARGET-10-PASYGM        TARGET-10-PATAAH        TARGET-10-PATCJJ        TARGET-10-PATCTI
                        TARGET-10-PATELK        TARGET-10-PATEVE        TARGET-10-PATISC        TARGET-10-PATRIC
                        TARGET-10-PATTEE        TARGET-10-PAUXZX        TARGET-10-SJMPAL017974  TARGET-15-PAREAT
                        TARGET-15-PARUIF        TARGET-15-PARWPU        TARGET-15-PASZVW
                        TARGET-15-PAUFIB        TARGET-15-PAVFTF        TARGET-15-SJMPAL011914
                        TARGET-15-SJMPAL012419  TARGET-15-SJMPAL012421  TARGET-15-SJMPAL012426  TARGET-15-SJMPAL012427
                        TARGET-15-SJMPAL016341  TARGET-15-SJMPAL016342  TARGET-15-SJMPAL016849  TARGET-15-SJMPAL016851
                        TARGET-15-SJMPAL016852  TARGET-15-SJMPAL016854  TARGET-15-SJMPAL016855  TARGET-15-SJMPAL017975
                        TARGET-15-SJMPAL017976  TARGET-15-SJMPAL019076  TARGET-15-SJMPAL040025  TARGET-15-SJMPAL040028
                        TARGET-15-SJMPAL040032  TARGET-15-SJMPAL040036  TARGET-15-SJMPAL040037  TARGET-15-SJMPAL040038
                        TARGET-15-SJMPAL040039  TARGET-15-SJMPAL040459  TARGET-15-SJMPAL041117  TARGET-15-SJMPAL041119
                        TARGET-15-SJMPAL041120  TARGET-15-SJMPAL042787  TARGET-15-SJMPAL042791  TARGET-15-SJMPAL042793
                        TARGET-15-SJMPAL042794  TARGET-15-SJMPAL042798  TARGET-15-SJMPAL042799  TARGET-15-SJMPAL042801
                        TARGET-15-SJMPAL042940  TARGET-15-SJMPAL042941  TARGET-15-SJMPAL042942  TARGET-15-SJMPAL042946
                        TARGET-15-SJMPAL043505  TARGET-15-SJMPAL043506  TARGET-15-SJMPAL043507  TARGET-15-SJMPAL043508
                        TARGET-15-SJMPAL043511  TARGET-15-SJMPAL043512  TARGET-15-SJMPAL043513  TARGET-15-SJMPAL043767
                        TARGET-15-SJMPAL043768  TARGET-15-SJMPAL043769  TARGET-15-SJMPAL043770  TARGET-15-SJMPAL043771
                        TARGET-15-SJMPAL043772  TARGET-15-SJMPAL043773  TARGET-15-SJMPAL043774  TARGET-15-SJMPAL043775
                    )],
                    'Validation' => [qw(
                        TARGET-10-PANSIZ  TARGET-10-PANSTA  TARGET-10-PANSYA  TARGET-10-PANTBB  TARGET-10-PANTCR
                        TARGET-10-PANTLF  TARGET-10-PANTRY  TARGET-10-PANTTB  TARGET-10-PANTTD  TARGET-10-PANTUZ
                        TARGET-10-PANTVC  TARGET-10-PANTWC  TARGET-10-PANTXA  TARGET-10-PANTYP  TARGET-10-PANTZE
                        TARGET-10-PANUKF  TARGET-10-PANURR  TARGET-10-PANUSL  TARGET-10-PANUXS  TARGET-10-PANUXU
                        TARGET-10-PANUYZ  TARGET-10-PANVAW  TARGET-10-PANVCM  TARGET-10-PANVDH  TARGET-10-PANVDV
                        TARGET-10-PANVFF  TARGET-10-PANVGZ  TARGET-10-PANVIB  TARGET-10-PANVIC  TARGET-10-PANVIX
                        TARGET-10-PANVJI  TARGET-10-PANVKF  TARGET-10-PANVKH  TARGET-10-PANVMT  TARGET-10-PANVTB
                        TARGET-10-PANVUD  TARGET-10-PANVUU  TARGET-10-PANVXF  TARGET-10-PANWDL  TARGET-10-PANWDN
                        TARGET-10-PANWDS  TARGET-10-PANWEI  TARGET-10-PANWES  TARGET-10-PANWGG  TARGET-10-PANWIM
                        TARGET-10-PANWJH  TARGET-10-PANWJM  TARGET-10-PANWJR  TARGET-10-PANWJS  TARGET-10-PANWKM
                        TARGET-10-PANWKP  TARGET-10-PANWLH  TARGET-10-PANWSP  TARGET-10-PANWWG  TARGET-10-PANWYM
                        TARGET-10-PANWZG  TARGET-10-PANXAM  TARGET-10-PANXCX  TARGET-10-PANXEE  TARGET-10-PANXGD
                        TARGET-10-PANXGM  TARGET-10-PANXLC  TARGET-10-PANXLP  TARGET-10-PANXLR  TARGET-10-PANXSF
                        TARGET-10-PANXTP  TARGET-10-PANXXD  TARGET-10-PANXZK  TARGET-10-PANXZX  TARGET-10-PANYDL
                        TARGET-10-PANYHB  TARGET-10-PANYJL  TARGET-10-PANYJV  TARGET-10-PANYXD  TARGET-10-PANYXR
                        TARGET-10-PANZBR  TARGET-10-PANZBY  TARGET-10-PANZCF  TARGET-10-PANZEG  TARGET-10-PANZFN
                        TARGET-10-PANZGN  TARGET-10-PANZPU  TARGET-10-PANZSE  TARGET-10-PANZUI  TARGET-10-PANZYY
                        TARGET-10-PANZZI  TARGET-10-PAPADT  TARGET-10-PAPAGB  TARGET-10-PAPAGF  TARGET-10-PAPAGS
                        TARGET-10-PAPAGV  TARGET-10-PAPAGW  TARGET-10-PAPAKJ  TARGET-10-PAPAMA  TARGET-10-PAPAMH
                        TARGET-10-PAPAMS  TARGET-10-PAPANB  TARGET-10-PAPAPC  TARGET-10-PAPAPX  TARGET-10-PAPART
                        TARGET-10-PAPAVR  TARGET-10-PAPAXH  TARGET-10-PAPAZA  TARGET-10-PAPAZD  TARGET-10-PAPBAI
                        TARGET-10-PAPBAN  TARGET-10-PAPBCK  TARGET-10-PAPBLU  TARGET-10-PAPBPC  TARGET-10-PAPBVD
                        TARGET-10-PAPBYM  TARGET-10-PAPBZW  TARGET-10-PAPCED  TARGET-10-PAPCJR  TARGET-10-PAPCNP
                        TARGET-10-PAPCPB  TARGET-10-PAPCRD  TARGET-10-PAPCRJ  TARGET-10-PAPCRU  TARGET-10-PAPCSZ
                        TARGET-10-PAPCUI  TARGET-10-PAPCVI  TARGET-10-PAPCVR  TARGET-10-PAPDBX  TARGET-10-PAPDCS
                        TARGET-10-PAPDDA  TARGET-10-PAPDFS  TARGET-10-PAPDHA  TARGET-10-PAPDKD  TARGET-10-PAPDKR
                        TARGET-10-PAPDLN  TARGET-10-PAPDMU  TARGET-10-PAPDRP  TARGET-10-PAPDSW  TARGET-10-PAPDUX
                        TARGET-10-PAPDVG  TARGET-10-PAPDYE  TARGET-10-PAPEJA  TARGET-10-PAPEJL  TARGET-10-PAPEJM
                        TARGET-10-PAPEMC  TARGET-10-PAPEMZ  TARGET-10-PAPERM  TARGET-10-PAPERN  TARGET-10-PAPERU
                        TARGET-10-PAPERW  TARGET-10-PAPESB  TARGET-10-PAPESY  TARGET-10-PAPESZ  TARGET-10-PAPETC
                        TARGET-10-PAPEZL  TARGET-10-PAPEZR  TARGET-10-PAPFAT  TARGET-10-PAPFBR  TARGET-10-PAPFBX
                        TARGET-10-PAPFFW  TARGET-10-PAPFHH  TARGET-10-PAPFHR  TARGET-10-PAPFHX  TARGET-10-PAPFIX
                        TARGET-10-PAPFKA  TARGET-10-PAPFNV  TARGET-10-PAPFPZ  TARGET-10-PAPFTJ  TARGET-10-PAPFUF
                        TARGET-10-PAPFZF  TARGET-10-PAPFZL  TARGET-10-PAPFZX  TARGET-10-PAPGEE  TARGET-10-PAPGFD
                        TARGET-10-PAPGKP  TARGET-10-PAPGLD  TARGET-10-PAPGLS  TARGET-10-PAPGMT  TARGET-10-PAPGWN
                        TARGET-10-PAPHAM  TARGET-10-PAPHBW  TARGET-10-PAPHCA  TARGET-10-PAPHDN  TARGET-10-PAPHDX
                        TARGET-10-PAPHED  TARGET-10-PAPHHP  TARGET-10-PAPHIG  TARGET-10-PAPHLH  TARGET-10-PAPHNM
                        TARGET-10-PAPHNR  TARGET-10-PAPHRV  TARGET-10-PAPHWE  TARGET-10-PAPHXJ  TARGET-10-PAPHYM
                        TARGET-10-PAPHYV  TARGET-10-PAPICC  TARGET-10-PAPIEW  TARGET-10-PAPIGD  TARGET-10-PAPIGV
                        TARGET-10-PAPIHH  TARGET-10-PAPIHT  TARGET-10-PAPIHU  TARGET-10-PAPIIB  TARGET-10-PAPIIX
                        TARGET-10-PAPIJD  TARGET-10-PAPILF  TARGET-10-PAPILG  TARGET-10-PAPIPG  TARGET-10-PAPZPJ
                        TARGET-10-PAPZPZ  TARGET-10-PAPZRA  TARGET-10-PAPZRB  TARGET-10-PAPZTD  TARGET-10-PAPZTL
                        TARGET-10-PAPZTS  TARGET-10-PAPZUE  TARGET-10-PAPZUW  TARGET-10-PAPZVI  TARGET-10-PAPZWP
                        TARGET-10-PAPZXI  TARGET-10-PAPZZJ  TARGET-10-PARABL  TARGET-10-PARABU  TARGET-10-PARACE
                        TARGET-10-PARAFH  TARGET-10-PARAFI  TARGET-10-PARAGW  TARGET-10-PARAJY  TARGET-10-PARANN
                        TARGET-10-PARAPT  TARGET-10-PARASC  TARGET-10-PARASN  TARGET-10-PARASZ  TARGET-10-PARATY
                        TARGET-10-PARAUE  TARGET-10-PARAXH  TARGET-10-PARAYM  TARGET-10-PARAZN  TARGET-10-PARBBV
                        TARGET-10-PARBCW  TARGET-10-PARBDP  TARGET-10-PARBGG  TARGET-10-PARBHI  TARGET-10-PARBIX
                        TARGET-10-PARBKG  TARGET-10-PARBKP  TARGET-10-PARBLL  TARGET-10-PARBLS  TARGET-10-PARBND
                        TARGET-10-PARBNY  TARGET-10-PARBPX  TARGET-10-PARBRM  TARGET-10-PARBRV  TARGET-10-PARBRX
                        TARGET-10-PARBSP  TARGET-10-PARBSW  TARGET-10-PARBTA  TARGET-10-PARBWN  TARGET-10-PARBXX
                        TARGET-10-PARBYS  TARGET-10-PARBYU  TARGET-10-PARBZT  TARGET-10-PARCAX  TARGET-10-PARCBE
                        TARGET-10-PARCBK  TARGET-10-PARCCM  TARGET-10-PARCDS  TARGET-10-PARCDV  TARGET-10-PARCDX
                        TARGET-10-PARCDZ  TARGET-10-PARCFM  TARGET-10-PARCGU  TARGET-10-PARCHU  TARGET-10-PARCHY
                        TARGET-10-PARCKD  TARGET-10-PARCKJ  TARGET-10-PARCKV  TARGET-10-PARCLU  TARGET-10-PARCLW
                        TARGET-10-PARCMD  TARGET-10-PARCMG  TARGET-10-PARCSH  TARGET-10-PARCTN  TARGET-10-PARCUM
                        TARGET-10-PARCUW  TARGET-10-PARCVB  TARGET-10-PARCVM  TARGET-10-PARCVT  TARGET-10-PARCWB
                        TARGET-10-PARCZY  TARGET-10-PARDAK  TARGET-10-PARDBN  TARGET-10-PARDBT  TARGET-10-PARDCJ
                        TARGET-10-PARDCR  TARGET-10-PARDCY  TARGET-10-PARDDM  TARGET-10-PARDDV  TARGET-10-PARDDW
                        TARGET-10-PARDEG  TARGET-10-PARDEJ  TARGET-10-PARDEP  TARGET-10-PARDEY  TARGET-10-PARDFB
                        TARGET-10-PARDFH  TARGET-10-PARDFI  TARGET-10-PARDFN  TARGET-10-PARDHK  TARGET-10-PARDHW
                        TARGET-10-PARDIN  TARGET-10-PARDKG  TARGET-10-PARDLJ  TARGET-10-PARDLP  TARGET-10-PARDLR
                        TARGET-10-PARDLZ  TARGET-10-PARDMI  TARGET-10-PARDNF  TARGET-10-PARDRI  TARGET-10-PARDRS
                        TARGET-10-PARDSN  TARGET-10-PARDSP  TARGET-10-PARDST  TARGET-10-PARDUM  TARGET-10-PARDVD
                        TARGET-10-PARDWM  TARGET-10-PARDXG  TARGET-10-PARDXI  TARGET-10-PARDXS  TARGET-10-PAREAA
                        TARGET-10-PAREAL  TARGET-10-PAREBA  TARGET-10-PAREBH  TARGET-10-PAREDS  TARGET-10-PAREEE
                        TARGET-10-PAREEX  TARGET-10-PAREGC  TARGET-10-PAREGE  TARGET-10-PAREGZ  TARGET-10-PAREHN
                        TARGET-10-PAREIE  TARGET-10-PAREIN  TARGET-10-PAREIV  TARGET-10-PAREJA  TARGET-10-PAREJZ
                        TARGET-10-PAREKG  TARGET-10-PAREKH  TARGET-10-PAREKM  TARGET-10-PARENT  TARGET-10-PARENU
                        TARGET-10-PARENW  TARGET-10-PAREPB  TARGET-10-PAREPF  TARGET-10-PARERM  TARGET-10-PARERS
                        TARGET-10-PARESP  TARGET-10-PAREST  TARGET-10-PARETC  TARGET-10-PARETH  TARGET-10-PARETV
                        TARGET-10-PAREUH  TARGET-10-PAREWE  TARGET-10-PAREWM  TARGET-10-PAREWZ  TARGET-10-PAREYJ
                        TARGET-10-PAREYW  TARGET-10-PAREZM  TARGET-10-PARFAP  TARGET-10-PARFDB  TARGET-10-PARFDG
                        TARGET-10-PARFDL  TARGET-10-PARFDW  TARGET-10-PARFEH  TARGET-10-PARFFC  TARGET-10-PARFHH
                        TARGET-10-PARFIH  TARGET-10-PARFIZ  TARGET-10-PARFJK  TARGET-10-PARFJM  TARGET-10-PARFKD
                        TARGET-10-PARFPJ  TARGET-10-PARFSF  TARGET-10-PARFXJ  TARGET-10-PARGBK  TARGET-10-PARGBR
                        TARGET-10-PARGBT  TARGET-10-PARGFL  TARGET-10-PARGFX  TARGET-10-PARGGI  TARGET-10-PARGJH
                        TARGET-10-PARGJY  TARGET-10-PARGKD  TARGET-10-PARGLE  TARGET-10-PARGLI  TARGET-10-PARGLW
                        TARGET-10-PARGMW  TARGET-10-PARGUZ  TARGET-10-PARGYV  TARGET-10-PARHAN  TARGET-10-PARHBI
                        TARGET-10-PARHBT  TARGET-10-PARHEA  TARGET-10-PARHES  TARGET-10-PARHFF  TARGET-10-PARHLM
                        TARGET-10-PARHMT  TARGET-10-PARHSD  TARGET-10-PARIBB  TARGET-10-PARIIA  TARGET-10-PARILG
                        TARGET-10-PARIYD  TARGET-10-PARIZN  TARGET-10-PARJAY  TARGET-10-PARJBB  TARGET-10-PARJBZ
                        TARGET-10-PARJJP  TARGET-10-PARJLF  TARGET-10-PARJMY  TARGET-10-PARJNL  TARGET-10-PARJNR
                        TARGET-10-PARJNX  TARGET-10-PARJPL  TARGET-10-PARJRT  TARGET-10-PARJWB  TARGET-10-PARJXW
                        TARGET-10-PARJYV  TARGET-10-PARKBT  TARGET-10-PARKEN  TARGET-10-PARKEU  TARGET-10-PARKFN
                        TARGET-10-PARKFU  TARGET-10-PARKLK  TARGET-10-PARKLL  TARGET-10-PARKZX  TARGET-10-PARLBP
                        TARGET-10-PARLDF  TARGET-10-PARLFI  TARGET-10-PARLHD  TARGET-10-PARLJA  TARGET-10-PARLMI
                        TARGET-10-PARLPA  TARGET-10-PARLPB  TARGET-10-PARLST  TARGET-10-PARLSU  TARGET-10-PARLTU
                        TARGET-10-PARLTX  TARGET-10-PARMEG  TARGET-10-PARMFF  TARGET-10-PARMIH  TARGET-10-PARMKK
                        TARGET-10-PARMKM  TARGET-10-PARMMA  TARGET-10-PARMMV  TARGET-10-PARMRF  TARGET-10-PARMSB
                        TARGET-10-PARMUC  TARGET-10-PARMWH  TARGET-10-PARMWZ  TARGET-10-PARMYP  TARGET-10-PARNAF
                        TARGET-10-PARNBN  TARGET-10-PARNDB  TARGET-10-PARNDY  TARGET-10-PARNEH  TARGET-10-PARNGI
                        TARGET-10-PARNIZ  TARGET-10-PARNJB  TARGET-10-PARNLW  TARGET-10-PARNMV  TARGET-10-PARNSP
                        TARGET-10-PARNSW  TARGET-10-PARNXJ  TARGET-10-PARPDP  TARGET-10-PARPET  TARGET-10-PARPFF
                        TARGET-10-PARPGJ  TARGET-10-PARPGL  TARGET-10-PARPGW  TARGET-10-PARPHB  TARGET-10-PARPIF
                        TARGET-10-PARPPV  TARGET-10-PARPUL  TARGET-10-PARPXV  TARGET-10-PARPYH  TARGET-10-PARPYJ
                        TARGET-10-PARPYS  TARGET-10-PARPZI  TARGET-10-PARPZR  TARGET-10-PARRJV  TARGET-10-PARRKG
                        TARGET-10-PARRKK  TARGET-10-PARRMU  TARGET-10-PARRPA  TARGET-10-PARRSR  TARGET-10-PARRVI
                        TARGET-10-PARRVK  TARGET-10-PARRYW  TARGET-10-PARSET  TARGET-10-PARSGM  TARGET-10-PARSHV
                        TARGET-10-PARSJG  TARGET-10-PARSJH  TARGET-10-PARSKH  TARGET-10-PARSKV  TARGET-10-PARSKY
                        TARGET-10-PARSNX  TARGET-10-PARSRI  TARGET-10-PARSSV  TARGET-10-PARSTB  TARGET-10-PARSUV
                        TARGET-10-PARTAK  TARGET-10-PARTAY  TARGET-10-PARTBP  TARGET-10-PARTEF  TARGET-10-PARTGB
                        TARGET-10-PARTGW  TARGET-10-PARTID  TARGET-10-PARTIK  TARGET-10-PARTJJ  TARGET-10-PARTLY
                        TARGET-10-PARTPW  TARGET-10-PARTSC  TARGET-10-PARTWH  TARGET-10-PARTZE  TARGET-10-PARTZJ
                        TARGET-10-PARUBN  TARGET-10-PARUBU  TARGET-10-PARUBX  TARGET-10-PARUCI  TARGET-10-PARUCT
                        TARGET-10-PARUEU  TARGET-10-PARUGV  TARGET-10-PARUIT  TARGET-10-PARUKK  TARGET-10-PARUKW
                        TARGET-10-PARURK  TARGET-10-PARUYE  TARGET-10-PARUYH  TARGET-10-PARUYU  TARGET-10-PARVAK
                        TARGET-10-PARVBL  TARGET-10-PARVBY  TARGET-10-PARVCG  TARGET-10-PARVEI  TARGET-10-PARVHY
                        TARGET-10-PARVMR  TARGET-10-PARWDM  TARGET-10-PARWID  TARGET-10-PARWLP  TARGET-10-PARWMF
                        TARGET-10-PARWNW  TARGET-10-PARXHT  TARGET-10-PARXLS  TARGET-10-PARXMV  TARGET-10-PARXVS
                        TARGET-10-PARYGI  TARGET-10-PARYMD  TARGET-10-PASFHR  TARGET-10-PASFKA  TARGET-10-PASFLK
                        TARGET-10-PASGBD  TARGET-10-PASGFH  TARGET-10-PASHDV  TARGET-10-PASHNK  TARGET-10-PASHUP
                        TARGET-10-PASHXL  TARGET-10-PASIIY  TARGET-10-PASILW  TARGET-10-PASINX  TARGET-10-PASJJR
                        TARGET-10-PASJLN  TARGET-10-PASJMK  TARGET-10-PASJYI  TARGET-10-PASKAD  TARGET-10-PASKCL
                        TARGET-10-PASKGG  TARGET-10-PASKIC  TARGET-10-PASKRN  TARGET-10-PASKSY  TARGET-10-PASKTG
                        TARGET-10-PASKXN  TARGET-10-PASLAB  TARGET-10-PASLBB  TARGET-10-PASMHF  TARGET-10-PASMIC
                        TARGET-10-PASMNV  TARGET-10-PASNEH  TARGET-10-PASNTZ  TARGET-10-PASPBU  TARGET-10-PASPDS
                        TARGET-10-PASPPN  TARGET-10-PASRCV  TARGET-10-PASRMM  TARGET-10-PASSEF  TARGET-10-PASSHC
                        TARGET-10-PASSPP  TARGET-10-PASSRP  TARGET-10-PASSSR  TARGET-10-PASSZA  TARGET-10-PASTDU
                        TARGET-10-PASTHE  TARGET-10-PASTLP  TARGET-10-PASTPT  TARGET-10-PASTXU  TARGET-10-PASUGC
                        TARGET-10-PASUIN  TARGET-10-PASUSV  TARGET-10-PASVIN  TARGET-10-PASVPZ  TARGET-10-PASWFN
                        TARGET-10-PASWNU  TARGET-10-PASWSR  TARGET-10-PASWXB  TARGET-10-PASWXZ  TARGET-10-PASWZJ
                        TARGET-10-PASXIL  TARGET-10-PASXLT  TARGET-10-PASXLZ  TARGET-10-PASXMF  TARGET-10-PASXSI
                        TARGET-10-PASXUC  TARGET-10-PASXUU  TARGET-10-PASYAJ  TARGET-10-PASYCN  TARGET-10-PASYHN
                        TARGET-10-PASYIS  TARGET-10-PASYSJ  TARGET-10-PASYWF  TARGET-10-PASZEW  TARGET-10-PASZIY
                        TARGET-10-PASZJW  TARGET-10-PATALJ  TARGET-10-PATAXS  TARGET-10-PATAYT  TARGET-10-PATBDJ
                        TARGET-10-PATBDK  TARGET-10-PATBGC  TARGET-10-PATBNT  TARGET-10-PATBRV  TARGET-10-PATBTX
                        TARGET-10-PATBYK  TARGET-10-PATCDM  TARGET-10-PATCDZ  TARGET-10-PATCKV  TARGET-10-PATCNI
                        TARGET-10-PATCUK  TARGET-10-PATCZN  TARGET-10-PATDBU  TARGET-10-PATDDZ  TARGET-10-PATDFE
                        TARGET-10-PATDGZ  TARGET-10-PATDKT  TARGET-10-PATDLG  TARGET-10-PATDMN  TARGET-10-PATDRC
                        TARGET-10-PATEAK  TARGET-10-PATEFF  TARGET-10-PATEHZ  TARGET-10-PATEIT  TARGET-10-PATEMI
                        TARGET-10-PATENL  TARGET-10-PATEVL  TARGET-10-PATEYS  TARGET-10-PATFJD  TARGET-10-PATFJP
                        TARGET-10-PATFRM  TARGET-10-PATFVG  TARGET-10-PATFWF  TARGET-10-PATFYZ  TARGET-10-PATGBY
                        TARGET-10-PATGKE  TARGET-10-PATGLV  TARGET-10-PATGMP  TARGET-10-PATGVX  TARGET-10-PATGWP
                        TARGET-10-PATGXS  TARGET-10-PATGYH  TARGET-10-PATGZA  TARGET-10-PATHBG  TARGET-10-PATHFE
                        TARGET-10-PATHGY  TARGET-10-PATHJF  TARGET-10-PATHRF  TARGET-10-PATHWV  TARGET-10-PATIBE
                        TARGET-10-PATIKN  TARGET-10-PATITB  TARGET-10-PATITY  TARGET-10-PATJBC  TARGET-10-PATJLT
                        TARGET-10-PATJZK  TARGET-10-PATKGP  TARGET-10-PATKVD  TARGET-10-PATKWU  TARGET-10-PATKYI
                        TARGET-10-PATLGU  TARGET-10-PATLHH  TARGET-10-PATLHS  TARGET-10-PATLMA  TARGET-10-PATLNS
                        TARGET-10-PATLNZ  TARGET-10-PATLPN  TARGET-10-PATLRZ  TARGET-10-PATMAF  TARGET-10-PATMRE
                        TARGET-10-PATMTV  TARGET-10-PATMVH  TARGET-10-PATMXN  TARGET-10-PATMYZ  TARGET-10-PATNAM
                        TARGET-10-PATNIA  TARGET-10-PATPDA  TARGET-10-PATPGE  TARGET-10-PATPWF  TARGET-10-PATRAB
                        TARGET-10-PATRGV  TARGET-10-PATRHL  TARGET-10-PATRNA  TARGET-10-PATRUN  TARGET-10-PATRXL
                        TARGET-10-PATSDS  TARGET-10-PATSIL  TARGET-10-PATSIY  TARGET-10-PATSLH  TARGET-10-PATTHR
                        TARGET-10-PATVDA  TARGET-10-PATWHB  TARGET-10-PATWIJ  TARGET-10-PATWJU  TARGET-10-PATWNL
                        TARGET-10-PATWXC  TARGET-10-PATWYL  TARGET-10-PATWYZ  TARGET-10-PATXAL  TARGET-10-PATXKW
                        TARGET-10-PATXNK  TARGET-10-PATXNR  TARGET-10-PATXSK  TARGET-10-PATYCH  TARGET-10-PATYJK
                        TARGET-10-PATYMP  TARGET-10-PATYWV  TARGET-10-PATZFF  TARGET-10-PATZSL  TARGET-10-PATZVD
                        TARGET-10-PATZWA  TARGET-10-PATZYC  TARGET-10-PATZYR  TARGET-10-PAUACG  TARGET-10-PAUAFN
                        TARGET-10-PAUAJA  TARGET-10-PAUAYB  TARGET-10-PAUAZV  TARGET-10-PAUBCB  TARGET-10-PAUBCT
                        TARGET-10-PAUBLL  TARGET-10-PAUBPY  TARGET-10-PAUBRD  TARGET-10-PAUBTC  TARGET-10-PAUBXP
                        TARGET-10-PAUCDC  TARGET-10-PAUCDY  
                    )],
                },
                'cases_by_disease' => {
                    'B-ALL' => [qw(
                        TARGET-10-DCC001  TARGET-10-DCC002  TARGET-10-PAIXPH  TARGET-10-PAIXSD  TARGET-10-PAKHZT
                        TARGET-10-PAKKCA  TARGET-10-PAKKXB  TARGET-10-PAKMJF  TARGET-10-PAKMVD  TARGET-10-PAKMZM
                        TARGET-10-PAKRSL  TARGET-10-PAKSWW  TARGET-10-PAKTAL  TARGET-10-PAKVKK  TARGET-10-PAKYEP
                        TARGET-10-PAKYKZ  TARGET-10-PALETF  TARGET-10-PALIBN  TARGET-10-PALIYC  TARGET-10-PALJCF
                        TARGET-10-PALJDL  TARGET-10-PALKMM  TARGET-10-PALKTY  TARGET-10-PALLSD  TARGET-10-PALNTB
                        TARGET-10-PALTWS  TARGET-10-PALUAH  TARGET-10-PALULW  TARGET-10-PALZVV  TARGET-10-PAMDKS
                        TARGET-10-PAMDRM  TARGET-10-PAMKZB  TARGET-10-PAMXHJ  TARGET-10-PAMXSP  TARGET-10-PANATY
                        TARGET-10-PANCVR  TARGET-10-PANDBX  TARGET-10-PANDWE  TARGET-10-PANEBL  TARGET-10-PANEHF
                        TARGET-10-PANEPX  TARGET-10-PANEUH  TARGET-10-PANFNZ  TARGET-10-PANGIF  TARGET-10-PANIEU
                        TARGET-10-PANJPG  TARGET-10-PANJWJ  TARGET-10-PANKAK  TARGET-10-PANKDT  TARGET-10-PANKGK
                        TARGET-10-PANKMB  TARGET-10-PANKRG  TARGET-10-PANLGK  TARGET-10-PANLIC  TARGET-10-PANNGL
                        TARGET-10-PANPJI  TARGET-10-PANPJW  TARGET-10-PANRAL  TARGET-10-PANRDC  TARGET-10-PANRWG
                        TARGET-10-PANRYM  TARGET-10-PANSBK  TARGET-10-PANSBR  TARGET-10-PANSDA  TARGET-10-PANSFD
                        TARGET-10-PANSHK  TARGET-10-PANSIA  TARGET-10-PANSIZ  TARGET-10-PANSPW  TARGET-10-PANSTA
                        TARGET-10-PANSUL  TARGET-10-PANSXG  TARGET-10-PANSYA  TARGET-10-PANTBB  TARGET-10-PANTCR
                        TARGET-10-PANTLF  TARGET-10-PANTRY  TARGET-10-PANTSM  TARGET-10-PANTTB  TARGET-10-PANTTD
                        TARGET-10-PANTTZ  TARGET-10-PANTUZ  TARGET-10-PANTVC  TARGET-10-PANTWC  TARGET-10-PANTXA
                        TARGET-10-PANTYP  TARGET-10-PANTZE  TARGET-10-PANUHA  TARGET-10-PANUKF  TARGET-10-PANUKN
                        TARGET-10-PANURR  TARGET-10-PANURW  TARGET-10-PANUSL  TARGET-10-PANUSN  TARGET-10-PANUUF
                        TARGET-10-PANUXS  TARGET-10-PANUXU  TARGET-10-PANUYZ  TARGET-10-PANVAW  TARGET-10-PANVCM
                        TARGET-10-PANVDH  TARGET-10-PANVDV  TARGET-10-PANVFF  TARGET-10-PANVGZ  TARGET-10-PANVIB
                        TARGET-10-PANVIC  TARGET-10-PANVIX  TARGET-10-PANVJI  TARGET-10-PANVKF  TARGET-10-PANVKH
                        TARGET-10-PANVMT  TARGET-10-PANVTB  TARGET-10-PANVUD  TARGET-10-PANVUU  TARGET-10-PANVXF
                        TARGET-10-PANVYR  TARGET-10-PANWDL  TARGET-10-PANWDN  TARGET-10-PANWDS  TARGET-10-PANWEI
                        TARGET-10-PANWES  TARGET-10-PANWEZ  TARGET-10-PANWFB  TARGET-10-PANWFL  TARGET-10-PANWGG
                        TARGET-10-PANWHJ  TARGET-10-PANWHW  TARGET-10-PANWIM  TARGET-10-PANWJB  TARGET-10-PANWJH
                        TARGET-10-PANWJM  TARGET-10-PANWJR  TARGET-10-PANWJS  TARGET-10-PANWKM  TARGET-10-PANWKP
                        TARGET-10-PANWLH  TARGET-10-PANWSP  TARGET-10-PANWVW  TARGET-10-PANWWG  TARGET-10-PANWYH
                        TARGET-10-PANWYK  TARGET-10-PANWYM  TARGET-10-PANWZG  TARGET-10-PANXAM  TARGET-10-PANXCX
                        TARGET-10-PANXDB  TARGET-10-PANXDR  TARGET-10-PANXEE  TARGET-10-PANXGD  TARGET-10-PANXGM
                        TARGET-10-PANXLC  TARGET-10-PANXLP  TARGET-10-PANXLR  TARGET-10-PANXPE  TARGET-10-PANXSF
                        TARGET-10-PANXTP  TARGET-10-PANXXD  TARGET-10-PANXZK  TARGET-10-PANXZX  TARGET-10-PANYDL
                        TARGET-10-PANYEJ  TARGET-10-PANYGB  TARGET-10-PANYHB  TARGET-10-PANYJL  TARGET-10-PANYJV
                        TARGET-10-PANYXD  TARGET-10-PANYXR  TARGET-10-PANYYV  TARGET-10-PANYZE  TARGET-10-PANZBR
                        TARGET-10-PANZBY  TARGET-10-PANZCF  TARGET-10-PANZEG  TARGET-10-PANZFN  TARGET-10-PANZGN
                        TARGET-10-PANZPJ  TARGET-10-PANZPU  TARGET-10-PANZSE  TARGET-10-PANZUI  TARGET-10-PANZXC
                        TARGET-10-PANZXZ  TARGET-10-PANZYY  TARGET-10-PANZZI  TARGET-10-PAPACP  TARGET-10-PAPADT
                        TARGET-10-PAPAGB  TARGET-10-PAPAGF  TARGET-10-PAPAGK  TARGET-10-PAPAGS  TARGET-10-PAPAGV
                        TARGET-10-PAPAGW  TARGET-10-PAPAIZ  TARGET-10-PAPAKJ  TARGET-10-PAPAMA  TARGET-10-PAPAMH
                        TARGET-10-PAPAMS  TARGET-10-PAPANB  TARGET-10-PAPAPC  TARGET-10-PAPAPX  TARGET-10-PAPART
                        TARGET-10-PAPAVR  TARGET-10-PAPAXH  TARGET-10-PAPAXK  TARGET-10-PAPAZA  TARGET-10-PAPAZD
                        TARGET-10-PAPBAI  TARGET-10-PAPBAN  TARGET-10-PAPBCI  TARGET-10-PAPBCK  TARGET-10-PAPBES
                        TARGET-10-PAPBFN  TARGET-10-PAPBLU  TARGET-10-PAPBPC  TARGET-10-PAPBSE  TARGET-10-PAPBSY
                        TARGET-10-PAPBVD  TARGET-10-PAPBYM  TARGET-10-PAPBZK  TARGET-10-PAPBZW  TARGET-10-PAPCED
                        TARGET-10-PAPCJR  TARGET-10-PAPCNP  TARGET-10-PAPCPB  TARGET-10-PAPCRD  TARGET-10-PAPCRJ
                        TARGET-10-PAPCRU  TARGET-10-PAPCSZ  TARGET-10-PAPCUI  TARGET-10-PAPCUR  TARGET-10-PAPCVI
                        TARGET-10-PAPCVR  TARGET-10-PAPCVZ  TARGET-10-PAPCXR  TARGET-10-PAPDBX  TARGET-10-PAPDCS
                        TARGET-10-PAPDDA  TARGET-10-PAPDFS  TARGET-10-PAPDFU  TARGET-10-PAPDHA  TARGET-10-PAPDJM
                        TARGET-10-PAPDKD  TARGET-10-PAPDKJ  TARGET-10-PAPDKR  TARGET-10-PAPDLN  TARGET-10-PAPDMU
                        TARGET-10-PAPDNB  TARGET-10-PAPDRP  TARGET-10-PAPDSW  TARGET-10-PAPDUF  TARGET-10-PAPDUV
                        TARGET-10-PAPDUX  TARGET-10-PAPDVG  TARGET-10-PAPDWT  TARGET-10-PAPDYE  TARGET-10-PAPEAB
                        TARGET-10-PAPECF  TARGET-10-PAPEFH  TARGET-10-PAPEJA  TARGET-10-PAPEJL  TARGET-10-PAPEJM
                        TARGET-10-PAPEJN  TARGET-10-PAPEMC  TARGET-10-PAPEMZ  TARGET-10-PAPERM  TARGET-10-PAPERN
                        TARGET-10-PAPERU  TARGET-10-PAPERW  TARGET-10-PAPESB  TARGET-10-PAPESW  TARGET-10-PAPESY
                        TARGET-10-PAPESZ  TARGET-10-PAPETC  TARGET-10-PAPEWB  TARGET-10-PAPEZL  TARGET-10-PAPEZR
                        TARGET-10-PAPFAT  TARGET-10-PAPFBR  TARGET-10-PAPFBX  TARGET-10-PAPFFW  TARGET-10-PAPFHH
                        TARGET-10-PAPFHR  TARGET-10-PAPFHX  TARGET-10-PAPFIX  TARGET-10-PAPFKA  TARGET-10-PAPFNV
                        TARGET-10-PAPFPZ  TARGET-10-PAPFTJ  TARGET-10-PAPFUF  TARGET-10-PAPFWH  TARGET-10-PAPFXN
                        TARGET-10-PAPFZF  TARGET-10-PAPFZL  TARGET-10-PAPFZX  TARGET-10-PAPGEE  TARGET-10-PAPGFD
                        TARGET-10-PAPGFP  TARGET-10-PAPGGT  TARGET-10-PAPGKP  TARGET-10-PAPGLD  TARGET-10-PAPGLS
                        TARGET-10-PAPGMT  TARGET-10-PAPGMV  TARGET-10-PAPGNC  TARGET-10-PAPGWN  TARGET-10-PAPGYC
                        TARGET-10-PAPHAM  TARGET-10-PAPHBW  TARGET-10-PAPHCA  TARGET-10-PAPHCJ  TARGET-10-PAPHDN
                        TARGET-10-PAPHDX  TARGET-10-PAPHED  TARGET-10-PAPHEK  TARGET-10-PAPHGD  TARGET-10-PAPHHP
                        TARGET-10-PAPHIG  TARGET-10-PAPHJF  TARGET-10-PAPHLH  TARGET-10-PAPHMH  TARGET-10-PAPHNM
                        TARGET-10-PAPHNR  TARGET-10-PAPHPX  TARGET-10-PAPHRT  TARGET-10-PAPHRV  TARGET-10-PAPHWE
                        TARGET-10-PAPHWH  TARGET-10-PAPHXJ  TARGET-10-PAPHYM  TARGET-10-PAPHYN  TARGET-10-PAPHYV
                        TARGET-10-PAPHZT  TARGET-10-PAPICC  TARGET-10-PAPIDY  TARGET-10-PAPIEW  TARGET-10-PAPIGD
                        TARGET-10-PAPIGV  TARGET-10-PAPIGX  TARGET-10-PAPIHH  TARGET-10-PAPIHT  TARGET-10-PAPIHU
                        TARGET-10-PAPIIB  TARGET-10-PAPIIX  TARGET-10-PAPIJB  TARGET-10-PAPIJD  TARGET-10-PAPIJM
                        TARGET-10-PAPIKG  TARGET-10-PAPILF  TARGET-10-PAPILG  TARGET-10-PAPIPG  TARGET-10-PAPIRZ
                        TARGET-10-PAPISG  TARGET-10-PAPIYG  TARGET-10-PAPJHB  TARGET-10-PAPJHR  TARGET-10-PAPJIB
                        TARGET-10-PAPJRR  TARGET-10-PAPJXI  TARGET-10-PAPKNC  TARGET-10-PAPKNJ  TARGET-10-PAPLDL
                        TARGET-10-PAPLDM  TARGET-10-PAPLTZ  TARGET-10-PAPLUG  TARGET-10-PAPMFI  TARGET-10-PAPMVB
                        TARGET-10-PAPMYD  TARGET-10-PAPNFY  TARGET-10-PAPNMY  TARGET-10-PAPNNX  TARGET-10-PAPPGN
                        TARGET-10-PAPRCS  TARGET-10-PAPRFE  TARGET-10-PAPRMM  TARGET-10-PAPSPG  TARGET-10-PAPSPN
                        TARGET-10-PAPTAT  TARGET-10-PAPTHJ  TARGET-10-PAPTLM  TARGET-10-PAPVNW  TARGET-10-PAPVTA
                        TARGET-10-PAPZNK  TARGET-10-PAPZPJ  TARGET-10-PAPZPZ  TARGET-10-PAPZRA  TARGET-10-PAPZRB
                        TARGET-10-PAPZST  TARGET-10-PAPZTD  TARGET-10-PAPZTL  TARGET-10-PAPZTS  TARGET-10-PAPZUE
                        TARGET-10-PAPZUW  TARGET-10-PAPZVI  TARGET-10-PAPZWP  TARGET-10-PAPZXI  TARGET-10-PAPZZJ
                        TARGET-10-PARABL  TARGET-10-PARABU  TARGET-10-PARACA  TARGET-10-PARACE  TARGET-10-PARAFH
                        TARGET-10-PARAFI  TARGET-10-PARAGW  TARGET-10-PARAJY  TARGET-10-PARAKF  TARGET-10-PARANN
                        TARGET-10-PARAPE  TARGET-10-PARAPT  TARGET-10-PARARJ  TARGET-10-PARASC  TARGET-10-PARASN
                        TARGET-10-PARATY  TARGET-10-PARAUE  TARGET-10-PARAXH  TARGET-10-PARAZN  TARGET-10-PARBBV
                        TARGET-10-PARBCW  TARGET-10-PARBDP  TARGET-10-PARBGG  TARGET-10-PARBGL  TARGET-10-PARBHI
                        TARGET-10-PARBIX  TARGET-10-PARBKG  TARGET-10-PARBKP  TARGET-10-PARBLL  TARGET-10-PARBLS
                        TARGET-10-PARBND  TARGET-10-PARBNY  TARGET-10-PARBPX  TARGET-10-PARBRK  TARGET-10-PARBRM
                        TARGET-10-PARBRV  TARGET-10-PARBRX  TARGET-10-PARBSP  TARGET-10-PARBSW  TARGET-10-PARBTA
                        TARGET-10-PARBVI  TARGET-10-PARBWN  TARGET-10-PARBXX  TARGET-10-PARBYS  TARGET-10-PARBYU
                        TARGET-10-PARBZT  TARGET-10-PARCAX  TARGET-10-PARCBE  TARGET-10-PARCBK  TARGET-10-PARCCM
                        TARGET-10-PARCDS  TARGET-10-PARCDV  TARGET-10-PARCDX  TARGET-10-PARCDZ  TARGET-10-PARCFM
                        TARGET-10-PARCGU  TARGET-10-PARCHB  TARGET-10-PARCHU  TARGET-10-PARCHY  TARGET-10-PARCKD
                        TARGET-10-PARCKJ  TARGET-10-PARCKV  TARGET-10-PARCLU  TARGET-10-PARCLW  TARGET-10-PARCMD
                        TARGET-10-PARCMG  TARGET-10-PARCSH  TARGET-10-PARCTN  TARGET-10-PARCUM  TARGET-10-PARCUW
                        TARGET-10-PARCVB  TARGET-10-PARCVT  TARGET-10-PARCWB  TARGET-10-PARCZY  TARGET-10-PARDAK
                        TARGET-10-PARDBN  TARGET-10-PARDBT  TARGET-10-PARDCJ  TARGET-10-PARDCR  TARGET-10-PARDCY
                        TARGET-10-PARDDM  TARGET-10-PARDDV  TARGET-10-PARDDW  TARGET-10-PARDEG  TARGET-10-PARDEJ
                        TARGET-10-PARDEP  TARGET-10-PARDEY  TARGET-10-PARDFB  TARGET-10-PARDFH  TARGET-10-PARDFI
                        TARGET-10-PARDFN  TARGET-10-PARDHK  TARGET-10-PARDHW  TARGET-10-PARDIN  TARGET-10-PARDKG
                        TARGET-10-PARDLJ  TARGET-10-PARDLP  TARGET-10-PARDLR  TARGET-10-PARDLZ  TARGET-10-PARDMI
                        TARGET-10-PARDNF  TARGET-10-PARDRI  TARGET-10-PARDRS  TARGET-10-PARDSN  TARGET-10-PARDSP
                        TARGET-10-PARDST  TARGET-10-PARDUM  TARGET-10-PARDVD  TARGET-10-PARDWE  TARGET-10-PARDWM
                        TARGET-10-PARDWN  TARGET-10-PARDXG  TARGET-10-PARDXI  TARGET-10-PARDXS  TARGET-10-PAREAA
                        TARGET-10-PAREAL  TARGET-10-PAREBA  TARGET-10-PAREBH  TARGET-10-PAREDS  TARGET-10-PAREEE
                        TARGET-10-PAREEX  TARGET-10-PAREGC  TARGET-10-PAREGE  TARGET-10-PAREHN  TARGET-10-PAREIE
                        TARGET-10-PAREIN  TARGET-10-PAREIV  TARGET-10-PAREJA  TARGET-10-PAREJZ  TARGET-10-PAREKG
                        TARGET-10-PAREKH  TARGET-10-PAREKM  TARGET-10-PARELH  TARGET-10-PARENT  TARGET-10-PARENU
                        TARGET-10-PARENW  TARGET-10-PAREPB  TARGET-10-PAREPF  TARGET-10-PARERM  TARGET-10-PARERS
                        TARGET-10-PARESP  TARGET-10-PAREST  TARGET-10-PARETC  TARGET-10-PARETH  TARGET-10-PARETV
                        TARGET-10-PAREUH  TARGET-10-PAREWE  TARGET-10-PAREWM  TARGET-10-PAREWZ  TARGET-10-PAREYJ
                        TARGET-10-PAREYW  TARGET-10-PAREZM  TARGET-10-PARFAP  TARGET-10-PARFDB  TARGET-10-PARFDG
                        TARGET-10-PARFDW  TARGET-10-PARFEH  TARGET-10-PARFFC  TARGET-10-PARFHH  TARGET-10-PARFIZ
                        TARGET-10-PARFJK  TARGET-10-PARFJM  TARGET-10-PARFKD  TARGET-10-PARFLV  TARGET-10-PARFSF
                        TARGET-10-PARFTR  TARGET-10-PARFWD  TARGET-10-PARGBK  TARGET-10-PARGBR  TARGET-10-PARGBT
                        TARGET-10-PARGFV  TARGET-10-PARGFX  TARGET-10-PARGGI  TARGET-10-PARGHW  TARGET-10-PARGJH
                        TARGET-10-PARGJY  TARGET-10-PARGKD  TARGET-10-PARGLE  TARGET-10-PARGLI  TARGET-10-PARGLW
                        TARGET-10-PARGML  TARGET-10-PARGMW  TARGET-10-PARGUZ  TARGET-10-PARGVZ  TARGET-10-PARGYV
                        TARGET-10-PARHAN  TARGET-10-PARHEA  TARGET-10-PARHFF  TARGET-10-PARHLM  TARGET-10-PARHMT
                        TARGET-10-PARHSD  TARGET-10-PARHUM  TARGET-10-PARIAD  TARGET-10-PARIBB  TARGET-10-PARIIA
                        TARGET-10-PARILG  TARGET-10-PARIPA  TARGET-10-PARJBB  TARGET-10-PARJBZ  TARGET-10-PARJJP
                        TARGET-10-PARJLA  TARGET-10-PARJLF  TARGET-10-PARJMY  TARGET-10-PARJNL  TARGET-10-PARJNR
                        TARGET-10-PARJRT  TARGET-10-PARJSR  TARGET-10-PARJWB  TARGET-10-PARJYV  TARGET-10-PARJZZ
                        TARGET-10-PARKBT  TARGET-10-PARKEN  TARGET-10-PARKEU  TARGET-10-PARKFN  TARGET-10-PARKFU
                        TARGET-10-PARKLL  TARGET-10-PARKZX  TARGET-10-PARLAF  TARGET-10-PARLBP  TARGET-10-PARLDF
                        TARGET-10-PARLEK  TARGET-10-PARLFI  TARGET-10-PARLHD  TARGET-10-PARLMI  TARGET-10-PARLPA
                        TARGET-10-PARLPB  TARGET-10-PARLSU  TARGET-10-PARLTU  TARGET-10-PARLTX  TARGET-10-PARLZG
                        TARGET-10-PARMEG  TARGET-10-PARMMA  TARGET-10-PARMSB  TARGET-10-PARMSP  TARGET-10-PARMWZ
                        TARGET-10-PARMXF  TARGET-10-PARMYP  TARGET-10-PARNAF  TARGET-10-PARNDB  TARGET-10-PARNDY
                        TARGET-10-PARNGI  TARGET-10-PARNIZ  TARGET-10-PARNLW  TARGET-10-PARNMF  TARGET-10-PARNSH
                        TARGET-10-PARNSW  TARGET-10-PARPCA  TARGET-10-PARPDP  TARGET-10-PARPFF  TARGET-10-PARPGJ
                        TARGET-10-PARPGL  TARGET-10-PARPGW  TARGET-10-PARPIF  TARGET-10-PARPNM  TARGET-10-PARPPV
                        TARGET-10-PARPRW  TARGET-10-PARPXV  TARGET-10-PARPYH  TARGET-10-PARPYS  TARGET-10-PARPZI
                        TARGET-10-PARPZJ  TARGET-10-PARPZR  TARGET-10-PARRAF  TARGET-10-PARRJV  TARGET-10-PARRKG
                        TARGET-10-PARRMU  TARGET-10-PARRPA  TARGET-10-PARRPK  TARGET-10-PARRSR  TARGET-10-PARRVI
                        TARGET-10-PARRVK  TARGET-10-PARRYW  TARGET-10-PARSGC  TARGET-10-PARSGM  TARGET-10-PARSHV
                        TARGET-10-PARSJH  TARGET-10-PARSKH  TARGET-10-PARSKV  TARGET-10-PARSKY  TARGET-10-PARSLL
                        TARGET-10-PARSRI  TARGET-10-PARSSV  TARGET-10-PARSTB  TARGET-10-PARSUV  TARGET-10-PARSZH
                        TARGET-10-PARTAK  TARGET-10-PARTAY  TARGET-10-PARTEF  TARGET-10-PARTGB  TARGET-10-PARTGW
                        TARGET-10-PARTID  TARGET-10-PARTIK  TARGET-10-PARTJJ  TARGET-10-PARTJL  TARGET-10-PARTKL
                        TARGET-10-PARTRW  TARGET-10-PARTSC  TARGET-10-PARTWH  TARGET-10-PARTYT  TARGET-10-PARTZE
                        TARGET-10-PARTZJ  TARGET-10-PARUAT  TARGET-10-PARUBK  TARGET-10-PARUBN  TARGET-10-PARUBU
                        TARGET-10-PARUBX  TARGET-10-PARUCI  TARGET-10-PARUCT  TARGET-10-PARUFL  TARGET-10-PARUGP
                        TARGET-10-PARUGV  TARGET-10-PARUIT  TARGET-10-PARUIW  TARGET-10-PARUKK  TARGET-10-PARUNW
                        TARGET-10-PARURK  TARGET-10-PARUYE  TARGET-10-PARUYH  TARGET-10-PARUYU  TARGET-10-PARVAK
                        TARGET-10-PARVBL  TARGET-10-PARVBS  TARGET-10-PARVBY  TARGET-10-PARVCG  TARGET-10-PARVWD
                        TARGET-10-PARWRJ  TARGET-10-PARWVN  TARGET-10-PARWXF  TARGET-10-PARXCD  TARGET-10-PARXMC
                        TARGET-10-PARYAJ  TARGET-10-PARYMD  TARGET-10-PARZYX  TARGET-10-PASCIU  TARGET-10-PASDYK
                        TARGET-10-PASDYM  TARGET-10-PASEVJ  TARGET-10-PASFGA  TARGET-10-PASFTL  TARGET-10-PASFXA
                        TARGET-10-PASGBD  TARGET-10-PASHUI  TARGET-10-PASIGB  TARGET-10-PASIIK  TARGET-10-PASILP
                        TARGET-10-PASIZE  TARGET-10-PASKAY  TARGET-10-PASKHT  TARGET-10-PASLCJ  TARGET-10-PASLMB
                        TARGET-10-PASLZM  TARGET-10-PASMGZ  TARGET-10-PASMVF  TARGET-10-PASNJI  TARGET-10-PASREU
                        TARGET-10-PASRSV  TARGET-10-PASRWZ  TARGET-10-PASRXC  TARGET-10-PASRYW  TARGET-10-PASSXJ
                        TARGET-10-PASTLM  TARGET-10-PASTSR  TARGET-10-PASTYT  TARGET-10-PASUBW  TARGET-10-PASUWG
                        TARGET-10-PASWUH  TARGET-10-PASXFY  TARGET-10-PASXZH  TARGET-10-PASYGM  TARGET-10-PATAAH
                        TARGET-10-PATCJJ  TARGET-10-PATCTI  TARGET-10-PATELK  TARGET-10-PATEVE  TARGET-10-PATISC
                        TARGET-10-PATRIC  TARGET-10-PATTEE  TARGET-10-PAUXZX  TARGET-10-SJMPAL017974
                    )],
                    'T-ALL' => [qw(
                        TARGET-10-CAAABC  TARGET-10-CAAABD  TARGET-10-CAAABF  TARGET-10-PARASZ  TARGET-10-PARAYM
                        TARGET-10-PARCVM  TARGET-10-PAREGZ  TARGET-10-PARFDL  TARGET-10-PARFIH  TARGET-10-PARFPJ
                        TARGET-10-PARFXJ  TARGET-10-PARGFL  TARGET-10-PARHBI  TARGET-10-PARHBT  TARGET-10-PARHES
                        TARGET-10-PARIKN  TARGET-10-PARIYD  TARGET-10-PARIZN  TARGET-10-PARJAY  TARGET-10-PARJNX
                        TARGET-10-PARJPL  TARGET-10-PARJXW  TARGET-10-PARKLK  TARGET-10-PARLJA  TARGET-10-PARLST
                        TARGET-10-PARMFF  TARGET-10-PARMIH  TARGET-10-PARMKK  TARGET-10-PARMKM  TARGET-10-PARMMV
                        TARGET-10-PARMRF  TARGET-10-PARMUC  TARGET-10-PARMWH  TARGET-10-PARNBN  TARGET-10-PARNEH
                        TARGET-10-PARNJB  TARGET-10-PARNMV  TARGET-10-PARNSP  TARGET-10-PARNXJ  TARGET-10-PARPET
                        TARGET-10-PARPHB  TARGET-10-PARPUL  TARGET-10-PARPYJ  TARGET-10-PARRKK  TARGET-10-PARSET
                        TARGET-10-PARSJG  TARGET-10-PARSNX  TARGET-10-PARTBP  TARGET-10-PARTLY  TARGET-10-PARTPW
                        TARGET-10-PARUEU  TARGET-10-PARUKW  TARGET-10-PARVEI  TARGET-10-PARVHY  TARGET-10-PARVMR
                        TARGET-10-PARWDM  TARGET-10-PARWID  TARGET-10-PARWLP  TARGET-10-PARWMF  TARGET-10-PARWNW
                        TARGET-10-PARXHT  TARGET-10-PARXLS  TARGET-10-PARXMV  TARGET-10-PARXVS  TARGET-10-PARYGI
                        TARGET-10-PASFHR  TARGET-10-PASFKA  TARGET-10-PASFLK  TARGET-10-PASGFH  TARGET-10-PASHDV
                        TARGET-10-PASHNK  TARGET-10-PASHUP  TARGET-10-PASHXL  TARGET-10-PASIIY  TARGET-10-PASILW
                        TARGET-10-PASINX  TARGET-10-PASJJR  TARGET-10-PASJLN  TARGET-10-PASJMK  TARGET-10-PASJYI
                        TARGET-10-PASKAD  TARGET-10-PASKCL  TARGET-10-PASKGG  TARGET-10-PASKIC  TARGET-10-PASKRN
                        TARGET-10-PASKSY  TARGET-10-PASKTG  TARGET-10-PASKXN  TARGET-10-PASLAB  TARGET-10-PASLBB
                        TARGET-10-PASMHF  TARGET-10-PASMIC  TARGET-10-PASMNV  TARGET-10-PASNEH  TARGET-10-PASNTZ
                        TARGET-10-PASPBU  TARGET-10-PASPDS  TARGET-10-PASPPN  TARGET-10-PASRCV  TARGET-10-PASRMM
                        TARGET-10-PASSEF  TARGET-10-PASSHC  TARGET-10-PASSPP  TARGET-10-PASSRP  TARGET-10-PASSSR
                        TARGET-10-PASSZA  TARGET-10-PASTDU  TARGET-10-PASTHE  TARGET-10-PASTLP  TARGET-10-PASTPT
                        TARGET-10-PASTXU  TARGET-10-PASUGC  TARGET-10-PASUIN  TARGET-10-PASUSV  TARGET-10-PASVIN
                        TARGET-10-PASVPZ  TARGET-10-PASWFN  TARGET-10-PASWNU  TARGET-10-PASWSR  TARGET-10-PASWXB
                        TARGET-10-PASWXZ  TARGET-10-PASWZJ  TARGET-10-PASXIL  TARGET-10-PASXLT  TARGET-10-PASXLZ
                        TARGET-10-PASXMF  TARGET-10-PASXSI  TARGET-10-PASXUC  TARGET-10-PASXUU  TARGET-10-PASYAJ
                        TARGET-10-PASYCN  TARGET-10-PASYHN  TARGET-10-PASYIS  TARGET-10-PASYSJ  TARGET-10-PASYWF
                        TARGET-10-PASZEW  TARGET-10-PASZIY  TARGET-10-PASZJW  TARGET-10-PATALJ  TARGET-10-PATAXS
                        TARGET-10-PATAYT  TARGET-10-PATBDJ  TARGET-10-PATBDK  TARGET-10-PATBGC  TARGET-10-PATBNT
                        TARGET-10-PATBRV  TARGET-10-PATBTX  TARGET-10-PATBYK  TARGET-10-PATCDM  TARGET-10-PATCDZ
                        TARGET-10-PATCKV  TARGET-10-PATCNI  TARGET-10-PATCUK  TARGET-10-PATCZN  TARGET-10-PATDBU
                        TARGET-10-PATDDZ  TARGET-10-PATDFE  TARGET-10-PATDGZ  TARGET-10-PATDKT  TARGET-10-PATDLG
                        TARGET-10-PATDMN  TARGET-10-PATDRC  TARGET-10-PATEAK  TARGET-10-PATEFF  TARGET-10-PATEHZ
                        TARGET-10-PATEIT  TARGET-10-PATEMI  TARGET-10-PATENL  TARGET-10-PATEVL  TARGET-10-PATEYS
                        TARGET-10-PATFJD  TARGET-10-PATFJP  TARGET-10-PATFRM  TARGET-10-PATFVG  TARGET-10-PATFWF
                        TARGET-10-PATFYZ  TARGET-10-PATGBY  TARGET-10-PATGKE  TARGET-10-PATGLV  TARGET-10-PATGMP
                        TARGET-10-PATGVX  TARGET-10-PATGWP  TARGET-10-PATGXS  TARGET-10-PATGYH  TARGET-10-PATGZA
                        TARGET-10-PATHBG  TARGET-10-PATHFE  TARGET-10-PATHGY  TARGET-10-PATHJF  TARGET-10-PATHRF
                        TARGET-10-PATHWV  TARGET-10-PATIBE  TARGET-10-PATIKN  TARGET-10-PATITB  TARGET-10-PATITY
                        TARGET-10-PATJBC  TARGET-10-PATJLT  TARGET-10-PATJZK  TARGET-10-PATKGP  TARGET-10-PATKVD
                        TARGET-10-PATKWU  TARGET-10-PATKYI  TARGET-10-PATLGU  TARGET-10-PATLHH  TARGET-10-PATLHS
                        TARGET-10-PATLMA  TARGET-10-PATLNS  TARGET-10-PATLNZ  TARGET-10-PATLPN  TARGET-10-PATLRZ
                        TARGET-10-PATMAF  TARGET-10-PATMRE  TARGET-10-PATMTV  TARGET-10-PATMVH  TARGET-10-PATMXN
                        TARGET-10-PATMYZ  TARGET-10-PATNAM  TARGET-10-PATNIA  TARGET-10-PATPDA  TARGET-10-PATPGE
                        TARGET-10-PATPWF  TARGET-10-PATRAB  TARGET-10-PATRGV  TARGET-10-PATRHL  TARGET-10-PATRNA
                        TARGET-10-PATRUN  TARGET-10-PATRXL  TARGET-10-PATSDS  TARGET-10-PATSIL  TARGET-10-PATSIY
                        TARGET-10-PATSLH  TARGET-10-PATTHR  TARGET-10-PATVDA  TARGET-10-PATWHB  TARGET-10-PATWIJ
                        TARGET-10-PATWJU  TARGET-10-PATWNL  TARGET-10-PATWXC  TARGET-10-PATWYL  TARGET-10-PATWYZ
                        TARGET-10-PATXAL  TARGET-10-PATXKW  TARGET-10-PATXNK  TARGET-10-PATXNR  TARGET-10-PATXSK
                        TARGET-10-PATYCH  TARGET-10-PATYJK  TARGET-10-PATYMP  TARGET-10-PATYWV  TARGET-10-PATZFF
                        TARGET-10-PATZSL  TARGET-10-PATZVD  TARGET-10-PATZWA  TARGET-10-PATZYC  TARGET-10-PATZYR
                        TARGET-10-PAUACG  TARGET-10-PAUAFN  TARGET-10-PAUAJA  TARGET-10-PAUAYB  TARGET-10-PAUAZV
                        TARGET-10-PAUBCB  TARGET-10-PAUBCT  TARGET-10-PAUBLL  TARGET-10-PAUBPY  TARGET-10-PAUBRD
                        TARGET-10-PAUBTC  TARGET-10-PAUBXP  TARGET-10-PAUCDC  TARGET-10-PAUCDY  
                    )],
                },
                'cases_by_substudy' => {
                    'Phase1' => [qw(
                        TARGET-10-DCC001  TARGET-10-DCC002  TARGET-10-PAIXPH  TARGET-10-PAIXSD  TARGET-10-PAKHZT
                        TARGET-10-PAKKCA  TARGET-10-PAKKXB  TARGET-10-PAKMJF  TARGET-10-PAKMVD  TARGET-10-PAKMZM
                        TARGET-10-PAKRSL  TARGET-10-PAKTAL  TARGET-10-PAKVKK  TARGET-10-PAKYEP  TARGET-10-PAKYKZ
                        TARGET-10-PALETF  TARGET-10-PALIBN  TARGET-10-PALIYC  TARGET-10-PALJCF  TARGET-10-PALJDL
                        TARGET-10-PALKMM  TARGET-10-PALKTY  TARGET-10-PALLSD  TARGET-10-PALNTB  TARGET-10-PALTWS
                        TARGET-10-PALUAH  TARGET-10-PALULW  TARGET-10-PALZVV  TARGET-10-PAMDKS  TARGET-10-PAMDRM
                        TARGET-10-PANEHF  
                    )],
                    'Phase2' => [qw(
                        TARGET-10-CAAABC  TARGET-10-CAAABD  TARGET-10-CAAABF  TARGET-10-PAKSWW  TARGET-10-PAMKZB
                        TARGET-10-PAMXHJ  TARGET-10-PAMXSP  TARGET-10-PANCVR  TARGET-10-PANDWE  TARGET-10-PANEBL
                        TARGET-10-PANEPX  TARGET-10-PANEUH  TARGET-10-PANFNZ  TARGET-10-PANGIF  TARGET-10-PANIEU
                        TARGET-10-PANJPG  TARGET-10-PANJWJ  TARGET-10-PANKAK  TARGET-10-PANKDT  TARGET-10-PANKGK
                        TARGET-10-PANKMB  TARGET-10-PANKRG  TARGET-10-PANLIC  TARGET-10-PANPJI  TARGET-10-PANPJW
                        TARGET-10-PANRAL  TARGET-10-PANRDC  TARGET-10-PANRWG  TARGET-10-PANRYM  TARGET-10-PANSBR
                        TARGET-10-PANSDA  TARGET-10-PANSFD  TARGET-10-PANSHK  TARGET-10-PANSIA  TARGET-10-PANSIZ
                        TARGET-10-PANSPW  TARGET-10-PANSTA  TARGET-10-PANSUL  TARGET-10-PANSXG  TARGET-10-PANSYA
                        TARGET-10-PANTBB  TARGET-10-PANTCR  TARGET-10-PANTLF  TARGET-10-PANTRY  TARGET-10-PANTSM
                        TARGET-10-PANTTB  TARGET-10-PANTTD  TARGET-10-PANTUZ  TARGET-10-PANTVC  TARGET-10-PANTWC
                        TARGET-10-PANTXA  TARGET-10-PANTYP  TARGET-10-PANTZE  TARGET-10-PANUHA  TARGET-10-PANUKF
                        TARGET-10-PANUKN  TARGET-10-PANURR  TARGET-10-PANURW  TARGET-10-PANUSL  TARGET-10-PANUSN
                        TARGET-10-PANUUF  TARGET-10-PANUXS  TARGET-10-PANUXU  TARGET-10-PANUYZ  TARGET-10-PANVAW
                        TARGET-10-PANVCM  TARGET-10-PANVDH  TARGET-10-PANVDV  TARGET-10-PANVFF  TARGET-10-PANVGZ
                        TARGET-10-PANVIB  TARGET-10-PANVIC  TARGET-10-PANVIX  TARGET-10-PANVJI  TARGET-10-PANVKF
                        TARGET-10-PANVKH  TARGET-10-PANVMT  TARGET-10-PANVTB  TARGET-10-PANVUD  TARGET-10-PANVUU
                        TARGET-10-PANVXF  TARGET-10-PANVYR  TARGET-10-PANWDL  TARGET-10-PANWDN  TARGET-10-PANWDS
                        TARGET-10-PANWEI  TARGET-10-PANWES  TARGET-10-PANWFB  TARGET-10-PANWFL  TARGET-10-PANWGG
                        TARGET-10-PANWHJ  TARGET-10-PANWHW  TARGET-10-PANWIM  TARGET-10-PANWJB  TARGET-10-PANWJH
                        TARGET-10-PANWJM  TARGET-10-PANWJR  TARGET-10-PANWJS  TARGET-10-PANWKM  TARGET-10-PANWKP
                        TARGET-10-PANWLH  TARGET-10-PANWSP  TARGET-10-PANWVW  TARGET-10-PANWWG  TARGET-10-PANWYH
                        TARGET-10-PANWYK  TARGET-10-PANWYM  TARGET-10-PANWZG  TARGET-10-PANXAM  TARGET-10-PANXCX
                        TARGET-10-PANXDB  TARGET-10-PANXDR  TARGET-10-PANXEE  TARGET-10-PANXGD  TARGET-10-PANXGM
                        TARGET-10-PANXLC  TARGET-10-PANXLP  TARGET-10-PANXLR  TARGET-10-PANXPE  TARGET-10-PANXSF
                        TARGET-10-PANXTP  TARGET-10-PANXXD  TARGET-10-PANXZK  TARGET-10-PANXZX  TARGET-10-PANYDL
                        TARGET-10-PANYEJ  TARGET-10-PANYGB  TARGET-10-PANYHB  TARGET-10-PANYJL  TARGET-10-PANYJV
                        TARGET-10-PANYXD  TARGET-10-PANYXR  TARGET-10-PANYYV  TARGET-10-PANYZE  TARGET-10-PANZBR
                        TARGET-10-PANZBY  TARGET-10-PANZCF  TARGET-10-PANZEG  TARGET-10-PANZFN  TARGET-10-PANZGN
                        TARGET-10-PANZPJ  TARGET-10-PANZPU  TARGET-10-PANZSE  TARGET-10-PANZUI  TARGET-10-PANZXC
                        TARGET-10-PANZXZ  TARGET-10-PANZYY  TARGET-10-PANZZI  TARGET-10-PAPACP  TARGET-10-PAPADT
                        TARGET-10-PAPAGB  TARGET-10-PAPAGF  TARGET-10-PAPAGK  TARGET-10-PAPAGS  TARGET-10-PAPAGV
                        TARGET-10-PAPAGW  TARGET-10-PAPAIZ  TARGET-10-PAPAKJ  TARGET-10-PAPAMA  TARGET-10-PAPAMH
                        TARGET-10-PAPAMS  TARGET-10-PAPANB  TARGET-10-PAPAPC  TARGET-10-PAPAPX  TARGET-10-PAPART
                        TARGET-10-PAPAVR  TARGET-10-PAPAXH  TARGET-10-PAPAZA  TARGET-10-PAPAZD  TARGET-10-PAPBAI
                        TARGET-10-PAPBAN  TARGET-10-PAPBCI  TARGET-10-PAPBCK  TARGET-10-PAPBES  TARGET-10-PAPBFN
                        TARGET-10-PAPBLU  TARGET-10-PAPBPC  TARGET-10-PAPBSE  TARGET-10-PAPBSY  TARGET-10-PAPBVD
                        TARGET-10-PAPBYM  TARGET-10-PAPBZK  TARGET-10-PAPBZW  TARGET-10-PAPCED  TARGET-10-PAPCJR
                        TARGET-10-PAPCNP  TARGET-10-PAPCPB  TARGET-10-PAPCRD  TARGET-10-PAPCRJ  TARGET-10-PAPCRU
                        TARGET-10-PAPCSZ  TARGET-10-PAPCUI  TARGET-10-PAPCUR  TARGET-10-PAPCVI  TARGET-10-PAPCVR
                        TARGET-10-PAPCVZ  TARGET-10-PAPCXR  TARGET-10-PAPDBX  TARGET-10-PAPDCS  TARGET-10-PAPDDA
                        TARGET-10-PAPDFS  TARGET-10-PAPDFU  TARGET-10-PAPDHA  TARGET-10-PAPDJM  TARGET-10-PAPDKD
                        TARGET-10-PAPDKJ  TARGET-10-PAPDKR  TARGET-10-PAPDLN  TARGET-10-PAPDMU  TARGET-10-PAPDNB
                        TARGET-10-PAPDRP  TARGET-10-PAPDSW  TARGET-10-PAPDUF  TARGET-10-PAPDUV  TARGET-10-PAPDUX
                        TARGET-10-PAPDVG  TARGET-10-PAPDWT  TARGET-10-PAPDYE  TARGET-10-PAPEAB  TARGET-10-PAPECF
                        TARGET-10-PAPEFH  TARGET-10-PAPEJA  TARGET-10-PAPEJL  TARGET-10-PAPEJM  TARGET-10-PAPEJN
                        TARGET-10-PAPEMC  TARGET-10-PAPEMZ  TARGET-10-PAPERM  TARGET-10-PAPERN  TARGET-10-PAPERU
                        TARGET-10-PAPERW  TARGET-10-PAPESB  TARGET-10-PAPESW  TARGET-10-PAPESY  TARGET-10-PAPESZ
                        TARGET-10-PAPETC  TARGET-10-PAPEWB  TARGET-10-PAPEZL  TARGET-10-PAPEZR  TARGET-10-PAPFAT
                        TARGET-10-PAPFBR  TARGET-10-PAPFBX  TARGET-10-PAPFFW  TARGET-10-PAPFHH  TARGET-10-PAPFHR
                        TARGET-10-PAPFHX  TARGET-10-PAPFIX  TARGET-10-PAPFKA  TARGET-10-PAPFNV  TARGET-10-PAPFPZ
                        TARGET-10-PAPFTJ  TARGET-10-PAPFUF  TARGET-10-PAPFWH  TARGET-10-PAPFXN  TARGET-10-PAPFZF
                        TARGET-10-PAPFZL  TARGET-10-PAPFZX  TARGET-10-PAPGEE  TARGET-10-PAPGFD  TARGET-10-PAPGFP
                        TARGET-10-PAPGGT  TARGET-10-PAPGKP  TARGET-10-PAPGLD  TARGET-10-PAPGLS  TARGET-10-PAPGMT
                        TARGET-10-PAPGMV  TARGET-10-PAPGNC  TARGET-10-PAPGWN  TARGET-10-PAPGYC  TARGET-10-PAPHAM
                        TARGET-10-PAPHBW  TARGET-10-PAPHCA  TARGET-10-PAPHCJ  TARGET-10-PAPHDN  TARGET-10-PAPHDX
                        TARGET-10-PAPHED  TARGET-10-PAPHEK  TARGET-10-PAPHGD  TARGET-10-PAPHHP  TARGET-10-PAPHIG
                        TARGET-10-PAPHJF  TARGET-10-PAPHLH  TARGET-10-PAPHMH  TARGET-10-PAPHNM  TARGET-10-PAPHNR
                        TARGET-10-PAPHRT  TARGET-10-PAPHRV  TARGET-10-PAPHWE  TARGET-10-PAPHWH  TARGET-10-PAPHXJ
                        TARGET-10-PAPHYM  TARGET-10-PAPHYV  TARGET-10-PAPHZT  TARGET-10-PAPICC  TARGET-10-PAPIDY
                        TARGET-10-PAPIEW  TARGET-10-PAPIGD  TARGET-10-PAPIGV  TARGET-10-PAPIGX  TARGET-10-PAPIHH
                        TARGET-10-PAPIHT  TARGET-10-PAPIHU  TARGET-10-PAPIIB  TARGET-10-PAPIIX  TARGET-10-PAPIJB
                        TARGET-10-PAPIJD  TARGET-10-PAPIJM  TARGET-10-PAPIKG  TARGET-10-PAPILF  TARGET-10-PAPILG
                        TARGET-10-PAPIPG  TARGET-10-PAPIRZ  TARGET-10-PAPISG  TARGET-10-PAPJHB  TARGET-10-PAPJHR
                        TARGET-10-PAPJIB  TARGET-10-PAPJRR  TARGET-10-PAPJXI  TARGET-10-PAPKNC  TARGET-10-PAPLDL
                        TARGET-10-PAPLDM  TARGET-10-PAPLTZ  TARGET-10-PAPLUG  TARGET-10-PAPMFI  TARGET-10-PAPMVB
                        TARGET-10-PAPMYD  TARGET-10-PAPNFY  TARGET-10-PAPNMY  TARGET-10-PAPNNX  TARGET-10-PAPPGN
                        TARGET-10-PAPRCS  TARGET-10-PAPRFE  TARGET-10-PAPSPG  TARGET-10-PAPSPN  TARGET-10-PAPTHJ
                        TARGET-10-PAPTLM  TARGET-10-PAPVNW  TARGET-10-PAPVTA  TARGET-10-PAPZNK  TARGET-10-PAPZPJ
                        TARGET-10-PAPZPZ  TARGET-10-PAPZRA  TARGET-10-PAPZRB  TARGET-10-PAPZST  TARGET-10-PAPZTD
                        TARGET-10-PAPZTL  TARGET-10-PAPZTS  TARGET-10-PAPZUE  TARGET-10-PAPZUW  TARGET-10-PAPZVI
                        TARGET-10-PAPZWP  TARGET-10-PAPZXI  TARGET-10-PAPZZJ  TARGET-10-PARABL  TARGET-10-PARABU
                        TARGET-10-PARACA  TARGET-10-PARACE  TARGET-10-PARAFH  TARGET-10-PARAFI  TARGET-10-PARAGW
                        TARGET-10-PARAJY  TARGET-10-PARAKF  TARGET-10-PARANN  TARGET-10-PARAPT  TARGET-10-PARARJ
                        TARGET-10-PARASC  TARGET-10-PARASN  TARGET-10-PARASZ  TARGET-10-PARATY  TARGET-10-PARAUE
                        TARGET-10-PARAXH  TARGET-10-PARAYM  TARGET-10-PARAZN  TARGET-10-PARBBV  TARGET-10-PARBCW
                        TARGET-10-PARBDP  TARGET-10-PARBGG  TARGET-10-PARBHI  TARGET-10-PARBIX  TARGET-10-PARBKG
                        TARGET-10-PARBKP  TARGET-10-PARBLL  TARGET-10-PARBLS  TARGET-10-PARBND  TARGET-10-PARBNY
                        TARGET-10-PARBPX  TARGET-10-PARBRK  TARGET-10-PARBRM  TARGET-10-PARBRV  TARGET-10-PARBRX
                        TARGET-10-PARBSP  TARGET-10-PARBSW  TARGET-10-PARBTA  TARGET-10-PARBVI  TARGET-10-PARBWN
                        TARGET-10-PARBXX  TARGET-10-PARBYS  TARGET-10-PARBYU  TARGET-10-PARBZT  TARGET-10-PARCAX
                        TARGET-10-PARCBE  TARGET-10-PARCBK  TARGET-10-PARCCM  TARGET-10-PARCDS  TARGET-10-PARCDV
                        TARGET-10-PARCDX  TARGET-10-PARCDZ  TARGET-10-PARCFM  TARGET-10-PARCGU  TARGET-10-PARCHB
                        TARGET-10-PARCHU  TARGET-10-PARCHY  TARGET-10-PARCKD  TARGET-10-PARCKJ  TARGET-10-PARCKV
                        TARGET-10-PARCLU  TARGET-10-PARCLW  TARGET-10-PARCMD  TARGET-10-PARCMG  TARGET-10-PARCSH
                        TARGET-10-PARCTN  TARGET-10-PARCUM  TARGET-10-PARCUW  TARGET-10-PARCVB  TARGET-10-PARCVM
                        TARGET-10-PARCVT  TARGET-10-PARCWB  TARGET-10-PARCZY  TARGET-10-PARDAK  TARGET-10-PARDBN
                        TARGET-10-PARDBT  TARGET-10-PARDCJ  TARGET-10-PARDCR  TARGET-10-PARDCY  TARGET-10-PARDDM
                        TARGET-10-PARDDV  TARGET-10-PARDDW  TARGET-10-PARDEG  TARGET-10-PARDEJ  TARGET-10-PARDEP
                        TARGET-10-PARDEY  TARGET-10-PARDFB  TARGET-10-PARDFH  TARGET-10-PARDFI  TARGET-10-PARDFN
                        TARGET-10-PARDHK  TARGET-10-PARDHW  TARGET-10-PARDIN  TARGET-10-PARDKG  TARGET-10-PARDLJ
                        TARGET-10-PARDLP  TARGET-10-PARDLR  TARGET-10-PARDLZ  TARGET-10-PARDMI  TARGET-10-PARDNF
                        TARGET-10-PARDRI  TARGET-10-PARDRS  TARGET-10-PARDSN  TARGET-10-PARDSP  TARGET-10-PARDST
                        TARGET-10-PARDUM  TARGET-10-PARDVD  TARGET-10-PARDWE  TARGET-10-PARDWM  TARGET-10-PARDXG
                        TARGET-10-PARDXI  TARGET-10-PARDXS  TARGET-10-PAREAA  TARGET-10-PAREAL  TARGET-10-PAREBA
                        TARGET-10-PAREBH  TARGET-10-PAREDS  TARGET-10-PAREEE  TARGET-10-PAREEX  TARGET-10-PAREGC
                        TARGET-10-PAREGE  TARGET-10-PAREGZ  TARGET-10-PAREHN  TARGET-10-PAREIE  TARGET-10-PAREIN
                        TARGET-10-PAREIV  TARGET-10-PAREJA  TARGET-10-PAREJZ  TARGET-10-PAREKG  TARGET-10-PAREKH
                        TARGET-10-PAREKM  TARGET-10-PARELH  TARGET-10-PARENT  TARGET-10-PARENU  TARGET-10-PARENW
                        TARGET-10-PAREPB  TARGET-10-PAREPF  TARGET-10-PARERM  TARGET-10-PARERS  TARGET-10-PARESP
                        TARGET-10-PAREST  TARGET-10-PARETC  TARGET-10-PARETH  TARGET-10-PARETV  TARGET-10-PAREUH
                        TARGET-10-PAREWE  TARGET-10-PAREWM  TARGET-10-PAREWZ  TARGET-10-PAREYJ  TARGET-10-PAREYW
                        TARGET-10-PAREZM  TARGET-10-PARFAP  TARGET-10-PARFDB  TARGET-10-PARFDG  TARGET-10-PARFDL
                        TARGET-10-PARFDW  TARGET-10-PARFEH  TARGET-10-PARFFC  TARGET-10-PARFHH  TARGET-10-PARFIH
                        TARGET-10-PARFIZ  TARGET-10-PARFJK  TARGET-10-PARFJM  TARGET-10-PARFKD  TARGET-10-PARFLV
                        TARGET-10-PARFPJ  TARGET-10-PARFSF  TARGET-10-PARFTR  TARGET-10-PARFXJ  TARGET-10-PARGBK
                        TARGET-10-PARGBR  TARGET-10-PARGBT  TARGET-10-PARGFL  TARGET-10-PARGFV  TARGET-10-PARGFX
                        TARGET-10-PARGGI  TARGET-10-PARGHW  TARGET-10-PARGJH  TARGET-10-PARGJY  TARGET-10-PARGKD
                        TARGET-10-PARGLE  TARGET-10-PARGLI  TARGET-10-PARGLW  TARGET-10-PARGML  TARGET-10-PARGMW
                        TARGET-10-PARGUZ  TARGET-10-PARGVZ  TARGET-10-PARGYV  TARGET-10-PARHAN  TARGET-10-PARHBI
                        TARGET-10-PARHBT  TARGET-10-PARHEA  TARGET-10-PARHES  TARGET-10-PARHFF  TARGET-10-PARHLM
                        TARGET-10-PARHMT  TARGET-10-PARHSD  TARGET-10-PARHUM  TARGET-10-PARIAD  TARGET-10-PARIBB
                        TARGET-10-PARIIA  TARGET-10-PARIKN  TARGET-10-PARILG  TARGET-10-PARIPA  TARGET-10-PARIYD
                        TARGET-10-PARIZN  TARGET-10-PARJAY  TARGET-10-PARJBB  TARGET-10-PARJBZ  TARGET-10-PARJJP
                        TARGET-10-PARJLF  TARGET-10-PARJMY  TARGET-10-PARJNL  TARGET-10-PARJNR  TARGET-10-PARJNX
                        TARGET-10-PARJPL  TARGET-10-PARJRT  TARGET-10-PARJSR  TARGET-10-PARJWB  TARGET-10-PARJXW
                        TARGET-10-PARJYV  TARGET-10-PARJZZ  TARGET-10-PARKBT  TARGET-10-PARKEN  TARGET-10-PARKEU
                        TARGET-10-PARKFN  TARGET-10-PARKFU  TARGET-10-PARKLK  TARGET-10-PARKLL  TARGET-10-PARKZX
                        TARGET-10-PARLAF  TARGET-10-PARLBP  TARGET-10-PARLDF  TARGET-10-PARLEK  TARGET-10-PARLFI
                        TARGET-10-PARLHD  TARGET-10-PARLJA  TARGET-10-PARLMI  TARGET-10-PARLPA  TARGET-10-PARLPB
                        TARGET-10-PARLST  TARGET-10-PARLSU  TARGET-10-PARLTU  TARGET-10-PARLTX  TARGET-10-PARLZG
                        TARGET-10-PARMEG  TARGET-10-PARMFF  TARGET-10-PARMIH  TARGET-10-PARMKK  TARGET-10-PARMKM
                        TARGET-10-PARMMA  TARGET-10-PARMMV  TARGET-10-PARMRF  TARGET-10-PARMSB  TARGET-10-PARMSP
                        TARGET-10-PARMUC  TARGET-10-PARMWH  TARGET-10-PARMWZ  TARGET-10-PARMXF  TARGET-10-PARMYP
                        TARGET-10-PARNAF  TARGET-10-PARNBN  TARGET-10-PARNDB  TARGET-10-PARNDY  TARGET-10-PARNEH
                        TARGET-10-PARNGI  TARGET-10-PARNIZ  TARGET-10-PARNJB  TARGET-10-PARNLW  TARGET-10-PARNMF
                        TARGET-10-PARNMV  TARGET-10-PARNSH  TARGET-10-PARNSP  TARGET-10-PARNSW  TARGET-10-PARNXJ
                        TARGET-10-PARPCA  TARGET-10-PARPDP  TARGET-10-PARPET  TARGET-10-PARPFF  TARGET-10-PARPGJ
                        TARGET-10-PARPGL  TARGET-10-PARPGW  TARGET-10-PARPHB  TARGET-10-PARPIF  TARGET-10-PARPNM
                        TARGET-10-PARPPV  TARGET-10-PARPRW  TARGET-10-PARPUL  TARGET-10-PARPXV  TARGET-10-PARPYH
                        TARGET-10-PARPYJ  TARGET-10-PARPYS  TARGET-10-PARPZI  TARGET-10-PARPZJ  TARGET-10-PARPZR
                        TARGET-10-PARRAF  TARGET-10-PARRJV  TARGET-10-PARRKG  TARGET-10-PARRKK  TARGET-10-PARRMU
                        TARGET-10-PARRPA  TARGET-10-PARRPK  TARGET-10-PARRSR  TARGET-10-PARRVI  TARGET-10-PARRVK
                        TARGET-10-PARRYW  TARGET-10-PARSET  TARGET-10-PARSGC  TARGET-10-PARSGM  TARGET-10-PARSHV
                        TARGET-10-PARSJG  TARGET-10-PARSJH  TARGET-10-PARSKH  TARGET-10-PARSKV  TARGET-10-PARSKY
                        TARGET-10-PARSNX  TARGET-10-PARSRI  TARGET-10-PARSSV  TARGET-10-PARSTB  TARGET-10-PARSUV
                        TARGET-10-PARSZH  TARGET-10-PARTAK  TARGET-10-PARTAY  TARGET-10-PARTBP  TARGET-10-PARTEF
                        TARGET-10-PARTGB  TARGET-10-PARTGW  TARGET-10-PARTID  TARGET-10-PARTIK  TARGET-10-PARTJJ
                        TARGET-10-PARTJL  TARGET-10-PARTKL  TARGET-10-PARTLY  TARGET-10-PARTPW  TARGET-10-PARTRW
                        TARGET-10-PARTSC  TARGET-10-PARTWH  TARGET-10-PARTYT  TARGET-10-PARTZE  TARGET-10-PARTZJ
                        TARGET-10-PARUBK  TARGET-10-PARUBN  TARGET-10-PARUBU  TARGET-10-PARUBX  TARGET-10-PARUCI
                        TARGET-10-PARUCT  TARGET-10-PARUEU  TARGET-10-PARUGP  TARGET-10-PARUGV  TARGET-10-PARUIT
                        TARGET-10-PARUIW  TARGET-10-PARUKK  TARGET-10-PARUKW  TARGET-10-PARURK  TARGET-10-PARUYE
                        TARGET-10-PARUYH  TARGET-10-PARUYU  TARGET-10-PARVAK  TARGET-10-PARVBL  TARGET-10-PARVBS
                        TARGET-10-PARVBY  TARGET-10-PARVCG  TARGET-10-PARVEI  TARGET-10-PARVHY  TARGET-10-PARVMR
                        TARGET-10-PARVWD  TARGET-10-PARWDM  TARGET-10-PARWID  TARGET-10-PARWLP  TARGET-10-PARWMF
                        TARGET-10-PARWNW  TARGET-10-PARWVN  TARGET-10-PARXHT  TARGET-10-PARXLS  TARGET-10-PARXMC
                        TARGET-10-PARXMV  TARGET-10-PARXVS  TARGET-10-PARYGI  TARGET-10-PARYMD  TARGET-10-PASCIU
                        TARGET-10-PASDYK  TARGET-10-PASEVJ  TARGET-10-PASFGA  TARGET-10-PASFHR  TARGET-10-PASFKA
                        TARGET-10-PASFLK  TARGET-10-PASFTL  TARGET-10-PASFXA  TARGET-10-PASGBD  TARGET-10-PASGFH
                        TARGET-10-PASHDV  TARGET-10-PASHNK  TARGET-10-PASHUI  TARGET-10-PASHUP  TARGET-10-PASHXL
                        TARGET-10-PASIIK  TARGET-10-PASIIY  TARGET-10-PASILW  TARGET-10-PASINX  TARGET-10-PASJJR
                        TARGET-10-PASJLN  TARGET-10-PASJMK  TARGET-10-PASJYI  TARGET-10-PASKAD  TARGET-10-PASKAY
                        TARGET-10-PASKCL  TARGET-10-PASKGG  TARGET-10-PASKHT  TARGET-10-PASKIC  TARGET-10-PASKRN
                        TARGET-10-PASKSY  TARGET-10-PASKTG  TARGET-10-PASKXN  TARGET-10-PASLAB  TARGET-10-PASLBB
                        TARGET-10-PASLZM  TARGET-10-PASMHF  TARGET-10-PASMIC  TARGET-10-PASMNV  TARGET-10-PASMVF
                        TARGET-10-PASNEH  TARGET-10-PASNTZ  TARGET-10-PASPBU  TARGET-10-PASPDS  TARGET-10-PASPPN
                        TARGET-10-PASRCV  TARGET-10-PASRMM  TARGET-10-PASRXC  TARGET-10-PASSEF  TARGET-10-PASSHC
                        TARGET-10-PASSPP  TARGET-10-PASSRP  TARGET-10-PASSSR  TARGET-10-PASSXJ  TARGET-10-PASSZA
                        TARGET-10-PASTDU  TARGET-10-PASTHE  TARGET-10-PASTLP  TARGET-10-PASTPT  TARGET-10-PASTXU
                        TARGET-10-PASUBW  TARGET-10-PASUGC  TARGET-10-PASUIN  TARGET-10-PASUSV  TARGET-10-PASVIN
                        TARGET-10-PASVPZ  TARGET-10-PASWFN  TARGET-10-PASWNU  TARGET-10-PASWSR  TARGET-10-PASWUH
                        TARGET-10-PASWXB  TARGET-10-PASWXZ  TARGET-10-PASWZJ  TARGET-10-PASXIL  TARGET-10-PASXLT
                        TARGET-10-PASXLZ  TARGET-10-PASXMF  TARGET-10-PASXSI  TARGET-10-PASXUC  TARGET-10-PASXUU
                        TARGET-10-PASYAJ  TARGET-10-PASYCN  TARGET-10-PASYGM  TARGET-10-PASYHN  TARGET-10-PASYIS
                        TARGET-10-PASYSJ  TARGET-10-PASYWF  TARGET-10-PASZEW  TARGET-10-PASZIY  TARGET-10-PASZJW
                        TARGET-10-PATALJ  TARGET-10-PATAXS  TARGET-10-PATAYT  TARGET-10-PATBDJ  TARGET-10-PATBDK
                        TARGET-10-PATBGC  TARGET-10-PATBNT  TARGET-10-PATBRV  TARGET-10-PATBTX  TARGET-10-PATBYK
                        TARGET-10-PATCDM  TARGET-10-PATCDZ  TARGET-10-PATCKV  TARGET-10-PATCNI  TARGET-10-PATCTI
                        TARGET-10-PATCUK  TARGET-10-PATCZN  TARGET-10-PATDBU  TARGET-10-PATDDZ  TARGET-10-PATDFE
                        TARGET-10-PATDGZ  TARGET-10-PATDKT  TARGET-10-PATDLG  TARGET-10-PATDMN  TARGET-10-PATDRC
                        TARGET-10-PATEAK  TARGET-10-PATEFF  TARGET-10-PATEHZ  TARGET-10-PATEIT  TARGET-10-PATEMI
                        TARGET-10-PATENL  TARGET-10-PATEVL  TARGET-10-PATEYS  TARGET-10-PATFJD  TARGET-10-PATFJP
                        TARGET-10-PATFRM  TARGET-10-PATFVG  TARGET-10-PATFWF  TARGET-10-PATFYZ  TARGET-10-PATGBY
                        TARGET-10-PATGKE  TARGET-10-PATGLV  TARGET-10-PATGMP  TARGET-10-PATGVX  TARGET-10-PATGWP
                        TARGET-10-PATGXS  TARGET-10-PATGYH  TARGET-10-PATGZA  TARGET-10-PATHBG  TARGET-10-PATHFE
                        TARGET-10-PATHGY  TARGET-10-PATHJF  TARGET-10-PATHRF  TARGET-10-PATHWV  TARGET-10-PATIBE
                        TARGET-10-PATIKN  TARGET-10-PATISC  TARGET-10-PATITB  TARGET-10-PATITY  TARGET-10-PATJBC
                        TARGET-10-PATJLT  TARGET-10-PATJZK  TARGET-10-PATKGP  TARGET-10-PATKVD  TARGET-10-PATKWU
                        TARGET-10-PATKYI  TARGET-10-PATLGU  TARGET-10-PATLHH  TARGET-10-PATLHS  TARGET-10-PATLMA
                        TARGET-10-PATLNS  TARGET-10-PATLNZ  TARGET-10-PATLPN  TARGET-10-PATLRZ  TARGET-10-PATMAF
                        TARGET-10-PATMRE  TARGET-10-PATMTV  TARGET-10-PATMVH  TARGET-10-PATMXN  TARGET-10-PATMYZ
                        TARGET-10-PATNAM  TARGET-10-PATNIA  TARGET-10-PATPDA  TARGET-10-PATPGE  TARGET-10-PATPWF
                        TARGET-10-PATRAB  TARGET-10-PATRGV  TARGET-10-PATRHL  TARGET-10-PATRIC  TARGET-10-PATRNA
                        TARGET-10-PATRUN  TARGET-10-PATRXL  TARGET-10-PATSDS  TARGET-10-PATSIL  TARGET-10-PATSIY
                        TARGET-10-PATSLH  TARGET-10-PATTEE  TARGET-10-PATTHR  TARGET-10-PATVDA  TARGET-10-PATWHB
                        TARGET-10-PATWIJ  TARGET-10-PATWJU  TARGET-10-PATWNL  TARGET-10-PATWXC  TARGET-10-PATWYL
                        TARGET-10-PATWYZ  TARGET-10-PATXAL  TARGET-10-PATXKW  TARGET-10-PATXNK  TARGET-10-PATXNR
                        TARGET-10-PATXSK  TARGET-10-PATYCH  TARGET-10-PATYJK  TARGET-10-PATYMP  TARGET-10-PATYWV
                        TARGET-10-PATZFF  TARGET-10-PATZSL  TARGET-10-PATZVD  TARGET-10-PATZWA  TARGET-10-PATZYC
                        TARGET-10-PATZYR  TARGET-10-PAUACG  TARGET-10-PAUAFN  TARGET-10-PAUAJA  TARGET-10-PAUAYB
                        TARGET-10-PAUAZV  TARGET-10-PAUBCB  TARGET-10-PAUBCT  TARGET-10-PAUBLL  TARGET-10-PAUBPY
                        TARGET-10-PAUBRD  TARGET-10-PAUBTC  TARGET-10-PAUBXP  TARGET-10-PAUCDC  TARGET-10-PAUCDY
                        TARGET-10-PAUXZX  
                    )],
                    'Phase3' => [qw(
                        TARGET-10-PANATY        TARGET-10-PANDBX        TARGET-10-PANLGK        TARGET-10-PANSBK
                        TARGET-10-PANTTZ        TARGET-10-PANWEZ        TARGET-10-PANWYH        TARGET-10-PAPAXK
                        TARGET-10-PAPHPX        TARGET-10-PAPHYN        TARGET-10-PAPIYG        TARGET-10-PAPKNJ
                        TARGET-10-PAPRMM        TARGET-10-PAPTAT        TARGET-10-PARAPE        TARGET-10-PARBGL
                        TARGET-10-PARDWN        TARGET-10-PARFWD        TARGET-10-PARJLA        TARGET-10-PARSLL
                        TARGET-10-PARUAT        TARGET-10-PARUFL        TARGET-10-PARUNW        TARGET-10-PARUYU
                        TARGET-10-PARWRJ        TARGET-10-PARWXF        TARGET-10-PARXCD        TARGET-10-PARYAJ
                        TARGET-10-PARZYX        TARGET-10-PASDYM        TARGET-10-PASIGB        TARGET-10-PASILP
                        TARGET-10-PASIZE        TARGET-10-PASLCJ        TARGET-10-PASLMB        TARGET-10-PASMGZ
                        TARGET-10-PASNJI        TARGET-10-PASREU        TARGET-10-PASRSV        TARGET-10-PASRWZ
                        TARGET-10-PASRYW        TARGET-10-PASTLM        TARGET-10-PASTSR        TARGET-10-PASTYT
                        TARGET-10-PASUWG        TARGET-10-PASXFY        TARGET-10-PASXZH        TARGET-10-PATAAH
                        TARGET-10-PATCJJ        TARGET-10-PATELK        TARGET-10-PATEVE        TARGET-10-SJMPAL017974
                        TARGET-15-PAREAT        TARGET-15-PARUIF        TARGET-15-PARWPU        TARGET-15-PASZVW
                        TARGET-15-PAUFIB        TARGET-15-PAVFTF        TARGET-15-SJMPAL011914  TARGET-15-SJMPAL012419
                        TARGET-15-SJMPAL012421  TARGET-15-SJMPAL012426
                        TARGET-15-SJMPAL012427  TARGET-15-SJMPAL016341  TARGET-15-SJMPAL016342  TARGET-15-SJMPAL016849
                        TARGET-15-SJMPAL016851  TARGET-15-SJMPAL016852  TARGET-15-SJMPAL016854  TARGET-15-SJMPAL016855
                        TARGET-15-SJMPAL017975  TARGET-15-SJMPAL017976  TARGET-15-SJMPAL019076  TARGET-15-SJMPAL040025
                        TARGET-15-SJMPAL040028  TARGET-15-SJMPAL040032  TARGET-15-SJMPAL040036  TARGET-15-SJMPAL040037
                        TARGET-15-SJMPAL040038  TARGET-15-SJMPAL040039  TARGET-15-SJMPAL040459  TARGET-15-SJMPAL041117
                        TARGET-15-SJMPAL041119  TARGET-15-SJMPAL041120  TARGET-15-SJMPAL042787  TARGET-15-SJMPAL042791
                        TARGET-15-SJMPAL042793  TARGET-15-SJMPAL042794  TARGET-15-SJMPAL042798  TARGET-15-SJMPAL042799
                        TARGET-15-SJMPAL042801  TARGET-15-SJMPAL042940  TARGET-15-SJMPAL042941  TARGET-15-SJMPAL042942
                        TARGET-15-SJMPAL042946  TARGET-15-SJMPAL043505  TARGET-15-SJMPAL043506  TARGET-15-SJMPAL043507
                        TARGET-15-SJMPAL043508  TARGET-15-SJMPAL043511  TARGET-15-SJMPAL043512  TARGET-15-SJMPAL043513
                        TARGET-15-SJMPAL043767  TARGET-15-SJMPAL043768  TARGET-15-SJMPAL043769  TARGET-15-SJMPAL043770
                        TARGET-15-SJMPAL043771  TARGET-15-SJMPAL043772  TARGET-15-SJMPAL043773  TARGET-15-SJMPAL043774
                        TARGET-15-SJMPAL043775  
                    )],
                },
            },
            'AML' => {
                'dbGaP_study_ids' => [qw(
                    phs000465
                )],
                'idf' => {
                    'contacts' => [
                        {
                            'last_name' => 'Meshinchi',
                            'first_name' => 'Soheil',
                            'email' => 'smeshinc@fredhutch.org',
                            'phone' => '+1 206 667 4077',
                            'fax' => '+1 206 667 4310',
                            'address' => '1100 Fairview Avenue North, D5-380, POB 19024, Seattle, WA  98109',
                            'affiliation' => 'Fred Hutchinson Cancer Research Center',
                            'roles' => [
                                'investigator',
                            ],
                        },
                        {
                            'last_name' => 'Arceci',
                            'first_name' => 'Robert',
                            'mid_initials' => 'J',
                            'email' => 'rarceci@phoenixchildrens.com',
                            'phone' => '+1 602 827 2508',
                            'fax' => '+1 602 271 0264',
                            'address' => '445 N. 5th St, Tgen Building Room 322, Phoenix, AZ 85004',
                            'affiliation' => 'Phoenix Children\'s Hospital',
                            'roles' => [
                                'investigator',
                            ],
                        },
                    ],
                },
                'cases_by_cohort' => {
                    'Discovery' => [qw(
                        TARGET-20-PABGKN  TARGET-20-PABHET  TARGET-20-PABHKY  TARGET-20-PABLDZ  TARGET-20-PACDZR
                        TARGET-20-PACEGD  TARGET-20-PADDXZ  TARGET-20-PADYIR  TARGET-20-PADZCG  TARGET-20-PADZKD
                        TARGET-20-PADZYC  TARGET-20-PAEABM  TARGET-20-PAEAFC  TARGET-20-PAEAKL  TARGET-20-PAECBZ
                        TARGET-20-PAECCE  TARGET-20-PAECRF  TARGET-20-PAEDKB  TARGET-20-PAEENN  TARGET-20-PAEERJ
                        TARGET-20-PAEEYP  TARGET-20-PAEFGR  TARGET-20-PAEFGT  TARGET-20-PAEFHC  TARGET-20-PAEGNK
                        TARGET-20-PAEGRE  TARGET-20-PAEGRI  TARGET-20-PAEIKD  TARGET-20-PAEJBT  TARGET-20-PAERAH
                        TARGET-20-PAERXF  TARGET-20-PAESVN  TARGET-20-PAKERZ  TARGET-20-PAKGXN  TARGET-20-PAKHBF
                        TARGET-20-PAKHLK  TARGET-20-PAKHZW  TARGET-20-PAKIWK  TARGET-20-PAKIYW  TARGET-20-PAKKBK
                        TARGET-20-PAKKIM  TARGET-20-PAKLPD  TARGET-20-PAKRUP  TARGET-20-PAKRZG  TARGET-20-PAKSMZ
                        TARGET-20-PAKTCX  TARGET-20-PAKVGI  TARGET-20-PAKVYM  TARGET-20-PAKXJR  TARGET-20-PAKXVC
                        TARGET-20-PALBYP  TARGET-20-PALFVW  TARGET-20-PALGKX  TARGET-20-PALHVV  TARGET-20-PALNAT
                        TARGET-20-PALVKV  TARGET-20-PAMVKZ  TARGET-20-PAMVVP  TARGET-20-PAMYAS  TARGET-20-PAMYGX
                        TARGET-20-PAMYJX  TARGET-20-PAMYVU  TARGET-20-PAMYWW  TARGET-20-PANAEV  TARGET-20-PANASY
                        TARGET-20-PANBWF  TARGET-20-PANBYS  TARGET-20-PANBZH  TARGET-20-PANCSC  TARGET-20-PANDDC
                        TARGET-20-PANDER  TARGET-20-PANDIX  TARGET-20-PANFMG  TARGET-20-PANGCM  TARGET-20-PANGDN
                        TARGET-20-PANGFV  TARGET-20-PANGJY  TARGET-20-PANGTF  TARGET-20-PANHWD  TARGET-20-PANHYK
                        TARGET-20-PANIGD  TARGET-20-PANILV  TARGET-20-PANINI  TARGET-20-PANJFJ  TARGET-20-PANJGR
                        TARGET-20-PANJIM  TARGET-20-PANJTK  TARGET-20-PANJVI  TARGET-20-PANKBX  TARGET-20-PANKCE
                        TARGET-20-PANKEF  TARGET-20-PANKFG  TARGET-20-PANKFZ  TARGET-20-PANKKE  TARGET-20-PANKNB
                        TARGET-20-PANLIR  TARGET-20-PANLIZ  TARGET-20-PANLJK  TARGET-20-PANLJN  TARGET-20-PANLKB
                        TARGET-20-PANLLX  TARGET-20-PANLRE  TARGET-20-PANLXK  TARGET-20-PANLXM  TARGET-20-PANMEM
                        TARGET-20-PANNBM  TARGET-20-PANNHB  TARGET-20-PANNJI  TARGET-20-PANPKN  TARGET-20-PANPLS
                        TARGET-20-PANPMY  TARGET-20-PANPSF  TARGET-20-PANPSV  TARGET-20-PANPTM  TARGET-20-PANPUR
                        TARGET-20-PANRIK  TARGET-20-PANRWM  TARGET-20-PANSBH  TARGET-20-PANSDI  TARGET-20-PANSJB
                        TARGET-20-PANTCT  TARGET-20-PANTIV  TARGET-20-PANTNA  TARGET-20-PANTPW  TARGET-20-PANTRL
                        TARGET-20-PANTWV  TARGET-20-PANTXR  TARGET-20-PANUDS  TARGET-20-PANUNT  TARGET-20-PANUTB
                        TARGET-20-PANUTX  TARGET-20-PANUUA  TARGET-20-PANUUU  TARGET-20-PANVBP  TARGET-20-PANVGE
                        TARGET-20-PANVGP  TARGET-20-PANVUF  TARGET-20-PANWHP  TARGET-20-PANXAF  TARGET-20-PANXPU
                        TARGET-20-PANXWX  TARGET-20-PANYCG  TARGET-20-PANYGP  TARGET-20-PANYNR  TARGET-20-PANYSN
                        TARGET-20-PANZCU  TARGET-20-PANZKA  TARGET-20-PANZWB  TARGET-20-PANZXI  TARGET-20-PAPAEG
                        TARGET-20-PAPAJE  TARGET-20-PAPAPD  TARGET-20-PAPAWN  TARGET-20-PAPBEJ  TARGET-20-PAPUNR
                        TARGET-20-PAPVCN  TARGET-20-PAPVDV  TARGET-20-PAPVGE  TARGET-20-PAPVKG  TARGET-20-PAPVZK
                        TARGET-20-PAPWHS  TARGET-20-PAPWIU  TARGET-20-PAPWYK  TARGET-20-PAPWZR  TARGET-20-PAPXJG
                        TARGET-20-PAPXRJ  TARGET-20-PAPXUF  TARGET-20-PAPXVK  TARGET-20-PAPXWI  TARGET-20-PAPYFJ
                        TARGET-20-PAPZIZ  TARGET-20-PAPZLT  TARGET-20-PARAHF  TARGET-20-PARAJX  TARGET-20-PARANT
                        TARGET-20-PARAPD  TARGET-20-PARASV  TARGET-20-PARBFJ  TARGET-20-PARBFZ  TARGET-20-PARBIU
                        TARGET-20-PARBRA  TARGET-20-PARBTC  TARGET-20-PARBTV  TARGET-20-PARBVE  TARGET-20-PARBXE
                        TARGET-20-PARCCH  TARGET-20-PARCEC  TARGET-20-PARCEV  TARGET-20-PARCHJ  TARGET-20-PARCHW
                        TARGET-20-PARCUK  TARGET-20-PARCVP  TARGET-20-PARCVS  TARGET-20-PARCZL  TARGET-20-PARDDA
                        TARGET-20-PARDDY  TARGET-20-PARDEV  TARGET-20-PARDMG  TARGET-20-PARDYG  TARGET-20-PARDZW
                        TARGET-20-PAREFM  TARGET-20-PARENB  TARGET-20-PARERV  TARGET-20-PARFAL  TARGET-20-PARFCH
                        TARGET-20-PARFGK  TARGET-20-PARFIW  TARGET-20-PARFRN  TARGET-20-PARFVC  TARGET-20-PARFXF
                        TARGET-20-PARGDB  TARGET-20-PARGTL  TARGET-20-PARGTR  TARGET-20-PARGVC  TARGET-20-PARGXP
                        TARGET-20-PARHBA  TARGET-20-PARHJV  TARGET-20-PARHPP  TARGET-20-PARHVI  TARGET-20-PARHVK
                        TARGET-20-PARIAP  TARGET-20-PARIEG  TARGET-20-PARIHK  TARGET-20-PARIMT  TARGET-20-PARINM
                        TARGET-20-PARIYB  TARGET-20-PARIZR  TARGET-20-PARJCR  TARGET-20-PARJVI  TARGET-20-PARJWH
                        TARGET-20-PARJYP  TARGET-20-PARKCX  TARGET-20-PARKFB  TARGET-20-PARKSH  TARGET-20-PARKUY
                        TARGET-20-PARLFE  TARGET-20-PARLMY  TARGET-20-PARLSW  TARGET-20-PARLVL  TARGET-20-PARMGX
                        TARGET-20-PARMIX  TARGET-20-PARMME  TARGET-20-PARMMN  TARGET-20-PARMST  TARGET-20-PARMZC
                        TARGET-20-PARMZF  TARGET-20-PARNIA  TARGET-20-PARNNT  TARGET-20-PARNZW  TARGET-20-PARPBF
                        TARGET-20-PARPDS  TARGET-20-PARPLC  TARGET-20-PARPPY  TARGET-20-PARPVZ  TARGET-20-PARPWL
                        TARGET-20-PARSAN  TARGET-20-PARSHM  TARGET-20-PARTAL  TARGET-20-PARTST  TARGET-20-PARTXH
                        TARGET-20-PARTYK  TARGET-20-PARTYV  TARGET-20-PARUBT  TARGET-20-PARUCB  TARGET-20-PARUDL
                        TARGET-20-PARUNX  TARGET-20-PARURW  TARGET-20-PARUTH  TARGET-20-PARUUB  TARGET-20-PARUWX
                        TARGET-20-PARVAI  TARGET-20-PARVLP  TARGET-20-PARVSF  TARGET-20-PARVUA  TARGET-20-PARWAS
                        TARGET-20-PARWDZ  TARGET-20-PARWPW  TARGET-20-PARWXS  TARGET-20-PARWXU  TARGET-20-PARXBT
                        TARGET-20-PARXCG  TARGET-20-PARXEC  TARGET-20-PARXMP  TARGET-20-PARXNG  TARGET-20-PARXVI
                        TARGET-20-PARXZP  TARGET-20-PARYCG  TARGET-20-PARYEB  TARGET-20-PARYFN  TARGET-20-PARYGA
                        TARGET-20-PARYVW  TARGET-20-PARYXV  TARGET-20-PARZMZ  TARGET-20-PARZUU  TARGET-20-PARZWH
                        TARGET-20-PARZYL  TARGET-20-PASADG  TARGET-20-PASAFM  TARGET-20-PASARK  TARGET-20-PASAUT
                        TARGET-20-PASAZL  TARGET-20-PASBBE  TARGET-20-PASBGE  TARGET-20-PASBHI  TARGET-20-PASBPK
                        TARGET-20-PASBPW  TARGET-20-PASBSB  TARGET-20-PASCCS  TARGET-20-PASCFW  TARGET-20-PASCGC
                        TARGET-20-PASCGR  TARGET-20-PASCIG  TARGET-20-PASCRZ  TARGET-20-PASCZU  TARGET-20-PASDFK
                        TARGET-20-PASDGX  TARGET-20-PASDJY  TARGET-20-PASDUD  TARGET-20-PASDVA  TARGET-20-PASECW
                        TARGET-20-PASEFD  TARGET-20-PASEGC  TARGET-20-PASELF  TARGET-20-PASENE  TARGET-20-PASEYM
                        TARGET-20-PASFEW  TARGET-20-PASFHK  TARGET-20-PASFIT  TARGET-20-PASFJB  TARGET-20-PASFKI
                        TARGET-20-PASFLG  TARGET-20-PASFLM  TARGET-20-PASFNP  TARGET-20-PASFVP  TARGET-20-PASFYF
                        TARGET-20-PASFZN  TARGET-20-PASGCB  TARGET-20-PASGCE  TARGET-20-PASGGK  TARGET-20-PASGMZ
                        TARGET-20-PASGWE  TARGET-20-PASGWH  TARGET-20-PASGZS  TARGET-20-PASHBI  TARGET-20-PASHHH
                        TARGET-20-PASHLE  TARGET-20-PASHWN  TARGET-20-PASHYZ  TARGET-20-PASHZX  TARGET-20-PASIBG
                        TARGET-20-PASIEJ  TARGET-20-PASIEP  TARGET-20-PASILA  TARGET-20-PASINN  TARGET-20-PASIZX
                        TARGET-20-PASJDV  TARGET-20-PASJEJ  TARGET-20-PASJGZ  TARGET-20-PASJIM  TARGET-20-PASJTM
                        TARGET-20-PASJUC  TARGET-20-PASKDS  TARGET-20-PASKFW  TARGET-20-PASKGH  TARGET-20-PASKIH
                        TARGET-20-PASKUA  TARGET-20-PASLDL  TARGET-20-PASLDS  TARGET-20-PASLMR  TARGET-20-PASLSD
                        TARGET-20-PASLTF  TARGET-20-PASLYX  TARGET-20-PASMGW  TARGET-20-PASMHY  TARGET-20-PASMYS
                        TARGET-20-PASNIY  TARGET-20-PASNRB  TARGET-20-PASPFE  TARGET-20-PASPGA  TARGET-20-PASPKE
                        TARGET-20-PASPLU  TARGET-20-PASPMI  TARGET-20-PASPSV  TARGET-20-PASPTM  TARGET-20-PASPTW
                        TARGET-20-PASPWZ  TARGET-20-PASPYW  TARGET-20-PASREH  TARGET-20-PASRLS  TARGET-20-PASRRB
                        TARGET-20-PASRRU  TARGET-20-PASRTP  TARGET-20-PASSLT  TARGET-20-PASSPT  TARGET-20-PASSSI
                        TARGET-20-PASSWG  TARGET-20-PASTFY  TARGET-20-PASTPU  TARGET-20-PASTTW  TARGET-20-PASTUH
                        TARGET-20-PASUHK  TARGET-20-PASVPJ  TARGET-20-PASVUI  TARGET-20-PASVVS  TARGET-20-PASVWK
                        TARGET-20-PASVYA  TARGET-20-PASVYL  TARGET-20-PASWAJ  TARGET-20-PASWAT  TARGET-20-PASWLN
                        TARGET-20-PASWPD  TARGET-20-PASWPT  TARGET-20-PASWTG  TARGET-20-PASWTY  TARGET-20-PASXEA
                        TARGET-20-PASXNR  TARGET-20-PASXNT  TARGET-20-PASXVC  TARGET-20-PASXYG  TARGET-20-PASYDC
                        TARGET-20-PASYJI  TARGET-20-PASYRN  TARGET-20-PASZEI  TARGET-20-PASZLJ  TARGET-20-PASZZE
                        TARGET-20-PATABB  TARGET-20-PATAML  TARGET-20-PATASP  TARGET-20-PATAST  TARGET-20-PATBFF
                        TARGET-20-PATBFL  TARGET-20-PATCHL  TARGET-20-PATDHA  TARGET-20-PATDNN  TARGET-20-PATEAF
                        TARGET-20-PATELT  TARGET-20-PATEYS  TARGET-20-PATFDF  TARGET-20-PATGAN  TARGET-20-PATGTL
                        TARGET-20-PATIAK  TARGET-20-PATJHJ  TARGET-20-PATJSP  TARGET-20-PATKJB  TARGET-20-PATLXB
                        TARGET-20-PATMIY  TARGET-21-PAMXZY  TARGET-21-PAMYMA  TARGET-21-PANVPB  TARGET-21-PANZLR
                        TARGET-21-PARBTV  TARGET-21-PARHRS  TARGET-21-PARLSL  TARGET-21-PARNAW  TARGET-21-PARXYR
                        TARGET-21-PARZIA  TARGET-21-PASDKZ  TARGET-21-PASDXR  TARGET-21-PASFHK  TARGET-21-PASFJJ
                        TARGET-21-PASFLG  TARGET-21-PASIGA  TARGET-21-PASLZE  TARGET-21-PASNKZ  TARGET-21-PASSLT
                        TARGET-21-PASTZK  TARGET-21-PASVJS  TARGET-21-PASYEJ  TARGET-21-PASYWA  TARGET-21-PATAIJ
                        TARGET-21-PATHIU  TARGET-21-PATISD  TARGET-21-PATJMY  TARGET-21-PATKBK  TARGET-21-PATKKJ
                        TARGET-21-PATKWH  
                    )],
                    'Validation' => [qw(
                        TARGET-20-PAPRND  TARGET-20-PAPSCM  TARGET-20-PAPUEM  TARGET-20-PAPUPC  TARGET-20-PAPUSR
                        TARGET-20-PAPVBS  TARGET-20-PAPVET  TARGET-20-PAPVWB  TARGET-20-PAPWFN  TARGET-20-PAPXAZ
                        TARGET-20-PAPXJT  TARGET-20-PAPYUI  TARGET-20-PAPZCL  TARGET-20-PAPZCZ  TARGET-20-PAPZFV
                        TARGET-20-PAPZJT  TARGET-20-PAPZTC  TARGET-20-PAPZTU  TARGET-20-PAPZXN  TARGET-20-PAPZYJ
                        TARGET-20-PAPZYS  TARGET-20-PAPZZE  TARGET-20-PARAEF  TARGET-20-PARAEG  TARGET-20-PARAFA
                        TARGET-20-PARAIC  TARGET-20-PARAUM  TARGET-20-PARBCV  TARGET-20-PARBEL  TARGET-20-PARBGF
                        TARGET-20-PARBLP  TARGET-20-PARBLV  TARGET-20-PARBZJ  TARGET-20-PARCAU  TARGET-20-PARCEA
                        TARGET-20-PARCIN  TARGET-20-PARCRW  TARGET-20-PARCTW  TARGET-20-PARCZP  TARGET-20-PARDFM
                        TARGET-20-PARDKT  TARGET-20-PARDLW  TARGET-20-PARDPM  TARGET-20-PARDRM  TARGET-20-PARDYL
                        TARGET-20-PARDYW  TARGET-20-PAREEC  TARGET-20-PAREHK  TARGET-20-PAREHP  TARGET-20-PAREWJ
                        TARGET-20-PARFJN  TARGET-20-PARFKS  TARGET-20-PARFLB  TARGET-20-PARFMY  TARGET-20-PARFPI
                        TARGET-20-PARFUZ  TARGET-20-PARFWM  TARGET-20-PARFZP  TARGET-20-PARGMH  TARGET-20-PARGSY
                        TARGET-20-PARGTF  TARGET-20-PARGYS  TARGET-20-PARHJA  TARGET-20-PARHJL  TARGET-20-PARHKJ
                        TARGET-20-PARHKX  TARGET-20-PARHKY  TARGET-20-PARHKZ  TARGET-20-PARHRS  TARGET-20-PARHSA
                        TARGET-20-PARHUP  TARGET-20-PARHXT  TARGET-20-PARHYP  TARGET-20-PARIFD  TARGET-20-PARILH
                        TARGET-20-PARIYP  TARGET-20-PARJET  TARGET-20-PARJGD  TARGET-20-PARJHP  TARGET-20-PARJKM
                        TARGET-20-PARJLW  TARGET-20-PARJRG  TARGET-20-PARJUJ  TARGET-20-PARJVU  TARGET-20-PARKGB
                        TARGET-20-PARKHV  TARGET-20-PARKJZ  TARGET-20-PARKLC  TARGET-20-PARKSY  TARGET-20-PARLGT
                        TARGET-20-PARLHW  TARGET-20-PARLSL  TARGET-20-PARLUS  TARGET-20-PARLXL  TARGET-20-PARMGH
                        TARGET-20-PARMHD  TARGET-20-PARMIZ  TARGET-20-PARMLW  TARGET-20-PARMMZ  TARGET-20-PARMPM
                        TARGET-20-PARNAW  TARGET-20-PARNFR  TARGET-20-PARNFZ  TARGET-20-PARNIH  TARGET-20-PARNIL
                        TARGET-20-PARNIN  TARGET-20-PARNJC  TARGET-20-PARNNX  TARGET-20-PARNPC  TARGET-20-PARNPF
                        TARGET-20-PARNRS  TARGET-20-PARNTM  TARGET-20-PARNXW  TARGET-20-PARPBA  TARGET-20-PARPCT
                        TARGET-20-PARPEK  TARGET-20-PARPHH  TARGET-20-PARPZP  TARGET-20-PARRAD  TARGET-20-PARRBK
                        TARGET-20-PARRDD  TARGET-20-PARRFC  TARGET-20-PARRHB  TARGET-20-PARRMF  TARGET-20-PARRTH
                        TARGET-20-PARRYL  TARGET-20-PARSAA  TARGET-20-PARSFK  TARGET-20-PARSGE  TARGET-20-PARSGS
                        TARGET-20-PARSIN  TARGET-20-PARSRR  TARGET-20-PARSXZ  TARGET-20-PARTBN  TARGET-20-PARTVG
                        TARGET-20-PARTWN  TARGET-20-PARUAD  TARGET-20-PARUBE  TARGET-20-PARUEX  TARGET-20-PARURX
                        TARGET-20-PARUSN  TARGET-20-PARUXJ  TARGET-20-PARUZS  TARGET-20-PARVAF  TARGET-20-PARVLH
                        TARGET-20-PARVSX  TARGET-20-PARVTI  TARGET-20-PARVUC  TARGET-20-PARVXT  TARGET-20-PARVZU
                        TARGET-20-PARWCG  TARGET-20-PARWNS  TARGET-20-PARWWW  TARGET-20-PARXDI  TARGET-20-PARXJW
                        TARGET-20-PARXNP  TARGET-20-PARXYC  TARGET-20-PARYHL  TARGET-20-PARYHR  TARGET-20-PARYTI
                        TARGET-20-PARZGM  TARGET-20-PARZHI  TARGET-20-PARZHT  TARGET-20-PARZIA  TARGET-20-PARZPD
                        TARGET-20-PARZVA  TARGET-20-PARZVE  TARGET-20-PARZYF  TARGET-20-PARZYN  TARGET-20-PASAFH
                        TARGET-20-PASAMY  TARGET-20-PASANH  TARGET-20-PASANW  TARGET-20-PASARF  TARGET-20-PASARM
                        TARGET-20-PASASN  TARGET-20-PASAUN  TARGET-20-PASAWH  TARGET-20-PASAXB  TARGET-20-PASAYA
                        TARGET-20-PASBAX  TARGET-20-PASBBF  TARGET-20-PASBCT  TARGET-20-PASBDC  TARGET-20-PASBGZ
                        TARGET-20-PASBII  TARGET-20-PASBNA  TARGET-20-PASBST  TARGET-20-PASBYL  TARGET-20-PASCAF
                        TARGET-20-PASCBW  TARGET-20-PASCDM  TARGET-20-PASCFS  TARGET-20-PASCRP  TARGET-20-PASDET
                        TARGET-20-PASDIR  TARGET-20-PASDMF  TARGET-20-PASDNU  TARGET-20-PASDSN  TARGET-20-PASDTY
                        TARGET-20-PASDXF  TARGET-20-PASDXR  TARGET-20-PASDZT  TARGET-20-PASELK  TARGET-20-PASFFS
                        TARGET-20-PASFFX  TARGET-20-PASFIE  TARGET-20-PASFJJ  TARGET-20-PASFLW  TARGET-20-PASFMX
                        TARGET-20-PASFRD  TARGET-20-PASFTR  TARGET-20-PASFWI  TARGET-20-PASFXF  TARGET-20-PASFZB
                        TARGET-20-PASGAE  TARGET-20-PASGCJ  TARGET-20-PASGEM  TARGET-20-PASGFI  TARGET-20-PASGHD
                        TARGET-20-PASGKA  TARGET-20-PASGML  TARGET-20-PASGZK  TARGET-20-PASGZV  TARGET-20-PASHMK
                        TARGET-20-PASHUS  TARGET-20-PASHWV  TARGET-20-PASIAI  TARGET-20-PASICM  TARGET-20-PASIGA
                        TARGET-20-PASINA  TARGET-20-PASJCL  TARGET-20-PASJNM  TARGET-20-PASJPW  TARGET-20-PASJRD
                        TARGET-20-PASJXN  TARGET-20-PASJYX  TARGET-20-PASJZX  TARGET-20-PASKAS  TARGET-20-PASKFN
                        TARGET-20-PASKGD  TARGET-20-PASKMZ  TARGET-20-PASKNV  TARGET-20-PASKPI  TARGET-20-PASKRJ
                        TARGET-20-PASKRM  TARGET-20-PASLGD  TARGET-20-PASLHH  TARGET-20-PASLPE  TARGET-20-PASLPU
                        TARGET-20-PASLSE  TARGET-20-PASLSI  TARGET-20-PASLTS  TARGET-20-PASLZE  TARGET-20-PASMPC
                        TARGET-20-PASMRU  TARGET-20-PASMTB  TARGET-20-PASMTK  TARGET-20-PASMYP  TARGET-20-PASNAL
                        TARGET-20-PASNDA  TARGET-20-PASNDH  TARGET-20-PASNKC  TARGET-20-PASNLR  TARGET-20-PASNYB
                        TARGET-20-PASPIN  TARGET-20-PASPIX  TARGET-20-PASPLH  TARGET-20-PASPWC  TARGET-20-PASPXN
                        TARGET-20-PASPYR  TARGET-20-PASRAT  TARGET-20-PASRCW  TARGET-20-PASRIN  TARGET-20-PASRJL
                        TARGET-20-PASRRL  TARGET-20-PASRSS  TARGET-20-PASRSY  TARGET-20-PASRUJ  TARGET-20-PASRZX
                        TARGET-20-PASSBI  TARGET-20-PASSDX  TARGET-20-PASSGX  TARGET-20-PASSHZ  TARGET-20-PASSNX
                        TARGET-20-PASSUW  TARGET-20-PASSVI  TARGET-20-PASSYV  TARGET-20-PASTBK  TARGET-20-PASTEI
                        TARGET-20-PASTHA  TARGET-20-PASTIE  TARGET-20-PASTJT  TARGET-20-PASTSH  TARGET-20-PASTTJ
                        TARGET-20-PASTVM  TARGET-20-PASTWE  TARGET-20-PASTXM  TARGET-20-PASTZD  TARGET-20-PASTZK
                        TARGET-20-PASTZU  TARGET-20-PASUAF  TARGET-20-PASUCA  TARGET-20-PASUGU  TARGET-20-PASULX
                        TARGET-20-PASUMD  TARGET-20-PASURM  TARGET-20-PASURR  TARGET-20-PASUUD  TARGET-20-PASUUP
                        TARGET-20-PASUVD  TARGET-20-PASVAN  TARGET-20-PASVFG  TARGET-20-PASVMU  TARGET-20-PASVPC
                        TARGET-20-PASVSS  TARGET-20-PASVTP  TARGET-20-PASVVM  TARGET-20-PASVWE  TARGET-20-PASVWW
                        TARGET-20-PASVZC  TARGET-20-PASWER  TARGET-20-PASWGL  TARGET-20-PASWGS  TARGET-20-PASWIM
                        TARGET-20-PASWMP  TARGET-20-PASWNZ  TARGET-20-PASWVH  TARGET-20-PASWWD  TARGET-20-PASXAH
                        TARGET-20-PASXAP  TARGET-20-PASXDS  TARGET-20-PASXGT  TARGET-20-PASXIS  TARGET-20-PASXJY
                        TARGET-20-PASXKT  TARGET-20-PASXLJ  TARGET-20-PASXSF  TARGET-20-PASXSS  TARGET-20-PASXWN
                        TARGET-20-PASYCJ  TARGET-20-PASYDA  TARGET-20-PASYEJ  TARGET-20-PASYJL  TARGET-20-PASYRE
                        TARGET-20-PASYRR  TARGET-20-PASYTG  TARGET-20-PASYTW  TARGET-20-PASYVX  TARGET-20-PASYWA
                        TARGET-20-PASYWV  TARGET-20-PASYYW  TARGET-20-PASZAF  TARGET-20-PASZAI  TARGET-20-PASZBM
                        TARGET-20-PASZEB  TARGET-20-PASZER  TARGET-20-PASZJC  TARGET-20-PASZJR  TARGET-20-PASZJT
                        TARGET-20-PASZNB  TARGET-20-PASZUT  TARGET-20-PASZYU  TARGET-20-PASZZL  TARGET-20-PATABK
                        TARGET-20-PATAEA  TARGET-20-PATAER  TARGET-20-PATAIJ  TARGET-20-PATAIY  TARGET-20-PATAKC
                        TARGET-20-PATAKZ  TARGET-20-PATALD  TARGET-20-PATANY  TARGET-20-PATAUU  TARGET-20-PATAVF
                        TARGET-20-PATAWB  TARGET-20-PATBHG  TARGET-20-PATBIP  TARGET-20-PATBIR  TARGET-20-PATBIZ
                        TARGET-20-PATBJK  TARGET-20-PATBNP  TARGET-20-PATBPW  TARGET-20-PATBRA  TARGET-20-PATBUR
                        TARGET-20-PATBVJ  TARGET-20-PATBVX  TARGET-20-PATBWH  TARGET-20-PATBXU  TARGET-20-PATBYV
                        TARGET-20-PATCBV  TARGET-20-PATCLR  TARGET-20-PATCPY  TARGET-20-PATCTM  TARGET-20-PATCVL
                        TARGET-20-PATCWP  TARGET-20-PATCXL  TARGET-20-PATCYP  TARGET-20-PATCYY  TARGET-20-PATDFZ
                        TARGET-20-PATDIC  TARGET-20-PATDLH  TARGET-20-PATDLI  TARGET-20-PATDLZ  TARGET-20-PATDMY
                        TARGET-20-PATDRB  TARGET-20-PATDRL  TARGET-20-PATDRZ  TARGET-20-PATDVM  TARGET-20-PATDYY
                        TARGET-20-PATEEA  TARGET-20-PATEFH  TARGET-20-PATEIA  TARGET-20-PATEID  TARGET-20-PATELV
                        TARGET-20-PATEMK  TARGET-20-PATEMV  TARGET-20-PATENX  TARGET-20-PATESK  TARGET-20-PATESX
                        TARGET-20-PATETC  TARGET-20-PATEUF  TARGET-20-PATEWX  TARGET-20-PATFBW  TARGET-20-PATFCZ
                        TARGET-20-PATFGK  TARGET-20-PATFGL  TARGET-20-PATFMR  TARGET-20-PATFNK  TARGET-20-PATFRY
                        TARGET-20-PATFYN  TARGET-20-PATFZR  TARGET-20-PATGAY  TARGET-20-PATGBX  TARGET-20-PATGDZ
                        TARGET-20-PATGGI  TARGET-20-PATGGY  TARGET-20-PATGHV  TARGET-20-PATGIG  TARGET-20-PATGIY
                        TARGET-20-PATGRP  TARGET-20-PATGTF  TARGET-20-PATGUB  TARGET-20-PATGXE  TARGET-20-PATGXW
                        TARGET-20-PATHAE  TARGET-20-PATHIW  TARGET-20-PATHMB  TARGET-20-PATHVG  TARGET-20-PATHWS
                        TARGET-20-PATHZC  TARGET-20-PATHZL  TARGET-20-PATIAB  TARGET-20-PATIDY  TARGET-20-PATIGE
                        TARGET-20-PATIHH  TARGET-20-PATIII  TARGET-20-PATIIM  TARGET-20-PATILU  TARGET-20-PATIRW
                        TARGET-20-PATISD  TARGET-20-PATISV  TARGET-20-PATIVW  TARGET-20-PATJES  TARGET-20-PATJIC
                        TARGET-20-PATJKC  TARGET-20-PATJLP  TARGET-20-PATJMY  TARGET-20-PATJNI  TARGET-20-PATJPY
                        TARGET-20-PATJUT  TARGET-20-PATJWG  TARGET-20-PATJWN  TARGET-20-PATJXZ  TARGET-20-PATJYT
                        TARGET-20-PATKAH  TARGET-20-PATKBK  TARGET-20-PATKBT  TARGET-20-PATKEA  TARGET-20-PATKGM
                        TARGET-20-PATKKI  TARGET-20-PATKKJ  TARGET-20-PATKLS  TARGET-20-PATKMB  TARGET-20-PATKPC
                        TARGET-20-PATKUG  TARGET-20-PATKWH  TARGET-20-PATKYC  TARGET-20-PATKYT  TARGET-20-PATLBC
                        TARGET-20-PATLDB  TARGET-20-PATLDZ  TARGET-20-PATLFJ  TARGET-20-PATLHB  TARGET-20-PATLIG
                        TARGET-20-PATLJF  TARGET-20-PATLKU  TARGET-20-PATLLK  TARGET-20-PATLMH  TARGET-20-PATLVC
                        TARGET-20-PATLVK  TARGET-20-PATLZB  TARGET-20-PATLZC  TARGET-20-PATMCW  TARGET-20-PATMDJ
                        TARGET-20-PATMDZ  TARGET-20-PATMEU  TARGET-20-PATMFM  TARGET-20-PATMFW  TARGET-20-PATMIK
                        TARGET-20-PATMMC  TARGET-20-PATMNT  TARGET-20-PATMNY  
                    )],
                },
            },
            'CCSK' => {
                'dbGaP_study_ids' => [qw(
                    phs000466
                )],
                'idf' => {
                    'contacts' => [
                        {
                            'last_name' => 'Gadd',
                            'first_name' => 'Samantha',
                            'mid_initials' => 'L',
                            'email' => 'sgadd@luriechildrens.org',
                            'phone' => '+1 773 755 6392',
                            'fax' => '',
                            'address' => '2430 N Halsted St, Room C366 Chicago, IL 60614',
                            'affiliation' => 'Lurie Children\'s Hospital of Chicago Research Center',
                            'roles' => [
                                'investigator',
                                'data analyst',
                            ],
                        },
                        {
                            'last_name' => 'Perlman',
                            'first_name' => 'Elizabeth',
                            'mid_initials' => 'J',
                            'email' => 'eperlman@luriechildrens.org',
                            'phone' => '+1 312 227 3967',
                            'fax' => '',
                            'address' => '225 E Chicago Ave, Chicago, IL 60611',
                            'affiliation' => 'Ann & Robert H. Lurie Children\'s Hospital of Chicago',
                            'roles' => [
                                'investigator',
                            ],
                        },
                    ],
                },
                'cases_by_cohort' => {
                    'Discovery' => [qw(
                        TARGET-51-PAEALX  TARGET-51-PAJLIV  TARGET-51-PAJLWU  TARGET-51-PAJMFS  TARGET-51-PAJMNM
                        TARGET-51-PAJNCV  TARGET-51-PAJPFB  TARGET-51-PAKWMM  TARGET-51-PALEIR  TARGET-51-PALFEF
                        TARGET-51-PALFYG  TARGET-51-PALKEI  TARGET-51-PALLXV  
                    )],
                },
            },
            'MDLS-NBL' => {
                'dbGaP_study_ids' => [qw(
                    phs000469
                )],
                'idf' => {
                    'contacts' => [
                        {
                            'last_name' => 'Maris',
                            'first_name' => 'John',
                            'mid_initials' => 'M',
                            'email' => 'maris@chop.edu',
                            'phone' => '+1 215 590 5244',
                            'fax' => '+1 267 426 0685',
                            'address' => '3501 Civic Center Blvd CTRB 3060, Philadelphia, PA 19104',
                            'affiliation' => 'Children\'s Hospital of Philadelphia',
                            'roles' => [
                                'investigator',
                            ],
                        },
                    ],
                },
            },
            'MDLS-PPTP' => {
                'dbGaP_study_ids' => [qw(
                    phs000469
                )],
                'idf' => {
                    'contacts' => [
                        {
                            'last_name' => 'Houghton',
                            'first_name' => 'Peter',
                            'mid_initials' => 'J',
                            'email' => 'peter.houghton@nationwidechildrens.org',
                            'phone' => '+1 614 355 2633',
                            'fax' => '',
                            'address' => '700 Children\'s Dr., Columbus OH 43205',
                            'affiliation' => 'Nationwide Children\'s Hospital',
                            'roles' => [
                                'investigator',
                            ],
                        },
                    ],
                },
            },
            'NBL' => {
                'dbGaP_study_ids' => [qw(
                    phs000467
                )],
                'idf' => {
                    'contacts' => [
                        {
                            'last_name' => 'Maris',
                            'first_name' => 'John',
                            'mid_initials' => 'M',
                            'email' => 'maris@chop.edu',
                            'phone' => '+1 215 590 5244',
                            'fax' => '+1 267 426 0685',
                            'address' => '3501 Civic Center Blvd CTRB 3060, Philadelphia, PA 19104',
                            'affiliation' => 'Children\'s Hospital of Philadelphia',
                            'roles' => [
                                'investigator',
                            ],
                        },
                    ],
                },
                'cases_by_cohort' => {
                    'Discovery' => [qw(
                        TARGET-30-PAHYWC  TARGET-30-PAICGF  TARGET-30-PAIFCS  TARGET-30-PAIFXV  TARGET-30-PAILNU
                        TARGET-30-PAIMDT  TARGET-30-PAINLN  TARGET-30-PAIPGU  TARGET-30-PAISNS  TARGET-30-PAISSH
                        TARGET-30-PAITCI  TARGET-30-PAITEG  TARGET-30-PAIVHE  TARGET-30-PAIVZR  TARGET-30-PAIWRB
                        TARGET-30-PAIXFZ  TARGET-30-PAIXIF  TARGET-30-PAIXNC  TARGET-30-PAIXNV  TARGET-30-PAIXRK
                        TARGET-30-PAKFUY  TARGET-30-PAKGKH  TARGET-30-PAKHCF  TARGET-30-PAKHHB  TARGET-30-PAKIPY
                        TARGET-30-PAKJRE  TARGET-30-PAKVUY  TARGET-30-PAKXDZ  TARGET-30-PAKYZS  TARGET-30-PAKZRE
                        TARGET-30-PAKZRF  TARGET-30-PAKZRH  TARGET-30-PALAKE  TARGET-30-PALAKM  TARGET-30-PALBFW
                        TARGET-30-PALCBW  TARGET-30-PALETP  TARGET-30-PALEVG  TARGET-30-PALFPI  TARGET-30-PALHVD
                        TARGET-30-PALIIN  TARGET-30-PALJPX  TARGET-30-PALJUV  TARGET-30-PALKUC  TARGET-30-PALKXJ
                        TARGET-30-PALNLU  TARGET-30-PALNVP  TARGET-30-PALPGG  TARGET-30-PALRSD  TARGET-30-PALSAE
                        TARGET-30-PALTEG  TARGET-30-PALTYB  TARGET-30-PALUDH  TARGET-30-PALUYS  TARGET-30-PALVKK
                        TARGET-30-PALWIP  TARGET-30-PALWVJ  TARGET-30-PALXHW  TARGET-30-PALXMM  TARGET-30-PALXTB
                        TARGET-30-PALZRG  TARGET-30-PALZSL  TARGET-30-PALZZV  TARGET-30-PAMBAC  TARGET-30-PAMBMJ
                        TARGET-30-PAMCXF  TARGET-30-PAMDAL  TARGET-30-PAMEZH  TARGET-30-PAMMWD  TARGET-30-PAMMXF
                        TARGET-30-PAMNLH  TARGET-30-PAMNYX  TARGET-30-PAMUTD  TARGET-30-PAMVLG  TARGET-30-PAMVRA
                        TARGET-30-PAMYCE  TARGET-30-PAMZGT  TARGET-30-PAMZMG  TARGET-30-PANBCI  TARGET-30-PANBJH
                        TARGET-30-PANBMJ  TARGET-30-PANBSP  TARGET-30-PANGXK  TARGET-30-PANIPC  TARGET-30-PANJLH
                        TARGET-30-PANKFE  TARGET-30-PANLET  TARGET-30-PANNMS  TARGET-30-PANPVI  TARGET-30-PANRHJ
                        TARGET-30-PANRRW  TARGET-30-PANRVJ  TARGET-30-PANSBN  TARGET-30-PANUIF  TARGET-30-PANUKV
                        TARGET-30-PANWRR  TARGET-30-PANXJL  TARGET-30-PANYBL  TARGET-30-PANYGR  TARGET-30-PANZPV
                        TARGET-30-PANZRV  TARGET-30-PANZVU  TARGET-30-PAPBGH  TARGET-30-PAPBJE  TARGET-30-PAPBJT
                        TARGET-30-PAPBZI  TARGET-30-PAPCTS  TARGET-30-PAPEAV  TARGET-30-PAPEFE  TARGET-30-PAPHPE
                        TARGET-30-PAPICY  TARGET-30-PAPKWN  TARGET-30-PAPKXS  TARGET-30-PAPLSD  TARGET-30-PAPNEP
                        TARGET-30-PAPPKJ  TARGET-30-PAPREJ  TARGET-30-PAPRMJ  TARGET-30-PAPRPR  TARGET-30-PAPRXW
                        TARGET-30-PAPSEI  TARGET-30-PAPSKM  TARGET-30-PAPSMC  TARGET-30-PAPTAN  TARGET-30-PAPTCR
                        TARGET-30-PAPTDH  TARGET-30-PAPTFZ  TARGET-30-PAPTIP  TARGET-30-PAPTJB  TARGET-30-PAPTLA
                        TARGET-30-PAPTLD  TARGET-30-PAPTLV  TARGET-30-PAPTLY  TARGET-30-PAPTMM  TARGET-30-PAPUAR
                        TARGET-30-PAPUEB  TARGET-30-PAPUJU  TARGET-30-PAPUNH  TARGET-30-PAPUTN  TARGET-30-PAPUWY
                        TARGET-30-PAPVEB  TARGET-30-PAPVFD  TARGET-30-PAPVRN  TARGET-30-PAPVXS  TARGET-30-PAPWFY
                        TARGET-30-PAPWUC  TARGET-30-PAPYNZ  TARGET-30-PAPZFW  TARGET-30-PAPZYP  TARGET-30-PAPZYZ
                        TARGET-30-PARABJ  TARGET-30-PARABN  TARGET-30-PARACM  TARGET-30-PARACR  TARGET-30-PARACS
                        TARGET-30-PARAHE  TARGET-30-PARAMT  TARGET-30-PARASL  TARGET-30-PARBAJ  TARGET-30-PARBGP
                        TARGET-30-PARBLH  TARGET-30-PARCRR  TARGET-30-PARCWT  TARGET-30-PARDCK  TARGET-30-PARDIW
                        TARGET-30-PARDUJ  TARGET-30-PARDVT  TARGET-30-PARDYU  TARGET-30-PAREAG  TARGET-30-PAREGK
                        TARGET-30-PARETE  TARGET-30-PARFRE  TARGET-30-PARFWB  TARGET-30-PARGDJ  TARGET-30-PARGHY
                        TARGET-30-PARGKK  TARGET-30-PARGUX  TARGET-30-PARGZK  TARGET-30-PARHAM  TARGET-30-PARHDE
                        TARGET-30-PARHUX  TARGET-30-PARHYL  TARGET-30-PARIKF  TARGET-30-PARIRD  TARGET-30-PARJEN
                        TARGET-30-PARJMX  TARGET-30-PARJVP  TARGET-30-PARKAG  TARGET-30-PARKGJ  TARGET-30-PARKNP
                        TARGET-30-PARKZF  TARGET-30-PARLMK  TARGET-30-PARLTG  TARGET-30-PARMDD  TARGET-30-PARMFA
                        TARGET-30-PARMLF  TARGET-30-PARMPP  TARGET-30-PARMTT  TARGET-30-PARNCW  TARGET-30-PARNEE
                        TARGET-30-PARNLJ  TARGET-30-PARNNC  TARGET-30-PARNNG  TARGET-30-PARNTS  TARGET-30-PARPGU
                        TARGET-30-PARRBU  TARGET-30-PARRLH  TARGET-30-PARSBI  TARGET-30-PARSEA  TARGET-30-PARSHT
                        TARGET-30-PARSRJ  TARGET-30-PARUPN  TARGET-30-PARURB  TARGET-30-PARUXY  TARGET-30-PARVFJ
                        TARGET-30-PARVLK  TARGET-30-PARVME  TARGET-30-PARVNT  TARGET-30-PARXLM  TARGET-30-PARYNK
                        TARGET-30-PARYXW  TARGET-30-PARZCJ  TARGET-30-PARZHA  TARGET-30-PARZIP  TARGET-30-PARZMY
                        TARGET-30-PASAAN  TARGET-30-PASAJU  TARGET-30-PASATK  TARGET-30-PASAZJ  TARGET-30-PASBEN
                        TARGET-30-PASBGV  TARGET-30-PASCDX  TARGET-30-PASCFC  TARGET-30-PASCJJ  TARGET-30-PASCKI
                        TARGET-30-PASCLP  TARGET-30-PASCTR  TARGET-30-PASCUF  TARGET-30-PASDZJ  TARGET-30-PASEGA
                        TARGET-30-PASFGG  TARGET-30-PASFIC  TARGET-30-PASFNY  TARGET-30-PASFRV  TARGET-30-PASGAP
                        TARGET-30-PASGPY  TARGET-30-PASGUT  TARGET-30-PASHFA  TARGET-30-PASJYB  TARGET-30-PASJZC
                        TARGET-30-PASKFV  TARGET-30-PASKJX  TARGET-30-PASKTB  TARGET-30-PASLGS  TARGET-30-PASMDM
                        TARGET-30-PASMJG  TARGET-30-PASMNT  TARGET-30-PASNEF  TARGET-30-PASNML  TARGET-30-PASNPG
                        TARGET-30-PASNZU  TARGET-30-PASPBZ  TARGET-30-PASPER  TARGET-30-PASREY  TARGET-30-PASRFS
                        TARGET-30-PASSRN  TARGET-30-PASSRS  TARGET-30-PASSWB  TARGET-30-PASSWW  TARGET-30-PASTCN
                        TARGET-30-PASTKC  TARGET-30-PASTKW  TARGET-30-PASTXR  TARGET-30-PASUCB  TARGET-30-PASUML
                        TARGET-30-PASUYG  TARGET-30-PASVRU  TARGET-30-PASWAU  TARGET-30-PASWFB  TARGET-30-PASWIJ
                        TARGET-30-PASWLY  TARGET-30-PASWVY  TARGET-30-PASWYR  TARGET-30-PASXGP  TARGET-30-PASXHE
                        TARGET-30-PASXIE  TARGET-30-PASXNN  TARGET-30-PASXRG  TARGET-30-PASXRJ  TARGET-30-PASYLD
                        TARGET-30-PASYMX  TARGET-30-PASYPX  TARGET-30-PASZKE  TARGET-30-PASZPI  TARGET-30-PATAYJ
                        TARGET-30-PATBMM  TARGET-30-PATCFL  TARGET-30-PATDWN  TARGET-30-PATDXC  TARGET-30-PATDXG
                        TARGET-30-PATEKG  TARGET-30-PATEPF  TARGET-30-PATESI  TARGET-30-PATFCY  TARGET-30-PATFIN
                        TARGET-30-PATFXV  TARGET-30-PATGJU  TARGET-30-PATGLU  TARGET-30-PATGWT  TARGET-30-PATHKB
                        TARGET-30-PATHVK  TARGET-30-PATILE  TARGET-30-PATINJ  TARGET-30-PATNKP  TARGET-30-PATYIL
                        TARGET-30-PAUDDK  
                    )],
                    'Validation' => [qw(
                        TARGET-30-PARPUF  TARGET-30-PARSVF  TARGET-30-PARSXI  TARGET-30-PARSZV  TARGET-30-PARTCE
                        TARGET-30-PARTPF  TARGET-30-PARTRP  TARGET-30-PARTYI  TARGET-30-PARTZW  TARGET-30-PARUCL
                        TARGET-30-PARUCM  TARGET-30-PARUGX  TARGET-30-PARUPT  TARGET-30-PARUTJ  TARGET-30-PARUTX
                        TARGET-30-PARVHG  TARGET-30-PARVIH  TARGET-30-PARVMU  TARGET-30-PARVVM  TARGET-30-PARVWL
                        TARGET-30-PARVZT  TARGET-30-PARWAM  TARGET-30-PARWBC  TARGET-30-PARWEH  TARGET-30-PARWEV
                        TARGET-30-PARWTY  TARGET-30-PARXAX  TARGET-30-PARXLL  TARGET-30-PARXLN  TARGET-30-PARXMH
                        TARGET-30-PARXMM  TARGET-30-PARXPD  TARGET-30-PARXVA  TARGET-30-PARXXC  TARGET-30-PARXZA
                        TARGET-30-PARYEH  TARGET-30-PARYRJ  TARGET-30-PARYSR  TARGET-30-PARYUK  TARGET-30-PARYVD
                        TARGET-30-PARYWX  TARGET-30-PARZBH  TARGET-30-PARZKK  TARGET-30-PARZNV  TARGET-30-PARZZC
                        TARGET-30-PARZZD  TARGET-30-PASAAB  TARGET-30-PASAFG  TARGET-30-PASAHC  TARGET-30-PASAJY
                        TARGET-30-PASALE  TARGET-30-PASANE  TARGET-30-PASATF  TARGET-30-PASAVJ  TARGET-30-PASAZZ
                        TARGET-30-PASBDN  TARGET-30-PASBJY  TARGET-30-PASBKP  TARGET-30-PASBMW  TARGET-30-PASBPN
                        TARGET-30-PASBYW  TARGET-30-PASBZV  TARGET-30-PASCEW  TARGET-30-PASCFA  TARGET-30-PASCFD
                        TARGET-30-PASCIX  TARGET-30-PASCRK  TARGET-30-PASCWD  TARGET-30-PASCZY  TARGET-30-PASDDP
                        TARGET-30-PASDRV  TARGET-30-PASDYT  TARGET-30-PASEAR  TARGET-30-PASEDP  TARGET-30-PASEGF
                        TARGET-30-PASEJZ  TARGET-30-PASESX  TARGET-30-PASEVK  TARGET-30-PASEWX  TARGET-30-PASEWZ
                        TARGET-30-PASEYW  TARGET-30-PASFCG  TARGET-30-PASFDJ  TARGET-30-PASFDU  TARGET-30-PASFDV
                        TARGET-30-PASFEV  TARGET-30-PASFGD  TARGET-30-PASFKX  TARGET-30-PASFNF  TARGET-30-PASFWL
                        TARGET-30-PASFXC  TARGET-30-PASFXS  TARGET-30-PASGCD  TARGET-30-PASGDB  TARGET-30-PASGEE
                        TARGET-30-PASGES  TARGET-30-PASGGI  TARGET-30-PASGHN  TARGET-30-PASGKP  TARGET-30-PASGNT
                        TARGET-30-PASJTA  TARGET-30-PASJUU  TARGET-30-PASJWA  TARGET-30-PASJWG  TARGET-30-PASJWU
                        TARGET-30-PASKCS  TARGET-30-PASKKZ  TARGET-30-PASKNK  TARGET-30-PASKPC  TARGET-30-PASKRA
                        TARGET-30-PASKRS  TARGET-30-PASKRX  TARGET-30-PASKSR  TARGET-30-PASKSX  TARGET-30-PASKYH
                        TARGET-30-PASKZT  TARGET-30-PASLAE  TARGET-30-PASLCD  TARGET-30-PASLDM  TARGET-30-PASLFG
                        TARGET-30-PASLGM  TARGET-30-PASLIH  TARGET-30-PASLMN  TARGET-30-PASLPG  TARGET-30-PASLRM
                        TARGET-30-PASLSS  TARGET-30-PASLTC  TARGET-30-PASLXS  TARGET-30-PASLYF  TARGET-30-PASMCP
                        TARGET-30-PASMDG  TARGET-30-PASMET  TARGET-30-PASMNU  TARGET-30-PASMPT  TARGET-30-PASMRC
                        TARGET-30-PASMUB  TARGET-30-PASNMJ  TARGET-30-PASNUI  TARGET-30-PASNVM  TARGET-30-PASNWH
                        TARGET-30-PASPBY  TARGET-30-PASPGB  TARGET-30-PASPGU  TARGET-30-PASPIK  TARGET-30-PASPSE
                        TARGET-30-PASPTF  TARGET-30-PASPVR  TARGET-30-PASPVZ  TARGET-30-PASPXU  TARGET-30-PASRIB
                        TARGET-30-PASRLC  TARGET-30-PASRSG  TARGET-30-PASRWE  TARGET-30-PASSEC  TARGET-30-PASSGT
                        TARGET-30-PASSII  TARGET-30-PASSJK  TARGET-30-PASSNN  TARGET-30-PASSPI  TARGET-30-PASSUU
                        TARGET-30-PASSXA  TARGET-30-PASSZI  TARGET-30-PASTDT  TARGET-30-PASTGD  TARGET-30-PASTGH
                        TARGET-30-PASTHF  TARGET-30-PASTIJ  TARGET-30-PASTMW  TARGET-30-PASTNT  TARGET-30-PASTSI
                        TARGET-30-PASTSY  TARGET-30-PASTTX  TARGET-30-PASTWY  TARGET-30-PASTXV  TARGET-30-PASUCU
                        TARGET-30-PASUEA  TARGET-30-PASUEZ  TARGET-30-PASUFL  TARGET-30-PASUMG  TARGET-30-PASUTC
                        TARGET-30-PASUXH  TARGET-30-PASUYL  TARGET-30-PASVKE  TARGET-30-PASVKL  TARGET-30-PASVSU
                        TARGET-30-PASVWG  TARGET-30-PASVYV  TARGET-30-PASWCY  TARGET-30-PASWKI  TARGET-30-PASWNG
                        TARGET-30-PASWSZ  TARGET-30-PASWVD  TARGET-30-PASWVE  TARGET-30-PASWXG  TARGET-30-PASXCG
                        TARGET-30-PASXMI  TARGET-30-PASYIP  TARGET-30-PASYJF  TARGET-30-PASYTP  TARGET-30-PASYYM
                        TARGET-30-PASYYX  TARGET-30-PASZFX  TARGET-30-PASZGB  TARGET-30-PASZJB  TARGET-30-PASZST
                        TARGET-30-PASZTV  TARGET-30-PASZYY  TARGET-30-PATAAV  TARGET-30-PATACA  TARGET-30-PATAFE
                        TARGET-30-PATAFI  TARGET-30-PATAKH  TARGET-30-PATBAC  TARGET-30-PATBHY  TARGET-30-PATBJI
                        TARGET-30-PATBKX  TARGET-30-PATBPG  TARGET-30-PATBRX  TARGET-30-PATCDJ  TARGET-30-PATCEM
                        TARGET-30-PATCJF  TARGET-30-PATCJP  TARGET-30-PATCKU  TARGET-30-PATDBR  TARGET-30-PATDCJ
                        TARGET-30-PATDFU  TARGET-30-PATDSY  TARGET-30-PATDVF  TARGET-30-PATECM  TARGET-30-PATEUC
                        TARGET-30-PATEWM  TARGET-30-PATFES  TARGET-30-PATFMU  TARGET-30-PATFPS  TARGET-30-PATFTN
                        TARGET-30-PATFTR  TARGET-30-PATFTY  TARGET-30-PATGWU  TARGET-30-PATHJU  TARGET-30-PATHJZ
                        TARGET-30-PATHUU  TARGET-30-PATHYK  TARGET-30-PATIHB  TARGET-30-PATISU  TARGET-30-PATIWH
                        TARGET-30-PATIYD  TARGET-30-PATJET  TARGET-30-PATJEY  TARGET-30-PATJHU  TARGET-30-PATJIN
                        TARGET-30-PATJPI  TARGET-30-PATJXV  TARGET-30-PATJZC  TARGET-30-PATJZF  TARGET-30-PATKGB
                        TARGET-30-PATKHS  TARGET-30-PATKPD  TARGET-30-PATKSX  TARGET-30-PATLCM  TARGET-30-PATLKI
                        TARGET-30-PATLLI  TARGET-30-PATLNM  TARGET-30-PATLUI  TARGET-30-PATLXP  TARGET-30-PATMAJ
                        TARGET-30-PATMAW  TARGET-30-PATMFL  TARGET-30-PATMJV  TARGET-30-PATMPC  TARGET-30-PATMRZ
                        TARGET-30-PATMSI  TARGET-30-PATMSR  TARGET-30-PATMTX  TARGET-30-PATMXC  TARGET-30-PATNCI
                        TARGET-30-PATNEA  TARGET-30-PATNGD  TARGET-30-PATNPW  TARGET-30-PATNRI  TARGET-30-PATNRK
                        TARGET-30-PATNWL  TARGET-30-PATNXK  TARGET-30-PATNZJ  TARGET-30-PATPET  TARGET-30-PATPHR
                        TARGET-30-PATPJD  TARGET-30-PATPNR  TARGET-30-PATPPK  TARGET-30-PATPPU  TARGET-30-PATPXF
                        TARGET-30-PATPXJ  TARGET-30-PATPYK  TARGET-30-PATRHD  TARGET-30-PATRJG  TARGET-30-PATRJK
                        TARGET-30-PATRMB  TARGET-30-PATRUL  TARGET-30-PATRUX  TARGET-30-PATRXC  TARGET-30-PATSDR
                        TARGET-30-PATSJV  TARGET-30-PATSKE  TARGET-30-PATSPZ  TARGET-30-PATSRD  TARGET-30-PATSSA
                        TARGET-30-PATSXC  TARGET-30-PATTDY  TARGET-30-PATTEF  TARGET-30-PATTFB  TARGET-30-PATTHA
                        TARGET-30-PATTMM  TARGET-30-PATTNA  TARGET-30-PATTPC  TARGET-30-PATTPL  TARGET-30-PATTPW
                        TARGET-30-PATUEH  TARGET-30-PATUNK  TARGET-30-PATUNX  TARGET-30-PATUNZ  TARGET-30-PATUPR
                        TARGET-30-PATUVB  TARGET-30-PATUWG  TARGET-30-PATUZF  TARGET-30-PATVDI  TARGET-30-PATVDP
                        TARGET-30-PATVDY  TARGET-30-PATVJX  TARGET-30-PATVMF  TARGET-30-PATVNW  TARGET-30-PATVSU
                        TARGET-30-PATVTL  TARGET-30-PATVWA  TARGET-30-PATVYZ  TARGET-30-PATVZB  TARGET-30-PATWED
                        TARGET-30-PATWGC  TARGET-30-PATWGR  TARGET-30-PATWIL  TARGET-30-PATWMX  TARGET-30-PATWNB
                        TARGET-30-PATWTW  TARGET-30-PATWWJ  TARGET-30-PATWZB  TARGET-30-PATWZZ  TARGET-30-PATXDV
                        TARGET-30-PATXHC  TARGET-30-PATXHT  TARGET-30-PATXHW  TARGET-30-PATXKG  TARGET-30-PATXTF
                        TARGET-30-PATXUG  TARGET-30-PATXWS  TARGET-30-PATXWY  TARGET-30-PATXXF  TARGET-30-PATXXI
                        TARGET-30-PATYCM  TARGET-30-PATYDC  TARGET-30-PATYEJ  TARGET-30-PATYMK  TARGET-30-PATYMS
                        TARGET-30-PATYMZ  TARGET-30-PATYPH  TARGET-30-PATYWM  TARGET-30-PATYWX  TARGET-30-PATZBH
                        TARGET-30-PATZIG  TARGET-30-PATZRF  TARGET-30-PATZRU  TARGET-30-PAUAKT  TARGET-30-PAUATG
                        TARGET-30-PAUAZA  TARGET-30-PAUBDC  TARGET-30-PAUBEC  TARGET-30-PAUBFU  TARGET-30-PAUBGW
                        TARGET-30-PAUBHV  TARGET-30-PAUBPW  TARGET-30-PAUBRR  TARGET-30-PAUBSW  TARGET-30-PAUBVN
                        TARGET-30-PAUBWP  TARGET-30-PAUBYW  TARGET-30-PAUCFI  TARGET-30-PAUCGP  TARGET-30-PAUCKF
                        TARGET-30-PAUCRL  TARGET-30-PAUDBX  TARGET-30-PAUDDZ  TARGET-30-PAUDFR  TARGET-30-PAUDIK
                        TARGET-30-PAUDMU  TARGET-30-PAUDPP  TARGET-30-PAUDVA  TARGET-30-PAUELT  TARGET-30-PAUEYW
                        TARGET-30-PAUEZU  TARGET-30-PAUFFP  TARGET-30-PAUFIM  TARGET-30-PAUFPG  TARGET-30-PAUFSR
                        TARGET-30-PAUFUS  TARGET-30-PAUFVW  TARGET-30-PAUGGK  TARGET-30-PAUGIP  TARGET-30-PAUGJI
                        TARGET-30-PAUGNL  TARGET-30-PAUGRP  TARGET-30-PAUGVZ  TARGET-30-PAUGWT  TARGET-30-PAUGZD
                        TARGET-30-PAUHBZ  TARGET-30-PAUHFW  TARGET-30-PAUHHW  TARGET-30-PAUHIK  TARGET-30-PAUHSJ
                        TARGET-30-PAUHYY  TARGET-30-PAUICI  TARGET-30-PAUIFL  TARGET-30-PAUIHH  TARGET-30-PAUITU
                        TARGET-30-PAUIWS  TARGET-30-PAUJLH  TARGET-30-PAUJPC  TARGET-30-PAUJRW  TARGET-30-PAUJTY
                        TARGET-30-PAUJVX  TARGET-30-PAUKAP  TARGET-30-PAUKAW  TARGET-30-PAUKIJ  TARGET-30-PAUKLK
                        TARGET-30-PAUKNU  TARGET-30-PAUKRF  TARGET-30-PAUKVC  TARGET-30-PAULMT  TARGET-30-PAULNF
                        TARGET-30-PAULVH  TARGET-30-PAUMBB  TARGET-30-PAUMMZ  TARGET-30-PAUMUC  TARGET-30-PAUMXC
                        TARGET-30-PAUNST  TARGET-30-PAUNTY  TARGET-30-PAUNWR  TARGET-30-PAUPDY  TARGET-30-PAUPGV
                        TARGET-30-PAUPIC  TARGET-30-PAUPRN  TARGET-30-PAUPWX  TARGET-30-PAURCG  TARGET-30-PAURGD
                        TARGET-30-PAURPL  TARGET-30-PAURUR  TARGET-30-PAURYJ  TARGET-30-PAURZH  TARGET-30-PAUSJB
                        TARGET-30-PAUSXH  TARGET-30-PAUTKJ  TARGET-30-PAUTKP  TARGET-30-PAUTLP  TARGET-30-PAUTVX
                        TARGET-30-PAUUGT  TARGET-30-PAUUHD  TARGET-30-PAUUZU  TARGET-30-PAUVVE  TARGET-30-PAUWDK
                        TARGET-30-PAUWED  TARGET-30-PAUWEV  TARGET-30-PAUWFE  TARGET-30-PAUWXY  TARGET-30-PAUWYM
                        TARGET-30-PAUXFZ  TARGET-30-PAUXIW  TARGET-30-PAUXSZ  TARGET-30-PAUXUP  TARGET-30-PAUYDE
                        TARGET-30-PAUYXX  TARGET-30-PAUZAE  TARGET-30-PAUZMG  TARGET-30-PAUZRC  TARGET-30-PAUZSB
                        TARGET-30-PAUZTF  TARGET-30-PAUZZI  TARGET-30-PAVABN  TARGET-30-PAVAGS  TARGET-30-PAVALS
                        TARGET-30-PAVAYF  TARGET-30-PAVCGD  TARGET-30-PAVCHH  TARGET-30-PAVCJZ  TARGET-30-PAVCKK
                        TARGET-30-PAVCLI  TARGET-30-PAVDBS  TARGET-30-PAVDGG  TARGET-30-PAVDNK  TARGET-30-PAVDPE
                        TARGET-30-PAVDYS  TARGET-30-PAVEKN  TARGET-30-PAVETV  TARGET-30-PAVEZM  
                    )],
                },
            },
            'OS' => {
                'dbGaP_study_ids' => [qw(
                    phs000468
                )],
                'idf' => {
                    'contacts' => [
                        {
                            'last_name' => 'Lau',
                            'first_name' => 'Ching',
                            'email' => 'cclau@txch.org',
                            'phone' => '+1 832 824 4543',
                            'fax' => '+1 832 825 4038',
                            'address' => '1102 Bates Ave, Houston TX 77030',
                            'affiliation' => 'Baylor College of Medicine',
                            'roles' => [
                                'investigator',
                            ],
                        },
                    ],
                },
                'cases_by_cohort' => {
                    'Discovery' => [qw(
                        TARGET-40-0A4HLD  TARGET-40-0A4HMC  TARGET-40-0A4HX8  TARGET-40-0A4HXS  TARGET-40-0A4HY5
                        TARGET-40-0A4I0Q  TARGET-40-0A4I0S  TARGET-40-0A4I0W  TARGET-40-0A4I3S  TARGET-40-0A4I42
                        TARGET-40-0A4I48  TARGET-40-0A4I4E  TARGET-40-0A4I4M  TARGET-40-0A4I4O  TARGET-40-0A4I5B
                        TARGET-40-0A4I65  TARGET-40-0A4I6O  TARGET-40-0A4I8U  TARGET-40-0A4I9K  TARGET-40-PAKFVX
                        TARGET-40-PAKUZU  TARGET-40-PAKXLD  TARGET-40-PAKZZK  TARGET-40-PALECC  TARGET-40-PALFYN
                        TARGET-40-PALHRL  TARGET-40-PALKDP  TARGET-40-PALKGN  TARGET-40-PALWWX  TARGET-40-PALZGU
                        TARGET-40-PAMEKS  TARGET-40-PAMHLF  TARGET-40-PAMHYN  TARGET-40-PAMJXS  TARGET-40-PAMLKS
                        TARGET-40-PAMRHD  TARGET-40-PAMTCM  TARGET-40-PAMYYJ  TARGET-40-PANGPE  TARGET-40-PANGRW
                        TARGET-40-PANMIG  TARGET-40-PANPUM  TARGET-40-PANSEN  TARGET-40-PANVJJ  TARGET-40-PANXSC
                        TARGET-40-PANZHX  TARGET-40-PANZZJ  TARGET-40-PAPFLB  TARGET-40-PAPIJR  TARGET-40-PAPKWD
                        TARGET-40-PAPNVD  TARGET-40-PAPVYW  TARGET-40-PAPWWC  TARGET-40-PAPXGT  TARGET-40-PARBGW
                        TARGET-40-PARDAX  TARGET-40-PARFTG  TARGET-40-PARGTM  TARGET-40-PARJXU  TARGET-40-PARKAF
                        TARGET-40-PASEBY  TARGET-40-PASEFS  TARGET-40-PASFCV  TARGET-40-PASKZZ  TARGET-40-PASNZV
                        TARGET-40-PASRNE  TARGET-40-PASSLM  TARGET-40-PASUUH  TARGET-40-PASYUK  TARGET-40-PATAWV
                        TARGET-40-PATEEM  TARGET-40-PATJVI  TARGET-40-PATKSS  TARGET-40-PATMIF  TARGET-40-PATMPU
                        TARGET-40-PATMXR  TARGET-40-PATPBS  TARGET-40-PATUXZ  TARGET-40-PATXFN  TARGET-40-PAUBIT
                        TARGET-40-PAUTWB  TARGET-40-PAUTYB  TARGET-40-PAUUML  TARGET-40-PAUVUL  TARGET-40-PAUXPZ
                        TARGET-40-PAUYTT  TARGET-40-PAVALD  TARGET-40-PAVCLP  TARGET-40-PAVDTY  TARGET-40-PAVECB
                    )],
                    'Validation' => [qw(
                        
                    )],
                },
            },
            'OS-Toronto' => {
                'dbGaP_study_ids' => [qw(
                    phs000468
                )],
                'idf' => {
                    'contacts' => [
                        {
                            'last_name' => 'Lau',
                            'first_name' => 'Ching',
                            'email' => 'cclau@txch.org',
                            'phone' => '+1 832 824 4543',
                            'fax' => '+1 832 825 4038',
                            'address' => '1102 Bates Ave, Houston TX 77030',
                            'affiliation' => 'Baylor College of Medicine',
                            'roles' => [
                                'investigator',
                            ],
                        },
                    ],
                },
            },
            'RT' => {
                'dbGaP_study_ids' => [qw(
                    phs000469
                    phs000470
                )],
                'idf' => {
                    'contacts' => [
                        {
                            'last_name' => 'Perlman',
                            'first_name' => 'Elizabeth',
                            'email' => 'eperlman@luriechildrens.org',
                            'phone' => '+1 312 227 3967',
                            'fax' => '',
                            'address' => '225 E Chicago Ave, Chicago, IL 60611',
                            'affiliation' => 'Ann & Robert H. Lurie Children\'s Hospital of Chicago',
                            'roles' => [
                                'investigator',
                            ],
                        },
                    ],
                },
                'cases_by_cohort' => {
                    'Discovery' => [qw(
                        TARGET-00-NAAEMA  TARGET-00-NAAEMB  TARGET-00-NAAEMC  TARGET-52-NAAELX  TARGET-52-NAAELV
                        TARGET-52-NAAELY  TARGET-52-NAAELZ  TARGET-52-PABKLN  TARGET-52-PADYZI  TARGET-52-PAJLWM
                        TARGET-52-PAJMRB  TARGET-52-PAJNER  TARGET-52-PAJNFP  TARGET-52-PAJNFZ  TARGET-52-PAKHTL
                        TARGET-52-PARECB  TARGET-52-PARGRN  TARGET-52-PARIRN  TARGET-52-PARPFY  TARGET-52-PARRCL
                        TARGET-52-PARUGK  TARGET-52-PARZBI  TARGET-52-PASABD  TARGET-52-PASADZ  TARGET-52-PASCDH
                        TARGET-52-PASDLA  TARGET-52-PASRHU  TARGET-52-PASVDP  TARGET-52-PASWZZ  TARGET-52-PASXNA
                        TARGET-52-PASYNF  TARGET-52-PASZYE  TARGET-52-PATAFT  TARGET-52-PATBLF  TARGET-52-PATDVL
                        TARGET-52-PATENH  TARGET-52-PATFXW  TARGET-52-PATFZZ  TARGET-52-PATXEE  TARGET-52-PATXKA
                        TARGET-52-PAUCGJ  TARGET-52-PAUDPV  TARGET-52-PAUEKW  TARGET-52-PAUFVP  TARGET-52-PAUGYZ
                        TARGET-52-PAUHAZ  TARGET-52-PAUNPA  
                    )],
                    'Validation' => [qw(
                        TARGET-52-PADWRZ  TARGET-52-PADYCE  TARGET-52-PAEHIP  TARGET-52-PAJLRA  TARGET-52-PAJMBW
                        TARGET-52-PAJPHJ  TARGET-52-PAKLYZ  TARGET-52-PAKPEW  TARGET-52-PAKTCT  TARGET-52-PAREWI
                        TARGET-52-PARKKN  TARGET-52-PARTKH  TARGET-52-PARZRH  TARGET-52-PASAMZ  TARGET-52-PASGCL
                        TARGET-52-PASGGN  TARGET-52-PASILR  TARGET-52-PASNED  TARGET-52-PASXGF  TARGET-52-PATYUA
                        TARGET-52-PAVCKS  TARGET-52-PAVDPR  TARGET-52-PAVITI  TARGET-52-PAVVIT  TARGET-52-PAVYDM
                        TARGET-52-PAVYKD  TARGET-52-PAWDGA  TARGET-52-PAWFBL  TARGET-52-PAWFWK  
                    )],
                },
            },
            'WT' => {
                'dbGaP_study_ids' => [qw(
                    phs000471
                )],
                'idf' => {
                    'contacts' => [
                        {
                            'last_name' => 'Gadd',
                            'first_name' => 'Samantha',
                            'mid_initials' => 'L',
                            'email' => 'sgadd@luriechildrens.org',
                            'phone' => '+1 773 755 6392',
                            'fax' => '',
                            'address' => '2430 N Halsted St, Room C366 Chicago, IL 60614',
                            'affiliation' => 'Lurie Children\'s Hospital of Chicago Research Center',
                            'roles' => [
                                'investigator',
                                'data analyst',
                            ],
                        },
                        {
                            'last_name' => 'Perlman',
                            'first_name' => 'Elizabeth',
                            'mid_initials' => 'J',
                            'email' => 'eperlman@luriechildrens.org',
                            'phone' => '+1 312 227 3967',
                            'fax' => '',
                            'address' => '225 E Chicago Ave, Chicago, IL 60611',
                            'affiliation' => 'Ann & Robert H. Lurie Children\'s Hospital of Chicago',
                            'roles' => [
                                'investigator',
                            ],
                        },
                    ],
                },
                'cases_by_cohort' => {
                    'Discovery' => [qw(
                        TARGET-50-CAAAAA  TARGET-50-CAAAAB  TARGET-50-CAAAAC  TARGET-50-CAAAAH  TARGET-50-CAAAAL
                        TARGET-50-CAAAAM  TARGET-50-CAAAAO  TARGET-50-CAAAAP  TARGET-50-CAAAAQ  TARGET-50-CAAAAR
                        TARGET-50-CAAAAS  TARGET-50-PADXAY  TARGET-50-PADZUB  TARGET-50-PAEAFB  TARGET-50-PAEBXA
                        TARGET-50-PAECJB  TARGET-50-PAJLIP  TARGET-50-PAJLKC  TARGET-50-PAJLKR  TARGET-50-PAJLLF
                        TARGET-50-PAJLNJ  TARGET-50-PAJLPX  TARGET-50-PAJLSP  TARGET-50-PAJLTH  TARGET-50-PAJLTI
                        TARGET-50-PAJLUJ  TARGET-50-PAJLWT  TARGET-50-PAJMEL  TARGET-50-PAJMEN  TARGET-50-PAJMEP
                        TARGET-50-PAJMFU  TARGET-50-PAJMFY  TARGET-50-PAJMIZ  TARGET-50-PAJMJK  TARGET-50-PAJMJT
                        TARGET-50-PAJMKI  TARGET-50-PAJMKJ  TARGET-50-PAJMKN  TARGET-50-PAJMLI  TARGET-50-PAJMLZ
                        TARGET-50-PAJMMY  TARGET-50-PAJMRL  TARGET-50-PAJMSE  TARGET-50-PAJMUF  TARGET-50-PAJMVC
                        TARGET-50-PAJMVU  TARGET-50-PAJMXF  TARGET-50-PAJNAA  TARGET-50-PAJNAV  TARGET-50-PAJNBN
                        TARGET-50-PAJNCC  TARGET-50-PAJNCJ  TARGET-50-PAJNCZ  TARGET-50-PAJNDU  TARGET-50-PAJNEC
                        TARGET-50-PAJNGH  TARGET-50-PAJNJJ  TARGET-50-PAJNLT  TARGET-50-PAJNNC  TARGET-50-PAJNNR
                        TARGET-50-PAJNRH  TARGET-50-PAJNRL  TARGET-50-PAJNSL  TARGET-50-PAJNTJ  TARGET-50-PAJNUP
                        TARGET-50-PAJNUS  TARGET-50-PAJNVE  TARGET-50-PAJNVX  TARGET-50-PAJNYT  TARGET-50-PAJNZI
                        TARGET-50-PAJNZK  TARGET-50-PAJNZS  TARGET-50-PAJNZU  TARGET-50-PAJPAR  TARGET-50-PAJPAU
                        TARGET-50-PAJPCM  TARGET-50-PAJPDC  TARGET-50-PAJPDN  TARGET-50-PAJPEW  TARGET-50-PAJPGY
                        TARGET-50-PAJPHA  TARGET-50-PAKECR  TARGET-50-PAKFME  TARGET-50-PAKFYV  TARGET-50-PAKGED
                        TARGET-50-PAKGMU  TARGET-50-PAKGZX  TARGET-50-PAKJGM  TARGET-50-PAKKNS  TARGET-50-PAKKSE
                        TARGET-50-PAKMSV  TARGET-50-PAKMUB  TARGET-50-PAKNAL  TARGET-50-PAKNRX  TARGET-50-PAKNTW
                        TARGET-50-PAKNXS  TARGET-50-PAKPDF  TARGET-50-PAKRCC  TARGET-50-PAKRVH  TARGET-50-PAKRZW
                        TARGET-50-PAKSCC  TARGET-50-PAKSDG  TARGET-50-PAKUIT  TARGET-50-PAKULH  TARGET-50-PAKVET
                        TARGET-50-PAKWPM  TARGET-50-PAKXWB  TARGET-50-PAKXXF  TARGET-50-PAKYFC  TARGET-50-PAKYLT
                        TARGET-50-PAKZER  TARGET-50-PAKZFK  TARGET-50-PAKZHF  TARGET-50-PALDTE  TARGET-50-PALDWP
                        TARGET-50-PALERC  TARGET-50-PALEZT  TARGET-50-PALFME  TARGET-50-PALFRD  TARGET-50-PALGAZ
                        TARGET-50-PALGLU  TARGET-50-PALGVY  TARGET-50-PALJIP  TARGET-50-PALKCW  TARGET-50-PALKRS
                        TARGET-50-PALLCK  TARGET-50-PALLFB  
                    )],
                    'Validation' => [qw(
                        TARGET-50-CAAAAJ  TARGET-50-PACDYF  TARGET-50-PACFNR  TARGET-50-PADCRV  TARGET-50-PADDLL
                        TARGET-50-PADVNN  TARGET-50-PADWHM  TARGET-50-PADWKZ  TARGET-50-PADWMG  TARGET-50-PADWNP
                        TARGET-50-PADWUE  TARGET-50-PADWXC  TARGET-50-PADWYI  TARGET-50-PADWYJ  TARGET-50-PADWYZ
                        TARGET-50-PADXBA  TARGET-50-PADXBG  TARGET-50-PADXIP  TARGET-50-PADXJK  TARGET-50-PADXJZ
                        TARGET-50-PADXRC  TARGET-50-PADXUJ  TARGET-50-PADXWJ  TARGET-50-PADXYT  TARGET-50-PADYAS
                        TARGET-50-PADYGD  TARGET-50-PADYGE  TARGET-50-PADYHT  TARGET-50-PADYJI  TARGET-50-PADYPH
                        TARGET-50-PADYRW  TARGET-50-PADYUS  TARGET-50-PADYVH  TARGET-50-PADYWB  TARGET-50-PADYWT
                        TARGET-50-PADYYC  TARGET-50-PADZCH  TARGET-50-PADZNG  TARGET-50-PADZNH  TARGET-50-PADZPL
                        TARGET-50-PADZSS  TARGET-50-PADZTP  TARGET-50-PADZUD  TARGET-50-PAEAFZ  TARGET-50-PAEALI
                        TARGET-50-PAEALK  TARGET-50-PAEAMT  TARGET-50-PAEAND  TARGET-50-PAECFM  TARGET-50-PAECHG
                        TARGET-50-PAECIE  TARGET-50-PAECJY  TARGET-50-PAECPC  TARGET-50-PAECTY  TARGET-50-PAECWU
                        TARGET-50-PAEDJU  TARGET-50-PAEEPR  TARGET-50-PAEFPT  TARGET-50-PAEHDE  TARGET-50-PAEHHM
                        TARGET-50-PAEHLE  TARGET-50-PAEHLJ  TARGET-50-PAEIGE  TARGET-50-PAEIIW  TARGET-50-PAEIJB
                        TARGET-50-PAEJJR  TARGET-50-PAENVA  TARGET-50-PAERTC  TARGET-50-PAJLIH  TARGET-50-PAJLIJ
                        TARGET-50-PAJLIT  TARGET-50-PAJLJG  TARGET-50-PAJLJH  TARGET-50-PAJLJP  TARGET-50-PAJLKS
                        TARGET-50-PAJLLD  TARGET-50-PAJLLI  TARGET-50-PAJLLN  TARGET-50-PAJLLV  TARGET-50-PAJLLY
                        TARGET-50-PAJLMB  TARGET-50-PAJLMH  TARGET-50-PAJLMJ  TARGET-50-PAJLML  TARGET-50-PAJLMN
                        TARGET-50-PAJLMV  TARGET-50-PAJLMW  TARGET-50-PAJLNA  TARGET-50-PAJLNC  TARGET-50-PAJLND
                        TARGET-50-PAJLNX  TARGET-50-PAJLPD  TARGET-50-PAJLPJ  TARGET-50-PAJLPU  TARGET-50-PAJLPW
                        TARGET-50-PAJLRC  TARGET-50-PAJLRF  TARGET-50-PAJLRH  TARGET-50-PAJLRL  TARGET-50-PAJLRP
                        TARGET-50-PAJLRV  TARGET-50-PAJLSF  TARGET-50-PAJLSL  TARGET-50-PAJLSM  TARGET-50-PAJLSS
                        TARGET-50-PAJLST  TARGET-50-PAJLSV  TARGET-50-PAJLSW  TARGET-50-PAJLSY  TARGET-50-PAJLSZ
                        TARGET-50-PAJLTD  TARGET-50-PAJLTE  TARGET-50-PAJLTJ  TARGET-50-PAJLTL  TARGET-50-PAJLTU
                        TARGET-50-PAJLUB  TARGET-50-PAJLUI  TARGET-50-PAJLUM  TARGET-50-PAJLUW  TARGET-50-PAJLVB
                        TARGET-50-PAJLVI  TARGET-50-PAJLVL  TARGET-50-PAJLVS  TARGET-50-PAJLVV  TARGET-50-PAJLVX
                        TARGET-50-PAJLWA  TARGET-50-PAJLWC  TARGET-50-PAJLWG  TARGET-50-PAJLWI  TARGET-50-PAJLWR
                        TARGET-50-PAJLWW  TARGET-50-PAJLWX  TARGET-50-PAJLWZ  TARGET-50-PAJLXD  TARGET-50-PAJLXE
                        TARGET-50-PAJLXH  TARGET-50-PAJLXI  TARGET-50-PAJLXM  TARGET-50-PAJLYD  TARGET-50-PAJLYF
                        TARGET-50-PAJLYG  TARGET-50-PAJLYP  TARGET-50-PAJLZA  TARGET-50-PAJLZC  TARGET-50-PAJLZN
                        TARGET-50-PAJLZT  TARGET-50-PAJMAX  TARGET-50-PAJMBG  TARGET-50-PAJMBN  TARGET-50-PAJMBP
                        TARGET-50-PAJMBR  TARGET-50-PAJMBZ  TARGET-50-PAJMCB  TARGET-50-PAJMCH  TARGET-50-PAJMDF
                        TARGET-50-PAJMDL  TARGET-50-PAJMDP  TARGET-50-PAJMDU  TARGET-50-PAJMED  TARGET-50-PAJMEG
                        TARGET-50-PAJMEJ  TARGET-50-PAJMFP  TARGET-50-PAJMGI  TARGET-50-PAJMHV  TARGET-50-PAJMIB
                        TARGET-50-PAJMIE  TARGET-50-PAJMIP  TARGET-50-PAJMIY  TARGET-50-PAJMJB  TARGET-50-PAJMJL
                        TARGET-50-PAJMJM  TARGET-50-PAJMJR  TARGET-50-PAJMKD  TARGET-50-PAJMKK  TARGET-50-PAJMKP
                        TARGET-50-PAJMKT  TARGET-50-PAJMKV  TARGET-50-PAJMKW  TARGET-50-PAJMLS  TARGET-50-PAJMLW
                        TARGET-50-PAJMLY  TARGET-50-PAJMMC  TARGET-50-PAJMME  TARGET-50-PAJMMK  TARGET-50-PAJMMN
                        TARGET-50-PAJMMU  TARGET-50-PAJMMW  TARGET-50-PAJMMZ  TARGET-50-PAJMND  TARGET-50-PAJMNR
                        TARGET-50-PAJMNW  TARGET-50-PAJMNZ  TARGET-50-PAJMPG  TARGET-50-PAJMPH  TARGET-50-PAJMPL
                        TARGET-50-PAJMPP  TARGET-50-PAJMPR  TARGET-50-PAJMPV  TARGET-50-PAJMRH  TARGET-50-PAJMRK
                        TARGET-50-PAJMRS  TARGET-50-PAJMRT  TARGET-50-PAJMRX  TARGET-50-PAJMRY  TARGET-50-PAJMSK
                        TARGET-50-PAJMSR  TARGET-50-PAJMTR  TARGET-50-PAJMTS  TARGET-50-PAJMUE  TARGET-50-PAJMUI
                        TARGET-50-PAJMUM  TARGET-50-PAJMUS  TARGET-50-PAJMUY  TARGET-50-PAJMVD  TARGET-50-PAJMVG
                        TARGET-50-PAJMVI  TARGET-50-PAJMVJ  TARGET-50-PAJMVK  TARGET-50-PAJMVL  TARGET-50-PAJMVW
                        TARGET-50-PAJMVX  TARGET-50-PAJMWC  TARGET-50-PAJMWF  TARGET-50-PAJMWN  TARGET-50-PAJMWP
                        TARGET-50-PAJMWX  TARGET-50-PAJMWZ  TARGET-50-PAJMXE  TARGET-50-PAJMXK  TARGET-50-PAJMXP
                        TARGET-50-PAJMXR  TARGET-50-PAJMYA  TARGET-50-PAJMYM  TARGET-50-PAJMYU  TARGET-50-PAJMZF
                        TARGET-50-PAJMZI  TARGET-50-PAJMZN  TARGET-50-PAJMZV  TARGET-50-PAJNAM  TARGET-50-PAJNAP
                        TARGET-50-PAJNAU  TARGET-50-PAJNBA  TARGET-50-PAJNBE  TARGET-50-PAJNBG  TARGET-50-PAJNBI
                        TARGET-50-PAJNBP  TARGET-50-PAJNBS  TARGET-50-PAJNBU  TARGET-50-PAJNBW  TARGET-50-PAJNBZ
                        TARGET-50-PAJNCA  TARGET-50-PAJNCK  TARGET-50-PAJNCL  TARGET-50-PAJNCN  TARGET-50-PAJNCU
                        TARGET-50-PAJNCX  TARGET-50-PAJNDB  TARGET-50-PAJNDC  TARGET-50-PAJNDS  TARGET-50-PAJNDX
                        TARGET-50-PAJNEB  TARGET-50-PAJNEE  TARGET-50-PAJNEH  TARGET-50-PAJNEL  TARGET-50-PAJNEX
                        TARGET-50-PAJNFB  TARGET-50-PAJNFD  TARGET-50-PAJNFH  TARGET-50-PAJNGA  TARGET-50-PAJNGB
                        TARGET-50-PAJNGC  TARGET-50-PAJNGJ  TARGET-50-PAJNGK  TARGET-50-PAJNGR  TARGET-50-PAJNGU
                        TARGET-50-PAJNHA  TARGET-50-PAJNHG  TARGET-50-PAJNHL  TARGET-50-PAJNHN  TARGET-50-PAJNHP
                        TARGET-50-PAJNHV  TARGET-50-PAJNHW  TARGET-50-PAJNHZ  TARGET-50-PAJNID  TARGET-50-PAJNIE
                        TARGET-50-PAJNIH  TARGET-50-PAJNIJ  TARGET-50-PAJNIM  TARGET-50-PAJNIS  TARGET-50-PAJNIY
                        TARGET-50-PAJNJC  TARGET-50-PAJNJL  TARGET-50-PAJNKA  TARGET-50-PAJNKD  TARGET-50-PAJNKJ
                        TARGET-50-PAJNKL  TARGET-50-PAJNKP  TARGET-50-PAJNKS  TARGET-50-PAJNKX  TARGET-50-PAJNLA
                        TARGET-50-PAJNLK  TARGET-50-PAJNLR  TARGET-50-PAJNLS  TARGET-50-PAJNMA  TARGET-50-PAJNMD
                        TARGET-50-PAJNME  TARGET-50-PAJNML  TARGET-50-PAJNMT  TARGET-50-PAJNMV  TARGET-50-PAJNMZ
                        TARGET-50-PAJNND  TARGET-50-PAJNNF  TARGET-50-PAJNNG  TARGET-50-PAJNNT  TARGET-50-PAJNNU
                        TARGET-50-PAJNNV  TARGET-50-PAJNNY  TARGET-50-PAJNPI  TARGET-50-PAJNPS  TARGET-50-PAJNPW
                        TARGET-50-PAJNPX  TARGET-50-PAJNPZ  TARGET-50-PAJNRE  TARGET-50-PAJNRK  TARGET-50-PAJNRW
                        TARGET-50-PAJNSB  TARGET-50-PAJNSF  TARGET-50-PAJNSI  TARGET-50-PAJNSK  TARGET-50-PAJNSV
                        TARGET-50-PAJNTM  TARGET-50-PAJNUJ  TARGET-50-PAJNUT  TARGET-50-PAJNUX  TARGET-50-PAJNVA
                        TARGET-50-PAJNVB  TARGET-50-PAJNVF  TARGET-50-PAJNVL  TARGET-50-PAJNVW  TARGET-50-PAJNWA
                        TARGET-50-PAJNWD  TARGET-50-PAJNWE  TARGET-50-PAJNWH  TARGET-50-PAJNWK  TARGET-50-PAJNWR
                        TARGET-50-PAJNWU  TARGET-50-PAJNWX  TARGET-50-PAJNWZ  TARGET-50-PAJNXB  TARGET-50-PAJNXC
                        TARGET-50-PAJNXG  TARGET-50-PAJNXI  TARGET-50-PAJNXR  TARGET-50-PAJNXS  TARGET-50-PAJNXT
                        TARGET-50-PAJNYM  TARGET-50-PAJNYX  TARGET-50-PAJNZY  TARGET-50-PAJNZZ  TARGET-50-PAJPAD
                        TARGET-50-PAJPAG  TARGET-50-PAJPAH  TARGET-50-PAJPAX  TARGET-50-PAJPBD  TARGET-50-PAJPBG
                        TARGET-50-PAJPBR  TARGET-50-PAJPBZ  TARGET-50-PAJPCF  TARGET-50-PAJPCN  TARGET-50-PAJPCV
                        TARGET-50-PAJPCX  TARGET-50-PAJPDF  TARGET-50-PAJPDX  TARGET-50-PAJPEA  TARGET-50-PAJPEF
                        TARGET-50-PAJPEJ  TARGET-50-PAJPEP  TARGET-50-PAJPER  TARGET-50-PAJPET  TARGET-50-PAJPEY
                        TARGET-50-PAJPFC  TARGET-50-PAJPFF  TARGET-50-PAJPFJ  TARGET-50-PAJPFK  TARGET-50-PAJPFN
                        TARGET-50-PAJPFR  TARGET-50-PAJPFY  TARGET-50-PAJPGA  TARGET-50-PAJPGF  TARGET-50-PAJPGM
                        TARGET-50-PAJPGP  TARGET-50-PAJPGU  TARGET-50-PAJPHG  TARGET-50-PAJPHH  TARGET-50-PAKAPI
                        TARGET-50-PAKAPZ  TARGET-50-PAKDUM  TARGET-50-PAKEMV  TARGET-50-PAKFRI  TARGET-50-PAKFTB
                        TARGET-50-PAKFZA  TARGET-50-PAKGDL  TARGET-50-PAKGHT  TARGET-50-PAKGJK  TARGET-50-PAKGMM
                        TARGET-50-PAKGRG  TARGET-50-PAKGUP  TARGET-50-PAKGWP  TARGET-50-PAKGXL  TARGET-50-PAKGZY
                        TARGET-50-PAKHBL  TARGET-50-PAKHFY  TARGET-50-PAKHIU  TARGET-50-PAKHKU  TARGET-50-PAKHMM
                        TARGET-50-PAKHNC  TARGET-50-PAKHNH  TARGET-50-PAKHWF  TARGET-50-PAKHWZ  TARGET-50-PAKHYJ
                        TARGET-50-PAKIDV  TARGET-50-PAKILU  TARGET-50-PAKIRF  TARGET-50-PAKISF  TARGET-50-PAKIZP
                        TARGET-50-PAKJHT  TARGET-50-PAKJIS  TARGET-50-PAKJJF  TARGET-50-PAKJKT  TARGET-50-PAKJVW
                        TARGET-50-PAKJXM  TARGET-50-PAKJZU  TARGET-50-PAKKAE  TARGET-50-PAKKJB  TARGET-50-PAKKRK
                        TARGET-50-PAKKSG  TARGET-50-PAKKSI  TARGET-50-PAKKZG  TARGET-50-PAKLDH  TARGET-50-PAKLRS
                        TARGET-50-PAKLRW  TARGET-50-PAKLYC  TARGET-50-PAKLZH  TARGET-50-PAKMAV  TARGET-50-PAKMCI
                        TARGET-50-PAKMDF  TARGET-50-PAKMDX  TARGET-50-PAKMGV  TARGET-50-PAKMHJ  TARGET-50-PAKMKW
                        TARGET-50-PAKMLA  TARGET-50-PAKMMS  TARGET-50-PAKMTZ  TARGET-50-PAKMZU  TARGET-50-PAKNFF
                        TARGET-50-PAKNGF  TARGET-50-PAKNSG  TARGET-50-PAKNUD  TARGET-50-PAKPET  TARGET-50-PAKPEU
                        TARGET-50-PAKPIJ  TARGET-50-PAKPRZ  TARGET-50-PAKPTZ  TARGET-50-PAKRRF  TARGET-50-PAKRVV
                        TARGET-50-PAKRYJ  TARGET-50-PAKSJN  TARGET-50-PAKSRE  TARGET-50-PAKTCE  TARGET-50-PAKTLC
                        TARGET-50-PAKTRB  TARGET-50-PAKUCW  TARGET-50-PAKUJY  TARGET-50-PAKUMS  TARGET-50-PAKVJN
                        TARGET-50-PAKVXE  TARGET-50-PAKVXU  TARGET-50-PAKWCB  TARGET-50-PAKWDE  TARGET-50-PAKWVW
                        TARGET-50-PAKWZR  TARGET-50-PAKXFS  TARGET-50-PAKXSD  TARGET-50-PAKXSE  TARGET-50-PAKYCN
                        TARGET-50-PAKYFF  TARGET-50-PAKYGM  TARGET-50-PAKYJS  TARGET-50-PAKYNK  TARGET-50-PAKYNT
                        TARGET-50-PAKYPP  TARGET-50-PAKYXG  TARGET-50-PAKZGW  TARGET-50-PAKZHG  TARGET-50-PAKZMW
                        TARGET-50-PALAXJ  TARGET-50-PALBRC  TARGET-50-PALCAB  TARGET-50-PALCMK  TARGET-50-PALCPP
                        TARGET-50-PALCTR  TARGET-50-PALCVC  TARGET-50-PALDAF  TARGET-50-PALDEU  TARGET-50-PALDND
                        TARGET-50-PALDNR  TARGET-50-PALDWR  TARGET-50-PALDYU  TARGET-50-PALEBJ  TARGET-50-PALEFG
                        TARGET-50-PALEHA  TARGET-50-PALEJW  TARGET-50-PALEWU  TARGET-50-PALEZR  TARGET-50-PALFGK
                        TARGET-50-PALFJK  TARGET-50-PALFJZ  TARGET-50-PALFYP  TARGET-50-PALGMA  TARGET-50-PALGWU
                        TARGET-50-PALHNG  TARGET-50-PALIMN  TARGET-50-PALJDK  TARGET-50-PALJHR  TARGET-50-PALKAW
                        TARGET-50-PALKJY  TARGET-50-PALKNP  TARGET-50-PALKUD  TARGET-50-PALKWP  TARGET-50-PALLCW
                        TARGET-50-PALLFV  TARGET-50-PALLMF  TARGET-50-PALMAM  TARGET-50-PALMHS  TARGET-50-PALMII
                        TARGET-50-PALMPF  TARGET-50-PALMSA  TARGET-50-PALNDB  
                    )],
                },
                'alt_id_by_case' => {
                    'TARGET-50-CAAAAA' => 'TARGET-50-PAHYBE',
                    'TARGET-50-CAAAAB' => 'TARGET-50-PAIMXD',
                    'TARGET-50-CAAAAC' => 'TARGET-50-PADWYI',
                    'TARGET-50-CAAAAH' => 'TARGET-50-PAHZZL',
                    'TARGET-50-CAAAAJ' => 'TARGET-50-PADWMG',
                    'TARGET-50-CAAAAL' => 'TARGET-50-PADXUJ',
                    'TARGET-50-CAAAAM' => 'TARGET-50-PADYGU',
                    'TARGET-50-CAAAAO' => 'TARGET-50-PACDYF',
                    'TARGET-50-CAAAAP' => 'TARGET-50-PAEHHM',
                    'TARGET-50-CAAAAQ' => 'TARGET-50-PAERTC',
                    'TARGET-50-CAAAAR' => 'TARGET-50-PAJNPS',
                    'TARGET-50-CAAAAS' => 'TARGET-50-PAKGHT',
                },
            },
        },
        'CGCI' => {
            'BLGSP' => {
                'dbGaP_study_ids' => [qw(
                    phs000527
                )],
            },
            'HTMCP-CC' => {
                'dbGaP_study_ids' => [qw(
                    phs000528
                )],
            },
            'HTMCP-DLBCL' => {
                'dbGaP_study_ids' => [qw(
                    phs000529
                )],
            },
            'HTMCP-LC' => {
                'dbGaP_study_ids' => [qw(
                    phs000530
                )],
            },
            'MB' => {
                'dbGaP_study_ids' => [qw(
                    phs000531
                )],
            },
            'NHL' => {
                'dbGaP_study_ids' => [qw(
                    phs000532
                )],
                'sample_info_by_old_id' => {
                    'A01413' => {
                        'case_id'     => '05-25439',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01414' => {
                        'case_id'     => '05-32947',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01415' => {
                        'case_id'     => '06-11535',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01416' => {
                        'case_id'     => '06-22057',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01417' => {
                        'case_id'     => '05-24395',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01418' => {
                        'case_id'     => '06-19919',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01419' => {
                        'case_id'     => '06-24915',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01420' => {
                        'case_id'     => '06-30145',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01421' => {
                        'case_id'     => '06-10398',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01422' => {
                        'case_id'     => '05-24904',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01423' => {
                        'case_id'     => '81-52884',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01424' => {
                        'case_id'     => '05-25674',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01425' => {
                        'case_id'     => '02-20170',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01426' => {
                        'case_id'     => '05-12939',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01427' => {
                        'case_id'     => '99-27137',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01428' => {
                        'case_id'     => '09-41082',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01429' => {
                        'case_id'     => '07-25012',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01430' => {
                        'case_id'     => '06-33777',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01431' => {
                        'case_id'     => '08-25894',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01432' => {
                        'case_id'     => '07-25012',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01433' => {
                        'case_id'     => '06-33777',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01434' => {
                        'case_id'     => '06-15256',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01435' => {
                        'case_id'     => '06-25674',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01436' => {
                        'case_id'     => '06-15256',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01437' => {
                        'case_id'     => '05-25439',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01438' => {
                        'case_id'     => '06-30025',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01439' => {
                        'case_id'     => '06-11535',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01440' => {
                        'case_id'     => '06-24915',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01441' => {
                        'case_id'     => '06-30145',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01442' => {
                        'case_id'     => '06-10398',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01443' => {
                        'case_id'     => '05-32947',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01444' => {
                        'case_id'     => '05-24395',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01445' => {
                        'case_id'     => '05-25674',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01446' => {
                        'case_id'     => '81-52884',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01447' => {
                        'case_id'     => '06-19919',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01448' => {
                        'case_id'     => '08-25894',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01449' => {
                        'case_id'     => '99-27137',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01450' => {
                        'case_id'     => '02-20170',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01451' => {
                        'case_id'     => '06-25674',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01452' => {
                        'case_id'     => '06-22057',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01453' => {
                        'case_id'     => '05-12939',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01454' => {
                        'case_id'     => '09-41082',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01455' => {
                        'case_id'     => '05-24904',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01456' => {
                        'case_id'     => '04-29264',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01457' => {
                        'case_id'     => '06-34043',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01458' => {
                        'case_id'     => '04-29264',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01459' => {
                        'case_id'     => '06-34043',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01460' => {
                        'case_id'     => '07-17613',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01462' => {
                        'case_id'     => '06-30025',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01677' => {
                        'case_id'     => '07-17613',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01971' => {
                        'case_id'     => '05-24006',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01972' => {
                        'case_id'     => '06-16716',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A01973' => {
                        'case_id'     => '06-16716',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A01974' => {
                        'case_id'     => '05-24006',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A02010' => {
                        'case_id'     => '06-23907',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A02011' => {
                        'case_id'     => '06-23907',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A03290' => {
                        'case_id'     => '06-14634',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A03291' => {
                        'case_id'     => '06-14634',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A03561' => {
                        'case_id'     => '03-10363',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A03586' => {
                        'case_id'     => '03-10363',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A06417' => {
                        'case_id'     => '95-32814',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A06418' => {
                        'case_id'     => '05-24561',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A06419' => {
                        'case_id'     => '09-12737',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A06420' => {
                        'case_id'     => '95-32814',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A06421' => {
                        'case_id'     => '05-24561',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A06422' => {
                        'case_id'     => '09-12737',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'A06720' => {
                        'case_id'     => '07-30628',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'A06721' => {
                        'case_id'     => '07-30628',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'AM_1' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'AM_2' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'AM_3' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'AM_4' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'AM_5' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'AM_6' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'AM_7' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'AM_8' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'AM_9' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'AM_10' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'AM_11' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'AM_12' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'AM_13' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Cell Line',
                    },
                    'HS0637' => {
                        'case_id'     => '05-25439',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0639' => {
                        'case_id'     => '02-30647',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0640' => {
                        'case_id'     => '04-11156',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0641' => {
                        'case_id'     => '03-31713',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0644' => {
                        'case_id'     => '03-33266',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0645' => {
                        'case_id'     => '02-30519',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0646' => {
                        'case_id'     => '04-23426',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0647' => {
                        'case_id'     => '98-22532',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0648' => {
                        'case_id'     => '05-32947',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0649' => {
                        'case_id'     => '04-39108',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0650' => {
                        'case_id'     => '05-26084',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0651' => {
                        'case_id'     => '06-25470',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0652' => {
                        'case_id'     => '06-27347',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0653' => {
                        'case_id'     => '06-30025',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0654' => {
                        'case_id'     => '06-31353',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0656' => {
                        'case_id'     => '07-35482',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0685' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => '',
                    },
                    'HS0747' => {
                        'case_id'     => '07-31833',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0748' => {
                        'case_id'     => '05-20543',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0749' => {
                        'case_id'     => '05-24666',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0750' => {
                        'case_id'     => '99-25549',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0751' => {
                        'case_id'     => '05-19287',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0798' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => '',
                    },
                    'HS0804' => {
                        'case_id'     => '06-12968',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0821' => {
                        'case_id'     => '06-12968',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0841' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => '',
                    },
                    'HS0842' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => '',
                    },
                    'HS0896' => {
                        'case_id'     => '06-12968',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0900' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => '',
                    },
                    'HS0901' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => '',
                    },
                    'HS0926' => {
                        'case_id'     => '06-11535',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0927' => {
                        'case_id'     => '06-16316',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0928' => {
                        'case_id'     => '06-22057',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0929' => {
                        'case_id'     => '06-23792',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0930' => {
                        'case_id'     => '95-32814',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0931' => {
                        'case_id'     => '01-26405',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0932' => {
                        'case_id'     => '03-10363',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0933' => {
                        'case_id'     => '03-13123',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0934' => {
                        'case_id'     => '05-24395',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0935' => {
                        'case_id'     => '08-21175',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0936' => {
                        'case_id'     => '06-19919',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0937' => {
                        'case_id'     => '05-24561',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0938' => {
                        'case_id'     => '06-15922',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0939' => {
                        'case_id'     => '06-24881',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0940' => {
                        'case_id'     => '04-10134',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0941' => {
                        'case_id'     => '00-26427',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0942' => {
                        'case_id'     => '96-20883',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0943' => {
                        'case_id'     => '02-22991',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS0944' => {
                        'case_id'     => '05-17793',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1131' => {
                        'case_id'     => '03-30438',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1132' => {
                        'case_id'     => '94-26795',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1133' => {
                        'case_id'     => '05-23110',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1134' => {
                        'case_id'     => '06-24915',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1135' => {
                        'case_id'     => '07-37968',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1136' => {
                        'case_id'     => '08-15460',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1137' => {
                        'case_id'     => '01-19969',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1138' => {
                        'case_id'     => '01-26579',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1163' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => '',
                    },
                    'HS1164' => {
                        'case_id'     => '01-18667',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1181' => {
                        'case_id'     => '05-24401',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1182' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => '',
                    },
                    'HS1183' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => '',
                    },
                    'HS1184' => {
                        'case_id'     => '05-12472',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1185' => {
                        'case_id'     => '05-14720',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1186' => {
                        'case_id'     => '05-14545',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1199' => {
                        'case_id'     => '05-19843',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1200' => {
                        'case_id'     => '03-10481',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1201' => {
                        'case_id'     => '04-28117',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1202' => {
                        'case_id'     => '07-21038',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1203' => {
                        'case_id'     => '08-10448',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1204' => {
                        'case_id'     => '06-28477',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1205' => {
                        'case_id'     => '01-16433',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1350' => {
                        'case_id'     => '06-24718',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1352' => {
                        'case_id'     => '06-10398',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1356' => {
                        'case_id'     => '02-22023',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1358' => {
                        'case_id'     => '05-24904',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1360' => {
                        'case_id'     => '92-33015',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1361' => {
                        'case_id'     => '03-28399',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1452' => {
                        'case_id'     => '92-56188',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1454' => {
                        'case_id'     => '03-30549',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1456' => {
                        'case_id'     => '03-31974',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1458' => {
                        'case_id'     => '81-52884',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1460' => {
                        'case_id'     => '05-24006',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1462' => {
                        'case_id'     => '05-25674',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1555' => {
                        'case_id'     => '05-11328',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1556' => {
                        'case_id'     => '06-30145',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1557' => {
                        'case_id'     => '02-13818',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1558' => {
                        'case_id'     => '01-25197',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1559' => {
                        'case_id'     => '02-20170',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1786' => {
                        'case_id'     => '04-11156',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'HS1787' => {
                        'case_id'     => '04-11156',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1788' => {
                        'case_id'     => '08-15460',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'HS1789' => {
                        'case_id'     => '08-15460',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1843' => {
                        'case_id'     => '06-12968',
                        'disease'     => 'FL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1846' => {
                        'case_id'     => '06-12968',
                        'disease'     => 'FL',
                        'tissue_type' => 'Normal',
                    },
                    'HS1974' => {
                        'case_id'     => '97-14402',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1975' => {
                        'case_id'     => '06-16716',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1976' => {
                        'case_id'     => '06-23057',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1977' => {
                        'case_id'     => '02-24725',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1978' => {
                        'case_id'     => '09-12737',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1979' => {
                        'case_id'     => '01-12047',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1980' => {
                        'case_id'     => '01-21689',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1981' => {
                        'case_id'     => '08-15393',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1982' => {
                        'case_id'     => '08-15577',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1983' => {
                        'case_id'     => '03-26817',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS1984' => {
                        'case_id'     => '85-63855',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2047' => {
                        'case_id'     => '',
                        'disease'     => 'DLBCL',
                        'tissue_type' => '',
                    },
                    'HS2048' => {
                        'case_id'     => '05-12939',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2049' => {
                        'case_id'     => '07-32561',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2050' => {
                        'case_id'     => '99-27137',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2051' => {
                        'case_id'     => '09-33003',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2053' => {
                        'case_id'     => '82-57570',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2054' => {
                        'case_id'     => '05-12224',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2055' => {
                        'case_id'     => '07-30109',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2056' => {
                        'case_id'     => 'SPEC-1120',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2058' => {
                        'case_id'     => 'SPEC-1185',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2059' => {
                        'case_id'     => 'SPEC-1187',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2060' => {
                        'case_id'     => 'SPEC-1203',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2248' => {
                        'case_id'     => '09-41082',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2249' => {
                        'case_id'     => '00-15694',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2250' => {
                        'case_id'     => '07-25012',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2251' => {
                        'case_id'     => '06-33777',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2252' => {
                        'case_id'     => '08-25894',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2604' => {
                        'case_id'     => '05-15797',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2605' => {
                        'case_id'     => '06-15256',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2606' => {
                        'case_id'     => '08-11596',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2607' => {
                        'case_id'     => '06-25674',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2702' => {
                        'case_id'     => '98-22532',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2703' => {
                        'case_id'     => '98-22532',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'HS2704' => {
                        'case_id'     => '07-35482',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2705' => {
                        'case_id'     => '07-35482',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'HS2706' => {
                        'case_id'     => '05-23110',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2707' => {
                        'case_id'     => '05-23110',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'HS2937' => {
                        'case_id'     => '06-34043',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2938' => {
                        'case_id'     => '04-20644',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2939' => {
                        'case_id'     => '04-36422',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2940' => {
                        'case_id'     => '06-18547',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2970' => {
                        'case_id'     => '02-22991',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2971' => {
                        'case_id'     => '02-22991',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'HS2972' => {
                        'case_id'     => '08-15460',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2973' => {
                        'case_id'     => '08-15460',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'HS2974' => {
                        'case_id'     => '09-33003',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS2975' => {
                        'case_id'     => '09-33003',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Normal',
                    },
                    'HS3014' => {
                        'case_id'     => '07-17613',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS3105' => {
                        'case_id'     => '06-14634',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS3120' => {
                        'case_id'     => '04-29264',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS3129' => {
                        'case_id'     => '06-23907',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    },
                    'HS3136' => {
                        'case_id'     => '07-30628',
                        'disease'     => 'DLBCL',
                        'tissue_type' => 'Tumor',
                    }
                },
            },
        },
    },
    'dataset' => {
        'TARGET' => {
            'ALL' => {
                'miRNA-seq' => {
                    'Phase2' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:RNA-Extraction-TRIzol:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:miRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                        },
                    },
                    'Phase3' => {
                        'idf' => {
                            'investigation_title' => 'TARGET: Ambiguous Lineage Acute Leukemia (ALAL) Phase III miRNA-seq',
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'stjude.org:Protocol:RNA-Extraction-TRIzol:01',
                                    },
                                },
                                'center_name' => 'StJude',
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:miRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                'mRNA-seq' => {
                    'Phase1' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'stjude.org:Protocol:RNA-Extraction-TRIzol:01',
                                    },
                                },
                                'center_name' => 'StJude',
                            },
                            'LibraryPrep' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-LibraryPrep-Illumina-Unstranded:01',
                                        },
                                    },
                                },
                                'StJude' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'stjude.org:Protocol:mRNAseq-LibraryPrep-Illumina-Unstranded:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_incl_design_desc_protocol' => [
                            'BCCA',
                            'StJude',
                        ],
                    },
                    'Phase2' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Xiaotu',
                                    'mid_initials' => '',
                                    'email' => 'xiaotu.ma@stjude.org',
                                    'phone' => '+1 901 595 3774',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Zhang',
                                    'first_name' => 'Jinghui',
                                    'mid_initials' => '',
                                    'email' => 'jinghui.zhang@stjude.org',
                                    'phone' => '+1 901 595 6829',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                    ],
                                },
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:RNA-Extraction-TRIzol:01',
                                    },
                                },
                                'center_name' => 'NCH',
                            },
                            'LibraryPrep' => {
                                'BCCA' => {
                                    'filter' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-LibraryPrep-Illumina-rRnaDepleted-StrandSpecific:01',
                                        },
                                    # input library names below when known from SRA
                                        'library_names' => [qw(
                                            A61061  A61062  A61063  A61064  A61065  A61066  A61067
					    A61068  A61069  A61070  A61071  A61072  A61073  A61074
                                        )],
                                    },
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-LibraryPrep-Illumina-StrandSpecific:01',
                                        },
                                    },
                                },
                                'StJude' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'stjude.org:Protocol:mRNAseq-LibraryPrep-Illumina-StrandSpecific:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                            'Fusion' => {
                                'StJude' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'stjude.org:Protocol:mRNAseq-Fusion-StrongArm-CICERO:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_ids_excl' => [qw(
                            SRX2239275  SRX2239292
                        )],
                        'exp_centers_incl_design_desc_protocol' => [
                            'StJude',
                        ],
                        'exp_center_library_data_qc_warning' => {
                            'BCCA' => {
                                'A32612' => 'HIGH NON-GENIC CONTENT (exon-intron ratio < 1)',
                                'A32616' => 'LOW SEQUENCE YIELD/DIVERSITY (chastity passed bases < 5Gb, genes detected < 17000)',
                                'A32620' => 'HIGH NON-GENIC CONTENT (exon-intron ratio < 1)',
                                'A32629' => 'LOW 5\'/3\'COVERAGE RATIO (genes with even 5\'/3\' coverage < 50%)',
                                'A32635' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 30%)',
                                'A32661' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 30%)',
                                'A32663' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 30%)',
                                'A32705' => 'LOW 5\'/3\'COVERAGE RATIO (genes with even 5\'/3\' coverage < 50%)',
                                'A32717' => 'LOW 5\'/3\'COVERAGE RATIO (genes with even 5\'/3\' coverage < 50%)',
                                'A32722' => 'HIGH NON-GENIC CONTENT (genes detected > 35000, intergenic reads > 15%)',
                                'A32724' => 'HIGH NON-GENIC CONTENT (genes detected > 35000, exon-intron ratio < 1, intergenic reads > 15%)',
                                'A32734' => 'HIGH NON-GENIC CONTENT (genes detected > 35000, exon-intron ratio < 1, intergenic reads > 15%)',
                                'A32740' => 'HIGH NON-GENIC CONTENT (exon-intron ratio < 1)',
                                'A32760' => 'LOW SEQUENCE YIELD/DIVERSITY (chastity passed bases  < 5Gb, genes detected < 17000)',
                                'A32763' => 'LOW SEQUENCE YIELD/DIVERSITY (genes detected < 17000)',
                                'A32764' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 30%)',
                                'A32765' => 'LOW SEQUENCE YIELD/DIVERSITY (genes detected < 17000)',
                                'A32774' => 'HIGH NON-GENIC CONTENT (gene with 1-5x coverage > 55%, intergenic reads > 15%)',
                                'A33584' => 'HIGH NON-GENIC CONTENT (genes detected > 35000, gene with 1-5x coverage > 55%, exon-intron ratio < 1, intergenic reads > 15%)',
                                'A33596' => 'LOW SEQUENCE YIELD/DIVERSITY (genes detected < 17000)',
                                'A33603' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 30%)',
                                'A33618' => 'HIGH NON-GENIC CONTENT (intergenic reads > 15%)',
                                'A33621' => 'LOW SEQUENCE YIELD/DIVERSITY (chastity passed bases  < 5Gb)',
                                'A33622' => 'HIGH NON-GENIC CONTENT (exon-intron ratio < 1, intergenic reads > 15%)',
                                'A33626' => 'HIGH NON-GENIC CONTENT (intergenic reads > 15%)',
                                'A33628' => 'HIGH NON-GENIC CONTENT (intergenic reads > 15%)',
                            },
                        },
                        'parse_files' => {
                            'L3' => [
                                'mutation/StJude/stjude.org_TARGET_TALL_mRNA-seq_IlluminaHiSeq_somatic.maf.txt',
                            ],
                        },
                        'sdrf_dag_info' => {
                            '_default' => {
                                'StJude' => {
                                    'StJude' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'stjude.org_TARGET_TALL_mRNA-seq_IlluminaHiSeq_somatic.maf.txt',
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                    'Phase3' => {
                        'idf' => {
                            'investigation_title' => 'TARGET: Ambiguous Lineage Acute Leukemia (ALAL)  Phase III mRNA-seq',
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'stjude.org:Protocol:RNA-Extraction-TRIzol:01',
                                    },
                                },
                                'center_name' => 'StJude',
                            },
                            'LibraryPrep' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-LibraryPrep-Illumina-rRnaDepleted-StrandSpecific:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                            'StructVariant-TransABySS' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-StructVariant-TransABySS:02',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_ids_excl' => [qw(
                            SRX547672
                        )],
                    },
                },
                'WGS' => {
                    'Phase1+2' => {
                        'idf' => {
                            'investigation_title' => 'TARGET: Acute Lymphoblastic Leukemia (ALL) Phase I/II WGS',
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Xiaotu',
                                    'email' => 'xiaotu.ma@stjude.org',
                                    'phone' => '+1 901 595 3774',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Zhang',
                                    'first_name' => 'Jinghui',
                                    'email' => 'jinghui.zhang@stjude.org',
                                    'phone' => '+1 901 595 6829',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                    ],
                                },
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                            'merge_idf_row_names' => [
                                'Experiment Description',
                                'Comment[SRA_STUDY]',
                                'Comment[BioProject]',
                                'Comment[dbGaP Study]',
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-QIAamp:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WGS-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                                'CGI' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'completegenomics.com:Protocol:WGS-ReadAlign-CGI:01',
                                        },
                                    },
                                },
                            },
                        },
                        'sdrf_incl_dbgap_study' => 1,
                        'exp_ids_excl' => [qw(
                            SRX2241842  SRX2241919  SRX2241922  SRX2241865
                        )],
                        'exp_centers_excl_exp_desc' => [
                            'BCCA',
                        ],
                        'exp_center_library_data_qc_warning' => {
                            'BCCA' => {
                                'HS2773' => 
                                    'While analyzing this WGS library for subclonal mutations, we discovered that this sample has been contaminated (most likely during ' .
                                    'library construction) with a significant amount of DNA from another patient in the study (TARGET-10-PALJDL-03A-01D). We determined ' .
                                    'that the contaminating DNA is likely from the malignant cells of the other patient as sequences corresponding to polymorphisms and ' .
                                    'somatic mutations in the contaminating patient\'s genome can be detected. Based on the mean level of read support for variants unique ' .
                                    'to the contaminating patient\'s genome, we estimate the amount of contamination to be 20-30%. Despite this contamination, we had ' .
                                    'sufficient power to detect clonal somatic mutations in the genome of this patient as described in Roberts et al, 2012.',
                            },
                        },
                    },
                    'Phase3' => {
                        'idf' => {
                            'investigation_title' => 'TARGET: Ambiguous Lineage Acute Leukemia (ALAL) Phase III WGS',
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'stjude.org:Protocol:DNA-Extraction-Qiagen-QIAamp:01',
                                    },
                                    'center_name' => 'StJude',
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WGS-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                            'StructVariant-ABySS' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WGS-StructVariant-ABySS:02',
                                        },
                                    },
                                },
                            },
                        },
                        #'exp_centers_excl_exp_desc' => [
                        #    'BCCA',
                        #],
                        'exp_ids_excl' => [qw(
                            SRX159555  SRX159556
                        )],
                    },
                },
                'WXS' => {
                    'Phase2' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Xiaotu',
                                    'mid_initials' => '',
                                    'email' => 'xiaotu.ma@stjude.org',
                                    'phone' => '+1 901 595 3774',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Zhang',
                                    'first_name' => 'Jinghui',
                                    'mid_initials' => '',
                                    'email' => 'jinghui.zhang@stjude.org',
                                    'phone' => '+1 901 595 6829',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-QIAamp:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ExomeCapture' => {
                                'BCG-Danvers' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'beckmangenomics.com:Protocol:WXS-ExomeCapture-Agilent-SureSelectHumanAllExonV5:01',
                                        },
                                    },
                                },
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-ExomeCapture-NimbleGen-SeqCapEZHumanExomeV2:01',
                                        },
                                    },
                                },
                                'StJude' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'stjude.org:Protocol:WXS-ExomeCapture-Illumina-NexteraRapidCaptureExome:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-ReadAlign-BWA-GATK:01',
                                        },
                                    },
                                },
                            },
                        },
                        'parse_files' => {
                            'L3' => [
                                'mutation/BCM/Germline/target-all-hg19-germline.mafplus.txt',
                                'mutation/BCM/CandidateSomatic/target-all-primary-somatic-v2.4-mafplus.xlsx',
                                'mutation/BCM/CandidateSomatic/target-all-recurrent-somatic-v2.4-mafplus.xlsx',
                                'mutation/BCM/VerifiedSomatic/target-all-primary-somatic-verified-v2.4-mafplus.xlsx',
                                'mutation/BCM/VerifiedSomatic/target-all-recurrent-somatic-verified-v2.4-mafplus.xlsx',
                                'mutation/StJude/CandidateSomatic/TARGET_ALLP2_WXS_Illumina_somatic.maf.txt',
                                'mutation/StJude/VerifiedSomatic/TARGET_ALLP2_WXS_Illumina_somatic_verified.maf.txt',
                                'mutation/StJude/CandidateSomatic/stjude.org_TARGET_BALL_WXS_Diagnosis_IlluminaHiSeq_somatic.maf.txt',
                                'mutation/StJude/CandidateSomatic/stjude.org_TARGET_BALL_WXS_Relapse_IlluminaHiSeq_somatic.maf.txt',
                                'mutation/StJude/CandidateSomatic/stjude.org_TARGET_TALL_WXS_Diagnosis_IlluminaHiSeq_somatic.maf.txt',
                            ],
                        },
                        'sdrf_dag_info' => {
                            '_default' => {
                                'BCM' => {
                                    'BCM' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall-AtlasPindel' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-all-hg19-germline.mafplus.txt',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-all-primary-somatic-v2.4-mafplus.xlsx',
                                                        'protocol_data_by_type' => {
                                                            'FilterVerified' => {
                                                                'file_data' => [
                                                                    {
                                                                        'data_level' => '3',
                                                                        'file_name' => 'target-all-primary-somatic-verified-v2.4-mafplus.xlsx',
                                                                    },
                                                                ],
                                                            },
                                                        },
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-all-recurrent-somatic-v2.4-mafplus.xlsx',
                                                        'protocol_data_by_type' => {
                                                            'FilterVerified' => {
                                                                'file_data' => [
                                                                    {
                                                                        'data_level' => '3',
                                                                        'file_name' => 'target-all-recurrent-somatic-verified-v2.4-mafplus.xlsx',
                                                                    },
                                                                ],
                                                            },
                                                        },
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                    'StJude' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'TARGET_ALLP2_WXS_Illumina_somatic.maf.txt',
                                                        'protocol_data_by_type' => {
                                                            'FilterVerified' => {
                                                                'file_data' => [
                                                                    {
                                                                        'data_level' => '3',
                                                                        'file_name' => 'TARGET_ALLP2_WXS_Illumina_somatic_verified.maf.txt',
                                                                    },
                                                                ],
                                                            },
                                                        },
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                },
                                '_default' => {
                                    'StJude' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall-Bambino-DToxoG' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'stjude.org_TARGET_BALL_WXS_Diagnosis_IlluminaHiSeq_somatic.maf.txt',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'stjude.org_TARGET_BALL_WXS_Relapse_IlluminaHiSeq_somatic.maf.txt',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'stjude.org_TARGET_TALL_WXS_Diagnosis_IlluminaHiSeq_somatic.maf.txt',
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                    'Phase3' => {
                        'idf' => {
                            'investigation_title' => 'TARGET: Ambiguous Lineage Acute Leukemia (ALAL) Phase III WXS',
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'stjude.org:Protocol:DNA-Extraction-Qiagen-QIAamp:01',
                                    },
                                    'center_name' => 'StJude',
                                },
                            },
                            'ExomeCapture' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WXS-ExomeCapture:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WXS-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                            'StructVariant-ABySS' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WXS-StructVariant-ABySS:02',
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
            'AML' => {
                'miRNA-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'fredhutch.org:Protocol:RNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'FHCRC',
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:miRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_excl_lib_const_protocol' => [
                            'BCCA',
                        ],
                        'exp_center_library_data_qc_warning' => {
                            'BCCA' => {
                                'm05005' => 'Low number of reads aligning to miRNA',
                                'm05006' => 'Low number of reads aligning to miRNA',
                                'm05007' => 'Low number of reads aligning to miRNA',
                                'm05008' => 'Low number of reads aligning to miRNA',
                                'm05009' => 'Low number of reads aligning to miRNA',
                                'm05010' => 'Low number of reads aligning to miRNA',
                                'm05011' => 'Low number of reads aligning to miRNA',
                                'm05012' => 'Low number of reads aligning to miRNA',
                                'm05013' => 'Low number of reads aligning to miRNA',
                                'm05014' => 'Low number of reads aligning to miRNA',
                                'm05015' => 'Low number of reads aligning to miRNA',
                                'm05016' => 'Low number of reads aligning to miRNA',
                                'm05017' => 'Low number of reads aligning to miRNA',
                                'm05018' => 'Low number of reads aligning to miRNA',
                                'm05029' => 'Low number of reads aligning to miRNA',
                                'm05043' => 'Low number of reads aligning to miRNA',
                                'm05068' => 'Low number of reads aligning to miRNA',
                                'm05069' => 'Low number of reads aligning to miRNA',
                                'm05070' => 'Low number of reads aligning to miRNA',
                                'm05071' => 'Low number of reads aligning to miRNA',
                            },
                        },
                    },
                },
                'mRNA-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'fredhutch.org:Protocol:RNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'FHCRC',
                                },
                            },
                            'LibraryPrep' => {
                                'BCCA' => {
                                    'filter' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-LibraryPrep-Illumina-UnstrandedLite:01',
                                        },
                                        'library_names' => [qw(
                                            A24311  A24312  A24313  A24314  A24315
                                            A24316  A24317  A24318  A24319  A24320
                                            A24321  A24322  A24323  A24324  A24325
                                            A24326  A24327  A24328  A24329  A24330
                                            A24331  A24332  A24333  A24334  A24335
                                            A24336  A24337  A24338  A24339  A24340
                                            A24341  A24342  A24343  A24344  A24345
                                            A24346  A24347  A24348  A24349  A24350
                                            A24351  A24352  A24353  A24354  A24355
                                            A24356  A24357  A24358  A24359  A24360
                                            A24362  A24363  A24364  A24365  A31166
                                        )],
                                    },
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-LibraryPrep-Illumina-StrandSpecific:01',
                                        },
                                    },
                                },
                                'HAIB' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'hudsonalpha.org:Protocol:mRNAseq-LibraryPrep-Illumina-Unstranded:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_incl_design_desc_protocol' => [
                            'HAIB',
                        ],
                        'exp_centers_excl_lib_const_protocol' => [
                            'BCCA',
                        ],
                        'barcode_by_alt_id' => {
                            'HAIB' => {
                                'AML_23196'  => 'TARGET-20-PABHET-09A-01R',
                                'AML_23350'  => 'TARGET-20-PABHKY-03A-01R',
                                'AML_36048'  => 'TARGET-20-PACDZR-09A-02R',
                                'AML_51040'  => 'TARGET-20-PADDXZ-03A-02R',
                                'AML_63761'  => 'TARGET-20-PAEAFC-09A-01R',
                                'AML_66841'  => 'TARGET-20-PAEFHC-09A-01R',
                                'AML_73407'  => 'TARGET-20-PAERAH-09A-01R',
                                'AML_709039' => 'TARGET-20-PAKVYM-09A-01R',
                                'AML_716200' => 'TARGET-20-PALHVV-09A-01R',
                                'AML_719261' => 'TARGET-20-PALNAT-09A-01R',
                                'AML_723026' => 'TARGET-20-PALVKV-09A-01R',
                                'AML_739075' => 'TARGET-20-PAMYWW-09A-01R',
                                'AML_740808' => 'TARGET-20-PANBWF-09A-01R',
                                'AML_741597' => 'TARGET-20-PANDER-09A-01R',
                                'AML_743295' => 'TARGET-20-PANGCM-03A-01R',
                                'AML_745148' => 'TARGET-20-PANJGR-09A-01R',
                                'AML_745410' => 'TARGET-20-PANJTK-09A-01R',
                                'AML_745886' => 'TARGET-20-PANKNB-09A-01R',
                                'AML_746371' => 'TARGET-20-PANLIZ-09A-01R',
                                'AML_746520' => 'TARGET-20-PANLRE-09A-01R',
                                'AML_746675' => 'TARGET-20-PANLXM-09A-01R',
                                'AML_748689' => 'TARGET-20-PANRIK-09A-01R',
                                'AML_749283' => 'TARGET-20-PANSJB-09A-01R',
                                'AML_750004' => 'TARGET-20-PANTPW-09A-01R',
                                'AML_750639' => 'TARGET-20-PANUTB-09A-01R',
                                'AML_750966' => 'TARGET-20-PANVGP-09A-01R',
                                'AML_751571' => 'TARGET-20-PANWHP-09A-01R',
                                'AML_753819' => 'TARGET-20-PAPAEG-09A-01R',
                                'AML_764821' => 'TARGET-20-PAPVCN-09A-01R',
                                'AML_765326' => 'TARGET-20-PAPVZK-09A-01R',
                                'AML_765551' => 'TARGET-20-PAPWIU-09A-01R',
                                'AML_766360' => 'TARGET-20-PAPXUF-09A-01R',
                                'AML_767829' => 'TARGET-20-PARAHF-09A-01R',
                                'AML_768364' => 'TARGET-20-PARBFJ-09A-01R',
                                'AML_768662' => 'TARGET-20-PARBTV-09A-01R',
                                'AML_769470' => 'TARGET-20-PARDDA-09A-01R',
                                'AML_770295' => 'TARGET-20-PARENB-09A-01R',
                                'AML_770716' => 'TARGET-20-PARFGK-09A-01R',
                                'AML_772076' => 'TARGET-20-PARHPP-03A-01R',
                                'AML_773431' => 'TARGET-20-PARJYP-03A-01R',
                                'AML_774511' => 'TARGET-20-PARLVL-09A-01R',
                                'AML_775184' => 'TARGET-20-PARMZF-09A-01R',
                                'AML_778078' => 'TARGET-20-PARTYK-09A-01R',
                                'AML_778533' => 'TARGET-20-PARUTH-09A-01R',
                                'AML_778552' => 'TARGET-20-PARUUB-09A-01R',
                                'AML_779900' => 'TARGET-20-PARXBT-09A-01R',
                                'AML_780178' => 'TARGET-20-PARXNG-09A-01R',
                                'AML_780535' => 'TARGET-20-PARYEB-09A-01R',
                                'AML_780582' => 'TARGET-20-PARYGA-09A-01R',
                                'AML_781469' => 'TARGET-20-PARZUU-09A-01R',
                                'AML_781506' => 'TARGET-20-PARZWH-09A-01R',
                                'AML_781728' => 'TARGET-20-PASAFM-09A-01R',
                                'AML_784743' => 'TARGET-20-PASFJB-09A-01R',
                                'AML_785729' => 'TARGET-20-PASHBI-09A-01R',
                                'AML_786388' => 'TARGET-20-PASIEP-09A-01R',
                                'AML_786543' => 'TARGET-20-PASILA-09A-01R',
                                'AML_787870' => 'TARGET-20-PASKUA-09A-01R',
                                'AML_789920' => 'TARGET-20-PASPGA-09A-01R',
                                'AML_790021' => 'TARGET-20-PASPKE-09A-01R',
                                'AML_790059' => 'TARGET-20-PASPLU-09A-01R',
                                'AML_790201' => 'TARGET-20-PASPTM-09A-01R',
                                'AML_790790' => 'TARGET-20-PASRTP-09A-01R',
                                # ineligible
                                #'AML_791679' => 'TARGET-20-PASTFY-09A-01R',
                                'AML_794421' => 'TARGET-20-PASXYG-09A-01R',
                                'AML_794537' => 'TARGET-20-PASYDC-09A-01R',
                                'AML_794690' => 'TARGET-20-PASYJI-09A-01R',
                                # ineligible
                                #'AML_794840' => 'TARGET-20-PASYRN-03A-01R',
                                'AML_798231' => 'TARGET-20-PATELT-03A-01R',
                            },
                        },
                        'exp_center_library_data_qc_warning' => {
                            'BCCA' => {
                                'A12535' => 'LOW SEQUENCE YIELD/DIVERSITY (genes detected < 17000)',
                                'A12536' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 50%) ',
                                'A12602' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 50%) ',
                                'A12619' => 'HIGH NON-GENIC CONTENT (genes detected > 30000, gene with 1-5x coverage > 35%, exon-intron ratio < 2, intergenic reads > 15%)',
                                'A12626' => 'HIGH NON-GENIC CONTENT (gene with 1-5x coverage > 35%)',
                                'A12627' => 'HIGH NON-GENIC CONTENT (gene with 1-5x coverage > 35%, exon-intron ratio < 2, intergenic reads > 15%)',
                                'A12639' => 'HIGH NON-GENIC CONTENT (gene with 1-5x coverage > 35%, exon-intron ratio < 2, intergenic reads > 15%)',
                                'A31932' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 50%) ',
                                'A31936' => 'HIGH NON-GENIC CONTENT (exon-intron ratio < 2)',
                                'A31941' => 'LOW SEQUENCE YIELD/DIVERSITY (genes detected < 17000); HIGH NON-GENIC CONTENT (gene with 1-5x coverage > 35%)',
                                'A31946' => 'HIGH NON-GENIC CONTENT (genes detected > 30000, gene with 1-5x coverage > 35%, exon-intron ratio < 2, intergenic reads > 15%)',
                                'A31966' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 50%) ',
                                'A31973' => 'LOW 5\'/3\'COVERAGE RATIO (genes with even 5\'/3\' coverage < 50%)',
                                'A31974' => 'HIGH NON-GENIC CONTENT (exon-intron ratio < 2)',
                                'A31993' => 'HIGH NON-GENIC CONTENT (exon-intron ratio < 2)',
                                'A31998' => 'HIGH NON-GENIC CONTENT (exon-intron ratio < 2)',
                                'A32002' => 'LOW 5\'/3\'COVERAGE RATIO (genes with uneven 5\'/3\' coverage > 15%, genes with even 5\'/3\' coverage < 50%)',
                                'A32025' => 'LOW SEQUENCE YIELD/DIVERSITY (genes detected < 17000); HIGH NON-GENIC CONTENT (gene with 1-5x coverage > 35%)',
                                'A32026' => 'LOW 5\'/3\'COVERAGE RATIO (genes with uneven 5\'/3\' coverage > 15%, genes with even 5\'/3\' coverage < 50%)',
                                'A32027' => 'LOW SEQUENCE YIELD/DIVERSITY (chastity passed bases < 5Gb, genes detected < 17000)',
                                'A32029' => 'LOW SEQUENCE YIELD/DIVERSITY (chastity passed percentage < 70%)',
                                'A32037' => 'LOW SEQUENCE YIELD/DIVERSITY (chastity passed percentage < 70%, genes detected < 17000)',
                                'A34410' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 50%)',
                                'A34412' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 50%)',
                            },
                        },
                    },
                },
                'Targeted-Capture' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'fredhutch.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'FHCRC',
                                },
                            },
                        },
                    },
                },
                'WGS' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Xiaotu',
                                    'mid_initials' => '',
                                    'email' => 'xiaotu.ma@stjude.org',
                                    'phone' => '+1 901 595 3774',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Zhang',
                                    'first_name' => 'Jinghui',
                                    'mid_initials' => '',
                                    'email' => 'jinghui.zhang@stjude.org',
                                    'phone' => '+1 901 595 6829',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                    ],
                                },
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'filter' => {
                                    'data' => {
                                        'name' => 'bcgsc.ca:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'barcodes' => [qw(
                                        TARGET-20-PAKIYW-03A-01D
                                        TARGET-20-PAKIYW-14A-01D
                                    )],
                                    'center_name' => 'BCCA',
                                },
                                'default' => {
                                    'data' => {
                                        'name' => 'fredhutch.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'FHCRC',
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WGS-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                                'CGI' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'completegenomics.com:Protocol:WGS-ReadAlign-CGI:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_excl_exp_desc' => [
                            'BCCA',
                        ],
                    },
                },
                'WXS' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Xiaotu',
                                    'mid_initials' => '',
                                    'email' => 'xiaotu.ma@stjude.org',
                                    'phone' => '+1 901 595 3774',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Zhang',
                                    'first_name' => 'Jinghui',
                                    'mid_initials' => '',
                                    'email' => 'jinghui.zhang@stjude.org',
                                    'phone' => '+1 901 595 6829',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'fredhutch.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'FHCRC',
                                },
                            },
                            'ExomeCapture' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-ExomeCapture-NimbleGen-SeqCapEZHumanExomeV2:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-ReadAlign-BWA-GATK-ITDAssembler:01',
                                        },
                                    },
                                },
                            },
                        },
                        'parse_files' => {
                            'L3' => [
                                'mutation/BCM/Germline/target-aml-germline-primary-dbsnp-nonsilent.txt',
                                'mutation/BCM/Germline/target-aml-germline-primary-novel-nonsilent.txt',
                                'mutation/BCM/CandidateSomatic/target-aml-snp-indel.mafplus.txt',
                                'mutation/BCM/CandidateSomatic/TARGET_AML_WXS_somatic.mafplus.xlsx',
                                'mutation/BCM/CandidateSomatic/TARGET_AML_WXS_somatic_filtered.mafplus.txt',
                                'mutation/BCM/VerifiedSomatic/TARGET_AML_WXS_somatic_filtered_verified.mafplus.txt',
                                'mutation/StJude/CandidateSomatic/stjude.org_TARGET_AML_WXS_Diagnosis_IlluminaHiSeq_somatic.maf.txt',
                                'mutation/StJude/CandidateSomatic/stjude.org_TARGET_AML_WXS_Relapse_IlluminaHiSeq_somatic.maf.txt',
                            ],
                        },
                        'sdrf_dag_info' => {
                            '_default' => {
                                'BCM' => {
                                    'BCM' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall-AtlasPindel' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-aml-germline-primary-dbsnp-nonsilent.txt',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-aml-germline-primary-novel-nonsilent.txt',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-aml-snp-indel.mafplus.txt',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'TARGET_AML_WXS_somatic.mafplus.xlsx',
                                                        'protocol_data_by_type' => {
                                                            'Filter' => {
                                                                'file_data' => [
                                                                    {
                                                                        'data_level' => '3',
                                                                        'file_name' => 'TARGET_AML_WXS_somatic_filtered.mafplus.txt',
                                                                        'protocol_data_by_type' => {
                                                                            'FilterVerified' => {
                                                                                'file_data' => [
                                                                                    {
                                                                                        'data_level' => '3',
                                                                                        'file_name' => 'TARGET_AML_WXS_somatic_filtered_verified.mafplus.txt',
                                                                                    },
                                                                                ],
                                                                            },
                                                                        },
                                                                    },
                                                                ],
                                                            },
                                                        },
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                    'StJude' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall-Bambino-DToxoG' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'stjude.org_TARGET_AML_WXS_Diagnosis_IlluminaHiSeq_somatic.maf.txt',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'stjude.org_TARGET_AML_WXS_Relapse_IlluminaHiSeq_somatic.maf.txt',
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
            'CCSK' => {
                'mRNA-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Khan',
                                    'first_name' => 'Javed',
                                    'email' => 'javed.khan@nih.gov',
                                    'phone' => '+1 301 435 2937',
                                    'fax' => '+1 301 480 0314',
                                    'address' => '37 Convent Dr Rm 2016B, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:RNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'LibraryPrep' => {
                                'NCI-Khan' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Khan.Protocol:mRNAseq-LibraryPrep-Illumina-Unstranded:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'NCI-Khan' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Khan.Protocol:mRNAseq-ReadAlign-TopHat:01',
                                        },
                                    },
                                },
                            },
                            'Expression' => {
                                'NCI-Khan' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Khan.Protocol:mRNAseq-Expression:02',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_incl_design_desc_protocol' => [
                            'NCI-Khan',
                        ],
                    },
                },
                'WGS' => {
                    '_default' => {
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ReadAlign' => {
                                'CGI' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'completegenomics.com:Protocol:WGS-ReadAlign-CGI:01',
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
            'MDLS-NBL' => {
                'WXS' => {
                    '_default' => {
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-GenomicTips:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'LibraryPrep' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-LibraryPrep-Illumina:02',
                                        },
                                    },
                                },
                            },
                            'ExomeCapture' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-ExomeCapture-NimbleGen-SeqCapEZHGSCVCRomeV2.1:01',
                                        },
                                    },
                                },
                            },
                            'Sequence' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-Sequence-Illumina-HiSeq2000:02',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-ReadAlign-BWA-GATK:02',
                                        },
                                    },
                                },
                            },
                        },
                        'parse_files' => {
                            'L3' => [
                                'mutation/BCM/CandidateSomatic/target-nbl-pptp-wxs-celllines-pdx-somatic-v1.3.mafplus.xlsx',
                                'mutation/BCM/CandidateSomatic/target-nbl-pptp-wxs-pdx-failed-somatic-v1.3.mafplus.xlsx',
                            ],
                        },
                        'sdrf_dag_info' => {
                            '_default' => {
                                'BCM' => {
                                    'BCM' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall-Atlas-ModelSystems' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-nbl-pptp-wxs-celllines-pdx-somatic-v1.3.mafplus.xlsx',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-nbl-pptp-wxs-pdx-failed-somatic-v1.3.mafplus.xlsx',
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                },
                            },
                        },
                        'add_data_types' => {
                            'Targeted-Capture' => {
                                'protocol_info' => {
                                    'Extraction' => {
                                        # extraction protocol info config has no center name hash key level
                                        'default' => {
                                            'data' => {
                                                'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-GenomicTips:01',
                                            },
                                            'center_name' => 'NCH',
                                        },
                                    },
                                    'ReadAlign' => {
                                        'BCM' => {
                                            'default' => {
                                                'data' => {
                                                    'name' => 'bcm.edu:Protocol:TargetedCapture-ReadAlign-BLAT-CrossMatch:01',
                                                },
                                            },
                                        },
                                    },
                                },
                                'sdrf_dag_info' => {
                                    '_default' => {
                                        'BCM' => {
                                            'BCM' => {
                                                'protocol_data_by_type' => {
                                                    'VariantCall-Atlas-ModelSystems' => {
                                                        'file_data' => [
                                                            {
                                                                'data_level' => '3',
                                                                'file_name' => 'target-nbl-pptp-wxs-celllines-pdx-somatic-v1.3.mafplus.xlsx',
                                                            },
                                                            {
                                                                'data_level' => '3',
                                                                'file_name' => 'target-nbl-pptp-wxs-pdx-failed-somatic-v1.3.mafplus.xlsx',
                                                            },
                                                        ],
                                                    },
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                'WGS' => {
                    '_default' => {
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-GenomicTips:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ReadAlign' => {
                                'CGI' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'completegenomics.com:Protocol:WGS-ReadAlign-CGI:01',
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
            'MDLS-PPTP' => {
                'WXS' => {
                    '_default' => {
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-GenomicTips:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'LibraryPrep' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-LibraryPrep-Illumina:02',
                                        },
                                    },
                                },
                            },
                            'ExomeCapture' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-ExomeCapture-NimbleGen-SeqCapEZHGSCVCRomeV2.1:01',
                                        },
                                    },
                                },
                            },
                            'Sequence' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-Sequence-Illumina-HiSeq2000:02',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-ReadAlign-BWA-GATK:02',
                                        },
                                    },
                                },
                            },
                        },
                        'parse_files' => {
                            'L3' => [
                                'mutation/BCM/Verified/target-pptp-wxs-verified.mafplus.xlsx',
                            ],
                        },
                        'sdrf_dag_info' => {
                            '_default' => {
                                'BCM' => {
                                    'BCM' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall-Atlas-ModelSystems' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-pptp-wxs-verified.mafplus.xlsx',
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                },
                            },
                        },
                        'add_data_types' => {
                            'Targeted-Capture' => {
                                'protocol_info' => {
                                    'Extraction' => {
                                        # extraction protocol info config has no center name hash key level
                                        'default' => {
                                            'data' => {
                                                'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-GenomicTips:01',
                                            },
                                            'center_name' => 'NCH',
                                        },
                                    },
                                    'ReadAlign' => {
                                        'BCM' => {
                                            'default' => {
                                                'data' => {
                                                    'name' => 'bcm.edu:Protocol:TargetedCapture-ReadAlign-BLAT-CrossMatch:01',
                                                },
                                            },
                                        },
                                    },
                                },
                                'sdrf_dag_info' => {
                                    '_default' => {
                                        'BCM' => {
                                            'BCM' => {
                                                'protocol_data_by_type' => {
                                                    'VariantCall-Atlas-ModelSystems' => {
                                                        'file_data' => [
                                                            {
                                                                'data_level' => '3',
                                                                'file_name' => 'target-pptp-wxs-verified.mafplus.xlsx',
                                                            },
                                                        ],
                                                    },
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },    
            },
            'NBL' => {
                'miRNA-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:RNA-Extraction-TRIzol-RNAeasy:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:miRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_incl_design_desc_protocol' => [
                            'BCCA',
                        ],
                        'exp_center_library_data_qc_warning' => {
                            'BCCA' => {
                                'm17797' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17802' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17805' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17807' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17819' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17824' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17827' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17832' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17836' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17841' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17848' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17851' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17856' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17859' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17864' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17867' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                                'm17872' => 'LOW SEQUENCE YIELD/DIVERSITY (aligned reads < 1000000)',
                            },
                        },
                    },
                },
                'mRNA-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Khan',
                                    'first_name' => 'Javed',
                                    'email' => 'javed.khan@nih.gov',
                                    'phone' => '+1 301 435 2937',
                                    'fax' => '+1 301 480 0314',
                                    'address' => '37 Convent Dr Rm 2016B, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:RNA-Extraction-TRIzol-RNAeasy:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'LibraryPrep' => {
                                'BCCA' => {
                                    'filter' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-LibraryPrep-Illumina-Unstranded:01',
                                        },
                                        'library_names' => [qw(
                                            HS1194  HS1195  HS1196  HS1197  HS1198  HS1795
                                            HS1797  HS1799  HS1801  HS1803  
                                        )],
                                    },
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-LibraryPrep-Illumina-StrandSpecific:01',
                                        },
                                    },
                                },
                                'NCI-Khan' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Khan.Protocol:mRNAseq-LibraryPrep-Illumina-Unstranded:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                                'NCI-Khan' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Khan.Protocol:mRNAseq-ReadAlign-TopHat:01',
                                        },
                                    },
                                },
                            },
                            'Expression' => {
                                'NCI-Khan' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Khan.Protocol:mRNAseq-Expression:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_incl_design_desc_protocol' => [
                            'BCCA',
                            'NCI-Khan',
                        ],
                    },
                },
                'Targeted-Capture' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-GenomicTips:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                        },
                        'skip_files' => {
                            'L3' => [
                                'copy_number/UHN/VisCap_Female_Germline/QC_coverage_panel_of_normals.pdf',
                                'copy_number/UHN/VisCap_Female_Germline/QC_coverage_project_samples.pdf',
                                'copy_number/UHN/VisCap_Female_Somatic/QC_coverage_panel_of_normals.pdf',
                                'copy_number/UHN/VisCap_Female_Somatic/QC_coverage_project_samples.pdf',
                                'copy_number/UHN/VisCap_Male_Germline/QC_coverage_panel_of_normals.pdf',
                                'copy_number/UHN/VisCap_Male_Germline/QC_coverage_project_samples.pdf',
                                'copy_number/UHN/VisCap_Male_Somatic/QC_coverage_panel_of_normals.pdf',
                                'copy_number/UHN/VisCap_Male_Somatic/QC_coverage_project_samples.pdf',
                            ],
                        },
                    },
                },
                'WGS' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Xiaotu',
                                    'mid_initials' => '',
                                    'email' => 'xiaotu.ma@stjude.org',
                                    'phone' => '+1 901 595 3774',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Zhang',
                                    'first_name' => 'Jinghui',
                                    'mid_initials' => '',
                                    'email' => 'jinghui.zhang@stjude.org',
                                    'phone' => '+1 901 595 6829',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                    ],
                                },
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-GenomicTips:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WGS-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                                'CGI' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'completegenomics.com:Protocol:WGS-ReadAlign-CGI:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_excl_exp_desc' => [
                            'BCCA',
                        ],
                    },
                },
                'WXS' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Xiaotu',
                                    'mid_initials' => '',
                                    'email' => 'xiaotu.ma@stjude.org',
                                    'phone' => '+1 901 595 3774',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Zhang',
                                    'first_name' => 'Jinghui',
                                    'mid_initials' => '',
                                    'email' => 'jinghui.zhang@stjude.org',
                                    'phone' => '+1 901 595 6829',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-GenomicTips:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ExomeCapture' => {
                                'Broad' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'broadinstitute.org:Protocol:WXS-ExomeCapture-Agilent-WholeExome1.1RefSeqPlus3Boosters:01',
                                        },
                                    },
                                },
                            },
                        },
                        'parse_files' => {
                            'L3' => [
                                'mutation/Broad/Germline/NB170_germline_calls_from_tumors.vcf',
                                'mutation/Broad/Germline/NB222_exome_germline_calls.snp.recalibrated.vcf',
                                'mutation/Broad/Germline/NB222_germline_calls_from_tumors.vcf',
                                'mutation/Broad/CandidateSomatic/TARGET_NBL_WXS_somatic.maf.txt',
                                'mutation/Broad/VerifiedSomatic/TARGET_NBL_WXS_somatic_verified.maf.txt',
                                'mutation/StJude/CandidateSomatic/stjude.org_TARGET_NBL_WXS_Diagnosis_IlluminaHiSeq_somatic.maf.txt',
                            ],
                        },
                        'skip_files' => {
                            'L3' => [
                                'copy_number/Broad/NB222_sample_info_file.sif',
                            ],
                        },
                        'sdrf_dag_info' => {
                            '_default' => {
                                'Broad' => {
                                    'Broad' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'NB170_germline_calls_from_tumors.vcf',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'NB222_exome_germline_calls.snp.recalibrated.vcf',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'NB222_germline_calls_from_tumors.vcf',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'TARGET_NBL_WXS_somatic.maf.txt',
                                                        'protocol_data_by_type' => {
                                                            'FilterVerified' => {
                                                                'file_data' => [
                                                                    {
                                                                        'data_level' => '3',
                                                                        'file_name' => 'TARGET_NBL_WXS_somatic_verified.maf.txt',
                                                                    },
                                                                ],
                                                            },
                                                        },
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                    'StJude' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall-Bambino-DToxoG' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'stjude.org_TARGET_NBL_WXS_Diagnosis_IlluminaHiSeq_somatic.maf.txt',
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },    
            },
            'OS' => {
                'mRNA-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Davis',
                                    'first_name' => 'Sean',
                                    'email' => 'sean.davis@nih.gov',
                                    'phone' => '+1 301 435 2652',
                                    'fax' => '',
                                    'address' => '37 Convent Dr Rm 6138, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Meltzer',
                                    'first_name' => 'Paul',
                                    'email' => 'paul.meltzer@nih.gov',
                                    'phone' => '+1 301 496 5266',
                                    'fax' => '',
                                    'address' => '37 Convent Dr Rm 6138, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:RNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'LibraryPrep' => {
                                'NCI-Meltzer' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Meltzer.Protocol:mRNAseq-LibraryPrep-Illumina-Unstranded:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_excl_exp_desc' => [
                            'NCI-Meltzer'
                        ],
                    },
                },
                'WGS' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Davis',
                                    'first_name' => 'Sean',
                                    'email' => 'sean.davis@nih.gov',
                                    'phone' => '+1 301 435 2652',
                                    'fax' => '',
                                    'address' => '37 Convent Dr Rm 6138, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Meltzer',
                                    'first_name' => 'Paul',
                                    'email' => 'paul.meltzer@nih.gov',
                                    'phone' => '+1 301 496 5266',
                                    'fax' => '',
                                    'address' => '37 Convent Dr Rm 6138, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Xiaotu',
                                    'mid_initials' => '',
                                    'email' => 'xiaotu.ma@stjude.org',
                                    'phone' => '+1 901 595 3774',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Zhang',
                                    'first_name' => 'Jinghui',
                                    'mid_initials' => '',
                                    'email' => 'jinghui.zhang@stjude.org',
                                    'phone' => '+1 901 595 6829',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                    ],
                                },
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'Sequence' => {
                                'NCI-Meltzer' => {
                                    'filter' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WGS-Sequence-Illumina-HiSeq2000:01',
                                        },
                                        'run_ids' => [qw(
                                            SRR3493410  SRR3493411  SRR3493412  SRR3493413  SRR3493414  SRR3493415
                                            SRR3493416  SRR3493417  SRR3493418  SRR3493419  SRR3493420  SRR3493421
                                            SRR3493422  SRR3493423  SRR3493424  SRR3493425  SRR3493426  SRR3493427
                                            SRR3493428  SRR3493429  SRR3493430  SRR3493431  SRR3493432  SRR3493433
                                        )],
                                        'center_name' => 'BCCA',
                                    },
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Meltzer.Protocol:WGS-Sequence-Illumina-HiSeq2000:01',
                                        },
                                    },
                                },
                            },
                            'BaseCall' => {
                                'NCI-Meltzer' => {
                                    'filter' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WGS-BaseCall-Illumina:01',
                                        },
                                        'run_ids' => [qw(
                                            SRR3493410  SRR3493411  SRR3493412  SRR3493413  SRR3493414  SRR3493415
                                            SRR3493416  SRR3493417  SRR3493418  SRR3493419  SRR3493420  SRR3493421
                                            SRR3493422  SRR3493423  SRR3493424  SRR3493425  SRR3493426  SRR3493427
                                            SRR3493428  SRR3493429  SRR3493430  SRR3493431  SRR3493432  SRR3493433
                                        )],
                                        'center_name' => 'BCCA',
                                    },
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Meltzer.Protocol:WGS-BaseCall-Illumina-Bustard:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WGS-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                                'CGI' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'completegenomics.com:Protocol:WGS-ReadAlign-CGI:01',
                                        },
                                    },
                                },
                                'NCI-Meltzer' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Meltzer.Protocol:WGS-ReadAlign-BWA-MEM:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_excl_exp_desc' => [
                            'BCCA',
                        ],
                    },
                },
                'WXS' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Davis',
                                    'first_name' => 'Sean',
                                    'email' => 'sean.davis@nih.gov',
                                    'phone' => '+1 301 435 2652',
                                    'fax' => '',
                                    'address' => '37 Convent Dr Rm 6138, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Meltzer',
                                    'first_name' => 'Paul',
                                    'email' => 'paul.meltzer@nih.gov',
                                    'phone' => '+1 301 496 5266',
                                    'fax' => '',
                                    'address' => '37 Convent Dr Rm 6138, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Xiaotu',
                                    'mid_initials' => '',
                                    'email' => 'xiaotu.ma@stjude.org',
                                    'phone' => '+1 901 595 3774',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Zhang',
                                    'first_name' => 'Jinghui',
                                    'mid_initials' => '',
                                    'email' => 'jinghui.zhang@stjude.org',
                                    'phone' => '+1 901 595 6829',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ExomeCapture' => {
                                'NCI-Meltzer' => {
                                    'filter' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Meltzer.Protocol:WXS-ExomeCapture-Illumina-TruSeqExome:01',
                                        },
                                        'library_names' => [
                                            '4938,5133', '5148,5713',      '4950,5145,5712', '5160',           '4951,5146',
                                            '5161,5715', '4939,5134,5709', '5149',           '4940,5135,5710', '5150',
                                            '4941,5136', '5151',           '4942,5137',      '5152,5714',      '4943,5138',
                                            '5153',      '4944,5139',      '5154',           '4946,5141',      '5156',
                                            '4947,5142', '5157',           '4948,5143,5711', '5158',           '4949,5144',
                                            '5159',
                                        ],
                                    },
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Meltzer.Protocol:WXS-ExomeCapture-Agilent-SureSelectHumanAllExonV3:01',
                                        },
                                    },
                                },
                            },
                            'BaseCall' => {
                                'NCI-Meltzer' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Meltzer.Protocol:WXS-BaseCall-Illumina-Bustard:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'NCI-Meltzer' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'nci.nih.gov:CCR.Meltzer.Protocol:WXS-ReadAlign-BWA-MEM:01',
                                        },
                                    },
                                },
                            },
                        },
                        'parse_files' => {
                            'L3' => [
                                # StJude didn't use correct barcodes in file so cannot parse, will grab barcodes from run info
                                #'mutation/StJude/CandidateSomatic/stjude.org_TARGET_OS_WXS_Diagnosis_IlluminaHiSeq_somatic.maf.txt',
                            ],
                        },
                        'sdrf_dag_info' => {
                            '_default' => {
                                'NCI-Meltzer' => {
                                    'StJude' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall-Bambino-DToxoG' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'stjude.org_TARGET_OS_WXS_Diagnosis_IlluminaHiSeq_somatic.maf.txt',
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
            'OS-Toronto' => {
                'mRNA-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Davis',
                                    'first_name' => 'Sean',
                                    'email' => 'sean.davis@nih.gov',
                                    'phone' => '+1 301 435 2652',
                                    'fax' => '',
                                    'address' => '37 Convent Dr Rm 6138, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Meltzer',
                                    'first_name' => 'Paul',
                                    'email' => 'paul.meltzer@nih.gov',
                                    'phone' => '+1 301 496 5266',
                                    'fax' => '',
                                    'address' => '37 Convent Dr Rm 6138, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:RNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                        },
                        'exp_centers_incl_design_desc_protocol' => [
                            'NCI-Meltzer',
                        ],
                    },
                },
                'WGS' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Davis',
                                    'first_name' => 'Sean',
                                    'email' => 'sean.davis@nih.gov',
                                    'phone' => '+1 301 435 2652',
                                    'fax' => '',
                                    'address' => '37 Convent Dr Rm 6138, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Meltzer',
                                    'first_name' => 'Paul',
                                    'email' => 'paul.meltzer@nih.gov',
                                    'phone' => '+1 301 496 5266',
                                    'fax' => '',
                                    'address' => '37 Convent Dr Rm 6138, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                        },
                        'exp_centers_excl_exp_desc' => [
                            'BCCA',
                        ],
                    },
                },
                'WXS' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Davis',
                                    'first_name' => 'Sean',
                                    'email' => 'sean.davis@nih.gov',
                                    'phone' => '+1 301 435 2652',
                                    'fax' => '',
                                    'address' => '37 Convent Dr Rm 6138, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Meltzer',
                                    'first_name' => 'Paul',
                                    'email' => 'paul.meltzer@nih.gov',
                                    'phone' => '+1 301 496 5266',
                                    'fax' => '',
                                    'address' => '37 Convent Dr Rm 6138, Bethesda MD 20892',
                                    'affiliation' => 'National Cancer Institute',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                        },
                        'add_run_center_barcodes' => {
                            'NCI-Meltzer' => [qw(
                                TARGET-40-0A4I0S-01A-01D
                                TARGET-40-0A4I0S-10A-01D
                            )],
                        },
                    },
                },
            },
            'RT' => {
                'Bisulfite-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                        },
                    },
                },
                'ChIP-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                        },
                    },
                },
                'miRNA-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:RNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:miRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_excl_lib_const_protocol' => [qw(
                            BCCA
                        )],
                    },
                },
                'mRNA-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:RNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'LibraryPrep' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-LibraryPrep-Illumina-StrandSpecific:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_excl_lib_const_protocol' => [qw(
                            BCCA
                        )],
                    },
                },
                'WGS' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WGS-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                        },
                        #'exp_centers_excl_exp_desc' => [
                        #    'BCCA',
                        #],
                    },
                },
            },
            'WT' => {
                'miRNA-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:RNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:miRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
                'mRNA-seq' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:RNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'LibraryPrep' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-LibraryPrep-Illumina-StrandSpecific:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:mRNAseq-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_center_library_data_qc_warning' => {
                            'BCCA' => {
                                'A33494' => 'LOW 5\'/3\'COVERAGE RATIO (genes with uneven 5\'/3\' coverage >25%)',
                                'A33520' => 'LOW 5\'/3\'COVERAGE RATIO (genes with uneven 5\'/3\' coverage >25%)',
                                'A33531' => 'LOW 5\'/3\'COVERAGE RATIO (genes with uneven 5\'/3\' coverage >25%)',
                                'A33550' => 'LOW 5\'/3\'COVERAGE RATIO (genes with uneven 5\'/3\' coverage >25%)',
                                'A33562' => 'HIGH NON-GENIC CONTENT (genes detected > 30000)',
                                'A33578' => 'HIGH NON-GENIC CONTENT (genes detected > 30000)',
                                'A33665' => 'LOW 5\'/3\'COVERAGE RATIO (genes with uneven 5\'/3\' coverage >25%)',
                                'A33666' => 'LOW 5\'/3\'COVERAGE RATIO (genes with uneven 5\'/3\' coverage >25%)',
                                'A34694' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 20%)',
                                'A34695' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 20%)',
                                'A34696' => 'HIGH MITOCHONDRIAL CONTENT (mitochondrial reads > 20%)',
                                'A35278' => 'LOW SEQUENCE YIELD/DIVERSITY (chastity passed percentage < 70%)',
                            },
                        },
                    },
                },
                'Targeted-Capture' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                        },
                        'alt_id_by_barcode' => {
                            'TARGET-50-CAAAAC-01A-02D' => 'TARGET-50-PADWYI-01A-01D',
                            'TARGET-50-CAAAAJ-01A-02D' => 'TARGET-50-PADWMG-01A-01D',
                            'TARGET-50-CAAAAL-01A-03D' => 'TARGET-50-PADXUJ-01A-02D',
                            'TARGET-50-CAAAAO-01A-02D' => 'TARGET-50-PACDYF-01A-01D',
                            'TARGET-50-CAAAAP-01A-02D' => 'TARGET-50-PAEHHM-01A-01D',
                            'TARGET-50-CAAAAQ-01A-02D' => 'TARGET-50-PAERTC-01A-01D',
                            'TARGET-50-CAAAAR-01A-04D' => 'TARGET-50-PAJNPS-01A-03D',
                            'TARGET-50-CAAAAS-01A-02D' => 'TARGET-50-PAKGHT-01A-01D',
                        },
                    },
                },
                'WGS' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Xiaotu',
                                    'mid_initials' => '',
                                    'email' => 'xiaotu.ma@stjude.org',
                                    'phone' => '+1 901 595 3774',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Zhang',
                                    'first_name' => 'Jinghui',
                                    'mid_initials' => '',
                                    'email' => 'jinghui.zhang@stjude.org',
                                    'phone' => '+1 901 595 6829',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                    ],
                                },
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Yussanne',
                                    'mid_initials' => 'P',
                                    'email' => 'yma@bcgsc.ca',
                                    'phone' => '+1 604 707 5800 Ext 6082',
                                    'fax' => '+1 604 876 3561',
                                    'address' => 'Suite 100-570 West 7th Ave, Vancouver, BC Canada V5Z 4S6',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Novik',
                                    'first_name' => 'Karen',
                                    'mid_initials' => 'L',
                                    'email' => 'knovik@bcgsc.ca',
                                    'phone' => '+1 604 707 8000 Ext 7983',
                                    'fax' => '+1 604 675 8178',
                                    'address' => '675 West 10th Ave Vancouver, BC Canada V5Z 1L3',
                                    'affiliation' => 'BC Cancer Agency Canada\'s Michael Smith Genome Sciences Centre',
                                    'roles' => [
                                        'investigator',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ReadAlign' => {
                                'BCCA' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcgsc.ca:Protocol:WGS-ReadAlign-BWA-Picard:01',
                                        },
                                    },
                                },
                                'CGI' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'completegenomics.com:Protocol:WGS-ReadAlign-CGI:01',
                                        },
                                    },
                                },
                            },
                        },
                        'exp_centers_excl_exp_desc' => [
                            'BCCA',
                        ],
                    },
                },
                'WXS' => {
                    '_default' => {
                        'idf' => {
                            'contacts' => [
                                {
                                    'last_name' => 'Ma',
                                    'first_name' => 'Xiaotu',
                                    'mid_initials' => '',
                                    'email' => 'xiaotu.ma@stjude.org',
                                    'phone' => '+1 901 595 3774',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                        'submitter',
                                    ],
                                },
                                {
                                    'last_name' => 'Zhang',
                                    'first_name' => 'Jinghui',
                                    'mid_initials' => '',
                                    'email' => 'jinghui.zhang@stjude.org',
                                    'phone' => '+1 901 595 6829',
                                    'fax' => '+1 901 595 7100',
                                    'address' => '262 Danny Thomas Place, Memphis, TN 38105',
                                    'affiliation' => 'St Jude Children\'s Research Hospital',
                                    'roles' => [
                                        'investigator',
                                        'data analyst',
                                    ],
                                },
                            ],
                        },
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                            'ExomeCapture' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-ExomeCapture-NimbleGen-SeqCapEZHumanExomeV2:01',
                                        },
                                    },
                                },
                            },
                            'ReadAlign' => {
                                'BCM' => {
                                    'default' => {
                                        'data' => {
                                            'name' => 'bcm.edu:Protocol:WXS-ReadAlign-BWA-GATK:01',
                                        },
                                    },
                                },
                            },
                        },
                        'parse_files' => {
                            'L3' => [
                                'mutation/BCM/Germline/target-wt-hg19-germline.mafplus.txt',
                                'mutation/BCM/CandidateSomatic/target-wt-snp-indel.mafplus.txt',
                                'mutation/BCM/CandidateSomatic/target-wt-17pairs-somatic-v1.1.mafplus.xlsx',
                                'mutation/BCM/CandidateSomatic/target-wt-pilot-bcm-somatic-v4.0.mafplus.xlsx',
                                'mutation/BCM/VerifiedSomatic/target-wt-pilot-bcm-somatic-verified-v4.0.mafplus.xlsx',
                                'mutation/NCI-Meerzaman/CandidateSomatic/target-wt-17pairs-NCI-somatic-exonic.bcmmaf.txt',
                                'mutation/NCI-Meerzaman/CandidateSomatic/target-wt-pilot-nci-somatic-v4.0.mafplus.xlsx',
                                'mutation/NCI-Meerzaman/CandidateSomatic/target-wt-primary-recurrent-NCI-somatic-exonic.bcmmaf.txt',
                                'mutation/NCI-Meerzaman/VerifiedSomatic/target-wt-pilot-nci-somatic-verified-v4.0.mafplus.xlsx',
                                'mutation/NCI-Meerzaman/VerifiedSomatic/target-wt-primary-recurrent-NCI-somatic-exonic-verified.bcmmaf.txt',
                                'mutation/StJude/CandidateSomatic/stjude.org_TARGET_WT_WXS_Diagnosis_IlluminaHiSeq_somatic.maf.txt',
                                'mutation/StJude/CandidateSomatic/stjude.org_TARGET_WT_WXS_Relapse_IlluminaHiSeq_somatic.maf.txt',
                            ],
                        },
                        'sdrf_dag_info' => {
                            '_default' => {
                                'BCM' => {
                                    'BCM' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall-AtlasPindel' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-wt-hg19-germline.mafplus.txt',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-wt-snp-indel.mafplus.txt',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-wt-17pairs-somatic-v1.1.mafplus.xlsx',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-wt-pilot-bcm-somatic-v4.0.mafplus.xlsx',
                                                        'protocol_data_by_type' => {
                                                            'FilterVerified' => {
                                                                'file_data' => [
                                                                    {
                                                                        'data_level' => '3',
                                                                        'file_name' => 'target-wt-pilot-bcm-somatic-verified-v4.0.mafplus.xlsx',
                                                                    },
                                                                ],
                                                            },
                                                        },
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                    'NCI-Meerzaman' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-wt-17pairs-NCI-somatic-exonic.bcmmaf.txt',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-wt-pilot-nci-somatic-v4.0.mafplus.xlsx',
                                                        'protocol_data_by_type' => {
                                                            'FilterVerified' => {
                                                                'file_data' => [
                                                                    {
                                                                        'data_level' => '3',
                                                                        'file_name' => 'target-wt-pilot-nci-somatic-verified-v4.0.mafplus.xlsx',
                                                                    },
                                                                ],
                                                            },
                                                        },
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'target-wt-primary-recurrent-NCI-somatic-exonic.bcmmaf.txt',
                                                        'protocol_data_by_type' => {
                                                            'FilterVerified' => {
                                                                'file_data' => [
                                                                    {
                                                                        'data_level' => '3',
                                                                        'file_name' => 'target-wt-primary-recurrent-NCI-somatic-exonic-verified.bcmmaf.txt',
                                                                    },
                                                                ],
                                                            },
                                                        },
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                    'StJude' => {
                                        'protocol_data_by_type' => {
                                            'VariantCall-Bambino-DToxoG' => {
                                                'file_data' => [
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'stjude.org_TARGET_WT_WXS_Diagnosis_IlluminaHiSeq_somatic.maf.txt',
                                                    },
                                                    {
                                                        'data_level' => '3',
                                                        'file_name' => 'stjude.org_TARGET_WT_WXS_Relapse_IlluminaHiSeq_somatic.maf.txt',
                                                    },
                                                ],
                                            },
                                        },
                                    },
                                },
                            },
                        },
                        'add_data_types' => {
                            'Targeted-Capture' => {
                                'protocol_info' => {
                                    'Extraction' => {
                                        # extraction protocol info config has no center name hash key level
                                        'default' => {
                                            'data' => {
                                                'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                            },
                                            'center_name' => 'NCH',
                                        },
                                    },
                                    'ReadAlign' => {
                                        'BCM' => {
                                            'default' => {
                                                'data' => {
                                                    'name' => 'bcm.edu:Protocol:TargetedCapture-ReadAlign-BLAT-CrossMatch:01',
                                                },
                                            },
                                        },
                                    },
                                },
                                'sdrf_dag_info' => {
                                    '_default' => {
                                        'BCM' => {
                                            'BCM' => {
                                                'protocol_data_by_type' => {
                                                    'VariantCall-AtlasPindel' => {
                                                        'file_data' => [
                                                            {
                                                                'data_level' => '3',
                                                                'file_name' => 'target-wt-pilot-bcm-somatic-v4.0.mafplus.xlsx',
                                                                'protocol_data_by_type' => {
                                                                    'FilterVerified' => {
                                                                        'file_data' => [
                                                                            {
                                                                                'data_level' => '3',
                                                                                'file_name' => 'target-wt-pilot-bcm-somatic-verified-v4.0.mafplus.xlsx',
                                                                            },
                                                                        ],
                                                                    },
                                                                },
                                                            },
                                                        ],
                                                    },
                                                },
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },    
                },    
            },
        },
        'CGCI' => {
            'HTMCP-DLBCL' => {
                'WGS' => {
                    '_default' => {
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                        },
                        'exp_centers_excl_exp_desc' => [
                            'BCCA',
                        ],
                        'exp_centers_excl_lib_const_protocol' => [
                            'BCCA',
                        ],
                    },
                },
            },
            'HTMCP-LC' => {
                'WGS' => {
                    '_default' => {
                        'protocol_info' => {
                            'Extraction' => {
                                # extraction protocol info config has no center name hash key level
                                'default' => {
                                    'data' => {
                                        'name' => 'nationwidechildrens.org:Protocol:DNA-Extraction-Qiagen-AllPrep:01',
                                    },
                                    'center_name' => 'NCH',
                                },
                            },
                        },
                        'exp_centers_excl_lib_const_protocol' => [
                            'BCCA',
                        ],
                    },
                },
            },
        },
    },
}
