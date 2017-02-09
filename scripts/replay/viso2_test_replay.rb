#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'transformer/runtime'
require 'vizkit'
include Orocos

Bundles.initialize
Bundles.transformer.load_conf(Bundles.find_file('config', 'hdpr_transformations.rb'))

Orocos::Process.run 'hdpr_unit_visual_odometry' do

    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure
    
    visual_odometry = TaskContext.get 'viso2'
    Orocos.conf.apply(visual_odometry, ['bumblebee'], :override => true)
    visual_odometry.configure

    # Connect the tasks to the logs
    if ARGV.size == 1 then
        log_replay = Orocos::Log::Replay.open(ARGV[0] + "bb2.log")
    end

    # Connect
    log_replay.camera_firewire_bb2.frame.connect_to camera_bb2.frame_in
    
    camera_bb2.left_frame.connect_to visual_odometry.left_frame
    camera_bb2.right_frame.connect_to visual_odometry.right_frame

    # Start
    camera_bb2.start
    visual_odometry.start

    # Open the log replay widget
    control = Vizkit.control log_replay
    control.speed = 1
    
    Vizkit.exec
end
