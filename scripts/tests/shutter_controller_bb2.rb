#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
#require 'vizkit'
include Orocos

Bundles.initialize

Orocos::Process.run 'unit_bb2', 'unit_shutter_controller' do

    camera_firewire = Orocos.name_service.get 'camera_firewire_bb2'
    Orocos.conf.apply(camera_firewire, ['hdpr_bb2', 'egp_bb2_id'], :override => true)
    camera_firewire.configure

    camera = Orocos.name_service.get 'camera_bb2'
    Orocos.conf.apply(camera, ['egp_bb2'], :override => true)
    camera.configure
    
    stereo = Orocos.name_service.get 'stereo_bb2'
    Orocos.conf.apply(stereo, ['egp_bb2'], :override => true)
    stereo.configure

    shutter_controller = Orocos.name_service.get 'shutter_controller'
    Orocos.conf.apply(shutter_controller, ['bb2fast'], :override => true)
    shutter_controller.configure

    camera_firewire.frame.connect_to                camera.frame_in
    camera_firewire.frame.connect_to                shutter_controller.frame
    camera_firewire.shutter_value.connect_to        shutter_controller.shutter_value
    
    camera.left_frame.connect_to                    stereo.left_frame
    camera.right_frame.connect_to                   stereo.right_frame
    
    camera_firewire.start
    camera.start
    stereo.start
    shutter_controller.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end
