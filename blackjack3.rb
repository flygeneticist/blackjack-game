require 'pry'

class Casino
  attr_accessor :deck, :casino_players, :round_queue
  attr_reader :table_limit, :table_min

  def initialize
    @deck = []
    @table_min = 10
    @table_limit = 100
    # hash queues structured as {:player_name => player_object}
    @casino_players = {} # will hold all players at a table, playing or not
    @round_queue = {} # will hold all players who are actively playing a round
  end

  # make the deck at the start of a round
  def make_a_deck
    @deck = [] # clear the previous round's left over deck
    card_faces = [2,3,4,5,6,7,8,9,10,'J','Q','K','A']
    card_suits = ['C','D','H','S']
    # sets up a 4 deck stack for the game
    card_faces.each do |face|
      card_suits.each {|suit| 4.times {@deck << [face, suit]}}
    end
    @deck = @deck.shuffle
  end

  #control the flow of players at the table and players playing a round
  def player_enters_casino player_name # add a new player to the casino table
    @casino_players["#{player_name}"] = Player.new("#{player_name}")
  end

  def player_leaves_casino player_name # remove player completely from the casino
    @casino_players.delete("#{player_name}")
  end

  def player_joins_round player_name # add a player to the next round
    @round_queue["#{player_name}"] = @casino_players["#{player_name}"]
  end

  def player_leaves_round player_name # remove player from next round, but not the casino
    @casino_players["#{player_name}"] = @round_queue["#{player_name}"]
    @round_queue.delete("#{player_name}")
  end

  def deal_card (player)
    new_card = @deck.pop()
    puts "#{player[1].name} drew: " + new_card.join("-").to_s
    player[1].hands[player[1].hands_counter] << new_card
    player[1].display_hand
  end

  private
  # handling money owed and earned throughout the game
  def payout (player)
    winnings = player[1].wager * 2
    player[1].bank += winnings
    puts "#{player[1].name} won $#{winnings} and now has $#{player[1].bank} total!"
  end

  def pushed (player)
    player[1].bank += player[1].wager
    puts "#{player[1].name} won back their bet of $#{player[1].wager} and now has $#{player[1].bank} total."
  end

  def loss (player)
    puts "#{player[1].name} lost their bet of $#{player[1].wager} and now has $#{player[1].bank} total."
  end
end


class Player
  attr_accessor :hands, :hands_counter, :wager, :name, :bank
  def initialize name
    @kill_check = false
    @name = name
    @hands = []
    @hands_counter = 0
    @value = []
    @bank = 1000
    @wager = 0
  end

  def display_hand # this will display one hand only
    print "#{@name}'s hand ##{@hands_counter+1}: "
    @hands[@hands_counter].each do |card|
      print "#{card.join("-")} "
    end
    puts
  end

  # player must ante up to get into the game. Take user's bet.
  def ante_up (casino)
    puts "#{@name}'s Turn:"
    puts "How much money (if any) are you wagering this round?"
    puts "Min buy-in of $#{casino.table_min} and a table limit of $#{casino.table_limit}."
    print "You may also bet $0 to stand out this round: "
    bet = gets.chomp.to_i
    if bet <= 0 # do not add player to the round if place a zero or negative bet
      # lots of nothing going on here...for now.
    else
      while bet > casino.table_limit || bet < casino.table_min || check_wager(bet) == false
        print 'That is not an acceptable wager. Please try again: '
        bet = gets.chomp.to_i
      end
      @bank -= bet
      @wager = bet
      puts "#{@name} antes up $#{bet}. Bank left: $#{@bank}."
      casino.player_joins_round(@name) # adds a new player to the next round's lineup
    end
    puts
  end

  def take_a_turn
    evaluate_hand
    decide_next_move
  end

 # run through a player's cards in their hand to get the total
  def evaluate_hand
    unless @kill_check
      @value[@hands_counter] = 0
        # sort by numbers first then by stings to get
        # then sort the hand's cards to do ACEs last
        @hands[@hands_counter].sort_by {|target| target[0].to_i}.each do |card|
          if card[0] == 'A' # ACE cards need to determine best choice: 11 or 1
            if (@value[@hands_counter] + 11) <= 21
              @value[@hands_counter] += 11
            elsif (@value[@hands_counter] + 1) <= 21
              @value[@hands_counter] += 1
            else
              bust
            end
          elsif card[0] == 'J' || card[0] == 'Q' || card[0] == 'K' # face card => 10 pts
            @value[@hands_counter] += 10
          else # normal number => take face value
            @value[@hands_counter] += card[0]
          end
        end
      puts "#{@name}'s hand ##{@hands_counter+1} totals: #{@value[@hands_counter]}"
    end
  end

  private
  def check_wager (bet) # check money wagered is less than or equal player's bank
    unless bet <= @bank
      return false
    else
      return true
    end
  end

  def decide_next_move
    if (@value[@hands_counter] <= 21)
      puts 'What do you want to do?'
      print 'Hit, Stand, or Check hand: '
      choice = gets.chomp.downcase
      #binding.pry
      case choice
        when 'hit'
          then casino.deal_card (@name)
        when 'stand'
          then stand
        else
          puts 'I did not understand that command. Please try again.'
          decide_next_move
      end
    else
      bust
    end
  end

  def stand # end evaluate_hand loop w/o changing hand_value further.
    @kill_check = true
    puts "#{@name} stands."
    puts
  end

  def bust # hand went over 21. player loses.
    @kill_check = true
    puts "#{@name} has busted!"
    puts
  end
end


class Dealer < Player
  def initialize
    @kill_check = false
    @name = 'The Dealer'
    @hands = []
    @hands_counter = 0
    @value = []
  end

  def decide_next_move
    if @value[@hands_counter] <= 21
      if @value[@hands_counter] < 17
        casino.deal_card (@self)
        evaluate_hand
      else
        stand
      end
    else
      bust
    end
  end
end

# ------ runtime code below here ------
# sets up the game with a casino, dealer, and a deck of cards
casino = Casino.new
dealer = Dealer.new
casino.make_a_deck
puts "Welcome to the world's finest blackjack casino."
# get the # of initial players and their names from the users
print 'How many players are playing? '
num_players = gets.chomp.to_i
counter = 1
num_players.times do |player| # for each player playing get their name
  print "What is Player #{counter}'s name? "
  user_name = gets.chomp
  casino.player_enters_casino(user_name) # adds a new player to the casino floot
  counter += 1
end
puts
puts "Let's start the round!"
puts "The Dealer will now be accepting bets."
puts

# testing code below here....
# allow for all players present in the casino to ante up and get in on the next round
casino.casino_players.each do |player|
  player[1].ante_up(casino)
end
# start the round using the new list of bidding players
casino.round_queue.each do |player|
  player[1].hands << casino.deck.pop(2)
  player[1].display_hand
  player[1].take_a_turn
end

