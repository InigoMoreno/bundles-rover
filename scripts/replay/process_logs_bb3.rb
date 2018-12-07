#! /usr/bin/env ruby

require 'orocos'
require 'orocos/log'
require 'rock/bundle'
require 'vizkit'
require 'utilrb'


include Orocos

Bundles.initialize

Orocos::Process.run 'camera_bb3::Task' => 'camera_bb3' do

    ## Get the task context ##
    STDERR.print "setting up camera_bb3..."
    camera_bb3 = TaskContext.get 'camera_bb3'
    Orocos.conf.apply(camera_bb3, ['default'], :override => true)
    camera_bb3.configure
    STDERR.puts "done"

    # logs files
    log_replay = Orocos::Log::Replay.open( ARGV[0] )
    log_replay.camera_firewire_bb3.frame.connect_to(camera_bb3.frame_in, :type => :buffer, :size => 200)


    ###################
    ## LOG THE PORTS ##
    ###################
    Bundles.log_all

    camera_bb3.start

    # open the log replay widget
    control = Vizkit.control log_replay
    control.speed = 1

    Vizkit.exec


end
