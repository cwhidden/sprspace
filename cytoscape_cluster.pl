#!/usr/bin/perl
################################################################################
# cytoscape_cluster.pl
################################################################################
# 
# Create a tab-separated cluster file from a comma-separated cluster file
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

my $i = 0;
print "ID\tcluster\n";
while(<>) {
	my @row = split(",");
	for my $d (@row) {
		print "$i\t$d\n";
		$i++;
	}

}
