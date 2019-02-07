HOWTO: Running Gen3 Middleware using Pegasus
============================================

Create your own conda environment
---------------------------------

First and foremost, we are using few extra packages which do not come with the
LSST stack by default.  These are:

#. **networkx**
#. **pygraphviz**
#. **pydotplus**

You cannot install them in the default conda environment due to permission
restrictions.  Probably the easiest way to circumvent these restrictions is to
clone default LSST environment. Executing lines shown below should give you
your own **conda** environment called **demo** and install missing packages.

.. code-block::

   scl enable devtoolset-6 bash
   source /software/lsstsw/stack/loadLSST.bash
   conda create --name demo --clone lsst-scipipe
   conda activate demo
   conda install networkx pydotplus pygraphviz

Of course, you only need to do this once.

Set up Pegasus
--------------

Currently, due to Gen3 Middleware limitations (no subsetting/merging dataset
repositories) Pegasus is configured to run in shared file system mode and only
handles transferring of non-science files (stderr/stedout).

`pegasus.properties`
   Global configuration for Pegasus, should not require any modifications.

`tc.txt`
   Transformation catalog, tells Pegasus where to find **pipetask** -- Gen3
   single-node activator.

   You will need to update the `pfn` to inform Pegasus about the location of
   the **pipetask** version you want to use.

`sites.xml`
   Site catalog.

   If you may want to update locations of the shared scratch and local storage,
   but it is not strictly required.  Also, we are overriding those values while
   calling **pegasus-plan**.


Prepare the Butler
------------------

At the moment, each time you run the script `run_demo.sh`, it copies required
input files from an existing **ci_hsc** dataset repository to the local
directory called `DATA`.

To make the Butler work with your copy you need to update paths `datastore.root` and `registry.db` in the attached Butler configuration file `butler.yaml`.

Again, you only need to do this once. The script `run_demo.sh` will use this
file to overwrite the original one from **ci_hsc**.

Prepare the environment
-----------------------

The script `demo_env.sh` should set up the required environment any time you
start a new shell (just remember to adjust the path to the directory with the
files).

.. code-block::

   scl enable devtoolset-6 bash
   cd ${HOME}/demo/develop
   source demo_env.sh

Allocate compute nodes
----------------------

.. code-block::

   export NODESET="mxknodes"
   allocateNodes.py -n 2 -s 1 -m 00:20:00 -N ${NODESET} -g 1200 -q normal lsstvc

Run demo
--------

The script `run_demo.sh` is the main driver we use to run Gen3 pipelines with
Pegasus. Roughly speaking, it:

#. copies **ci_hcs** repository to the local directory,
#. converts Gen3 Quantum Graph into more convenient representation we
   call Science Graph,
#. creates pickle files with corresponding quanta,
#. makes some figures,
#. calls Pegasus to execute the corresponding workflow.

To execute a portion of **ci_hsc** pipeline using Pegasus, run the
following command:

.. code-block::

  ./run_demo.sh 0 1

First argument is the just run number which you can adjust as you please.
Second determines how big portion of **ci_hsc** pipeline is supposed to be
used. Setting in to 1 will use the minimal For now I would not change it as
lager portion of the pipeline suffers form 

Since `run_demo.sh` makes a fresh copy of **ci_hsc** data every time it runs,
you may need to update the path pointing it to your "master" copy if you are
not happy with using mine.

.. warning::

   Keep in mind though, you cannot use just any **ci_hcs** dataset repository.
   Due to frequent changes in Butler innerworkins, you have to use the version
   which was build with that specific version of Gen3 Middleware you are using.

