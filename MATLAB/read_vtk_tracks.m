function [tracks] = read_vtk_tracks(filename)
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
if ~strcmp(str(3:5), 'vtk')
    error('The file is not a valid VTK one.');    
end
% read header
str = fgets(fid); % notes, e.g. "vtk output ImageThreshold=53.0" 
formatStr = fgets(fid); % datatype, "BINARY" or "ASCII" 
if ~strcmpi(formatStr(1:6), 'BINARY')
    error('Only able to read VTK images saved as BINARY.');
end
kindStr = fgets(fid); % kind, e.g. "DATASET POLYDATA" or "DATASET STRUCTURED_ POINTS"
if isempty(strfind(upper(kindStr),'POLYDATA'))
    error('Only able to read VTK images saved as POLYDATA, not %s', kindStr);
end
vertStr = fgets(fid); % number of vertices, e.g. "POINTS 685462 float"
if isempty(strfind(upper(vertStr),'POINTS'))
    error('Expected header to report "POINTS", not %s', vertStr);
end
nvert = sscanf(vertStr,'%*s %d %*s', 1);
% read vertices
cnt = 3*nvert;
vtx = fread(fid, cnt, 'float32=>float32','ieee-be');
% read lines
j = 1;
while ~feof(fid)
    str = fgets(fid); %e.g. "POLYGONS 6 30" 
    if startsWith(str,'LINES','IgnoreCase',true)
       break 
    end
end
if feof(fid)
    error('Only able to read binary VTK files with LINES'); 
end
n_streamlines = sscanf(str,'%*s %d %*s', 1);
n_items = sscanf(str,'%*s %*s %d', 1); 
if (n_items - n_streamlines) ~= nvert
    error('Expected no vertex re-use');
end
asInt = fread(fid, n_items, 'uint32=>uint32', 'ieee-be');
%asFloat = typecast(asInt, 'single');
%numel(asFloat)
tracks.datatype = 'Float32LE';
tracks.count = num2str(n_streamlines);
tracks.total_count = num2str(n_streamlines);
tracks.data = {};
i = 1;
for s = 1:n_streamlines
    nVtx = asInt(i);
    i = i + 1;
    data = zeros(nVtx, 3); 
    for j = 1:nVtx
        data(j,:) = vtx(asInt(i)+1);
        i = i + 1;
    end
    tracks.data{end+1} = data;
end
%end readVtk()
