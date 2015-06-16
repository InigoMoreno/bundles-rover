#!/usr/bin/env ruby

require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

Orocos::Process.run 'exoter_perception' do

    # Camera firewire
    grashopper2_left = TaskContext.get 'camera_firewire'
    Orocos.conf.apply(grashopper2_left, ['grashopper2_left'], :override => true)
    grashopper2_left.configure
  
    # Log all ports
    Orocos.log_all_ports

    # Start the tasks
    grashopper2_left.start

    Readline::readline("Press ENTER to exit\n") do
    end
end
