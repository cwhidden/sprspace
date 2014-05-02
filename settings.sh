RSPR=~/bin/rspr
FILL_MATRIX=~/bin/fill_matrix
NW_ORDER=~/bin/nw_order
BURNIN_THRESHOLD=0.25

# check variables

for var in RSPR FILL_MATRIX NW_ORDER; do

	if [ -z "${!var}" ]; then
		echo "please enter the location of $var in settings.sh; see README for details.";
		exit 1;
	fi
done
