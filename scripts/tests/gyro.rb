#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'gyro' do
    # Configure
    gyro = TaskContext.get 'dsp1760'
    Orocos.conf.apply(gyro, ['default'], :override => true)
    gyro.configure

    # Log the configuration (bias value)
    Orocos.configuration_log_name = "gyro_properties"
    Orocos.log_all_configuration

    # Log samples
    logger_gyro = Orocos.name_service.get 'gyro_Logger'
    logger_gyro.file = "gyro.log"
    logger_gyro.log(gyro.rotation)
    logger_gyro.log(gyro.orientation_samples)
    logger_gyro.log(gyro.bias_samples)
    logger_gyro.log(gyro.bias_values)
    logger_gyro.log(gyro.temperature)
    logger_gyro.log(gyro.sequence_counter)
    logger_gyro.start

    # Start
    gyro.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
