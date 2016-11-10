#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'imu_stim300::Task' => 'imu_stim300' do
    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'HDPR', 'ESTEC', 'stim300_5g'], :override => true)
    
    imu_stim300.configure

    # Log all ports
    Orocos.log_all_ports

    imu_stim300.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
