To use this code, run the following commands:

1. Create a configuration file:
```
	create_config(config_name, image_list, number_pixels, offsets, classes, class_of_interest, original_images, file_prefix, file_ext)
```
where:
  -	config_name is the configuration name
  - image_list refers to a list of training images (a cell array consisting of the full path to each training image)
  - number_pixels is the number of desired superpixels
  - offsets refers to a 1xm matrix that describes which images (above and below) should be included in the training set
  - classes is a cell array of the classes desired
  - class_of_interest is the index of the class of interest (deprecated)
  - original_images is a directory containing all original images
  - file_prefix is the prefix before image counters (e.g., 01CT01 is the prefix to 01CT01######.tif)
  - file_ext is the file extension

2. 
