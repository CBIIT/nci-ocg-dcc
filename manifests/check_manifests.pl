#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use sigtrap qw( handler sig_handler normal-signals error-signals ALRM );
use Cwd qw( realpath );
use Digest::MD5;
#use Crypt::Digest::SHA256 qw( sha256_file_hex );
use Digest::SHA;
use File::Basename qw( fileparse );
use File::Find;
use File::Spec;
use Getopt::Long qw( :config auto_help auto_version );
use List::Util qw( any all first none uniq );
use NCI::OCGDCC::Config qw( :all );
use NCI::OCGDCC::Utils qw( load_configs manifest_by_file_path );
use Pod::Usage qw( pod2usage );
use Sort::Key::Natural qw( natsort );
use Term::ANSIColor;
use Data::Dumper;

sub sig_handler {
    die "Caught signal, exiting\n";
}

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
my $config_hashref = load_configs(qw(
    cgi
    common
    manifests
));
my @program_names = @{$config_hashref->{'common'}->{'program_names'}};
my %program_project_names = %{$config_hashref->{'common'}->{'program_project_names'}};
my %program_project_names_w_subprojects = %{$config_hashref->{'common'}->{'program_project_names_w_subprojects'}};
my @programs_w_data_types = @{$config_hashref->{'common'}->{'programs_w_data_types'}};
my @data_types = @{$config_hashref->{'common'}->{'data_types'}};
my @data_types_w_data_levels = @{$config_hashref->{'common'}->{'data_types_w_data_levels'}};
my @data_level_dir_names = @{$config_hashref->{'common'}->{'data_level_dir_names'}};
my %program_dn_group_name = %{$config_hashref->{'common'}->{'data_filesys_info'}->{'program_dn_group_name'}};
my $default_manifest_file_name = $config_hashref->{'manifests'}->{'default_manifest_file_name'};
my $manifest_delimiter_regexp = $config_hashref->{'manifests'}->{'manifest_delimiter_regexp'};
my $manifest_out_delimiter = $config_hashref->{'manifests'}->{'manifest_out_delimiter'};
my @manifest_supported_checksum_algs = @{$config_hashref->{'manifests'}->{'manifest_supported_checksum_algs'}};
my %program_manifest_default_checksum_alg = %{$config_hashref->{'manifests'}->{'program_manifest_default_checksum_alg'}};
my $manifest_user_name = $config_hashref->{'manifests'}->{'data_filesys_info'}->{'manifest_user_name'};
my $manifest_group_name = $config_hashref->{'manifests'}->{'data_filesys_info'}->{'manifest_group_name'};
my $manifest_file_mode = $config_hashref->{'manifests'}->{'data_filesys_info'}->{'manifest_file_mode'};
my $cgi_dir_name = $config_hashref->{'cgi'}->{'dir_name'};
my @cgi_analysis_dir_names = @{$config_hashref->{'cgi'}->{'analysis_dir_names'}};
my @cgi_manifest_file_names = @{$config_hashref->{'cgi'}->{'manifest_file_names'}};
my @cgi_skip_file_names = @{$config_hashref->{'cgi'}->{'skip_file_names'}};
my $cgi_manifest_file_mode = $config_hashref->{'cgi'}->{'data_filesys_info'}->{'manifest_file_mode'};
my @param_groups = qw(
    programs
    projects
    data_types
    data_sets
    data_level_dirs
);

