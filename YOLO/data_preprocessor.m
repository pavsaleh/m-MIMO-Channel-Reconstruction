% Taken from https://www.mathworks.com/help/vision/ug/object-detection-using-yolo-v3-deep-learning.html#ObjectDetectionUsingYOLOV3DeepLearningExample-1
function data = preprocessData(data, targetSize)

for ii = 1:size(data,1)
    I = data{ii,1};
    imgSize = size(I);
    
    % Convert an input image with single channel to 3 channels.
    if numel(imgSize) < 3 
        I = repmat(I,1,1,3);
    end
    bboxes = data{ii,2};

    I = im2single(imresize(I,targetSize(1:2)));
    scale = targetSize(1:2)./imgSize(1:2);
    bboxes = bboxresize(bboxes,scale);
    
    data(ii, 1:2) = {I, bboxes};
end
