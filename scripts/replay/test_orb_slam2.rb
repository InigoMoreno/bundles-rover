#! /usr/bin/env ruby

require 'orocos'
require 'orocos/log'
require 'rock/bundle'
require 'vizkit'


include Orocos

Bundles.initialize

#create window,button and text field
#window = Qt::Widget.new
#button = Qt::PushButton.new(window)
#button.move(10,10)
#text_field = Qt::TextEdit.new(window)
#text_field.move 10,70
#window.show

#Orocos.run 'stereo::Task' => 'stereo', 
#    'cartographer::Task' => 'cartographer' do 
Orocos.run 'orb_slam2::Task' => 'orb_slam2' do

    #Orocos.log_all_ports 

    # declare logger of new ports
    logger = Orocos.name_service.get 'stereo_Logger'
    # new log destination
    logger.file = "rectifiedImages.log"

    # new components to run on top of the log
    orb_slam2 = Orocos.name_service.get 'orb_slam2'
    #cartographer = Orocos.name_service.get 'cartographer'
    Orocos.conf.apply(stereo, ['exoter_bb2'], :override => true)
    Orocos.conf.apply(cartographer, ['default'], :override => true)

    # open log file to be postprocessed
    if ARGV.size == 0 then
        log_replay = Orocos::Log::Replay.open( "bb2.log",
                                              "exoter_proprioceptive.0.log",
                                              "exoter_groundtruth.0.log",
                                              "exoter_control.0.log")
    else
        log_replay = Orocos::Log::Replay.open(ARGV[0]+"bb2.log",
                                              ARGV[0]+"exoter_proprioceptive.0.log",
                                              ARGV[0]+"exoter_groundtruth.0.log",
                                              ARGV[0]+"exoter_control.0.log") 
    end

    # uses timestamp when data was acquired
    log_replay.use_sample_time = true

    # new connections
    # log_replay.*.*.connect_to( orb_slam2.point_cloud_samples )
    log_replay.camera_bb2.left_frame.connect_to( orb_slam2.left_frame)
    log_replay.camera_bb2.right_frame.connect_to( orb_slam2.right_frame)
    # log_replay.*.*.connect_to( orb_slam.delta_pose_samples )

    #stereo.distance_frame.connect_to(cartographer.distance_image)
    #log_replay.imu_stim300.orientation_samples_out.connect_to(cartographer.pose_imu)
    #log_replay.vicon.pose_samples.connect_to(cartographer.pose_vicon)
    #log_replay.ptu_control.mast_to_ptu_out.connect_to(cartographer.pose_ptu)

    # data to be logged
    #logger.log(stereo.left_frame_sync, 200)
    #logger.log(stereo.right_frame_sync, 200)

    # start the components
    orb_slam2.configure
    orb_slam2.start

    #cartographer.configure
    #cartographer.start

    #logger.start

    #show the control widget for the log file
    Vizkit.control log_replay
    #Vizkit.display log_replay.camera_bb2.right_frame
    #Vizkit.display log_replay.camera_bb2.left_frame
    #Vizkit.display stereo.disparity_frame
    #Vizkit.display DepthImage2Pointcloud.pointcloud
    Vizkit.display orb_slam2.features_map_out


    #start gui
    Vizkit.exec

    Readline::readline("Press enter to exit \n") do
    end
end
