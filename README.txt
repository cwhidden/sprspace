################################################################################
sprspace
################################################################################

This is a collection of shell and perl scripts for quantifying MCMC
(Markov chain Monte Carlo) exploration of tree space in MrBayes posteriors.

For more information see:
C. Whidden and F. A. Matsen IV. (2015) Quantifying MCMC Exploration of
Phylogenetic Tree Space. Systematic Biology. First published online: January
27, 2015. doi:10.1093/sysbio/syv006

Copyright 2014 Chris Whidden
cwhidden@fhcrc.org
May 1, 2014
Version 1.0

This file is part of sprspace.

sprspace is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
sprspace is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with sprspace.  If not, see <http://www.gnu.org/licenses/>.

################################################################################
SYNOPSIS
################################################################################

Includes scripts to:

1. Compute the 95% credible set of topologies.

2. Construct graphs of the explored tree space including subtree
   prune-and-regraft (SPR) graphs of topologies and MCMC graphs.
	 SPR graphs connect graph nodes (trees) by an edge if a single
	 SPR move suffices to transform one tree into the other.
	 An SPR operation prunes a subtree and regrafts it at another
	 location. This is the most common type of MCMC move and many other
	 moves (e.g. tree-bisection-and-reconnection, subtree swap) are
	 the equivalent of 2 SPR moves.

3. Compute access time, commute time, and cover time statistics for the
   explored trees. Mean access time is the mean time required for the
	 MCMC search to transition between two trees. Mean commute time is the
	 time required to move between two trees and return to the first. Mean
	 cover time is the time required to sample (cover) each tree in the
	 95% credible set once.

4. Compute the topological SPR Gelman-Rubin convergence criteria to
   determine whether a set of Markov chains have converged on a similar
	 tree space.


################################################################################
REQUIREMENTS
################################################################################

This software is a collection of BASH shell scripts and perl scripts. It
thus requires these environments, which are available on most Linux and
Mac systems. Several basic utilities are assumed including awk, bc,
and gzip. Moreover, these scripts require that the C++ software program rspr
(version 1.3 or later) be installed for SPR computation and the Newick
Utilities to identify identical trees. Constructed graphs can be
visualized with the open source Cytoscape graph visualization program
(or other graph visualization programs).

rspr can be obtained from https://github.com/cwhidden/rspr and requires a
C++ compiler to build.  The Newick Utilities can be obtained from
http://cegg.unige.ch/newick_utils .  Cytoscape can be obtained from
http://www.cytoscape.org/ .


################################################################################
INSTALLATION
################################################################################

1. Extract the files into a common directory.  Several of the scripts call each
   other and they must remain in the same directory.

2. Run "make" in this directory to compile matrix2pairs.cpp as
   matrix2pairs and fill_matrix.cpp as fill_matrix. The makefile assumes the
   g++ compiler is present.

3. Obtain rspr and the Newick Utilities program nw_order (see Requirements,
   above). Enter the location of these two programs in the file settings.sh.

################################################################################
FILES
################################################################################

Main Files:

COPYING
Makefile
mean_access_time.pl
process_graph.sh
process_mrbayes_posterior.bash
process_mrbayes_posteriors.bash
README.txt
settings.sh
topological_gelman_rubin.bash

Internal Scripts:

aggregate_pp.pl
cluster_posterior_by_likelihood_spr.pl
cytoscape_cluster.pl
cytoscape_edge_weights.pl
cytoscape_PP.pl
find_uniq_best_ll.pl
fill_matrix.cpp -> fill_matrix
get_95_credible_set.pl
id_trees.pl
matrix2pairs.cpp -> matrix2pairs
neighbourhood_pp.pl
split_nexus_tree.pl
topo_gr.pl

################################################################################
INSTRUCTIONS
################################################################################

1. Credible Set and Preprocessing

Each analysis begins by computing the 95% credible set of a MrBayes
posterior or set of posteriors. This requires the MrBayes output ".t"
and ".p" files. To save disk space, these can be compressed with gzip (ending
in ".t.gz" and ".p.gz").

a) Single run

To analyze a single MrBayes run, use:
bash process_mrbayes_posterior.bash <directory> <file.t> <file.p>

This will create a set of files in <directory> that can be analyzed with
the other scripts. In particular, the file uniq_shapes_C_sorted_by_PP
contains the 95% credible set of trees, sorted by posterior probability.
Note that the first 25% of sampled trees are ignored as burn in.
The file uniq_trees_T contains all of the MCMC samples but with only one
tree entry for a series of identical topologies in the Markov chain.

Note that the sample usage shown here assumes that all files are in the
current directory and should be amended as necessary (e.g. with the
directory containing process_mrbayes_posterior.bash).
The interpreter (bash or perl) is unnecessary if the scripts
are made executable (chmod +x <scriptname>). Further, if the sprspace
scripts are in your path then they can be invoked without the leading
directory.


b) Multiple runs 

To analyze a set of MrBayes runs from the same MrBayes execution, use:
bash process_mrbayes_posteriors.bash <directory> <run_directory>
This will analyze all of the .t and .p files in <run_directory> with
names containing run1, run2, etc. This script creates a set of files in
<directory> that can be analyzed with other scripts. Each run will be
processed and the results entered in subdirectories run1, run2, etc.
In addition to the previously mentioned files, this script creates files
of the form uniq_shapes_C_numbered which contain the credible set of the
given run (or aggregate runs, in the case of the main directory)
numbered by posterior probability in the aggregate set of runs.


