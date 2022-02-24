import math
import os
import sys

import cv2
import deep_ga
import matplotlib.pyplot as plt
import numpy as np
import pocolog_pybind
from progressbar import progressbar
from plyfile import PlyData, PlyElement


def euler_from_quaternion(quaternion):
        """
        Convert a quaternion into euler angles (yaw, pitch, roll) (in radians)
        """
        x=quaternion["im"][0]
        y=quaternion["im"][1]
        z=quaternion["im"][2]
        w=quaternion["re"]

        t0 = 2*(w*z + x*y)
        t1 = 1 - 2 * (x*x + y*y)
        t1 = w*w + x*x - y*y - z*z 
        yaw = math.atan2(t0, t1)
     
        t2 = 2*(w*y - z*x)
        pitch = math.asin(t2)
     
        t3 = 2*(w*x + y*z)
        t4 = w*w - x*x - y*y + z*z 
        roll = math.atan2(t3, t4)
     
        return yaw, pitch, roll # in radians

def extract_rigidbody_stream(gps_stream, resolution=1):
    # Extract the time, position and euler from a gps_stream
    size=gps_stream.get_size()
    size//=resolution
    state = np.empty((size,7))
    for i in progressbar(range(0,size)):
        value = gps_stream.get_sample(i*resolution)
        py_value = value.cast(recursive=True)
        # print(py_value.keys())
        time = py_value["time"]["microseconds"]
        pos = py_value["position"]["data"]
        eul = euler_from_quaternion(py_value["orientation"])
        state[i,0]=time
        state[i,1:4]=pos
        state[i,4:]=eul
        value.destroy()
    return state

# Dataset path
dataset='/media/heimdal/Dataset1'


# Get the traverse folder from the argv
if len(sys.argv)>1:
    traverse=str(sys.argv[1])
else:
    traverse='10June/Traverse/20170610-1818/'

traverse_name=traverse.split('/')[-2]
print(traverse_name)
path = dataset + "/" + traverse
processed_path = dataset + "/processed/" + traverse

print(processed_path)
if not os.path.isdir(processed_path):
    print("No processed path")
    exit()


# Get the streams from the logs using Maxi's pocolog_pybind
# https://github.com/esa-prl/tools-pocolog_pybind
multi_file_index = pocolog_pybind.pocolog.MultiFileIndex()
multi_file_index.create_index([processed_path + "ga_slam.0.log",
                            path + "updated/waypoint_navigation.log"])
streams = multi_file_index.get_all_streams()
dem_stream = streams["/ga_slam.localElevationMapMean"]
gps_stream = streams["/gps_heading.pose_samples_out"]

# Use constants from https://github.com/InigoMoreno/deep_ga/blob/main/deep_ga/constants.py
gps_references = deep_ga.get_gps_references()
state = extract_rigidbody_stream(gps_stream,1)
state[:,1]+=gps_references[0]
state[:,2]+=gps_references[1]
state[:,3]+=gps_references[2]

# Initialize numpy arrays
size=dem_stream.get_size()
dems  = None 
times = np.empty((size,))
state_dem = np.empty((size,7))

index_gps = 0

for t in progressbar(range(1,size)):
    try:
        # Try to load the dem
        value = dem_stream.get_sample(t)
        py_value = value.cast(recursive=True)
        value.destroy()
    except RuntimeError:
        # If there are less values than advertised, cut the numpy arrays short
        dems=dems[:t,:,:]
        times=times[:t]
        state_dem=state_dem[:t,:]
        break
    
    times[t] = py_value["time"]["microseconds"]

    # Get the state (position and orientation) of the gps at the time of the dem
    # This could be improved by interpolating between the previous and current value
    while state[index_gps+1,0]<py_value["time"]["microseconds"]:
        index_gps+=1
    state_dem[t,:]=state[index_gps,:]

    # Transform to numpy
    local_dem = np.array(py_value["data"])
    local_dem = local_dem.reshape((py_value["height"], py_value["width"]), order="F").astype("float32")
    # Do some weird flip of the images to orient the dem correctly
    # This is an artifact from the way the data is stored by the logfile
    # This was found by trial and error (using dem_visualize.py)
    local_dem = local_dem[::-1,::-1].T
    if dems is None: 
        w,h = local_dem.shape
        dems = np.empty((size,w,h))
    dems[t,:,:]=local_dem

# save everything to a compressed numpy format (.npz)
np.savez_compressed(dataset + "/processed/"+traverse_name+".npz",dem_times=times,dems=dems,gps=state,gps_dem=state_dem)