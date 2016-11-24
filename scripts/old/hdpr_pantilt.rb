#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'orocos/async'
require 'readline'

hostname = nil
    
if hostname
    Orocos::CORBA.name_service.ip = hostname
end

include Orocos

## Initialize Orocos ##
Bundles.initialize

#Orocos::Process.run 'ptu_directedperception::Task' => 'ptu_directedperception' do

    ptu = TaskContext.get 'ptu_directedperception'
    port = "/dev/ttyUSB2"
    ptu.io_port = ["serial://", port,":9600"].join("")
    ptu.io_read_timeout = Time.at(2.0)
    ptu.io_write_timeout = Time.at(2.0)
    ptu.configure
    ptu.start
    Readline::readline("Press Enter to exit\n") 
#end

