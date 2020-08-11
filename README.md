# TractographyFormat

## About

This is a simple repository for testing different tractography formats inspired by discussions [here](https://github.com/nipy/nibabel/issues/942).

- example.gltf: [TRAKO glTF container](https://github.com/bostongfx/TRAKO)
- example.vtp: [VTK xml format v0.1](https://vtk.org/wp-content/uploads/2015/04/file-formats.pdf)
- example.vtk, stroke.vtk: [VTK legacy format v4.2](https://vtk.org/wp-content/uploads/2015/04/file-formats.pdf)
- example.tck, stroke.vtk: [MRTrix tracks file format](https://mrtrix.readthedocs.io/en/latest/getting_started/image_data.html#tracks-file-format-tck) created with [tckconvert](https://mrtrix.readthedocs.io/en/latest/reference/commands/tckconvert.html).
= exmaple.trk, stroke.trk: [TrackVis track file](http://trackvis.org/docs/?subsect=fileformat)
- example.vtx, stroke.vtx: Experimental modification of legacy VTK format (see below)

A desirable feature for streamline files is the ability to rapidly read the files, and the ability to randomly access specific streamlines or bundles of streamlines. The conventional storage of tck, and trk all interleave the length of streamlines with the streamline vertices, e.g. an integer reports the number of vertices in this streamline, followed by the vertices for this streamline, followed by the number of vertices in the next streamline. While this allows efficient generation of the streamlines, it has a penalty for file reading and random access, as one must handle the data serialization. 
 On the other hand, the legacy VTK format is traditionally used to store streamlines using the format.
 
```
DATASET POLYDATA 
POINTS n dataType 
p0x p0y p0z
p1x p1y p1z
...
p(n-1)x p(n-1)y p(n-1)z
LINES n size
numPoints0, i0, j0, k0, ... 
numPoints1, i1, j1, k1, ...
...
numPointsn-1, in-1, jn-1, kn-1, ...
```

Note a separate index is stored for each point in a line. This [indexing](http://hacksoflife.blogspot.com/2010/01/to-strip-or-not-to-strip.html) is efficient for triangular meshes where vertices are repeated, but leads to excessively large files for streamlines (where each vertex is unique). Likewise, since reading from disk is typically slow, large files necessarily correspond with slow reads. Further, in theory the order of the vertices in the POINTS array might not correspond to the order they are used in the LINES array, hindering attempts at random access.

The proposed experimental format leverages the fact that the order the vertex positions (points) are saved to disk precisely matches the position in each streamline and the order of the streamlines. The experimental dataset matches the legacy VTK data, but provides a new DATASET type named STREAMLINE:

```
DATASET STREAMLINES 
POINTS n dataType 
p0x p0y p0z
p1x p1y p1z
...
p(n-1)x p(n-1)y p(n-1)z
OFFSETS n dataType
offsetEnd0...
offsetEndn-1
```

The number of OFFSETS corresponds to the number of STREAMLINES. An offset is reported for each streamline, reporting the final point (indexed from 0) included in the line. The first line starts with point 0.  As an example, consider a minimal file:

```
# vtk DataFile Version 2.0
simple example
ASCII
DATASET STREAMLINES
POINTS 6 float 
0.0 0.0 0.0
1.0 0.0 0.0
1.0 1.0 0.0
0.0 1.0 0.0
0.0 0.0 1.0
1.0 0.0 1.0
OFFSETS 2 int 
3
5
```

The first streamline ends at point 3, so it will traverse points [0,1,2,3]. The second streamline ends with point 5, so it traverses vertices [4,5]. In other words, streamline j spans points offsetEnd[j-1]..offsetEnd[j]. The number of points in streamline j is offsetEnd[j]-offsetEnd[j-1]. The number of line segments for each streamline is the number of points in the segment [minus 1](https://en.wikipedia.org/wiki/Off-by-one_error). For all these calculations, when j = 0, remember that offsetEnd[-1] = -1. 

## Matlab Example

The Matlab script test_read() will load each tractography maps. The output should look similar to this:

```
VTX: 163.328ms to read 36763 streamlines stroke.vtx
VTK: 384.054ms to read 36763 streamlines stroke.vtk
TCK: 145.939ms to read 36763 streamlines stroke.tck
TRK: 367.098ms to read 36763 streamlines stroke.trk
```

## Reading TCK files quickly with Python

[NiBabel](https://nipy.org/nibabel/manual.html) can read many file formats (including TCK), and uses its own internal format. However, it tends to be [quite slow](https://github.com/nipy/nibabel/issues/943) at reading large tractography files. In response, members of the [DiPy team](https://github.com/nipy/nibabel/issues/942) have suggested developing and supporting formats that use separate arrays for vertex positions and streamline offsets (e.g. an arrays that track the first/last vertex associated with each streamline). This could provide direct memory mapping to the file on disk. 

A simple way to explore this while leveraging large existing datasets is to generate the streamline offsets for TCK files. This exploits the fact that the TCK format uses three values of the identical datatype for both the vertex position and the end-of-streamline signal. Therefore, the array can be mapped directly from disk as a Nx3 list of vertex positions. This trick would not work with the TCK format, where vertices are stored using three values, but embedded line length only uses a single entry.

To demonstrate this, consider the 869Mb file that [Soichi Hayashi describes as having slow performance with NiBabel](https://github.com/nipy/nibabel/issues/943). This repository includes code for timing TCK loading using NiBabel (read_nibabel.py), Matlab (read_mrtrix_tracks.m) and a Python script that loads the vertices and generates line start/end information (read_mrtrix_tracks.py). These methods were tested on a Ryzen 3900X running Linux with 64Gb of RAM. The Matlab code required 7.7 seconds to load the TCK file.

```
./read_nibabel.py track.tck
track.tck loaded in 33.43 seconds
    
./read_mrtrix_tracks.py track.tck
track.tck loaded in 0.73 seconds
streamlines 675000 vertices (72386074, 3)
first line has 100 vertices X Y Z:
 first [-11.223304 -56.063725 -25.203579]
 final [-26.574024 -41.0987   -30.864029]
```

The Python script stores the vertices, offsets to line starts and offsets to line ends in NumPy arrays, using the approach described by [Tony Yu](https://tonysyu.github.io/ragged-arrays.html#.XzF73i2ZN0J). 

## Related work

In tractography, some streamlines often have fewer vertices than others. This situation is often referred to as "jagged arrays" or "ragged arrays".

- [Tony Yu discussed usage of ragged arrays in Python](https://tonysyu.github.io/ragged-arrays.html#.XzF73i2ZN0J)
- [netCDF provides VLEN Types for ragged arrays](https://www.unidata.ucar.edu/software/netcdf/docs/data_type.html)

