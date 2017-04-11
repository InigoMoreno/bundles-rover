#! /usr/bin/env ruby

require 'orocos'
require 'orocos/log'
require 'rock/bundle'
require 'vizkit'


include Orocos

Bundles.initialize

Orocos.run 'stereo::Task' => 'stereo'do
 
    #Orocos.log_all_ports 
    
    # declare logger of new ports
    logger = Orocos.name_service.get 'stereo_Logger'
    # new log destination
    logger.file = "rectifiedImages.log"
    
    # new components to run on top of the log
    stereo = Orocos.name_service.get 'stereo'
    Orocos.conf.apply(stereo, ['panCam'], :override => true)

    # open log file to be postprocessed
    if ARGV.size == 0 then
		log_replay = Orocos::Log::Replay.open( "pancam.log")
    else
		log_replay = Orocos::Log::Replay.open(ARGV[0]+"pancam.log")
    end
    
    # uses timestamp when data was acquired
    log_replay.use_sample_time = true
    
    # new connection (either to logfed ports or new components)
    log_replay.pancam_panorama.left_frame_out.connect_to( stereo.left_frame)
    log_replay.pancam_panorama.right_frame_out.connect_to( stereo.right_frame)
    log_replay.shutter_controller.shutter_value    
    
    # data to be logged
	logger.log(stereo.left_frame_sync, 200)
	logger.log(stereo.right_frame_sync, 200)
    
    # start the components
    stereo.configure
    stereo.start
        
    #logger.start
    
	#show the control widget for the log file
	Vizkit.control log_replay
	#Vizkit.display log_replay.camera_bb2.right_frame
	#Vizkit.display log_replay.camera_bb2.left_frame
	Vizkit.display stereo.disparity_frame
	#Vizkit.display DepthImage2Pointcloud.pointcloud
	
	
	#start gui
	Vizkit.exec

    Readline::readline("Press enter to exit \n") do
    end
end
