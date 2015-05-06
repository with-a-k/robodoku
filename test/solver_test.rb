require './lib/solver'
require "minitest"
require "minitest/autorun"
require 'pry'

class SolverTest < Minitest::Test
  def test_instantiates_properly
    assert Solver.new(["123456789\n",
                       "456789123\n",
                       "789123456\n",
                       "234567891\n",
                       "567891234\n",
                       "891234567\n",
                       "345678912\n",
                       "678912345\n",
                       "912345678\n"])
  end

  HasPeers = Struct.new :fake_peers do
    def peers(cell)
      fake_peers
    end
  end

  def cell_with_peers(peer_string)
    peers = peer_string.chars.map { |c| Cell.new 1, 2, c, nil }
    board = HasPeers.new(peers)
    Cell.new 1, 2, ' ', board
  end

  # def cell_with_peer_possibles(peer_possible_array)
  #   peers = peer_possible_array.map { |string| Cell.new 1, 2, " ", nil }
  #   board = HasPeers.new(peers)
  #   peers.each_with_index { |peer, index| peer.@possible = peer_possible_array[index] }
  #   Cell.new 1, 2, ' ', board
  # end

  def test_cells_will_adopt_a_value_if_it_is_the_only_possibility
    assert_equal "1", cell_with_peers('23456789').update!.value
  end

  def test_cells_will_usually_not_adopt_a_value_if_uncertainty_exists
    assert_equal " ", cell_with_peers('2345678').update!.value
  end

  def test_cells_will_remove_possibilities_when_updating
    assert_equal "19", cell_with_peers('2345678').update!.possible
  end

  def test_cells_will_adopt_a_value_if_no_other_cell_in_its_row_can
    b = Board.new([" 234567  \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "       1 \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "        1\n"])
    b.empty_cells.each { |cell| cell.update! }
    b.basic_group_exclusion(b.rows[0])
    assert_equal "1", b.rows[0][0].value
  end

  def test_cells_will_adopt_a_value_if_no_other_cell_in_its_column_can
    b = Board.new(["         \n",
                   "2        \n",
                   "3        \n",
                   "4        \n",
                   "5        \n",
                   "6        \n",
                   "7        \n",
                   "    1    \n",
                   "        1\n"])
    b.empty_cells.each { |cell| cell.update! }
    b.basic_group_exclusion(b.cols[0])
    assert_equal "1", b.cols[0][0].value
  end

  def test_cells_will_adopt_a_value_if_no_other_cell_in_its_block_can
    b = Board.new(["  7      \n",
                   "2 4      \n",
                   "3 9      \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   " 1       \n"])
    b.empty_cells.each { |cell| cell.update! }
    b.basic_group_exclusion(b.blocks[0])
    assert_equal "1", b.blocks[0][0].value
  end

  def test_it_solves_trivial_puzzles
    b = Board.new([" 26594317\n",
                   "715638942\n",
                   "394721865\n",
                   "163459278\n",
                   "948267153\n",
                   "257813694\n",
                   "531942786\n",
                   "482176539\n",
                   "679385421\n"])
    b.solve
    assert_equal "826594317\n715638942\n394721865\n163459278\n"\
                 "948267153\n257813694\n531942786\n482176539\n"\
                 "679385421\n", b.to_s
  end

  def test_it_solves_easy_puzzles
    b = Board.new(["4  8725  \n",
                   "5  64 213\n",
                   " 29   8  \n",
                   "    6 73 \n",
                   "1 8 2 4  \n",
                   "97  15 2 \n",
                   "3  2  1  \n",
                   "  659   2\n",
                   "8 2 37946\n"])
    b.solve
    assert_equal "431872569\n587649213\n629351874\n245968731\n"\
                 "168723495\n973415628\n394286157\n716594382\n"\
                 "852137946\n", b.to_s
  end

  def test_it_solves_medium_puzzles
    b = Board.new(["     124 \n",
                   "5 43 26  \n",
                   "2   4  8 \n",
                   "     4816\n",
                   " 8     3 \n",
                   "3519     \n",
                   " 3  9   4\n",
                   "  81 53 9\n",
                   " 294     \n"])
    b.solve
    assert_equal "897651243\n514382697\n263749581\n972534816\n"\
                 "486217935\n351968472\n135896724\n748125369\n"\
                 "629473158\n", b.to_s
  end

  def test_advanced_exclusion_works
    b = Board.new(["         \n",
                   " 1267    \n",
                   " 3489    \n",
                   "       5 \n",
                   " 21      \n",
                   " 43      \n",
                   "         \n",
                   "         \n",
                   "         \n"])
    b.cells.each { |cell| cell.update! }
    b.filter_cells_for_possibility(3, "5")
    refute b.intersection(b.blocks[0], b.cols[0]).any? { |cell| cell.possible.include?("5") },
      "There's still a 5 in the possibility ranges of the intersection of block 0 and column 0."
    b.filter_cells_for_possibility(0, "5")
    refute b.intersection(b.blocks[1], b.rows[0]).any? { |cell| cell.possible.include?("5") },
      "There's still a 5 in the possibility ranges of the intersection of block 1 and row 0."
  end

  def test_board_inspect_is_helpful
    b = Board.new(["         \n",
                   " 1267    \n",
                   " 3489    \n",
                   "       5 \n",
                   " 21      \n",
                   " 43      \n",
                   "         \n",
                   "         \n",
                   "         \n"])
    desired = "#<Board:\n" + 
              "|         |\n" +
              "| 1267    |\n" +
              "| 3489    |\n" +
              "|       5 |\n" +
              "| 21      |\n" +
              "| 43      |\n" +
              "|         |\n" +
              "|         |\n" +
              "|         |\n" + ">"
    assert_equal desired, b.inspect
  end

  def test_cell_inspect_is_helpful
    b = Board.new(["         \n",
                   " 1267    \n",
                   " 3489    \n",
                   "       5 \n",
                   " 21      \n",
                   " 43      \n",
                   "         \n",
                   "         \n",
                   "         \n"])
    cell = b.rows[3][0]
    desired = "#<Cell: row: 3, column: 0, block: 3, value: \" \", possible: 123456789>"
    assert_equal desired, cell.inspect
  end
end
