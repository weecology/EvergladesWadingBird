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
            A.OneOf([
            A.RandomSizedBBoxSafeCrop(width=200, height=200),                
            A.RandomSizedBBoxSafeCrop(width=400, height=400),
            A.RandomSizedBBoxSafeCrop(width=300, height=300),
            A.RandomSizedBBoxSafeCrop(width=500, height=500)], p=0.5
            ),
            A.HorizontalFlip(p=0.5),
            A.pytorch.ToTensorV2(),
        ], bbox_params=A.BboxParams(format='pascal_voc',label_fields=["category_ids"]))
        
    else:
        transform = A.Compose([A.pytorch.ToTensorV2()])
        
    return transform
