#! /usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

Bundles.initialize

Orocos.run 'telemetry_telecommand::Task' => 'telemetry_telecommand' do

    Orocos.log_all

    telemetry_telecommand = Orocos.name_service.get 'telemetry_telecommand'
    Orocos.conf.apply(telemetry_telecommand, ['default'], :override => true)
    telemetry_telecommand.configure
    telemetry_telecommand.start

    #reader = vicon.pose_samples.reader

    #while true
    #    if sample = reader.read
	#        puts "%s %s %s" % [sample.position.x, sample.position.y, sample.position.z]
       # end
       # sleep 0.01
    # end
    Readline::readline("Press ENTER to exit\n") do
    end
    telemetry_telecommand.stop
end
