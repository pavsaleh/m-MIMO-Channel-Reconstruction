# m-MIMO-Channel-Reconstruction

## Abstract
This report details the author’s term project focused on addressing the issue of reducing feedback and overhead for channel reconstruction in 5G wireless research. The project implemented advanced techniques for channel reconstruction and explored new methods to improve accu- racy and decrease run time. The project included the implementation of two existing methods: a regression-based approach using the Least Absolute Shrinkage and Selection Operator (LASSO) algorithm, and a deep learning image processing algorithm called You Only Look Once (YOLO) that transformed the received pilots into an image to extract path information. Additionally, a new method was developed using autokeras to build and train a Deep Neural Network (DNN) to predict path information directly from channel images.

## LASSO
This involves using LASSO as a regression method for channel reconstruction of sparse channels. As anticipated, increasing the number of pilot symbols in the reference signal reduces the error in the estimated channel vector at an exponential rate, thus confirming the belief that the accuracy of the channel vector is directly proportional to the number of pilot symbols used in downlink channel recon- struction.

## Image Generation
The bright spots in the image correspond to paths, and their positions are determined by the antenna steering vector and the delay-related phase vector. Varying degrees of SNR affect the image, resulting in noise appearing as static. As the SNR decreases, static in the points becomes less recognizable from the static in the background. Using advanced image detection techniques like YOLO can help identify points in images with high noise.

## YOLO
After generating the channel images using the received channel measure- ments, the spots within the images must be detected and the bounds set to represent the channel paths back in the delay and angular domain for chan- nel reconstruction. To achieve this, YOLO, a fast object detection model, is utilized to extract the bounding boxes of the spots in the images. To train the object detection model, labeled data comprising a training, validation, and test set of images must be generated. Once the YOLO object detection model is trained with labeled data, test- ing data can be used to predict the average precision and generate Precision- Recall Curve plots to evaluate the precision and recall of the detector. The Precision-Recall Curve can then be used to adjust the threshold of the detector.

## DNN
A deep neural network was used to directly predict the path gains and delays from the generated images, without going through the object detection, coordinate translation, and path calculations. This approach was an image regression model that attempted to predict the path components by extracting the path information encoded in the image. Deep neural networks (DNNs) have the potential to improve image-based path recognition from received pilots.
