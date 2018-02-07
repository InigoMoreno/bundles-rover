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
Orocos::Process.run 'unit_mesa' do

    # Configure
    tofcamera_mesasr = TaskContext.get 'tofcamera_mesasr'
    Orocos.conf.apply(tofcamera_mesasr, ['hdpr'], :override => true)
    tofcamera_mesasr.configure

    # Log
    #Orocos.log_all
    #Orocos.log_all_configuration
    
    # Log a single value to a custom lof file
    logfile = Pocolog::Logfiles.create(File.expand_path('tof_properties', Bundles.log_dir))
    property = tofcamera_mesasr.property('integration_time')
    property.log_stream = logfile.create_stream "integration_time", property.type, property.name
    # Force output of the current properties, otherwise it will only log values when the properties change
    property.log_current_value
    
    # Start
    tofcamera_mesasr.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
