#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_bb2' do

    loc_cam = TaskContext.get 'loc_cam'
    Orocos.conf.apply(loc_cam, ['default'], :override => true)
    loc_cam.configure

    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure
    
    loccam_stereo = TaskContext.get 'loccam_stereo'
    Orocos.conf.apply(loccam_stereo, ['locCam'], :override => true)
    loccam_stereo.configure

    # Log all ports
    Orocos.log_all_ports
    
    loc_cam.frame.connect_to camera_bb2.frame_in
    camera_bb2.left_frame.connect_to loccam_stereo.left_frame
    camera_bb2.right_frame.connect_to loccam_stereo.right_frame

    loc_cam.start
    camera_bb2.start
    loccam_stereo.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
