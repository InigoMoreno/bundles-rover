#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Actual time is defined in the config files of the sensors
$calibration_seconds = 1200.0 # 20 minutes in seconds
$elapsed_time = 0.0
$percent_complete = 0.0

# Execute the task
Orocos::Process.run 'hdpr_unit_imu', 'unit_dsp1760' do

    # Configure
    imu_stim300 = TaskContext.get 'imu_stim300'
    Orocos.conf.apply(imu_stim300, ['default', 'calibration', 'HDPR', 'ESTEC', 'stim300_5g'], :override => true)
    imu_stim300.configure

    gyro = TaskContext.get 'dsp1760'
    Orocos.conf.apply(gyro, ['default', 'calibration'], :override => true)
    gyro.configure

    logger_imu = Orocos.name_service.get 'hdpr_unit_imu_Logger'
    logger_imu.file = "imu_calibration_samples.log"
    logger_imu.log(imu_stim300.inertial_sensors_out)
    logger_imu.log(imu_stim300.temp_sensors_out)
    logger_imu.log(imu_stim300.orientation_samples_out)
    logger_imu.start

    logger_gyro = Orocos.name_service.get 'unit_dsp1760_Logger'
    logger_gyro.file = "unit_dsp1760.log"
    logger_gyro.log(gyro.rotation)
    logger_gyro.log(gyro.orientation_samples)
    logger_gyro.log(gyro.bias_samples)
    logger_gyro.log(gyro.bias_values)
    logger_gyro.log(gyro.temperature)
    logger_gyro.start

    # Start
    imu_stim300.start
    gyro.start

    puts "IMU and gyro calibration started"
    # Wait for the sensors to go into calibrating mode (change status)
    sleep 2

    while gyro.state != :RUNNING and imu_stim300.state != :RUNNING
        print "\rCalibration #{sprintf('%.02f', $percent_complete)}% complete"
        sleep 5
        $elapsed_time += 5
        $percent_complete = 100.0 * $elapsed_time / $calibration_seconds
        # Sometimes it might take a little bit more time for the states to switch to RUNNING
        if $percent_complete > 99
            $percent_complete = 99
        end
    end
    puts "Calibration done, exiting..."
end 
