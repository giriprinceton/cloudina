function write_tiff(data,image_name)
    % This function writes a tiff file given some data and an image path
    % Write the file
    to_write = Tiff(image_name,'w');
    % Set some values
    tagstruct.ImageLength = size(data,1);
    tagstruct.ImageWidth = size(data,2);
    tagstruct.Photometric = Tiff.Photometric.RGB;
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Compression = 1;
    tagstruct.BitsPerSample = 16;
    tagstruct.SamplesPerPixel = 3;
    tagstruct.Software = 'MATLAB';
    to_write.setTag(tagstruct);
    to_write.write(data);
    to_write.close();
end