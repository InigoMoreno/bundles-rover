#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_bb2', 'hdpr_unit_mesa' do

    # Configure
    camera_firewire_bb2 = TaskContext.get 'camera_firewire_bb2'
    Orocos.conf.apply(camera_firewire_bb2, ['bumblebee2'], :override => true)
    camera_firewire_bb2.configure

    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure
    
    tofcamera_mesasr = TaskContext.get 'tofcamera_mesasr'
    Orocos.conf.apply(tofcamera_mesasr, ['default'], :override => true)
    tofcamera_mesasr.configure

    # Log
    logger_bb2 = Orocos.name_service.get 'hdpr_unit_bb2_Logger'
    logger_bb2.file = "bb2.log"
    logger_bb2.log(camera_bb2.left_frame)
    logger_bb2.log(camera_bb2.right_frame)
    logger_bb2.start
    
    logger_tof = Orocos.name_service.get 'hdpr_unit_mesa_Logger'
    logger_tof.file = "tof.log"
    logger_tof.log(tofcamera_mesasr.ir_frame)
    logger_tof.start
    
    # Connect
    camera_firewire_bb2.frame.connect_to camera_bb2.frame_in

    # Start
    camera_firewire_bb2.start
    camera_bb2.start
    tofcamera_mesasr.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
