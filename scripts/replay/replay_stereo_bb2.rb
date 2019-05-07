#! /usr/bin/env ruby

require 'orocos'
require 'orocos/log'
require 'rock/bundle'
require 'vizkit'


include Orocos

Bundles.initialize

Orocos.run 'stereo::Task' => 'stereo', 'camera_bb2::Task' => 'camera_bb2'do
 
    #Orocos.log_all_ports 
    
    # declare logger of new ports
    logger = Orocos.name_service.get 'stereo_Logger'
    # new log destination
    logger.file = "rectifiedImages.log"
    
    # new components to run on top of the log
    stereo = Orocos.name_service.get 'stereo'
    Orocos.conf.apply(stereo, ['hdpr_bb2'], :override => true)
    camera_bb2 = Orocos.name_service.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)

    # open log file to be postprocessed
    if ARGV.size == 0 then
		log_replay = Orocos::Log::Replay.open( "bb2.log")
    else
		log_replay = Orocos::Log::Replay.open(ARGV[0]+"bb2.log")
    end
    
    # uses timestamp when data was acquired
    log_replay.use_sample_time = true
    
     # new connection (either to logfed ports or new components
    log_replay.camera_firewire_bb2.frame.connect_to( camera_bb2.frame_in)


    # new connection (either to logfed ports or new components)
    camera_bb2.left_frame.connect_to( stereo.left_frame)
    camera_bb2.right_frame.connect_to( stereo.right_frame)
    
    
    # data to be logged
	logger.log(stereo.left_frame_sync, 200)
	logger.log(stereo.right_frame_sync, 200)
    
    # start the components
    camera_bb2.configure
    stereo.configure
    camera_bb2.start
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
