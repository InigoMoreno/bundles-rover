#!/usr/bin/env ruby

require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

Orocos::Process.run 'exoter_perception' do

    # Camera firewire
    grashopper2_right = TaskContext.get 'camera_firewire'
    Orocos.conf.apply(grashopper2_right, ['grashopper2_right'], :override => true)
    grashopper2_right.configure

    # Log all ports
    Orocos.log_all_ports

    # Start the tasks
    grashopper2_right.start

    Readline::readline("Press ENTER to exit\n") do
    end
end
