#!/usr/bin/env python3

# -*- coding: utf-8 -*-
# emacs: -*- mode: python; py-indent-offset: 4; indent-tabs-mode: nil -*-
# vi: set ft=python sts=4 ts=4 sw=4 et:
import os.path as op
import numpy as np
import time
import os
import sys
import nibabel as nib


if __name__ == '__main__':
    fnm = '../DATA/stroke.tck'
    if len(sys.argv) > 1:
        fnm = sys.argv[1]
    if not os.path.isfile(fnm):
        sys.exit('Unable to find ' + fnm)
    start = time.time()
    nib.streamlines.load(fnm)
    print('{} loaded in {:.2f} seconds'.format(fnm, time.time()-start))

