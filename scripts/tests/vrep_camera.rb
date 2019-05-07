require 'vizkit'
require 'rock/bundle'
require 'readline'

include Orocos

Bundles.initialize
Orocos::Process.run 'unit_following', 'navigation', 'control', 'simulation', 'autonomy' do

    puts "Setting up simulation_vrep"
    simulation_vrep = Orocos.name_service.get 'simulation'
    Orocos.conf.apply(simulation_vrep, ['hdpr'], :override => true)
    simulation_vrep.configure
    puts "done"

    puts "Connecting ports"

    simulation_vrep.start

    Readline::readline("Press ENTER to exit\n")
end
