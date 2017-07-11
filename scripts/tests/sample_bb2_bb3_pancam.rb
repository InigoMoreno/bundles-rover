#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_bb3', 'hdpr_unit_bb2', 'hdpr_unit_pancam', 'hdpr_unit_shutter_controller', 'hdpr_shutter_controller_bumblebee' do

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

    shutter_controller = Orocos.name_service.get 'shutter_controller'
    Orocos.conf.apply(shutter_controller, ['default'], :override => true)
    shutter_controller.configure

    shutter_controller_bb2 = Orocos.name_service.get 'shutter_controller_bb2'
    Orocos.conf.apply(shutter_controller_bb2, ['bb2tenerife'], :override => true)
    shutter_controller_bb2.configure

    shutter_controller_bb3 = Orocos.name_service.get 'shutter_controller_bb3'
    Orocos.conf.apply(shutter_controller_bb3, ['bb3tenerife'], :override => true)
    shutter_controller_bb3.configure

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
    camera_firewire_bb3.frame.connect_to                shutter_controller_bb3.frame
    camera_firewire_bb3.shutter_value.connect_to        shutter_controller_bb3.shutter_value

    camera_firewire_bb2.frame.connect_to camera_bb2.frame_in
    camera_firewire_bb2.frame.connect_to                shutter_controller_bb2.frame
    camera_firewire_bb2.shutter_value.connect_to        shutter_controller_bb2.shutter_value

    pancam_left.frame.connect_to shutter_controller.frame
    pancam_left.shutter_value.connect_to shutter_controller.shutter_value
    pancam_right.shutter_value.connect_to shutter_controller.shutter_value

    # Start
    camera_firewire_bb3.start
    camera_bb3.start
    camera_firewire_bb2.start
    camera_bb2.start
    pancam_left.start
    pancam_right.start
    shutter_controller.start
    shutter_controller_bb2.start
    shutter_controller_bb3.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
