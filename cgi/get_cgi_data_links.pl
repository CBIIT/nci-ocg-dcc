#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../common/lib/perl5";
use Config::Any;
use Cwd qw( realpath );
use File::Find;
use File::Spec;
use Getopt::Long qw( :config auto_help auto_version );
use List::Util qw( first uniq );
use List::MoreUtils qw( any none );
use Pod::Usage qw( pod2usage );
use Sort::Key::Natural qw( natsort natkeysort );
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
my @param_groups = qw(
    programs
    projects
);

my $relative = 0;
my $verbose = 0;
my $debug = 0;
GetOptions(
    'relative' => \$relative,
    'verbose' => \$verbose,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
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
        #print "[$program_name $project_name]\n";
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
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                        ": invalid subproject '$subproject'\n";
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
                    die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                        ": invalid subproject '$subproject'\n";
                }
            }
            else {
                die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'), 
                    ": invalid disease project '$disease_proj'\n";
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
        my @link_info;
        find({
            wanted => sub {
                # symlinks only
                return unless -l;
                my $link = $File::Find::name;
                my $link_dir = $File::Find::dir;
                my $target = realpath(readlink($link));
                if ($relative) {
                    $target = File::Spec->abs2rel($target, $link_dir);
                }
                push @link_info, [
                    $target,
                    $link,
                ];
            },
        }, @cgi_data_dirs);
        print join("\n", map { "$_->[0]\t$_->[1]" } natkeysort { $_->[1] } @link_info), "\n";
    }
}
exit;

__END__

=head1 NAME

get_cgi_data_links.pl - CGI WGS Data Symlinks List Generator

=head1 SYNOPSIS

 get_cgi_data_links.pl <program name(s)> <project name(s)> [options]
 
 Parameters:
    <program name(s)>       Comma-separated list of program name(s) (optional, default: all programs)
    <project name(s)>       Comma-separated list of project name(s) (optional, default: all program projects)
 
 Options:
    --verbose               Be verbose
    --debug                 Show debug information
    --help                  Display usage message and exit
    --version               Display program version and exit

=cut