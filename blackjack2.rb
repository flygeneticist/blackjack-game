#require 'pry'

# Casino class handles the transfer of money, the players at a table and in a round
class Casino
	attr_accessor :deck, :casino_players, :round_queue
	def initialize
		@deck = []
		# hash queues structured as {:player_name => player_object}
		@casino_players = {} # will hold all players at a table, playing or not
		@round_queue = {} # will hold all players who are actively playing a round
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

	def player_leaves_round player_name # remove player from next round, but not table
		@casino_players["#{player_name}"] = @round_queue["#{player_name}"]
		@round_queue.delete("#{player_name}")
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

	# setting the money owed and taken at the end of a hand
	def payout
		winnings = @wager * 2
		@bank += winnings
		puts "#{@name} won $#{winnings} and now has $#{@bank} total!"
	end

	def pushed
		@bank += @wager
		puts "#{@name} won back their bet of $#{@wager} and now has $#{@bank} total."
	end

	def loss
		puts "#{@name} lost their bet of $#{@wager} and now has $#{@bank} total."
	end
end


# players will have hands of cards, a wager, and a bank of money to gamble with
class Player
	attr_accessor :hands, :hands_counter, :bank, :wager
	def initialize name
		@kill_check = false
		@name = name
		@hands = []
		@hands_counter = 0
		print 'How much money are you gambling with? '
		@bank = gets.chomp.to_i
		@wager = 0
		ante_up
		puts "#{@name} antes up $20. Money left: $#{@bank}."
	end

	def ante_up # player must ante up to get into the game
		@bank -= 20
		@wager += 20
	end

	def take_a_turn
		evaluate_hand
		decide_next_move
	end

	def evaluate_hand # run through a hand's cards to get the total
		unless @kill_check
			@hands[:value][@hands_counter] = 0
				@hands[:cards][@hands_counter].sort.reverse.each do |card| # reverse sort the hand's cards to do ACEs last
					if card == 'A' # ACE cards need to determine best choice: 11 or 1
						if (@hands[:value][@hands_counter] + 11) <= 21
							@hands[:value][@hands_counter] += 11
						elsif (@hands[:value][@hands_counter] + 1) <= 21
							@hands[:value][@hands_counter] += 1
						else
							bust
						end
					elsif card == 'J' || card == 'Q' || card == 'K' # face card => 10 pts
						@hands[:value][@hands_counter] += 10
					else # normal number => take face value
						@hands[:value][@hands_counter] += card
					end
				end
			puts "#{@name}"s hand is #{@hands[:cards][@hands_counter]} and totals to: #{@hands[:value][@hands_counter]}"
		end
	end

	private
	def draw_card
		new_card = $deck.pop
		puts "#{@name} is dealt a card and got: #{new_card}"
		@hands[:cards][@hands_counter] << new_card
		take_a_turn
	end

	def decide_next_move
		if (@hands[:value][@hands_counter] <= 21)
			puts 'What do you want to do?'
			print 'Hit, Stand, or Check hand: '
			choice = gets.chomp.downcase
			case choice
				when 'hit'
					then draw_card
				when 'stand'
					then stand
				when 'check hand'
					then
						check_hand
						decide_next_move
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
		@name = 'The Dealer'
		@hands = {:cards=>[$deck.pop(2)],:value=>[0]}
		@hands_counter = 0
		puts "#{@name} has a #{@hands[:cards][@hands_counter][0]} showing." # reveals the dealer's one card face up to the players
		puts
	end

	def decide_next_move
		if @hands[:value][@hands_counter] <= 21
			if @hands[:value][@hands_counter] < 17
				draw_card
				evaluate_hand
			else
				stand
			end
		else
			bust
		end
	end
end

# Start runtime code
casino = Casino.new # sets up the game with a casino
casino.make_a_deck

puts "Welcome to the world's finest blackjack casino."
print 'How many players are playing? '
num_players = gets.chomp.to_i
counter = 1
num_players.times do |player| # for each player playing get their name
	print "What is Player #{counter}'s name? "
	player_name = gets.chomp
	casino.player_enters_casino(player_name) # adds a new player to the lineup
	counter += 1
end
puts

round_queue << Dealer.new # create a dealer

# go around for each player and let them play
round_queue.each {|player| player.take_a_turn}

# after all players and the dealer have gone compare their hands
dealer_score = round_queue[-1].check_value
if dealer_score > 21
	puts 'All players who did not bust win by default!'
	round_queue[0..-2].each do |player|
		player_score = player.check_value
		if player_score <= 21
			player.payout
		else
			player.loss
		end
	end
else
	round_queue[0..-2].each do |player|
		player_score = player.check_value
		player_name = player.get_name
		if player_score > 21
			puts "#{player_name} has busted and lost!"
			player.loss
		elsif player_score > dealer_score
			puts "#{player_name} has beaten the dealer!"
			player.payout
		elsif player_score < dealer_score
			puts "#{player_name} has lost to the dealer!"
			player.loss
		elsif player_score == dealer_score
			puts "#{player_name} tied the dealer. The hand ended in a push."
			player.pushed
		end
	puts
	end
end
