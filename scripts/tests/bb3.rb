#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_bb3' do

    # Configure
    camera_firewire_bb3 = TaskContext.get 'camera_firewire_bb3'
    Orocos.conf.apply(camera_firewire_bb3, ['bumblebee3'], :override => true)
    camera_firewire_bb3.configure

    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure
    
    stereo_bb3 = TaskContext.get 'stereo_bb3'
    Orocos.conf.apply(stereo_bb3, ['hdpr_bb3_left_right'], :override => true)
    stereo_bb3.configure

    # Log
    Orocos.log_all_ports
    
    # Connect
    camera_firewire_bb3.frame.connect_to camera_bb3.frame_in
    camera_bb3.left_frame.connect_to stereo_bb3.left_frame
    camera_bb3.right_frame.connect_to stereo_bb3.right_frame

    # Start
    camera_firewire_bb3.start
    camera_bb3.start
    stereo_bb3.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
