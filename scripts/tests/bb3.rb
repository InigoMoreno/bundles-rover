#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_bb3' do
    
    camera_firewire = TaskContext.get 'camera_firewire'
    Orocos.conf.apply(camera_firewire, ['bumblebee3'], :override => true)
    camera_firewire.configure
 
    #camera_bb2 = TaskContext.get 'camera_bb2'
    #Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    #camera_bb2.configure
        
    #loccam_stereo = TaskContext.get 'loccam_stereo'
    #Orocos.conf.apply(loccam_stereo, ['locCam'], :override => true)
    #loccam_stereo.configure

    # Log all ports
    Orocos.log_all_ports
    
    #loc_cam.frame.connect_to camera_bb2.frame_in 
    #camera_bb2.left_frame.connect_to loccam_stereo.left_frame 
    #camera_bb2.right_frame.connect_to loccam_stereo.right_frame 

    camera_firewire.start
    #camera_bb2.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
