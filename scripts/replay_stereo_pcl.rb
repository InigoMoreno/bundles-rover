#! /usr/bin/env ruby

require 'orocos'
require 'orocos/log'
require 'rock/bundle'
require 'vizkit'


include Orocos

#BASE_DIR = File.expand_path('..', File.dirname(__FILE__))
#ENV['PKG_CONFIG_PATH'] = "#{BASE_DIR}/build:#{ENV['PKG_CONFIG_PATH']}"

Bundles.initialize
#Orocos.conf.load_dir("#{ENV['AUTOPROJ_PROJECT_BASE']}/bundles/asguard/config/orogen")

#Orocos.run 'test_trajectory' do |p|
Orocos.run 'stereo::Task' => 'stereo' do 

    #Orocos.log_all_ports 
    #tf = p.task 'trajectory'
    stereo = Orocos.name_service.get 'stereo'
    Orocos.conf.apply(stereo, ['default'], :override => true)

    if ARGV.size == 0 then
	log_replay = Orocos::Log::Replay.open( "exoter_exteroceptive.0.log") 
    else
	log_replay = Orocos::Log::Replay.open( ARGV[0]+"exoter_exteroceptive.0.log") 
    end
    log_replay.camera_bb2_pan_cam.left_frame.connect_to( stereo.left_frame)
    log_replay.camera_bb2_pan_cam.right_frame.connect_to( stereo.right_frame)
    
    stereo.configure
    stereo.start

    log_replay.run
    
    Readline::readline("Press enter to exit \n") do
    end
end
