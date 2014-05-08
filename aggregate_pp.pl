#!/usr/bin/perl
################################################################################
# aggregate_pp.pl
################################################################################
# 
# Aggregate the posterior probabilities of a set of Bayesian MCMC runs
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
my $sum_pp = 0;
while(<>) {
	my ($pp, $start, $ll, $tree) = split(" ");
#	print STDERR "$pp\n";
	chomp $tree;
	if ($current ne $tree) {
		if ($current ne "") {
			print "$sum_pp $current\n";
		}
		$current = $tree;
		$sum_pp = $pp;
	}
	else {
		$sum_pp += $pp;
	}
}
print "$sum_pp $current\n";
