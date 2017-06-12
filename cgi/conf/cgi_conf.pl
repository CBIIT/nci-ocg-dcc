# cgi config
{
    'program_names' => [qw(
        TARGET
    )],
    'program_project_names' => {
        'TARGET' => [qw(
            ALL
            AML
            CCSK
            NBL
            MDLS-NBL
            OS
            OS-Toronto
            WT
        )],
    },
    'program_subproject_names' => {
        'TARGET' => [qw(
            NBL
            Toronto
        )],
    },
    'job_types' => [qw(
        BCCA
        FullMafsVcfs
        Germline
        SomaticVcfs
        TEMP
    )],
    'data_type_dir_name' => 'WGS',
    'dir_name' => 'CGI',
    'analysis_dir_names' => [qw(
        PilotAnalysisPipeline2
        OptionAnalysisPipeline2
    )],
    'manifest_file_names' => [qw(
        manifest.all.unencrypted
        manifest.dcc.unencrypted
    )],
    'skip_file_names' => [qw(
        manifest.all.unencrypted.sig
        sha256output
        idMap.tsv
    )],
    'data_filesys_info' => {
        'adm_owner_name' => 'ocg-dcc-adm',
        'adm_group_name' => 'ocg-dcc-adm',
        'data_dir_mode' => 0770,
        'data_file_mode' => 0660,
        'dn_adm_group_name' => 'ocg-dn-ro',
        'dn_ctrld_group_name' => 'target-dn-ctrld',
        'dn_ctrld_dir_mode' => 0550,
        'dn_ctrld_dir_mode_str' => '550',
        'dn_ctrld_file_mode' => 0440,
        'dn_ctrld_file_mode_str' => '440',
        'manifest_file_mode' => 0444,
        'manifest_file_mode_str' => '444',
    },
}
