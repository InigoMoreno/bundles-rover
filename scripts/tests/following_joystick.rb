#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'hdpr_unit_following' do

    # Configure
    joystick = Orocos.name_service.get 'joystick'
    joystick.device = "/dev/input/js0"
    begin
        joystick.configure
    rescue
        abort("Cannot configure the joystick, is the dongle connected to HDPR?")
    end
    
    motion_translator = Orocos.name_service.get 'motion_translator'
    motion_translator.configure
    
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['default'], :override => true)
    locomotion_control.configure
    
    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['commanding'], :override => true)
    command_joint_dispatcher.configure
    
    platform_driver = Orocos.name_service.get 'platform_driver'
    Orocos.conf.apply(platform_driver, ['default'], :override => true)
    platform_driver.configure
    
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['reading'], :override => true)
    read_joint_dispatcher.configure
    
    ptu_directedperception = Orocos.name_service.get 'ptu_directedperception'
    Orocos.conf.apply(ptu_directedperception, ['default'], :override => true)
    ptu_directedperception.configure

	 # setup Vicon
    puts "Setting up vicon"
    vicon = Orocos.name_service.get 'vicon'
    Orocos.conf.apply(vicon, ['default','hdpr'], :override => true)
    vicon.configure
    puts "done"
    
	 # setup Waypoint_navigation 
    puts "Setting up waypoint_navigation"
    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    Orocos.conf.apply(waypoint_navigation, ['hdpr'], :override => true)
    waypoint_navigation.configure
    puts "done"

    # setup command arbiter
    puts "Setting up command arbiter"
    command_arbiter = Orocos.name_service.get 'command_arbiter'
    Orocos.conf.apply(command_arbiter, ['default'], :override => true)
    command_arbiter.configure
    puts "done"
    
	# add the trajectory generation component
    puts "Setting up the trajectory generation"
    trajectoryGen = Orocos.name_service.get 'trajectoryGen'
    Orocos.conf.apply(trajectoryGen, ['hdprtest','prl'], :override => true)
    trajectoryGen.configure
    puts "done"

    # Log
    Orocos.log_all_ports
    
    # Connect
    joystick.raw_command.connect_to motion_translator.raw_command
    joystick.raw_command.connect_to command_arbiter.raw_command #
    # motion commands
    motion_translator.motion_command.connect_to   command_arbiter.joystick_motion_command #
    waypoint_navigation.motion_command.connect_to command_arbiter.follower_motion_command #
    command_arbiter.motion_command.connect_to     locomotion_control.motion_command 	  #
    # waypoint navigation inputs:
    vicon.pose_samples.connect_to 		waypoint_navigation.pose		#
    trajectoryGen.trajectory.connect_to waypoint_navigation.trajectory	#

    # joint and ptu commands
    locomotion_control.joints_commands.connect_to command_joint_dispatcher.joints_commands
    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to locomotion_control.joints_readings
    motion_translator.ptu_pan_angle.connect_to ptu_directedperception.pan_set
    motion_translator.ptu_tilt_angle.connect_to ptu_directedperception.tilt_set
    
    # Start
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    ptu_directedperception.start
    joystick.start
    motion_translator.start
    waypoint_navigation.start
    command_arbiter.start
    trajectoryGen.start
    vicon.start

    Readline::readline("Press ENTER to generate the trajectory.")
    trajectoryGen.trigger

    Readline::readline("Press Enter to exit\n") do
    end
end 
