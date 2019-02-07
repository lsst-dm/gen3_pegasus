#!/usr/bin/env python

import argparse
from daxgen import Daxgen


def create_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('filename', type=str,
                        help='Serialized graph')
    parser.add_argument('-o', '--output', type=str, default='wf.dax',
                        help='DAX file')
    parser.add_argument('-c', '--catalog', type=str, default='rc.txt',
                        help='Replica catalog')
    return parser


if __name__ == '__main__':
    parser = create_parser()
    args = parser.parse_args()

    gen = Daxgen()
    gen.read(args.filename)

    gen.write_dax(args.output)
    gen.write_rc(args.catalog)
