#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
require 'transformer/runtime'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_visual_odometry' do

    # Configure
    camera_firewire_bb2 = TaskContext.get 'camera_firewire_bb2'
    Orocos.conf.apply(camera_firewire_bb2, ['bumblebee2'], :override => true)
    camera_firewire_bb2.configure

    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure
    
    visual_odometry = TaskContext.get 'viso2'
    Orocos.conf.apply(visual_odometry, ['bumblebee'], :override => true)
    visual_odometry.configure
    
    # Log
    #Orocos.log_all_ports

    # Connect
    camera_firewire_bb2.frame.connect_to camera_bb2.frame_in
    camera_bb2.left_frame.connect_to visual_odometry.left_frame
    camera_bb2.left_frame.connect_to visual_odometry.right_frame

    # Start
    camera_firewire_bb2.start
    camera_bb2.start
    visual_odometry.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