my $verify_checksums = 0;
my $fix = 0;
my $sort = 0;
my $gen_new = 0;
my $skip_existing = 0;
my $skip_cgi = 0;
my $manifest_checksum_alg = '';
my $dry_run = 0;
my $verbose = 0;
my $debug = 0;
GetOptions(
    'verify-checksums' => \$verify_checksums,
    'fix' => \$fix,
    'sort' => \$sort,
    'gen-new' => \$gen_new,
    'skip-existing' => \$skip_existing,
    'skip-cgi' => \$skip_cgi,
    'use-checksum-alg:s' => \$manifest_checksum_alg,
    'dry-run' => \$dry_run,
    'verbose' => \$verbose,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
if ($< != 0 and ($fix or $sort or $gen_new) and !$dry_run) {
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
if (defined($manifest_checksum_alg) and $manifest_checksum_alg ne '') {
    $manifest_checksum_alg = lc($manifest_checksum_alg);
    if (none { $manifest_checksum_alg eq $_ } @manifest_supported_checksum_algs) {
        pod2usage(
            -message => "Invalid checksum algorithm: $manifest_checksum_alg\n" .
                        "Supported algorithms: " . join(', ', @manifest_supported_checksum_algs),
            -verbose => 0,
        );
    }
}
print STDERR "\%user_params:\n", Dumper(\%user_params) if $debug;
my $manifest_uid = getpwnam($manifest_user_name)
    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": couldn't get uid for $manifest_user_name\n";
my $manifest_gid = getgrnam($manifest_group_name)
    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": couldn't get gid for $manifest_group_name\n";
for my $program_name (@program_names) {
    next if defined($user_params{programs}) and none { $program_name eq $_ } @{$user_params{programs}};
    my $manifest_download_gid = getgrnam($program_dn_group_name{$program_name})
        or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
               ": couldn't get gid for $program_dn_group_name{$program_name}";
    if (!defined($manifest_checksum_alg) or $manifest_checksum_alg eq '') {
        $manifest_checksum_alg = $program_manifest_default_checksum_alg{$program_name};
    }
    PROJECT_NAME: for my $project_name (@{$program_project_names{$program_name}}) {
        next if defined($user_params{projects}) and none { $project_name eq $_ } @{$user_params{projects}};
        my ($disease_proj, $subproject);
        if (any { $project_name eq $_ } @{$program_project_names_w_subprojects{$program_name}}) {
            ($disease_proj, $subproject) = split /-/, $project_name, 2;
        }
        else {
            $disease_proj = $project_name;
        }
        my $project_dir_path_part = $disease_proj;
        if (defined($subproject)) {
            $project_dir_path_part = "$project_dir_path_part/$subproject";
        }
        # programs with data types
        if (any { $program_name eq $_ } @programs_w_data_types) {
            DATA_TYPE: for my $data_type (@data_types) {
                next if defined($user_params{data_types}) and none { $data_type eq $_ } @{$user_params{data_types}};
                (my $data_type_dir_name = $data_type) =~ s/-Seq$/-seq/i;
                my $data_type_dir = "/local/ocg-dcc/data/\U$program_name\E/$project_dir_path_part/$data_type_dir_name";
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
                            warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                                 ": $data_type_dir subdirectory structure is invalid\n";
                            next DATA_TYPE;
                        }
                    }
                }
                else {
                    warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                         ": $data_type_dir subdirectory structure is invalid\n";
                    next DATA_TYPE;
                }
                for my $dataset (@datasets) {
                    next if defined($user_params{data_sets}) and none { $dataset eq $_ } @{$user_params{data_sets}};
                    my $dataset_dir = $data_type_dir . ( $dataset eq '' ? $dataset : "/$dataset" ) . '/current';
                    next unless -d $dataset_dir;
                    # data types that have data levels (except for Resources datasets)
                    if (( any { $data_type eq $_ } @data_types_w_data_levels ) and $project_name ne 'Resources') {
                        for my $data_level_dir_name (@data_level_dir_names) {
                            next if defined($user_params{data_level_dirs}) and none { $data_level_dir_name eq $_ } @{$user_params{data_level_dirs}};
                            my $data_level_dir = "$dataset_dir/$data_level_dir_name";
                            next unless -d $data_level_dir;
                            my $real_data_level_dir = realpath($data_level_dir);
                            # standard data directory
                            if ($data_level_dir_name ne $cgi_dir_name) {
                                find({
                                    follow => 1,
                                    wanted => sub {
                                        # directories only
                                        return unless -d;
                                        my $data_dir = $File::Find::name;
                                        my $real_data_dir = realpath($data_dir);
                                        my (@data_file_names, @manifest_file_names);
                                        opendir(my $dh, $real_data_dir)
                                            or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                                                   ": couldn't opendir $real_data_dir: $!";
                                        for (readdir($dh)) {
                                            next unless -f "$real_data_dir/$_";
                                            if (!m/^$default_manifest_file_name$/io) {
                                                push @data_file_names, $_;
                                            }
                                            else {
                                                push @manifest_file_names, $_;
                                            }
                                        }
                                        closedir($dh);
                                        if (@data_file_names or @manifest_file_names) {
                                            if ($verbose) {
                                                my $data_dir_rel_parts_str = $data_dir ne $data_level_dir
                                                    ? join(' ', File::Spec->splitdir(File::Spec->abs2rel($data_dir, $data_level_dir)))
                                                    : '';
                                                print "[$program_name $project_name $data_type",
                                                      ($dataset ne '' ? " $dataset" : ''),
                                                      " $data_level_dir_name",
                                                      ($data_dir_rel_parts_str ne '' ? " $data_dir_rel_parts_str" : ''),
                                                      "]\n";
                                            }
                                            check_manifests(
                                                $real_data_dir,
                                                \@manifest_file_names,
                                                $real_data_dir =~ /^\/local\/ocg-dcc\/download\/\U$program_name\E\// ? 1 : 0,
                                                $manifest_checksum_alg,
                                                $manifest_download_gid,
                                                \@data_file_names,
                                            );
                                        }
                                    },
                                }, $real_data_level_dir);
                            }
                            # TARGET WGS CGI data directory
                            elsif (!$skip_cgi) {
                                if ($verbose) {
                                    print "[$program_name $project_name $data_type",
                                          ($dataset ne '' ? " $dataset" : ''),
                                          " $data_level_dir_name]\n";
                                }
                                my @analysis_dirs;
                                for my $analysis_dir_name (@cgi_analysis_dir_names) {
                                    my $analysis_dir = "$real_data_level_dir/$analysis_dir_name";
                                    push @analysis_dirs, $analysis_dir if -d $analysis_dir;
                                }
                                if ($debug) {
                                    print STDERR "\@analysis_dirs:\n", Dumper(\@analysis_dirs);
                                }
                                for my $analysis_dir (@analysis_dirs) {
                                    opendir(my $analysis_dh, $analysis_dir)
                                        or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                                        ": couldn't opendir $analysis_dir: $!";
                                    my @data_dir_names = natsort grep {
                                        !m/^\./ and (
                                            -d "$analysis_dir/$_" or (
                                                -l "$analysis_dir/$_" and
                                                -d readlink "$analysis_dir/$_"
                                            )
                                        )
                                    } readdir $analysis_dh;
                                    closedir($analysis_dh);
                                    for my $data_dir_name (@data_dir_names) {
                                        # CGI case dirs
                                        if ($data_dir_name =~ /^$OCG_CGI_CASE_DIR_REGEXP$/) {
                                            my $data_dir;
                                            if (-d "$analysis_dir/$data_dir_name/EXP") {
                                                $data_dir = "$analysis_dir/$data_dir_name/EXP";
                                            }
                                            elsif ($disease_proj eq 'OS') {
                                                $data_dir = "$analysis_dir/$data_dir_name";
                                            }
                                            else {
                                                die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                                                    ": invalid CGI data dir: $analysis_dir/$data_dir_name";
                                            }
                                            check_manifests(
                                                $data_dir,
                                                \@cgi_manifest_file_names,
                                                1,
                                                $manifest_checksum_alg,
                                                $manifest_download_gid,
                                            );
                                        }
                                        else {
                                            print +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'),
                                                  ": CGI data dir type not supported: $analysis_dir/$data_dir_name\n";
                                        }
                                    }
                                }
                            }
                        }
                    }
                    # data types that don't have data levels (and Resources datasets)
                    elsif (!defined $user_params{data_level_dirs}) {
                        find({
                            follow => 1,
                            wanted => sub {
                                # directories only
                                return unless -d;
                                my $data_dir = $File::Find::name;
                                my $real_data_dir = realpath($data_dir);
                                my (@data_file_names, @manifest_file_names);
                                opendir(my $dh, $real_data_dir)
                                    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                                       ": couldn't opendir $real_data_dir: $!";
                                for (readdir($dh)) {
                                    next unless -f "$real_data_dir/$_";
                                    if (!m/^$default_manifest_file_name$/io) {
                                        push @data_file_names, $_;
                                    }
                                    else {
                                        push @manifest_file_names, $_;
                                    }
                                }
                                closedir($dh);
                                if (@data_file_names or @manifest_file_names) {
                                    if ($verbose) {
                                        my $data_dir_rel_parts_str = $data_dir ne $dataset_dir
                                            ? join(' ', File::Spec->splitdir(File::Spec->abs2rel($data_dir, $dataset_dir)))
                                            : '';
                                        print "[$program_name $project_name $data_type",
                                              ($dataset ne '' ? " $dataset" : ''),
                                              ($data_dir_rel_parts_str ne '' ? " $data_dir_rel_parts_str" : ''),
                                              "]\n";
                                    }
                                    check_manifests(
                                        $real_data_dir,
                                        \@manifest_file_names,
                                        $real_data_dir =~ /^\/local\/ocg-dcc\/download\/\U$program_name\E\// ? 1 : 0,
                                        $manifest_checksum_alg,
                                        $manifest_download_gid,
                                        \@data_file_names,
                                    );
                                }
                            },
                        }, $dataset_dir);
                    }
                }
            }
        }
        # programs w/o data types
        else {
            my $project_dir = "/local/ocg-dcc/data/\U$program_name\E/$project_dir_path_part";
            next unless -d $project_dir;
            opendir(my $project_dh, $project_dir)
                or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $project_dir: $!";
            my @project_sub_dir_names = grep { -d "$project_dir/$_" and !m/^\./ } readdir($project_dh);
            closedir($project_dh);
            my @datasets;
            if (all { m/^(current|old)$/ } @project_sub_dir_names) {
                push @datasets, '';
            }
            elsif (none { m/^(current|old)$/ } @project_sub_dir_names) {
                for my $project_sub_dir_name (@project_sub_dir_names) {
                    my $project_sub_dir = "$project_dir/$project_sub_dir_name";
                    opendir(my $project_sub_dh, $project_sub_dir)
                        or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                               ": could not open $project_sub_dir: $!";
                    my @sub_dir_names = grep { -d "$project_sub_dir/$_" and !m/^\./ } readdir($project_sub_dh);
                    closedir($project_sub_dh);
                    if (all { m/^(current|old)$/ } @sub_dir_names) {
                        push @datasets, $project_sub_dir_name;
                    }
                    else {
                        warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                             ": $project_dir subdirectory structure is invalid\n";
                        next PROJECT_NAME;
                    }
                }
            }
            else {
                warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                     ": $project_dir subdirectory structure is invalid\n";
                next PROJECT_NAME;
            }
            for my $dataset (@datasets) {
                next if defined($user_params{data_sets}) and none { $dataset eq $_ } @{$user_params{data_sets}};
                my $dataset_dir = $project_dir . ( $dataset eq '' ? $dataset : "/$dataset" ) . '/current';
                next unless -d $dataset_dir;
                find({
                    follow => 1,
                    wanted => sub {
                        # directories only
                        return unless -d;
                        my $data_dir = $File::Find::name;
                        my $real_data_dir = realpath($data_dir);
                        my (@data_file_names, @manifest_file_names);
                        opendir(my $dh, $real_data_dir)
                            or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
                                   ": couldn't opendir $real_data_dir: $!";
                        for (readdir($dh)) {
                            next unless -f "$real_data_dir/$_";
                            if (!m/^$default_manifest_file_name$/io) {
                                push @data_file_names, $_;
                            }
                            else {
                                push @manifest_file_names, $_;
                            }
                        }
                        closedir($dh);
                        if (@data_file_names or @manifest_file_names) {
                            if ($verbose) {
                                my $data_dir_rel_parts_str = $data_dir ne $dataset_dir
                                    ? join(' ', File::Spec->splitdir(File::Spec->abs2rel($data_dir, $dataset_dir)))
                                    : '';
                                print "[$program_name $project_name",
                                      ($dataset ne '' ? " $dataset" : ''),
                                      ($data_dir_rel_parts_str ne '' ? " $data_dir_rel_parts_str" : ''),
                                      "]\n";
                            }
                            check_manifests(
                                $real_data_dir,
                                \@manifest_file_names,
                                $real_data_dir =~ /^\/local\/ocg-dcc\/download\/\U$program_name\E\// ? 1 : 0,
                                $manifest_checksum_alg,
                                $manifest_download_gid,
                                \@data_file_names,
                            );
                        }
                    },
                }, $dataset_dir);
            }
        }
    }
}
exit;

