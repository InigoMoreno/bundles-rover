#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_pancam' do

    # Configure
    pancam_right = Orocos.name_service.get 'pancam_right'
    Orocos.conf.apply(pancam_right, ['grashopper2_right'], :override => true)
    pancam_right.configure

    # Log
    logger_pancam = Orocos.name_service.get 'hdpr_unit_pancam_Logger'
    logger_pancam.file = "pancam.log"
    logger_pancam.log(pancam_right.frame)
    logger_pancam.start
    
    # Start
    pancam_right.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
