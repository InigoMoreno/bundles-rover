#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'gnss_trimble::Task' => 'gps' do
    gps = TaskContext.get 'gps'
    Orocos.conf.apply(gps, ['HDPR', 'Netherlands', 'ESTEC'], :override => true)
    
    gps.configure

    # Log all ports
    Orocos.log_all_ports

    gps.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
