# manifests config
{
    'default_manifest_file_name' => 'MANIFEST.txt',
    'manifest_delimiter_regexp' => qr/( (?:\*| )?)/,
    'manifest_out_delimiter' => ' *',
    'manifest_supported_checksum_algs' => [qw(
        sha256
        md5
    )],
    'program_manifest_default_checksum_alg' => {
        'TARGET' => 'sha256',
        'CGCI'   => 'md5',
        'CTD2'   => 'md5',
        'GMKF'   => 'md5',
	'CMDC'   => 'md5',
    },
    'data_filesys_info' => {
        'manifest_user_name' => 'ocg-dcc-adm',
        'manifest_group_name' => 'ocg-dcc-adm',
        'manifest_file_mode' => 0440,
        'manifest_file_mode_str' => '440',
    },
    'generate_merged_manifest' => {
        'program_download_search_skip_dirs' => {
            'TARGET' => {
                'dirs_to_search' => [
                    'Controlled',
                    'PreRelease/ALL/mRNA-seq/Phase2/L1',
                    'PreRelease/ALL/WGS/Phase2/L2',
                    'PreRelease/OS/WGS/L2',
                    'PreRelease/OS/WXS/L2',
                    'Public',
                ],
                'dirs_to_skip' => [
                    'Controlled/CGI',
                    'Controlled/OS/Brazil',
                    'Controlled/OS/Toronto',
                    'Public/DBGAP_METADATA',
                    'Public/OS/Brazil',
                    'Public/OS/Toronto',
                    'Public/Resources/copy_number_array',
                    'Public/Resources/SAMPLE_MATRIX',
                    'Public/Resources/WGS',
                ],
            },
            'CGCI' => {
                'dirs_to_search' => [
                    'Controlled',
                    'Public',
                ],
                'dirs_to_skip' => [
                    'Controlled/CGI',
                    'Public/DBGAP_METADATA',
                    'Public/Resources',
                ],
            },
            'CTD2' => {
                'dirs_to_search' => [
                    'Public',
                ],
                'dirs_to_skip' => [
                    'Public/Dashboard',
                    'Public/Resources',
                ],
            },
            'GMKF' => {
                'dirs_to_search' => [
                    'Controlled',
                    'Public',
                ],
                'dirs_to_skip' => [
                    'Controlled/CGI',
                    'Public/DBGAP_METADATA',
                    'Public/Resources',
                ],
            },
        },
    },
}
