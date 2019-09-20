#!/usr/bin/env ruby

require 'orocos'
require 'rock/bundle'
require 'readline'
include Orocos

# Initialize bundles to find the configurations for the packages
Bundles.initialize

# Execute the task
Orocos::Process.run 'traversability::Task' => 'traversability' do

    # Configure
    traversability = TaskContext.get 'traversability'
    Orocos.conf.apply(traversability, ['default'], :override => true)
    traversability.configure

    # Start
    traversability.start

    Readline::readline("Press Enter to exit\n") do
    end
end
