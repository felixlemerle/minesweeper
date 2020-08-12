require 'pry'


MIN_ROWS = 4
MIN_COLUMNS = 4
	
MIN_BOMBS = 1
	
MAX_ROWS = 16
MAX_COLUMNS = 30
	
DEFAULT_ROWS = 9
DEFAULT_COLUMNS = 16

HIDDEN = "."
EMPTY = " "
BOMB = "*"
	
NO_MARK = ""
FLAG = "!"
QUESTION = "?"
	
WON = "W"
LOST = "L"
CONTINUE = "C"

TYPE_OF_MOVE = {
	"1" => { :text => "Expose",   :symbol => :expose   },
	"2" => { :text => "Flag",     :symbol => :flag     },
	"3" => { :text => "Question", :symbol => :question },
	"4" => { :text => "Unmark",   :symbol => :unmark   },
}

BORDER = [
	{
		"top"    => { "left" => "┌", "middle" => "┬", "right" => "┐" },
		"middle" => { "left" => "├", "middle" => "┼", "right" => "┤" },
		"bottom" => { "left" => "└", "middle" => "┴", "right" => "┘" },
		"side"   => { "vertical" => "│", "horizontal" => "───"       }
	},
	{
		"top"    => { "left" => "╔", "middle" => "╦", "right" => "╗" },
		"middle" => { "left" => "╠", "middle" => "╬", "right" => "╣" },
		"bottom" => { "left" => "╚", "middle" => "╩", "right" => "╝" },
		"side"   => { "vertical" => "║", "horizontal" => "═══"       }
	},
	{
		"top"    => { "left" => "╓", "middle" => "╥", "right" => "╖" },
		"middle" => { "left" => "╟", "middle" => "╫", "right" => "╢" },
		"bottom" => { "left" => "╙", "middle" => "╨", "right" => "╜" },
		"side"   => { "vertical" => "║", "horizontal" => "───"       }
	},
	{
		"top"    => { "left" => "╒", "middle" => "╤", "right" => "╕" },
		"middle" => { "left" => "╞", "middle" => "╪", "right" => "╡" },
		"bottom" => { "left" => "╘", "middle" => "╧", "right" => "╛" },
		"side"   => { "vertical" => "│", "horizontal" => "═══"       }
	}
]

module Value
	def self.adjust(value, min_value, max_value)
		if value < min_value
			min_value
		elsif value > max_value
			max_value
		else
			value
		end
	end
end

module Screen
	def self.clear
		if RUBY_PLATFORM =~ /win32|win64|\.NET|windows|cygwin|mingw32/i
			system('cls')
		else
			system('clear')
		end
	end
end


class Cell
	attr_accessor :symbol, :exposed, :marking
	 
	def initialize
		@symbol = EMPTY
		@exposed = false
		@marking = NO_MARK
	end
	
	def exposed?
		@exposed
	end
	
	def hidden?
		!exposed?
	end
	
	def expose
		unmark
		@exposed = true
	end
	
	def hide
		@exposed = false
	end
	
	def empty?
		@symbol == EMPTY
	end
	
	def bomb?
		@symbol == BOMB
	end
	
	def place_bomb
		@symbol = BOMB
	end
	
	def number?
		!empty? && !bomb?
	end
	
	def increment
		@symbol = (@symbol.to_i + 1).to_s unless bomb?
	end
	
	def marked?
		@marking != NO_MARK
	end
	
	def mark(marking)
		@marking = marking if hidden?
	end
	
	def flag
		mark(FLAG)
	end
	
	def question
		mark(QUESTION)
	end
	
	def marking?(marking)
		@marking == marking
	end
	
	def flagged?
		marking?(FLAG)
	end
	
	def question?
		marking?(QUESTION)
	end
	
	def unmark
		mark(NO_MARK)
	end
	
	def display
		if exposed?
			@symbol
		else
			if marked?
				@marking
			else
				HIDDEN
			end
		end
	end
end


