#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'unit_bb2' do

    # Configure
    camera_firewire_bb2 = TaskContext.get 'camera_firewire_bb2'
    #Orocos.conf.apply(camera_firewire_bb2, ['exoter_bb2','egp_bb2_id'], :override => true)
    Orocos.conf.apply(camera_firewire_bb2, ['exoter_bb2_b'], :override => true)
    #Orocos.conf.apply(camera_firewire_bb2, ['exoter_bb2_b','auto_exposure'], :override => true)
    camera_firewire_bb2.configure

    camera_bb2 = TaskContext.get 'camera_bb2'
    #Orocos.conf.apply(camera_bb2, ['egp_bb2'], :override => true)
    Orocos.conf.apply(camera_bb2, ['hdpr_bb2'], :override => true)
    #Orocos.conf.apply(camera_bb2, ['exoter_bb2'], :override => true)
    #Orocos.conf.apply(camera_bb2, ['test_hdpr_bb2'], :override => true)
    camera_bb2.configure

    stereo_bb2 = TaskContext.get 'stereo_bb2'
    #Orocos.conf.apply(stereo_bb2, ['egp_bb2'], :override => true)
    # Orocos.conf.apply(stereo_bb2, ['hdpr_bb2'], :override => true)
    #Orocos.conf.apply(stereo_bb2, ['exoter_bb2'], :override => true)
    Orocos.conf.apply(stereo_bb2, ['test_hdpr_bb2'], :override => true)
    stereo_bb2.configure

    # Log
    Orocos.log_all_ports
    #camera_firewire_bb2.log_all_ports
    #camera_bb2.log_all_ports

    # Connect
    camera_firewire_bb2.frame.connect_to camera_bb2.frame_in
    camera_bb2.left_frame.connect_to stereo_bb2.left_frame
    camera_bb2.right_frame.connect_to stereo_bb2.right_frame

    # Start
    camera_firewire_bb2.start
    camera_bb2.start
    stereo_bb2.start

    Readline::readline("Press Enter to exit\n") do
    end
end
