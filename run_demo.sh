#!/bin/sh

set -e

if [ $# -ne 2 ]; then
    echo "Usage: run_demo.sh <run num> <type:1 three coadd steps, 2 full>"
    exit 1;
fi

#set -x

runnum=$1
outdir=run${runnum}

echo ""
echo "Cleaning up previous outputs and resetting repo"
rm -rf input *.pickle *.dot *.gexf *.png *.dax
rm -rf ${outdir}

# Reset butler
[[ -e DATA ]] && rm -rf DATA
cp -r ${HOME}/ci_hsc/w_2019_05/DATA .
chmod -R a+w DATA

# override original repo path with test repo path
cp butler.yaml DATA

mkdir ${outdir}
mkdir ${outdir}/input
mkdir ${outdir}/draw

if [ $2 -eq 2 ]; then
    echo ""
    echo "Running full demo"
else
    echo ""
    echo "Running tiny demo (three coadd steps)"
fi

echo ""
echo "Creating QuantumGraph"
# just to ensure that submit side doesn't write to registry
chmod 444 DATA/gen3.sqlite3

# make QGraph
if [ $2 -eq 2 ]; then
    set -x
    pipetask -b DATA/butler.yaml -i shared/ci_hsc -o qgraph1 qgraph -t multiBand.DetectCoaddSourcesTask -t mergeDetections.MergeDetectionsTask:mdt -c mdt:priorityList="['i', 'r']" -t deblendCoaddSourcesPipeline.DeblendCoaddSourcesSingleTask -t multiBand.MeasureMergedCoaddSourcesTask -q ${outdir}/demo_qgraph.pickle --pipeline-dot ${outdir}/draw/pipetask_pipeline.dot --qgraph-dot ${outdir}/draw/pipetask_qgraph.dot
    { set  +x ;} 2> /dev/null
else
    set -x
    pipetask -b DATA/butler.yaml -i shared/ci_hsc -o qgraph1 qgraph -t multiBand.DetectCoaddSourcesTask -t mergeDetections.MergeDetectionsTask:mdt -c mdt:priorityList="['i', 'r']" -t deblendCoaddSourcesPipeline.DeblendCoaddSourcesSingleTask -q ${outdir}/demo_qgraph.pickle --pipeline-dot ${outdir}/draw/pipetask_pipeline.dot --qgraph-dot ${outdir}/draw/pipetask_qgraph.dot
    { set  +x ;} 2> /dev/null
fi

if [ $? != 0 ]; then
    exit $?
fi

# since shared repo demo, must make writeable again for compute jobs
chmod 644 DATA/gen3.sqlite3

echo ""
echo "Prepare workflow"
set -x
demo_bps.py -b ${HOME}/demo/develop/DATA/butler.yaml -i shared/ci_hsc -o myrun${runnum} --qgraph ${outdir}/demo_qgraph.pickle --outdir ${outdir} --create_schemas --drawdir ${outdir}
{ set  +x ;} 2> /dev/null
if [ $? != 0 ]; then
    exit $?
fi

# make pngs of .dot files and quantum graphs 
echo ""
echo "Make pngs"
draw_qgraph_html.py --qgraph ${outdir}/demo_qgraph.pickle -o $outdir/draw/demo_qgraph.dot
for f in `cd $outdir/input/; ls *.pickle`; do
    draw_qgraph_html.py --qgraph $outdir/input/$f -o $outdir/draw/$f.dot
done
pushd $outdir/draw > /dev/null
for f in `ls *.dot`; do
    dot -Tpng -o $f.png $f
done
popd > /dev/null

cp tc.txt $outdir
cp pegasus.properties $outdir
cp sites.xml $outdir
cd $outdir
if [ -e demo_wf.dax ]; then
    rm demo_rc.txt
    echo ""
    echo "Calling pegasus-plan"
    set -x
    pegasus-plan \
        --verbose \
        --conf pegasus.properties \
        --dax demo_wf.dax \
        --dir submit \
        --cleanup none \
        --sites condorpool \
        --input-dir input \
        --output-dir output 2>&1 | tee pegasus-plan.out
    { set  +x ;} 2> /dev/null
    if [ $? == 0 ]; then
	echo ""
	echo "Submitting run"
	psub=`grep pegasus-run pegasus-plan.out`
	eval "$psub" 2>&1 | tee pegasus-run.out
	if [ $? == 0 ]; then
	    echo ""
	    echo "Sleeping before watching pegasus status"
	    sleep 15
	    pstat=`grep pegasus-status pegasus-run.out`
	    watch $pstat
	fi
    fi
fi
