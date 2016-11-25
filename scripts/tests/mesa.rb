#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_mesa' do

    # Configure
    tofcamera_mesasr = TaskContext.get 'tofcamera_mesasr'
    Orocos.conf.apply(tofcamera_mesasr, ['default'], :override => true)
    tofcamera_mesasr.configure

    # Log
    Orocos.log_all_ports

    # Start
    tofcamera_mesasr.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
