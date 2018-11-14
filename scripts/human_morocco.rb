#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
require 'optparse'
include Orocos

# Command line options for the script, default values
options = {
    :logging => true,
    :bb2 => true,
    :bb3 => true,
    :csc => true
}

# Options parser
OptionParser.new do |opts|
  opts.banner = "Usage: start.rb [options]"
  opts.on('-bb2', '--bb2 state', 'Enable/disable BB2 camera') { |state| options[:bb2] = state }
  opts.on('-bb3', '--bb3 state', 'Enable/disable BB3 camera') { |state| options[:bb3] = state }
  opts.on('-csc', '--customShutterController state', 'Enable/disable custom shutter controller') { |state| options[:csc] = state }
end.parse!

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
#
# task context 'hdpr_unit_visual_odometry' is necessary, because it is used in the transforms,
# eventhough we do not make use of visual odometry in this script.
Orocos::Process.run 'control', 'bb2', 'bb3', 'imu', 'gps', 'shutter_controller' do

    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'HDPR', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure

    if options[:bb2]
        puts "Starting BB2"

        camera_firewire_bb2 = TaskContext.get 'camera_firewire_bb2'
        Orocos.conf.apply(camera_firewire_bb2, ['hdpr_bb2','egp_bb2_id', 'auto_exposure'], :override => true)
        camera_firewire_bb2.configure

        camera_bb2 = TaskContext.get 'camera_bb2'
        Orocos.conf.apply(camera_bb2, ['hdpr_bb2'], :override => true)
        camera_bb2.configure

        if options[:csc]
            shutter_controller_bb2 = Orocos.name_service.get 'shutter_controller_bb2'
            Orocos.conf.apply(shutter_controller_bb2, ['bb2tenerife'], :override => true)

            shutter_controller_bb2.configure
        end
    end

    if options[:bb3]
        puts "Starting BB3"

        camera_firewire_bb3 = TaskContext.get 'camera_firewire_bb3'
        Orocos.conf.apply(camera_firewire_bb3, ['hdpr_bb3', 'altec_bb3_id', 'auto_exposure'], :override => true)
        camera_firewire_bb3.configure

        camera_bb3 = TaskContext.get 'camera_bb3'
        Orocos.conf.apply(camera_bb3, ['default'], :override => true)
        camera_bb3.configure

        if options[:csc]
            shutter_controller_bb3 = Orocos.name_service.get 'shutter_controller_bb3'
            Orocos.conf.apply(shutter_controller_bb3, ['bb3tenerife'], :override => true)
            shutter_controller_bb3.configure
        end
    end

    gps = TaskContext.get 'gps'
    Orocos.conf.apply(gps, ['HDPR', 'Netherlands', 'DECOS'], :override => true)
    gps.configure

    gps_heading = TaskContext.get 'gps_heading'
    Orocos.conf.apply(gps_heading, ['default'], :override => true)
    gps_heading.configure

    if options[:bb2]
        #camera_firewire_bb2.frame.connect_to             camera_bb2.frame_in

        if options[:csc]
            camera_firewire_bb2.frame.connect_to         shutter_controller_bb2.frame
            camera_firewire_bb2.shutter_value.connect_to shutter_controller_bb2.shutter_value
        end
    end

    if options[:bb3]
        #camera_firewire_bb3.frame.connect_to                camera_bb3.frame_in

        if options[:csc]
            camera_firewire_bb3.frame.connect_to            shutter_controller_bb3.frame
            camera_firewire_bb3.shutter_value.connect_to    shutter_controller_bb3.shutter_value
        end

    end

    gps.pose_samples.connect_to                         gps_heading.gps_pose_samples
    gps.raw_data.connect_to                             gps_heading.gps_raw_data

    imu_stim300.orientation_samples_out.connect_to      gps_heading.imu_pose_samples

    if options[:logging]
        Orocos.log_all_configuration

        if options[:bb2]
            logger_bb2 = Orocos.name_service.get 'bb2_Logger'
            logger_bb2.file = "bb2.log"
            logger_bb2.log(camera_firewire_bb2.frame)
            logger_bb2.log(camera_bb2.left_frame)
            logger_bb2.log(camera_bb2.right_frame)
            if options[:csc] == true
                logger_bb2.log(shutter_controller_bb2.shutter_value)
            end
            logger_bb2.start
        end

        if options[:bb3]
            logger_bb3 = Orocos.name_service.get 'bb3_Logger'
            logger_bb3.file = "bb3.log"
            logger_bb3.log(camera_firewire_bb3.frame)
            logger_bb3.log(camera_bb3.left_frame)
            logger_bb3.log(camera_bb3.center_frame)
            logger_bb3.log(camera_bb3.right_frame)
            if options[:csc] == true
                logger_bb3.log(shutter_controller_bb3.shutter_value)
            end
            logger_bb3.start
        end

        logger_gps = Orocos.name_service.get 'gps_Logger'
        logger_gps.file = "gps.log"
        logger_gps.log(gps.pose_samples)
        logger_gps.log(gps.raw_data)
        logger_gps.log(gps.time)
        logger_gps.log(gps_heading.pose_samples_out)
        logger_gps.start

        logger_imu = Orocos.name_service.get 'imu_Logger'
        logger_imu.file = "imu.log"
        logger_imu.log(imu_stim300.inertial_sensors_out)
        logger_imu.log(imu_stim300.orientation_samples_out)
        logger_imu.log(imu_stim300.compensated_sensors_out)
        logger_imu.start
    end

    # Start the components
    imu_stim300.start
    gps.start
    gps_heading.start

    if options[:bb2] == true
        #camera_firewire_bb2.start
        camera_bb2.start
        if options[:csc]
            shutter_controller_bb2.start
        end
    end
    if options[:bb3] == true
        #camera_firewire_bb3.start
        camera_bb3.start
        if options[:csc]
            shutter_controller_bb3.start
        end
    end

    # Race condition with internal gps_heading states. This check is here to only trigger the
    # trajectoryGen when the pose has been properly initialised. Otherwise the trajectory is set wrong.
    puts "Move rover forward to initialise the gps_heading component"
    while gps_heading.ready == false
       sleep 1
    end
    puts "GPS heading calibration done"

    # take pictures every sample_distance meters
    sample_distance = 0.10

    reader_gps_pose = gps.pose_samples.reader
    reader_camera_bb2_fw = camera_bb2_firewire.frame.reader
    reader_camera_bb3_fw = camera_bb3_firewire.frame.reader
    writer_camera_bb2 = camera_bb2.acquire_image.writer
    writer_camera_bb3 = camera_bb3.acquire_image.writer

    position = reader_gps_pose.position.read
    last_position_x = position.x
    last_position_y = position.y
    while true
        position = reader_gps_pose.position.read
        distance = sqrt((position.x - last_position_x)**2 + (position.y - last_position_y)**2)

        if distance > sample_distance
            writer_camera_bb2.write(reader_camera_bb2_fw.read)
            writer_camera_bb3.write(reader_camera_bb3_fw.read)

            last_position_x = pose.x
            last_position_y = pose.y
        end
    end

    Readline::readline("Press Enter to exit\n") do
    end
end
