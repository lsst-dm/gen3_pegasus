#!/bin/sh

ciVer=current
ciPath=/work/mgower/ci_hsc/$ciVer

set -e

if [ $# -ne 1 ]; then
    echo "Usage: run_full_single.sh <run num>"
    exit 1;
fi

#set -x

runnum=$1
dinputs=cmpn_inputs
incol='raw','calib',ref/ps1_pv3_3pi_20170110,${dinputs}
#incol=shared/ci_hsc,${dinputs}
outcol=test/single${runnum}

cd $ciPath
dbutler=`pwd`/DATA

/usr/bin/time pipetask -d "Patch.patch = 69" -j 8 -b DATA/butler.yaml \
-p lsst.meas.base -p lsst.ip.isr -p lsst.pipe.tasks -i $incol -o $outcol run \
--register-dataset-types \
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
-t forcedPhotCoadd.ForcedPhotCoaddTask:fpct -C fpct:$DEMO_HSC_PIPELINETASK_DIR/config/forcedPhotCoadd.py
