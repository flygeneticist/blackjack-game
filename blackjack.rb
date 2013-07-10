require_relative './classes/engine'
require_relative './classes/casino'
require_relative './classes/cashier'
require_relative './classes/player'
require_relative './classes/dealer'

game = Game_Engine.new
game.start_casino
