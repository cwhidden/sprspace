#!/usr/bin/perl
################################################################################
# cytoscape_edge_weights.pl
################################################################################
#
# Construct an MCMC graph of transitions between trees in a phylogenetic
# Bayesian Markov chain
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

#input:
# list of tree transitions
# tree order list

my $topology_order_file = $ARGV[0]; 

my $INCLUDE_ISOLATED = 1;

if ($#ARGV >= 1) {
	$INCLUDE_ISOLATED = $ARGV[1];
}

open(TOPO_ORDER, "<$topology_order_file");

my %topo_order = ();
my $num = 1;
while(<TOPO_ORDER>) {
	chomp;
	$topo_order{$_} = $num;
	$num++;
}

my @m = ();

my $prev_topo_num;
while(<STDIN>) {
	chomp;
	my $new_topo = $_;
	my $new_topo_num= $topo_order{$new_topo}; 
	if (defined($prev_topo_num)) {
		my $a;
		my $b;
		if ($new_topo_num < $prev_topo_num) {
			$a = $new_topo_num;
			$b = $prev_topo_num;
		}
		else {
			$a = $prev_topo_num;
			$b = $new_topo_num;
		}
		# ignore transitions outside of the node set
		if ($a > 0) {
			if (!defined($m[$a])) {
				$m[$a] = {};
			}
			if (!defined($m[$a]{$b})) {
				$m[$a]{$b} = 1;
			}
			else {
				$m[$a]{$b}++;
			}
		}
	}
	$prev_topo_num = $new_topo_num;
}

my @isolated;
if ($INCLUDE_ISOLATED) {
	@isolated = (1) x $num;
}
for my $i (1..($num-1)) {
	for my $b (sort { $a <=> $b } keys %{ $m[$i] } ) {
		$isolated[$i] = 0;
		my $j = $m[$i]{$b};
		$isolated[$b] = 0;
		print $i-1,",",$b-1,",";
		print $j;
		print "\n";
	}
	if ($isolated[$i]) {
		print $i-1,"\n";
	}
}
