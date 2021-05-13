#Transform augmentations
from deepforest import transforms as T
import albumentations as A

## general style
#def get_transform(augment):
    #transforms = []
    #transforms.append(T.ToTensor())
    #if augment:
        #transforms.append(T.RandomHorizontalFlip(0.5))
    #return T.Compose(transforms)

#TODO Make the crop size probabilistic. 

def get_transform(augment):
    """Albumentations transformation of bounding boxs"""
    if augment:
        transform = A.Compose([
            A.RandomCrop(width=450, height=450, p=1),
            A.HorizontalFlip(p=0.5),
            A.RandomBrightnessContrast(p=0.2),
        ], bbox_params=A.BboxParams(format='pascal_voc'))
        
    else:
        transform = A.Compose()
        
    return transform