sub check_manifests {
    my (
        $data_dir,
        $manifest_file_names_arrayref,
        $manifest_in_download_area,
        $manifest_checksum_alg,
        $manifest_download_gid,
        $data_file_names_arrayref,
    ) = @_;
    my ($manifest_exists, %manifest_file_rel_paths);
    for my $manifest_file_name (@{$manifest_file_names_arrayref}) {
        my $manifest_file = "$data_dir/$manifest_file_name";
        next unless -f $manifest_file;
        $manifest_exists++;
        if ($skip_existing) {
            print " Skipping $manifest_file\n" if $verbose;
            next;
        }
        my (@new_manifest_lines, $write_new_manifest);
        print "Checking $manifest_file\n" if $verbose;
        open(my $manifest_in_fh, '<', $manifest_file)
            or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not read open $manifest_file: $!";
        while (<$manifest_in_fh>) {
            next if m/^\s*$/;
            s/\s+$//;
            my ($manifest_checksum, $manifest_delimiter, $file_rel_path) = split /$manifest_delimiter_regexp/, $_, 2;
            if (!exists $manifest_file_rel_paths{$file_rel_path}) {
                $manifest_file_rel_paths{$file_rel_path}++;
            }
            else {
                print +(-t STDERR ? colored('DUPLICATE MANIFEST ENTRY', 'red') : 'DUPLICATE MANIFEST ENTRY'), ": $file_rel_path\n";
            }
            my $file_path = "$data_dir/$file_rel_path";
            # check file exists and manifest entry not an actual manifest file
            if (-f $file_path and $file_rel_path !~ /^$default_manifest_file_name$/io) {
                if ($verify_checksums) {
                    print "Verifying $_\n" if $verbose;
                    my $file_checksum;
                    if (length($manifest_checksum) == 64) {
                        #$file_checksum = sha256_file_hex($file_path);
                        $file_checksum = Digest::SHA->new('256')->addfile($file_path, 'b')->hexdigest;
                    }
                    elsif (length($manifest_checksum) == 32) {
                        open(my $fh, '<', $file_path)
                            or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $file_path: $!";
                        $file_checksum = Digest::MD5->new->addfile($fh)->hexdigest;
                        close($fh);
                    }
                    else {
                        die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": unsupported checksum format: $_";
                    }
                    if ($file_checksum eq $manifest_checksum) {
                        if ($fix) {
                            if ($manifest_checksum_alg eq 'sha256' and length($manifest_checksum) != 64) {
                                #$file_checksum = sha256_file_hex($file_path);
                                $file_checksum = Digest::SHA->new('256')->addfile($file_path, 'b')->hexdigest;
                                my $new_manifest_line = "${file_checksum}${manifest_out_delimiter}${file_rel_path}\n";
                                print "Updating $new_manifest_line" if $verbose;
                                push @new_manifest_lines, $new_manifest_line;
                                $write_new_manifest++;
                            }
                            elsif ($manifest_checksum_alg eq 'md5' and length($manifest_checksum) != 32) {
                                open(my $fh, '<', $file_path)
                                    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $file_path: $!";
                                $file_checksum = Digest::MD5->new->addfile($fh)->hexdigest;
                                close($fh);
                                my $new_manifest_line = "${file_checksum}${manifest_out_delimiter}${file_rel_path}\n";
                                print "Updating $new_manifest_line" if $verbose;
                                push @new_manifest_lines, $new_manifest_line;
                                $write_new_manifest++;
                            }
                            elsif ($manifest_delimiter ne $manifest_out_delimiter) {
                                my $new_manifest_line = "${manifest_checksum}${manifest_out_delimiter}${file_rel_path}\n";
                                print "Updating $new_manifest_line" if $verbose;
                                push @new_manifest_lines, $new_manifest_line;
                                $write_new_manifest++;
                            }
                            else {
                                push @new_manifest_lines, "$_\n";
                            }
                        }
                    }
                    else {
                        print +(-t STDOUT ? colored('BAD MANIFEST CHECKSUM', 'red') : 'BAD MANIFEST CHECKSUM'), ": $_\n";
                        if ($fix) {
                            if ($manifest_checksum_alg eq 'sha256') {
                                #$file_checksum = sha256_file_hex($file_path);
                                $file_checksum = Digest::SHA->new('256')->addfile($file_path, 'b')->hexdigest;
                            }
                            elsif ($manifest_checksum_alg eq 'md5') {
                                open(my $fh, '<', $file_path)
                                    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $file_path: $!";
                                $file_checksum = Digest::MD5->new->addfile($fh)->hexdigest;
                                close($fh);
                            }
                            my $new_manifest_line = "${file_checksum}${manifest_out_delimiter}${file_rel_path}\n";
                            print "Updating $new_manifest_line" if $verbose;
                            push @new_manifest_lines, $new_manifest_line;
                            $write_new_manifest++;
                        }
                    }
                }
                elsif ($fix) {
                    if ($manifest_checksum_alg eq 'sha256' and length($manifest_checksum) != 64) {
                        #my $file_checksum = sha256_file_hex($file_path);
                        my $file_checksum = Digest::SHA->new('256')->addfile($file_path, 'b')->hexdigest;
                        my $new_manifest_line = "${file_checksum}${manifest_out_delimiter}${file_rel_path}\n";
                        print "Updating $new_manifest_line" if $verbose;
                        push @new_manifest_lines, $new_manifest_line;
                        $write_new_manifest++;
                    }
                    elsif ($manifest_checksum_alg eq 'md5' and length($manifest_checksum) != 32) {
                        open(my $fh, '<', $file_path)
                            or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $file_path: $!";
                        my $file_checksum = Digest::MD5->new->addfile($fh)->hexdigest;
                        close($fh);
                        my $new_manifest_line = "${file_checksum}${manifest_out_delimiter}${file_rel_path}\n";
                        print "Updating $new_manifest_line" if $verbose;
                        push @new_manifest_lines, $new_manifest_line;
                        $write_new_manifest++;
                    }
                    elsif ($manifest_delimiter ne $manifest_out_delimiter) {
                        my $new_manifest_line = "${manifest_checksum}${manifest_out_delimiter}${file_rel_path}\n";
                        print "Updating $new_manifest_line" if $verbose;
                        push @new_manifest_lines, $new_manifest_line;
                        $write_new_manifest++;
                    }
                    else {
                        push @new_manifest_lines, "$_\n";
                    }
                }
            }
            else {
                print !-f $file_path
                    ? ( (-t STDOUT ? colored('NOT IN FILESYSTEM', 'red') : 'NOT IN FILESYSTEM'), ": $file_path" )
                    : ( (-t STDOUT ? colored('BAD MANIFEST ENTRY', 'red') : 'BAD MANIFEST ENTRY'), ": $_" ),
                    "\n";
                if ($fix) {
                    print "Removing $_\n" if $verbose;
                    $write_new_manifest++;
                }
            }
        }
        close($manifest_in_fh);
        if ($fix and $write_new_manifest) {
            print "Writing new manifest $manifest_file\n" if $verbose;
            if (!$dry_run) {
                open(my $manifest_out_fh, '>', $manifest_file)
                    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not write open $manifest_file: $!";
                print $manifest_out_fh @new_manifest_lines;
                close($manifest_out_fh);
                set_manifest_perms(
                    $manifest_file,
                    ( !$manifest_in_download_area        ? $manifest_gid       : $manifest_download_gid ),
                    ( defined($data_file_names_arrayref) ? $manifest_file_mode : $cgi_manifest_file_mode ),
                );
            }
        }
        if ($sort) {
            print "Sorting manifest $manifest_file\n" if $verbose;
            if (!$dry_run) {
                open(my $manifest_in_fh, '<', $manifest_file)
                    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not read open $manifest_file: $!";
                my @manifest_lines = grep { !m/^\s*$/ } <$manifest_in_fh>;
                close($manifest_in_fh);
                my @sorted_manifest_lines = sort manifest_by_file_path @manifest_lines;
                open(my $manifest_out_fh, '>', $manifest_file)
                    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not write open $manifest_file: $!";
                print $manifest_out_fh @sorted_manifest_lines;
                close($manifest_out_fh);
                set_manifest_perms(
                    $manifest_file,
                    ( !$manifest_in_download_area        ? $manifest_gid       : $manifest_download_gid ),
                    ( defined($data_file_names_arrayref) ? $manifest_file_mode : $cgi_manifest_file_mode ),
                );
            }
        }
    }
    if ($manifest_exists and !$skip_existing) {
        my %new_manifest_lines_by_manifest_name;
        # standard data directory
        if (defined($data_file_names_arrayref)) {
            for my $data_file_name (@{$data_file_names_arrayref}) {
                # skip files which already exist in manifests
                next if $manifest_file_rel_paths{$data_file_name};
                print +(-t STDOUT ? colored('NOT IN MANIFEST', 'red') : 'NOT IN MANIFEST'), ": $data_dir/$data_file_name\n";
                if ($fix) {
                    my $file_path = "$data_dir/$data_file_name";
                    my $file_checksum;
                    if ($manifest_checksum_alg eq 'sha256') {
                        #$file_checksum = sha256_file_hex($file_path);
                        $file_checksum = Digest::SHA->new('256')->addfile($file_path, 'b')->hexdigest;
                    }
                    elsif ($manifest_checksum_alg eq 'md5') {
                        open(my $fh, '<', $file_path)
                            or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $file_path: $!";
                        $file_checksum = Digest::MD5->new->addfile($fh)->hexdigest;
                        close($fh);
                    }
                    my $new_manifest_line = "${file_checksum}${manifest_out_delimiter}${data_file_name}\n";
                    print "Adding $new_manifest_line" if $verbose;
                    push @{$new_manifest_lines_by_manifest_name{$default_manifest_file_name}}, $new_manifest_line;
                }
            }
        }
        # WGS CGI data directory
        else {
            find({
                follow => 1,
                wanted => sub {
                    # files only
                    return unless -f;
                    my $file_name = $_;
                    my $file = $File::Find::name;
                    my $file_rel_path = File::Spec->abs2rel($file, $data_dir);
                    # skip top-level manifest files and TARGET CGI manifest sig files
                    return if any { $file_rel_path eq $_ } (@{$manifest_file_names_arrayref}, @cgi_skip_file_names);
                    # skip files which exist in manifests
                    return if $manifest_file_rel_paths{$file_rel_path};
                    print +(-t STDOUT ? colored('NOT IN MANIFEST', 'red') : 'NOT IN MANIFEST'), ": $file\n";
                    if ($fix) {
                        my (undef, undef, $file_ext) = fileparse($file, qr/\..*/);
                        my $manifest_file_name = (
                                                   $file_name eq 'results_from_parsed' or
                                                   $file_name eq 'somatic_filtered_data_only' or
                                                   $file_name eq 'somatic_filtered_data_utr3_utr5_tss_upstream_only' or
                                                  ($file_name =~ /^somaticVcfBeta/ and $file_ext eq '.txt')
                                                 ) ? 'manifest.dcc.unencrypted'
                                                   : 'manifest.all.unencrypted';
                        my $file_checksum;
                        if ($manifest_checksum_alg eq 'sha256') {
                            #$file_checksum = sha256_file_hex($file);
                            $file_checksum = Digest::SHA->new('256')->addfile($file, 'b')->hexdigest;
                        }
                        elsif ($manifest_checksum_alg eq 'md5') {
                            open(my $fh, '<', $file)
                                or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $file: $!";
                            $file_checksum = Digest::MD5->new->addfile($fh)->hexdigest;
                            close($fh);
                        }
                        my $new_manifest_line = "${file_checksum}${manifest_out_delimiter}${file_rel_path}\n";
                        print "Adding $new_manifest_line" if $verbose;
                        push @{$new_manifest_lines_by_manifest_name{$manifest_file_name}}, $new_manifest_line;
                    }
                },
            }, $data_dir);
        }
        if ($fix and %new_manifest_lines_by_manifest_name) {
            for my $manifest_file_name (natsort keys %new_manifest_lines_by_manifest_name) {
                my $manifest_file = "$data_dir/$manifest_file_name";
                open(my $manifest_in_fh, '<', $manifest_file)
                   or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not read open $manifest_file: $!";
                my @manifest_lines = grep { !m/^\s*$/ } <$manifest_in_fh>;
                close($manifest_in_fh);
                push @manifest_lines, @{$new_manifest_lines_by_manifest_name{$manifest_file_name}};
                my @sorted_manifest_lines = sort manifest_by_file_path @manifest_lines;
                print "Writing new manifest $manifest_file\n" if $verbose;
                if (!$dry_run) {
                    open(my $manifest_out_fh, '>', $manifest_file)
                        or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not write open $manifest_file: $!";
                    print $manifest_out_fh @sorted_manifest_lines;
                    close($manifest_out_fh);
                    set_manifest_perms(
                        $manifest_file,
                        ( !$manifest_in_download_area        ? $manifest_gid       : $manifest_download_gid ),
                        ( defined($data_file_names_arrayref) ? $manifest_file_mode : $cgi_manifest_file_mode ),
                    );
                }
            }
        }
    }
    elsif (!$manifest_exists) {
        # only generate new manifests for standard data directories
        if ($gen_new and defined($data_file_names_arrayref)) {
            my @manifest_lines;
            my $manifest_file = "$data_dir/$default_manifest_file_name";
            print "Generating $manifest_file\n";
            for my $data_file_name (@{$data_file_names_arrayref}) {
                my $file_path = "$data_dir/$data_file_name";
                my $file_checksum;
                if ($manifest_checksum_alg eq 'sha256') {
                    #$file_checksum = sha256_file_hex($file_path);
                    $file_checksum = Digest::SHA->new('256')->addfile($file_path, 'b')->hexdigest;
                }
                elsif ($manifest_checksum_alg eq 'md5') {
                    open(my $fh, '<', $file_path)
                        or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not open $file_path: $!";
                    $file_checksum = Digest::MD5->new->addfile($fh)->hexdigest;
                    close($fh);
                }
                my $new_manifest_line = "${file_checksum}${manifest_out_delimiter}${data_file_name}\n";
                print "Adding $new_manifest_line" if $verbose;
                push @manifest_lines, $new_manifest_line;
            }
            my @sorted_manifest_lines = sort manifest_by_file_path @manifest_lines;
            print "Writing new manifest $manifest_file\n" if $verbose;
            if (!$dry_run) {
                open(my $manifest_out_fh, '>', $manifest_file)
                    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": could not write open $manifest_file: $!";
                print $manifest_out_fh @sorted_manifest_lines;
                close($manifest_out_fh);
                set_manifest_perms(
                    $manifest_file,
                    ( !$manifest_in_download_area        ? $manifest_gid       : $manifest_download_gid ),
                    ( defined($data_file_names_arrayref) ? $manifest_file_mode : $cgi_manifest_file_mode ),
                );
            }
        }
        elsif ($verbose) {
            print +(-t STDOUT ? colored('No manifests found', 'red') : 'No manifests found'), "\n";
        }
    }
}

