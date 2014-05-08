#!/usr/bin/perl
################################################################################
# neighbourhood_pp.pl
################################################################################
#
# Compute PP and size stats for the neighbourhood around tree 0
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

my @neighbourhood_pp = ();
my @neighbourhood_size = ();
while(<>) {
	my ($id, $pp, $dist) = split(",");
	$neighbourhood_pp[$dist] += $pp;
	$neighbourhood_size[$dist]++;
}
my $cumulative_pp = 0;
my $cumulative_size = 0;
for my $i (0..$#neighbourhood_pp) {
	$cumulative_pp += $neighbourhood_pp[$i];
	$cumulative_size += $neighbourhood_size[$i];

	print "$i,", $cumulative_pp, ",", $cumulative_size, "\n";
}

