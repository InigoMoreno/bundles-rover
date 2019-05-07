#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'unit_bb3', 'unit_bb2', 'unit_pancam', 'shutter_controller' do

    # Configure
    camera_firewire_bb3 = TaskContext.get 'camera_firewire_bb3'
    Orocos.conf.apply(camera_firewire_bb3, ['hdpr_bb3','altec_bb3_id'], :override => true)
    camera_firewire_bb3.configure

    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure
    
    pancam_left = Orocos.name_service.get 'pancam_left'
    Orocos.conf.apply(pancam_left, ['grashopper2_left'], :override => true)
    pancam_left.configure
    
    pancam_right = Orocos.name_service.get 'pancam_right'
    Orocos.conf.apply(pancam_right, ['grashopper2_right'], :override => true)
    pancam_right.configure

    shutter_controller_pancam = Orocos.name_service.get 'shutter_controller_pancam'
    Orocos.conf.apply(shutter_controller_pancam, ['default'], :override => true)
    shutter_controller_pancam.configure

    shutter_controller_bb3 = Orocos.name_service.get 'shutter_controller_bb3'
    Orocos.conf.apply(shutter_controller_bb3, ['bb3tenerife'], :override => true)
    shutter_controller_bb3.configure

    # Log
    logger_pancam = Orocos.name_service.get 'unit_pancam_Logger'
    logger_pancam.file = "pancam.log"
    logger_pancam.log(pancam_left.frame)
    logger_pancam.log(pancam_right.frame)
    logger_pancam.start
    
    logger_bb3 = Orocos.name_service.get 'unit_bb3_Logger'
    logger_bb3.file = "bb3.log"
    logger_bb3.log(camera_bb3.left_frame)
    logger_bb3.log(camera_bb3.center_frame)
    logger_bb3.log(camera_bb3.right_frame)
    logger_bb3.start

    camera_firewire_bb3.frame.connect_to         camera_bb3.frame_in
    camera_firewire_bb3.frame.connect_to         shutter_controller_bb3.frame
    camera_firewire_bb3.shutter_value.connect_to shutter_controller_bb3.shutter_value

    pancam_left.frame.connect_to shutter_controller_pancam.frame
    pancam_left.shutter_value.connect_to shutter_controller_pancam.shutter_value
    pancam_right.shutter_value.connect_to shutter_controller_pancam.shutter_value

    # Start
    camera_firewire_bb3.start
    camera_bb3.start
    pancam_left.start
    pancam_right.start
    shutter_controller_pancam.start
    shutter_controller_bb3.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
