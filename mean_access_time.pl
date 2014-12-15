#!/usr/bin/perl
################################################################################
# mean_access_time.pl
################################################################################
#
# computes several tree mixing stats:
#   mean access time, H_ij: the expected number of steps between tree i and
#     tree j
#   mean commute time, k_ij: the expected number of steps to visit i, j, and
#     return to i = H_ij + H_ji
#
#  perl mean_access_time.pl [--num_trees n] [--num_trees_2 n2] [--tree_list l]
#  < tree_file
# Note that all three arguments are optional but at least one of
# --num_trees or --tree_list is required.
# tree_file must be a uniq_trees_T file of MCMC samples computed in Step 1.
# With --tree_list, l is a list of trees to compute mixing statistics between.
# For example, this could be a "uniq_shapes_C_sorted_by_PP" file.
# Access time statistics will be recorded between the first n trees and
# the first n2 trees. A 0 value in either specifies all trees. n2 cannot
# be smaller than n unless n2=0. If tree_list is not specified, the trees
# will be # numbered by their order in tree_file.
# 
# A typical usage will be: perl mean_access_time.pl --num_trees 1
# --tree_list uniq_shapes_C_sorted_by_PP < uniq_trees_T
# This usage computes access time and commute time statistics between tree 0
# and each other tree in the 95% credible set.
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

# TODO: read in a list of groups and compute per-group stats

use Getopt::Long;


my $num_trees = 0;
my $num_trees_2 = 0;
my $tree_list = "";
my $usage = 0;

GetOptions (
	'tree_list=s' => \$tree_list
,	'num_trees=i' => \$num_trees
,	'num_trees_2=i' => \$num_trees_2
, 'usage' => \$usage
, 'help' => \$usage
);

if ($usage || ($num_trees <= 0 && $tree_list eq "")) {
	print "usage: mean_access_time.pl [--num_trees n] [--num_trees_2 n2] [--tree_list l] < tree_file\n";
	print "       note that one of --num_trees or --tree_list is required\n";
	exit;
}

# index of trees
my %index = ();

my $trees_seen = 0;

# optionally, read in tree_list for order and specific trees
# TODO: groups?

if ($tree_list ne "") {
	open(TREES, "<$tree_list") or die "could not open $tree_list";
	while(<TREES>) {
		chomp;
		/\(\S+\)/;
		my $tree = $&;
		if (!exists($index{$tree})) {
			$index{$tree} = $trees_seen;
			$trees_seen++;
		}
	}
	close(TREES);
}

if ($num_trees <= 0) {
	$num_trees = $trees_seen;
}
if ($num_trees_2 <= 0) {
	$num_trees_2 = $trees_seen;
}

# hash of info for transition i->j
my %info = ();

# ensure num_trees is smaller than or equal to num_trees_2
if ($num_trees_2 < $num_trees) {
	my $temp = $num_trees;
	$num_trees = $num_trees_2;
	$num_trees_2 = $temp;
}

for my $i (0..($num_trees-1)) {
	push(@info, {});
	for my $j (0..($num_trees_2-1)) {
		$info{$i}{$j} = {};
		$info{$i}{$j}{mean_start} = 0;
		$info{$i}{$j}{start_count} = 0; 
		$info{$i}{$j}{mean_access} = 0; 
		$info{$i}{$j}{count} = 0; 
	}
}

for my $i ($num_trees..($num_trees_2-1)) {
	push(@info, {});
	for my $j (0..($num_trees-1)) {
		$info{$i}{$j} = {};
		$info{$i}{$j}{mean_start} = 0;
		$info{$i}{$j}{start_count} = 0; 
		$info{$i}{$j}{mean_access} = 0; 
		$info{$i}{$j}{count} = 0; 
	}
}

# read in trees
my $prev_n = 0;
while(<STDIN>) {
	chomp;
	my ($step) = split();
	/\(\S+\)/;
	my $tree = $&;
	my $n = $prev_n;
	my $final_n = $n + $step;
	if (!exists($index{$tree})) {
		if ($tree_list eq "") {
			$index{$tree} = $trees_seen;
			$trees_seen++;
			$found = 1;
		}
		else {
			$prev_n = $final_n;
			next;
		}
	}
	my $i = $index{$tree};

	my $max = $num_trees-1;
	if ($i < $num_trees) {
		$max = $num_trees_2;
	}

		while ($n < $final_n) {
			$n++;

			for my $j (0..($max)) {
	
	
			# update j -> i
			if (($info{$j}{$i}{count} + $info{$j}{$i}{start_count}) > 0) {
				my $update_weight = $info{$j}{$i}{start_count} /
						($info{$j}{$i}{count} + $info{$j}{$i}{start_count});
				my $update = ($n - $info{$j}{$i}{mean_start})
						- $info{$j}{$i}{mean_access}; 
				$info{$j}{$i}{mean_access} += $update_weight * $update;
		
				$info{$j}{$i}{count} += $info{$j}{$i}{start_count};
				$info{$j}{$i}{start_count} = 0;
				$info{$j}{$i}{start_avg} = 0;
			}
	
			# update i -> j
			## TESTING ignore multiple visits
			if ($info{$i}{$j}{start_count} == 0) {
				$info{$i}{$j}{start_count}++;
				# running mean of i visits before j visit
				$info{$i}{$j}{mean_start} += ($n - $info{$i}{$j}{mean_start}) / $info{$i}{$j}{start_count}; 
			}
		}
	}
	
	$prev_n = $final_n;
}

#print "trees_seen: $trees_seen\n";

# update for end values greater than the mean
for my $i (0..($num_trees-1)) {
	for my $j (0..($num_trees2-1)) {
		# update j -> i
		if (($info{$j}{$i}{count} + $info{$j}{$i}{start_count}) > 0) {
			my $update_weight = $info{$j}{$i}{start_count} /
					($info{$j}{$i}{count} + $info{$j}{$i}{start_count});
			my $update = ($prev_n - $info{$j}{$i}{mean_start})
					- $info{$j}{$i}{mean_access}; 
			# only update if it increases a non-infinite mean access time
			if ($update > 0 && $info{$j}{$i}{mean_access} > 0) {
				$info{$j}{$i}{mean_access} += $update_weight * $update;
	
				$info{$j}{$i}{count} += $info{$j}{$i}{start_count};
				$info{$j}{$i}{start_count} = 0;
				$info{$j}{$i}{start_avg} = 0;
			}
		}
	}
}

print " \tmean_access_time";
print "\tmean_commute_time";
print "\n";
for my $i (0..($num_trees-1)) {
	for my $j (0..($num_trees_2-1)) {
		print "$i -> $j";
		if ($info{$i}{$j}{mean_access} <= 0) {
			print "\t", "inf";
		}
		else {
			print "\t", $info{$i}{$j}{mean_access};
		}
		if ($info{$i}{$j}{mean_access} <= 0 || $info{$j}{$i}{mean_access} <= 0) {
			print "\t", "inf";
		}
		else {
			print "\t", $info{$i}{$j}{mean_access} + $info{$j}{$i}{mean_access};
		}
		print "\n";
	}
}






