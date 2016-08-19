#!/usr/bin/env perl

use strict;
use warnings;
use sigtrap qw(handler sig_handler normal-signals error-signals ALRM);
use Cwd qw(cwd);
use File::Basename qw(fileparse);
use Getopt::Long qw(:config auto_help auto_version);
use List::Util qw(min);
use Parallel::Forker;
use Pod::Usage qw(pod2usage);
use Sort::Key::Natural qw(natsort);
use Unix::Processors;
use Data::Dumper;

our $VERSION = '0.1';

# Unbuffer error and output streams (make sure STDOUT is last so that it remains the default filehandle)
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Deepcopy = 1;

sub sig_handler {
    die "Caught signal, exiting\n";
}

my $num_procs = 1;
my $debug = 0;
my $verbose = 0;
my $dry_run = 0;
GetOptions(
    'num-procs:i' => \$num_procs,
    'debug' => \$debug,
    'verbose' => \$verbose,
    'dry-run' => \$dry_run,
) || pod2usage(-verbose => 0);
pod2usage(
    -message => 'Invalid input directory',
    -verbose => 0,
) if $ARGV[0] and !-d $ARGV[0];
pod2usage(
    -message => 'Invalid output directory',
    -verbose => 0,
) if $ARGV[1] and !-d $ARGV[1];
pod2usage(
    -message => 'Num procs must be >= 1',
    -verbose => 0,
) unless $num_procs >= 1;
my ($data_dir, $output_dir) = @ARGV;
$data_dir = cwd() unless $data_dir;
$output_dir = cwd() unless $output_dir;
my $cwd = cwd();
print 'Getting fastq.gz file list... ';
# chdir so zcat cmd below can be shorter (won't need to specify full file paths)
chdir($data_dir) or die "ERROR: could not chdir $data_dir: $!";
opendir(my $data_dh, $data_dir) or die "ERROR: could not opendir $data_dir: $!";
my @file_names = natsort grep { -f "$data_dir/$_" and m/\.fastq\.gz$/i } readdir($data_dh);
closedir($data_dh);
pod2usage(
    -message => "\nNo fastq.gz files found in $data_dir",
    -verbose => 0,
) unless @file_names;
print scalar(@file_names), " files\n";
my %file_names_by_prefix;
for my $file_name (@file_names) {
    my @file_basename_parts = split('_', fileparse($file_name, qr/\..*/));
    my $file_basename_prefix = join('_', @file_basename_parts[0 .. $#file_basename_parts - 1]);
    push @{$file_names_by_prefix{$file_basename_prefix}}, $file_name;
}
my $fork_manager = Parallel::Forker->new(use_sig_child => 1, max_proc => min($num_procs, Unix::Processors->new()->max_physical));
$SIG{CHLD} = sub { Parallel::Forker::sig_child($fork_manager) };
$SIG{TERM} = sub { $fork_manager->kill_tree_all('TERM') if $fork_manager and $fork_manager->in_parent; die "Exiting child process\n" };
for my $file_basename_prefix (natsort keys %file_names_by_prefix) {
    $fork_manager->schedule(
        run_on_start => sub {
            print "[$file_basename_prefix]\n" if $num_procs == 1;
            my @file_names = @{$file_names_by_prefix{$file_basename_prefix}};
            print STDERR ($num_procs > 1 ? "[PID $$] " : ''), "\@file_names = ", Dumper(\@file_names) if $debug;
            my $files_str = join(' ', @file_names);
            my $zcat_opts = '-f' . ( ( $verbose and $num_procs == 1 ) ? 'v' : '' );
            # for FASTQs you get much faster gzip compression speed and close 
            # to standard compression level when you specify -1 or --fast
            my $gzip_opts = '-1f' . ( ( $verbose and $num_procs == 1 ) ? 'v' : '' );
            my $cmd_str = "zcat $zcat_opts $files_str | gzip $gzip_opts > $output_dir/${file_basename_prefix}.fastq.gz";
            print +($num_procs > 1 ? "[PID $$] " : ''), "$cmd_str\n";
            if (!$dry_run) {
                system($cmd_str) == 0
                    or die +($num_procs > 1 ? "[PID $$] " : ''), "gzip command failed, exit code ", $? >> 8, "\n";
            }
        }
    )->ready();
}
# wait for all child processes to finish
$fork_manager->wait_all();
chdir($cwd);
exit;

__END__

=head1 NAME 

merge_fastqs.pl - Compressed FASTQ File Merger

=head1 SYNOPSIS

 merge_fastqs.pl <fastq.gz dir> <output dir> [options]
 
 Parameters:
    <fastq.gz dir>      Input fastq.gz directory path (optional, default $PWD)
    <output dir>        Output merged fastq.gz directory path (optional, default $PWD)
 
 Options:
    --num-procs=n       Number of parallel processes to use (default 1, no parallel)
    --dry-run           Show what would be done
    --verbose           Be verbose
    --debug             Run in debug mode
    --help              Display usage message and exit
    --version           Display program version and exit

=cut
