require './lib/solver'

puzzle_path = ARGV[0]
puzzle_text = File.readlines(puzzle_path)
solver = Solver.new(puzzle_text)
puts solver.solve
