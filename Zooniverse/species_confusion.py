#Confusion matrix
#srun -p gpu --gpus=1 --mem 20GB --time 5:00:00 --pty -u bash -i
#module load tensorflow/1.14.0
#export PATH=${PATH}:/home/b.weinstein/miniconda3/envs/Zooniverse/bin/
#export PYTHONPATH=${PYTHONPATH}:/home/b.weinstein/miniconda3/envs/Zooniverse/lib/python3.7/site-packages/
#export LD_LIBRARY_PATH=/home/b.weinstein/miniconda3/envs/Zooniverse/lib/:${LD_LIBRARY_PATH}

from deepforest import deepforest
from deepforest import utilities
import pandas as pd
from sklearn.metrics import roc_curve, f1_score

m = deepforest.deepforest(saved_model="/orange/ewhite/everglades/Zooniverse/predictions/20210212_191155/species_model.h5")
truth = pd.read_csv("/orange/ewhite/everglades/Zooniverse/parsed_images/test.csv",names=["image_path","xmin","ymin","xmax","ymax","label"])
m.classes_file = utilities.create_classes("/orange/ewhite/everglades/Zooniverse/parsed_images/test.csv")
m.read_classes()
m.config["save_path"] = "/orange/ewhite/everglades/Zooniverse/tmp/"
mAP = m.evaluate_generator(annotations="/orange/ewhite/everglades/Zooniverse/parsed_images/test.csv", iou_threshold=0.4)
boxes = m.predict_generator(annotations="/orange/ewhite/everglades/Zooniverse/parsed_images/test.csv", iou_threshold=0.4)

results = pd.DataFrame({"truth":truth.label,"predicted":boxes.label})


#15 instances of class Great Blue Heron with average precision: 0.1156
#695 instances of class Great Egret with average precision: 0.6904
#164 instances of class Roseate Spoonbill with average precision: 0.5949
#105 instances of class Snowy Egret with average precision: 0.0693
#3840 instances of class White Ibis with average precision: 0.8148
#56 instances of class Wood Stork with average precision: 0.2261
#mAP using the weighted average of precisions among classes: 0.7647
