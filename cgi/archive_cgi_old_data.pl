#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use Config::Any;
use File::Basename qw( fileparse );
use File::Copy qw( move );
use File::Copy::Recursive qw( dirmove );
use File::Find;
use File::Path 2.11 qw( make_path );
use File::Spec;
use Getopt::Long qw( :config auto_help auto_version );
use List::Util qw( first uniq );
use List::MoreUtils qw( any none );
use NCI::OCGDCC::Config qw( :all );
use Pod::Usage qw( pod2usage );
use Sort::Key::Natural qw( natsort );
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
my %config_file_info = (
    'common' => {
        file => "$FindBin::Bin/../common/conf/common_conf.pl",
        plugin => 'Config::Any::Perl',
    },
    'cgi' => {
        file => "$FindBin::Bin/conf/cgi_conf.pl",
        plugin => 'Config::Any::Perl',
    },
);
my @config_files = map { $_->{file} } values %config_file_info;
my @config_file_plugins = map { $_->{plugin} } values %config_file_info;
my $config_hashref = Config::Any->load_files({
    files => \@config_files,
    force_plugins => \@config_file_plugins,
    flatten_to_hash => 1,
});
# use %config_file_info key instead of file path (saves typing)
for my $config_file (keys %{$config_hashref}) {
    $config_hashref->{
        first {
            $config_file_info{$_}{file} eq $config_file
        } keys %config_file_info
    } = $config_hashref->{$config_file};
    delete $config_hashref->{$config_file};
}
for my $config_key (natsort keys %config_file_info) {
    if (!exists($config_hashref->{$config_key})) {
        die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
        ": could not compile/load $config_file_info{$config_key}{file}\n";
    }
}
# use cgi (not common) program names and program project names
my @program_names = @{$config_hashref->{'cgi'}->{'program_names'}};
my %program_project_names = %{$config_hashref->{'cgi'}->{'program_project_names'}};
my $data_type_dir_name = $config_hashref->{'cgi'}->{'data_type_dir_name'};
my $cgi_dir_name = $config_hashref->{'cgi'}->{'cgi_dir_name'};
my @cgi_data_dir_names = @{$config_hashref->{'cgi'}->{'cgi_data_dir_names'}};
my @cgi_manifest_file_names = @{$config_hashref->{'cgi'}->{'cgi_manifest_file_names'}};
my (
    $adm_owner_name,
    $adm_group_name,
    $data_dir_mode,
    $data_file_mode,
) = @{$config_hashref->{'cgi'}->{'data_filesys_info'}}{qw(
    adm_owner_name
    adm_group_name
    data_dir_mode
    data_file_mode
)};
my $adm_owner_uid = getpwnam($adm_owner_name);
my $adm_group_gid = getgrnam($adm_group_name);
my @param_groups = qw(
    programs
    projects
);

