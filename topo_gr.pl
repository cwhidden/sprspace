#!/bin/bash
################################################################################
# topo_gr.pl
################################################################################
#
# Compute the topological Gelman-Rubin statistic for a set of Bayesian
# posteriors.
# 
# Copyright 2014 Chris Whidden
# cwhidden@fhcrc.org
# May 2, 2014
# Version 1.0
# 
# This file is part of spr_grapher.
# 
# spr_grapher is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# spr_grapher is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# spr_grapheralong with spr_grapher.  If not, see <http://www.gnu.org/licenses/>.
################################################################################
#!/usr/bin/perl

use File::Basename;

die "usage: topo_gr.pl <tree_list> <distance_matrix> <num_samples>\n" unless ($#ARGV >= 2);
my $tree_list_file = $ARGV[0];
my $distance_matrix = $ARGV[1];
my $num_samples = $ARGV[2];
my $top = 4096;
if ($#ARGV >= 3) {
	$top = $ARGV[3];
}
# 1 - square each distance
# 2 - square difference of tree to other trees
# 3 - neither
my $mode=1;
if ($#ARGV >= 4) {
	$mode = $ARGV[4];
}
my $top_dir = dirname($tree_list_file);

my @distances = ();
my @topologies = ();
my @all_topologies = ();

my @chain_W = ();

# read distance matrix
open(DISTANCE, "<$distance_matrix");
while(<DISTANCE>) {
	chomp;
	push(@distances, []);
	push($distances[$#distances], split(","));
}
close(DISTANCE);

# read topology orders and PP
open(TREES, "<$tree_list_file");
while (<TREES>) {
	my ($id, $pp) = split();
	if ($id < $top) {
		push(@all_topologies, {});
		$all_topologies[-1]{id} = $id;
		$all_topologies[-1]{pp} = $pp;
	}
}
close(TREES);

# for each run_dir
while(<STDIN>) {
	chomp;
	my $run_dir = $_;
	my $tree_file = "$run_dir/uniq_shapes_C_numbered";
	push(@topologies, []);
	open(TREES, "<$tree_file");
	while (<TREES>) {
		my ($id, $pp) = split();
		if ($id < $top) {
			push(@topologies[-1], {});
			$topologies[-1][-1]{id} = $id;
			$topologies[-1][-1]{pp} = $pp;
		}
	}
	close(TREES);
}

##for my $i (0..$#all_topologies) {
##	print $all_topologies[$i]{id};
##	print "\t";
##	print $all_topologies[$i]{pp};
##	print "\n";
##}
##print "\n";
##for my $j (0..$#topologies) {
##	print "run", $j+1, "\n";
##	for my $i (0..$#{$topologies[$j]}) {
##		print $topologies[$j][$i]{id};
##		print "\t";
##		print $topologies[$j][$i]{pp};
##		print "\n";
##	}
##	print "\n";
##}

my $num_runs = scalar @topologies;
my $num_topologies = scalar @all_topologies; 

# calculate W: within-chain variance
# TODO: running average for less error
my $W = 0;
my $all_normalize = 0;
print "computing within-chain variance\n";
for my $j (0..$num_runs-1) {
##	print "within-chain variance for run", $j+1, "\n";
	my $chain_topologies = scalar @{$topologies[$j]};
	my $chain_W = 0;
	my $chain_normalize = 0;
	for my $i1 (0..$chain_topologies-1) {
		my $global_i1 = $topologies[$j][$i1]{id};
		my $weight_i1 = $topologies[$j][$i1]{pp};
		my $chain_diff = 0;
		$chain_normalize += $weight_i1;
##		print "\t", $i1+1, " = $global_i1, $weight_i1\n";
		my $normalize = 0;
		for my $i2 (0..$chain_topologies-1) {
			my $global_i2 = $topologies[$j][$i2]{id};
			my $weight_i2 = $topologies[$j][$i2]{pp};
			my $diff = $distances[$global_i1-1][$global_i2-1];
if ($mode == 1) {
			$diff *= $diff;
}
			my $weight = $weight_i2;
			$normalize += $weight_i2;
##			print "\t\t", $i2+1, " = $global_i2, $weight_i2";
##			print ", diff=$diff, weight=$weight, ";
			$diff *= $weight;
##			print "weighted_diff=$diff";
##			print "\n";
			$chain_diff += $diff;
		}
		
##		print "\t$normalize\n";
		$chain_diff /= $normalize;
##		print "\tchain_diff=$chain_diff, squared=", $chain_diff * $chain_diff, "\n";
if ($mode == 2) {
		$chain_diff = $chain_diff * $chain_diff * $weight_i1;
}
else {
		$chain_diff = $chain_diff * $weight_i1;
##		print "\tchain_diff=",$chain_diff/$weight_i1,", weight=$weight_i1, weighted_diff=$chain_diff\n";
}
		$chain_W += $chain_diff;
	}
##	$all_normalize += $chain_normalize;
	$all_normalize++;
	$chain_W /= $chain_normalize;
	push(@chain_W, $chain_W);
	$W += $chain_W;
##	print "chain_W: ", $chain_W, ", chain_normalize: $chain_normalize, W: $W\n";
	print "\tchain_W: $chain_W\n";
}
$W /= $all_normalize;
##print "W: $W, all_normalize: $all_normalize\n";
print "W: $W\n";

# calculate B: between-chain variance
# TODO: running average for less error
my $B = 0;
my $all_normalize = 0;
print "computing between-chain variance\n";
for my $j (0..$num_runs-1) {
##	print "between-chain variance for run", $j+1, "\n";
	my $chain_topologies = scalar @{$topologies[$j]};
	my $chain_B = 0;
	my $chain_normalize = 0;
	for my $i1 (0..$chain_topologies-1) {
		my $global_i1 = $topologies[$j][$i1]{id};
		my $weight_i1 = $topologies[$j][$i1]{pp};
		my $chain_diff = 0;
		$chain_normalize += $weight_i1;
##		print "\t", $i1+1, " = $global_i1, $weight_i1\n";
		my $normalize = 0;
		for my $i2 (0..$num_topologies-1) {
			my $global_i2 = $all_topologies[$i2]{id};
			my $weight_i2 = $all_topologies[$i2]{pp};
			my $diff = $distances[$global_i1-1][$global_i2-1];
if ($mode == 1) {
			$diff *= $diff;
}
			my $weight = $weight_i2;
			$normalize += $weight_i2;
##			print "\t\t", $i2+1, " = $global_i2, $weight_i2";
##			print ", diff=$diff, weight=$weight, ";
			$diff *= $weight;
##			print "weighted_diff=$diff";
##			print "\n";
			$chain_diff += $diff;
		}
		
##		print "\t$normalize\n";
		$chain_diff /= $normalize;
##		print "\tchain_diff=$chain_diff, squared=", $chain_diff * $chain_diff, "\n";
if ($mode == 2) {
		$chain_diff = $chain_diff * $chain_diff * $weight_i1;
}
else {
		$chain_diff = $chain_diff * $weight_i1;
##		print "\tchain_diff=",$chain_diff/$weight_i1,", weight=$weight_i1, weighted_diff=$chain_diff\n";
}
		$chain_B += $chain_diff;
	}
#	$all_normalize += $chain_normalize;
	$all_normalize++;
	$chain_B /= $chain_normalize;
	push(@chain_B, $chain_B);
	$B += $chain_B;
##	print "chain_B: ", $chain_B, ", chain_normalize: $chain_normalize, B: $B\n";
	print "\tchain_B: $chain_B\n";
}
$B /= $all_normalize;
##print "B: $B, all_normalize: $all_normalize\n";
print "B: $B\n";



if (0) {

# calculate B: between-chain variance
my $B = 0;
print "computing between-chain variance\n";
my $all_normalize = -1;
for my $j (0..$num_runs-1) {
	my $chain_B = 0;
	my $chain_normalize = 0;
	for my $chain_i (0..$#{$topologies[$j]}) {
		my $i1 = $topologies[$j][$chain_i]{id};
##		print "\tchain_i: $chain_i, i1: $i1\n";
		for my $i2 (0..$num_topologies-1) {
##			print "\t\ti2: $i2\n";
			my $diff = $distances[$i1][$i2];
			$diff *= $diff;
			my $weight1 = $topologies[$j][$chain_i]{pp};
			my $weight2 = $all_topologies[$i2]{pp};
##			print "\t\tdiff: $diff, w1: $weight1, w2: $weight2\n";
			$chain_B += $diff * $weight1 * $weight2;
			$chain_normalize += $weight1 * $weight2;
		}
	}
	$chain_B /= $chain_normalize;
##	$all_normalize += $chain_normalize;
	$all_normalize++;
##	print "\tsqrt(chain_B): $chain_B, chain_normalize, $chain_normalize";
#	$chain_B *= $chain_B;
##	print ", chain_B: $chain_B\n";
	print "\tchain_B: $chain_B\n";
	$B += $chain_B;
}
$B /= $all_normalize;
##print "B: $B, all_normalize: $all_normalize\n";
print "B: $B\n";

}

my $var = ($W + $B) / 2;
#$var = (1 - 1/$num_samples) * $W + 1/$num_samples * $B;
print "variance: $var\n";

my $RMSD = sqrt($var);
print "RMSD: $RMSD\n";

my $PSRF = sqrt($var / $W);
print "PSRF: $PSRF\n";

##my $alt1 = (1 - 1/$num_samples) * $W + 1/$num_samples * $B;
##my $psrf_1 = sqrt($alt1 / $W);
##my $alt2 = (1 - 1/$num_samples) * $W + $B;
##my $psrf_2 = sqrt($alt2 / $W);
##print "alternatives\t";
##print "var: ", $alt1;
##print ", ", $alt2;
##print "\n";
##print "PSRF: ", $psrf_1;
##print ", ", $psrf_2;
##print "\n";
