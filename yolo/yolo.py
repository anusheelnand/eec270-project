import os
import cv2
from PIL import Image
import numpy as np
import argparse
from glob import glob

from ultralytics import YOLO

locations = []

# Use argparse to convert CLI arguments to strings/lists of strings
def parse_arguments():
    arg_parsing = argparse.ArgumentParser()
    arg_parsing.add_argument('--img', type=str, required=True, nargs='+', help='Path to image(s)')
    arg_parsing.add_argument('--labels', type=str, required=True, help='Labels file')
    cli_args = arg_parsing.parse_args()
    return cli_args

def load_images(cli_args):
    for location in cli_args.img:
        # If image: open and add to global image list, keep track of file names with global list
        if '.jpg' in location or '.jpeg' in location or '.png' in location: # support for different img types
            locations.append(location)

        if (location): # If directory of imgs (check for empty string)
            
            locations.extend(glob(os.path.join(location,'*.jpg')))
            locations.extend(glob(os.path.join(location,'*.jpeg')))
            locations.extend(glob(os.path.join(location,'*.png')))

        else: # Empty string
            raise ValueError("Invalid image name/path")
        
# Load class names from --labels argument
#   Input cli_args: output of .parse_args()   
#   Returns list of strings  
#    
def load_labels(cli_args):
    with open(cli_args.labels) as label_file:
        class_names = [line.strip() for line in label_file]
    return class_names

# Main function
if __name__ == "__main__":
    cli_args = parse_arguments()
    load_images(cli_args)
    class_names = load_labels(cli_args)
    model = YOLO("yolo11n.pt")
    for idx, file in enumerate(locations):
        # Calculating time using https://docs.opencv.org/4.x/dc/d71/tutorial_py_optimization.html
        image = cv2.imread(file)
        results = model.predict(source=image, verbose=False)
        
