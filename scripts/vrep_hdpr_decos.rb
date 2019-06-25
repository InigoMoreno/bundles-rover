# Simulation of HDPR on DECOS

require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

## Initialize orocos ##
Bundles.initialize

Orocos::Process.run 'unit_following', 'navigation', 'control', 'simulation', 'autonomy' do

  ## SETUP ##

  # setup locomotion_control
    puts "Setting up locomotion_control"
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['hdpr'], :override => true)
    locomotion_control.configure
    puts "done"

  # setup simulation_vrep
    puts "Setting up simulation_vrep"
    simulation_vrep = Orocos.name_service.get 'simulation'
    Orocos.conf.apply(simulation_vrep, ['hdpr'], :override => true)
    simulation_vrep.configure
    puts "done"

    if ARGV[0]=="noJoystick"
        puts "Joystick is not set up"
    else
      # setup joystick
        puts "Setting up joystick"
        joystick = Orocos.name_service.get 'joystick'
        Orocos.conf.apply(joystick, ['default', 'logitech_gamepad'], :override => true)
        joystick.configure
        puts "done"
    end

  # setup motion_translator
    puts "Setting up motion_translator"
    motion_translator = Orocos.name_service.get 'motion_translator'
    Orocos.conf.apply(motion_translator, ['hdpr'], :override => true)
    motion_translator.configure
    puts "done"

  # setup read_joint_dispatcher
    puts "Setting up reading joint_dispatcher"
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['hdpr_reading'], :override => true)
    read_joint_dispatcher.configure
    puts "done"

  # setup command_joint_dispatcher
    puts "Setting up commanding joint_dispatcher"
    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['hdpr_commanding'], :override => true)
    command_joint_dispatcher.configure
    puts "done"

  # setup waypoint_navigation
    puts "Setting up waypoint_navigation"
    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    Orocos.conf.apply(waypoint_navigation, ['default'], :override => true)
    waypoint_navigation.configure
    puts "done"

  # setup command_arbitrer
    puts "Setting up command arbiter"
    arbiter = Orocos.name_service.get 'command_arbiter'
    Orocos.conf.apply(arbiter, ['default'], :override => true)
    arbiter.configure
    puts "done"

  # setup path_planning
    puts "Setting up path planner"
    path_planner = Orocos.name_service.get 'path_planner'
    path_planner.keep_old_waypoints = true
    Orocos.conf.apply(path_planner, ['hdpr','decos'], :override => true)
    path_planner.configure
    puts "done"

  ## LOGGERS ##
  # Orocos.log_all_ports


  ## PORT CONNECTIONS ##
    puts "Connecting ports"

    simulation_vrep.pose.connect_to                       path_planner.pose
    simulation_vrep.goalWaypoint.connect_to               path_planner.goalWaypoint
    simulation_vrep.pose.connect_to                       waypoint_navigation.pose
    simulation_vrep.joints_readings.connect_to            read_joint_dispatcher.joints_readings

    path_planner.trajectory.connect_to                    simulation_vrep.trajectory
    path_planner.trajectory.connect_to	                  waypoint_navigation.trajectory

    locomotion_control.joints_commands.connect_to         command_joint_dispatcher.joints_commands
    command_joint_dispatcher.motors_commands.connect_to   simulation_vrep.joints_commands
    
    read_joint_dispatcher.motors_samples.connect_to       locomotion_control.joints_readings

    if ARGV[0] == "noJoystick"
        puts "Joystick Ports are not connected"
    else
        joystick.raw_command.connect_to                       motion_translator.raw_command
        joystick.raw_command.connect_to                       arbiter.raw_command
        motion_translator.motion_command.connect_to           arbiter.joystick_motion_command
    end
    waypoint_navigation.motion_command.connect_to         arbiter.follower_motion_command
    arbiter.motion_command.connect_to                     locomotion_control.motion_command

    simulation_vrep.start
    sleep 1
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    if ARGV[0] != "noJoystick"
        joystick.start
    end
    motion_translator.start
    arbiter.start
    waypoint_navigation.start
    path_planner.start

    Readline::readline("Press ENTER to exit\n")
end
