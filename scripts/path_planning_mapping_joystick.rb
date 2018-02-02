#!/usr/bin/env ruby

#require 'vizkit'
require 'orocos'
require 'rock/bundle'
require 'readline'
require 'optparse'

include Orocos

# Command line options for the script, default values
options = {:v => false}

# Options parser
OptionParser.new do |opts|
  opts.banner = "Usage: start.rb [options]"
  opts.on('-v', '--vicon state', 'Enable gps') { |state| options[:v] = state }
end.parse!

## Initialize orocos ##
Bundles.initialize

## Transformation for the transformer
Bundles.transformer.load_conf(Bundles.find_file('config', 'transforms_scripts.rb'))

Orocos::Process.run 'hdpr_unit_bb2', 'hdpr_pancam', 'hdpr_unit_shutter_controller', 'hdpr_gps', 'hdpr_control', 'hdpr_autonomy', 'hdpr_unit_gyro', 'hdpr_imu', 'hdpr_unit_visual_odometry', 'hdpr_shutter_controller_bumblebee' do

	# Visiodom bb2
	puts "Startng BB2 for visiodom"

    camera_firewire_bb2 = TaskContext.get 'camera_firewire_bb2'
    Orocos.conf.apply(camera_firewire_bb2, ['bumblebee2'], :override => true)
    camera_firewire_bb2.configure

    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['default'], :override => true)
    camera_bb2.configure
    
    stereo_bb2 = TaskContext.get 'stereo_bb2'
    Orocos.conf.apply(stereo_bb2, ['hdpr_bb2'], :override => true)
    stereo_bb2.configure
    puts "done"
    
    # Mapping PanCam
	puts "Startng mapping PanCam"

    pancam_left = Orocos.name_service.get 'pancam_left'
    Orocos.conf.apply(pancam_left, ['grashopper2_left'], :override => true)
    pancam_left.configure
    
    pancam_right = Orocos.name_service.get 'pancam_right'
    Orocos.conf.apply(pancam_right, ['grashopper2_right'], :override => true)
    pancam_right.configure
    
    stereo_pancam = Orocos.name_service.get 'stereo_pancam'
    Orocos.conf.apply(stereo_pancam, ['panCam'], :override => true)
    stereo_pancam.configure

    shutter_controller = Orocos.name_service.get 'shutter_controller'
    Orocos.conf.apply(shutter_controller, ['default'], :override => true)
    shutter_controller.configure
    
    shutter_controller_bb2 = Orocos.name_service.get 'shutter_controller_bb2'
    Orocos.conf.apply(shutter_controller_bb2, ['bb2tenerife'], :override => true)
    shutter_controller_bb2.configure

    pancam_panorama = Orocos.name_service.get 'pancam_panorama'
    Orocos.conf.apply(pancam_panorama, ['hdpr_autonomy'], :override => true)
    pancam_panorama.configure
	puts "Done"


    # setup platform_driver
    puts "Setting up platform_driver"
    platform_driver = Orocos.name_service.get 'platform_driver'
    Orocos.conf.apply(platform_driver, ['default'], :override => true)
    platform_driver.configure
    puts "done"

    # setup read dispatcher
    puts "Setting up reading joint_dispatcher"
    read_joint_dispatcher = Orocos.name_service.get 'read_joint_dispatcher'
    Orocos.conf.apply(read_joint_dispatcher, ['reading'], :override => true)
    read_joint_dispatcher.configure
    puts "done"
    
    # setup ptu
    puts "Setting up ptu"
    ptu_directedperception = Orocos.name_service.get 'ptu_directedperception'
    Orocos.conf.apply(ptu_directedperception, ['default'], :override => true)
    ptu_directedperception.configure
    puts "done"

    # setup the commanding dispatcher
    puts "Setting up commanding joint_dispatcher"    
    command_joint_dispatcher = Orocos.name_service.get 'command_joint_dispatcher'
    Orocos.conf.apply(command_joint_dispatcher, ['commanding'], :override => true)
    command_joint_dispatcher.configure
    puts "done"

    # setup exoter locomotion_control
    puts "Setting up locomotion_control"
    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['default'], :override => true)
    locomotion_control.configure
    puts "done"
    
    # setup gps and gps heading
    puts "Setting up gps and gps heading"
    gps = TaskContext.get 'gps'
    Orocos.conf.apply(gps, ['HDPR', 'Spain', 'TENERIFE_AUTONOMY'], :override => true)
    gps.configure
    
    gps_heading = TaskContext.get 'gps_heading'
    Orocos.conf.apply(gps_heading, ['default'], :override => true)
    gps_heading.configure
    puts "done"
    
    # setup imu_stim300 
    puts "Setting up imu_stim300"
    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'HDPR', 'Tenerife', 'stim300_5g'], :override => true)
    imu_stim300.configure
    puts "done"
    
    # Setup laser gyro
	puts "Setting up laser gyro"
	gyro = TaskContext.get 'dsp1760'
    Orocos.conf.apply(gyro, ['default'], :override => true)
    gyro.configure
    puts "done"
    
    # Setup visual odometry
    puts "Setting up visual odometry"
	visual_odometry = TaskContext.get 'viso2'
    Orocos.conf.apply(visual_odometry, ['bumblebee'], :override => true)
    Bundles.transformer.setup(visual_odometry)
    visual_odometry.configure

    viso2_with_imu = TaskContext.get 'viso2_with_imu'
    Orocos.conf.apply(viso2_with_imu, ['hdpr_autonomy'], :override => true)
    Bundles.transformer.setup(viso2_with_imu)
	viso2_with_imu.configure
	puts "done"
	
    # setup joystick
    puts "Setting up joystick"
    joystick = Orocos.name_service.get 'joystick'
    Orocos.conf.apply(joystick, ['default'], :override => true)
    begin
        joystick.configure
    rescue
        abort("Cannot configure the joystick, is the dongle connected?")
    end
    puts "done"

    # setup motion_translator
    puts "Setting up motion_translator"
    motion_translator = Orocos.name_service.get 'motion_translator'
	Orocos.conf.apply(motion_translator, ['default'], :override => true)
    motion_translator.configure
    puts "done"

    # setup waypoint_navigation 
    puts "Setting up waypoint_navigation"
    waypoint_navigation = Orocos.name_service.get 'waypoint_navigation'
    Orocos.conf.apply(waypoint_navigation, ['default','hdpr_autonomy'], :override => true)
    waypoint_navigation.configure
    puts "done"

    # setup command arbiter
    puts "Setting up command arbiter"
    command_arbiter = Orocos.name_service.get 'command_arbiter'
    Orocos.conf.apply(command_arbiter, ['default'], :override => true)
    command_arbiter.configure
    puts "done"

    # setup motion_planning_libraries
    puts "Setting up the motion_planning_libraries"
    planner = Orocos.name_service.get 'path_planner' 
    planner.traversability_map_id = "trav_map"
    planner.planning_time_sec = 20.0
    planner.config do |p|
        p.mPlanningLibType = :LIB_SBPL
        p.mEnvType = :ENV_XY
        p.mPlanner = :ANYTIME_DSTAR
        p.mFootprintLengthMinMax.first = 0.70
        p.mFootprintLengthMinMax.second = 0.70
        p.mFootprintWidthMinMax.first  = 0.70
        p.mFootprintWidthMinMax.second = 0.70
        p.mMaxAllowedSampleDist = -1
        p.mNumFootprintClasses  = 10
        p.mTimeToAdaptFootprint = 10
        p.mAdaptFootprintPenalty = 2
        p.mSearchUntilFirstSolution = false
        p.mReplanDuringEachUpdate = true
        p.mNumIntermediatePoints  = 8
        p.mNumPrimPartition = 2

        # EO2
        p.mSpeeds.mSpeedForward         = 0.05
        p.mSpeeds.mSpeedBackward        = 0.05
        p.mSpeeds.mSpeedLateral         = 0.0
        p.mSpeeds.mSpeedTurn            = 0.083
        p.mSpeeds.mSpeedPointTurn       = 0.083
        p.mSpeeds.mMultiplierForward    = 1
        p.mSpeeds.mMultiplierBackward   = 500
        p.mSpeeds.mMultiplierLateral    = 500
        p.mSpeeds.mMultiplierTurn       = 5 
        p.mSpeeds.mMultiplierPointTurn  = 2

        # SBPL specific configuration
        p.mSBPLEnvFile = ""
        p.mSBPLMotionPrimitivesFile = ""
        p.mSBPLForwardSearch = false # ADPlanner throws 'g-values are non-decreasing' if true
    end
    planner.configure
    puts "done"

    # setup trajectory resampling 
    puts "Setting up trajectory resampling"
    refiner = Orocos.name_service.get 'trajectory_refiner'
    refiner.configure
    puts "done"

    # Autonomy
    puts "Setting cartographer"
    cartographer = TaskContext.get 'cartographer'
    Orocos.conf.apply(cartographer, ['hdpr'], :override => true)
    Bundles.transformer.setup(cartographer)
    cartographer.configure
    puts "done"


    # Log all ports
    Orocos.log_all_ports

    puts "Connecting ports"

    # Connect gps pose tasks
    if options[:v] == true
		gps.pose_samples.connect_to                         gps_heading.gps_pose_samples
		imu_stim300.orientation_samples_out.connect_to      gps_heading.imu_pose_samples
		command_arbiter.motion_command.connect_to           gps_heading.motion_command
		gps.raw_data.connect_to                             gps_heading.gps_raw_data
		gps_heading.pose_samples_out.connect_to             waypoint_navigation.pose
    else
		camera_bb2.left_frame.connect_to                    visual_odometry.left_frame
		camera_bb2.right_frame.connect_to                   visual_odometry.right_frame
		imu_stim300.orientation_samples_out.connect_to  	viso2_with_imu.pose_samples_imu
		visual_odometry.delta_pose_samples_out.connect_to 	viso2_with_imu.delta_pose_samples_in
		gyro.orientation_samples.connect_to 				viso2_with_imu.pose_samples_imu_extra
		viso2_with_imu.pose_samples_out.connect_to 			waypoint_navigation.pose
	end
    #trajectoryGen.trajectory.connect_to                 waypoint_navigation.trajectory
    
    # Connect pancam panorama tasks
    pancam_panorama.pan_angle_in.connect_to             ptu_directedperception.pan_angle
    pancam_panorama.tilt_angle_in.connect_to            ptu_directedperception.tilt_angle
    pancam_panorama.pan_angle_out.connect_to            ptu_directedperception.pan_set
    pancam_panorama.tilt_angle_out.connect_to           ptu_directedperception.tilt_set
    pancam_left.frame.connect_to                        pancam_panorama.left_frame_in
    pancam_right.frame.connect_to                       pancam_panorama.right_frame_in
    pancam_left.frame.connect_to                        shutter_controller.frame
    pancam_left.shutter_value.connect_to                shutter_controller.shutter_value
    pancam_right.shutter_value.connect_to               shutter_controller.shutter_value
    pancam_panorama.left_frame_out.connect_to           stereo_pancam.left_frame
    pancam_panorama.right_frame_out.connect_to          stereo_pancam.right_frame
    pancam_panorama.execution_valid.connect_to          cartographer.sync_out

    # Connect bb2 tasks (not yet to visual odometry)
    camera_firewire_bb2.frame.connect_to                camera_bb2.frame_in
    camera_bb2.left_frame.connect_to                    stereo_bb2.left_frame
    camera_bb2.right_frame.connect_to                   stereo_bb2.right_frame
    camera_firewire_bb2.frame.connect_to                shutter_controller_bb2.frame
    camera_firewire_bb2.shutter_value.connect_to        shutter_controller_bb2.shutter_value

    # COnnect locomotion ports
    joystick.raw_command.connect_to                     motion_translator.raw_command
    joystick.raw_command.connect_to                     command_arbiter.raw_command
    
    motion_translator.motion_command.connect_to         command_arbiter.joystick_motion_command
    command_arbiter.motion_command.connect_to           locomotion_control.motion_command
    waypoint_navigation.motion_command.connect_to       command_arbiter.follower_motion_command

    locomotion_control.joints_commands.connect_to       command_joint_dispatcher.joints_commands
    command_joint_dispatcher.motors_commands.connect_to platform_driver.joints_commands
    platform_driver.joints_readings.connect_to          read_joint_dispatcher.joints_readings
    #read_joint_dispatcher.joints_samples.connect_to     locomotion_control.joints_readings
    read_joint_dispatcher.motors_samples.connect_to     locomotion_control.joints_readings

    # Connect autonomy tasks
    stereo_pancam.distance_frame.connect_to 			cartographer.distance_image
    if options[:v] == true
		gps_heading.pose_samples_out.connect_to         cartographer.pose_in        
    else
		viso2_with_imu.pose_samples_out.connect_to		cartographer.pose_in
	end
	
    pancam_panorama.pan_angle_out_degrees.connect_to cartographer.ptu_pan
    pancam_panorama.tilt_angle_out_degrees.connect_to cartographer.ptu_tilt

    # Connect ports: traversability explorer to	planner
    #trav.traversability_map.connect_to	planner.traversability_map
    cartographer.traversability_map.connect_to	planner.traversability_map

    # Connect ports: planner 		to	trajectory refiner
    planner.waypoints.connect_to                refiner.waypoints_in

    # Connect ports: trajectory refiner to 	waypoint_navigation
    refiner.waypoints_out.connect_to            waypoint_navigation.trajectory

    # Connect ports: Vicon 		to 	traversability explorer
    #gps_heading.pose_samples_out.connect_to      trav.robot_pose        

    # Connect ports: Vicon 		to 	path planner
