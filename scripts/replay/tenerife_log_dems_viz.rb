#! /usr/bin/env ruby

require 'orocos'
require 'orocos/log'
require 'rock/bundle'
require 'vizkit'

include Orocos

Bundles.initialize
Bundles.transformer.load_conf(
    Bundles.find_file('config', 'transforms_scripts_ga_slam.rb'))

####### Replay Logs #######
bag = Orocos::Log::Replay.open(
#       Nominal start
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1413/bb2.log',
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1413/bb3.log',
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1413/pancam.log',
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1413/waypoint_navigation.log',
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1413/imu.log',
#       Nurburing
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1448/bb2.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1448/bb3.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1448/pancam.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1448/waypoint_navigation.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1448/imu.log',
#       Nurburing End //Not used due to lack of time
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1615/bb2.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1615/bb3.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1615/pancam.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1615/waypoint_navigation.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1615/imu.log',
#       Side Track
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1556/bb2.log',
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1556/bb3.log',
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1556/pancam.log',
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1556/waypoint_navigation.log',
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1556/imu.log',
#       Eight Track (Dusk)
        '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/bb2.log',
        '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/bb3.log',
        '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/pancam.log',
        '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/waypoint_navigation.log',
        '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/imu.log',
)
bag.use_sample_time = true

Orocos.run(
    ####### Tasks #######
    'camera_bb2::Task' => 'camera_bb2',
    'camera_bb3::Task' => 'camera_bb3',
    'stereo::Task' => ['stereo_bb2', 'stereo_bb3', 'stereo_pancam'],
    'viso2::StereoOdometer' => 'viso2',
    'pancam_transformer::Task' => 'pancam_transformer',
    'gps_transformer::Task' => 'gps_transformer',
    'orbiter_preprocessing::Task' => 'orbiter_preprocessing',
    'ga_slam::Task' => 'ga_slam',
    ####### Debug #######
    # :output => '%m-%p.log',
    # :gdb => ['ga_slam'],
    # :valgrind => ['ga_slam'],
    :valgrind_options => ['--track-origins=yes']) \
