#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_bb3', 'hdpr_unit_bb2', 'hdpr_unit_pancam' do

    # Configure
    camera_firewire_bb3 = TaskContext.get 'camera_firewire_bb3'
    Orocos.conf.apply(camera_firewire_bb3, ['bumblebee3'], :override => true)
    camera_firewire_bb3.configure

    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure
    
    camera_firewire_bb2 = TaskContext.get 'camera_firewire_bb2'
    Orocos.conf.apply(camera_firewire_bb2, ['bumblebee2'], :override => true)
    camera_firewire_bb2.configure

    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure
    
    pancam_left = Orocos.name_service.get 'pancam_left'
    Orocos.conf.apply(pancam_left, ['grashopper2_left'], :override => true)
    pancam_left.configure
    
    pancam_right = Orocos.name_service.get 'pancam_right'
    Orocos.conf.apply(pancam_right, ['grashopper2_right'], :override => true)
    pancam_right.configure

    # Log
    logger_pancam = Orocos.name_service.get 'hdpr_unit_pancam_Logger'
    logger_pancam.file = "pancam.log"
    logger_pancam.log(pancam_left.frame)
    logger_pancam.log(pancam_right.frame)
    logger_pancam.start
    
    logger_bb3 = Orocos.name_service.get 'hdpr_unit_bb3_Logger'
    logger_bb3.file = "bb3.log"
    logger_bb3.log(camera_bb3.left_frame)
    logger_bb3.log(camera_bb3.center_frame)
    logger_bb3.log(camera_bb3.right_frame)
    logger_bb3.start

    logger_bb2 = Orocos.name_service.get 'hdpr_unit_bb2_Logger'
    logger_bb2.file = "bb2.log"
    logger_bb2.log(camera_bb2.left_frame)
    logger_bb2.log(camera_bb2.right_frame)
    logger_bb2.start
    
    # Connect
    camera_firewire_bb3.frame.connect_to camera_bb3.frame_in
    camera_firewire_bb2.frame.connect_to camera_bb2.frame_in

    # Start
    camera_firewire_bb3.start
    camera_bb3.start
    camera_firewire_bb2.start
    camera_bb2.start
    pancam_left.start
    pancam_right.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
