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

  def test_cells_will_adopt_a_value_if_it_is_the_only_possibility
    b = Board.new([" 23456789\n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n"])
    b.rows[0][0].update!
    assert_equal "1", b.rows[0][0].value
  end

  def test_cells_will_usually_not_adopt_a_value_if_uncertainty_exists
    b = Board.new([" 2345678 \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n"])
    b.rows[0][0].update!
    b.rows[0][8].update!
    b.rows[8][8].update!
    assert_equal " ", b.rows[0][0].value
    assert_equal " ", b.rows[0][8].value
    assert_equal " ", b.rows[8][8].value
  end

  def test_cells_will_remove_possibilities_when_updating
    b = Board.new([" 2345678 \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n",
                   "         \n"])
    assert_equal "123456789", b.rows[0][0].possible
    b.rows[0][0].update!
    b.rows[8][7].update!
    assert_equal "19", b.rows[0][0].possible
    assert_equal "12345679", b.rows[8][7].possible
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
    b.rows[0].each { |cell| cell.update! }
    b.rows[0][0].check_for_loners!
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
    b.cols[0].each { |cell| cell.update! }
    b.cols[0][0].check_for_loners!
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
    b.blocks[0].each { |cell| cell.update! }
    b.blocks[0][0].check_for_loners!
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
end
