#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use Cwd qw( cwd );
use File::Find;
use File::Spec;
use Getopt::Long qw( :config auto_help auto_version );
use List::Util qw( any first none uniq );
use NCI::OCGDCC::Utils qw( load_configs manifest_by_file_path );
use Pod::Usage qw( pod2usage );
use POSIX qw( strftime );
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
my $config_hashref = load_configs(qw(
    cgi
    common
    manifests
));
my @program_names = @{$config_hashref->{'common'}->{'program_names'}};
my %program_dn_group_name = %{$config_hashref->{'common'}->{'data_filesys_info'}->{'program_dn_group_name'}};
my $default_manifest_file_name = $config_hashref->{'manifests'}->{'default_manifest_file_name'};
my $manifest_user_name = $config_hashref->{'manifests'}->{'data_filesys_info'}->{'manifest_user_name'};
my $manifest_file_mode = $config_hashref->{'manifests'}->{'data_filesys_info'}->{'manifest_file_mode'};
my @cgi_manifest_file_names = @{$config_hashref->{'cgi'}->{'manifest_file_names'}};
my @manifest_file_names = (
    $default_manifest_file_name,
    @cgi_manifest_file_names,
);
my %program_download_search_skip_dirs =
    %{$config_hashref->{'manifests'}->{'merged_manifest'}->{'program_download_search_skip_dirs'}};
my @param_groups = qw(
    programs
);

my $dry_run = 0;
my $verbose = 0;
my $debug = 0;
GetOptions(
    'dry-run' => \$dry_run,
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
my $manifest_uid = getpwnam($manifest_user_name)
    or die +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), ": couldn't get uid for $manifest_user_name\n";
for my $program_name (@program_names) {
    next if defined $user_params{programs} and none { $program_name eq $_ } @{$user_params{programs}};
    my $manifest_gid = getgrnam($program_dn_group_name{$program_name})
        or die +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), 
               ": couldn't get gid for $program_dn_group_name{$program_name}\n";
    my $program_download_dir = "/local/ocg-dcc/download/$program_name";
    my @merged_manifest_lines;
    find({
        follow => 1,
        wanted => sub {
            # directories
            if (-d) {
                if (
                    any { $File::Find::name =~ /^$_/ }
                    map { "$program_download_dir/$_" }
                    @{$program_download_search_skip_dirs{$program_name}{'dirs_to_skip'}}
                ) {
                    print "Skipping $File::Find::name\n" if $verbose;
                    $File::Find::prune = 1;
                    return;
                }
            }
            elsif (-f) {
                my $file_name = $_;
                # manifest files only
                return unless any { $_ eq $file_name } @manifest_file_names;
                my $manifest_rel_dir = File::Spec->abs2rel($File::Find::dir, $program_download_dir);
                print "Adding $File::Find::name\n" if $verbose;
                open(my $manifest_in_fh, '<', $File::Find::name)
                    or die +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), ": could not read open $File::Find::name: $!";
                while (<$manifest_in_fh>) {
                    next if m/^\s*$/;
                    s/\b (\*?)/ $1$manifest_rel_dir\//;
                    push @merged_manifest_lines, $_;
                }
                close($manifest_in_fh);
            }
        },
    }, map { "$program_download_dir/$_" } @{$program_download_search_skip_dirs{$program_name}{'dirs_to_search'}});
    my @sorted_merged_manifest_lines = sort manifest_by_file_path @merged_manifest_lines;
    my $date_str = strftime('%Y%m%d', localtime);
    my $merged_manifest_file_name = "${program_name}_MANIFEST_MERGED_${date_str}.txt";
    my $merged_manifest_file = (
        !$dry_run
            ? "$program_download_dir/PreRelease/GDC"
            : cwd()
    ) . "/$merged_manifest_file_name";
    print "Writing $merged_manifest_file\n" if $verbose;
    open(my $manifest_out_fh, '>', $merged_manifest_file)
        or die +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'),
               ": could not write open $merged_manifest_file: $!";
    print $manifest_out_fh @sorted_merged_manifest_lines;
    close($manifest_out_fh);
    if (!$dry_run) {
        set_manifest_perms(
            $merged_manifest_file, $manifest_gid, $manifest_file_mode,
        );
    }
}
exit;

sub set_manifest_perms {
    my ($manifest_file, $manifest_gid, $manifest_file_mode) = @_;
    #chown(-1, $manifest_gid, $manifest_file);
    chown($manifest_uid, $manifest_gid, $manifest_file)
        or warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), ": couldn't chown $manifest_file\n";
    chmod($manifest_file_mode, $manifest_file)
        or warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), ": couldn't chmod $manifest_file\n";
}

__END__

=head1 NAME

generate_merged_manifest.pl - OCG DCC Merged Manifest Generator

=head1 SYNOPSIS

 generate_merged_manifest.pl <program name(s)> [options]
 
 Parameters:
    <program name(s)>       Comma-separated list of program name(s) (optional, default: all programs)
 
 Options:
    --verbose               Be verbose
    --dry-run               Perform trial run creating new merged manifest in $PWD (sudo not required, default: off)
    --debug                 Run in debug mode
    --help                  Display usage message and exit
    --version               Display program version and exit

=cut
