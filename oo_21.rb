# rubocop:disable Metrics/MethodLength

module Listable
  def joinand(arr)
    case arr.size
    when 0 then ""
    when 1 then arr[0].to_s
    when 2 then arr[0].to_s + ' and ' + arr[1].to_s
    else "#{arr[0..-2].join(', ')}, and " + arr[-1].to_s
    end
  end
end

module Hand
  include Listable

  def show_hand
    "#{joinand(hand)} (total: #{total})"
  end

  def hit(deck)
    hand << deck.deal_one_card
  end

  def busted?
    total > TwentyOneGame::MAX_HAND_VALUE
  end

  def total
    sum = 0
    hand.each do |card|
      if card.ace?
        sum += 11
      elsif ['J', 'Q', 'K'].include?(card.face_value)
        sum += 10
      else
        sum += card.face_value.to_i
      end
    end

    hand.select(&:ace?).size.times do
      sum -= 10 if sum > TwentyOneGame::MAX_HAND_VALUE
    end
    sum
  end
end

class Participant
  include Hand

  attr_accessor :hand

  def initialize
    @hand = []
  end
end

class Player < Participant
  attr_reader :name

  def initialize(name)
    super()
    @name = name
  end
end

class Deck
  def initialize
    all_suits_and_values = Card::SUITS.product(Card::VALUES)
    @cards = all_suits_and_values.each_with_object([]) do |(suit, value), deck|
      deck << Card.new(suit, value)
    end
    cards.shuffle!
  end

  def deal_one_card
    cards.pop
  end

  private

  attr_reader :cards
end

class Card
  SUITS = %w(H D S C)
  VALUES = %w(2 3 4 5 6 7 8 9 10 J Q K A)

  attr_reader :suit, :face_value

  def initialize(suit, face_value)
    @suit = suit
    @face_value = face_value
  end

  def ace?
    face_value == 'A'
  end

  def face_value_name
    case face_value
    when 'J' then 'Jack'
    when 'Q' then 'Queen'
    when 'K' then 'King'
    when 'A' then 'Ace'
    else face_value
    end
  end

  def suit_name
    case suit
    when 'H' then 'Hearts'
    when 'D' then 'Diamonds'
    when 'S' then 'Spades'
    when 'C' then 'Clubs'
    end
  end

  def to_s
    "#{face_value_name} of #{suit_name}"
  end
end

class TwentyOneGame
  MAX_HAND_VALUE = 21
  DEALER_HIT_UNTIL = 17

  attr_reader :player, :dealer

  def initialize
    @player = Player.new(username)
    @dealer = Participant.new
    @deck = Deck.new
  end

  def play
    loop do
      show_welcome_message
      deal_cards
      show_initial_cards
      player_turn
      dealer_turn unless player.busted?
      show_final_cards
      show_result
      break unless play_again?
      reset_game
    end

    show_goodbye_message
  end

  private

  attr_accessor :deck

  def username
    name = ''
    loop do
      puts "Welcome! What's your name?"
      name = gets.chomp
      break unless name.empty?
      puts "Sorry, please enter a name."
    end
    name
  end

  def show_welcome_message
    puts "Welcome to the #{MAX_HAND_VALUE} game, #{player.name}! The computer" \
    " will be the dealer in this game."
  end

  def show_goodbye_message
    puts "Thank you for playing #{MAX_HAND_VALUE}! Goodbye!"
  end

  def deal_cards
    2.times do
      player.hand << deck.deal_one_card
      dealer.hand << deck.deal_one_card
    end
  end

  def show_player_hand
    puts "#{player.name} has: #{player.show_hand}."
  end

  def show_dealer_hand
    puts "Dealer has: #{dealer.show_hand}."
  end

  def show_initial_cards
    puts "Dealer has: #{dealer.hand.first} and unknown card."
    show_player_hand
  end

  def player_turn
    loop do
      break if player.busted?
      puts "Enter 'h' to hit or 's' to stay."
      answer = gets.chomp.downcase

      if answer == 'h'
        puts "You chose to hit!"
        player.hit(deck)
        show_player_hand
      elsif answer == 's'
        puts "You chose to stay. Dealer's turn!"
        break
      else
        puts "Sorry, that's not a valid choice."
      end
    end
  end

  def dealer_turn
    loop do
      break if dealer.busted?
      if dealer.total >= DEALER_HIT_UNTIL
        puts "Dealer stays."
        break
      else
        puts "Dealer hit!"
        dealer.hit(deck)
        show_dealer_hand
      end
    end
  end

  def show_final_cards
    if player.busted? || (dealer.total >= DEALER_HIT_UNTIL && !dealer.busted?)
      show_dealer_hand
    end
    show_player_hand unless player.busted?
  end

  def show_result
    if player.busted?
      puts "#{player.name} busted - Dealer wins!"
    elsif dealer.busted?
      puts "Dealer busted - #{player.name} wins!"
    elsif player.total > dealer.total
      puts "#{player.name} wins!"
    elsif dealer.total > player.total
      puts "Dealer wins!"
    else
      puts "It's a tie!"
    end
  end

  def reset_game
    self.deck = Deck.new
    player.hand = []
    dealer.hand = []
  end

  def play_again?
    answer = ''
    loop do
      puts "Would you like to play again? Enter 'y' for yes, 'n' for no."
      answer = gets.chomp.downcase
      break if answer.start_with?('y') || answer.start_with?('n')
      puts "Sorry, please enter 'y' or 'n'."
    end
    system 'clear'
    answer.start_with?('y')
  end
end

TwentyOneGame.new.play
# rubocop:enable Metrics/MethodLength
