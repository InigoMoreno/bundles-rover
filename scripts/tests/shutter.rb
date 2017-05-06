#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
#require 'vizkit'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_shutter_controller' do

    # Configure
    pancam_left = Orocos.name_service.get 'pancam_left'
    Orocos.conf.apply(pancam_left, ['grashopper2_left'], :override => true)
    pancam_left.configure
    
    pancam_right = Orocos.name_service.get 'pancam_right'
    Orocos.conf.apply(pancam_right, ['grashopper2_right'], :override => true)
    pancam_right.configure
    
    stereo_pancam = Orocos.name_service.get 'stereo_pancam'
    Orocos.conf.apply(stereo_pancam, ['panCam'], :override => true)
    stereo_pancam.configure

    shutter_controller = Orocos.name_service.get 'shutter_controller'
    Orocos.conf.apply(shutter_controller, ['default'], :override => true)
    #Orocos.conf.apply(shutter_controller, ['bright'], :override => true)
    shutter_controller.configure
    
    #stereo_pancam.log_all_ports
    
    # Connect
    pancam_left.frame.connect_to stereo_pancam.left_frame
    pancam_right.frame.connect_to stereo_pancam.right_frame

    pancam_left.frame.connect_to shutter_controller.frame
    pancam_left.shutter_value.connect_to shutter_controller.shutter_value
    pancam_right.shutter_value.connect_to shutter_controller.shutter_value
    
    # Start
    pancam_left.start
    pancam_right.start
    stereo_pancam.start
    shutter_controller.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end

