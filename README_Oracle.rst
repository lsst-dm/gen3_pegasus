First read README.rst

Set up your Oracle environment:
* on lsst-dev see instructions on https://confluence.lsstcorp.org/display/DM/Gen3+Milestone+FY2019-2

Before running bootstrap.sh, if running against Oracle
(Need to change these instructions to use multiple configs once tested)

copy DATA/butler.yaml.orig $newconfig
edit $newconfig making
   cls: lsst.daf.butler.registries.oracleRegistry.OracleRegistry
   db: oracle+cx_oracle://@<your_wallet_name>
   And whatever other changes are needed, e.g., for templates

   copy any of the following that you may want to keep from CI_HSC_DIR:
     DATA/butler.yaml DATA/gen3.sqlite3 DATA/calib DATA/test


To run full ci_hsc pipeline:
sqlplus and execute @clobber.sql
bootstrap.sh
run_full_single.sh <run num> (for single-node activator) or run_full_multi.sh <run num> (for multi-node activator)



