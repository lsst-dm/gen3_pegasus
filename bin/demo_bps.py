#!/usr/bin/env python

import logging
import argparse
import os
import sys
import re
import pickle

from bps_draw import draw_networkx_dot
from bps_funcs import create_science_graph, create_workflow_graph, create_all_schemas
from daxgen import Daxgen

def read_qgraph(qgraph_filename):
    with open(qgraph_filename, 'rb') as pickleFile:
        qgraph = pickle.load(pickleFile)
    return qgraph

def parse_args(argv=None):
    """Parse command line, and test for required arguments

    Parameters
    ----------
    argv : `list`
        List of strings containing the command-line arguments.

    Returns
    -------
    args : `Namespace`
        Command-line arguments converted into an object with attributes.
    """
    if argv is None:
        argv = sys.argv[1:]
    parser = argparse.ArgumentParser()
    required = parser.add_argument_group('required arguments')
    required.add_argument("-b", "--butler", action="store", dest="butler", required=True,
                          help="Butler yaml file location")
    required.add_argument("-i", "--input_collection", action="store", dest="incol", required=True,
                          help="Butler input collection name")
    required.add_argument("-o", "--output_collection", action="store", dest="outcol", required=True,
                          help="Butler output collection name")
    required.add_argument("--qgraph", action="store", dest="qgraph", required=True,
                          help="Pipeline qgraph pickle file")
    parser.add_argument("-x", "--activator", action="store", dest="activator", required=False,
                        help="Activator executable name (no path)",
                        default="pipetask")
    parser.add_argument("-a", "--actargs", action="store", type=str, dest="actargs", required=False,
                        help="Activator args with special keys as {key}",
                        default="-b {butler} -i {incol} -o {outcol} run --skip-init-writes --qgraph {qlfn}")
    parser.add_argument("--outdir", action="store", dest="outdir", required=False,
                        help="output directory for internal files", default=".")
    parser.add_argument("--drawdir", action="store", dest="drawdir", required=False,
                        help="output directory for dot files", default=None)
    parser.add_argument("--dryrun", action="store_true", dest="dryrun", required=False,
                        help="If set, creates all files, but does not actually submit")
    parser.add_argument("-d", "--debug", action="store_true", dest="debug", required=False,
                        help="Set logging to debug level")
    parser.add_argument("-v", "--verbose", action="store_true", dest="verbose", required=False,
                        help="Set logging to info level")
    parser.add_argument('--dax', type=str, default='demo_wf.dax', required=False,
                        help='DAX filename (will be saved in outdir)')
    parser.add_argument('-c', '--catalog', type=str, default='demo_rc.txt', required=False,
                        help='Replica catalog (will be saved in outdir)')
    parser.add_argument("--create_schemas", action="store_true", dest="create_schemas", required=False,
                        help="If set, creates schema files")
    parser.add_argument('--schema_args', action="store", dest="schargs", type=str, required=False,
                        help='Command line to create schemas with special keys as {key}',
                        default="pipetask -b {butler} -i {incol} -o {outcol} run --init-only --qgraph {qlfn}")
    return parser.parse_args(argv)


def main(argv):
    """Program entry point.  Control process that iterates over each file

    Parameters
    ----------
    argv : `list`
        List of strings containing command line arguments.
    """
    args = parse_args(sys.argv[1:])

    # set up logging
    logging.basicConfig(format="%(levelname)s::%(asctime)s::%(message)s", datefmt="%m/%d/%Y %H:%M:%S")
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
    elif args.verbose:
        logging.getLogger().setLevel(logging.INFO)

    # Get basename of input QuantumGraph to use in output filenames
    basename = os.path.basename(os.path.splitext(args.qgraph)[0])

    # Read quantum graph
    qGraph = read_qgraph(args.qgraph)

    # Create science graph
    demoGraph, qgnodes = create_science_graph(qGraph)
    if args.drawdir is not None:
        draw_networkx_dot(demoGraph, os.path.join(args.drawdir, 'draw', "%s_sci.dot" % basename))


    # Fill in variables for activator command line from args
    #   qlfn is filled in on a per activator basis later
    args.actargs = args.actargs.format(**vars(args),qlfn='{qlfn}')
    logging.info("actargs = '%s'", args.actargs)

    # Create workflow graph
    create_workflow_graph(args, demoGraph, qgnodes)
    with open(os.path.join(args.outdir, "%s_wf.pickle" % basename), "wb") as pickleFile:
        pickle.dump(demoGraph, pickleFile)
    if args.drawdir is not None:
        draw_networkx_dot(demoGraph, os.path.join(args.drawdir, 'draw', "%s_wf.dot" % basename))

    # create schemas
    if args.create_schemas:
        create_all_schemas(args, demoGraph, qgnodes)

    # Create Pegasus DAX and replica catalog
    gen = Daxgen(graph=demoGraph)
    gen.write_dax(os.path.join(args.outdir, args.dax))
    gen.write_rc(os.path.join(args.outdir, args.catalog))

if __name__ == "__main__":
    main(sys.argv[1:])
