#! /usr/bin/env ruby

require 'rock/bundle'
require 'vizkit'

include Orocos

Bundles.initialize
Bundles.transformer.load_conf(
    Bundles.find_file('config', 'transforms_scripts_ga_slam.rb'))

Orocos.run(
    ####### Tasks #######
    'camera_firewire::CameraTask' => ['camera_firewire_bb2', 'camera_firewire_bb3'],
    'camera_bb2::Task' => 'camera_bb2',
    'camera_bb3::Task' => 'camera_bb3',
    'stereo::Task' => ['stereo_bb2', 'stereo_bb3', 'stereo_pancam'],
    'viso2::StereoOdometer' => 'viso2',
    'pancam_transformer::Task' => 'pancam_transformer',
    'gps_heading::Task' => 'gps_heading',
    'gps_transformer::Task' => 'gps_transformer',
    'vicon::Task' => 'vicon',
    'orbiter_preprocessing::Task' => 'orbiter_preprocessing',
    'ga_slam::Task' => 'ga_slam',
    'traversability::Task' => 'traversability',
    ####### Debug #######
    # :output => '%m-%p.log',
    # :gdb => ['ga_slam'],
    # :valgrind => ['ga_slam'],
    :valgrind_options => ['--track-origins=yes']) \
do
    ####### Configure Tasks #######
    camera_firewire_bb2 = TaskContext.get 'camera_firewire_bb2'
    Orocos.conf.apply(camera_firewire_bb2, ['hdpr_bb2', 'egp_bb2_id', 'auto_exposure'], :override => true)
    camera_firewire_bb2.configure

    camera_firewire_bb3 = TaskContext.get 'camera_firewire_bb3'
    Orocos.conf.apply(camera_firewire_bb3, ['hdpr_bb3', 'altec_bb3_id', 'auto_exposure'], :override => true)
    camera_firewire_bb3.configure

    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['egp_bb2'], :override => true)
    camera_bb2.configure

    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure

    stereo_bb2 = TaskContext.get 'stereo_bb2'
    Orocos.conf.apply(stereo_bb2, ['egp_bb2'], :override => true)
    stereo_bb2.configure

    stereo_bb3 = TaskContext.get 'stereo_bb3'
    Orocos.conf.apply(stereo_bb3, ['marta_bb3_left_right'], :override => true)
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

    vicon = TaskContext.get 'vicon'
    Orocos.conf.apply(vicon, ['default','hdpr'], :override => true)
    vicon.configure

    gps_heading = TaskContext.get 'gps_heading'
    Orocos.conf.apply(gps_heading, ['default'], :override => true)
    gps_heading.configure

    gps_transformer = TaskContext.get 'gps_transformer'
    gps_transformer.configure

    orbiter_preprocessing = TaskContext.get 'orbiter_preprocessing'
    Orocos.conf.apply(orbiter_preprocessing, ['default'], :override => true)
    # Orocos.conf.apply(orbiter_preprocessing, ['prepared'], :override => true)
    orbiter_preprocessing.configure

    ga_slam = TaskContext.get 'ga_slam'
    # Orocos.conf.apply(ga_slam, ['default'], :override => true)
    Orocos.conf.apply(ga_slam, ['default','test'], :override => true)
    Bundles.transformer.setup(ga_slam)
    ga_slam.configure

    traversability = Orocos.name_service.get 'traversability'
    Orocos.conf.apply(traversability, ['hdpr'], :override => true)
    traversability.configure

    # Copy parameters from ga_slam to orbiter_preprocessing
    orbiter_preprocessing.cropSize = ga_slam.orbiterMapLength
    orbiter_preprocessing.voxelSize = ga_slam.orbiterMapResolution

    ####### Connect Task Ports #######
    camera_firewire_bb2.frame.connect_to            camera_bb2.frame_in
    camera_firewire_bb3.frame.connect_to            camera_bb3.frame_in

    camera_bb2.left_frame.connect_to                stereo_bb2.left_frame
    camera_bb2.right_frame.connect_to               stereo_bb2.right_frame
    camera_bb3.left_frame.connect_to                stereo_bb3.left_frame
    camera_bb3.right_frame.connect_to               stereo_bb3.right_frame
    #pancam_panorama.left_frame_out.connect_to       stereo_pancam.left_frame
    #pancam_panorama.right_frame_out.connect_to      stereo_pancam.right_frame

    stereo_bb2.point_cloud.connect_to               ga_slam.hazcamCloud
    stereo_bb3.point_cloud.connect_to               ga_slam.loccamCloud
    #stereo_pancam.point_cloud.connect_to            ga_slam.pancamCloud

    camera_bb2.left_frame.connect_to                viso2.left_frame
    camera_bb2.right_frame.connect_to               viso2.right_frame

    #pancam_panorama.
    #    tilt_angle_out_degrees.connect_to           pancam_transformer.pitch
    #pancam_panorama.
    #    pan_angle_out_degrees.connect_to            pancam_transformer.yaw
    #pancam_transformer.transformation.connect_to    ga_slam.pancamTransformation

    vicon.pose_samples.connect_to                   ga_slam.odometryPose
    vicon.pose_samples.connect_to                   orbiter_preprocessing.robotPose
    gps_heading.pose_samples_out.connect_to         gps_transformer.inputPose
    gps_heading.pose_samples_out.connect_to         orbiter_preprocessing.robotPose

    viso2.pose_samples_out.connect_to               ga_slam.odometryPose
    gps_transformer.outputDriftPose.connect_to      ga_slam.odometryPose

    # Connect IMU (roll, pitch) + Laser Gyro (yaw)
    gps_transformer.outputPose.connect_to           ga_slam.imuOrientation

    orbiter_preprocessing.pointCloud.connect_to     ga_slam.orbiterCloud
    gps_transformer.outputPose.connect_to           ga_slam.orbiterCloudPose
    vicon.pose_samples.connect_to                   ga_slam.orbiterCloudPose

    ga_slam.elevationMap.connect_to                 traversability.elevation_map

    ####### Start Tasks #######
    # camera_firewire_bb2.start
    camera_firewire_bb3.start
    # camera_bb2.start
    camera_bb3.start
    # stereo_bb2.start
    stereo_bb3.start
    # stereo_pancam.start
    # viso2.start
    # pancam_transformer.start
    vicon.start
    # gps_heading.start
    # gps_transformer.start
    # orbiter_preprocessing.start
    ga_slam.start
    traversability.start

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

    #Vizkit.display camera_bb2.left_frame
    Vizkit.display camera_bb3.left_frame
    # Vizkit.display bag.pancam_panorama.left_frame_out

    # Vizkit.display stereo_bb2.point_cloud
    # Vizkit.display stereo_bb3.point_cloud
    # Vizkit.display stereo_pancam.point_cloud
    # Vizkit.display viso2.point_cloud_samples_out
    # Vizkit.display ga_slam.mapCloud

    # Vizkit.display ga_slam.elevationMap

    # Vizkit.display orbiter_preprocessing.pointCloud

    ####### ROS RViz #######
    spawn 'roslaunch ga_slam_visualization ga_slam_visualization.launch'
    sleep 3

    ####### Vizkit #######
    Vizkit.exec
end

