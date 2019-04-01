#!/bin/sh

# run clobber.sql and bootstrap.sh
# assumes gen3_pegasus subdirs in PATH and PYTHONPATH

ciVer=git-w.2019.12
ciPath=/work/mgower/ci_hsc/${ciVer}

set -e

if [ $# -ne 1 ]; then
    echo "Usage: run_full_multi.sh <run num>"
    exit 1;
fi

#set -x

runnum=$1
outdir=peg${runnum}
dinputs=test/peg${runnum}
incol='raw','calib',ref/ps1_pv3_3pi_20170110,cmpn_inputs,${dinputs}
#incol=shared/ci_hsc,${dinputs}
outcol=${dinputs}
dbutler=${ciPath}/DATA

echo ""
echo "Cleaning up previous outputs and resetting repo"
##rm -rf input *.pickle *.dot *.gexf *.png *.dax
rm -rf ${outdir}
rm -rf ${dbutler}/${outcol}

mkdir ${outdir}
mkdir ${outdir}/input
mkdir ${outdir}/draw

echo ""
echo "Creating QuantumGraph"

# If sqlite, just to ensure that submit side doesn't write to registry
#chmod 444 ${ciPath}/DATA/gen3.sqlite3

# make QGraph
set -x
echo $CTRL_MPEXEC_DIR
which pipetask
/usr/bin/time pipetask -d "Patch.patch = 69" -j 8 -b $dbutler/butler.yaml -p lsst.meas.base -p lsst.ip.isr -p lsst.pipe.tasks \
    -i ${incol} -o notused qgraph \
    -t isrTask.IsrTask:isr -C isr:$DEMO_HSC_PIPELINETASK_DIR/config/isr.py \
    -t characterizeImage.CharacterizeImageTask:cit -C cit:$DEMO_HSC_PIPELINETASK_DIR/config/charImage.py \
    -t calibrate.CalibrateTask:ct -C ct:$DEMO_HSC_PIPELINETASK_DIR/config/calibrate.py \
    -t makeCoaddTempExp.MakeWarpTask:mwt -C mwt:$DEMO_HSC_PIPELINETASK_DIR/config/makeWarp.py \
    -t assembleCoadd.CompareWarpAssembleCoaddTask:cwact -C cwact:$DEMO_HSC_PIPELINETASK_DIR/config/compareWarpAssembleCoadd.py \
    -t multiBand.DetectCoaddSourcesTask \
    -t mergeDetections.MergeDetectionsTask:mdt -C mdt:$DEMO_HSC_PIPELINETASK_DIR/config/mergeDetections.py \
    -t deblendCoaddSourcesPipeline.DeblendCoaddSourcesSingleTask \
    -t multiBand.MeasureMergedCoaddSourcesTask:mmcst -C mmcst:$DEMO_HSC_PIPELINETASK_DIR/config/measureMerged.py \
    -t mergeMeasurements.MergeMeasurementsTask:mmt -C mmt:$DEMO_HSC_PIPELINETASK_DIR/config/mergeCoaddMeasurements.py \
    -t forcedPhotCcd.ForcedPhotCcdTask:fpccdt -C fpccdt:$DEMO_HSC_PIPELINETASK_DIR/config/forcedPhotCcd.py \
    -t forcedPhotCoadd.ForcedPhotCoaddTask:fpct -C fpct:$DEMO_HSC_PIPELINETASK_DIR/config/forcedPhotCoadd.py \
    -q ${outdir}/demo_qgraph.pickle \
    --pipeline-dot ${outdir}/draw/pipetask_pipeline.dot --qgraph-dot ${outdir}/draw/pipetask_qgraph.dot 2>&1 | tee ${outdir}/pipetask_qgraph_full.txt

echo "MMG1 " $?
{ set  +x ;} 2> /dev/null

pipetask qgraph -g ${outdir}/demo_qgraph.pickle --show=graph 2>&1 | tee ${outdir}/pipetask_show_fullgraph.txt
pipetask qgraph -g ${outdir}/demo_qgraph.pickle \
    --pipeline-dot ${outdir}/draw/pipetask_pipeline_2.dot \
    --qgraph-dot ${outdir}/draw/pipetask_qgraph_2.dot 2>&1 | tee ${outdir}/pipetask_draw_fullgraph.txt

if [ $? != 0 ]; then
    exit $?
fi

# If sqlite, since shared repo demo, must make writeable again for compute jobs
#chmod 644 ${ciPath}/DATA/gen3.sqlite3

echo ""
echo "Prepare workflow"
set -x
/usr/bin/time demo_bps.py -b $dbutler/butler.yaml -i ${incol} -o ${outcol} --qgraph ${outdir}/demo_qgraph.pickle --outdir ${outdir} --create_schemas
{ set  +x ;} 2> /dev/null
if [ $? != 0 ]; then
    exit $?
fi

# make pngs of .dot files and quantum graphs 
echo ""
echo "Make pngs"
draw_qgraph_html.py --qgraph ${outdir}/demo_qgraph.pickle -o $outdir/draw/demo_qgraph.dot
for f in `cd $outdir/input; ls *.pickle | head -n 1`; do
    draw_qgraph_html.py --qgraph $outdir/input/$f -o $outdir/draw/$f.dot
done
pushd $outdir/draw > /dev/null
for f in `ls *.dot`; do
    dot -Tpng -o $f.png $f
done
popd > /dev/null

# copy sites.xml, tc.txt, acsws02.properties
cp /work/mgower/gen3work/oracle_trace/acsws02/* $outdir
cd $outdir
if [ -e demo_wf.dax ]; then
    rm demo_rc.txt
    echo ""
    echo "Calling pegasus-plan"
    set -x
    pegasus-plan --quiet --conf acsws02.properties --dax demo_wf.dax --dir submit --cleanup none --sites condorpool  --input-dir input --output-dir output 2>&1 | tee pegasus-plan.out
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
