module sudoku

include("CellBag.jl")
export CellBag, filled_cells, empty_cells, iscompleted, InvalidInputException, remove_possible_values!, ↔,
HasCompare, MissingCompare, compare_trait, set_if_only_one_option_left, ValuesUnique, ValuesCanRepeat,
iscorrect

include("Cell.jl")
export Cell, set_value, remove_possible_values, get_distinct_possible_values, get_cells_with_possible_value

include("Solver.jl")
export Solver, InvalidPuzzleException, string, check_correctness, get_cellbags, get_cells, StuckPuzzleException,
determine_comparable_cellbag_pairs, operate_between_cellbags, operate_within_cellbags,
solve

include("solvers/Classic.jl")
export Classic, get_cells, get_cellbags, solve

include("LinearCellBag.jl")
export LinearCellBag, get_cells, create_all

include("CellBags/Row.jl")
export Row, get_cells, create_all

include("CellBags/Column.jl")
export Column, get_cells, create_all

include("CellBags/Box.jl")
export Box, get_cells, create_all, ↔

include("Utils.jl")
export \

end
