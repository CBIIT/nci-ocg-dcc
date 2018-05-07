# common config
{
    'program_names' => [qw(
        TARGET
        CGCI
        CTD2
        GMKF
        CMDC
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
        'GMKF' => [qw(
            BASIC3
            EWS
            LEUK
            NBL
            OS
        )],
        'CMDC' => [qw(
            DCC
            Model_QC_Data
        )],
    },
    'program_project_names_w_subprojects' => {
        'TARGET' => [qw(
            MDLS-NBL
            MDLS-PPTP
            OS-Brazil
            OS-Toronto
        )],
    },
    'programs_w_data_types' => [qw(
        TARGET
        CGCI
        GMKF
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
        qc_images
        SAMPLE_MATRIX
        shipping_manifests
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
    'data_level_dir_names' => [qw(
        L1
        L2
        L3
        L4
        METADATA
        CGI
        DESIGN
    )],
    'data_filesys_info' => {
        'adm_owner_name' => 'ocg-dcc-adm',
        'adm_group_name' => 'ocg-dcc-adm',
        'dn_ro_group_name' => 'ocg-dn-ro',
        'program_dn_group_name' => {
            'TARGET' => 'ocg-dn-ro',
            'CGCI'   => 'ocg-dn-ro',
            'CTD2'   => 'ctd2-dn-net',
            'GMKF'   => 'ocg-dn-ro',
            'CMDC'   => 'cmdc-dn-intnl',
        },
        'program_dn_ctrld_group_name' => {
            'TARGET' => 'target-dn-ctrld',
            'CGCI'   => 'cgci-dn-ctrld',
            'CTD2'   => 'ctd2-dn-net',
            'GMKF'   => 'gmkf-dn-ctrld',
            'CMDC'   => 'cmdc-dn-intnl',
        },
        'program_project_dn_ctrld_group_name' => {
            'CGCI' => {
                'MB' => 'cgci-dn-ctrld-ped',
            },
        },
        'data_dir_mode' => 0770,
        'data_dir_mode_str' => '770',
        'data_file_mode' => 0660,
        'data_file_mode_str' => '660',
        'dn_ctrld_dir_mode' => 0550,
        'dn_ctrld_dir_mode_str' => '550',
        'dn_ctrld_file_mode' => 0440,
        'dn_ctrld_file_mode_str' => '440',
        'dn_public_dir_mode' => 0555,
        'dn_public_dir_mode_str' => '555',
        'dn_public_file_mode' => 0444,
        'dn_public_file_mode_str' => '444',
    },
    'pp_compile' => {
        'script_compile_includes' => {
            'check_manifests' => {
                'modules' => [
                    'Config::Any::Perl',
                ],
                'file_paths_from_base' => [
                    'cgi/conf/cgi_conf.pl',
                    'common/conf/common_conf.pl',
                    'manifests/conf/manifests_conf.pl',
                ],
            },
            'generate_merged_manifest' => {
                'modules' => [
                    'Config::Any::Perl',
                ],
                'file_paths_from_base' => [
                    'cgi/conf/cgi_conf.pl',
                    'common/conf/common_conf.pl',
                    'manifests/conf/manifests_conf.pl',
                ],
            },
            'sync_dcc_data' => {
                'modules' => [
                    'Config::Any::Perl',
                ],
                'file_paths_from_base' => [
                    'cgi/conf/cgi_conf.pl',
                    'common/conf/common_conf.pl',
                    'data_util/conf/data_util_conf.pl',
                ],
            },
            'watch_dcc_data' => {
                'modules' => [
                    'Config::Any::Perl',
                    'File::ChangeNotify',
                    'File::ChangeNotify::Watcher',
                    'Email::Sender',
                    'Email::Sender::Role::CommonSending',
                    'Throwable',
                    'Throwable::Error',
                    'StackTrace::Auto',
                    'List::MoreUtils::PP',
                    'Email::Abstract::EmailSimple',
                ],
                'file_paths_from_base' => [
                    'common/conf/common_conf.pl',
                    'services/conf/services_conf.pl',
                ],
            },
            'watch_dcc_uploads' => {
                'modules' => [
                    'Config::Any::Perl',
                    'File::ChangeNotify',
                    'File::ChangeNotify::Watcher',
                    'Email::Sender',
                    'Email::Sender::Role::CommonSending',
                    'Throwable',
                    'Throwable::Error',
                    'StackTrace::Auto',
                    'List::MoreUtils::PP',
                    'Email::Abstract::EmailSimple',
                ],
                'file_paths_from_base' => [
                    'common/conf/common_conf.pl',
                    'services/conf/services_conf.pl',
                ],
            },
        },
    },
}
