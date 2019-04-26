
%{
The purpose of this function is to create an array of feature maps/matrix, 
which are filtered responses to an image. The dimensions of each feature map
is the same as the dimensions original image. They are used to 
create the local spectral histogram. We use gabor filters
%}

function fMaps = featureMaps(I)

wavelength = 5;
orientations = [0, 45, 90, 135];

filters = gabor(wavelength, orientations);
filterCount = size(filters, 2);

[imageRows, imageCols] = size(I);

fMaps = zeros(imageRows, imageCols, filterCount);

for i=1:filterCount
    fMaps(:,:,i) = imgaborfilt(I, filters(i));
end