sub set_manifest_perms {
    my ($manifest_file, $manifest_gid, $manifest_file_mode) = @_;
    #chown(-1, $manifest_gid, $manifest_file);
    chown($manifest_uid, $manifest_gid, $manifest_file)
        or warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": couldn't chown $manifest_file\n";
    chmod($manifest_file_mode, $manifest_file)
        or warn +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), ": couldn't chmod $manifest_file\n";
}

__END__

=head1 NAME

check_manifests.pl - Manifest and Data File Integrity Checker/Fixer/Generator

=head1 SYNOPSIS

 check_manifests.pl <program name(s)> <project name(s)> <data type(s)> <data set(s)> <data level dir(s)> [options]
 
 Parameters:
    <program name(s)>       Comma-separated list of program name(s) (optional, default: all programs)
    <project name(s)>       Comma-separated list of project name(s) (optional, default: all program projects)
    <data type(s)>          Comma-separated list of data type(s) (optional, default: all project data types)
    <data set(s)>           Comma-separated list of data set(s) (optional, default: all data type data sets)
    <data level dir(s)>     Comma-separated list of data level dir(s) (optional, default: all data set data level dirs)
 
 Options:
    --verify-checksums      Verify manifest checksums (default: off)
    --fix                   Fix manifest issues found, automatically re-sorts
    --sort                  Re-sort all manifest files (default: off)
    --gen-new               Generate new manifests if not found (default: off)
    --skip-existing         Skip checking of existing manifests (default: off)
    --skip-cgi              Skip checking TARGET CGI master data trees (default: off)
    --use-checksum-alg      Override checksum algorithm (default: program-specific default checksum algorithm)
    --dry-run               Perform trial run with no changes made, only with --fix, --sort, --gen-new (sudo not required, default: off)
    --verbose               Be verbose
    --debug                 Run in debug mode
    --help                  Display usage message and exit
    --version               Display program version and exit

=cut
