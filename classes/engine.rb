class Game_Engine
  def start_casino # sets up the game with a casino, dealer, a deck of cards, and runs.
    casino = Casino.new
    dealer = Dealer.new
    puts "Welcome to the world's finest blackjack casino."
    get_players(casino, dealer)
  end

  def get_players(casino, dealer) # get the # of initial players and their names from the users
    print 'How many players are playing? '
    num_players = gets.chomp.to_i
    counter = 1
    num_players.times do |player| # for each player playing get their name
      print "What is Player #{counter}'s name? "
      user_name = gets.chomp
      casino.player_enters_casino(user_name) # adds a new player to the casino floot
      counter += 1
    end
    begin_round_of_play(casino, dealer)
  end

  def begin_round_of_play(casino, dealer)
    round_counter = 0 # setup a counter to track rounds played
    while casino.casino_players != 0
      if round_counter == 10 # refresh deck after every 10 rounds
        casino.deck = Deck.new
        round_counter = 0 # reset round counter
      else
        round_counter += 1
      end
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      puts "Let's start the next round!"
      puts "The Dealer will now be accepting bets."
      # allow for all players present in the casino to ante up and get in on the next round
      casino.casino_players.each_value do |player|
        casino.kick_broke_players(player)
        player.ante_up(casino)
      end
      # let the get a hands for the round
      casino.deal_out_hands (dealer)
      # begin the main play allowing each player at the table to play in turn
      casino.round_queue.each_value do |player|
        player.take_a_turn (casino)
      end
      # after the players have gone, the dealer shows his hand and plays
      # if all players bust dealer does not go. Set score to 22.
      viable_player = false
      casino.round_queue.each_value do |player|
        player.value.each do |hand_value|
          if hand_value <= 21
            viable_player = true
          end
        end
      end

      if viable_player == true
        dealer.take_a_turn (casino)
      else
        dealer.value = 22
      end
      settle_money_changes(dealer,casino.round_queue)
      dealer = Dealer.new # new dealer comes to the table each round.
    end
    puts
    puts "Thanks for playing!"
  end

  def settle_money_changes(dealer, round_queue) # Setting the winnings/losses after the dealer busts or stands.
    cashier = Cashier.new(dealer, round_queue)
    cashier.settle_scores
  end
end