do
    ####### Configure Tasks #######
    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['loc_cam_front'], :override => true)
    camera_bb2.configure

    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure

    stereo_bb2 = TaskContext.get 'stereo_bb2'
    Orocos.conf.apply(stereo_bb2, ['hdpr_bb2_ga_slam_tenerife'], :override => true)
    stereo_bb2.configure

    stereo_bb3 = TaskContext.get 'stereo_bb3'
    Orocos.conf.apply(stereo_bb3, ['hdpr_bb3_left_right'], :override => true)
    stereo_bb3.configure

    stereo_pancam = TaskContext.get 'stereo_pancam'
    Orocos.conf.apply(stereo_pancam, ['panCam'], :override => true)
    stereo_pancam.configure

    viso2 = TaskContext.get 'viso2'
    Orocos.conf.apply(viso2, ['bumblebee'], :override => true)
    Bundles.transformer.setup(viso2)
    viso2.configure

    pancam_transformer = TaskContext.get 'pancam_transformer'
    Orocos.conf.apply(pancam_transformer, ['default'], :override => true)
    pancam_transformer.configure

    gps_transformer = TaskContext.get 'gps_transformer'
    gps_transformer.configure

    orbiter_preprocessing = TaskContext.get 'orbiter_preprocessing'
    Orocos.conf.apply(orbiter_preprocessing, ['default', 'ga_slam', 'solving_occlusion'], :override => true)
    # Orocos.conf.apply(orbiter_preprocessing, ['prepared'], :override => true)
    orbiter_preprocessing.configure

    ga_slam = TaskContext.get 'ga_slam'
    # Orocos.conf.apply(ga_slam, ['default'], :override => true)
    Orocos.conf.apply(ga_slam, ['default', 'test', 'solving_occlusion'], :override => true)
    Bundles.transformer.setup(ga_slam)
    ga_slam.configure

    # Copy parameters from ga_slam to orbiter_preprocessing
    orbiter_preprocessing.cropSize = ga_slam.orbiterMapLength
    orbiter_preprocessing.voxelSize = ga_slam.orbiterMapResolution

    ####### Connect Task Ports #######
    bag.camera_firewire_bb2.frame.connect_to        camera_bb2.frame_in
    bag.camera_firewire_bb3.frame.connect_to        camera_bb3.frame_in

    camera_bb2.left_frame.connect_to                stereo_bb2.left_frame
    camera_bb2.right_frame.connect_to               stereo_bb2.right_frame
    camera_bb3.left_frame.connect_to                stereo_bb3.left_frame
    camera_bb3.right_frame.connect_to               stereo_bb3.right_frame
    bag.pancam_panorama.left_frame_out.connect_to   stereo_pancam.left_frame
    bag.pancam_panorama.right_frame_out.connect_to  stereo_pancam.right_frame

    stereo_bb2.point_cloud.connect_to               ga_slam.hazcamCloud
    stereo_bb3.point_cloud.connect_to               ga_slam.loccamCloud
    stereo_pancam.point_cloud.connect_to            ga_slam.pancamCloud

    camera_bb2.left_frame.connect_to                viso2.left_frame
    camera_bb2.right_frame.connect_to               viso2.right_frame

    bag.pancam_panorama.
        tilt_angle_out_degrees.connect_to           pancam_transformer.pitch
    bag.pancam_panorama.
        pan_angle_out_degrees.connect_to            pancam_transformer.yaw
    pancam_transformer.transformation.connect_to    ga_slam.pancamTransformation

    bag.gps_heading.pose_samples_out.connect_to     gps_transformer.inputPose
    bag.gps_heading.pose_samples_out.connect_to     orbiter_preprocessing.robotPose

    #viso2.pose_samples_out.connect_to               ga_slam.odometryPose
    gps_transformer.outputPose.connect_to           ga_slam.odometryPose

    # Connect IMU (roll, pitch) + Laser Gyro (yaw)
    gps_transformer.outputPose.connect_to           ga_slam.imuOrientation

    orbiter_preprocessing.pointCloud.connect_to     ga_slam.orbiterCloud
    gps_transformer.outputPose.connect_to           ga_slam.orbiterCloudPose

    ####### Start Tasks #######
    # camera_bb2.start
    camera_bb3.start
    # stereo_bb2.start
    stereo_bb3.start
    # stereo_pancam.start
    # viso2.start
    # pancam_transformer.start
    gps_transformer.start
    orbiter_preprocessing.start
    ga_slam.start


    ####### Vizkit Display #######
    # Vizkit.display viso2.pose_samples_out,
    #     :widget => Vizkit.default_loader.RigidBodyStateVisualization
    # Vizkit.display viso2.pose_samples_out,
    #     :widget => Vizkit.default_loader.TrajectoryVisualization
    # Vizkit.display gps_transformer.outputPose,
    #     :widget => Vizkit.default_loader.RigidBodyStateVisualization
    # Vizkit.display gps_transformer.outputPose,
    #     :widget => Vizkit.default_loader.TrajectoryVisualization
    # Vizkit.display ga_slam.estimatedPose,
    #     :widget => Vizkit.default_loader.RigidBodyStateVisualization
    # Vizkit.display ga_slam.estimatedPose,
    #     :widget => Vizkit.default_loader.TrajectoryVisualization

    # Vizkit.display camera_bb2.left_frame
    Vizkit.display camera_bb3.left_frame
    # Vizkit.display bag.pancam_panorama.left_frame_out

    # Vizkit.display stereo_bb2.point_cloud
    # Vizkit.display stereo_bb3.point_cloud
    # Vizkit.display stereo_pancam.point_cloud
    # Vizkit.display viso2.point_cloud_samples_out
    # Vizkit.display ga_slam.mapCloud

    Vizkit.display ga_slam.localElevationMapMean
    Vizkit.display ga_slam.globalElevationMapMean

    Vizkit.display orbiter_preprocessing.pointCloud

    ####### Vizkit Replay Control #######
    control = Vizkit.control bag
#    control.speed = 1.0
#    control.seek_to 13000 # Nominal
#    control.seek_to 34700 #17181 #34000 #31000 # Nurburing
#    control.seek_to 59000 # Eight Track Dusk
#    control.seek_to 4955 #24000 #15378 # Side Track
    control.bplay_clicked

    ####### Vizkit #######
    Vizkit.exec
end