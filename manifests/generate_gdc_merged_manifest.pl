#!/usr/bin/env perl

use strict;
use warnings;
use File::Find;
use File::Spec;
use Getopt::Long qw( :config auto_help auto_version );
use List::Util qw( any none max );
use Pod::Usage qw( pod2usage );
use POSIX qw( strftime );
use Sort::Key::Natural qw( natsort mkkey_natural );
use Term::ANSIColor;
use Data::Dumper;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = sub {
    my ($hashref) = @_;
    my @sorted_keys = natsort keys %{$hashref};
    return \@sorted_keys;
};

# sort by file path (file column idx 1)
sub manifest_by_file_path {
    my $a_file_path = (split(' ', $a, 2))[1];
    my $b_file_path = (split(' ', $b, 2))[1];
    my @a_path_parts = File::Spec->splitdir($a_file_path);
    my @b_path_parts = File::Spec->splitdir($b_file_path);
    # sort top-level files last
    if ($#a_path_parts != 0 and 
        $#b_path_parts == 0) {
        return -1;
    }
    elsif ($#a_path_parts == 0 and 
           $#b_path_parts != 0) {
        return 1;
    }
    for my $i (0 .. max($#a_path_parts, $#b_path_parts)) {
        # debugging
        #print join(',', map { $_ eq $a_path_parts[$i] ? colored($_, 'red') : $_ } @a_path_parts), "\n",
        #      join(',', map { $_ eq $b_path_parts[$i] ? colored($_, 'red') : $_ } @b_path_parts);
        #<STDIN>;
        return -1 if $i > $#a_path_parts;
        return  1 if $i > $#b_path_parts;
        # do standard ls sorting instead of natural sorting
        #return mkkey_natural(lc($a_path_parts[$i])) cmp mkkey_natural(lc($b_path_parts[$i]))
        #    if mkkey_natural(lc($a_path_parts[$i])) cmp mkkey_natural(lc($b_path_parts[$i]));
        return lc($a_path_parts[$i]) cmp lc($b_path_parts[$i])
            if lc($a_path_parts[$i]) cmp lc($b_path_parts[$i]);
    }
    return $#a_path_parts <=> $#b_path_parts;
}

# config
my @program_names = qw(
    TARGET
    CGCI
    CTD2
);
my @param_groups = qw(
    programs
);
my $default_manifest_file_name = 'MANIFEST.txt';
my $manifest_user_name = 'ocg-dcc-adm';
my $manifest_file_perm = 0440;
my @manifest_file_names = (
    $default_manifest_file_name,
    'manifest.all.unencrypted',
    'manifest.dcc.unencrypted',
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
    my $manifest_gid = getgrnam("\L$program_name\E-dn-adm")
        or die +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), ": couldn't get gid for \L$program_name\E-dn-adm\n";
    my $program_download_dir = "/local/\L$program_name\E/download";
    my @search_download_dirs = (
        "$program_download_dir/Controlled",
        "$program_download_dir/Public",
    );
    my @merged_manifest_lines;
    for my $search_download_dir (@search_download_dirs) {
        find({
            follow => 1,
            wanted => sub {
                # directories
                if (-d) {
                    # skip hidden and directories with duplicate data or data not of interest
                    if ($File::Find::name =~ /^\Q$search_download_dir\E\/(CGI|DBGAP_METADATA|OS\/(?:Brazil|Toronto)|Resources)$/) {
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
        }, $search_download_dir);
    }
    my @sorted_merged_manifest_lines = sort manifest_by_file_path @merged_manifest_lines;
    my $date_str = strftime('%Y%m%d', localtime);
    my $merged_manifest_file = "$program_download_dir/PreRelease/GDC/\U$program_name\E_MANIFEST_MERGED_${date_str}.txt";
    print "Writing $merged_manifest_file\n" if $verbose;
    if (!$dry_run) {
        open(my $manifest_out_fh, '>', $merged_manifest_file)
            or die +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), ": could not write open $merged_manifest_file: $!";
        print $manifest_out_fh @sorted_merged_manifest_lines;
        close($manifest_out_fh);
        set_manifest_perms(
            $merged_manifest_file, $manifest_gid, $manifest_file_perm,
        );
    }
}
exit;

sub set_manifest_perms {
    my ($manifest_file, $manifest_gid, $manifest_file_perm) = @_;
    #chown(-1, $manifest_gid, $manifest_file);
    chown($manifest_uid, $manifest_gid, $manifest_file) 
        or warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), ": couldn't chown $manifest_file\n";
    chmod($manifest_file_perm, $manifest_file) 
        or warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), ": couldn't chmod $manifest_file\n";
}

__END__

=head1 NAME 

generate_merged_manifest.pl - OCG DCC Merged Manifest Generator

=head1 SYNOPSIS

 generate_merged_manifest.pl [options] <program name(s)>
 
 Parameters:
    <program name(s)>       Comma-separated list of program name(s) (optional, default: all programs)
 
 Options:
    --verbose               Be verbose
    --help                  Display usage message and exit
    --version               Display program version and exit

=cut
