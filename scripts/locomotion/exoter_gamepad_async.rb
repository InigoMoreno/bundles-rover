#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'orocos/async'
require 'vizkit'
require 'Qt4'
require 'readline'
require 'optparse'

hostname = nil

options = OptionParser.new do |opt|
    opt.banner = <<-EOD
    usage: exoter_gamepad_async.rb [options]  </path/to/gamepad_device>
    EOD
    opt.on '--host=HOSTNAME', String, 'the host we should contact to find RTT tasks' do |host|
    hostname = host
    end
    opt.on '--help', 'this help message' do
    puts opt
    exit 0
    end
end

args = options.parse(ARGV)
device_name = args.shift

if !device_name
    puts "missing device name for the joystick/gamepad"
    puts options
    exit 1
end

if hostname
    Orocos::CORBA.name_service.ip = hostname
end

include Orocos

## Initialize Orocos ##
Bundles.initialize

## Load GUI ##
file_ui = Bundles.find_file('data/gui', 'joystick_controller.ui')
widget = Vizkit.load file_ui

widget.pan_position.setValidator(Qt::IntValidator.new(-180, 180))
widget.tilt_position.setValidator(Qt::IntValidator.new(-180, 180))

# Global variable
max_linear_speed = 0.00
max_rot_speed = 0.00
rover_speed_ratio = 0.00
x_velocity = 0.00
y_velocity = 0.00
rotation = 0.00
translation = 0.00
x_axis = 0.00
y_axis = 0.00
pan_axis = 0.00
tilt_axis = 0.00
axes_changed = FALSE
buttons_changed = FALSE

pan_pos = 0.00
tilt_pos = 0.00
# This offset is used cause our PTU is REFURBISHED and has an offset (Tilted about 14.6.... degrees) 
tilt_offset= 0.25491745
# Each discrete position (DP) of the ptu is about 185.1428 arcseconds or 0.0514285°
#Let's Define the limits
#MIN TILT 587 DP = 0.52688923589 radians (ROCK Driver uses different axes than PTU-D46)
min_tilt=-0.52688923589

#MAX TILT -889 DP = -0.7979634254 radians (ROCK Driver uses different axes than PTU-D46)
max_tilt=0.7979634254
#MIN PAN -3074 DP = 2.7592121144 radians
min_pan=-2.757507351
#MAX PAN 3075 DP = 2.76010971105 radians
max_pan=2.75010971105
#The scaling of the incrimental controll of the rover
delta_theta=0.2
#Direct_Control
direct_control=FALSE


tilt_pos = tilt_pos - tilt_offset
#tilt_pos_prev = tilt_pos
beginning_time = Time.now

