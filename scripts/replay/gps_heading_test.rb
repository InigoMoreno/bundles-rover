#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'vizkit'
include Orocos

Bundles.initialize

Orocos::Process.run 'hdpr_gps_heading' do
    
    gps_heading = TaskContext.get 'gps_heading'
    Orocos.conf.apply(gps_heading, ['default'], :override => true)
    gps_heading.configure

    # Connect the tasks to the logs
    if ARGV.size == 1 then
        log_replay = Orocos::Log::Replay.open(ARGV[0] + "control2.log", ARGV[0] + "gps.log", ARGV[0] + "imu.log")
    end
    
    Orocos.log_all_ports

    log_replay.use_sample_time = true
 
    # Connect
    log_replay.gps.pose_samples.connect_to                    gps_heading.gps_pose_samples
    log_replay.imu_stim300.orientation_samples_out.connect_to gps_heading.imu_pose_samples
    log_replay.gps.raw_data.connect_to                        gps_heading.gps_raw_data
    # Motion command is not timestamped and cannot be used in the replay
    log_replay.command_arbiter.motion_command.connect_to      gps_heading.motion_command

    # Start
    gps_heading.start

    # Open the log replay widget
    control = Vizkit.control log_replay
    control.speed = 10
    
    Vizkit.exec
end
