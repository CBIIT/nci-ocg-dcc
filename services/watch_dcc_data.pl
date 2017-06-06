#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use sigtrap qw( handler sig_handler normal-signals error-signals ALRM );
use Email::Sender::Simple qw( try_to_sendmail );
use Email::Simple;
use Email::Simple::Creator;
use File::ChangeNotify;
use Getopt::Long qw( :config auto_help auto_version );
use NCI::OCGDCC::Utils qw( load_configs );
use Pod::Usage qw( pod2usage );
use Sort::Key::Natural qw( natsort );
use Sys::Hostname;
use Data::Dumper;

sub sig_handler {
    die "[", scalar localtime, "] Stopping watcher\n";
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
    common
    services
));
my $email_from_address =
    $config_hashref->{'services'}->{'watch_dcc_data'}->{'email_from_address_prefix'} .
    hostname .
    $config_hashref->{'services'}->{'watch_dcc_data'}->{'email_from_address_suffix'};
my @email_to_addresses = @{$config_hashref->{'services'}->{'watch_dcc_data'}->{'email_to_addresses'}};
my @email_cc_addresses = @{$config_hashref->{'services'}->{'watch_dcc_data'}->{'email_cc_addresses'}};
my %program_config = %{$config_hashref->{'services'}->{'watch_dcc_data'}->{'program_config'}};
my %data_type_dir_names = map { $_ => 1 } @{$config_hashref->{'common'}->{'data_types'}};

my $debug = 0;
GetOptions(
    'debug' => \$debug,
) || pod2usage(-verbose => 0);
if ($< != 0) {
    pod2usage(
        -message => 'Service must be run as root or with sudo',
        -verbose => 0,
    );
}
pod2usage(
    -message => 'Missing required parameter: sleep interval (in seconds)',
    -verbose => 0,
) unless @ARGV;
my $watcher_sleep_interval = shift @ARGV;
my (@dirs_to_watch, @dirs_to_exclude);
for my $program_name (keys %program_info) {
    for my $dir_to_watch (@{$program_info{$program_name}{'dirs_to_watch'}}) {
        if (!-d $dir_to_watch) {
            die "Invalid directory $dir_to_watch\n";
        }
        push @dirs_to_watch, $dir_to_watch;
    }
    for my $dir_to_exclude (@{$program_info{$program_name}{'dirs_to_exclude'}}) {
        push @dirs_to_exclude, $dir_to_exclude;
    }
}
print
    "[", scalar localtime, "] Starting watcher\n",
    "[", scalar localtime, "] Directories: ", join('; ', @dirs_to_watch), "\n",
    "[", scalar localtime, "] Exclude: ", join('; ', @dirs_to_exclude), "\n",
    "[", scalar localtime, "] Sleep interval: $watcher_sleep_interval seconds\n";
my $watcher = File::ChangeNotify->instantiate_watcher(
    directories => \@dirs_to_watch,
    exclude => \@dirs_to_exclude,
    sleep_interval => $watcher_sleep_interval,
    follow_symlinks => 1,
);
print "[", scalar localtime, "] Ready\n";
while (my @events = $watcher->wait_for_events()) {
    for my $event (@events) {
        print '[', scalar localtime, '] ', $event->type, ' ', $event->path, "\n";
    }
}
print "[", scalar localtime, "] Stopping watcher\n";
exit;

__END__

=head1 NAME 

watch_dcc_data - Watch OCG DCC Data/Download Directories

=head1 SYNOPSIS

 watch_dcc_data [options] <sleep interval>
 
 Parameters:
    <sleep interval>    Watcher sleep interval (in secconds)
 
 Options:
    --help              Display usage message and exit
    --version           Display program version and exit
    --debug             Debug mode
    
=cut

