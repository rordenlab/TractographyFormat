#!/usr/bin/env python3

# -*- coding: utf-8 -*-
# emacs: -*- mode: python; py-indent-offset: 4; indent-tabs-mode: nil -*-
# vi: set ft=python sts=4 ts=4 sw=4 et:
import os.path as op
import numpy as np
import time
import os
import sys



#from nipype/interfaces/mrtrix/convert.py
def read_mrtrix_header(in_file):
    fileobj = open(in_file, "rb")
    header = {}
    #iflogger.info("Reading header data...")
    for line in fileobj:
        line = line.decode()
        if line == "END\n":
            #iflogger.info("Reached the end of the header!")
            break
        elif ": " in line:
            line = line.replace("\n", "")
            line = line.replace("'", "")
            key = line.split(": ")[0]
            value = line.split(": ")[1]
            header[key] = value
            #iflogger.info('...adding "%s" to header for key "%s"', value, key)
    fileobj.close()
    header["count"] = int(header["count"].replace("\n", ""))
    header["offset"] = int(header["file"].replace(".", ""))
    return header

def read_mrtrix_streamlines(in_file, header):
    byte_offset = header["offset"]
    stream_count = header["count"]
    datatype = header["datatype"]
    dt = 4
    if datatype.startswith( 'Float64' ):
        dt = 8
    elif not datatype.startswith( 'Float32' ):
        print('Unsupported datatype: ' + datatype)
        return
    #tck format stores three floats (x/y/z) for each vertex
    num_triplets = (os.path.getsize(in_file) - byte_offset) // (dt * 3)
    dt = 'f' + str(dt)
    if datatype.endswith( 'LE' ):
        dt = '<'+dt    
    if datatype.endswith( 'BE' ):
        dt = '>'+dt
    vtx = np.fromfile(in_file, dtype=dt, count=(num_triplets*3), offset=byte_offset)
    vtx = np.reshape(vtx, (-1,3)) 
    #make sure last streamline delimited...
    if not np.isnan(vtx[-2,1]):
        vtx[-1,:] = np.nan
    line_ends, = np.where(np.all(np.isnan(vtx), axis=1));
    if stream_count != line_ends.size:
        print('expected {} streamlines, found {}'.format(stream_count, vtx_nans.size))
    line_starts = line_ends + 0
    line_starts[1:line_ends.size] = line_ends[0:line_ends.size-1]
    #the first line starts with the first vertex (index 0), so preceding NaN at -1
    line_starts[0] = -1;
    #first vertex of line is the one after a NaN
    line_starts = line_starts + 1
    #last vertex of line is the one before NaN
    line_ends = line_ends - 1
    return vtx, line_starts, line_ends


def read_mrtrix_tracks(in_file):
    header = read_mrtrix_header(in_file)
    vertices, line_starts, line_ends = read_mrtrix_streamlines(in_file, header)
    return header, vertices, line_starts, line_ends

if __name__ == '__main__':
    fnm = 'example.tck'
    if len(sys.argv) > 1:
        fnm = sys.argv[1]
    if not os.path.isfile(fnm):
        sys.exit('Unable to find ' + fnm)
    start = time.time()
    header, vertices, line_starts, line_ends = read_mrtrix_tracks(fnm)
    print('{} loaded in {:.2f} seconds'.format(fnm, time.time()-start))
    print('streamlines {} vertices {}'.format(line_ends.size, vertices.shape))
    print('first line has {} vertices X Y Z:'.format(line_ends[0]-line_starts[0]+1))
    print(' first {}'.format(vertices[line_starts[0],:])) 
    print(' final {}'.format(vertices[line_ends[0],:]))
    
