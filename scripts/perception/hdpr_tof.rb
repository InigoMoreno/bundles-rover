#!/usr/bin/env ruby
require 'orocos'
require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

Orocos::Process.run 'exoter_perception' do

    # Camera tof
    camera_tof = TaskContext.get 'camera_tof'
    Orocos.conf.apply(camera_tof, ['default'], :override => true)
    camera_tof.configure

    # Log all ports
    Orocos.log_all_ports

    camera_tof.start

    Readline::readline("Press ENTER to exit\n") do
    end
end
