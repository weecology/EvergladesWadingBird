#Transform augmentations
import albumentations as A
#from albumentations.augmentations.geometric import functional as FGeometric
#from albumentations.augmentations.bbox_utils import union_of_bboxes
import random
import numpy as np
import cv2

## general style
#def get_transform(augment):
    #"""Albumentations transformation of bounding boxs"""
    #if augment:
        #transform = A.Compose([
            #A.HorizontalFlip(p=0.5),
            #ToTensorV2()
        #], bbox_params=A.BboxParams(format='pascal_voc',label_fields=["category_ids"]))
        
    #else:
        #transform = A.Compose([ToTensorV2()])
        
    #return transform

#TODO Make the crop size probabilistic. 

def get_transform(augment):
    """Albumentations transformation of bounding boxs"""
    if augment:
        transform = A.Compose([
            A.RandomSizedBBoxSafeCrop(height=400, width=400, erosion_rate=1),
            A.GaussianBlur(),
            A.Flip(p=0.5),
            A.RandomBrightnessContrast(),
            A.pytorch.ToTensorV2(),
        ], bbox_params=A.BboxParams(format='pascal_voc',label_fields=["category_ids"]))
        
    else:
        transform = A.Compose([A.pytorch.ToTensorV2()])
        
    return transform

#class CropOnNBoxesSafe(A.DualTransform):
    #"""Crop a fixed part of the input and rescale it to some size without loss of all bboxes.
    #Args:
        #height (int): height of crop.
        #width (int): width of crop.
        #n_boxes (int): max number of boxes to mantain. If n > number of total boxes, all boxes are kept.
        #interpolation (OpenCV flag): flag that is used to specify the interpolation algorithm. Should be one of:
            #cv2.INTER_NEAREST, cv2.INTER_LINEAR, cv2.INTER_CUBIC, cv2.INTER_AREA, cv2.INTER_LANCZOS4.
            #Default: cv2.INTER_LINEAR.
        #p (float): probability of applying the transform. Default: 1.
    #Targets:
        #image, mask, bboxes
    #Image types:
        #uint8, float32
    #"""

    #def __init__(self, height, width, n_boxes, erosion_rate=0, interpolation=cv2.INTER_LINEAR, always_apply=False, p=1.0):
        #super(CropOnNBoxesSafe, self).__init__(always_apply, p)
        #self.height = height
        #self.width = width
        #self.erosion_rate = erosion_rate

    #def apply(self, img, crop_height=0, crop_width=0, h_start=0, w_start=0, interpolation=cv2.INTER_LINEAR, **params):
        #crop = F.random_crop(img, crop_height, crop_width, h_start, w_start)
        #return FGeometric.resize(crop, img.shape[0], img.shape[1], interpolation)

    #def get_params_dependent_on_targets(self, params):
        #img_h, img_w = params["image"].shape[:2]
        #if len(params["bboxes"]) == 0:  # less likely, this class is for use with bboxes.
            #return {
                #"h_start": random.random(),
                #"w_start": random.random(),
                #"crop_height": self.height,
                #"crop_width": self.width,
            #}
        ## Choose a random box
        #box_index = np.arange(len(params["bboxes"]))
        #random.shuffle(box_index)        
        #selected_boxes = params["bboxes"][box_index[0]]
        
        #x, y, x2, y2 = union_of_bboxes(
            #width=img_w, height=img_h, bboxes=selected_boxes, erosion_rate=self.erosion_rate
        #)
        ## find bigger region
        #bx, by = x * random.random() + self.width, y * self.height
        #bx2, by2 = x2 + (1 - x2) * self.width, y2 + (1 - y2) * random.random()
        #bw, bh = bx2 - bx, by2 - by
        #crop_height = img_h if bh >= 1.0 else int(img_h * bh)
        #crop_width = img_w if bw >= 1.0 else int(img_w * bw)
        #h_start = np.clip(0.0 if bh >= 1.0 else by / (1.0 - bh), 0.0, 1.0)
        #w_start = np.clip(0.0 if bw >= 1.0 else bx / (1.0 - bw), 0.0, 1.0)
        #return {"h_start": h_start, "w_start": w_start, "crop_height": crop_height, "crop_width": crop_width}

    #def apply_to_bbox(self, bbox, crop_height=0, crop_width=0, h_start=0, w_start=0, rows=0, cols=0, **params):
        #return F.bbox_random_crop(bbox, crop_height, crop_width, h_start, w_start, rows, cols)

    #@property
    #def targets_as_params(self):
        #return ["image", "bboxes"]

    #def get_transform_init_args_names(self):
        #return ("height", "width", "erosion_rate", "interpolation")
