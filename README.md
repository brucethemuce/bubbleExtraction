## how to install

1. make a python environment
~2. pip install git+https://github.com/facebookresearch/segment-anything.git~
3. pip install opencv-python pycocotools matplotlib onnxruntime onnx torch torchvision pandas scikit-image
 - and whatever other dependencies give an error on trying to run, overall needs several gigabytes of space.
~4. download a "model checkpoint". starting with the smallest model "vit_b" which runs fine on cpu only. later will use vit_h on come cuda hardware (MTDL01)
 - https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth~
5. run ProcessVideo.py to generate a bunch of frames.
6. run jiaqi_python.py to process into binary image and get the stats.

## current capabilities 
returns the diam distribution from an mp4, ~10s for 2 mins of video at 10fps

## future tasks
process the 2scfh case, write a report

## Notes
the ID of the cylinder chamber is 2.5 inches (left to right)


## Final Goal
Input a video file, export bubble statistics with some nice graphs (histograms, or timeplots). Repeat the processing for each experimental condition of interest.
