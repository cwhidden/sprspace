#!/bin/bash
################################################################################
# process_mrbayes_posteriors.bash
################################################################################
#
# Compute the 95% credible set of a set of Bayesian posteriors and prepare for
# further analysis.
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

# constants
SPLIT_NEXUS_TREE=$SCRIPTPATH/split_nexus_tree.pl
FIND_UNIQ_BEST_LL=$SCRIPTPATH/find_uniq_best_ll.pl
GET_CRED_SET=$SCRIPTPATH/get_95_credible_set.pl

# arguments
out_dir=$1
top_dir=$2

for runs in `(ls $top_dir/*.run*.t*; ls -d $top_dir/run[0-9]*) 2>/dev/null | grep -o 'run[0-9]\+' | sort | uniq`; do
	mkdir -p $out_dir/$runs;
	echo "processing $runs";

	dir=$out_dir/$runs/
	
	if [ -f $top_dir/*.$runs.t.gz ]; then
		tree_file=$top_dir/*.$runs.t.gz
	elif [ -f $top_dir/*.$runs.t ]; then
		tree_file=$top_dir/*.$runs.t
	else
		continue;
	fi
	if [ -f $top_dir/*.$runs.p.gz ]; then
		prob_file=$top_dir/*.$runs.p.gz
	elif [ -f $top_dir/*.$runs.p ]; then
		prob_file=$top_dir/*.$runs.p
	else
		continue;
	fi
	
	probs_uniq_T=$dir/LL_uniq_trees_T
	
	# get trees
	LL_ALL=`mktemp`
	TREES_ALL=`mktemp`
	TREES_ONLY_ALL_ORDERED=`mktemp`
	UNIQ_TREES=`mktemp`
	TREES_ALL_ORDERED=`mktemp`
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
	# cleanup large files
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
	
	# cleanup large files
	rm $TREES_ALL_ORDERED
	rm $LL_ALL
	
	# get PP
	sort -k1,1n $dir/uniq_shapes_T | tac | awk '{$1=($1/'$range'); print}' > $dir/uniq_shapes_T_sorted_by_PP
	perl $GET_CRED_SET < $dir/uniq_shapes_T_sorted_by_PP > $dir/uniq_shapes_C_sorted_by_PP
	
done

# aggregate topologies
echo "aggregating topologies";
num_runs=`ls -d $out_dir/run[0-9]* | wc -l`
CAT=cat
$CAT $out_dir/run*/uniq_shapes_C_sorted_by_PP | sort -k4,4 | perl $SCRIPTPATH/aggregate_pp.pl | awk '{print $1/'$num_runs',$2}' | sort -k1,1g | tac > $out_dir/uniq_shapes_C_sorted_by_PP

# id topologies
ls -d $out_dir/run[0-9]* | perl $SCRIPTPATH/id_trees.pl $out_dir/uniq_shapes_C_sorted_by_PP

cat $out_dir/run*/uniq_trees_T > $out_dir/uniq_trees_T
