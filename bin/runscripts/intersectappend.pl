#!/usr/bin/perl -w
##use strict;

#######################################################################################
#Copyright (c) 2017  The Chancellors, Masters and Scholars of the University of Oxford
#Copyright (c) 2017, Stephen Taylor (Computational Biology Research Group, MRC Weatherall Institute of Molecular Medicine, University of Oxford)
########################################################################################

use Getopt::Long;
use Pod::Usage;
use strict;

my $output;

if ($#ARGV<3 ) {
	print "Usage: intersectappend.pl <a gff3 file> <b gff3 file> <facet name> <return value true> <return value false>\n";
	print "\nFor example:\n";
	print "a.gff is the original file that will be appended to.\n";
	print "b.gff is the comparison file generated by BEDTools:intersectBed\n";
	print "intersectappend.pl a.gff b.gff a_overlaps_b TRUE FALSE\n";
	print "would append a_overlaps_b=TRUE where a overlaps b\n";
	exit;
}

my $a_gff3=$ARGV[0];
my $b_gff3=$ARGV[1];
my $facet_return=$ARGV[2];
my $value_true=$ARGV[3];
my $value_false=$ARGV[4];

&GetOptions("o=s"=>\$output);

# compare the two files using intersectToBed
my $tmp_intersect="/tmp/intesect2bed$$.gff3";
# system("/package/bedtools/default/bin/intersectBed -a $a_gff3 -b $b_gff3 -wa | uniq > $tmp_intersect");

# Supports bedtools 2.1* - does not support bedtools 2.2*
system("bedtools intersect -a $a_gff3 -b $b_gff3 -wa | uniq > $tmp_intersect");


open(A_GFF3,$a_gff3) or die $a_gff3;
open(B_GFF3,$tmp_intersect) or die $tmp_intersect;
my @a=<A_GFF3>;
my @b=<B_GFF3>;

foreach my $a (@a) {
    my $found=0;
    foreach my $b (@b) {
	if ($a eq $b) {
	    $found=1;
	    last;
	}
    }
    chomp($a);
    if ($found==1) {
	print $a.$facet_return."=".$value_true.";\n";
    } else {
	print $a.$facet_return."=".$value_false.";\n";
    }
}

unlink($tmp_intersect);
  