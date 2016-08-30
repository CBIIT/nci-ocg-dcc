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
    },
    'seq_data_types' => [qw(
        Bisulfite-seq
        ChIP-seq
        miRNA-seq
        mRNA-seq
        Targeted-Capture
        WGS
        WXS
    )],
    'default_manifest_file_name' => 'MANIFEST.txt',
}
