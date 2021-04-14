#DeepForest bird detection from extracted Zooniverse predictions
import comet_ml
from pytorch_lightning.loggers import CometLogger
from deepforest.callbacks import images_callback
from deepforest import visualize
from deepforest import main
import traceback
import geopandas as gp
from shapely.geometry import Point, box
import pandas as pd
import rasterio
import os
import numpy as np
import glob
import torch
from datetime import datetime

#Define shapefile utility
def shapefile_to_annotations(shapefile, rgb_path, savedir="."):
    """
    Convert a shapefile of annotations into annotations csv file for DeepForest training and evaluation
    Args:
        shapefile: Path to a shapefile on disk. If a label column is present, it will be used, else all labels are assumed to be "Tree"
        rgb_path: Path to the RGB image on disk
        savedir: Directory to save csv files
    Returns:
        None: a csv file is written
    """
    #Read shapefile
    gdf = gp.read_file(shapefile)
    
    #Drop any rounding errors duplicated
    gdf = gdf.groupby("selected_i").apply(lambda x: x.head(1))
    
    #define in image coordinates and buffer to create a box
    gdf["geometry"] =[Point(x,y) for x,y in zip(gdf.x.astype(float), gdf.y.astype(float))]
    gdf["geometry"] = [box(int(left), int(bottom), int(right), int(top)) for left, bottom, right, top in gdf.geometry.buffer(25).bounds.values]
        
    #extent bounds
    df = gdf.bounds
    
    #Assert size mantained
    assert df.shape[0] == gdf.shape[0]
    
    df = df.rename(columns={"minx":"xmin","miny":"ymin","maxx":"xmax","maxy":"ymax"})
    
    #cut off on borders
    try:
        with rasterio.open(rgb_path) as src:
            height, width = src.shape
    except:
        print("Image {} failed to open".format(rgb_path))
        os.remove(rgb_path)
        return None
    
    df.ymax[df.ymax > height] = height
    df.xmax[df.xmax > width] = width
    df.ymin[df.ymin < 0] = 0
    df.xmin[df.xmin < 0] = 0
    
    #add filename and bird labels
    df["image_path"] = os.path.basename(rgb_path)
    df["label"] = "Bird"
    
    #enforce pixel rounding
    df.xmin = df.xmin.astype(int)
    df.ymin = df.ymin.astype(int)
    df.xmax = df.xmax.astype(int)
    df.ymax = df.ymax.astype(int)
    
    #select columns
    result = df[["image_path","xmin","ymin","xmax","ymax","label"]]
     
    result = result.drop_duplicates()
    
    return result

def find_rgb_path(shp_path, image_dir):
    basename = os.path.splitext(os.path.basename(shp_path))[0]
    rgb_path = "{}/{}.png".format(image_dir,basename)
    return rgb_path
    
def format_shapefiles(shp_dir,image_dir=None):
    """
    Format the shapefiles from extract.py into a list of annotations compliant with DeepForest -> [image_name, xmin,ymin,xmax,ymax,label]
    shp_dir: directory of shapefiles
    image_dir: directory of images. If not specified, set as shp_dir
    """
    if not image_dir:
        image_dir = shp_dir
        
    shapefiles = glob.glob(os.path.join(shp_dir,"*.shp"))
    
    #Assert all are unique
    assert len(shapefiles) == len(np.unique(shapefiles))
    
    annotations = [ ]
    for shapefile in shapefiles:
        rgb_path = find_rgb_path(shapefile, image_dir)
        result = shapefile_to_annotations(shapefile, rgb_path)
        #skip invalid files
        if result is None:
            continue
        annotations.append(result)
    annotations = pd.concat(annotations)
    
    return annotations

def split_test_train(annotations):
    """Split annotation in train and test by image"""
    #Currently want to mantain the random split
    np.random.seed(0)
        
    #add to train_names until reach target split threshold
    image_names = annotations.image_path.unique()
    target = int(annotations.shape[0] * 0.9)
    counter = 0
    train_names = []
    for x in image_names:
        if target > counter:
            train_names.append(x)
            counter+=annotations[annotations.image_path == x].shape[0]
        else:
            break
        
    train = annotations[annotations.image_path.isin(train_names)]
    test = annotations[~(annotations.image_path.isin(train_names))]
    
    return train, test
    
def is_empty(precision_curve, threshold):
    precision_curve.score = precision_curve.score.astype(float)
    precision_curve = precision_curve[precision_curve.score > threshold]
    
    return precision_curve.empty

def empty_image(precision_curve, threshold):
    empty_true_positives = 0
    empty_false_negatives = 0
    for name, group in precision_curve.groupby('image'): 
        if is_empty(group, threshold):
            empty_true_positives +=1
        else:
            empty_false_negatives+=1
    empty_recall = empty_true_positives/float(empty_true_positives + empty_false_negatives)
    
    return empty_recall

