class Player
  attr_accessor :hands, :hands_counter, :wager, :bank, :value, :kill_check
  attr_reader :name

  def initialize (name)
    @kill_check = false
    @name = name
    @hands = []
    @hands_counter = 0
    @value = []
    @bank = 1000
    @wager = 0
  end

  def take_a_turn (casino)
    unless self.kill_check
      evaluate_hand
      check_for_special_hand
      display_hand
      decide_next_move (casino)
    end
  end

  def display_hand
    print "#{name}'s hand ##{self.hands_counter+1}: "
    self.hands[self.hands_counter].each {|card| print "#{card.join("-")},"}
    print " and totals: #{value[self.hands_counter]}"
    puts
  end

  # player must ante up to get into the game. Take user's bet.
  def ante_up (casino)
    puts "#{name}'s Turn:"
    puts "How much money (if any) are you wagering this round?"
    puts "Minimum buy-in of $#{casino.table_min} and a table limit of $#{casino.table_limit}."
    print "You may also bet $0 to skip out on this round: $"
    bet = gets.chomp.to_i
    if bet == 0 # do not add player to the round if zero or negative bet
      return
    else
      while bet > casino.table_limit || bet < casino.table_min || check_wager(bet) == false
        print 'That is not an acceptable wager. Please try again: '
        bet = gets.chomp.to_i
      end
      # bet meets all criteria...
      self.bank -= bet
      self.wager = bet
      # reset the previous round's values and hands
      self.hands = []
      self.hands_counter = 0
      self.value = []
      puts "#{name} antes up $#{bet}. Bank left: $#{bank}."
      self.kill_check = false
      casino.player_joins_round(self.name) # adds a new player to the next round's lineup
    end
    puts
  end

 # run through a player's cards in their hand to get the total
  def evaluate_hand
    self.value[self.hands_counter] = 0
    # sort by numbers first then by stings to get ACEs last
    self.hands[self.hands_counter].sort_by {|target| target[0].to_i}.each do |card|
      if card[0] == 'A' # ACE cards need to determine best choice: 11 or 1
        if (self.value[self.hands_counter] + 11) <= 21
          self.value[self.hands_counter] += 11
        elsif (self.value[self.hands_counter] + 1) <= 21
          self.value[self.hands_counter] += 1
        else
          bust
        end
      elsif card[0].to_i == 0 # face card => 10 pts
        self.value[self.hands_counter] += 10
      else # normal number => take face value
        self.value[self.hands_counter] += card[0]
      end
    end
  end

  def check_for_special_hand
    # the checks below are special for the first turn only (2 cards)
    if self.hands[self.hands_counter].length == 2
      # checks for a blackjack on the first deal
      if self.value[self.hands_counter] == 21
        puts "Blackjack!"
      # checks for the option to split a hand (two cards with the same face)
      elsif self.hands[self.hands_counter][0][0] == self.hands[self.hands_counter][1][0]
        puts "This hand can be split if you wish."
      end
    end
  end

  def decide_next_move (casino)
    if self.value[self.hands_counter] <= 21
      puts 'What do you want to do?'
      puts "Special cases: Double Down, Split, or Surrender: "
      print "Standard choices: Hit or Stand? "
      choice = gets.chomp.downcase
      # check user input to determine correct action to take
      case choice
        when 'double down' # take one more card, double wager, and force stand on that hand
          then
            if self.hands[self.hands_counter].length == 2 # only available if first turn
              self.wager += self.wager
              casino.deal_card(self)
              evaluate_hand
              stand
            else
              reset_bad_choice(choice, casino)
            end
        when 'hit' # take one card
          then
            casino.deal_card(self)
            take_a_turn (casino)
        when 'stand' # end round and take current score
          then stand
        when 'split' # split hand and play each seperately
          then
            if self.hands[self.hands_counter][0] == self.hands[self.hands_counter][1]
              casino.split_hand(self)
            else
              reset_bad_choice(choice, casino)
            end
        when 'surrender' # allow late-surrender only! loose 1/2 wager and fold.
          then
            if self.hands[self.hands_counter].length != 2 # only available after first turn
              puts "You surrender this hand and fold."
              self.value[self.hands_counter] = 100 # ie forces a bust
              bust
            else
              reset_bad_choice(choice, casino)
            end
      else
        puts 'I did not understand that command. Please try again.'
        decide_next_move (casino)
      end
    else
      bust
    end
  end

  def reset_bad_choice(choice, casino)
    puts "You cannot #{choice} that hand!"
    decide_next_move (casino)
  end

  private
  def check_wager (bet) # check money wagered is less than or equal player's bank
    unless bet <= self.bank
      return false
    else
      return true
    end
  end

  def stand # end evaluate_hand loop w/o changing hand_value further.
    self.kill_check = true
    puts "#{name} stands."
    puts
  end

  def bust # hand went over 21 and player loses.
    self.kill_check = true
    puts "#{name} has busted!"
    puts
  end
end
