#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'controldev::JoystickTask' => 'joystick', 'motion_translator::Task' => 'motion_translator' do
#Orocos::Process.run 'hdpr_control' do
    # Get the task contexts
    joystick = Orocos.name_service.get 'joystick'
    joystick.configure
    
    motion_translator = Orocos.name_service.get 'motion_translator'
    motion_translator.configure
    
    joystick.raw_command.connect_to motion_translator.raw_command
    
    joystick.start
    motion_translator.start
    
    Readline::readline("Press Enter to exit\n") do
    end
end 
