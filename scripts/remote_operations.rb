#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
#require 'vizkit'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

## Transformation for the transformer
Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts.rb'))

# Distance to move between 360 picture taking
$distance_360_picture = 30

# Execute the task
Orocos::Process.run 'hdpr_control', 'hdpr_pancam', 'hdpr_lidar', 'hdpr_tof', 'hdpr_bb2', 'hdpr_bb3', 'hdpr_imu', 'hdpr_gps', 'hdpr_gps_heading', 'hdpr_navigation', 'hdpr_tmtchandling' do

    joystick = Orocos.name_service.get 'joystick'
    # Set the joystick input
    joystick.device = "/dev/input/js0"
    # In case the dongle is not connected exit gracefully
    begin
        # Configure the joystick
        joystick.configure
    rescue
        # Abort the process as there is no joystick to get input from
        abort("Cannot configure the joystick, is the dongle connected to HDPR?")
    end
    
    # Configure the control packages
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
    
    # Configure the sensor packages
    velodyne_lidar = TaskContext.get 'velodyne_lidar'
    Orocos.conf.apply(velodyne_lidar, ['default'], :override => true)
    velodyne_lidar.configure
    
    tofcamera_mesasr = TaskContext.get 'tofcamera_mesasr'
    Orocos.conf.apply(tofcamera_mesasr, ['default'], :override => true)
    tofcamera_mesasr.configure
    
    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'HDPR', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure
    
    gps = TaskContext.get 'gps'
    Orocos.conf.apply(gps, ['HDPR', 'Netherlands', 'DECOS'], :override => true)
    gps.configure
    
    gps_heading = TaskContext.get 'gps_heading'
    Orocos.conf.apply(gps_heading, ['default'], :override => true)
    gps_heading.configure

    camera_firewire_bb2 = TaskContext.get 'camera_firewire_bb2'
    Orocos.conf.apply(camera_firewire_bb2, ['bumblebee2'], :override => true)
    camera_firewire_bb2.configure
    
    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure

    camera_firewire_bb3 = TaskContext.get 'camera_firewire_bb3'
    Orocos.conf.apply(camera_firewire_bb3, ['bumblebee3'], :override => true)
    camera_firewire_bb3.configure
    
    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure
    
    pancam_left = Orocos.name_service.get 'pancam_left'
    Orocos.conf.apply(pancam_left, ['grashopper2_left'], :override => true)
    pancam_left.configure
    
    pancam_right = Orocos.name_service.get 'pancam_right'
    Orocos.conf.apply(pancam_right, ['grashopper2_right'], :override => true)
    pancam_right.configure
    
    pancam_panorama = Orocos.name_service.get 'pancam_panorama'
    Orocos.conf.apply(pancam_panorama, ['default'], :override => true)
    pancam_panorama.configure
    
    pancam_360 = Orocos.name_service.get 'pancam_360'
    Orocos.conf.apply(pancam_360, ['default'], :override => true)
    pancam_360.configure
    
     # Setup Waypoint_navigation 
    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    Orocos.conf.apply(waypoint_navigation, ['default','hdpr'], :override => true)
    waypoint_navigation.configure

    # Setup command arbiter
    command_arbiter = Orocos.name_service.get 'command_arbiter'
    Orocos.conf.apply(command_arbiter, ['default'], :override => true)
    command_arbiter.configure
    
	# Add the trajectory generation component
    trajectoryGen = Orocos.name_service.get 'trajectoryGen'
    Orocos.conf.apply(trajectoryGen, ['hdprtest','decos'], :override => true)
    trajectoryGen.configure
    
    # "Fuse" GPS position and IMU orientation to get rover pose
    simple_pose = Orocos.name_service.get 'simple_pose'
    Orocos.conf.apply(simple_pose, ['default'], :override => true)
    simple_pose.configure
    
    # setup telemetry_telecommand
    telemetry_telecommand = Orocos.name_service.get 'telemetry_telecommand'
    Orocos.conf.apply(telemetry_telecommand, ['default'], :override => true)
    #Bundles.transformer.setup(telemetry_telecommand)
    telemetry_telecommand.configure
   
    # Configure the connections between the components
    joystick.raw_command.connect_to                     motion_translator.raw_command
    joystick.raw_command.connect_to                     command_arbiter.raw_command
    
    motion_translator.motion_command.connect_to         command_arbiter.joystick_motion_command
    waypoint_navigation.motion_command.connect_to       command_arbiter.follower_motion_command
    command_arbiter.motion_command.connect_to           locomotion_control.motion_command
    
    locomotion_control.joints_commands.connect_to       command_joint_dispatcher.joints_commands
    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to          read_joint_dispatcher.joints_readings
    #read_joint_dispatcher.joints_samples.connect_to     locomotion_control.joints_readings
    read_joint_dispatcher.motors_samples.connect_to     locomotion_control.joints_readings
    camera_firewire_bb2.frame.connect_to                camera_bb2.frame_in
    camera_firewire_bb3.frame.connect_to                camera_bb3.frame_in
    
    # Waypoint navigation inputs:
    #imu_stim300.orientation_samples_out.connect_to      simple_pose.imu_pose
    #gps.pose_samples.connect_to                         simple_pose.gps_pose
    #simple_pose.pose.connect_to                         waypoint_navigation.pose
    gps.pose_samples.connect_to                         gps_heading.gps_pose_samples
    imu_stim300.orientation_samples_out.connect_to      gps_heading.imu_pose_samples
    #command_arbiter.motion_command.connect_to           gps_heading.motion_command
    trajectoryGen.trajectory.connect_to                 waypoint_navigation.trajectory
    gps_heading.pose_samples_out.connect_to             waypoint_navigation.pose
    
    # PanCam connections to panorama and 360 components (must function exclusivly)
    pancam_panorama.pan_angle_in.connect_to             ptu_directedperception.pan_angle
    pancam_panorama.tilt_angle_in.connect_to            ptu_directedperception.tilt_angle
    pancam_panorama.pan_angle_out.connect_to            ptu_directedperception.pan_set
    pancam_panorama.tilt_angle_out.connect_to           ptu_directedperception.tilt_set
    pancam_left.frame.connect_to                        pancam_panorama.left_frame_in
    pancam_right.frame.connect_to                       pancam_panorama.right_frame_in
    pancam_360.pan_angle_in.connect_to                  ptu_directedperception.pan_angle
    pancam_360.tilt_angle_in.connect_to                 ptu_directedperception.tilt_angle
    pancam_360.pan_angle_out.connect_to                 ptu_directedperception.pan_set
    pancam_360.tilt_angle_out.connect_to                ptu_directedperception.tilt_set
    pancam_left.frame.connect_to                        pancam_360.left_frame_in
    pancam_right.frame.connect_to                       pancam_360.right_frame_in
    
    # Log all the properties of the components
    Orocos.log_all_configuration
    
    # Define loggers
    logger_control = Orocos.name_service.get 'hdpr_control_Logger'
    logger_control.file = "control.log"
    logger_control.log(platform_driver.joints_readings)
    logger_control.log(command_arbiter.motion_command)
    
    logger_pancam = Orocos.name_service.get 'hdpr_pancam_Logger'
    logger_pancam.file = "pancam.log"
    logger_pancam.log(pancam_panorama.frame)
    logger_pancam.log(pancam_360.frame)
    
    logger_bb2 = Orocos.name_service.get 'hdpr_bb2_Logger'
    logger_bb2.file = "bb2.log"
    logger_bb2.log(camera_firewire_bb2.frame)
    
    logger_bb3 = Orocos.name_service.get 'hdpr_bb3_Logger'
    logger_bb3.file = "bb3.log"
    logger_bb3.log(camera_firewire_bb3.frame)
    
    logger_tof = Orocos.name_service.get 'hdpr_tof_Logger'
    logger_tof.file = "tof.log"
    logger_tof.log(tofcamera_mesasr.distance_frame)
    logger_tof.log(tofcamera_mesasr.ir_frame)
    logger_tof.log(tofcamera_mesasr.pointcloud)
    logger_tof.log(tofcamera_mesasr.tofscan)
    
    logger_lidar = Orocos.name_service.get 'hdpr_lidar_Logger'
    logger_lidar.file = "lidar.log"
    logger_lidar.log(velodyne_lidar.ir_frame)
    logger_lidar.log(velodyne_lidar.laser_scans)
    logger_lidar.log(velodyne_lidar.range_frame)
    
    logger_gps = Orocos.name_service.get 'hdpr_gps_Logger'
    logger_gps.file = "gps.log"
    logger_gps.log(gps.pose_samples)
    logger_gps.log(gps.raw_data)
    logger_gps.log(gps.time)
    logger_gps.log(gps_heading.pose_samples_out)
    
    logger_imu = Orocos.name_service.get 'hdpr_imu_Logger'
    logger_imu.file = "imu.log"
    logger_imu.log(imu_stim300.inertial_sensors_out)
    logger_imu.log(imu_stim300.temp_sensors_out)
    logger_imu.log(imu_stim300.orientation_samples_out)
    logger_imu.log(imu_stim300.compensated_sensors_out)
    #Orocos.log_all_ports
    
    # Start loggers
    logger_control.start
    logger_pancam.start
    logger_bb2.start
    logger_bb3.start
    logger_tof.start
    logger_lidar.start
    logger_gps.start
    logger_imu.start

    # Start the components
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    ptu_directedperception.start
    pancam_left.start
    pancam_right.start
    motion_translator.start
    joystick.start
    velodyne_lidar.start
    tofcamera_mesasr.start
    imu_stim300.start
    gps.start
    gps_heading.start
    camera_bb2.start
    camera_firewire_bb2.start
    camera_bb3.start
    camera_firewire_bb3.start
    command_arbiter.start
    trajectoryGen.start
    #simple_pose.start
    waypoint_navigation.start
    
    # Race condition with internal gps_heading states. This check is here to only trigger the 
    # trajectoryGen when the pose has been properly initialised. Otherwise the trajectory is set wrong.
    while gps_heading.state != :RUNNING
        sleep 1
    end
    # Trigger the trojectory generation, waypoint_navigation must be running at this point
    trajectoryGen.trigger
    
    # Waypoint navigation needs to be stopped at the beginning
    waypoint_navigation.stop
    
    # Get a reader instance for the GPS
    reader_gps_position = gps.pose_samples.reader
    
    # Initialise GPS position
    $last_gps_position = 0
    $distance = 0
    $pass_360 = 0
    
    # 3-state machine toggling between waypoint navigation and 360 image taking (2 passes at different tilts)
    # If the user is controlling the platform it will still switch between the states
    while true
        if pancam_360.state == :RUNNING
            puts "Still taking a picture, waiting 1 seconds"
            sleep 1
        elsif pancam_360.state == :STOPPED and $pass_360 == 1
            puts "360 degree picture done, waiting 1 second"
            sleep 1
            puts "360 pass 1"
            $pass_360 = 2
            pancam_360.positionTilt = 20
            pancam_360.start
        elsif pancam_360.state == :STOPPED and $pass_360 == 2
            puts "360 pass 2"
            $pass = 0
            pancam_360.positionTilt = 40
            pancam_360.start
        elsif pancam_360.state == :STOPPED
            puts "360 degree picture done"
            pancam_panorama.start
            
            # Start waypoint navigation
            waypoint_navigation.start
            
            # Wait for the rover to move for a defined distance in meters
            while $distance < $distance_360_picture or $distance.nan?
                sample = reader_gps_position.read_new
                if sample
                    # Initialise GPS position
                    if $last_gps_position == 0
                        $last_gps_position = sample
                    end
                    
                    # Evaluate distance from last position
                    dx = sample.position[0] - $last_gps_position.position[0]
                    dy = sample.position[1] - $last_gps_position.position[1]
                    # Cumulative distance
                    $distance += Math.sqrt(dx*dx + dy*dy)
                    $last_gps_position = sample
                end
            end
            $distance = 0
            
            # Stop sending waypoint navigation commands, this should also stop the rover now so the following lines are not required
            waypoint_navigation.stop
            
            # Stop the panorama taking
            pancam_panorama.stop
            puts "Taking new 360 degree picture"
            pancam_360.start
            $pass_360 = 1
        end
    end
    
    # Show camera output
    #Vizkit.display pancam_panorama.left_frame_out
    #Vizkit.display pancam_panorama.right_frame_out
    #Vizkit.display camera_bb2.left_frame
    #Vizkit.display camera_bb3.left_frame
    #Vizkit.display tofcamera_mesasr.distance_frame
    #Vizkit.display velodyne_lidar.ir_interp_frame
    
    #Vizkit.exec
    
    # Not needed when Vizkit is running
    Readline::readline("Press Enter to exit\n") do
    end
end 
