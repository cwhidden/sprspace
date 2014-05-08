#!/usr/bin/perl
################################################################################
# find_uniq_best_ll.pl
################################################################################
#
# Aggregate MCMC samples with the same topology, storing the top log likelihood
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

my $current = "";
my $best_ll = 0 - "inf";
my $c_num;
my $count = 0;
while(<>) {
	my ($num, $ll, $tree) = split(";");
#	print "$tree\n";
#	$tree=`bash -c \'nw_order <(echo "$tree;"\)\'`;
#	print "$tree\n";
#	print "\n\n";
#	chomp $tree;
	if ($current ne $tree) {
		if ($current ne "") {
			print "$count $c_num $best_ll $current\n";
		}
		$current = $tree;
		$best_ll = $ll;
		$c_num = $num;
		$count = 1;
	}
	else {
		if ($ll > $best_ll) {
			$best_ll = $ll;
			$c_num = $num;
		}
		$count++;
	}
}
print "$count $c_num $best_ll $current\n";
