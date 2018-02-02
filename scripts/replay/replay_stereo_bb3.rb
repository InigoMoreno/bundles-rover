#! /usr/bin/env ruby

require 'orocos'
require 'orocos/log'
require 'rock/bundle'
require 'vizkit'


include Orocos

Bundles.initialize

Orocos.run 'stereo::Task' => 'stereo', 'camera_bb3::Task' => 'camera_bb3' do

    #Orocos.log_all_ports 

    # declare logger of new ports
    logger = Orocos.name_service.get 'stereo_Logger'
    # new log destination
    logger.file = "rectifiedImages.log"

    # new components to run on top of the log
    stereo = Orocos.name_service.get 'stereo'
    Orocos.conf.apply(stereo, ['hdpr_bb3_left_right'], :override => true)
    camera_bb3 = Orocos.name_service.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)

    # open log file to be postprocessed
    if ARGV.size == 0 then
        log_replay = Orocos::Log::Replay.open("bb3.log")
    else
        log_replay = Orocos::Log::Replay.open(ARGV[0]+"bb3.log")
    end

    # uses timestamp when data was acquired
    log_replay.use_sample_time = true

    # new connection (either to logfed ports or new components
    log_replay.camera_firewire_bb3.frame.connect_to(camera_bb3.frame_in)

    # new connection (either to logfed ports or new components)
    camera_bb3.left_frame.connect_to(stereo.left_frame)
    camera_bb3.right_frame.connect_to(stereo.right_frame)

    # data to be logged
    logger.log(stereo.left_frame_sync, 200)
    logger.log(stereo.right_frame_sync, 200)

    # start the components
    camera_bb3.configure
    stereo.configure
    camera_bb3.start
    stereo.start

    #logger.start

    #show the control widget for the log file
    Vizkit.control log_replay
    Vizkit.display camera_bb3.right_frame
    #Vizkit.display log_replay.camera_bb3.left_frame
    Vizkit.display stereo.disparity_frame
    #Vizkit.display DepthImage2Pointcloud.pointcloud


    #start gui
    Vizkit.exec

    Readline::readline("Press enter to exit \n") do
    end
end
