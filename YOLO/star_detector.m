should_train = true;
threshold_value = 0.3;
image_size = [256 256 3];
num_classes = 1;
image_filenames = [];
data_paths = {};

if should_train
    % Load the labeled data
    labeled_data = {'imageLabelingSession3.mat', 'imageLabelingSession4.mat', 'imageLabelingSession5.mat'};
    image_folders = {'channel_images3','channel_images4','channel_images5'};
    for data_index = 1:length(labeled_data);
        data = load(labeled_data{data_index}).gTruth;
        
        % Generate the appropriate path names
        [filepath,name,ext] = fileparts(string(data.DataSource.Source));
        image_names = strings(length(name),1);
        for k = 1:length(name)
           image_names(k) = fullfile(pwd, image_folders(data_index), append(name(k), ext(k)));
        end

        image_filenames = [image_filenames; image_names];
        data_paths = [data_paths; data.LabelData.path];
    end

    % Create structured table of data for training
    dataset = table(image_filenames);
    dataset.gTruth = data_paths;
    
    % Split data into training and test sets
    rng(0);
    shuffled_indices = randperm(length(name));
    idx = floor(0.8 * length(shuffled_indices)); % 80% data for training
    train_data_tbl = dataset(shuffled_indices(1:idx), :);
    test_data_tbl = dataset(shuffled_indices(idx+1:end), :);

    % Create image datastores for training and test sets
    trainImageStore = imageDatastore(train_data_tbl.image_filenames);
    testImageStore = imageDatastore(test_data_tbl.image_filenames);

    % Create box label datastores for training and test sets
    trainBoxLabelStore = boxLabelDatastore(train_data_tbl(:, 2:end));
    testBoxLabelStore = boxLabelDatastore(test_data_tbl(:, 2:end));

    % Combine image and label datastores for training and test sets
    combinedTrainData = combine(trainImageStore, trainBoxLabelStore);
    combinedTestData = combine(testImageStore, testBoxLabelStore);

    % Augment and preprocess training data
    augmentedTrainData = transform(combinedTrainData, @data_augmentator);
    preprocessedTrainData = transform(augmentedTrainData, @(data)data_preprocessor(data, image_size));

    % Preprocess test data
    preprocessedTestData = transform(combinedTestData, @(data)data_preprocessor(data, image_size));

    % Estimate anchor boxes for YOLOv2 detector
    rng(0);
    training_data_for_estimation = transform(preprocessedTrainData, @(data)data_preprocessor(data, image_size));
    num_anchors = 6;
    [anchor_boxes, mean_iou] = estimateAnchorBoxes(training_data_for_estimation, num_anchors);
    
    % Create network
    feature_extraction_network = darknet53;
    feature_layer = 'conv33';
    lgraph = yolov2Layers(image_size, num_classes, anchor_boxes, feature_extraction_network, feature_layer);

    options = trainingOptions('sgdm', ...
            'MiniBatchSize', 6, ....
            'InitialLearnRate', 1e-3, ...
            'MaxEpochs', 20, ... 
            'CheckpointPath', tempdir, ...
            'ValidationData', preprocessedTestData, ...
            'Plots', 'training-progress');

    [detector, info] = trainYOLOv2ObjectDetector(preprocessedTrainData, lgraph, options);
end

foldername = 'channel_images1';
file1 = fullfile(foldername, '1.png');
file2 = fullfile(foldername, '2.png');
file3 = fullfile(foldername, '3.png');
file4 = fullfile(foldername, '4.png');
testImages = {file1, file2, file3, file4};

% Detection on test images
for i = 1:length(testImages)
   % Read image
   [img, map] = imread(testImages{i});
   I = cat(3,img,img,img); % Convert to RGB
   I = imresize(I,image_size(1:2));
   
   % Detect objects
   [bboxes,scores] = detect(detector,I,'Threshold', threshold);
   
   % Add annotations to image
   if ~isempty(bboxes) && ~isempty(scores)
       I = insertObjectAnnotation(I,'rectangle',bboxes,scores);
   end
   
   % Display image with annotations
   figure
   imshow(I) 
end

% Evaluate detector on test data
preprocessedTestData = transform(testData,@(data)preprocessData(data,image_size));
detectionResults = detect(detector, preprocessedTestData, 'Threshold', threshold);
[ap,recall,precision] = evaluateDetectionPrecision(detectionResults, preprocessedTestData, threshold);

% Plot Precision-Recall curve
figure
plot(recall,precision)
xlabel('Recall')
ylabel('Precision')
grid on
title(sprintf('Average Precision = %.2f',ap))
