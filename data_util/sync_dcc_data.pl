#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw(fileparse);
use File::Path 2.11 qw(make_path remove_tree);
use Getopt::Long qw(:config auto_help auto_version);
use List::Util qw(any all none);
use List::MoreUtils qw(uniq);
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natsort);
use Term::ANSIColor;
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
my @program_names = qw(
    TARGET
    CGCI
    CTD2
);
my %program_project_names = (
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
        Columbia
        CSHL
        DFCI
        Emory
        FHCRC-1
        FHCRC-2
        MDACC
        Stanford
        TGen
        UCSF-1
        UCSF-2
        UTSW
        Resources
    )],
);
my @data_types = qw(
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
);
my @data_types_w_data_levels = qw(
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
);
my $target_cgi_dir_name = 'CGI';
my @data_level_dir_names = (
    'L1',
    'L2',
    'L3',
    'L4',
    'METADATA',
    $target_cgi_dir_name,
    'DESIGN',
);
my @dests = qw(
    PreRelease
    Controlled
    Public
    Release
    Germline
    BCCA
);
my @param_groups = qw(
    programs
    projects
    data_types
    data_sets
    data_level_dirs
    dests
);
my $default_manifest_file_name = 'MANIFEST.txt';
my $owner_name = 'ocg-dcc-adm';
my $ctrld_dir_mode = 0550;
my $ctrld_dir_mode_str = '550';
my $ctrld_file_mode = 0440;
my $ctrld_file_mode_str = '440';
my $public_dir_mode = 0555;
my $public_dir_mode_str = '555';
my $public_file_mode = 0444;
my $public_file_mode_str = '444';
my $default_rsync_opts = '-rtmv';
my %sync_config = (
    'biospecimen' => {
        '_default' => {
            'controlled' => {
                'no_data' => 1,
            },
        },
    },
    'Bisulfite-seq' => {
        '_default' => {
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
        '_default' => {
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
        '_default' => {
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
        '_default' => {
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
        '_custom' => {
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
        '_default' => {
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
        '_custom' => {
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
        '_default' => {
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
        '_default' => {
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
        '_default' => {
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
        '_default' => {
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
        '_default' => {
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
        '_default' => {
            'controlled' => {
                'no_data' => 1,
            },
        },
    },
    'miRNA-seq' => {
        '_default' => {
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
        '_default' => {
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
        '_default' => {
            'controlled' => {
                'no_data' => 1,
            },
        },
    },
    'SAMPLE_MATRIX' => {
        '_default' => {
            'controlled' => {
                'no_data' => 1,
            },
            'public' => {
                'copy_links' => 1,
            },
        },
        '_custom' => {
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
        '_default' => {
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
        '_custom' => {
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
        '_default' => {
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
        '_default' => {
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
        '_custom' => {
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
        '_default' => {
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
        '_custom' => {
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
);

# validate sync config
sub check_sync_config_node {
    my ($data_type, $config_section_hashref) = @_;
    for my $dest (map(lc, @dests)) {
        if (defined($config_section_hashref->{$dest})) {
            if (defined($config_section_hashref->{$dest}->{excludes})) {
                for my $type (qw( excludes includes )) {
                    if (
                        defined($config_section_hashref->{$dest}->{$type}) and
                        ref($config_section_hashref->{$dest}->{$type}) ne 'ARRAY'
                    ) {
                        die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                            ": invalid $data_type $dest $type rsync pattern config\n";
                    }
                }
            }
        }
    }
}

for my $data_type (@data_types) {
    if (
        defined($sync_config{$data_type}) and
        defined($sync_config{$data_type}{'_default'})
    ) {
        if (any { $data_type eq $_ } @data_types_w_data_levels) {
            for my $data_level_dir_name (@data_level_dir_names) {
                if (defined($sync_config{$data_type}{'_default'}{$data_level_dir_name})) {
                    check_sync_config_node(
                        $data_type,
                        $sync_config{$data_type}{'_default'}{$data_level_dir_name},
                    );
                }
            }
        }
        else {
            check_sync_config_node(
                $data_type,
                $sync_config{$data_type}{'_default'},
            );
        }
    }
    else {
        die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
            ": missing/invalid '$data_type' rsync include/exclude pattern config\n";
    }
    if (defined($sync_config{$data_type}{'_custom'})) {
        for my $program_name (natsort keys %{$sync_config{$data_type}{'_custom'}}) {
            if (any { $program_name eq $_ } @program_names) {
                for my $project_name (natsort keys %{$sync_config{$data_type}{'_custom'}{$program_name}}) {
                    if (any { $project_name eq $_ } @{$program_project_names{$program_name}}) {
                        if (any { $data_type eq $_ } @data_types_w_data_levels) {
                            for my $data_level_dir_name (@data_level_dir_names) {
                                if (defined($sync_config{$data_type}{'_custom'}{$program_name}{$project_name}{$data_level_dir_name})) {
                                    check_sync_config_node(
                                        $data_type,
                                        $sync_config{$data_type}{'_custom'}{$program_name}{$project_name}{$data_level_dir_name},
                                    );
                                }
                            }
                        }
                        else {
                            check_sync_config_node(
                                $data_type,
                                $sync_config{$data_type}{'_custom'}{$program_name}{$project_name},
                            );
                        }
                    }
                    else {
                        die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                            ": invalid $data_type rsync include/exclude pattern custom config\n";
                    }
                }
            }
            else {
                die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                    ": invalid $data_type rsync include/exclude pattern custom config\n";
            }
        }
    }
}

my $dry_run = 0;
my $delete = 0;
my $verbose = 0;
my $debug = 0;
GetOptions(
    'dry-run' => \$dry_run,
    'delete' => \$delete,
    'verbose' => \$verbose,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
if ($< != 0 and !$dry_run) {
    pod2usage(
        -message => 'Script must be run with sudo',
        -verbose => 0,
    );
}
my %user_params;
if (@ARGV) {
    for my $i (0 .. $#param_groups) {
        next unless defined $ARGV[$i] and $ARGV[$i] !~ /^\s*$/;
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
                $user_param = 'mRNA-seq' if $user_param =~ /^RNA-seq$/i;
            }
            for my $data_type (@data_types) {
                push @valid_user_params, $data_type if any { m/^$data_type$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @data_types;
            }
            @valid_choices = @data_types;
        }
        elsif ($param_groups[$i] eq 'dests') {
            for my $dest (@dests) {
                push @valid_user_params, $dest if any { m/^$dest$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @dests;
            }
            @valid_choices = @dests;
        }
        elsif ($param_groups[$i] eq 'data_level_dirs') {
            for my $data_level_dir_name (@data_level_dir_names) {
                push @valid_user_params, $data_level_dir_name if any { m/^$data_level_dir_name$/i } @user_params;
            }
            for my $user_param (@user_params) {
                push @invalid_user_params, $user_param if none { m/^$user_param$/i } @data_level_dir_names;
            }
            @valid_choices = @data_level_dir_names;
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
# Release dest
if (
    exists($user_params{dests}) and
    any { $_ eq 'Release' } @{$user_params{dests}}
) {
    $user_params{dests} = [qw(
        Controlled
        Public
        Release
    )];
}
print STDERR "\%user_params:\n", Dumper(\%user_params) if $debug;
for my $program_name (@program_names) {
    next if defined $user_params{programs} and none { $program_name eq $_ } @{$user_params{programs}};
    for my $project_name (@{$program_project_names{$program_name}}) {
        next if defined $user_params{projects} and none { $project_name eq $_ } @{$user_params{projects}};
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
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid subproject '$subproject'\n";
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
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid subproject '$subproject'\n";
                }
            }
            else {
                die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": invalid disease project '$disease_proj'\n";
            }
        }
        DATA_TYPE: for my $data_type (@data_types) {
            next if defined $user_params{data_types} and none { $data_type eq $_ } @{$user_params{data_types}};
            (my $data_type_dir_name = $data_type) =~ s/-Seq$/-seq/i;
            my $data_type_dir = "/local/\L$program_name\E/data/$project_dir/$data_type_dir_name";
            next unless -d $data_type_dir;
            opendir(my $data_type_dh, $data_type_dir) 
                or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $data_type_dir: $!";
            my @data_type_sub_dir_names = grep { -d "$data_type_dir/$_" and !m/^\./ } readdir($data_type_dh);
            closedir($data_type_dh);
            my @datasets;
            if (all { m/^(current|old)$/ } @data_type_sub_dir_names) {
                push @datasets, '';
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
            for my $dataset (@datasets) {
                next if defined $user_params{data_sets} and none { $dataset eq $_ } @{$user_params{data_sets}};
                my $dataset_dir = $data_type_dir . ($dataset eq '' ? $dataset : "/$dataset" ) . '/current';
                next unless -d $dataset_dir;
                for my $dest (@dests) {
                    next if (!defined $user_params{dests} and $dest ne 'PreRelease') or
                            ( defined $user_params{dests} and none { $dest eq $_ } @{$user_params{dests}});
                    my $download_dir = 'download';
                    if ($dest eq 'Controlled') {
                        $download_dir = $project_name eq 'MB'
                                      ? "$download_dir/${dest}_Pediatric"
                                      : "$download_dir/$dest";
                    }
                    elsif ($dest eq 'Release') {
                        $download_dir = "$download_dir/PreRelease";
                    }
                    else {
                        $download_dir = "$download_dir/$dest";
                    }
                    my $dest_data_type_dir = "/local/\L$program_name\E/$download_dir/$project_dir/$data_type_dir_name";
                    my $dest_dataset_dir = $dest_data_type_dir . ( $dataset ? "/$dataset" : '' );
                    my $group_name = $dest eq 'Controlled'
                                   ? ( $program_name eq 'CGCI' and $project_name eq 'MB' )
                                       ? "\L$program_name\E-dn-ctrld-ped"
                                       : "\L$program_name\E-dn-ctrld"
                                   : ( $program_name eq 'CTD2' ) 
                                       ? 'ctd2-dn-net'
                                       : "\L$program_name\E-dn-adm";
                    # data types that have data levels (except for Resources datasets)
                    if (( any { $data_type eq $_ } @data_types_w_data_levels ) and $project_name ne 'Resources') {
                        for my $data_level_dir_name (@data_level_dir_names) {
                            next if defined($user_params{data_level_dirs}) and none { $data_level_dir_name eq $_ } @{$user_params{data_level_dirs}};
                            my $data_level_dir = "$dataset_dir/$data_level_dir_name";
                            next unless -d $data_level_dir;
                            my $dest_data_level_dir = "$dest_dataset_dir/$data_level_dir_name";
                            my $header = "[$program_name $project_name $data_type" . ( $dataset ? " $dataset" : '' ) . " $dest $data_level_dir_name]";
                            my $dest_node_sync_config_hashref;
                            if (
                                defined($sync_config{$data_type}{'_custom'}) and
                                defined($sync_config{$data_type}{'_custom'}{$program_name}) and
                                defined($sync_config{$data_type}{'_custom'}{$program_name}{$project_name}) and
                                defined($sync_config{$data_type}{'_custom'}{$program_name}{$project_name}{$data_level_dir_name})
                            ) {
                                if (defined($sync_config{$data_type}{'_custom'}{$program_name}{$project_name}{$data_level_dir_name}{lc($dest)})) {
                                    $dest_node_sync_config_hashref =
                                        $sync_config{$data_type}{'_custom'}{$program_name}{$project_name}{$data_level_dir_name}{lc($dest)};
                                }
                            }
                            elsif (
                                defined($sync_config{$data_type}{'_default'}) and
                                defined($sync_config{$data_type}{'_default'}{$data_level_dir_name}) and
                                defined($sync_config{$data_type}{'_default'}{$data_level_dir_name}{lc($dest)})
                            ) {
                                $dest_node_sync_config_hashref = $sync_config{$data_type}{'_default'}{$data_level_dir_name}{lc($dest)};
                            }
                            if (
                                $dest ne 'Release' and 
                                (
                                    !defined($dest_node_sync_config_hashref) or
                                    !exists($dest_node_sync_config_hashref->{no_data})
                                )
                            ) {
                                print "$header\n";
                                sync_to_dest(
                                    $dest,
                                    $data_level_dir,
                                    $dest_data_level_dir,
                                    $dest_node_sync_config_hashref,
                                    $group_name,
                                );
                                print "\n";
                            }
                            elsif (-e $dest_data_level_dir) {
                                print "$header\n";
                                if ($dest ne 'Release' or $delete) {
                                    clean_up_dest($dest_data_level_dir);
                                }
                                else {
                                    print "Keeping $dest_data_level_dir\n";
                                }
                                print "\n";
                            }
                        }
                    }
                    # data types that don't have data levels (and Resources datasets)
                    elsif (!defined $user_params{data_level_dirs}) {
                        my $header = "[$program_name $project_name $data_type" . ( $dataset ? " $dataset" : '' ) . " $dest]";
                        my $dest_node_sync_config_hashref;
                        if (
                            defined($sync_config{$data_type}{'_custom'}) and
                            defined($sync_config{$data_type}{'_custom'}{$program_name}) and
                            defined($sync_config{$data_type}{'_custom'}{$program_name}{$project_name})
                        ) {
                            if (defined($sync_config{$data_type}{'_custom'}{$program_name}{$project_name}{lc($dest)})) {
                                $dest_node_sync_config_hashref = $sync_config{$data_type}{'_custom'}{$program_name}{$project_name}{lc($dest)};
                            }
                        }
                        elsif (
                            defined($sync_config{$data_type}{'_default'}) and
                            defined($sync_config{$data_type}{'_default'}{lc($dest)})
                        ) {
                           $dest_node_sync_config_hashref = $sync_config{$data_type}{'_default'}{lc($dest)};
                        }
                        if (
                            $dest ne 'Release' and 
                            (
                                !defined($dest_node_sync_config_hashref) or
                                !exists($dest_node_sync_config_hashref->{no_data})
                            )
                        ) {
                            print "$header\n";
                            sync_to_dest(
                                $dest,
                                $dataset_dir,
                                $dest_dataset_dir,
                                $dest_node_sync_config_hashref,
                                $group_name,
                            );
                            print "\n";
                        }
                        elsif (-e $dest_dataset_dir) {
                            print "$header\n";
                            if ($dest ne 'Release' or $delete) {
                                clean_up_dest($dest_dataset_dir);
                            }
                            else {
                                print "Keeping $dest_dataset_dir\n";
                            }
                            print "\n";
                        }
                    }
                    # clean up empty dest dirs (during Release or to clean up when nothing gets synced)
                    my $header = "[$program_name $project_name $data_type" . ( $dataset ? " $dataset" : '' ) . " $dest]";
                    my ($printed_header, $empty_dirs_exist);
                    for my $dest_dir ($dest_dataset_dir, $dest_data_type_dir) {
                        if (-d -z $dest_dir) {
                            if (( any { $data_type eq $_ } @data_types_w_data_levels ) and !$printed_header) {
                                print "$header\n";
                                $printed_header++;
                            }
                            clean_up_dest($dest_dir);
                            $empty_dirs_exist++;
                        }
                    }
                    print "\n" if $empty_dirs_exist;
                }
            }
        }
    }
}
exit;

sub sync_to_dest {
    my (
        $dest,
        $src_dir,
        $dest_dir,
        $dest_node_sync_config_hashref,
        $group_name,
    ) = @_;
    my (
        $dir_mode, $dir_mode_str,
        $file_mode, $file_mode_str,
    );
    # Controlled
    if ($dest eq 'Controlled') {
        $dir_mode = $ctrld_dir_mode;
        $dir_mode_str = $ctrld_dir_mode_str;
        $file_mode = $ctrld_file_mode;
        $file_mode_str = $ctrld_file_mode_str;
    }
    # Public
    elsif ($dest eq 'Public') {
        $dir_mode = $public_dir_mode;
        $dir_mode_str = $public_dir_mode_str;
        $file_mode = $public_file_mode;
        $file_mode_str = $public_file_mode_str;
    }
    # PreRelease, BCCA, Germline
    else {
        $dir_mode = $ctrld_dir_mode;
        $dir_mode_str = $ctrld_dir_mode_str;
        $file_mode = $ctrld_file_mode;
        $file_mode_str = $ctrld_file_mode_str;
    }
    # create/set up dest dir if needed
    if (-l $src_dir and $dest eq 'PreRelease') {
        if (-e $dest_dir) {
            if (!-l $dest_dir) {
                print "Deleting $dest_dir\n";
                if (!$dry_run) {
                    remove_tree($dest_dir, {
                        verbose => $verbose,
                        error => \my $err,
                    });
                    if (@{$err}) {
                        for my $diag (@{$err}) {
                            my ($file, $message) = %{$diag};
                            warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                 ": could not delete $file: $message\n";
                        }
                        return;
                    }
                }
            }
            elsif (readlink($src_dir) ne readlink($dest_dir)) {
                print "Removing symlink $dest_dir\n";
                if (!$dry_run) {
                    if (!unlink($dest_dir)) { 
                        warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                             ": could not unlink $dest_dir: $!\n";
                        return;
                    }
                }
            }
        }
        if (!-e $dest_dir) {
            print "Creating symlink $dest_dir\n";
            if (!$dry_run) {
                my $dest_parent_dir = (fileparse($dest_dir))[1];
                if (!-d $dest_parent_dir) {
                    make_path($dest_parent_dir, {
                        chmod => $dir_mode,
                        owner => $owner_name,
                        group => $group_name,
                        error => \my $err,
                    });
                    if (@{$err}) {
                        for my $diag (@{$err}) {
                            my ($file, $message) = %{$diag};
                            warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                                 ": could not create $file: $message\n";
                        }
                        return;
                    }
                }
                if (!symlink(readlink($src_dir), $dest_dir)) {
                    warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                    ": could not create link $dest_dir: $!\n";
                    return;
                }
            }
        }
    }
    elsif (!-d $dest_dir) {
        print "Creating $dest_dir\n";
        if (!$dry_run) {
            make_path($dest_dir, {
                chmod => $dir_mode,
                owner => $owner_name,
                group => $group_name,
                error => \my $err,
            });
            if (@{$err}) {
                for my $diag (@{$err}) {
                    my ($file, $message) = %{$diag};
                    warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                         ": could not create $file: $message\n";
                }
                return;
            }
        }
    }
    my $rsync_incl_excl_str = '';
    if (
        any { $dest eq $_ } qw( PreRelease Controlled Public ) and
        defined($dest_node_sync_config_hashref)
    ) {
        # includes (always before excludes)
        if (defined($dest_node_sync_config_hashref->{includes})) {
            $rsync_incl_excl_str .= ' ' if $rsync_incl_excl_str;
            $rsync_incl_excl_str .= join(' ', 
                map { "--include=\"$_\"" } @{$dest_node_sync_config_hashref->{includes}}
            );
        }
        # excludes
        if (defined($dest_node_sync_config_hashref->{excludes})) {
            $rsync_incl_excl_str .= ' ' if $rsync_incl_excl_str;
            $rsync_incl_excl_str .= join(' ', 
                map { "--exclude=\"$_\"" } @{$dest_node_sync_config_hashref->{excludes}}
            );
        }
    }
    my @rsync_opts = ( $default_rsync_opts );
    push @rsync_opts, ( $dest_node_sync_config_hashref->{copy_links} ? '--copy-links' : '--links' );
    push @rsync_opts, '--dry-run' if $dry_run;
    push @rsync_opts, '--delete' if $delete;
    if (
        defined($dest_node_sync_config_hashref->{excludes}) and 
        !$dest_node_sync_config_hashref->{no_delete_excluded}
    ) {
        push @rsync_opts, '--delete-excluded';
    }
    my $rsync_opts_str = join(' ', @rsync_opts);
    # make sure rsync src and dest paths always finish with /
    my $rsync_cmd_str      = "rsync $rsync_opts_str $rsync_incl_excl_str \"$src_dir/\" \"$dest_dir/\"";
    my $rmdir_cmd_str      = "find $dest_dir -depth -type d -empty -exec rmdir -v {} \\;";
    my $dir_chmod_cmd_str  = "find $dest_dir -type d -exec chmod $dir_mode_str {} \\;";
    my $file_chmod_cmd_str = "find $dest_dir -type f -exec chmod $file_mode_str {} \\;";
    my $chown_cmd_str      = "chown -Rh $owner_name:$group_name $dest_dir";
    for my $cmd_str ($rsync_cmd_str, $rmdir_cmd_str, $dir_chmod_cmd_str, $file_chmod_cmd_str, $chown_cmd_str) {
        next if (
            $cmd_str eq $dir_chmod_cmd_str or
            $cmd_str eq $file_chmod_cmd_str or
            $cmd_str eq $chown_cmd_str
        ) and !-d $dest_dir;
        $cmd_str =~ s/\s+/ /g;
        if (($cmd_str eq $rsync_cmd_str) or !$dry_run) {
            print "$cmd_str\n";
            system($cmd_str) == 0 
                or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                       ": command failed, exit code: ", $? >> 8, "\n";
        }
    }
}

sub clean_up_dest {
    my ($dest_dir) = @_;
    if (-l $dest_dir or -f $dest_dir) {
        print "Removing $dest_dir\n";
        if (!$dry_run) {
            unlink($dest_dir) or
                warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                     ": could not unlink $dest_dir: $!\n";
        }
    }
    elsif (-d $dest_dir) {
        print "Deleting $dest_dir\n";
        if (!$dry_run) {
            remove_tree($dest_dir, {
                verbose => $verbose,
                error => \my $err,
            });
            if (@{$err}) {
                for my $diag (@{$err}) {
                    my ($file, $message) = %{$diag};
                    warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                         ": could not delete $file: $message\n";
                }
            }
        }
    }
}

__END__

=head1 NAME 

sync_dcc_data - OCG DCC Master Data-to-Download Areas Synchronizer

=head1 SYNOPSIS

 sync_dcc_data.pl <program name(s)> <project name(s)> <data type(s)> <data set(s)> <data level dir(s)> <destination(s)> [options]
 
 Parameters:
    <program name(s)>       Comma-separated list of program name(s) (optional, default: all programs)
    <project name(s)>       Comma-separated list of project name(s) (optional, default: all program projects)
    <data type(s)>          Comma-separated list of data type(s) (optional, default: all project data types)
    <data set(s)>           Comma-separated list of data set(s) (optional, default: all data type data sets)
    <data level dir(s)>     Comma-separated list of data level dir(s) (optional, default: all data set data level dirs)
    <destination(s)>        Comma-separated list of destination(s): PreRelease, Controlled, Public, Release, Germline, BCCA (optional, default: PreRelease)
 
 Options:
    --dry-run               Perform trial run with no changes made (sudo not required, default: off)
    --delete                Delete extraneous files from destination dirs (default: off)
    --verbose               Be verbose
    --help                  Display usage message and exit
    --version               Display program version and exit
 
=cut
