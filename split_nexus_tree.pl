#!/usr/bin/perl
################################################################################
# split_nexus_tree.pl
################################################################################
#
# Strip non-topological information from a BEAST or MrBayes tree
# posterior
# Example Output
# STATE_0 -10437.71208084664 ((((32,21),((((37,8),23),15),16)),((((((30,(6,14)),(18,((36,9),34))),13),((27,(17,31)),4)),((12,(19,1)),(3,((11,26),28)))),((((7,(22,25)),(2,(24,39))),33),((20,29),((10,38),5))))),35);
# 
# Copyright 2014 Chris Whidden
# cwhidden@fhcrc.org
# May 2, 2014
# Version 1.0
# 
# This file is part of sprspace.
# 
# sprspace is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# sprspace is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with sprspace.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

my @trees = ();
while(<>) {
	if (/^\s*tree ([^ ]*)[^(]* (\([^ ]*\)[^()]*;)/) {
		my ($name, $tree) = ($1, $2);
		$tree =~ s/:[^(),]*//g;
		$tree =~ s/\[[^\]]*\]//g;
#		print "$name $post $tree\n";;
		push(@trees, [$name, $tree]);
	}
}
#@trees = sort {$b->[1] <=> $a->[1]} @trees;
my $i = 0;
for my $tree (@trees) {
#	if ($i == 0) {
#		$i++;
#		next;
#	}
	my @t = @$tree;
	print "$t[0] ";
	my $length = length($#trees+1);
	print sprintf("%0" . $length . "d", $i);
	print " $t[1]\n";
	$i++;
}
