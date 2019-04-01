#!/bin/sh

# Before running this, if running against Oracle
# copy DATA/butler.yaml.orig $newconfig
# edit $newconfig making
#   cls: lsst.daf.butler.registries.oracleRegistry.OracleRegistry
#   db: oracle+cx_oracle://@${oracleCred}
#   And whatever other changes are needed, e.g., for templates
#
# copy any of the following that you may want to keep from CI_HSC_DIR:
#     DATA/butler.yaml DATA/gen3.sqlite3 DATA/calib DATA/test


ciVer=git-w.2019.12
ciPath=/work/mgower/ci_hsc/${ciVer}
oracleCred=gen3_cred_mgower_1
newconfig=/work/mgower/gen3work/oracle_trace/myconfig.yaml
xtracol=cmpn_inputs

###################################################################
set -e

cd $ciPath
setup -j -r .
dbutler=`pwd`/DATA

rm -rf DATA/butler.yaml DATA/gen3.sqlite3 DATA/calib DATA/test

makeButlerRepo.py -c $newconfig ${dbutler}
python ${ciPath}/bin/gen3.py
python $DEMO_HSC_PIPELINETASK_DIR/bin/ingestSkyMap.py $dbutler $xtracol
python $DEMO_HSC_PIPELINETASK_DIR/bin/ingestBrightObjectMask.py $dbutler $xtracol
