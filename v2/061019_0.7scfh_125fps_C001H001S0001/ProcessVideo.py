import cv2
import numpy as np
import os
from PIL import Image
import subprocess
import shutil

# -------- SETTINGS --------
input_path = "061019_0.7scfh_125fps_C001H001S0001.mp4" #must be h.264 codec
images_dir = "frames_partial"
make_video = False
outputName = "foo.mp4"
output_fps = 20 #1/125 = 8ms, 80ms is 10 frames. Video is rendered at 20. sampling rate is then 2fps
background = cv2.imread("background.jpg")

# Time trimming (in seconds)
start_time = 0.0
end_time = start_time+240
duration = None  # e.g. 5.0 (used only if end_time is None)

# Processing settings
crop_x, crop_y, crop_w, crop_h = 380, 0, 333, 632
rotation_angle = 0.
contrast_alpha = 0.95
sharpenWeight = 2
clipLimit = 4.0
# --------------------------

cap = cv2.VideoCapture(input_path)
if not cap.isOpened():
    raise Exception("Error opening video file")

input_fps = cap.get(cv2.CAP_PROP_FPS)
# print(input_fps)
total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

# ---- TIME HANDLING ----
start_frame = int(start_time * input_fps)

if end_time is not None:
    end_frame = int(end_time * input_fps)
elif duration is not None:
    end_frame = start_frame + int(duration * input_fps)
else:
    end_frame = total_frames

cap.set(cv2.CAP_PROP_POS_FRAMES, start_frame)

# FPS downsampling
frame_interval = int(round(input_fps / output_fps))

# ---- CALCULATE TOTAL OUTPUT FRAMES ----
total_input_frames = end_frame - start_frame
total_output_frames = total_input_frames // frame_interval

print(f"Total frames to process: {total_output_frames}")


# Prepare output
os.makedirs(images_dir, exist_ok=True)
# Completely remove the folder and all its contents
shutil.rmtree(images_dir)
os.makedirs(images_dir, exist_ok=True)

# CLAHE object
clahe = cv2.createCLAHE(clipLimit=clipLimit, tileGridSize=(8,8))

frame_idx = start_frame
saved_idx = 0

# -----------------------
# LOAD BACKGROUND IMAGE
# -----------------------

# Apply SAME preprocessing as frames (VERY IMPORTANT)
bg_rotated = cv2.warpAffine(
    background,
    cv2.getRotationMatrix2D((frame_width // 2, frame_height // 2), rotation_angle, 1.0),
    (frame_width, frame_height),
    flags=cv2.INTER_LINEAR,
    borderMode=cv2.BORDER_REPLICATE
)

bg_cropped = bg_rotated[crop_y:crop_y+crop_h, crop_x:crop_x+crop_w]
bg_gray = cv2.cvtColor(bg_cropped, cv2.COLOR_BGR2GRAY)

while frame_idx < end_frame:
    ret, frame = cap.read()
    if not ret:
        break

    if (frame_idx - start_frame) % frame_interval != 0:
        frame_idx += 1
        continue

    # ---- ROTATE ----
    center = (frame_width // 2, frame_height // 2)
    matrix = cv2.getRotationMatrix2D(center, rotation_angle, 1.0)

    rotated = cv2.warpAffine(
        frame,
        matrix,
        (frame_width, frame_height),
        flags=cv2.INTER_LINEAR,
        borderMode=cv2.BORDER_REPLICATE
    )

    # ---- CROP ----
    cropped = rotated[crop_y:crop_y+crop_h, crop_x:crop_x+crop_w]

    # ---- GRAYSCALE ----
    gray = cv2.cvtColor(cropped, cv2.COLOR_BGR2GRAY)

        # Optional: smooth
    # thresh = cv2.GaussianBlur(thresh, (5, 5), 0)
    
    # ---- CLAHE ----
    local_contrast = clahe.apply(gray)

    # ---- SHARPEN ----
    blur = cv2.GaussianBlur(local_contrast, (0, 0), 1.0)
    enhanced = cv2.addWeighted(local_contrast, sharpenWeight, blur, -0.5, 0)



    # -----------------------
    # SAVE IMAGE
    # -----------------------
    filename = os.path.join(images_dir, f"frame_{saved_idx:05d}.png")
    cv2.imwrite(filename, enhanced)

    saved_idx += 1
    frame_idx += 1

    # ---- PROGRESS ----
    if saved_idx % 10 == 0 or saved_idx == total_output_frames:
        percent = (saved_idx / total_output_frames) * 100
        print(f"\rProgress: {saved_idx}/{total_output_frames} ({percent:.1f}%)", end="")

cap.release()
print("\nFrame extraction complete.")

# ---- OPTIONAL GIF ----
if make_video:
    print("Creating Video...")
    dir=images_dir+"/frame_%05d.png"
    subprocess.run([
        "ffmpeg",
        "-y",
        "-framerate", str(output_fps),
        "-i", dir,
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        outputName
    ])

    print(f"Output saved to {outputName}")

print("Done!")