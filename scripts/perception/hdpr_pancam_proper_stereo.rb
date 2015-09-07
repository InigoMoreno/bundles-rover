#!/usr/bin/env ruby

require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

Orocos::Process.run 'hdpr_perception' do

    # Camera firewire grasshopper left
    grashopper2_left = TaskContext.get 'pancam_left' # This name is defined in the hdpr_deployment 
    Orocos.conf.apply(grashopper2_left, ['grashopper2_left'], :override => true) # This is a setting in "bundle hdpr config"
    grashopper2_left.configure

    # Camera firewire grasshopper right
    grashopper2_right = TaskContext.get 'pancam_right'
    Orocos.conf.apply(grashopper2_right, ['grashopper2_right'], :override => true)
    grashopper2_right.configure

    # Camera Stereo
    pancam_stereo = TaskContext.get 'pancam_stereo'
    Orocos.conf.apply(pancam_stereo, ['default'], :override => true)
    pancam_stereo.configure

    camera_firewire = TaskContext.get 'camera_firewire'
    Orocos.conf.apply(camera_firewire, ['default'], :override => true)
    camera_firewire.configure

    # Camera bb2
    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure

    # stereo
    grashopper2_left.frame.connect_to pancam_stereo.left_frame #, :type => :buffer, :size => 1
    grashopper2_right.frame.connect_to pancam_stereo.right_frame #, :type => :buffer, :size => 1
    camera_firewire.frame.connect_to camera_bb2.frame_in

    # Camera tof
    camera_tof = TaskContext.get 'camera_tof'
    Orocos.conf.apply(camera_tof, ['default'], :override => true)
    camera_tof.configure

    # Start the tasks
    grashopper2_left.start
    grashopper2_right.start
    pancam_stereo.start
    camera_firewire.start
    camera_bb2.start
    camera_tof.start
    

    #Orocos.log_all_ports


    Readline::readline("Press ENTER to exit\n") do
    end
end
