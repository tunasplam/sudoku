#=
Classic variant of sudoku.
=#

struct Classic <: Solver
    ruleset::Vector{Type}
    cells::Matrix{Cell}
    cellbags::Dict{Type, Vector{CellBag}}

    """
        Classic(in_str::String)
    
    Classic variant of sudoku

    # Arguments
    - `in_str::String`: input string representing puzzle to be solved.

    Example `in_str``:

    102
    300
    010

    """
    function Classic(in_str::String)
        ruleset = Vector{Type}([Row, Column, Box])
        cells = _instantiate_cells(in_str)
        cellbags = _instantiate_cellbags(cells, ruleset)
        p = new(ruleset, cells, cellbags)
        iscorrect(p)
        return p
    end

end

get_cells(c::Classic)::Matrix{Cell} = c.cells
get_cellbags(c::Classic)::Dict{Type, Vector{CellBag}} = c.cellbags

function _instantiate_cells(in_str::String)::Matrix{Cell}
    rows = split(in_str, '\n')
    N = length(rows)

    # dimensions of puzzle must be square
    if any(length(r) != N for r ∈ rows)
        throw(InvalidInputException("Input puzzle must have square dimensions."))
    end

    return reshape(
        [Cell(parse(Int, v), N) for r ∈ split(in_str, '\n') for v ∈ r],
        N, N
    )
end

function _instantiate_cellbags(
    cells::Matrix{Cell},
    ruleset::Vector{Type}
)::Dict{Type, Vector{CellBag}}
    return Dict(CellBagT => create_all(CellBagT, cells) for CellBagT ∈ ruleset)
end

"""
    solve(P::Classic)::String

Takes a Classic sudoku puzzle and returns a string representing its solution
"""
function solve(P::Classic)::String
    # loop until stuck or a mistake is found
    prev_P = string(P)

    # get a list of tuples that define comparable cellbagtypes

    cbs = get_cellbags(P)
    comparable_cbtypes = determine_comparable_cellbag_pairs(P)

    while true
        operate_on_cells(P)
        operate_between_cellbags(comparable_cbtypes, cbs)
        operate_within_cellbags(cbs)
        iscorrect(P)

        if iscompleted(P)
            return string(P)
        elseif string(P) == prev_P
            throw(StuckPuzzleException(P, "Classic puzzle solver is stuck!"))
        end
        prev_p = string(P)
    end
end
