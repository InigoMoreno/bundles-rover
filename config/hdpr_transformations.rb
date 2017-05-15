# Transformations for the ExoTer rover
# ############################################
## ESA - NPI
## Author: Javier Hidalgo Carrio
## Email: javier.hidalgo_carrio@dfki.de
## ###########################################
# The convention to follow is "frame1" => "frame2" means the base of frame2 is
# expressed in the base of frame1. Therefore Tbody_stim300 is expressing
# stim300_frame in body_frame. Keep in mind that if we have a vector in
# stim300_frame and we want to have it in body_frame.
# v_body = Tbody_stim300 v_stim300
#
# It first translates by the Vector3d and then rotates
#######
## MS: GEOMETRICAL INFO UPDATE
## * According to the paper 'The Katwijk beach planetary rover dataset' the frames have been expressed wrt. to the IMU frame:
##   To get them to the body frame, the signs of x and y have to be changed

############################
# Static transformations
############################

# Transformation Body to IMU (IMU frame expressed in Body frame) but transformer expects the other sense
# MS: In HDPR, BODY and IMU frame coincide wrt. translation but are different wrt. orientation
static_transform Eigen::Quaternion.from_angle_axis(Math::PI, Eigen::Vector3.UnitZ),
    Eigen::Vector3.new( 0.0, 0.0, 0.0 ), "imu" => "body"

# Transformation Body to Mast top (Mast top frame expressed in Body frame) but transformations expects the other sense
# MS: In HDPR, the mast is called PAN-TILT-FRAME
static_transform Eigen::Quaternion.Identity(),
    Eigen::Vector3.new( 0.138, -0.005, 1.286 ), "ptu_base" => "body"

# Transformation Body to GPS (GPS frame expressed in Body frame) but transformer expects the other sense
static_transform Eigen::Quaternion.Identity(),
    Eigen::Vector3.new( -0.6, 0.0, 0.3 ), "gps" => "body"

# Transformation GPS to Lab for naming convention (GPS frame expressed in Body frame) but transformer expects the other sense
static_transform Eigen::Quaternion.Identity(),
#    Eigen::Vector3.new( 0.0, 0.0, 0.0 ), "imu" => "lab"
    Eigen::Vector3.new( 0.0, 0.0, 0.0 ), "gnss_utm" => "lab" # Original, meantime switched to imu to have quaternions
static_transform Eigen::Quaternion.Identity(),
    Eigen::Vector3.new( 0.0, 0.0, 0.0 ), "world_osg" => "lab" # tp be used in the actual lab
static_transform Eigen::Quaternion.Identity(),
    Eigen::Vector3.new( 0.0, 0.0, 0.0 ), "viso_world" => "lab" # tp be used in the actual lab

# Transformation PTU to Left camera (Left camera frame expressed in PTU frame) but transformer expects the other sense
static_transform Eigen::Quaternion.from_euler(Eigen::Vector3.new( -Math::PI/2.0, 0.00, -Math::PI/2.0), 2,1,0),
    Eigen::Vector3.new( 0.01, 0.25, 0.055 ), "left_camera_pancam" => "ptu_head"

# Transformation Left camera to Right camera (Right camera frame expressed in Left camera frame) but transformer expects the other sense
static_transform Eigen::Quaternion.Identity(),
    Eigen::Vector3.new( 0.5, 0.0, 0.0 ), "right_camera" => "left_camera"

# Transformation Left camera to ToF camera (ToF camera frame expressed in Left camera frame) but transformer expects the other sense
#static_transform Eigen::Quaternion.from_euler(Eigen::Vector3.new( Math::PI/2.0, 0.00, Math::PI/2.0), 2,1,0),
# MS: Renamed left_camera frame to reflect that the BB3 used as the front cam is different from the mast frame
# TODO: Measure again when final position has come up
static_transform Eigen::Quaternion.from_euler(Eigen::Vector3.new(-Math::PI/2.0, 0.0, -0.506-Math::PI/2.0), 2,1,0),
    Eigen::Vector3.new( 0.6, 0.0, 0.1), "tof" => "body"

# Transformation front BB2 to body center
static_transform Eigen::Quaternion.from_euler(Eigen::Vector3.new(-Math::PI/2.0, 0.0, -0.593-Math::PI/2.0), 2,1,0),
    Eigen::Vector3.new(0.54309, 0.06, 0.01713), "left_camera_bb2" => "body"
# TODO: Not verified
static_transform Eigen::Quaternion.from_euler(Eigen::Vector3.new( -Math::PI/2.0, 0.0, -0.314-Math::PI/2.0), 2,1,0),
    Eigen::Vector3.new(0.46, 0.12, 0.455), "left_camera_bb3" => "body"
static_transform Eigen::Quaternion.Identity(),
    Eigen::Vector3.new( 0.12, 0.0, 0.0 ), "center_camera_bb3" => "left_camera_bb3"
static_transform Eigen::Quaternion.Identity(),
    Eigen::Vector3.new( 0.12, 0.0, 0.0 ), "right_camera_bb3" => "center_camera_bb3"

# MS: Transformation Body to Velodyne (Velodyne frame expressed in Body frame)
# TODO: Measure the height again, since its not tilted anymore
static_transform Eigen::Quaternion.from_euler(Eigen::Vector3.new(Math::PI, 0.0, 0.0), 2,1,0),
    Eigen::Vector3.new(0.46, 0.018, 0.55), "lidar" => "body"

static_transform Eigen::Quaternion.Identity(),
    Eigen::Vector3.new( 0.0, 0.0, 0.0 ), "left_camera_bb2" => "left_camera_viso2"
