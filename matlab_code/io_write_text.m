function [Data,N] = io_write_text(formatSpec, data, filename, newFile)
%WFILE Write data to files
    if nargin < 3 || isempty(formatSpec)
        formatSpec = '%s\n';
    end
    if nargin < 4 || isempty(newFile)
        newFile = 0;
    end

    if newFile
        fileID = fopen(filename,'w');
    else
        fileID = fopen(filename, 'a');
    end

    if fileID == -1, error('Cannot open file: %s', filename); end

    fprintf(fileID,formatSpec,data); 
    fclose(fileID);
end