#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

#Orocos.initialize
Bundles.initialize

Orocos.run 'camera_firewire::CameraTask' => 'camera_firewire' do
  camera_firewire = Orocos.name_service.get 'camera_firewire'
  Orocos.conf.apply(camera_firewire, ['hdpr_bb3','altec_bb3_id','auto_exposure'], :override => true)

  ## Configure the task
  camera_firewire.configure

  ## Start the task ##
  camera_firewire.start

  Readline::readline("Press Enter to exit\n") do
  end
end
