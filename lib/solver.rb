class Solver
  attr_reader :puzzle

  def initialize(puzzle_text)
    @puzzle = Board.new(puzzle_text)
  end

  def solve
    until puzzle.solved?
      buffer = puzzle.cells
      puzzle.cells.sort_by { |cell| cell.possible.length }.each { |cell| cell.update }
      if buffer == puzzle.cells
        require 'pry'
        binding.pry
        puzzle.cells.each { |cell| cell.check_for_loners }
      end
    end
    puzzle.to_s
  end
end

module Inspector
  
  def inspect
    string = "#<#{self.class.name}:#{self.object_id} "
    fields = self.class.inspector_fields.map{|field| "#{field}: #{self.send(field)}"}
    string << fields.join(", ") << ">"
    string.gsub("\n", "\\n")
  end
  
  def self.inspected
    @inspected ||= []
  end
  
  def self.included source
    # $stdout.puts "Overriding inspect on #{source}"
    inspected << source
    source.class_eval do
      def self.inspector *fields
        @inspector_fields = *fields
      end
      
      def self.inspector_fields
        @inspector_fields ||= []
      end
    end
  end
end

class Board
  include Inspector
  inspector :cells
  attr_reader :cells, :rows, :cols, :blocks

  def initialize(puzzle_text)
    @cells = puzzle_text.each_with_index.map do |row, row_index|
      row.chars.each_with_index.map do |spot, col_index|
        Cell.new(row_index, col_index, spot, self)
      end
    end.flatten
    make_groups
  end

  def make_groups 
    @rows   = cells.group_by { |cell| cell.row }
    @cols   = cells.group_by { |cell| cell.column }
    @blocks = cells.group_by { |cell| cell.block }
  end

  def solved?
    cells.all? { |cell| cell.value != " " }
  end

  def to_s
    cells.reduce("") { |output, cell| output << cell.value }
  end
end

class Cell
  include Inspector
  inspector :row, :column, :block, :value, :possible
  attr_reader :row, :column, :board, :block
  attr_accessor :value, :possible

  def initialize(row, column, value, board)
    @row = row
    @column = column
    @board = board
    @block = (3*(row/3))+(column/3)
    @value = value
    @possible = value
    @possible = "123456789" if possible == " "
    @possible = "----------" if possible == "\n"
  end

  def update
    return if value != " "
    possible = peers.reduce(@possible) { |possible, cell| possible.delete(cell.value) }
    if possible.length == 1
      @value = possible
      @possible = value * 10
    end
  end

  def check_for_loners
    possible.each_char do |digit|
      row_loner?(digit)
      column_loner?(digit)
      block_loner?(digit)
    end
  end

  private
  def row_loner?(digit)
    if board.rows[row].reject { |cell| cell == self }.none? { |cell| cell.possible.include?(digit) }
      @value = digit
      @possible = value * 10
    end
  end

  def column_loner?(digit)
    if board.cols[column].reject { |cell| cell == self }.none? { |cell| cell.possible.include?(digit) }
      @value = digit
      @possible = value * 10
    end
  end

  def block_loner?(digit)
    if board.blocks[block].reject { |cell| cell == self }.none? { |cell| cell.possible.include?(digit) }
      @value = digit
      @possible = value * 10
    end
  end

  def peers
    [*(board.rows[row]), *(board.cols[column]), *(board.blocks[block])].
    reject { |cell| cell == self}.uniq
  end
end