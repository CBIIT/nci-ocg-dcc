#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use File::Basename qw( fileparse );
use NCI::OCGDCC::Utils qw( load_configs );
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
    common
));
my %script_compile_includes = %{$config_hashref->{'common'}->{'pp_compile'}->{'script_compile_includes'}};

my $script_file = shift(@ARGV) or pod2usage(
    -message => 'Script file is required parameter',
    -verbose => 0,
);
if (!-f $script_file) {
    pod2usage(
        -message => "Invalid script file $script_file",
        -verbose => 0,
    );
}
my ($script_basename, $script_dir, $script_ext) = fileparse($script_file, qr/\.[^.]*/);
if (!defined($script_compile_includes{$script_basename})) {
    pod2usage(
        -message => "No compile config exists for $script_file",
        -verbose => 0,
    );
}
my @pp_file_includes;
if (
    defined($script_compile_includes{$script_basename}{'file_paths_from_base'}) and
    @{$script_compile_includes{$script_basename}{'file_paths_from_base'}}
) {
    for my $file_path_from_base (
        @{$script_compile_includes{$script_basename}{'file_paths_from_base'}}
    ) {
        push(@pp_file_includes, "-a \"$file_path_from_base;" . fileparse($file_path_from_base) . "\"");
    }
}
my @pp_module_includes;
if (
    defined($script_compile_includes{$script_basename}{'modules'}) and
    @{$script_compile_includes{$script_basename}{'modules'}}
) {
    for my $module_name (
        @{$script_compile_includes{$script_basename}{'modules'}}
    ) {
        push(@pp_module_includes, "-M $module_name");
    }
}
my $pp_cmd_str = 'pp ';
if (@pp_file_includes or @pp_module_includes) {
    $pp_cmd_str .= "\\\n";
    $pp_cmd_str .= join(" \\\n", @pp_file_includes) . " \\\n" if @pp_file_includes;
    $pp_cmd_str .= join(" \\\n", @pp_module_includes) . " \\\n" if @pp_module_includes;
}
$pp_cmd_str .= "-c -o $script_basename $script_file";
print "$pp_cmd_str\n";
system($pp_cmd_str) == 0
    or die +(-t STDERR ? colored('ERROR', 'red') : 'ERROR'),
           ": pp compile failed, exit code: ", $? >> 8, "\n";
exit;

__END__

=head1 NAME

pp_compile.pl - OCG DCC PAR::Packer Script Compiler

=head1 SYNOPSIS

 pp_compile.pl <script file> [options]
 
 Parameters:
    <script file>       Path to script file (required)
 
 Options:
    --verbose           Be verbose
    --help              Display usage message and exit
    --version           Display program version and exit
 
=cut
