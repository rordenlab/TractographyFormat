function test_read

p = fullfile( fileparts(fileparts(mfilename('fullpath'))), 'DATA');
n = 'stroke';
if ~exist(p, 'DIR')
    error('Unable to find %s', p);
end

fnm = fullfile(p, [n, '.vtx']);
if exist(fnm, 'file')
   tic
   tracks = read_vtx_tracks (fnm);
   fprintf('VTX: %.3fms to read %d streamlines %s\n',toc * 1000, numel(tracks.data), fnm)
else
    warning('unable to find %s', fnm);
end

fnm = fullfile(p, [n, '.vtk']);
if exist(fnm, 'file')
   tic
   tracks = read_vtk_tracks (fnm);
   fprintf('VTK: %.3fms to read %d streamlines %s\n',toc * 1000, numel(tracks.data),fnm)
else
    warning('unable to find %s', fnm);
end

fnm = fullfile(p, [n, '.tck']);
if exist(fnm, 'file')
   tic
   tracks = read_mrtrix_tracks (fnm);
   fprintf('TCK: %.3fms to read %d streamlines %s\n',toc * 1000, numel(tracks.data), fnm)
else
    warning('unable to find %s', fnm);
end

fnm = fullfile(p, [n, '.trk']);
if exist(fnm, 'file')
   tic
   [header, data] = read_trk_tracks(fnm);
   fprintf('TRK: %.3fms to read %d streamlines %s\n',toc * 1000, header.n_count, fnm);
else
    warning('unable to find %s', fnm);
end


