#!/bin/bash
################################################################################
# process_mrbayes_posterior.bash
################################################################################
#
# Compute the 95% credible set of Bayesian posterior and prepare for
# further analysis.
# See the README for details.
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

# script location
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# settings
. $SCRIPTPATH/settings.sh

# constants
SPLIT_NEXUS_TREE=$SCRIPTPATH/split_nexus_tree.pl
FIND_UNIQ_BEST_LL=$SCRIPTPATH/find_uniq_best_ll.pl
GET_CRED_SET=$SCRIPTPATH/get_95_credible_set.pl

FIGS=figs

# arguments
dir=$1
tree_file=$2
prob_file=$3

probs_uniq_T=$dir/LL_uniq_trees_T

# temporary files
LL_ALL=`mktemp`
TREES_ALL=`mktemp`
TREES_ONLY_ALL_ORDERED=`mktemp`
UNIQ_TREES=`mktemp`
TREES_ALL_ORDERED=`mktemp`

# get trees
CAT=cat
if [ ${tree_file: -3} == ".gz" ]; then
	CAT="gunzip -c"
fi

$CAT $tree_file | perl $SPLIT_NEXUS_TREE | awk '{print $2,$3}' > $TREES_ALL

$NW_ORDER <(awk '{print $2}' < $TREES_ALL) > $TREES_ONLY_ALL_ORDERED
paste <(awk '{print $1}' < $TREES_ALL) $TREES_ONLY_ALL_ORDERED > $TREES_ALL_ORDERED

CAT=cat
if [ ${prob_file: -3} == ".gz" ]; then
	CAT="gunzip -c"
fi
$CAT $prob_file | grep '^[0-9]' | awk '{print $1,$2}' |
		perl -e '
			while(<>) {
				chomp;
				my ($num, $LL) = split;
				print "$num,";
				printf("%f\n", $LL);
			}
		' > $LL_ALL

# cleanup very large files
rm $TREES_ALL
rm $TREES_ONLY_ALL_ORDERED

# get tree shape changes
paste -d\; <(awk '{print $1}' < $TREES_ALL_ORDERED) <(awk -F, '{print $2}' < $LL_ALL) <(awk '{print $2}' < $TREES_ALL_ORDERED) | perl $FIND_UNIQ_BEST_LL > $UNIQ_TREES

# take the last 75% of the run
num_trees=`cat $TREES_ALL_ORDERED | wc -l`;
threshold_val=`echo "$num_trees * $BURNIN_THRESHOLD" | bc`;
range=`echo "scale=0; ($num_trees - $threshold_val)/1" | bc`;
awk '$2>='$threshold_val < $UNIQ_TREES > $dir/uniq_trees_T
awk '{print $2","$3}' < $dir/uniq_trees_T > $probs_uniq_T
paste -d\; <(awk '{print $1}' < $TREES_ALL_ORDERED) <(awk -F, '{print $2}' < $LL_ALL) <(awk '{print $2}' < $TREES_ALL_ORDERED) | awk -F\; 'BEGIN {OFS=";";} $1>='$threshold_val | sort -t\; -k3,3 | perl $FIND_UNIQ_BEST_LL > $dir/uniq_shapes_T

# get PP
sort -k1,1n $dir/uniq_shapes_T | tac | awk '{$1=($1/'$range'); print}' > $dir/uniq_shapes_T_sorted_by_PP
perl $GET_CRED_SET < $dir/uniq_shapes_T_sorted_by_PP > $dir/uniq_shapes_C_sorted_by_PP

# cleanup large files
rm $TREES_ALL_ORDERED
rm $LL_ALL
