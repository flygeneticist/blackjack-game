require_relative './deck.rb'

class Casino
  attr_accessor :deck, :casino_players, :round_queue
  attr_reader :table_limit, :table_min

  def initialize
    @deck = Deck.new
    @table_min = 10
    @table_limit = 100
    @casino_players = {} # will hold all players at a table, playing or not
    @round_queue = {} # will hold all players who are actively playing a round
  end

  #control the flow of players at the table and players playing a round
  def player_enters_casino (player_name) # add a new player to the casino floor
    self.casino_players["#{player_name}"] = Player.new("#{player_name}")
  end

  def player_joins_round (player_name) # add a player to the next round at the table
    self.round_queue["#{player_name}"] = self.casino_players["#{player_name}"]
  end

  def player_leaves_round (player_name) # remove player from next round, but not the casino floor
    self.round_queue.delete("#{player_name}")
  end

  def deal_out_hands (dealer) # deals out hands using the new list of bidding players
    puts "No more bets please. The cards are being dealt."
    self.round_queue.each do |player|
      player[1].hands << deck.deal_new_hand
    end
    dealer.hands << deck.deal_new_hand
    # let players know what the dealer's first card is.
    puts "The Dealer has a #{dealer.hands[0][0].join("-")} showing."
    puts
  end

  def split_hand (player) #split up a hand into two seperate hands
    while player.hands_counter <= player.hands.length
      deal_card (player)
      take_a_turn (self)
      hands_counter += 1
    end
  end

  def kick_broke_players (player)
    if player[1].bank <= 0
      puts "#{player[1].name} has run out of money and was kicked out of the casino!"
      self.casino_players.delete(player[1].name)
    end
    puts
  end
end
