#! /usr/bin/env ruby

require 'orocos'
require 'orocos/log'
require 'rock/bundle'
require 'vizkit'


include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

## Transformation for the transformer
Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts_exoter.rb'))


Orocos.run 'stereo::Task' => 'stereo', 'camera_bb2::Task' => 'camera_bb2', 'viso2::StereoOdometer' => 'viso2' do
 
    #Orocos.log_all_ports 
    
    # declare logger of new ports
    logger = Orocos.name_service.get 'stereo_Logger'
    # new log destination
    logger.file = "rectifiedImages.log"
    
    # new components to run on top of the log
    stereo = Orocos.name_service.get 'stereo'
    Orocos.conf.apply(stereo, ['hdpr_bb2'], :override => true)
    camera_bb2 = Orocos.name_service.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['hdpr_bb2'], :override => true)

    visual_odometry = TaskContext.get 'viso2'
    Orocos.conf.apply(visual_odometry, ['default','bumblebee'], :override => true)
    Bundles.transformer.setup(visual_odometry)
    visual_odometry.configure

    # open log file to be postprocessed
    if ARGV.size == 0 then
		log_replay = Orocos::Log::Replay.open( "loccam.log")
    else
		log_replay = Orocos::Log::Replay.open(ARGV[0]+"loccam.log")
    end
    
    # uses timestamp when data was acquired
    log_replay.use_sample_time = true
    
     # new connection (either to logfed ports or new components
    log_replay.camera_firewire_loccam.frame.connect_to( camera_bb2.frame_in)


    # new connection (either to logfed ports or new components)
    camera_bb2.left_frame.connect_to( stereo.left_frame)
    camera_bb2.right_frame.connect_to( stereo.right_frame)
    
    camera_bb2.left_frame.connect_to                 visual_odometry.left_frame
    camera_bb2.right_frame.connect_to                visual_odometry.right_frame
 
    # data to be logged
	logger.log(stereo.left_frame_sync, 200)
	logger.log(stereo.right_frame_sync, 200)
    
    # start the components
    camera_bb2.configure
    stereo.configure
    camera_bb2.start
    stereo.start
    visual_odometry.start
        
    #logger.start
    
	#show the control widget for the log file
	Vizkit.control log_replay
	Vizkit.display camera_bb2.right_frame
	Vizkit.display camera_bb2.left_frame
	Vizkit.display stereo.disparity_frame
	#Vizkit.display DepthImage2Pointcloud.pointcloud
	
	
	#start gui
	Vizkit.exec

    Readline::readline("Press enter to exit \n") do
    end
end
