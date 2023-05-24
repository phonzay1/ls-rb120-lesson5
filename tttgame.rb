require 'pry'

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # cols
                  [[1, 5, 9], [3, 5, 7]]

  def initialize
    @squares = {}
    reset
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def get_square_at(key)
    @squares[key]
  end

  def []=(key, marker)
    @squares[key].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).map(&:marker)
    markers.size == 3 && markers.uniq.size == 1
  end
end

class Square
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    marker
  end

  def marked?
    marker != INITIAL_MARKER
  end

  def unmarked?
    marker == INITIAL_MARKER
  end
end

Player = Struct.new('Player', :marker)

class TTTGame
  FIRST_TO_MOVE = 'X'
  SCORE_TO_WIN = 3
  COMPUTER_NAMES = %w(R2D2 C3PO BB8 K2SO B2EMO)

  def initialize
    @board = Board.new
    @current_marker = FIRST_TO_MOVE
    @human_score = 0
    @computer_score = 0
    @human_name = username
    @computer_name = COMPUTER_NAMES.sample
    @human = Player.new(choose_human_marker)
    @computer = Player.new(choose_computer_marker)
  end

  def play
    clear
    display_welcome_message
    main_game
    display_goodbye_message
  end

  private

  attr_reader :board, :human, :computer, :human_name, :computer_name
  attr_accessor :current_marker, :human_score, :computer_score

  def display_welcome_message
    puts "Welcome to the Tic Tac Toe game, #{human_name}! You'll be playing " \
    "against the droid #{computer_name}. First player with #{SCORE_TO_WIN} " \
    "wins is the grand champion!"
    puts ''
  end

  def username
    name = ''
    loop do
      puts "Welcome to the Tic Tac Toe game! What's your name?"
      name = gets.chomp
      break unless name.empty?
      puts "Sorry, please enter a name."
    end
    name
  end

  def choose_human_marker
    marker = ''
    loop do
      puts "Enter X to play as 'X', O to play as 'O', or C to let the " \
      "computer choose for you. 'X' goes first."
      marker = gets.chomp.upcase
      break if %w(X O C).include?(marker)
      puts "Sorry, please enter X, O, or C."
    end

    marker == 'C' ? %w(X O).sample : marker
  end

  def choose_computer_marker
    human.marker == 'X' ? 'O' : 'X'
  end

  def display_goodbye_message
    puts "Thanks for playing Tic Tac Toe, #{human_name} - goodbye!"
  end

  def joinor(arr, punctuation = ', ', conjunction = 'or')
    case arr.size
    when 0 then ''
    when 1 then arr[0].to_s
    when 2 then "#{arr[0]} #{conjunction} #{arr[1]}"
    else "#{arr[0..-2].join(punctuation)}#{punctuation}#{conjunction} #{arr[-1]}"
    end
  end

  def clear
    system 'clear'
  end

  def display_board
    puts "You're playing as #{human.marker}. #{computer_name} is playing as " \
    "#{computer.marker}."
    puts ''
    board.draw
    puts ''
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def player_moves
    loop do
      if human.marker == FIRST_TO_MOVE
        display_board
        current_player_moves
        clear if human_turn?
      else
        current_player_moves
        display_board
        clear_screen_and_display_board if !human_turn?
      end
      break if board.someone_won? || board.full?
    end
  end

  def current_player_moves
    if human_turn?
      human_moves
      self.current_marker = computer.marker
    else
      computer_moves
      self.current_marker = human.marker
    end
  end

  def main_game
    loop do
      loop do
        player_moves
        tally_score
        display_result
        reset_board
        break display_grand_champion if grand_champion?
      end

      break unless play_again?
      reset_board_and_clear
      reset_scores
      display_play_again_message
    end
  end

  def human_turn?
    current_marker == human.marker
  end

  def human_moves
    puts "Choose a square: #{joinor(board.unmarked_keys)}"
    square = nil

    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  def computer_moves
    if find_winning_square
      board[find_winning_square] = computer.marker
    elsif find_at_risk_square
      board[find_at_risk_square] = computer.marker
    elsif board.get_square_at(5).marker == Square::INITIAL_MARKER
      board[5] = computer.marker
    else
      board[board.unmarked_keys.sample] = computer.marker
    end
  end

  def markers_on_each_line(line_array)
    line_array.each_with_object({}) do |key, hsh|
      hsh[key] = board.get_square_at(key).marker
    end
  end

  def find_winning_square
    Board::WINNING_LINES.each do |line|
      squares = markers_on_each_line(line)
      if squares.values.count(computer.marker) == 2 &&
         squares.values.count(Square::INITIAL_MARKER) == 1
        return squares.select { |_, v| v == Square::INITIAL_MARKER }.keys.first
      end
    end
    nil
  end

  def find_at_risk_square
    Board::WINNING_LINES.each do |line|
      squares = markers_on_each_line(line)
      if squares.values.count(human.marker) == 2 &&
         squares.values.count(Square::INITIAL_MARKER) == 1
        return squares.select { |_, v| v == Square::INITIAL_MARKER }.keys.first
      end
    end
    nil
  end

  def tally_score
    case board.winning_marker
    when human.marker
      self.human_score += 1
    when computer.marker
      self.computer_score += 1
    end
  end

  def display_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts "#{human_name} won!"
    when computer.marker
      puts "#{computer_name} won!"
    else
      puts "It's a tie!"
    end

    puts "#{human_name} has #{human_score} wins. #{computer_name} has " \
    "#{computer_score} wins."
  end

  def grand_champion?
    (human_score >= SCORE_TO_WIN) || (computer_score >= SCORE_TO_WIN)
  end

  def display_grand_champion
    if human_score >= SCORE_TO_WIN
      puts "With #{human_score} wins, #{human_name} is the grand champion! " \
      "Congrats on beating the robots!"
    elsif computer_score >= SCORE_TO_WIN
      puts "With #{computer_score} wins, #{computer_name} is the grand " \
      "champion. Better luck next time, human!"
    end
  end

  def play_again?
    answer = nil

    loop do
      puts "Would you like to play again? (enter y for yes, n for no)"
      answer = gets.chomp.downcase
      break if %w(y n).include?(answer)
      puts "Sorry, answer must be y or n"
    end

    answer == 'y'
  end

  def reset_board
    board.reset
    self.current_marker = FIRST_TO_MOVE
  end

  def reset_board_and_clear
    board.reset
    self.current_marker = FIRST_TO_MOVE
    clear
  end

  def reset_scores
    self.human_score = 0
    self.computer_score = 0
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ''
  end
end

game = TTTGame.new
game.play
