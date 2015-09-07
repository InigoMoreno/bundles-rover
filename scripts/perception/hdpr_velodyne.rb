#!/usr/bin/env ruby
require 'orocos'
require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

Orocos::Process.run 'exoter_perception' do

    # Velodyne Lidar
    velodyne_lidar = TaskContext.get 'velodyne_lidar'
    Orocos.conf.apply(velodyne_lidar, ['default'], :override => true)
    velodyne_lidar.configure

    # Log all ports
    Orocos.log_all_ports

    velodyne_lidar.start

    Readline::readline("Press ENTER to exit\n") do
    end
end
