#Transform augmentations
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
            A.OneOf(
            A.RandomCrop(width=100, height=100, p=0.1),
            A.RandomCrop(width=300, height=300, p=0.1),
            A.RandomCrop(width=500, height=500, p=0.1)
            ),
            A.HorizontalFlip(p=0.5),
            A.RandomBrightnessContrast(p=0.2),
        ], bbox_params=A.BboxParams(format='pascal_voc',label_fields=["category_ids"]))
        
    else:
        transform = A.Compose()
        
    return transform
