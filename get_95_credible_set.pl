#!/usr/bin/perl
################################################################################
# get_95_credible_set.pl
################################################################################
#
# input: a whitespace separated list of trees sorted by probability in the
# first field
# output: the 95% credible set
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


my $sum = 0;
my $T = 0.95;
while(<STDIN>) {
	my ($p) = split();
	$sum += $p;
	print;
	if ($sum > $T) {
		last;
	}
}
