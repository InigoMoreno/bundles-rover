#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos



# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'control' do
    # Configure
    joystick = Orocos.name_service.get 'joystick'
    Orocos.conf.apply(joystick, ['default', 'logitech_gamepad'], :override => true)
    begin
        joystick.configure
    rescue
        abort("Cannot configure the joystick, is the dongle connected to MaRTA?")
    end

    motion_translator = Orocos.name_service.get 'motion_translator'
    Orocos.conf.apply(motion_translator, ['exoter'], :override => true)
    motion_translator.configure

    locomotion_control = Orocos.name_service.get 'locomotion_control'
    Orocos.conf.apply(locomotion_control, ['marta'], :override => true)
    locomotion_control.configure
	
    locomotion_switcher = Orocos.name_service.get 'locomotion_switcher'
    Orocos.conf.apply(locomotion_switcher, ['default'], :override => true)
    locomotion_switcher.configure

    # Connect
    joystick.raw_command.connect_to                       motion_translator.raw_command

    motion_translator.motion_command.connect_to           locomotion_switcher.motion_command
    motion_translator.locomotion_mode.connect_to          locomotion_switcher.locomotion_mode_override

    locomotion_switcher.lc_motion_command.connect_to      locomotion_control.motion_command

    locomotion_control.joints_commands.connect_to         locomotion_switcher.lc_joints_commands

    locomotion_control.start
    locomotion_switcher.start
    motion_translator.start
    joystick.start

    Readline::readline("Press Enter to exit\n") do
    end
end
