package NCI::OCGDCC::Utils;

use strict;
use warnings;
use File::Spec;
use List::Util qw( max );
use Sort::Key::Natural qw( mkkey_natural );
require Exporter;

our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    manifest_by_file_path
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.1';

# sort by file path (file column idx 1)
sub manifest_by_file_path ($$) {
    my ($a, $b) = @_;
    my $a_file_path = (split(' ', $a, 2))[1];
    my $b_file_path = (split(' ', $b, 2))[1];
    my @a_path_parts = File::Spec->splitdir($a_file_path);
    my @b_path_parts = File::Spec->splitdir($b_file_path);
    # sort top-level files last
    if (
        $#a_path_parts != 0 and 
        $#b_path_parts == 0
    ) {
        return -1;
    }
    elsif (
        $#a_path_parts == 0 and 
        $#b_path_parts != 0
    ) {
        return 1;
    }
    for my $i (
        0 .. max($#a_path_parts, $#b_path_parts)
    ) {
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

1;
