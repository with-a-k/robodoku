require 'set'
require 'pry'

class Solver
  attr_reader :puzzle

  def initialize(puzzle_lines)
    @puzzle = Board.new(puzzle_lines)
  end

  def solve
    puzzle.solve
    puzzle.to_s
  end
end

class Board
  attr_reader :cells, :rows, :cols, :blocks

  def initialize(puzzle_lines)
    @cells = puzzle_lines.each_with_index.map do |row, row_index|
      row.chars.each_with_index.map do |spot, col_index|
        Cell.new(row_index, col_index, spot, self)
      end
    end.flatten.reject { |cell| cell.row > 8 }
    make_groups
  end

  def inspect
    inspected_rows = rows.values
      .map { |row| row.map(&:value).join }
      .map { |inspected| "|#{inspected.chomp}|\n" }
    "#<Board:\n#{inspected_rows.join}>"
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

  def empty_cells(group = cells)
    group.select { |cell| cell.value == " " }
  end

  def count_possibilities
    empty_cells.reduce(1) { |options, cell| options * cell.possible.length }
  end

  def solve
    tries = 0
    until solved?
      buffer = [empty_cells, count_possibilities]
      empty_cells.sort_by { |cell| cell.possible.length }.each { |cell| cell.update! }
      next if buffer != [empty_cells, count_possibilities]
      (rows.values + cols.values + blocks.values).each do |group|
        basic_group_exclusion(group)
        cells.each { |cell| cell.update! }
      end
      next if buffer != [empty_cells, count_possibilities]
      advanced_block_exclusion
      next if buffer != [empty_cells, count_possibilities]
      binding.pry
      find_naked_pairs (@rows)
      find_naked_pairs (@cols)
      find_naked_pairs (@blocks)
      if buffer == [empty_cells, count_possibilities] && tries == 9
        # guess_at_cells
        binding.pry
        failed_solve
      end
      tries += 1
    end
  end

  def basic_group_exclusion(group)
    group.each { |cell| cell.update! }
    (1..9).each do |value|
      if group.one? { |cell| cell.possible.include?(value.to_s) }
        choice = group.find { |cell| cell.possible.include?(value.to_s) }
        choice.assign!(value.to_s)
        choice.peers.each { |peer| peer.remove_possibility!(value.to_s) }
      end
    end
    group.each { |cell| cell.update! }
  end

  def advanced_block_exclusion
    (0...9).each do |block|
      scan_for = @blocks[block].reduce("123456789") { |unassigned, cell| unassigned.delete(cell.value) }
      scan_for.each_char do |digit|
        filter_cells_for_possibility(block, digit)
      end
    end
  end

  def find_naked_pairs(groups)
    groups.values.each do |group|
      unless two_candidate_cells(group).empty?
        act_on_naked_pairs(group)
      end
    end
  end

  def extract_naked_pairs(group)
    two_candidate_cells(group).group_by{ |cell| cell.possible }
                .values.select { |equals| equals.length == 2 }
  end

  def act_on_naked_pairs(group)
    extract_naked_pairs(group).each do |pair|
      remove = pair[0].possible
      empty_cells(group).each do |cell|
        unless pair.include?(cell)
          remove.each_char { |digit| cell.remove_possibility!(digit) }
        end
      end
    end
  end

  def two_candidate_cells(group)
    group.select { |cell| cell.possible.length == 2 }
  end

  def guess_at_cells
    successful_guess = false
    empty_cells.sort_by { |cell| cell.possible.length }.each do |cell|
      cell.possible.each_char do |value|
        if suppose(cell.row, cell.column, value)
          cell.assign!(value)
          return
        end
      end
    end
    failed_solve
  end

  def failed_solve
    puts "Couldn't solve. Ending state is:"
    puts to_s
    abort("Couldn't solve.")
  end

  def duplicate
    Board.new(self.to_s.each_line.map { |line| line.gsub(/\|/, "") })
  end

  def suppose(cell_row, cell_col, value)
    test_board = duplicate
    test_board.rows[cell_row][cell_col].assign!(value)
    test_board.empty_cells.sort_by { |cell| cell.possible.length }.each { |cell| cell.update! }
    return false if test_board.empty_cells.any? { |cell| cell.possible.empty? }
    true
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

  def peers(cell)
    (rows[cell.row] +
     cols[cell.column] +
     blocks[cell.block]
    ).reject { |potential_peer| potential_peer == cell}
     .uniq
  end
end

class Cell
  attr_reader :row, :column, :board, :block, :possible, :value

  def initialize(row, column, value, board)
    @row = row
    @column = column
    @board = board
    @block = (3*(row/3))+(column/3)
    @value = value
    @possible = value * 10
    @possible = "123456789" if value == " "
  end

  def inspect
    "#<Cell: row: #{row}, column: #{column}, block: #{block}, value: \"#{value}\", possible: #{possible}>"
  end

  def update!
    @possible = peers.reduce(possible) { |options, cell| options.delete(cell.value) }
    if possible.length == 1
      @value = possible
      @possible = value * 10
    end
    self
  end

  def peers
    board.peers self
  end

  def assign!(value)
    @value = value
    @possible = value * 10
  end

  def remove_possibility!(digit)
    @possible.delete(digit)
  end
end