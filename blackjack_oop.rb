#require 'pry'

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
  def player_enters_casino player_name # add a new player to the casino floor
    @casino_players["#{player_name}"] = Player.new("#{player_name}")
  end

  def player_leaves_casino player_name # remove player completely from the casino
    @casino_players.delete("#{player_name}")
  end

  def player_joins_round player_name # add a player to the next round at the table
    @round_queue["#{player_name}"] = @casino_players["#{player_name}"]
  end

  def player_leaves_round player_name # remove player from next round, but not the casino floor
    @round_queue.delete("#{player_name}")
  end

  # start the round using the new list of bidding players
  def deal_out_hands (dealer)
    puts "No more bets please. The cards are being dealt."
    @round_queue.each do |player|
        player[1].hands << @deck.pop(2)
    end
    dealer.hands << @deck.pop(2)
    # let players know what the first card the dealer has.
    puts "The Dealer has a #{dealer.hands[0][0].join("-")} showing."
    # this is the point at which insurance would be offered if dealer has an ace showing...
    puts
  end

  def deal_card (player)
    new_card = @deck.pop()
    puts
    puts "#{player.name} drew a: " + new_card.join("-").to_s
    player.hands[player.hands_counter] << new_card
    player.display_hand
  end

  #split up a hand into two seperate hands
  def split_hand (player)
    while player.hands_counter <= player.hands.length
      deal_card (player)
      take_a_turn (self)
      hands_counter += 1
    end
  end

  # handles all of the money exchanges for the players who've not busted at the end of the round.
  def settle_scores (dealer)
    dealer_score = dealer.value[0]
    @round_queue.each do |player|
      player[1].value.each do |player_score|
        if player_score == 100
          @bank += @wager/2
          puts "#{@name} surrenders and recieves $#{@wager/2}. Bank left: $#{@bank}."
        elsif dealer_score > 21 && player_score <= 21
          winnings = player[1].wager * 2 # pays out 2:1
          player[1].bank += winnings
           puts "#{player[1].name}: won $#{winnings} and now has $#{player[1].bank} total."
        else
          if player_score > dealer_score && player_score <= 21
            if player_score == 21
              puts "#{player[1].name} got blackjack!"
              winnings = (player[1].wager + player[1].wager*(3.0/2.0)).to_i # pays out 3:2
              player[1].bank += winnings
            else
              winnings = player[1].wager * 2 # pays out 2:1
              player[1].bank += winnings
            end
            puts "#{player[1].name}: won $#{winnings} and now has $#{player[1].bank} total."
          elsif player_score == dealer_score
              winnings = player[1].wager # pays back player's wager
              player[1].bank += winnings
              puts "#{player[1].name}: pushed and got back the bet of $#{winnings} and now has $#{player[1].bank} total."
          else # player lost to dealer
            puts "#{player[1].name}: lost $#{player[1].wager} and now has $#{player[1].bank} total."
          end
        end
        player_leaves_round(player[1].name)
      end
      if player[1].bank <= 0
        puts "#{player[1].name} has run out of money and was kicked out of the casino!"
        player_leaves_casino(player[1].name)
      end
    puts
    end
  end
end


