# services conf
{
    'watch_dcc_uploads' => {
        'email_from_address_prefix' => 'OCG DCC Upload Watcher <donotreply@',
        'email_from_address_suffix' => '>',
        'email_to_addresses' => [qw(
            patee.gesuwan@nih.gov
            yiwen.he@nih.gov
        )],
        'email_cc_addresses' => [qw(
            tanja.davidsen@nih.gov
            daniela.gerhard@nih.gov
        )],
        'program_config' => {
            'TARGET' => {
                dirs_to_watch => [
                    '/local/ocg-dcc/upload/TARGET',
                ],
                dirs_to_exclude => [
                    '/local/ocg-dcc/upload/TARGET/.snapshot',
                ],
                email_cc_addresses => [
                    'jaime.guidryauvil@nih.gov',
                ],
            },
            'CGCI' => {
                dirs_to_watch => [
                    '/local/ocg-dcc/upload/CGCI',
                ],
                dirs_to_exclude => [
                    '/local/ocg-dcc/upload/CGCI/.snapshot',
                ],
                email_cc_addresses => [
                    'nicholas.griner@nih.gov'
                ],
            },
            'CTD2' => {
                dirs_to_watch => [
                    '/local/ocg-dcc/upload/CTD2',
                ],
                dirs_to_exclude => [
                    '/local/ocg-dcc/upload/CTD2/.snapshot',
                ],
                email_cc_addresses => [
                    'pamela.birriel@nih.gov',
                ],
            },
            'GMKF' => {
                dirs_to_watch => [
                    '/local/ocg-dcc/upload/GMKF',
                ],
                dirs_to_exclude => [
                    '/local/ocg-dcc/upload/GMKF/.snapshot',
                ],
                email_cc_addresses => [
                    'jaime.guidryauvil@nih.gov',
                ],
	    },
            'CMDC' => {
                dirs_to_watch => [
                    '/local/ocg-dcc/upload/CMDC',
                ],
                dirs_to_exclude => [
                    '/local/ocg-dcc/upload/CMDC/.snapshot',
                ],
                email_cc_addresses => [
		    'conrado.soria@nih.gov',
		    'anand.merchant@nih.gov',
		    'julyann.perez-mayoral@nih.gov',
                ],
            },
        },
    },
    'watch_dcc_data' => {
        'email_from_address_prefix' => 'OCG DCC Data Watcher <donotreply@',
        'email_from_address_suffix' => '>',
        'email_to_addresses' => [qw(
            
        )],
        'email_cc_addresses' => [qw(
            
        )],
        'program_config' => {
            'TARGET' => {
                dirs_to_watch => [
                    '/local/ocg-dcc/data/TARGET',
                    '/local/ocg-dcc/download/TARGET',
                ],
                dirs_to_exclude => [
                    '/local/ocg-dcc/data/TARGET/.snapshot',
                    '/local/ocg-dcc/download/TARGET/.snapshot',
                ],
            },
            'CGCI' => {
                dirs_to_watch => [
                    '/local/ocg-dcc/data/CGCI',
                    '/local/ocg-dcc/download/CGCI',
                ],
                dirs_to_exclude => [
                    '/local/ocg-dcc/data/CGCI/.snapshot',
                    '/local/ocg-dcc/download/CGCI/.snapshot',
                ],
            },
            'CTD2' => {
                dirs_to_watch => [
                    '/local/ocg-dcc/data/CTD2',
                    '/local/ocg-dcc/download/CTD2',
                ],
                dirs_to_exclude => [
                    '/local/ocg-dcc/data/CTD2/.snapshot',
                    '/local/ocg-dcc/download/CTD2/.snapshot',
                ],
            },
            'GMKF' => {
                dirs_to_watch => [
                    '/local/ocg-dcc/data/GMKF',
                    '/local/ocg-dcc/download/GMKF',
                ],
                dirs_to_exclude => [
                    '/local/ocg-dcc/data/GMKF/.snapshot',
                    '/local/ocg-dcc/download/GMKF/.snapshot',
                ],
            },
            'CMDC' => {
                dirs_to_watch => [
                    '/local/ocg-dcc/data/CMDC',
                    '/local/ocg-dcc/download/CMDC',
                ],
                dirs_to_exclude => [
                    '/local/ocg-dcc/data/CMDC/.snapshot',
                    '/local/ocg-dcc/download/CMDC/.snapshot',
                ],
            },
        },
    },
}
