#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use File::Path 2.11 qw(make_path);
use File::Spec;
use Getopt::Long qw(:config auto_help auto_version);
use Pod::Usage qw(pod2usage);
use Term::ANSIColor;
use Data::Dumper;

our $VERSION = '0.1';

# Unbuffer error and output streams 
# (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

# config
my $symlink_file = "$FindBin::Bin/target_cgi_data_symlinks.txt";
my $owner_name = 'ocg-dcc-adm';
my $group_name = 'target-dn-ctrld';
my $link_group_name = 'ocg-dcc-adm';
my $ctrld_dir_mode = 0550;
my $ctrld_dir_mode_str = '550';
my $ctrld_file_mode = 0440;
my $ctrld_file_mode_str = '440';

my $dry_run = 0;
my $clean_only = 0;
my $verbose = 0;
my $debug = 0;
GetOptions(
    'dry-run' => \$dry_run,
    'clean-only' => \$clean_only,
    'verbose' => \$verbose,
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
if ($< != 0 and !$dry_run) {
    pod2usage(
        -message => 'Script must be run with sudo',
        -verbose => 0,
    );
}
open(my $fh, '<', $symlink_file) or 
    die +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), 
        ": could not open $symlink_file: $!";
while (<$fh>) {
    s/^\s+//;
    s/\s+$//;
    my ($target, $link) = split /\t/;
    if (!-d $target) {
        warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), 
             ": $target doesn't exist\n";
    }
    my @link_dir_parts = File::Spec->splitdir($link);
    my $link_parent_dir = File::Spec->catdir(@link_dir_parts[0 .. $#link_dir_parts - 1]);
    if (!-d $link_parent_dir) {
        print "Creating $link_parent_dir\n";
        if (!$dry_run) {
            make_path($link_parent_dir, {
                chmod => $ctrld_dir_mode,
                owner => $owner_name,
                group => $group_name,
                error => \my $err,
            });
            if (@{$err}) {
                for my $diag (@{$err}) {
                    my ($file, $message) = %{$diag};
                    warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), 
                         ": could not create $file: $message\n";
                }
            }
        }
    }
    if (-e $link) {
        print "Removing $link\n";
        if (!$dry_run) {
            if (!unlink($link)) {
                warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), 
                     ": could not remove symlink: $!\n";
                next;
            }
        }
    }
    next if $clean_only;
    my $target_rel_path = File::Spec->abs2rel($target, $link_parent_dir);
    print "Linking $link ->\n",
          "        $target_rel_path\n";
    if (!$dry_run) {
        symlink($target_rel_path, $link) or
            warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), 
                 ": could not create symlink: $!\n";
        system("chown -h $owner_name:$link_group_name $link") == 0 or
            warn +(-t STDOUT ? colored('ERROR', 'red') : 'ERROR'), 
                 ": could not chown symlink, exit code: ", $? >> 8, "\n";
    }
}
close($fh);

__END__

=head1 NAME 

create_target_cgi_data_symlinks.pl - TARGET CGI Data Symlink Creator

=head1 SYNOPSIS

 create_target_cgi_data_symlinks.pl [options]
 
 Options:
    --dry-run               Perform trial run with no changes made (doesn't require sudo)
    --clean-only            Only clean existing links
    --verbose               Be verbose
    --help                  Display usage message and exit
    --version               Display program version and exit
 
=cut
