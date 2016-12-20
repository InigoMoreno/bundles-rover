#!/usr/bin/env ruby
require 'vizkit'

Orocos.initialize

hosts = []
hosts << "localhost"

hosts.each do |host|    
    Orocos::Async.name_service << Orocos::Async::CORBA::NameService.new(host)
end

compound_display = Vizkit.default_loader.CompoundDisplay
compound_display.set_grid_dimensions(2,3) # 2 rows, 4 columns
compound_display.show_menu(false)
compound_display.show

compound_display.configure(0, "pancam_left", "frame", "ImageView")
compound_display.configure(1, "pancam_right", "frame", "ImageView")
compound_display.configure(2, "tofcamera_mesasr", "distance_frame", "ImageView")
compound_display.configure(3, "camera_bb2", "left_frame", "ImageView")
compound_display.configure(4, "camera_bb3", "center_frame", "ImageView")
compound_display.configure(5, "velodyne_lidar", "ir_interp_frame", "ImageView")

#run qt main loop
Vizkit.exec
