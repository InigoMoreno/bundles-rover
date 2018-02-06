#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'unit_temperature' do
    # Configure
    temperature = TaskContext.get 'temperature'
    Orocos.conf.apply(temperature, ['default'], :override => true)
    temperature.configure

    # Log
    Orocos.log_all_configuration
    temperature.log_all_ports

    # Start
    temperature.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