class Player
  attr_accessor :hands, :hands_counter, :wager, :name, :bank, :value
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
    puts "Mininimum buy-in of $#{casino.table_min} and a table limit of $#{casino.table_limit}."
    print "You may also bet $0 to skip out on this round: $"
    bet = gets.chomp.to_i
    if bet == 0 # do not add player to the round if place a zero or negative bet

    else
      while bet > casino.table_limit || bet < casino.table_min || check_wager(bet) == false
        print 'That is not an acceptable wager. Please try again: '
        bet = gets.chomp.to_i
      end
      # bet meets all criteria...
      @bank -= bet
      @wager = bet
      # reset the previous round's values and hands
      @hands = []
      @hands_counter = 0
      @value = []
      puts "#{@name} antes up $#{bet}. Bank left: $#{@bank}."
      @kill_check = false
      casino.player_joins_round(@name) # adds a new player to the next round's lineup
    end
    puts
  end

  def take_a_turn (casino)
    evaluate_hand
    decide_next_move (casino)
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
      # the checks below are special for the first turn only (2 cards)
      if @hands[@hands_counter].length == 2
        # checks for a blackjack on the first deal
        if @value[@hands_counter] == 21
          puts "#{@name}'s hand ##{@hands_counter+1} totals: #{@value[@hands_counter]}"
          puts "Blackjack!"
        # checks for the option to split a hand (two cards with the same face)
        elsif @hands[@hands_counter][0][0] == @hands[@hands_counter][1][0]
          puts "#{@name}'s hand ##{@hands_counter+1} totals: #{@value[@hands_counter]}"
          puts "This hand can be split if you wish."
        end
      else
        # if no special starting hands are found display standard message
        puts "#{@name}'s hand ##{@hands_counter+1} totals: #{@value[@hands_counter]}"
      end
    end
  end

  def decide_next_move (casino)
    if (@value[@hands_counter] <= 21)
      puts 'What do you want to do?'
      puts "Special cases: Double Down, Split, or Surrender: "
      print "Standard choices: Hit or Stand? "
      choice = gets.chomp.downcase
      # check user input to determine correct action to take
      case choice
        when 'double down' # take one more card, double wager, and force stand on that hand
          then
            if @hands[@hands_counter].length == 2 # only available if first turn
              @wager += @wager
              casino.deal_card(self)
              evaluate_hand
              stand
            else
              puts "You cannot double down on this hand."
              decide_next_move (casino)
            end
        when 'hit' # take one card
          then
            casino.deal_card(self)
            take_a_turn (casino)
        when 'stand' # end round and take current score
          then stand
        when 'split' # split hand and play each seperately
          then
            if @hands[@hands_counter][0] == @hands[@hands_counter][1]
              casino.split_hand(self)
            else
              puts "You cannot split that hand!"
              decide_next_move (casino)
            end
        when 'surrender' # allow late-surrender only! loose 1/2 wager and fold.
          then
            if @hands[@hands_counter].length != 2 # only available after first turn
              puts "You surrender this hand and fold."
              @value[@hands_counter] = 100 # ie forces a bust
              bust
            else
              puts "You cannot surrender a hand until having drawn at least one card."
              decide_next_move (casino)
            end
        else
          puts 'I did not understand that command. Please try again.'
          decide_next_move (casino)
      end
    else
      bust
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

  # end evaluate_hand loop w/o changing hand_value further.
  def stand
    @kill_check = true
    puts "#{@name} stands."
    puts
  end

  # hand went over 21 and player loses.
  def bust
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

  def decide_next_move (casino)
    if @value[@hands_counter] <= 21
      if @value[@hands_counter] < 17
        casino.deal_card(self)
        take_a_turn (casino)
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

while casino.casino_players != 0
  dealer = Dealer.new # the dealers get tired quickly in this casino and need to be replaced often
  puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  puts "Let's start the next round!"
  puts "The Dealer will now be accepting bets."
  puts
  # allow for all players present in the casino to ante up and get in on the next round
  casino.casino_players.each do |player|
    player[1].ante_up(casino)
  end
  # let the get a hands for the round
  casino.deal_out_hands (dealer)
  # begin the main play allowing each player at the table to play in turn
  casino.round_queue.each do |player|
    player[1].display_hand
    player[1].take_a_turn (casino)
  end
  # after the players have gone, the dealer shows his hand and plays
  # if all players bust dealer does not go.
  # set dealer score == 21 and move on to settling money.
  dealer.display_hand
  dealer.take_a_turn (casino)
  # Setting the winnings/losses after the dealer busts or stands.
  casino.settle_scores(dealer)
end
puts
puts "Thank you for playing!"