#	if options[:v] == true
#		gps_heading.pose_samples_out.connect_to         planner.start_pose_samples
#		puts "GPS HEADING POSE connected to PLANNER POSE"
#   else
		viso2_with_imu.pose_samples_out.connect_to		planner.start_pose_samples
#	end

    # Connect ports: Goal Generator	to 	path planner
    cartographer.goal.connect_to                   planner.goal_pose_samples

    # Connect ports: Goal Generator	to 	trajectory refiner
    cartographer.goal.connect_to                   refiner.goal_pose

    puts "done"

    # Start the tasks
    platform_driver.start
    read_joint_dispatcher.start
    command_joint_dispatcher.start
    locomotion_control.start
    imu_stim300.start
    joystick.start
    waypoint_navigation.start
    command_arbiter.start
    refiner.start
    planner.start
    motion_translator.start
    #trav.start

	# start cameras
    camera_firewire_bb2.start
    camera_bb2.start
    #stereo_bb2.start
    pancam_left.start
    pancam_right.start
    stereo_pancam.start
    shutter_controller.start
    shutter_controller_bb2.start
    pancam_panorama.start
   
    # start sensors
    ptu_directedperception.start
    gyro.start
    if options[:v] == true
		gps.start
		gps_heading.start
		puts "------------------------------ Using GPS ------------------------------"
	else
		visual_odometry.start
		viso2_with_imu.start
		puts "------------------------------ Using VISODOM ------------------------------"
	end
    sleep 5
    cartographer.start
    #sleep 1


    Readline::readline("Press ENTER to exit\n") do
    end

end