Orocos::Process.run 'controldev::JoystickTask' => 'joystick', 'ptu_directedperception::Task' => 'ptu_dp' do

    ptu = TaskContext.get 'ptu_dp'
    port = "/dev/ttyUSB2"
    ptu.io_port = ["serial://", port,":9600"].join("")
    ptu.io_read_timeout = Time.at(2.0)
    ptu.io_write_timeout = Time.at(2.0)
    puts "connecting to #{ptu.io_port}"
    pan_writer = ptu.set_orientation.writer
    rot_reader = ptu.orientation_samples.reader
    pan_writer = ptu.pan_set.writer
    tilt_writer = ptu.tilt_set.writer
    ptu.configure
    ptu.start
 
    ## Get the Joystick task context ##
    joystick = TaskContext.get 'joystick'
    Orocos.conf.apply(joystick, ['default', 'logitech_gamepad'], :override => true)
    joystick.device = device_name

    ## Get the ExoTer control
    locomotion_control = Orocos::Async.proxy 'locomotion_control'
    ptu_control = Orocos::Async.proxy 'ptu_control'

    # Log all ports
    joystick.log_all_ports

    # Configure and start the task
    if File.exist? device_name then
        joystick.configure
        joystick.start

        ## Joystick Variables
        puts "Configuring Joystick..."
        axes = Array.new(joystick.axisScale.size, 0.00)
        buttons = Array.new(11, 0.00)
        max_linear_speed = joystick.maxSpeed
        max_rot_speed = joystick.maxRotationSpeed
        puts "          number of buttons: #{buttons.length}"
        puts "          max_linear_speed: #{max_linear_speed}"
        puts "          max_rot_speed: #{max_rot_speed}"
        puts "DONE."
    else
        puts 'Couldn\'t find device ' + device_name + '. Using joystick gui instead.'
        locomotion_control.on_reachable do
            joystickGui = Vizkit.default_loader.create_plugin('VirtualJoystick')
            joystickGui.show
            joystickGui.connect(SIGNAL('axisChanged(double, double)')) do |x, y|
                motion_cmd = Types::Base::Commands::Motion2D.new
                motion_cmd.translation = x * 0.1
                motion_cmd.rotation =  - y.abs() * Math::atan2(y, x.abs()) / 1.0 * 0.3

                motion_port = locomotion_control.port('motion_command')
                motion_port.write(motion_cmd) do |result|
                    puts "Sent command #{motion_cmd.translation} and #{motion_cmd.rotation}"
                end
            end
        end
    end

    # Get the logger from the bundles
    #joystick_logger_task =  TaskContext.get 'joystick_Logger'
    #motion_port_logger = joystick_logger_task.port('exoter/joystick.motion_command')
    #motion_port_logger.disconnect_all

    # Get the logger async
    #joystick_logger = Orocos::Async.proxy 'joystick_Logger'

    # Get the joystick in async
    joystick_async = Orocos::Async.proxy 'joystick'

    # Read the Raw Commands
    raw_cmd_port = joystick_async.port('raw_command')


    raw_cmd_port.on_data do |raw_command|

        #puts "Pressed at: #{raw_command.time}"

        # Axes
        i = 0
        current_axes = Array.new(joystick.axisScale.size, 0.00)
        raw_command.axes.elements.each do |item|
            current_axes[i] = item
            i = i + 1
        end

        #Buttons
        i = 0
        current_buttons = Array.new(11, 0.00)
        raw_command.buttons.elements.each do |item|
            current_buttons[i] = item
            i = i + 1
        end

        # Check Axes changed
        unless (axes == current_axes)

            # Main Axes set have priority
            unless (axes[5] == current_axes[5]) and (axes[4] == current_axes[4])
                x_axis = current_axes[5]
                y_axis = current_axes[4]
            else
                x_axis = current_axes[1]
                y_axis = current_axes[0]
            end

            #PTU Joints information
            pan_axis = current_axes[2]
            tilt_axis = current_axes[3]

            #puts "x_axis: #{x_axis}"
            #puts "y_axis: #{y_axis}"
            #puts "pan_axis: #{pan_axis}"
            #puts "tilt_axis: #{tilt_axis}"

            axes = current_axes;
            axes_changed = TRUE
        end

        # Check buttons changed
        unless (buttons == current_buttons)

            # Check buttons
            if current_buttons[8] == 1.0 ## emergency stop button 5
                # TO-DO Kill locomotion control
            end

            if current_buttons[5]==1.0
                rover_speed_ratio = rover_speed_ratio + 0.050000
            elsif current_buttons[7]==1.0
                rover_speed_ratio = rover_speed_ratio - 0.050000
            end

            if (rover_speed_ratio > 1.0)
                rover_speed_ratio = 1.0
            elsif (rover_speed_ratio < 0.0)
                rover_speed_ratio = 0.00
            end

	    if current_buttons[1]==1.0
		if direct_control == FALSE
			direct_control = TRUE
		elsif direct_control == TRUE
			direct_control = FALSE
		end
	    end

            buttons = current_buttons;
            buttons_changed = TRUE
        end

        # Send the command to the locomotion control
        if (axes_changed or buttons_changed)

            # Form the command
            x_velocity = x_axis * max_linear_speed * rover_speed_ratio
            y_velocity = y_axis

            translation = x_velocity
            rotation = (-y_velocity.abs * Math::atan2(y_velocity, x_velocity.abs) / Math::PI) * max_rot_speed * rover_speed_ratio
            if translation < 0.00
                rotation = -rotation
            end

            # Point turn button
            if buttons[10]==1.0
                translation = 0.00
            elsif rotation != 0.00 and translation == 0.00
                translation = 0.001 * max_linear_speed * rover_speed_ratio
            end

            puts "*** SEND TO HDPR ***"
            puts "rover_speed_ratio: #{rover_speed_ratio}"
            puts "translation: #{translation}"
            puts "rotation: #{rotation}"
            puts "pan_position: #{pan_pos}"
            puts "tilt_position: #{tilt_pos}"


	    axes_changed = FALSE
            buttons_changed = FALSE
        end

	# Control of the PTU (the rock driver uses position commands so the control is really sketchy)
	if direct_control == TRUE
		pan_pos = (pan_axis * Math::PI)
        	tilt_pos = (tilt_axis * Math::PI/2) - tilt_offset
	else
            	pan_pos = pan_pos  + (pan_axis * delta_theta)
            	tilt_pos = tilt_pos + (tilt_axis * delta_theta)
	end
	if pan_pos > max_pan
		pan_pos = max_pan
	elsif pan_pos < min_pan
		pan_pos = min_pan
	end
	if tilt_pos > max_tilt
		tilt_pos = max_tilt
	elsif tilt_pos < min_tilt
		tilt_pos = min_tilt
	end
	    
	    pan_writer.write(pan_pos)
	    tilt_writer.write(tilt_pos)

        ## ############ ##
        # Motion commands
        ## ############ ##
        locomotion_control.on_reachable do
            motion_cmd = Types::Base::Commands::Motion2D.new
            motion_cmd.translation = translation
            motion_cmd.rotation =  rotation
            motion_port = locomotion_control.port('motion_command')
            motion_port.write(motion_cmd) do |result|
                #puts "Sent command #{motion_cmd.translation} and #{motion_cmd.rotation}"
            end
            #loggint_port_writer = joystick_logger_task.port('exoter/joystick.motion_command').writer
            #loggint_port_sample = loggint_port_writer.new_sample
            #loggint_port_sample.translation = translation
            #loggint_port_sample.rotation = rotation
            #loggint_port_writer.write(loggint_port_sample)
            #puts "Logging command #{motion_cmd.translation} and #{motion_cmd.rotation}"
        end

        ## ############## ##
        # Send PTU Positions
        ## ############## ##
        ptu_control.on_reachable do
           widget.sendButton.connect(SIGNAL('clicked()')) do
               pan_pos = (widget.pan_position.text.to_f * Math::PI / 180.00)
               tilt_pos = (widget.tilt_position.text.to_f * Math::PI / 180.00) - tilt_offset
	       #rot = ptu.rbsFromPanTilt(pan_pos,tilt_pos)
	       #rot_writer.write(rot)
	       pan_writer.write(pan_pos)
	       tilt_writer.write(tilt_pos)
           end
        end


        #Commented because Asyn API cannot find the port of a logger task when it is not in the local hostt
        #joystick_logger.on_reachable do
        #    puts "joystick_logger"
        #    motion_cmd = Types::Base::Commands::Motion2D.new
        #    motion_cmd.translation = translation
        #    motion_cmd.rotation =  rotation
        #    puts joystick_logger.port_names[2]
        #    motion_port = joystick_logger.port(joystick_logger.port_names[2])
        #    motion_port.write(motion_cmd) do |result|
        #        puts "Logging command #{motion_cmd.translation} and #{motion_cmd.rotation}"
        #    end
        #end

        ## ###### ##
        # Update GUI
        ## ###### ##
        #puts widget.lcd_translation.public_methods
        #puts "TRANSLATION:#{translation*100.00}"
        widget.lcd_translation.display(translation*100.00)
        widget.lcd_heading.display(rotation*180.00/Math::PI)
        widget.bar_rover_ratio.setValue(rover_speed_ratio*100.00)
        widget.bar_ptu_ratio.setValue(100.00)
        widget.lcd_pan.display( 0 )
        widget.lcd_tilt.display( 0 )


        ## ######### ##
        # Update Images
        ## ######### ##

        # ExoTer Stop
        pixmap = Qt::Pixmap.new(Bundles.find_file('data/gui/images', 'exoter_start.png'))

           if rotation > 0.00
               if translation == 0.00
                   # Spot-turn to left
                   pixmap = Qt::Pixmap.new(Bundles.find_file('data/gui/images', 'exoter_point_turn_left.png'))
               elsif translation > 0.00
                   # Ackerman left forward
                   pixmap = Qt::Pixmap.new(Bundles.find_file('data/gui/images', 'exoter_ackerman_left_fwd.png'))
               else
                   # Ackerman left back
                   pixmap = Qt::Pixmap.new(Bundles.find_file('data/gui/images', 'exoter_ackerman_right_back.png'))
               end
           elsif rotation < 0.00
               if translation == 0.00
                   # Spot-turn to right
                   pixmap = Qt::Pixmap.new(Bundles.find_file('data/gui/images', 'exoter_point_turn_right.png'))
               elsif translation > 0.00
                   # Ackerman right forward
                   pixmap = Qt::Pixmap.new(Bundles.find_file('data/gui/images', 'exoter_ackerman_right_fwd.png'))
               else
                   # Ackerman right back
                   pixmap = Qt::Pixmap.new(Bundles.find_file('data/gui/images', 'exoter_ackerman_left_back.png'))
               end
           elsif rotation == 0.00
               if translation > 0.00
                   # Forward
                   pixmap = Qt::Pixmap.new(Bundles.find_file('data/gui/images', 'exoter_fwd.png'))
               elsif translation < 0.00
                   # Backward
                   pixmap = Qt::Pixmap.new(Bundles.find_file('data/gui/images', 'exoter_back.png'))
               end
           end
        
        widget.image.setPixmap(pixmap)
    end

    #Locomotion and PTU control
    locomotion_control.on_reachable{widget.setEnabled(true)}
    locomotion_control.on_unreachable{widget.setEnabled(false)}
    ptu_control.on_unreachable{widget.setEnabled(false)}

    # Show the GUI
    widget.show
    Vizkit.exec

    #Readline::readline("Press Enter to exit\n") 
end


