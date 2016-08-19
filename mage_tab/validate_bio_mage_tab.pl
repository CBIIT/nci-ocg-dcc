#!/usr/bin/env perl

use strict;
use warnings;
use Bio::MAGETAB::Util::Reader;

my $magetab_reader = Bio::MAGETAB::Util::Reader->new({
    idf => shift @ARGV,
});
my $magetab = $magetab_reader->parse();
