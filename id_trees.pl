#!/usr/bin/perl
################################################################################
# id_trees.pl
################################################################################
#
# Create a common numbering for multiple credible sets on the same
# dataset. Numbering is based on descending posterior probability in the
# aggregate posterior sample.
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

use File::Basename;

die "usage: id_trees.pl <tree_list>\n" unless ($#ARGV >= 0);
my $tree_list_file = $ARGV[0];
my $top_dir = dirname($tree_list_file);

my %tree_hash = ();
my @tree_info = ();
my $tree_count = 0;

my $pp_sum = 0;
open(TREE_LIST_FILE, "<$tree_list_file") or die "can't open $tree_list_file\n";
while(<TREE_LIST_FILE>) {
	my ($pp, $tree) = split();
	push(@tree_info, []);
	$tree_info[$tree_count][0] = $tree_count + 1;
	$tree_info[$tree_count][1] = $pp;
	$pp_sum += $pp;
	$tree_info[$tree_count][2] = $tree;
	$tree_count++;
	$tree_hash{$tree} = $tree_count;
}
close(TREE_LIST_FILE);

open(TREE_LIST_OUT_FILE, ">$top_dir/uniq_shapes_C_numbered");
for my $info_ref (@tree_info) {
	print TREE_LIST_OUT_FILE @$info_ref[0], " ";
	print TREE_LIST_OUT_FILE @$info_ref[1]/$pp_sum, " ";
	print TREE_LIST_OUT_FILE @$info_ref[2], " ";
	print TREE_LIST_OUT_FILE "\n";
}
close(TREE_LIST_OUT_FILE);

# for each run_dir
# read, number, and print to $run_dir/uniq_shapes_C_numbered
while(<STDIN>) {
	chomp;
	my $run_dir = $_;
	my $tree_list_file = "$run_dir/uniq_shapes_C_sorted_by_PP";
	open(TREE_LIST_FILE, "<$tree_list_file");
	my $pp_sum = 0;
	my @tree_info = ();
	my $local_tree_count = 0;
	while(<TREE_LIST_FILE>) {
		my ($pp, $first, $ll, $tree) = split();
		$pp_sum += $pp;
		push(@tree_info, []);
		my $tree_count = $tree_hash{$tree};
		$tree_info[$local_tree_count][0] = $tree_count;
		$tree_info[$local_tree_count][1] = $pp;
		$tree_info[$local_tree_count][2] = $tree;
		$local_tree_count++;
	}
	close(TREE_LIST_FILE);
	open(TREE_LIST_OUT_FILE, ">$run_dir/uniq_shapes_C_numbered");
	for my $info_ref (@tree_info) {
		print TREE_LIST_OUT_FILE @$info_ref[0], " ";
		print TREE_LIST_OUT_FILE @$info_ref[1]/$pp_sum, " ";
		print TREE_LIST_OUT_FILE @$info_ref[2], " ";
		print TREE_LIST_OUT_FILE "\n";
	}
	close(TREE_LIST_OUT_FILE);
}
