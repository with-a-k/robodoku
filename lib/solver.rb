require 'set'

class Solver
  attr_reader :puzzle

  def initialize(puzzle_text)
    @puzzle = Board.new(puzzle_text)
  end

  def solve
    puzzle.solve
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
    end.flatten.reject { |cell| cell.row > 8 }
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

  def empty_cells
    cells.select { |cell| cell.value == " " }
  end

  def solve
    until solved?
      buffer = empty_cells
      empty_cells.sort_by { |cell| cell.possible.length }.each { |cell| cell.update! }
      if buffer == empty_cells
        empty_cells.each { |cell| cell.check_for_loners! }
        if buffer == empty_cells
          advanced_block_exclusion
          if buffer == empty_cells
            puts "Couldn't solve, here's what I could manage:"
            break
          end
        end
      end
    end
  end

  def advanced_block_exclusion
    (0...9).each do |block|
      scan_for = @blocks[block].reduce("123456789") { |unassigned, cell| unassigned.delete(cell.value) }
      scan_for.each_char do |digit|
        filter_cells_for_possibility(block, digit)
      end
    end
  end

  def filter_cells_for_possibility(block, digit)
    options = @blocks[block].find_all { |cell| cell.possible.include?(digit) }
    if same_column?(options)
      isolate_to_intersection(digit, @blocks[block], @cols[options.sample.column])
    elsif same_row?(options)
      isolate_to_intersection(digit, @blocks[block], @rows[options.sample.row])
    end
  end

  def same_column?(cells)
    random_column = cells.sample.column
    cells.all? { |cell| cell.column == random_column }
  end

  def same_row?(cells)
    random_row = cells.sample.row
    cells.all? { |cell| cell.row == random_row }
  end

  def isolate_to_intersection(digit, block, line) #a block from blocks and a row or column
    anti_intersection(block, line).each { |cell| cell.possible.delete!(digit) }
  end

  def anti_intersection(block, line)
    block.to_set ^ line.to_set
  end

  def intersection(block, line)
    block & line
  end
end

class Cell
  include Inspector
  inspector :row, :column, :block, :value, :possible
  attr_reader :row, :column, :board, :block, :possible, :value

  def initialize(row, column, value, board)
    @row = row
    @column = column
    @board = board
    @block = (3*(row/3))+(column/3)
    @value = value
    @possible = value * 10
    @possible = "123456789" if value == " "
    @possible = "-" if value == "\n"
  end

  def update!
    @possible = peers.reduce(possible) { |options, cell| options.delete(cell.value) }
    if possible.length == 1
      @value = possible
      @possible = value * 10
    end
  end

  def check_for_loners!
    possible.each_char do |digit|
      row_loner?(digit)
      column_loner?(digit)
      block_loner?(digit)
    end
  end

  def row_loner?(digit)
    if same_row.none? { |cell| cell.possible.include?(digit) }
      @value = digit
      @possible = value * 10
    end
  end

  def column_loner?(digit)
    if same_column.none? { |cell| cell.possible.include?(digit) }
      @value = digit
      @possible = value * 10
    end
  end

  def block_loner?(digit)
    if same_block.none? { |cell| cell.possible.include?(digit) }
      @value = digit
      @possible = value * 10
    end
  end

  def peers
    [*(board.rows[row]), *(board.cols[column]), *(board.blocks[block])].
    reject { |cell| cell == self}.uniq
  end

  def same_row
    peers.select { |cell| cell.row == row }
  end

  def same_column
    peers.select { |cell| cell.column == column }
  end

  def same_block
    peers.select { |cell| cell.block == block }
  end
end