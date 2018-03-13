#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
require 'optparse'
#require 'vizkit'
include Orocos

# Command line options for the script, default values
options = {:nav => true, :pan => true, :v => true, :loc => true}

# Options parser
OptionParser.new do |opts|
  opts.banner = "Usage: start.rb [options]"
  opts.on('-nav', '--nav state', 'Enable/disable NavCam camera') { |state| options[:nav] = state }
  opts.on('-pan', '--pan state', 'Enable/disable PanCam camera') { |state| options[:pan] = state }
  opts.on('-v', '--vicon state', 'Enable/disable Vicon') { |state| options[:v] = state }
  opts.on('-loc', '--loc state', 'Enable/disable LocCam camera') { |state| options[:loc] = state }
end.parse!

# Initialize bundles to find the configurations for the packages
Bundles.initialize

## Transformation for the transformer
Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts.rb'))

# Execute the task
Orocos::Process.run 'control', 'pancam_bb3', 'navcam', 'loccam', 'imu', 'tmtchandling', 'unit_vicon', 'navigation'  do
    joystick = Orocos.name_service.get 'joystick'
    # Set the joystick input
    joystick.device = "/dev/input/js0"
    # In case the dongle is not connected exit gracefully
    begin
        # Configure the joystick
        Orocos.conf.apply(joystick, ['default'], :override => true)
        joystick.configure
    rescue
        # Abort the process as there is no joystick to get input from
        abort("Cannot configure the joystick, is the dongle connected to ExoTeR?")
    end
    
    # Configure the control packages
    motion_translator = Orocos.name_service.get 'motion_translator'
    Orocos.conf.apply(motion_translator, ['exoter'], :override => true)
    motion_translator.configure
    
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['exoter'], :override => true)
    locomotion_control.configure
    
    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['exoter_commanding'], :override => true)
    command_joint_dispatcher.configure
    
    platform_driver = Orocos.name_service.get 'platform_driver'
    Orocos.conf.apply(platform_driver, ['exoter'], :override => true)
    platform_driver.configure
    
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['exoter_reading'], :override => true)
    read_joint_dispatcher.configure
    
    ptu_control = Orocos.name_service.get 'ptu_control'
    Orocos.conf.apply(ptu_control, ['default'], :override => true)
    ptu_control.configure
  
    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'exoter', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure
    
    if options[:v] == true
	vicon = TaskContext.get 'vicon'
        Orocos.conf.apply(vicon, ['default','exoter'], :override => true)
        vicon.configure
    else
	# use visodom or gps if outdoors
    end	

    if options[:nav] == true
        puts "Starting NavCam"
    
        camera_firewire_navcam = TaskContext.get 'camera_firewire_navcam'
        Orocos.conf.apply(camera_firewire_navcam, ['exoter_bb2'], :override => true)
        camera_firewire_navcam.configure
    
        camera_navcam = TaskContext.get 'camera_navcam'
        Orocos.conf.apply(camera_navcam, ['exoter_bb2'], :override => true)
        camera_navcam.configure

        trigger_navcam = TaskContext.get 'trigger_navcam'
       
        stereo_navcam = TaskContext.get 'stereo_navcam'
        Orocos.conf.apply(stereo_navcam, ['exoter_bb2'], :override => true)
        stereo_navcam.configure
    
        dem_generation_navcam = TaskContext.get 'dem_generation_navcam'
        Orocos.conf.apply(dem_generation_navcam, ['exoter_bb2'], :override => true)
        dem_generation_navcam.configure
    end

    if options[:loc] == true
        puts "Starting LocCam"
    
        camera_firewire_loccam = TaskContext.get 'camera_firewire_loccam'
        Orocos.conf.apply(camera_firewire_loccam, ['exoter_bb2_b'], :override => true)
        camera_firewire_loccam.configure
    
        camera_loccam = TaskContext.get 'camera_loccam'
        Orocos.conf.apply(camera_loccam, ['hdpr_bb2'], :override => true)
        camera_loccam.configure

        trigger_loccam = TaskContext.get 'trigger_loccam'
       
        stereo_loccam = TaskContext.get 'stereo_loccam'
        Orocos.conf.apply(stereo_loccam, ['hdpr_bb2'], :override => true)
        stereo_loccam.configure
    
        dem_generation_loccam = TaskContext.get 'dem_generation_loccam'
        Orocos.conf.apply(dem_generation_loccam, ['hdpr_bb2'], :override => true)
        dem_generation_loccam.configure
    end

    if options[:pan] == true
        puts "Starting PanCam"
        
        camera_firewire_pancam = TaskContext.get 'camera_firewire_pancam'
        Orocos.conf.apply(camera_firewire_pancam, ['exoter_bb3'], :override => true)
        camera_firewire_pancam.configure
        
        camera_pancam = TaskContext.get 'camera_pancam'
        Orocos.conf.apply(camera_pancam, ['default'], :override => true)
        camera_pancam.configure

        trigger_pancam = TaskContext.get 'trigger_pancam'

        stereo_pancam = TaskContext.get 'stereo_pancam'
        Orocos.conf.apply(stereo_pancam, ['bb3_left_right'], :override => true)
        stereo_pancam.configure
    
        dem_generation_pancam = TaskContext.get 'dem_generation_pancam'
        Orocos.conf.apply(dem_generation_pancam, ['exoter_bb3'], :override => true)
        dem_generation_pancam.configure

        pancam_360 = Orocos.name_service.get 'pancam_360'
        Orocos.conf.apply(pancam_360, ['default', 'separation_40_x'], :override => true)
        pancam_360.configure
        
        trigger_pancam_360 = TaskContext.get 'trigger_pancam_360'
    end
  
    # Setup Waypoint_navigation 
    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    Orocos.conf.apply(waypoint_navigation, ['default','exoter'], :override => true)
    waypoint_navigation.configure

    # Setup command arbiter
    command_arbiter = Orocos.name_service.get 'command_arbiter'
    Orocos.conf.apply(command_arbiter, ['default'], :override => true)
    command_arbiter.configure  
	    
    # setup telemetry_telecommand
    telemetry_telecommand = Orocos.name_service.get 'telemetry_telecommand'
    Orocos.conf.apply(telemetry_telecommand, ['default'], :override => true)
    Bundles.transformer.setup(telemetry_telecommand)
    telemetry_telecommand.configure
   
    # Configure the connections between the components
    joystick.raw_command.connect_to                     motion_translator.raw_command
    joystick.raw_command.connect_to                     command_arbiter.raw_command

    #motion_translator.ptu_command.connect_to            ptu_control.ptu_joints_commands
    motion_translator.motion_command.connect_to         command_arbiter.joystick_motion_command
    waypoint_navigation.motion_command.connect_to       command_arbiter.follower_motion_command
    command_arbiter.motion_command.connect_to           locomotion_control.motion_command
    
    locomotion_control.joints_commands.connect_to       command_joint_dispatcher.joints_commands
    ptu_control.ptu_commands_out.connect_to             command_joint_dispatcher.ptu_commands
    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to          read_joint_dispatcher.joints_readings
    read_joint_dispatcher.motors_samples.connect_to     locomotion_control.joints_readings
    read_joint_dispatcher.ptu_samples.connect_to        ptu_control.ptu_samples
    
    if options[:nav] == true
        camera_firewire_navcam.frame.connect_to         camera_navcam.frame_in
        camera_navcam.left_frame.connect_to             trigger_navcam.frame_left_in
        camera_navcam.right_frame.connect_to            trigger_navcam.frame_right_in
        trigger_navcam.frame_left_out.connect_to        stereo_navcam.left_frame
        trigger_navcam.frame_right_out.connect_to       stereo_navcam.right_frame
        trigger_navcam.frame_left_out.connect_to        dem_generation_navcam.left_frame_rect
        stereo_navcam.distance_frame.connect_to         dem_generation_navcam.distance_frame

        telemetry_telecommand.front_trigger.connect_to      trigger_navcam.telecommand_in
        trigger_navcam.telecommands_out.connect_to          dem_generation_navcam.telecommands_in
        dem_generation_navcam.telemetry_out.connect_to      telemetry_telecommand.telemetry_product, :type => :buffer, :size => 10
        # Configure the sensor trigger after the ports are connected
        trigger_navcam.configure
    end

    if options[:loc] == true
        camera_firewire_loccam.frame.connect_to         camera_loccam.frame_in
        camera_loccam.left_frame.connect_to             trigger_loccam.frame_left_in
        camera_loccam.right_frame.connect_to            trigger_loccam.frame_right_in
        trigger_loccam.frame_left_out.connect_to        stereo_loccam.left_frame
        trigger_loccam.frame_right_out.connect_to       stereo_loccam.right_frame
        trigger_loccam.frame_left_out.connect_to        dem_generation_loccam.left_frame_rect
        stereo_loccam.distance_frame.connect_to         dem_generation_loccam.distance_frame
        telemetry_telecommand.haz_front_trigger.connect_to  trigger_loccam.telecommand_in

        trigger_loccam.telecommands_out.connect_to          dem_generation_loccam.telecommands_in
        dem_generation_loccam.telemetry_out.connect_to      telemetry_telecommand.telemetry_product, :type => :buffer, :size => 10
        # Configure the sensor trigger after the ports are connected
        trigger_loccam.configure
    end

    if options[:pan] == true
        camera_firewire_pancam.frame.connect_to         camera_pancam.frame_in
        camera_pancam.left_frame.connect_to             trigger_pancam.frame_left_in
        camera_pancam.right_frame.connect_to            trigger_pancam.frame_right_in
        trigger_pancam.frame_left_out.connect_to        stereo_pancam.left_frame
        trigger_pancam.frame_right_out.connect_to       stereo_pancam.right_frame
        trigger_pancam.frame_left_out.connect_to        dem_generation_pancam.left_frame_rect
        stereo_pancam.distance_frame.connect_to         dem_generation_pancam.distance_frame

        pancam_360.pan_angle_in.connect_to                  ptu_control.pan_samples_out
        pancam_360.tilt_angle_in.connect_to                 ptu_control.tilt_samples_out
        pancam_360.pan_angle_out.connect_to                 ptu_control.pan_command_in
        pancam_360.tilt_angle_out.connect_to                ptu_control.tilt_command_in
        camera_pancam.left_frame.connect_to                 pancam_360.left_frame_in
        camera_pancam.right_frame.connect_to                pancam_360.right_frame_in

        pancam_360.left_frame_out.connect_to                trigger_pancam_360.frame_left_in
        pancam_360.right_frame_out.connect_to               trigger_pancam_360.frame_right_in
        trigger_pancam_360.frame_left_out.connect_to        stereo_pancam.left_frame
        trigger_pancam_360.frame_right_out.connect_to       stereo_pancam.right_frame
        trigger_pancam_360.frame_left_out.connect_to        dem_generation_pancam.left_frame_rect
        dem_generation_pancam.sync_out.connect_to	        pancam_360.sync_in

        telemetry_telecommand.mast_trigger.connect_to       trigger_pancam.telecommand_in
        telemetry_telecommand.pancam_360_trigger.connect_to trigger_pancam_360.telecommand_in
        telemetry_telecommand.panorama_tilt.connect_to      pancam_360.trigger_tilt

        trigger_pancam.telecommands_out.connect_to          dem_generation_pancam.telecommands_in
        trigger_pancam_360.telecommands_out.connect_to      dem_generation_pancam.telecommands_in
        dem_generation_pancam.telemetry_out.connect_to      telemetry_telecommand.telemetry_product, :type => :buffer, :size => 10
        # Configure the sensor trigger after the ports are connected
        trigger_pancam.configure
        trigger_pancam_360.configure
    end

    if options[:v] == false
        # use visodom or gps outdoors
    else
    	vicon.pose_samples.connect_to             	waypoint_navigation.pose
    	vicon.pose_samples.connect_to             	telemetry_telecommand.current_pose
    	puts "using vicon"
    end

    # Telemetry Telecommand connections
    telemetry_telecommand.locomotion_command.connect_to locomotion_control.motion_command
    telemetry_telecommand.mast_pan.connect_to           ptu_control.pan_command_in
    telemetry_telecommand.mast_tilt.connect_to          ptu_control.tilt_command_in
    telemetry_telecommand.trajectory.connect_to         waypoint_navigation.trajectory
    telemetry_telecommand.trajectory_speed.connect_to   waypoint_navigation.speed_input
    waypoint_navigation.trajectory_status.connect_to    telemetry_telecommand.trajectory_status
    telemetry_telecommand.current_pan.connect_to        ptu_control.pan_samples_out
    telemetry_telecommand.current_tilt.connect_to       ptu_control.tilt_samples_out
    #telemetry_telecommand.current_imu.connect_to        imu_stim300.orientation_samples_out
    read_joint_dispatcher.joints_samples.connect_to     telemetry_telecommand.joint_samples

    # Start the components
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    ptu_control.start
    command_arbiter.start
    motion_translator.start
    joystick.start
    imu_stim300.start
    if options[:v] == false
        # start visodom
    else
      	vicon.start
    end

    if options[:pan] == true
        camera_firewire_pancam.start
        camera_pancam.start
        trigger_pancam.start
        stereo_pancam.start
        dem_generation_pancam.start
        pancam_360.start
        trigger_pancam_360.start
    end
    if options[:loc] == true
        camera_loccam.start
        camera_firewire_loccam.start
        trigger_loccam.start
        stereo_loccam.start
        dem_generation_loccam.start
    end
    if options[:nav] == true
        camera_navcam.start
        camera_firewire_navcam.start
        trigger_navcam.start
        stereo_navcam.start
        dem_generation_navcam.start
    end
    telemetry_telecommand.start
    waypoint_navigation.start

    Readline::readline("Press Enter to exit\n") do
    end
end
