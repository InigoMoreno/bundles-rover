#!/usr/bin/env ruby
require 'vizkit'

Orocos.initialize

hosts = []
hosts << "localhost"

hosts.each do |host|    
    Orocos::Async.name_service << Orocos::Async::CORBA::NameService.new(host)
end

compound_display = Vizkit.default_loader.CompoundDisplay
compound_display.set_grid_dimensions(1,2)
compound_display.show_menu(false)
compound_display.show

compound_display.configure(0, "pancam_left", "frame", "ImageView")
compound_display.configure(1, "pancam_right", "frame", "ImageView")

#run qt main loop
Vizkit.exec
