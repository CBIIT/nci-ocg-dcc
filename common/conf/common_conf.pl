# common config
{
    'program_names' => [qw(
        TARGET
        CGCI
        CTD2
    )],
    'program_project_names' => {
        'TARGET' => [qw(
            ALL
            AML
            CCSK
            MDLS-NBL
            MDLS-PPTP
            NBL
            OS
            OS-Brazil
            OS-Toronto
            RT
            WT
            Resources
        )],
        'CGCI' => [qw(
            BLGSP
            HTMCP-CC
            HTMCP-DLBCL
            HTMCP-LC
            MB
            NHL
            Resources
        )],
        'CTD2' => [qw(
            Broad
            CNIS
            Columbia
            CSHL
            DFCI
            Emory
            FHCRC-1
            FHCRC-2
            Resources
            Stanford
            TGen
            UCSF-1
            UCSF-2
            UTMDA
            UTSW
        )],
    },
    'programs_w_data_types' => [qw(
        TARGET
        CGCI
    )],
    'data_types' => [qw(
        biospecimen
        Bisulfite-seq
        ChIP-seq
        clinical
        copy_number_array
        gene_expression_array
        GWAS
        kinome
        methylation_array
        miRNA_array
        miRNA_pcr
        misc
        miRNA-seq
        mRNA-seq
        pathology_images
        SAMPLE_MATRIX
        targeted_capture_sequencing
        targeted_pcr_sequencing
        WGS
        WXS
    )],
    'data_types_w_data_levels' => [qw(
        Bisulfite-seq
        ChIP-seq
        copy_number_array
        gene_expression_array
        GWAS
        kinome
        methylation_array
        miRNA_array
        miRNA_pcr
        miRNA-seq
        mRNA-seq
        targeted_capture_sequencing
        targeted_pcr_sequencing
        WGS
        WXS
    )],
    'seq_data_types' => [qw(
        Bisulfite-seq
        ChIP-seq
        miRNA-seq
        mRNA-seq
        Targeted-Capture
        WGS
        WXS
    )],
    'data_level_dir_names' => [qw(
        L1
        L2
        L3
        L4
        METADATA
        CGI
        DESIGN
    )],
    
}
