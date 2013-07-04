require 'pry_debug'

# deck of cards for blackjack game
$deck = []
(1..13).each {|i| $deck.concat([i]*16)} # sets up a 4 deck stack for the game
$deck = $deck.shuffle

class Player
	def initialize name
		@kill_check = false
		@name = name
		@hands = {:cards=>[$deck.pop(2)],:value=>[0]}
		@hands_counter = 0
		print "How much money are you gambling with? "
		@bank = gets.chomp.to_i
		@bet = 0
		ante_up
		puts "#{@name} antes up $20. Money left: $#{@bank}."
	end

	def ante_up # player must ante up to get into the game
		@bank -= 20
		@bet += 20
	end

	def payout 
		winnings = @bet * 2
		@bank += winnings
		puts "#{@name} won $#{winnings} and now has $#{@bank} total!"
	end

	def pushed
		@bank += @bet
		puts "#{@name} won back their bet of $#{@bet} and now has $#{@bank} total."
	end

	def loss
		puts "#{@name} lost their bet of $#{@bet} and now has $#{@bank} total."
	end

	def get_name # allows return of name 
		return @name
	end

	def check_value
		return @hands[:value][@hands_counter]
	end

	def check_hand
		puts "#{@name}'s' current hands: #{@hands[:cards][@hands_counter]}"
	end

	def take_a_turn
		evaluate_hand
		decide_next_move
	end

	def evaluate_hand # run through a hand's cards to get the total
		unless @kill_check
			@hands[:value][@hands_counter] = 0
				@hands[:cards][@hands_counter].sort.reverse.each do |card| # reverse sort the hand's cards to do ACEs last
					if card == 1 # ACE cards need to determine best choice: 11 or 1
						if (@hands[:value][@hands_counter] + 11) <= 21 
							@hands[:value][@hands_counter] += 11
						elsif (@hands[:value][@hands_counter] + 1) <= 21
							@hands[:value][@hands_counter] += 1
						else
							bust
						end
					elsif card < 11 # normal number => take face value
						@hands[:value][@hands_counter] += card
					else # face card => 10 pts
						@hands[:value][@hands_counter] += 10
					end
				end
			puts "#{@name}'s hand is #{@hands[:cards][@hands_counter]} and totals to: #{@hands[:value][@hands_counter]}"
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
			puts "What do you want to do?"
			print "Hit, Stand, or Check hand: "
			choice = gets.chomp.downcase
			case choice
				when "hit"
					then draw_card
				when "stand"
					then stand
				when "check hand"
					then
						check_hand
						decide_next_move
				else
					puts "I did not understand that command. Please try again."
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
		@name = "The Dealer"
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
 

# sets up the game with X players and a dealer. Deals out the starting hands.
player_lineup = [] # empty array will hold all player objects
print "How many players are playing? "
num_players = gets.chomp.to_i
counter = 1
num_players.times do |player| # for each player playing get their name
	print "What is Player #{counter}'s name? "
	player_name = gets.chomp 
	player_lineup << Player.new(player_name) # adds a new player to the lineup
	counter += 1
end
puts
player_lineup << Dealer.new # pass in the Dealer last to the linup


#start the game
player_lineup.each {|player| player.take_a_turn} # go around table for each player and let them play


# after all players and the dealer have gone compare their hands
dealer_score = player_lineup[-1].check_value
player_lineup.pop

if dealer_score > 21
	puts "All players who did not bust win by default!"
	player_lineup.each do |player|
		player_score = player.check_value
		if player_score <= 21
			player.payout
		else
			player.loss
		end
	end
else
	player_lineup.each do |player| 
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
