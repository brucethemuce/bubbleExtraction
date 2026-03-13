## how to install

1. make a python environment
2. pip install git+https://github.com/facebookresearch/segment-anything.git
3. pip install opencv-python pycocotools matplotlib onnxruntime onnx torch torchvision
 - and whatever other dependencies give an error on trying to run, overall needs several gigabytes of space.
4. download a "model checkpoint". starting with the smallest model "vit_b" which runs fine on cpu only. later will use vit_h on come cuda hardware (MTDL01)
 - https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth
5. run the test.py file

## current capabilities 
Right now the script test.py looks for spherical-ish objects in the input image. Then it highlights each one and labels with a number and writes a copy jpeg with whatever it detected.

test_markAll.py draws all detected shapes that have a small-ish area

Runtime is ~30-120s per image.

## future tasks
~1. Use a real input test image to tune whichever prompt parameters~
~2. export the bubble diameter distribution (or other stats the sponsor is interested in, velocity could be significant work)~
1. use the condition of interest per Dr G
   1. no u-bend tests
2. from vid file export a frame every ~1 second as jpeg
3. autocrop it down to help the model
4. crank up the settings and try to get 90%+ of the gas (including churn and caps)
   1. in parallel try opencv (cv2) with some sorta basic edge detection if its faster/better then great. if it sucks or is similar speed then forget it
5. in post, record the rep. diameter, the x and y position, and timestamp. dump in a csv file for plotting later in histogram or whatever
   1. find a pixel -> length conversion

## Final Goal
Input a video file, export bubble statistics with some nice graphs (histograms, or timeplots). Repeat the processing for each experimental condition of interest.