def plot_recall_curve(precision_curve, invert=False):
    """Plot recall at fixed interval 0:1"""
    recalls = {}
    for i in np.linspace(0,1,11):
        recalls[i] = empty_image(precision_curve=precision_curve, threshold=i)
    
    recalls = pd.DataFrame(list(recalls.items()), columns=["threshold","recall"])
    
    if invert:
        recalls["recall"] = 1 - recalls["recall"].astype(float)
    
    ax1 = recalls.plot.scatter("threshold","recall")
    
    return ax1
    
def predict_empty_frames(model, empty_images, comet_experiment, invert=False):
    """Optionally read a set of empty frames and predict
        Args:
            invert: whether the recall should be relative to empty images (default) or non-empty images (1-value)"""
    
    #Create PR curve
    precision_curve = [ ]
    for path in empty_images:
        boxes = model.predict_image(path=path, return_plot=False)
        if boxes is not None:    
            boxes["image"] = path
            precision_curve.append(boxes)
    
    #if no boxes, skip plot
    try:
        precision_curve = pd.concat(precision_curve)
    except:
        return None
    
    recall_plot = plot_recall_curve(precision_curve, invert=invert)
    value = empty_image(precision_curve, threshold=0.4)
    
    if invert:
        value = 1 - value
        metric_name = "BirdRecall_at_0.4"
        recall_plot.set_title("Atleast One Bird Recall")
    else:
        metric_name = "EmptyRecall_at_0.4"
        recall_plot.set_title("Empty Recall")        
        
    comet_experiment.experiment.log_metric(metric_name,value)
    comet_experiment.experiment.log_figure(recall_plot)    
    
def train_model(train_path, test_path, empty_images_path=None, save_dir=".", debug = False):
    """Train a DeepForest model"""
    
    comet_logger = CometLogger(api_key="ypQZhYfs3nSyKzOfz13iuJpj2",
                                  project_name="everglades", workspace="bw4sz")
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    model_savedir = "{}/{}".format(save_dir,timestamp)  
    
    try:
        os.mkdir(model_savedir)
    except Exception as e:
        print(e)
    
    comet_logger.experiment.log_parameter("timestamp",timestamp)
    comet_logger.experiment.add_tag("Bird Detector")
    
    #Log the number of training and test
    train = pd.read_csv(train_path)
    test = pd.read_csv(test_path)

    #Set config and train'    
    label_dict = {key:value for value, key in enumerate(train.label.unique())}
    model = main.deepforest(num_classes=len(train.label.unique()),label_dict=label_dict)
    
    model.config["train"]["csv_file"] = train_path
    model.config["train"]["root_dir"] = os.path.dirname(train_path)
    
    #Set config and train
    model.config["validation"]["csv_file"] = test_path
    model.config["validation"]["root_dir"] = os.path.dirname(test_path)
    model.config["train"]["epochs"] = 20
    
    if debug:
        print("DEBUG")
        model.config["train"]["fast_dev_run"] = False
        model.config["gpus"] = None
        model.config["workers"] = 0
        model.config["batch_size"] = 1    
    if comet_logger is not None:
        comet_logger.experiment.log_parameters(model.config)
        comet_logger.experiment.log_parameter("Training_Annotations",train.shape[0])    
        comet_logger.experiment.log_parameter("Testing_Annotations",test.shape[0])
        
    #im_callback = images_callback(csv_file=model.config["validation"]["csv_file"], root_dir=model.config["validation"]["root_dir"], savedir=model_savedir, n=20)    
    model.create_trainer(logger=comet_logger)
    
    model.trainer.fit(model)
    
    #Manually convert model
    results = model.evaluate(test_path, root_dir = os.path.dirname(test_path))
    
    if comet_logger is not None:
        try:
            results["results"].to_csv("{}/iou_dataframe.csv".format(model_savedir))
            comet_logger.experiment.log_asset("{}/iou_dataframe.csv".format(model_savedir))
            
            results["class_recall"].to_csv("{}/class_recall.csv".format(model_savedir))
            comet_logger.experiment.log_asset("{}/class_recall.csv".format(model_savedir))
            
            for index, row in results["class_recall"].iterrows():
                comet_logger.experiment.log_metric("{}_Recall".format(row["label"]),row["recall"])
                comet_logger.experiment.log_metric("{}_Precision".format(row["label"]),row["precision"])
            
            comet_logger.experiment.log_metric("Average Class Recall",results["class_recall"].recall.mean())
            comet_logger.experiment.log_metric("Box Recall",results["box_recall"])
            comet_logger.experiment.log_metric("Box Precision",results["box_precision"])
            
            comet_logger.experiment.log_parameter("saved_checkpoint","{}/species_model.pl".format(model_savedir))
            
            ypred = results["results"].predicted_label.astype('category').cat.codes.to_numpy()            
            ypred = torch.from_numpy(ypred)
            ypred = torch.nn.functional.one_hot(ypred, num_classes = model.num_classes).numpy()
            
            ytrue = results["results"].true_label.astype('category').cat.codes.to_numpy()
            ytrue = torch.from_numpy(ytrue)
            ytrue = torch.nn.functional.one_hot(ytrue, num_classes = model.num_classes).numpy()
            comet_logger.experiment.log_confusion_matrix(y_true=ytrue, y_predicted=ypred, labels = list(model.label_dict.keys()))
        except Exception as e:
            print("logger exception: {} with traceback \n {}".format(e, traceback.print_exc()))
    
    #Create a positive bird recall curve
    test_frame_df = pd.read_csv(test_path)
    dirname = os.path.dirname(test_path)
    test_frame_df["image_path"] = test_frame_df["image_path"].apply(lambda x: os.path.join(dirname,x))
    empty_images = test_frame_df.image_path.unique()    
    predict_empty_frames(model, empty_images, comet_logger, invert=True)
    
    #Test on empy frames
    if empty_images_path:
        empty_frame_df = pd.read_csv(empty_images_path)
        empty_frame_df["image_path"] = empty_frame_df["image_path"].apply(lambda x: os.path.join(dirname,x))        
        empty_images = empty_frame_df.image_path.unique()
        predict_empty_frames(model, empty_images, comet_logger)
    
    #save model
    model.trainer.save_checkpoint("{}/species_model.pl".format(model_savedir))
    
    #Save a full set of predictions to file.
    boxes = model.predict_file(model.config["validation"]["csv_file"], root_dir=model.config["validation"]["root_dir"])
    visualize.plot_prediction_dataframe(df = boxes, savedir = model_savedir, root_dir=model.config["validation"]["root_dir"])
    
    return model

