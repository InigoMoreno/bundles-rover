#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
require 'pocolog'
include Pocolog
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'tof' do

    # Configure
    tofcamera_mesasr = TaskContext.get 'tofcamera_mesasr'
    Orocos.conf.apply(tofcamera_mesasr, ['hdpr'], :override => true)
    tofcamera_mesasr.configure

    # Start
    tofcamera_mesasr.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