class Board
	attr_accessor :board, :num_bombs, :num_flags, :num_exposed, :skin
	
	def initialize(rows = DEFAULT_ROWS, columns = DEFAULT_COLUMNS, num_bombs = 0, skin = 0)
		@board = Array.new(Value.adjust(rows, MIN_ROWS, MAX_ROWS))
		
		for row in 0...self.rows
			@board[row] = Array.new(Value.adjust(columns, MIN_COLUMNS, MAX_COLUMNS))
			
			for column in 0...self.columns
				@board[row][column] = Cell.new
			end
		end
		
		max_bombs = [self.rows * self.columns - 9, MIN_BOMBS].max
		@num_bombs = Value.adjust(num_bombs, MIN_BOMBS, max_bombs)
		
		@num_flags = 0
		@num_exposed = 0
		@skin = skin
	end
	
	def rows
		@board.length
	end
	
	def columns
		@board[0].length
	end
	
	def cell(row, column)
		@board[row][column]
	end
	
	def expose_all
		apply_to_all_cells {|cell| cell.expose}
	end
	
	def expose_all_bombs
		apply_to_all_cells {|cell| cell.expose if cell.bomb?}
	end
	
	def in_bounds?(row, column)
		row >= 0 && column >= 0 && row < self.rows && column < self.columns
	end
	
	def out_of_bounds?(row, column)
		!in_bounds?(row, column)
	end
	
	def num_cells
		rows * columns
	end
	
	def won?		
		@num_exposed == num_cells - @num_bombs
	end
	
	def display
		Screen.clear
		
		puts columns_numbers_line
	
		puts top_border
		
		for row in 0...self.rows
		
			print (" " * (MAX_ROWS.to_s.length - (row + 1).to_s.length)) + (row + 1).to_s + " "
		
			for cell in @board[row]
				print BORDER[@skin]["side"]["vertical"] + " " + cell.display + " "
			end
			
			print BORDER[@skin]["side"]["vertical"] + "\n"
			
			puts middle_border if row < (self.rows - 1)
		end
		
		puts bottom_border
		
		puts bomb_counter
		
		puts "\n"
	end
	
	private
	
	def apply_to_all_cells
		for row in @board
			for cell in row
				yield cell
			end
		end
	end
	
	def indentation(correction = 1)
		" " * (MAX_ROWS.to_s.length + correction)
	end
	
	def bomb_counter
		indentation + "BOMBS: " + (@num_bombs - @num_flags).to_s
	end
	
	def columns_numbers_line
		line = indentation
		
		for column in 0...self.columns
			line += "  " + (column + 1).to_s
			line += " " if column < 9
		end
		
		line
	end
	
	def top_border
		border("top")
	end
	
	def middle_border
		border("middle")
	end
	
	def bottom_border
		border("bottom")
	end
	
	def border(position)
		left   = BORDER[@skin][position]["left"]
		middle = BORDER[@skin]["side"]["horizontal"] + BORDER[@skin][position]["middle"]
		right  = BORDER[@skin]["side"]["horizontal"] + BORDER[@skin][position]["right"]
		
		indentation + left + (middle * (self.columns - 1)) + right
	end
end


class Move
	attr_accessor :board, :status, :first_expose
	
	def initialize(board)
		@board = board
		@status = CONTINUE
		@first_expose = true
	end
	
	def go(function, row, column)
		return if @board.out_of_bounds?(row, column)
		
		method(function).call(row, column, @board.cell(row, column))
	end
	
	def expose(row, column, cell = @board.cell(row, column))		
		initialize_bombs(row, column) if @first_expose
		
		if cell.hidden?
			if cell.bomb?
				@board.expose_all_bombs
				@status = LOST
			else
				@board.num_flags -= 1 if cell.flagged?
				
				cell.expose
				@board.num_exposed += 1
				apply_function_to_neighbors(:expose, row, column) if cell.symbol == EMPTY
				
				if @board.won?
					@status = WON
					@board.expose_all
				end
			end
		end
	end
	
	def flag(row, column, cell)
		if cell.hidden? && !cell.flagged?
			cell.flag
			@board.num_flags += 1
		end
	end
	
	def question(row, column, cell)
		cell.question
	end
	
	def unmark(row, column, cell)
		if cell.marked?
			@board.num_flags -= 1 if cell.flagged?
			
			cell.unmark
		end
	end
	
	private
	
	def apply_function_to_neighbors(function, row, column)
		for i in -1..1
			for j in -1..1
				if !(i == 0 && j == 0) && @board.in_bounds?(row + i, column + j)
					method(function).call(row + i, column + j)
				end
			end
		end
	end
	
	def initialize_bombs(row, column)
		random = Random.new
		countdown = @board.num_bombs
		
		while countdown > 0
			new_random = random.rand(@board.rows * @board.columns)
			new_indices = convert_to_indices(new_random)
			new_row = new_indices[0]
			new_column = new_indices[1]
			
			cell = @board.cell(new_row, new_column)
			
			if !neighbors?(new_indices, [row, column]) && !cell.bomb?
				cell.place_bomb
				countdown -= 1
				apply_function_to_neighbors(:increment_cell, new_row, new_column)
			end
		end
		
		@first_expose = false
	end
	
	def neighbors?(indices_1, indices_2)
		contiguous?(indices_1[0], indices_2[0]) && contiguous?(indices_1[1], indices_2[1])
	end
	
	def contiguous?(a, b)
		(a - b).abs <= 1
	end
	
	def convert_to_indices(number)
		row = number % @board.rows
		column = number / @board.rows
		[row, column]
	end
	
	def increment_cell(row, column)
		@board.cell(row, column).increment if @board.in_bounds?(row, column)		
	end
