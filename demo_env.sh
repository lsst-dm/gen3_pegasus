# Set up Pegasus WMS.
wmshome="/project/production/pegasus/current"
export PATH="${wmshome}/bin:${PATH}"
export PYTHONPATH="${wmshome}/lib64/python2.7/site-packages"

# Setup pre-requisites (currenty provided by conda).

# Set up LSST stack.
lssthome="/software/lsstsw/stack"
tag="w_2019_07"
source ${lssthome}/loadLSST.bash
conda activate demo
setup lsst_distrib --tag ${tag} --verbose

# Add demo "packages"
export PATH="`pwd`/bin:$PATH"
export PYTHONPATH="`pwd`/python:$PYTHONPATH"
