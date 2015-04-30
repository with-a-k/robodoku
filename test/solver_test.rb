require './lib/sudoku'
require './lib/solver'
require "minitest"
require "minitest/autorun"

class SolverTest < Minitest::Test
  def test_instantiates_properly
    assert Solver.new(:fake_text)
    assert Board.new(:fake_text)
    assert Cell.new(:r, :c, :v, :b)
  end

  def test_it_solves
    skip
    assert false, "make it solve!"
  end
end