end


class Game
	attr_accessor :board, :skin
	
	def initialize(skin = 1)
		parameters = get_parameters
		
		@board = Board.new(parameters[:rows], parameters[:columns], parameters[:bombs], skin)
		
		move = Move.new(@board)
		
		while move.status == CONTINUE
			move_steps(move)
		end
		
		@board.display
		
		ending(move.status)
	end
	
	private
	
	def move_steps(move)
		@board.display
		
		move_data = get_move_data
		
		move.go(TYPE_OF_MOVE[move_data[:type_of_move]][:symbol], move_data[:row], move_data[:column])
	end
	
	def ending(status)
		puts (status == WON ? "! VICTORY !" : "* GAME OVER *")
		
		print "\n(Press ENTER to go back to the menu)" 
		gets 
	end
	
	def defeat
		puts 
	end
	
	def get_parameters
		puts "\nChoose game parameters:"
		
		rows = ""
		columns = ""
		num_bombs = ""
		
		until integer_strings?([rows, columns, num_bombs])
			rows = get("Rows")
			columns = get("Columns")
			num_bombs = get("Bombs")
		end
		
		{:rows => rows.to_i, :columns => columns.to_i, :bombs => num_bombs.to_i}
	end
	
	def get_move_data
		puts "\nYour move!"
	
		row = ""
		column = ""
		type_of_move = ""
		
		until integer_strings?([row, column]) &&
			  @board.in_bounds?(row.to_i - 1, column.to_i - 1) &&
			  valid_type_of_move?(type_of_move)
		
			row = get("Row")
			column = get("Column")
			type_of_move = get(types_of_moves + "Move")
		end
		
		{:row => row.to_i - 1, :column => column.to_i - 1, :type_of_move => type_of_move}
	end
	
	def integer_string?(string)
		string != "" && string.to_i.to_s == string
	end
	
	def integer_strings?(array)
		for string in array
			return false if !integer_string?(string)
		end
		
		true
	end
	
	def valid_type_of_move?(type_of_move)
		integer_string?(type_of_move) && TYPE_OF_MOVE[type_of_move]
	end
	
	def get(prompt)
		print prompt + ": "
		gets.chomp
	end
	
	def types_of_moves
		string = "\n"
		separation = "\t"
		
		TYPE_OF_MOVE.each do |number, data|			
			separation = "\n" if number.to_i == TYPE_OF_MOVE.length
		
			string += "[" + number + "] " + data[:text] + separation
		end
		
		string
	end
end


class Menu
	attr_accessor :skin

	def initialize(skin = 1)
		@skin = skin
		user_input = ""
		
		while user_input != "3"
			display_title(@skin)
			display_menu
			user_input = get_user_input
			
			if user_input == "1"
				Game.new(@skin)
			elsif user_input == "2"
				change_skin
			end
		end
			
	end
	
	private
	
	def display_title(skin)
		Screen.clear
		
		puts title_border("top", skin)
		puts title_line(skin)
		puts title_border("bottom", skin)
	end
	
	def title_border(position, skin)
		left = BORDER[skin][position]["left"]
		side = BORDER[skin]["side"]["horizontal"]
		middle = BORDER[skin][position]["middle"]
		right = BORDER[skin][position]["right"]
		
		left + side + middle + (side[0] * 13) + middle + side + right
	end
	
	def title_line(skin)
		side = BORDER[skin]["side"]["vertical"]
				
		side + " " + BOMB + " " + side + " MINESWEEPER " + side + " " + BOMB + " " + side
	end
	
	def display_menu
		puts "\n[1] New game"
		puts "[2] Change skin"
		puts "[3] Exit"
	end
	
	def get_user_input
		print "> "
		gets.chomp
	end
	
	def change_skin
		max = BORDER.length - 1
		
		puts "\nChoose skin:"
		print_skin_options
		
		@skin = Value.adjust(get_user_input.to_i - 1, 0, max)
	end
	
	def print_skin_options
		for i in 0...BORDER.length
			print skin_border("top", i) + skin_options_padding(i)
		end
		
		print "\n"
		
		for i in 0...BORDER.length
			side = BORDER[i]["side"]["vertical"]
			
			print side + " " + (i + 1).to_s + " " + side + skin_options_padding(i)
		end
		
		print "\n"
		
		for i in 0...BORDER.length
			print skin_border("bottom", i) + skin_options_padding(i)
		end
		
		print "\n"
	end
	
	def skin_border(position, skin)
		left = BORDER[skin][position]["left"]
		side = BORDER[skin]["side"]["horizontal"]
		right = BORDER[skin][position]["right"]
		
		left + side + right
	end
	
	def skin_options_padding(i)
		if i == (BORDER.length - 1)
			""
		else
			" "
		end
	end
end

Menu.new