#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

Bundles.initialize

Orocos::Process.run 'unit_bb2', 'unit_hazard_detector' do

    camera_firewire_bb2 = TaskContext.get 'camera_firewire_bb2'
    Orocos.conf.apply(camera_firewire_bb2, ['exoter_bb2','egp_bb2_id','auto_exposure'], :override => true)
    camera_firewire_bb2.configure

    camera_bb2 = TaskContext.get 'camera_bb2'
    Orocos.conf.apply(camera_bb2, ['egp_bb2'], :override => true)
    camera_bb2.configure

    stereo_bb2 = TaskContext.get 'stereo_bb2'
    Orocos.conf.apply(stereo_bb2, ['egp_bb2'], :override => true)
    stereo_bb2.configure

    hazard_detector = Orocos.name_service.get 'hazard_detector'
    Orocos.conf.apply(hazard_detector, ['default'], :override => true)
    hazard_detector.configure

    camera_firewire_bb2.frame.connect_to   camera_bb2.frame_in
    camera_bb2.left_frame.connect_to       stereo_bb2.left_frame
    camera_bb2.right_frame.connect_to      stereo_bb2.right_frame
    stereo_bb2.left_frame_sync.connect_to  hazard_detector.camera_frame
    stereo_bb2.distance_frame.connect_to   hazard_detector.distance_frame

    camera_bb2.start
    camera_firewire_bb2.start
    stereo_bb2.start
    hazard_detector.start

    Readline::readline("Press Enter to exit\n") do
    end

end
