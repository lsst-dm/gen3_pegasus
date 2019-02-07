#!/usr/bin/env python

import logging
import argparse
import sys
import pickle


def read_qgraph(qgraph_filename):
    with open(qgraph_filename, 'rb') as pickleFile:
        qgraph = pickle.load(pickleFile)
    return qgraph


def draw_qgraph(qgraph, outfile):
    logging.info("creating explicit science graph")

    tcnt = 0
    drcnt = 0
    qcnt = 0

    mapId = {}
    jobs = {}
    qgnodes = {}

    with open(outfile, "w") as ofh:
        ofh.write("digraph Q {\n")
        ofh.write('\tedge [color="invis"];\n')
        for taskId, nodes in enumerate(qgraph):
            tcnt += 1
            tnodeName = '.'.join(nodes.taskDef.taskName.split('.')[-2:])

            ofh.write('task%d [shape=none, margin=0, label=<\n' % (tcnt))
            ofh.write('<table border="0" cellborder="1" cellspacing="0" cellpadding="4">\n')
            ofh.write('<TR><TD><b>TD</b></TD><TD colspan="%d">%s</TD></TR>\n' % (len(nodes.quanta), tnodeName))

            # write quantum headers
            ofh.write('<TR><TD><b>Q</b></TD>')
            colcnt = 0
            for qId in range(1, len(nodes.quanta)+1):
                qcnt += 1
                colcnt += 1
                if colcnt % 2 == 0:
                    ofh.write('<TD><b>Q%02d</b></TD>' % qcnt)
                else:
                    ofh.write('<TD BGcolor="lightgrey"><b>Q%02d</b></TD>' % qcnt)
            ofh.write('</TR>\n')

            # write quantum inputs
            ofh.write('<TR><TD><b>IN</b></TD>')
            colcnt = 0
            for qId, quantum in enumerate(nodes.quanta):
                dr_ids = []
                for dsRefs in quantum.predictedInputs.values():
                    for dsRef in dsRefs:
                        dsName = "%s+%s" % (dsRef.datasetType.name, dsRef.dataId)
                        if dsName not in mapId:
                            drcnt += 1
                            mapId[dsName] = drcnt
                        dr_ids.append('dr%03d' % mapId[dsName])
                colcnt += 1
                if colcnt % 2 == 0:
                    ofh.write('<TD>%s</TD>' % ','.join(dr_ids))
                else:
                    ofh.write('<TD BGcolor="lightgrey">%s</TD>' % ', '.join(dr_ids))
            ofh.write("</TR>\n")

            # write quantum outputs
            ofh.write('<TR><TD><b>OUT</b></TD>')
            colcnt = 0
            for qId, quantum in enumerate(nodes.quanta):
                dr_ids = []
                for dsRefs in quantum.outputs.values():
                    for dsRef in dsRefs:
                        dsName = "%s+%s" % (dsRef.datasetType.name, dsRef.dataId)
                        if dsName not in mapId:
                            drcnt += 1
                            mapId[dsName] = drcnt
                        dr_ids.append('dr%03d' % mapId[dsName])
                colcnt += 1
                if colcnt % 2 == 0:
                    ofh.write('<TD>%s</TD>' % ','.join(dr_ids))
                else:
                    ofh.write('<TD BGcolor="lightgrey">%s</TD>' % ', '.join(dr_ids))
            ofh.write("</TR>\n")
            ofh.write('</table>>];\n')

        # add invisible edges so force vertical
        for i in range(1, tcnt):
            ofh.write("task%d -> task%d;" % (i, i+1))
        ofh.write("}\n")

    logging.info("tasks=%d dataset refs=%d", tcnt, drcnt)


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
    required.add_argument("-o", "--output_file", action="store", dest="outfile", required=True,
                          help="Output filename for dot file")
    required.add_argument("--qgraph", action="store", dest="qgraph", required=True,
                          help="Pipeline qgraph pickle file")
    parser.add_argument("-d", "--debug", action="store_true", dest="debug", required=False,
                        help="Set logging to debug level")
    parser.add_argument("-v", "--verbose", action="store_true", dest="verbose", required=False,
                        help="Set logging to info level")
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

    # Read quantum graph
    qGraph = read_qgraph(args.qgraph)

    # Create science graph
    draw_qgraph(qGraph, args.outfile)


if __name__ == "__main__":
    main(sys.argv[1:])
