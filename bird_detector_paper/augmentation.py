#Transform augmentations
import albumentations as A

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
            A.CLAHE(),
            A.Cutout(),
            A.GaussianBlur(),
            A.Flip(p=0.5),
            A.RandomBrightnessContrast(),
            A.RandomShadow(),
            A.RGBShift(),
            A.pytorch.ToTensorV2(),
        ], bbox_params=A.BboxParams(format='pascal_voc',label_fields=["category_ids"]))
        
    else:
        transform = A.Compose([A.pytorch.ToTensorV2()])
        
    return transform