my $verbose = 0;
my $dry_run = 0;
my $debug = 0;
GetOptions(
    'verbose' => \$verbose,
    'dry-run' => \$dry_run,
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
print STDERR "\%user_params:\n", Dumper(\%user_params) if $debug;
for my $program_name (@program_names) {
    next if defined($user_params{programs}) and none { $program_name eq $_ } @{$user_params{programs}};
    my $program_data_dir = "/local/ocg-dcc/data/\U$program_name\E";
    my $program_download_ctrld_dir = "/local/ocg-dcc/download/\U$program_name\E/Controlled";
    for my $project_name (@{$program_project_names{$program_name}}) {
        next if defined($user_params{projects}) and none { $project_name eq $_ } @{$user_params{projects}};
        print "[$program_name $project_name]\n";
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
        my $data_type_dir = "$program_download_ctrld_dir/$project_dir/$data_type_dir_name";
        my $dataset_dir_name = $project_name eq 'ALL'
                             ? 'Phase1+2'
                             : '';
        my $dataset_dir = $dataset_dir_name
                        ? "$data_type_dir/$dataset_dir_name"
                        : $data_type_dir;
        my $dataset_cgi_dir = "$dataset_dir/$cgi_dir_name";
        my @cgi_data_dirs;
        for my $data_dir_name (@cgi_data_dir_names) {
            my $cgi_data_dir = "$dataset_cgi_dir/$data_dir_name";
            push @cgi_data_dirs, $cgi_data_dir if -d $cgi_data_dir;
        }
        if ($debug) {
            print STDERR "\@cgi_data_dirs:\n", Dumper(\@cgi_data_dirs);
        }
        find({
            follow => 1,
            wanted => sub {
                my $parent_dir_path = $File::Find::dir;
                (my $archive_dir_path = $parent_dir_path) =~ s/\/local\/ocg-dcc\/download\/\U$program_name\E\/Controlled/\/local\/ocg-dcc\/data\/\U$program_name\E/;
                $archive_dir_path =~ s/$data_type_dir_name\/$cgi_dir_name/$data_type_dir_name\/old\/$cgi_dir_name/;
                # directories
                if (-d) {
                    my $dir_name = $_;
                    my $dir_path = $File::Find::name;
                    # old_data, corrupted directories
                    if ($dir_name eq 'old_data' or
                        $dir_name eq 'corrupted') {
                        # corrupted directories will be archived retaining the directory
                        if ($dir_name eq 'corrupted') {
                            $archive_dir_path .= "/$dir_name";
                        }
                        if (!-z $dir_path) {
                            if (!-e $archive_dir_path) {
                                print "Creating $archive_dir_path\n" if $verbose;
                                if (!$dry_run) {
                                    make_path($archive_dir_path, {
                                        chmod => $data_dir_mode,
                                        owner => $adm_owner_name,
                                        group => $adm_group_name,
                                    }) or warn "ERROR: could not create $archive_dir_path\n";
                                }
                            }
                            print "  Moving $dir_path ->\n",
                                  "         $archive_dir_path\n" if $verbose;
                            if (!$dry_run) {
                                dirmove($dir_path, $archive_dir_path) or
                                    warn "ERROR: could not move directory: $!\n",
                                         "$dir_path ->\n$archive_dir_path\n";
                                $File::Find::prune = 1;
                            }
                        }
                        else {
                            print "Removing $dir_path\n" if $verbose;
                            if (!$dry_run) {
                                rmdir($dir_path)
                                    or warn "ERROR: could not remove empty $dir_path: $!\n";
                                $File::Find::prune = 1;
                            }
                        }
                    }
                }
                # files
                elsif (-f) {
                    my $file_name = $_;
                    my $file_path = $File::Find::name;
                    # old manifest and bak files
                    if ($file_name =~ /(?:^manifest\.all(?:(?:.*?\.(?:old|orig))?|\.sig)|\.bak)$/i) {
                        my ($file_basename, $file_dir, $file_ext) = fileparse($file_path, qr/\..*/);
                        $file_dir =~ s/\/$//;
                        my @dir_parts = File::Spec->splitdir($file_dir);
                        # special case for Analysis directory files
                        if ($dir_parts[$#dir_parts] eq 'Analysis') {
                            my @file_basename_parts = split('_', $file_basename);
                            my $file_date_part = join('_', @file_basename_parts[$#file_basename_parts - 2 .. $#file_basename_parts]);
                            $archive_dir_path .= "/$file_date_part";
                        }
                        # special case for bak files
                        if ($file_name =~ /\.bak$/i) {
                            $file_name =~ s/\.bak$//i;
                        }
                        if (!-e $archive_dir_path) {
                            print "Creating $archive_dir_path\n" if $verbose;
                            if (!$dry_run) {
                                make_path($archive_dir_path, {
                                    chmod => $data_dir_mode,
                                    owner => $adm_owner_name,
                                    group => $adm_group_name,
                                }) or warn "ERROR: could not create $archive_dir_path\n";
                            }
                        }
                        # backup archive if exists
                        my $backup_success;
                        if (-e "$archive_dir_path/$file_name") {
                            for (my $i = 1; ; $i++) {
                                if (!-e "$archive_dir_path/${file_name}.$i") {
                                    print "  Moving $archive_dir_path/$file_name ->\n",
                                          "         $archive_dir_path/${file_name}.$i\n" if $verbose;
                                    if (!$dry_run) {
                                        if (move("$archive_dir_path/$file_name", "$archive_dir_path/${file_name}.$i")) {
                                            $backup_success++;
                                        }
                                        else {
                                            warn "ERROR: could not move file: $!\n",
                                                 "$archive_dir_path/$file_name ->\n$archive_dir_path/${file_name}.$i\n";
                                        }
                                    }
                                    last;
                                }
                            }
                        }
                        else {
                            $backup_success++;
                        }
                        # archive file
                        if ($backup_success or $dry_run) {
                            print "  Moving $file_path ->\n",
                                  "         $archive_dir_path/$file_name\n" if $verbose;
                            if (!$dry_run) {
                                if (move($file_path, "$archive_dir_path/$file_name")) {
                                    chmod($data_file_mode, "$archive_dir_path/$file_name");
                                    chown($adm_owner_uid, $adm_group_gid, "$archive_dir_path/$file_name");
                                }
                                else {
                                    warn "ERROR: could not move file: $!\n",
                                         "$file_path ->\n$archive_dir_path/$file_name\n";
                                }
                            }
                        }
                    }
                    # current manifest files
                    elsif (any { $file_name eq $_ } @cgi_manifest_file_names) {
                        open(my $manifest_in_fh, '<', $file_path)
                                or die "\nERROR: could not open for read $file_path\n\n";
                        my @manifest_file_old_data_lines;
                        while (<$manifest_in_fh>) {
                            next if m/^\s*$/;
                            my ($checksum, $rel_file_path) = split(' ', $_, 2);
                            if ($rel_file_path =~ /\/old_data\//) {
                                push @manifest_file_old_data_lines, $_;
                            }
                        }
                        close($manifest_in_fh);
                        if (@manifest_file_old_data_lines) {
                            if (!-e $archive_dir_path) {
                                print "Creating $archive_dir_path\n" if $verbose;
                                if (!$dry_run) {
                                    make_path($archive_dir_path, {
                                        chmod => $data_dir_mode,
                                        owner => $adm_owner_name,
                                        group => $adm_group_name,
                                    }) or warn "ERROR: could not create $archive_dir_path\n";
                                }
                            }
                            # filter out old_data path entries
                            open(my $manifest_in_fh, '<', $file_path)
                                or die "\nERROR: could not open for read $file_path\n\n";
                            my @new_manifest_file_lines;
                            while (<$manifest_in_fh>) {
                                next if m/^\s*$/;
                                my ($checksum, $rel_file_path) = split(' ', $_, 2);
                                if ($rel_file_path !~ /\/old_data\//) {
                                    push @new_manifest_file_lines, $_;
                                }
                            }
                            close($manifest_in_fh);
                            # backup archive if exists
                            my $backup_success;
                            if (-e "$archive_dir_path/$file_name") {
                                for (my $i = 1; ; $i++) {
                                    if (!-e "$archive_dir_path/${file_name}.$i") {
                                        print "  Moving $archive_dir_path/$file_name ->\n",
                                              "         $archive_dir_path/${file_name}.$i\n" if $verbose;
                                        if (!$dry_run) {
                                            if (!$dry_run) {
                                                if (move("$archive_dir_path/$file_name", "$archive_dir_path/${file_name}.$i")) {
                                                    $backup_success++;
                                                }
                                                else {
                                                    warn "ERROR: could not move file: $!\n",
                                                         "$archive_dir_path/$file_name ->\n$archive_dir_path/${file_name}.$i\n";
                                                }
                                            }
                                        }
                                        last;
                                    }
                                }
                            }
                            else {
                                $backup_success++;
                            }
                            # archive file
                            my $archive_success;
                            if ($backup_success or $dry_run) {
                                print "  Moving $file_path ->\n",
                                      "         $archive_dir_path/$file_name\n" if $verbose;
                                if (!$dry_run) {
                                    if (move($file_path, "$archive_dir_path/$file_name")) {
                                        $archive_success++;
                                        chmod($data_file_mode, "$archive_dir_path/$file_name");
                                        chown($adm_owner_uid, $adm_group_gid, "$archive_dir_path/$file_name");
                                    }
                                    else {
                                        warn "ERROR: could not move file $!\n",
                                             "$file_path ->\n$archive_dir_path/$file_name\n";
                                    }
                                }
                            }
                            # create new manifest file
                            if ($archive_success or $dry_run) {
                                print "Creating $file_path\n" if $verbose;
                                if (!$dry_run) {
                                    open(my $manifest_out_fh, '>', $file_path)
                                        or die "\nERROR: could not open for write $file_path\n\n";
                                    print $manifest_out_fh @new_manifest_file_lines;
                                    close($manifest_out_fh);
                                    chmod($data_file_mode, "$archive_dir_path/$file_name");
                                    chown($adm_owner_uid, $adm_group_gid, "$archive_dir_path/$file_name");
                                }
                            }
                        }
                    }
                }
            },
        },
        @cgi_data_dirs);
    }
}
exit;

__END__

=head1 NAME

archive_cgi_old_data.pl - CGI WGS Old Data and Manifest Archiver

=head1 SYNOPSIS

 archive_cgi_old_data.pl <program name(s)> <project name(s)> [options]
 
 Parameters:
    <program name(s)>       Comma-separated list of program name(s) (optional, default: all programs)
    <project name(s)>       Comma-separated list of project name(s) (optional, default: all program projects)
 
 Options:
    --verbose               Be verbose
    --dry-run               Show what would be done
    --debug                 Show debug information
    --help                  Display usage message and exit
    --version               Display program version and exit

=cut

