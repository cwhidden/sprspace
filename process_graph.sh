#!/bin/bash
################################################################################
# process_graph.sh
################################################################################
#
# Construct SPR and MCMC graphs of a Bayesian posterior tree space.
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

# min graph size constructed with iterative deepening
MIN_GRAPH_SIZE=128

dir=$1

# max graph size constructed
MAX_GRAPH_SIZE=${2:-1024}

ROOTED=${3:--unrooted}

# script location
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# settings
. $SCRIPTPATH/settings.sh

fig_dir=$dir/figs
graph_dir=$dir/spr_graphs
cluster_dir=$dir/clusters
distance_dir=$dir/distances

LL_uniq=$dir/LL_uniq_trees_T

mkdir -p $graph_dir
mkdir -p $cluster_dir
mkdir -p $distance_dir

# PP values
awk '{print 0","$1}' < $dir/uniq_shapes_C_sorted_by_PP |
		perl $SCRIPTPATH/cytoscape_PP.pl > $graph_dir/graph_pp.tab

end=`cat $dir/uniq_shapes_C_sorted_by_PP | wc -l`
size=$MIN_GRAPH_SIZE
while [ "$size" -lt "$end" ]; do
	echo $size

	if [ $size -gt $MAX_GRAPH_SIZE ]; then
		exit;
	fi	

size_plus_one=$(($size+1))

	# clusters
	cluster_file=$cluster_dir/clusters_shapes_${size}_spr_sorted_by_PP_auto.csv
	head -$size < $dir/uniq_shapes_C_sorted_by_PP |
			grep -o '(.*' |
			perl $SCRIPTPATH/cluster_posterior_by_likelihood_spr.pl > $cluster_file
	perl $SCRIPTPATH/cytoscape_cluster.pl < $cluster_file > $graph_dir/graph_${size}_color.tab

	# distances from peak
	head -$size < $dir/uniq_shapes_C_sorted_by_PP |
			$RSPR -rf $ROOTED -pairwise 0 1 > $distance_dir/rf_distances_${size}_PP_1_shape.csv
	perl $SCRIPTPATH/cytoscape_cluster.pl < $distance_dir/rf_distances_${size}_PP_1_shape.csv > $graph_dir/graph_${size}_dist_rf.tab
	sed -i 's/cluster/dist_rf/' $graph_dir/graph_${size}_dist_rf.tab
	head -$size < $dir/uniq_shapes_C_sorted_by_PP |
			$RSPR $ROOTED -pairwise 0 1 > $distance_dir/spr_distances_${size}_PP_1_shape.csv
	perl $SCRIPTPATH/cytoscape_cluster.pl < $distance_dir/spr_distances_${size}_PP_1_shape.csv > $graph_dir/graph_${size}_dist_spr.tab
	sed -i 's/cluster/dist_spr/' $graph_dir/graph_${size}_dist_spr.tab

	# attribute file
	paste -d"\t" $graph_dir/graph_${size}_color.tab <(awk '{print $2}' < $graph_dir/graph_${size}_dist_rf.tab) <(awk '{print $2}' < $graph_dir/graph_${size}_dist_spr.tab) <(awk '{print $2"\t"$3}' < $graph_dir/graph_pp.tab | head -$size_plus_one) |
			awk 'NF>=4' > $graph_dir/graph_${size}_attr.tab

	# peak 1 neighbourhood size
	echo "dist,PP,size" > $graph_dir/graph_${size}_neighbourhood_pp.csv
	paste $graph_dir/graph_pp.tab $graph_dir/graph_${size}_dist_spr.tab |
			head -$size |
			awk '{print $1,$2,$5}' |
			tr " " "," |
			sed '1d' |
			perl $SCRIPTPATH/neighbourhood_pp.pl \
			>> $graph_dir/graph_${size}_neighbourhood_pp.csv

	# weighted MCMC graph
	if [ -f $dir/uniq_trees_T ]; then
		echo "source,target,weight" > $graph_dir/graph_${size}_weighted.csv
		cat $dir/uniq_trees_T | awk '{print $4}' | perl $SCRIPTPATH/cytoscape_edge_weights.pl <(grep -o '(.*' $dir/uniq_shapes_C_sorted_by_PP | head -$size) | grep -v '^0,,' >> $graph_dir/graph_${size}_weighted.csv
	fi

	# SPR graph
	grep -o '(.*' < $dir/uniq_shapes_C_sorted_by_PP |
			head -$size |
			$RSPR $ROOTED -pairwise_max 1 -fpt -q |
			$SCRIPTPATH/matrix2pairs 1 |
			sed "s/\t/,/g" > $graph_dir/graph_${size}.csv
	
	size=$(($size * 2))
done

# clusters
cluster_file=$cluster_dir/clusters_shapes_spr_sorted_by_PP_auto.csv
cat $dir/uniq_shapes_C_sorted_by_PP |
		grep -o '(.*' | 
		perl $SCRIPTPATH/cluster_posterior_by_likelihood_spr.pl > $cluster_file
perl $SCRIPTPATH/cytoscape_cluster.pl < $cluster_file > $graph_dir/graph_color.tab

# distances from peak
cat $dir/uniq_shapes_C_sorted_by_PP |
		$RSPR -rf $ROOTED -pairwise 0 1 > $distance_dir/rf_distances_PP_1_shape.csv
perl $SCRIPTPATH/cytoscape_cluster.pl < $distance_dir/rf_distances_PP_1_shape.csv > $graph_dir/graph_dist_rf.tab
sed -i 's/cluster/dist_rf/' $graph_dir/graph_dist_rf.tab
cat $dir/uniq_shapes_C_sorted_by_PP |
		$RSPR $ROOTED -pairwise 0 1 > $distance_dir/spr_distances_PP_1_shape.csv
perl $SCRIPTPATH/cytoscape_cluster.pl < $distance_dir/spr_distances_PP_1_shape.csv > $graph_dir/graph_dist_spr.tab
sed -i 's/cluster/dist_spr/' $graph_dir/graph_dist_spr.tab

# attribute file
paste -d"\t" $graph_dir/graph_color.tab <(awk '{print $2}' < $graph_dir/graph_dist_rf.tab) <(awk '{print $2}' < $graph_dir/graph_dist_spr.tab) <(awk '{print $2"\t"$3}' < $graph_dir/graph_pp.tab ) |
		awk 'NF>=4' > $graph_dir/graph_attr.tab

# peak 1 neighbourhood size
echo "dist,PP,size" > $graph_dir/graph_neighbourhood_pp.csv
paste $graph_dir/graph_pp.tab $graph_dir/graph_dist_spr.tab |
		awk '{print $1,$2,$5}' |
		tr " " "," |
		sed '1d' |
		perl $SCRIPTPATH/neighbourhood_pp.pl \
		>> $graph_dir/graph_neighbourhood_pp.csv

# weighted MCMC graph
if [ -f $dir/uniq_trees_T ]; then
	echo "source,target,weight" > $graph_dir/graph_weighted.csv
	cat $dir/uniq_trees_T | awk '{print $4}' | perl $SCRIPTPATH/cytoscape_edge_weights.pl <(grep -o '(.*' $dir/uniq_shapes_C_sorted_by_PP ) | grep -v '^0,,' >> $graph_dir/graph_weighted.csv
fi

# SPR graph
grep -o '(.*' < $dir/uniq_shapes_C_sorted_by_PP |
		$RSPR $ROOTED -q -pairwise_max 1 |
		$SCRIPTPATH/matrix2pairs 1 |
		sed "s/\t/,/g" > $graph_dir/graph.csv