2. SPR Graphs and MCMC Graphs

a) Graph computation

To compute tree space graphs run:
bash process_graph.sh <directory> [top_m] [rooted]
<directory> must contains the results of process_mrbayes_posterior.bash
or process_mrbayes_posteriors.bash .
[top_m] is an optional argument that limits comparison to the top_m trees
with highest posterior probability. This is 1024 by default.
[rooted] can be one of -rooted, -simple_unrooted, or -unrooted. This
indicates whether the input trees are rooted or unrooted.
-simple_unrooted uses an arbitrary rooting based on nw_order that
provides a quick approximation for unrooted trees.  The default value is
-unrooted.

This process requires a large amount of computation and can be very time
consuming. For large posteriors (at least 128 trees in the credible
set), graphs will be constructed for the top 128, top 256, top 512, etc
graphs (increasing powers of 2) until the [top_m] limit is reached or the
full 95% credible set analyzed.

This will create several directories and files in <directory>.
The spr_graphs directory contains the constructed graphs. SPR edge lists
are in comma-separated (CSV) files labelled graph_x.csv and graph.csv, where
x is the number of nodes. The 2 fields are the numbered nodes of
the graph representing two trees separated by a single SPR operation.
These numbers are in posterior probability order from the
"uniq_shapes_C_sorted_by_PP" file.

MCMC transition graphs are in files labelled graph_weighted_x.csv and
graph_weighted.csv . The first 2 fields are the graph nodes, similar to the
SPR graphs. The 3rd field is the number of times that MCMC transition was
observed.

Tree information is contained in the tab-separated files labelled
graph_x_attr.tab and graph_attr.tab . These files contain the tree ID
numbers, tree cluster, RF distance from tree 0 (highest probability
tree), SPR distance from tree 0, posterior probability of the tree, and
the square root of the posterior probability.

Files of the form graph_x_neighbourhood_pp.csv show the cumulative
posterior probability and number of trees at an SPR distance of 0, 1, 2,
etc from tree 0.


b) Graph Visualization

These graphs can be visualized with the open source Cytoscape graph
visualization program. Open an SPR or MCMC graph with the
File->Import->Network->File dialog. Select "Show Text File Import
Options" and then select "Comma" in the Delimiter section. Also, select
"Transfer first line as column names" in the Column Names section.
Now, select the source field as the Source Interaction and target
field as the Target Interaction. For MCMC graphs, also click on the
"weight" field in the Preview section. Finally, press OK to open the graph.

Next, import the tree parameters with the File->Import->Table->File
dialog. Select the appropriate attribute file (same x value).
Again select "Show Text File Import Options" and select "Transfer first
line as column names". If you open multiple graphs in the same Cytoscape
session, ensure that the correct graph is selected in the "Network
Collection" filed. Press OK to import the tree parameters.

Cytoscape contains a number of graph layout algorithms. The
Layout->Prefuse Force Directed Layout is fast and useful. In a force
directed layout, graph nodes are pushed away from one another and edges
act as springs that attempt to maintain a uniform length. For MCMC
graphs, you can use the weight field to bias edge length.

Cytoscape also contains a number of visualization options in the
VizMapper tab. Graph nodes can be colored (e.g. by cluster, distance,
posterior probability) and sized (e.g. by posterior probability). MCMC
edge weights can be visualized with edge thickness or color. For large
graphs you may wish to add transparency to the edges. Many other
options are available. See the Cytoscape manual for more details.


3. Mixing Statistics

To compute mean access time and mean commute time statistics, use:
perl mean_access_time.pl [--num_trees n] [--num_trees_2 n2] [--tree_list l]
< tree_file

Note that all three arguments are optional but at least one of
--num_trees or --tree_list is required.
tree_file must be a uniq_trees_T file of MCMC samples computed in Step 1.
With --tree_list, l is a list of trees to compute mixing statistics between.
For example, this could be a "uniq_shapes_C_sorted_by_PP" file.
Access time statistics will be recorded between the first n trees and
the first n2 trees. A 0 value in either specifies all trees. n2 cannot
be smaller than n unless n2=0. If tree_list is not specified, the trees will be
numbered by their order in tree_file.

A typical usage will be: perl mean_access_time.pl --num_trees 1
--tree_list uniq_shapes_C_sorted_by_PP < uniq_trees_T
This usage computes access time and commute time statistics between tree 0
and each other tree in the 95% credible set.


4. Topological Gelman-Rubin

To compute the topological Gelman-Rubin convergence statistic for a set of
runs, use:
bash topological_gelman_rubin.bash <directory> [top_m] [rooted]

<directory> must contain the results of process_mrbayes_posteriors.bash .
[top_m] is an optional argument that limits comparison to the top_m trees
with highest posterior probability. This is 1024 by default.
[rooted] can be one of -rooted, -simple_unrooted, or -unrooted. This
indicates whether the input trees are rooted or unrooted.
-simple_unrooted uses an arbitrary rooting based on nw_order that
provides a quick approximation for unrooted trees. The default value is
-unrooted.

Subsequent parameters will be passed to rspr. For example, 
bash topological_gelman_rubin.bash my_directory 1024 -unrooted -rf
will use the RF distance rather than the SPR distance.
