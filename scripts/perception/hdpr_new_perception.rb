#!/usr/bin/env ruby

require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

Orocos::Process.run 'exoter_perception' do

    # Camera firewire grasshopper left
    grashopper2_left = TaskContext.get 'camera_firewire_left'
    Orocos.conf.apply(grashopper2_left, ['grashopper2_left'], :override => true)
    grashopper2_left.configure

    # Camera firewire grasshopper right
    grashopper2_right = TaskContext.get 'camera_firewire_right'
    Orocos.conf.apply(grashopper2_right, ['grashopper2_right'], :override => true)
    grashopper2_right.configure
    
    # Camera firewire for bb2
#    camera_firewire = TaskContext.get 'camera_firewire'
#    Orocos.conf.apply(camera_firewire, ['default'], :override => true)
#    camera_firewire.configure

    # Camera bb2
    #camera_bb2 = TaskContext.get 'camera_bb2'
    #Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    #camera_bb2.configure

    # Camera bb2
    hdpr_pancam = TaskContext.get 'hdpr_pancam'
    Orocos.conf.apply(hdpr_pancam, ['default'], :override => true)
    hdpr_pancam.configure

    # Log all ports
    Orocos.log_all_ports

    # Connect the ports
    grashopper2_left.frame.connect_to hdpr_pancam.left_frame_in
    grashopper2_right.frame.connect_to hdpr_pancam.right_frame_in

    # Start the tasks
#    camera_firewire.start
#    camera_bb2.start
    grashopper2_left.start
    grashopper2_right.start
    hdpr_pancam.start

    Readline::readline("Press ENTER to exit\n") do
    end
end
