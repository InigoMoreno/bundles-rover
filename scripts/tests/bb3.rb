#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_bb3' do
    camera_firewire = TaskContext.get 'camera_firewire'
    Orocos.conf.apply(camera_firewire, ['bumblebee3'], :override => true)
    camera_firewire.configure
    
    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure

    # Log all ports
    Orocos.log_all_ports
    
    camera_firewire.frame.connect_to camera_bb3.frame_in

    camera_firewire.start
    camera_bb3.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
