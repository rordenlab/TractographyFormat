function [tracks] = read_vtx_tracks(filename)
%  [tracks] = read_vtk_tracks(filename);
%   mimics tracks structure of read_mrtrix_tracks()
% adapts code from Mario Richtsfeld to support vtk "LINES"
%   Copyright (c) Mario Richtsfeld, distributed under BSD license
% http://www.mathworks.com/matlabcentral/fileexchange/5355-toolbox-graph/content/toolbox_graph/read_vtk.m
% http://www.ifb.ethz.ch/education/statisticalphysics/file-formats.pdf
% ftp://ftp.tuwien.ac.at/visual/vtk/www/FileFormats.pdf
%The VTK format supports a wide range of datasets, Chris Rorden modified
% this version to read some binary images and provide sensible error reporting 
% for unsupported variants of the VTK format
% --- read VTK format lines
fid = fopen(filename,'r');
if( fid==-1 )
    error('Can''t open the VTK file %s',filename);
end
str = fgets(fid);   % -1 if eof, signature, e.g. "# vtk DataFile Version 3.0"
if ~strcmp(str(3:5), 'vtx')
    error('The file is not a valid VTK one.');    
end
% read header
str = fgets(fid); % notes, e.g. "vtk output ImageThreshold=53.0" 
formatStr = fgets(fid); % datatype, "BINARY" or "ASCII" 
if ~strcmpi(formatStr(1:6), 'BINARY')
    error('Only able to read VTK images saved as BINARY.');
end
kindStr = fgets(fid); % kind, e.g. "DATASET POLYDATA" or "DATASET STRUCTURED_ POINTS"
if isempty(strfind(upper(kindStr),'STREAMLINES'))
    error('Only able to read VTK images saved as STREAMLINES, not %s', kindStr);
end
vertStr = fgets(fid); % number of vertices, e.g. "POINTS 685462 float"
if isempty(strfind(upper(vertStr),'POINTS'))
    error('Expected header to report "POINTS", not %s', vertStr);
end
nvert = sscanf(vertStr,'%*s %d %*s', 1);
% read vertices
cnt = 3*nvert;
vtx = fread(fid, cnt, 'float32=>float32','ieee-be');
vtx = reshape(vtx, 3, nvert)';
% read lines
j = 1;
while ~feof(fid)
    str = fgets(fid); %e.g. "POLYGONS 6 30" 
    if startsWith(str,'OFFSETS','IgnoreCase',true)
       break 
    end
end
if feof(fid)
    error('Only able to read binary VTK files with OFFSETS'); 
end
n_streamlines = sscanf(str,'%*s %d %*s', 1);
datatype = sscanf(str,'%*s %*s %s', 1);
if ~startsWith(datatype,'long')
    error('Only long OFFSETS currently supported');
end
offsets = fread(fid, n_streamlines, 'uint32=>uint32', 'ieee-be');
tracks.datatype = 'Float32LE';
tracks.count = num2str(n_streamlines);
tracks.total_count = num2str(n_streamlines);
tracks.data = {};
lineStart = 1; %Matlab arrays start 1
for s = 1:n_streamlines
    lineEnd = offsets(s) + 1; %+1 as Matlab arrays indexed from 1
    tracks.data{end+1} = vtx(lineStart:lineEnd,:);
    lineStart = lineEnd;
end
%end readVtk()
