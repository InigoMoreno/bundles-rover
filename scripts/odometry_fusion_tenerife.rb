#! /usr/bin/env ruby

require 'rock/bundle'
require 'vizkit'

include Orocos

Bundles.initialize
Orocos.conf.load_dir('/home/user/rock/perception/orogen/spartan/config')
Bundles.transformer.load_conf(
    Bundles.find_file('config', 'transforms_scripts.rb'))

camera = 3

Orocos.run(
    # 'unit_odometry_fusion',
    'unit_odometry',
    'localization_frontend::Task' => 'localization_frontend',
    'camera_bb2::Task' => 'camera_bb2',
    'camera_bb3::Task' => 'camera_bb3',
    'spartan::Task' => 'spartan',
    'gps_transformer::Task' => 'gps_transformer',
    'viso2_evaluation::Task' => 'visual_evaluation'
    ) \
do
    ####### Replay Logs #######
    bag = Orocos::Log::Replay.open(
#       Nominal start
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1413/bb2.log',
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1413/bb3.log',
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1413/pancam.log',
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1413/waypoint_navigation.log',
#        '/media/heimdal/Dataset1/9June/Traverse/20170609-1413/imu.log',
#         '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/control.log',

#       Nurburing
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1448/bb2.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1448/bb3.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1448/pancam.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1448/waypoint_navigation.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1448/imu.log',
#         '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/control.log',

#       Nurburing End //Not used due to lack of time
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1615/bb2.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1615/bb3.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1615/pancam.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1615/waypoint_navigation.log',
#        '/media/heimdal/Dataset1/10June/Traverse/20170610-1615/imu.log',
#         '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/control.log',

#       Side Track
       '/media/heimdal/Dataset1/9June/Traverse/20170609-1556/bb2.log',
       '/media/heimdal/Dataset1/9June/Traverse/20170609-1556/bb3.log',
       '/media/heimdal/Dataset1/9June/Traverse/20170609-1556/pancam.log',
       '/media/heimdal/Dataset1/9June/Traverse/20170609-1556/waypoint_navigation.log',
       '/media/heimdal/Dataset1/9June/Traverse/20170609-1556/imu.log',
        '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/control.log',
#       Eight Track (Dusk)
#         '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/bb2.log',
#         '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/bb3.log',
#         '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/pancam.log',
#         '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/waypoint_navigation.log',
#         '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/imu.log',
#         '/media/heimdal/Dataset1/9June/Traverse/20170609-1909/control.log',

    )
    bag.use_sample_time = true

    ####### Configure Tasks #######

    # odometry_fusion = Orocos.name_service.get "odometry_fusion"
    # Orocos.conf.apply(odometry_fusion, ['default'], :override => true)
    # odometry_fusion.configure

    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['hdpr_bb2'], :override => true)
    camera_bb2.configure

    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure

    gps_transformer = TaskContext.get 'gps_transformer'
    gps_transformer.configure

    spartan = Orocos.name_service.get 'spartan'
    Orocos.conf.apply(spartan, ['default'], :override => true)
    Orocos.transformer.setup(spartan)
    spartan.desired_period=1
    if camera==2
        spartan.calibration_confs.calib_path = '/home/user/rock/perception/orogen/spartan/config/hdpr_bb2_ga_slam_tenerife.yaml'
        spartan.calibration_confs.spartanWidth = 1024
        spartan.calibration_confs.spartanHeight = 768
    else
        spartan.calibration_confs.calib_path = '/home/user/rock/perception/orogen/spartan/config/hdpr_bb3_calib.yaml'
        spartan.calibration_confs.spartanWidth = 1280
        spartan.calibration_confs.spartanHeight = 960
    end
    spartan.configure
    
    visual_evaluation = TaskContext.get 'visual_evaluation'
    Orocos.conf.apply(visual_evaluation, ['default'], :override => true)
    visual_evaluation.skip_first_n=5
    visual_evaluation.align_streams=true
    visual_evaluation.configure
    
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['hdpr_reading'], :override => true)
    read_joint_dispatcher.configure

    puts "Setting up localization_frontend"
    localization_frontend = Orocos.name_service.get 'localization_frontend'
    Orocos.conf.apply(localization_frontend, ['default', 'HDPR', 'hamming1hzsampling12hz'], :override => true)
    #Orocos.conf.apply(localization_frontend, ['default', 'bessel50'], :override => true)
    localization_frontend.urdf_file = Bundles.find_file('data/odometry', 'hdpr_odometry_model_complete.urdf')
    Bundles.transformer.setup(localization_frontend)
    localization_frontend.configure

    threed_odometry = Orocos.name_service.get 'threed_odometry'
    Orocos.conf.apply(threed_odometry, ['default', 'HDPR', 'bessel50'], :override => true)
    threed_odometry.urdf_file = Bundles.find_file('data/odometry', 'hdpr_odometry_model_complete.urdf')
    Bundles.transformer.setup(threed_odometry)
    threed_odometry.configure

    ####### Connect Task Ports #######
    if camera==2
        bag.camera_firewire_bb2.frame.connect_to        camera_bb2.frame_in
        camera_bb2.left_frame.connect_to                spartan.img_in_left
        camera_bb2.right_frame.connect_to               spartan.img_in_right
    else
        bag.camera_firewire_bb3.frame.connect_to            camera_bb3.frame_in
        camera_bb3.left_frame.connect_to                    spartan.img_in_left
        camera_bb3.right_frame.connect_to                   spartan.img_in_right
    end

    bag.gps_heading.pose_samples_out.connect_to         gps_transformer.inputPose

    gps_transformer.outputPose.connect_to               visual_evaluation.groundtruth_pose
    spartan.vo_out.connect_to                           visual_evaluation.odometry_pose

    bag.platform_driver.joints_readings.connect_to      read_joint_dispatcher.joints_readings
    read_joint_dispatcher.joints_samples.connect_to     localization_frontend.joints_samples
    bag.imu_stim300.orientation_samples_out.connect_to  localization_frontend.orientation_samples
    bag.imu_stim300.compensated_sensors_out.connect_to  localization_frontend.inertial_samples

    localization_frontend.joints_samples_out.connect_to         threed_odometry.joints_samples
    localization_frontend.orientation_samples_out.connect_to    threed_odometry.orientation_samples
    localization_frontend.weighting_samples_out.connect_to      threed_odometry.weighting_samples, :type => :buffer, :size => 200

    # Connect odometry fusion
    # threed_odometry.delta_pose_samples_out.connect_to \
    #     odometry_fusion.inertial_delta_pose_in, :type => :buffer, :size => 10000
    # spartan.delta_vo_out.connect_to \
    #     odometry_fusion.visual_delta_pose_in, :type => :buffer, :size => 10000

    bag.gps_heading.pose_samples_out.on_data do |sample|
        puts sample.time
    end
    
    puts "\n CONFIGURATION DONE \n\n"
    
    Orocos.log_all_ports(exclude_ports: /frame/)

    ####### Start Tasks #######
    camera_bb2.start
    camera_bb3.start
    gps_transformer.start
    spartan.start
    # odometry_fusion.start
    read_joint_dispatcher.start
    localization_frontend.start
    visual_evaluation.start
    threed_odometry.start
    
    puts "\n TASKS STARTED\n\n"

    ####### Vizkit Replay Control #######
    control = Vizkit.control bag
    control.speed = 1
    control.seek_to 500000 # Eight Track Dusk
    control.bplay_clicked

    ####### Vizkit #######
    Vizkit.exec
end

