#Create a few sample predictions
from deepforest import deepforest

model_path = "/orange/ewhite/everglades/Zooniverse/predictions/20201210_024559.h5"
model = deepforest.deepforest(weights=model_path)
model.config["save_path"] = "/orange/ewhite/everglades/Zooniverse/test_predictions/"
model.evaluate_generator(annotations="/orange/ewhite/everglades/Zooniverse/parsed_images/test.csv", color_annotation = [255,204,0], color_detection = [0,145,255], thickness_annotate = 2, thickness_detect = 2)