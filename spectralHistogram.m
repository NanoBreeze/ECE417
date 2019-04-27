%{
 Compute local spectral histogram from feature maps
 This corresponds with Eqn. 1, which uses the paper Image and Texture Segmentation Using
Local Spectral Histograms
%}
function HW = spectralHistogram(fMaps, windowSize)

[numRows, numCols, numFilters] = size(fMaps);
numBins = 11;

HI = integralHistograms(numBins, numFilters, numRows, numCols, fMaps);
HW = integralToSpectralHistograms(numBins, numFilters, numRows, numCols, windowSize, HI);

numFeatures = size(HW, 1); 

% now that we're done the conversoins,
% convert from three dimensions into two dimensions
HW = reshape(HW, numFeatures, numRows*numCols);



%{
This function corresponds to Eqn. 7 of Image and Texture Segmentation Using
Local Spectral Histograms. We find the integral (cumulative) histogram for
each filtered image, which is partitioned into a fixed set of bins.
The matrix that stores the cumulative histogram has dimensions:

[(# of bins per filtered image) * (number of filtered image), rows, cols]

We can visualize this as layers of 'grids', each grid having the size of the image.
The first dimension represents the number of layers, and each layer
corresponds to a filtered image's histogram bin. 
ie. Layers 1 to numBins correspond to the first filtered image 
(layer 1 is the smallest bin; layer 2 is the second smallest bin, etc., layer numBins 
is the largest bin for the first filtered image.); 
Layers (numBins+1) to (numBins*2) correspond to the second filtered image, etc. 

A coordinate on each layer's 'grid', which has size rows * cols (the second and third
dimensions), stores the cumulative number of pixels discretized into that bin, up
to that coordinate. 

That was a lot of words, here's an example: Let's say coordinate (200, 150)
 of layer 1's grid has a value of 10. This means that for the first filtered 
image, there are 10 pixels from (0,0) to (200, 150) that are discretized into bin 1.

This algorihm is fast because it uses dynamic programming. It iterates
through each filtered image once and updates all the layers corresponding
to a filtered image at once.
%}

function HI = integralHistograms(numBins, numFilters, numRows, numCols, fMaps)

    HI = zeros(numBins * numFilters, numRows, numCols); % HI is the name of the matrix, as defined in Eqn. 6 of the same paper

    for filterIndex = 1:numFilters

       filteredImage = fMaps(:,:,filterIndex);
       maxVal = max(filteredImage(:));
       minVal = min(filteredImage(:));
       binSize = (maxVal-minVal) / numBins;

       bins = (1:numBins) * binSize + minVal;
       bins = bins - binSize / 2; % center each bin

       for rowIndex = 1:numRows % row of HI. The first row and column of HI are 0

           binCountUpdate = zeros(1, numBins);

           for colIndex = 1:numCols

               % find which bin the current pixel should be placed in
               [blah, binIndex] = min(abs(bins - filteredImage(rowIndex, colIndex)));
               binCountUpdate(binIndex) = binCountUpdate(binIndex) + 1;

               if rowIndex == 1 
                    HI(((filterIndex-1) * numBins + 1):(filterIndex * numBins),1, colIndex) = binCountUpdate';

               elseif rowIndex > 1 && colIndex == 1
                   HI(((filterIndex-1) * numBins + binIndex), rowIndex, 1) = HI(((filterIndex-1) * numBins + binIndex), rowIndex-1, 1);

               else % (rowIndex > 1 && colIndex > 1)
                   HI(((filterIndex-1) * numBins + 1):(filterIndex * numBins),rowIndex, colIndex) = ...
                       HI(((filterIndex-1) * numBins + 1):(filterIndex * numBins), rowIndex - 1, colIndex) + binCountUpdate';
               end


           end
       end
    end


function HW = integralToSpectralHistograms(numBins, numFilters, numRows, numCols, windowSize, HI)

HW = zeros(numBins * numFilters, numRows, numCols); % spectral histogram

%{ 
We apply Eqn. 5 and use a max/min trick to compute the cases when the
window cannot entirely fit into the filtered image. We don't have to 
use this trick but it greatly reduces the amount of code to write. 
Inspired from Liu Wang. There might be off-by-one errors but in this case,
they barely affect the final output.
%}
for layerIndex = 1:(numBins * numFilters)
    for rowIndex = 1:numRows
        for colIndex = 1:numCols
            upperLeft = [max(rowIndex-windowSize, 1), max(colIndex-windowSize,1)];
            bottomRight = [min(rowIndex+windowSize, numRows), min(colIndex+windowSize, numCols)];
            activeWindowSize = (bottomRight(1)-upperLeft(1)+1) * (bottomRight(2)-upperLeft(2)+1);
            
            if upperLeft(1) == 1 && upperLeft(2) == 1 % upper left quadrant, doesn't fit
                HW(layerIndex, rowIndex, colIndex) = HI(layerIndex, bottomRight(1), bottomRight(2));
            elseif upperLeft(1) == 1 
                HW(layerIndex, rowIndex, colIndex) = HI(layerIndex, bottomRight(1), bottomRight(2)) - HI(layerIndex, bottomRight(1), upperLeft(2));
            elseif upperLeft(2) == 1 
                HW(layerIndex, rowIndex, colIndex) = HI(layerIndex, bottomRight(1), bottomRight(2)) - HI(layerIndex, upperLeft(1), bottomRight(2));
            else
                HW(layerIndex, rowIndex, colIndex) = ...
                    HI(layerIndex, bottomRight(1), bottomRight(2)) + ...
                    HI(layerIndex, upperLeft(1), upperLeft(2)) - ...
                    HI(layerIndex, bottomRight(1), upperLeft(2)) - ...
                    HI(layerIndex, upperLeft(1), bottomRight(2));
            end
            
            HW(layerIndex, rowIndex, colIndex)= HW(layerIndex, rowIndex, colIndex) / activeWindowSize;
        end
    end
end





