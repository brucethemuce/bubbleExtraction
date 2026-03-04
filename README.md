## how to install

1. make a python environment
2. pip install git+https://github.com/facebookresearch/segment-anything.git
3. pip install opencv-python pycocotools matplotlib onnxruntime onnx
 - and whatever other dependencies give an error on trying to run, torch e.g. may not install on the first go. overall needs several gigabytes of space.
5. download a "model checkpoint". starting with the smallest model "vit_b" which runs fine on cpu only. later will use vit_h on come cuda hardware (MTDL01)
 - https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth
5. run the test.py file

## current capabilities 
Right now the script test.py looks for spherical-ish objects in the input image. Then it highlights each one and labels with a number and writes a copy jpeg with whatever it detected.

## future tasks
1. Use a real input test image to tune whichever prompt parameters
2. export the bubble diameter distribution (or other stats the sponsor is interested in, velocity could be significant work)
3. pivot the example to run on cuda and use the 'huge' model
4. test on an input video file. start with a short clip, downsample the framerate to like 100 fps as a start.

## Final Goal
Input a video file, export bubble statistics with some nice graphs (histograms, or timeplots). Repeat the processing for each experimental condition of interest.
