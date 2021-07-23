function struct = jsonDecodeFile(jsonFilename)
    arguments
       jsonFilename {mustBeFile}
    end    
    % https://stackoverflow.com/questions/42136291/reading-json-object-in-matlab
    fileId = fopen(jsonFilename, 'r');
    text = fread(fileId, '*char').';
    fclose(fileId);
    struct = jsondecode(text);
end