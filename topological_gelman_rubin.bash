#!/bin/bash
################################################################################
# topological_gelman_rubin.bash
################################################################################
#
# Compute the topological Gelman-Rubin statistic for a set of Bayesian
# posteriors
# See the README for details.
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

# script location
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# settings
. $SCRIPTPATH/settings.sh

# arguments
top_dir=$1
top=${2:-1024}
rooting=${3:--unrooted}

shift 3

if [ -z "$top_dir" ]; then
	echo "usage: topological_gelman_rubin.bash <directory> [top_m] [rooted]" 
	exit;
fi

echo "computing spr distance matrix";
head -n$top $top_dir/uniq_shapes_C_numbered | awk '{print $3}' | $RSPR -pairwise $rooting $@ | $FILL_MATRIX > $top_dir/spr_distance_matrix


# compute G-R
ls -d $top_dir/run[0-9]*
ls -d $top_dir/run[0-9]* | perl $SCRIPTPATH/topo_gr.pl $top_dir/uniq_shapes_C_numbered $top_dir/spr_distance_matrix $top


# cleanup large files
#rm $probs_uniq
