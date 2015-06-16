#!/usr/bin/env ruby

require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

Orocos::Process.run 'exoter_perception' do

    # Camera firewire grasshopper left
    grashopper2_left = TaskContext.get 'camera_firewire_left'
    Orocos.conf.apply(grashopper2_left, ['grashopper2_left'], :override => true)
    grashopper2_left.configure

    # Camera firewire grasshopper right
    grashopper2_right = TaskContext.get 'camera_firewire_right'
    Orocos.conf.apply(grashopper2_right, ['grashopper2_right'], :override => true)
    grashopper2_right.configure
    

    # Log all ports
    Orocos.log_all_ports

    # Start the tasks
    grashopper2_left.start
    grashopper2_right.start

    Readline::readline("Press ENTER to exit\n") do
    end
end