def run(shp_dir, empty_frames_path=None, save_dir="."):
    """Parse annotations, create a test split and train a model"""
    annotations = format_shapefiles(shp_dir)    

    #Split train and test
    train, test = split_test_train(annotations)
    
    #Add some empty images to train and test
    empty_frames_df = pd.read_csv(empty_frames_path, index_col=0)
    empty_frames_df.sample(n=10)
    
    #add some blank annotations
    empty_frames_df["xmin"] = pd.Series(dtype="Int64")
    empty_frames_df["ymin"] = pd.Series(dtype="Int64")
    empty_frames_df["xmax"] = pd.Series(dtype="Int64")
    empty_frames_df["ymax"] = pd.Series(dtype="Int64")
    empty_frames_df["label"] = pd.Series(dtype=str)
    
    empty_train, empty_test = split_test_train(empty_frames_df)
    
    #limit the number of empty
    #train = pd.concat([train, empty_train])
    #test = pd.concat([test, empty_test])
    
    #Enforce rounding to pixels, pandas "Int64" dtype for nullable arrays https://pandas.pydata.org/pandas-docs/stable/user_guide/integer_na.html
    train.xmin = train.xmin.astype("Int64")
    train.ymin = train.ymin.astype("Int64")
    train.xmax = train.xmax.astype("Int64")
    train.ymax = train.ymax.astype("Int64")
    
    test.xmin = test.xmin.astype("Int64")
    test.ymin = test.ymin.astype("Int64")
    test.xmax = test.xmax.astype("Int64")
    test.ymax = test.ymax.astype("Int64")
                
    #write paths to headerless files alongside data, add a seperate test empty file
    train_path = "{}/train.csv".format(shp_dir)
    test_path = "{}/test.csv".format(shp_dir)
    empty_test_path = "{}/empty_test.csv".format(shp_dir)
    
    train.to_csv(train_path, index=False)
    test.to_csv(test_path, index=False)
    empty_test.to_csv(empty_test_path, index=False)
    
if __name__ == "__main__":
    run(
       shp_dir="/orange/ewhite/everglades/Zooniverse/parsed_images/",
       empty_frames_path="/orange/ewhite/everglades/Zooniverse/parsed_images/empty_frames.csv",
       save_dir="/orange/ewhite/everglades/Zooniverse/predictions/"
    )
    
    model = train_model(train_path="/orange/ewhite/everglades/Zooniverse/parsed_images/train.csv",
                        test_path="/orange/ewhite/everglades/Zooniverse/parsed_images/test.csv",
                        empty_images_path="/orange/ewhite/everglades/Zooniverse/parsed_images/empty_test.csv",
                        save_dir="/orange/ewhite/everglades/Zooniverse/predictions/")
    
