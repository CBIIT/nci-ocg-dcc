# data_util config
{
    'sync_dcc_data' => {
        'default_rsync_opts' => '-rtmv',
        'program_dests' => {
            'TARGET' => [qw(
                PreRelease
                Controlled
                Public
                Release
                Germline
                BCCA
            )],
            'CGCI' => [qw(
                PreRelease
                Controlled
                Public
                Release
                BCCA
            )],
            'CTD2' => [qw(
                Network
                Public
                Release
            )],
        },
        'data_type_sync_config' => {
            'biospecimen' => {
                'default' => {
                    'controlled' => {
                        'no_data' => 1,
                    },
                },
            },
            'Bisulfite-seq' => {
                'default' => {
                    'L1' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
            },
            'ChIP-seq' => {
                'default' => {
                    'L1' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
            },
            'clinical' => {
                'default' => {
                    'controlled' => {
                        'includes' => [
                            '*/',
                            '/controlled/*',
                            '/protected/*',
                            '/controlled/harmonized/***',
                            '/protected/harmonized/***',
                        ],
                        'excludes' => [
                            '*',
                        ],
                    },
                    'public' => {
                        'excludes' => [
                            '/controlled',
                            '/protected',
                            '/public/orig_file',
                            '/orig_file',
                            'controlled',
                            'protected',
                        ],
                    },
                },
            },
            'copy_number_array' => {
                'default' => {
                    'L1' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'DESIGN' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
                'custom' => {
                    'TARGET' => {
                        'Resources' => {
                            'controlled' => {
                                'no_data' => 1,
                            },
                        },
                    },
                },
            },
            'gene_expression_array' => {
                'default' => {
                    'L1' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
                'custom' => {
                    'TARGET' => {
                        'NBL' => {
                            'L1' => {
                                'public' => {
                                    'no_data' => 1,
                                },
                            },
                            'L2' => {
                                'public' => {
                                    'no_data' => 1,
                                },
                            },
                            'L3' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                            'L4' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                            'METADATA' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                        },
                        'OS' => {
                            'L1' => {
                                'public' => {
                                    'no_data' => 1,
                                },
                            },
                            'L2' => {
                                'public' => {
                                    'no_data' => 1,
                                },
                            },
                            'L3' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                            'L4' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                            'METADATA' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                        },
                        'OS-Brazil' => {
                            'L1' => {
                                'public' => {
                                    'no_data' => 1,
                                },
                            },
                            'L2' => {
                                'public' => {
                                    'no_data' => 1,
                                },
                            },
                            'L3' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                            'L4' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                            'METADATA' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                        },
                        'OS-Toronto' => {
                            'L1' => {
                                'public' => {
                                    'no_data' => 1,
                                },
                            },
                            'L2' => {
                                'public' => {
                                    'no_data' => 1,
                                },
                            },
                            'L3' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                            'L4' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                            'METADATA' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                        },
                    },
                },
            },
            'GWAS' => {
                'default' => {
                    'L1' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
            },
            'kinome' => {
                'default' => {
                    'L1' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
            },
            'methylation_array' => {
                'default' => {
                    'L1' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'DESIGN' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
            },
            'miRNA_array' => {
                'default' => {
                    'L1' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
            },
            'miRNA_pcr' => {
                'default' => {
                    'L1' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
            },
            'misc' => {
                'default' => {
                    'controlled' => {
                        'no_data' => 1,
                    },
                },
            },
            'miRNA-seq' => {
                'default' => {
                    'L1' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
            },
            'mRNA-seq' => {
                'default' => {
                    'L1' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'controlled' => {
                            'excludes' => [
                                '/expression',
                            ],
                        },
                        'public' => {
                            'excludes' => [
                                '/mutation',
                                '/structural',
                            ],
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
            },
            'pathology_images' => {
                'default' => {
                    'controlled' => {
                        'no_data' => 1,
                    },
                },
            },
            'SAMPLE_MATRIX' => {
                'default' => {
                    'controlled' => {
                        'no_data' => 1,
                    },
                    'public' => {
                        'copy_links' => 1,
                    },
                },
                'custom' => {
                    'TARGET' => {
                        'Resources' => {
                            'controlled' => {
                                'no_data' => 1,
                            },
                        },
                    },
                    'CGCI' => {
                        'Resources' => {
                            'controlled' => {
                                'no_data' => 1,
                            },
                        },
                    },
                },
            },
            'targeted_capture_sequencing' => {
                'default' => {
                    'L1' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'DESIGN' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
                'custom' => {
                    'TARGET' => {
                        'NBL' => {
                            'L1' => {
                                'public' => {
                                    'no_data' => 1,
                                },
                            },
                            'L2' => {
                                'public' => {
                                    'no_data' => 1,
                                },
                            },
                            'L3' => {
                                'controlled' => {
                                    'excludes' => [
                                        '/copy_number/*/*[Ss]omatic*',
                                    ],
                                },
                                'public' => {
                                    'includes' => [
                                        '*/',
                                        '/copy_number/*/*[Ss]omatic*/***',
                                    ],
                                    'excludes' => [
                                        '*',
                                    ],
                                },
                            },
                            'L4' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                            'METADATA' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                            'DESIGN' => {
                                'controlled' => {
                                    'no_data' => 1,
                                },
                            },
                        },
                    },
                },
            },
            'targeted_pcr_sequencing' => {
                'default' => {
                    'L1' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
            },
            'WGS' => {
                'default' => {
                    'CGI' => {
                        'public' => {
                            'includes' => [
                                '*/',
                                '/README*/***',
                            ],
                            'excludes' => [
                                '*',
                            ],
                        },
                    },
                    'L1' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'controlled' => {
                            'no_delete_excluded' => 1,
                            'excludes' => [
                                '/copy_number',
                                '/mutation/*/FullMafsVcfs',
                                '/mutation/*/*[Vv]erified*',
                            ],
                        },
                        'public' => {
                            'includes' => [
                                '*/',
                                '/copy_number/***',
                                '/mutation/*/*[Vv]erified*/***',
                            ],
                            'excludes' => [
                                '*',
                            ],
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
                'custom' => {
                    'TARGET' => {
                        'Resources' => {
                            'controlled' => {
                                'no_data' => 1,
                            },
                        },
                    },
                    'CGCI' => {
                        'Resources' => {
                            'controlled' => {
                                'no_data' => 1,
                            },
                        },
                    },
                },
            },
            'WXS' => {
                'default' => {
                    'L1' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L2' => {
                        'public' => {
                            'no_data' => 1,
                        },
                    },
                    'L3' => {
                        'controlled' => {
                            'excludes' => [
                                '/copy_number',
                                '/mutation/*/*[Vv]erified*',
                            ],
                        },
                        'public' => {
                            'includes' => [
                                '*/',
                                '/copy_number/***',
                                '/mutation/*/*[Vv]erified*/***',
                            ],
                            'excludes' => [
                                '*',
                            ],
                        },
                    },
                    'L4' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'METADATA' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                    'DESIGN' => {
                        'controlled' => {
                            'no_data' => 1,
                        },
                    },
                },
                'custom' => {
                    'TARGET' => {
                        'Resources' => {
                            'controlled' => {
                                'no_data' => 1,
                            },
                        },
                    },
                    'CGCI' => {
                        'Resources' => {
                            'controlled' => {
                                'no_data' => 1,
                            },
                        },
                    },
                },
            },
        },
    },
}
