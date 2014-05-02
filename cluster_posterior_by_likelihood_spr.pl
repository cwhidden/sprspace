#!/usr/bin/perl
################################################################################
# cluster_posterior_by_likelihood_spr.pl
################################################################################
# 
# Cluster trees from a Bayesian posterior by balls of SPR tree space in
# descending order of posterior probability.
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
# along with spr_grapher.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

my $T = -1;
my $AUTO_T = 1;
if ($#ARGV >= 0) {
	$T = $ARGV[0];
	$AUTO_T=0;
}

my $K = 8;

# read in matrix
#my @distances;
#while(<STDIN>) {
#	chomp;
#	my @row = split(",");
#	push(@distances, [@row]);
#}

# read in trees
my @trees = ();
while(<STDIN>) {
	chomp;
	push(@trees, $_);
}

# TODO: compute only distances needed?
# TODO: repeat for k clusters? other stopping criteria

my @unclustered = 0..$#trees;
my @cluster = ((-1) x scalar @trees);
# for each tree, sorted by likelihood
my $current_cluster = 1;
my @centers = ();
my $temp_tree_file = `mktemp`;
chomp $temp_tree_file;

# online mean and stdev calculation (Knuth ACP vol 2 1998, citing Welford 1962)
my $n = 0;
my $mean = 0;
my $M2 = 0;
my $stddev = 0;


while (@unclustered && $current_cluster <= $K) {
	# take next tree as a cluster
	my $center = $unclustered[0];
	push(@centers, $center);
	$cluster[$center] = $current_cluster;
	my @still_unclustered = ();
	# TODO: compute similarity threshold

	# compute only distances needed
	open(TMP_FILE, ">$temp_tree_file");
#	my $tree_string = "";
	for my $tree_num (@unclustered) {
		print TMP_FILE $trees[$tree_num];
		print TMP_FILE "\n";
	}
	close(TMP_FILE);
	my $distance_string = `rspr -simple_unrooted -pairwise 0 1 < $temp_tree_file`;
	my @distances = split(",", $distance_string);
	die "error: no distances returned\n" unless (scalar @distances > 0);

	# online mean and stdev calculation (Knuth ACP vol 2 1998, citing Welford 1962)
	if ($AUTO_T) {
		for my $x (@distances) {
			# ignore 0 entries
			next unless ($x > 0);
			$n++;
			my $delta = $x - $mean;
			$mean = $mean + $delta/$n;
			$M2 = $M2 + $delta * ($x - $mean);
			$stddev = sqrt($M2 / $n);
			$T = $mean - $stddev;
		}
		$T = $mean - $stddev;
	}

	for my $i (1..$#unclustered) {
		my $tree = $unclustered[$i];
		# if close enough, put in the cluster
		if ($distances[$i] <= $T) {
			$cluster[$tree] = $current_cluster;
		}
		# else put in the todo list
		else {
			push(@still_unclustered, $tree);
		}
	}
	$current_cluster++;
	@unclustered = @still_unclustered;
}

# output list of clusters
print $cluster[0];
for my $i (1..$#cluster) {
	print ",";
print $cluster[$i];
}
print "\n";

#cleanup
`rm $temp_tree_file`;
