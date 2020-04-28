# Utility script to crop a sample image to upload to zooniverse. Files need to be under 1MB.
"""
I've played around with the patch size argument, we want to make the image small, but give enough context for the viewer, so not too small.
"""
import glob
import os
import cv2
from deepforest import preprocess

#Find images
images = glob.glob("/Users/ben/Dropbox/Everglades/imagery/drone/*")

for image_path in images:
    numpy_image = cv2.imread(image_path)    
    
    #Create windows
    
    windows = preprocess.compute_windows(numpy_image, 1000, patch_overlap=0.1)
    
    for index, window in enumerate(windows):
        #Crop and save
        crop = numpy_image[window.indices()]
        filename = "{}_{}.jpg".format(os.path.splitext(image_path)[0],index)
        cv2.imwrite(filename, crop)