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

    Example `in_str`:

    102
    300
    010

    """
    function Classic(in_str::String)
        ruleset = Vector{Type}([Row, Column, Box])
        cells = _instantiate_cells(in_str)
        cellbags = _instantiate_cellbags(cells, ruleset)
        p = new(ruleset, cells, cellbags)
        check_correctness(p)
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
        [Cell(9*(i-1)+j, parse(Int, v), N) for (i, r) ∈ enumerate(split(in_str, '\n')) for (j, v) ∈ enumerate(r)],
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
    #=
    "threat level" indicator that starts as low as possible
    but increments each time the solver gets stuck. higher levels allow
    for methods that have lower likelihood of giving any new information.
    throw the exception once the threat level is "maxed out"

    The idea is :
    1 -> no threat
    2 -> more strenuous checks
    3 -> last resort checks

    Threat level resets once a cell is filled.
    TODO solver does not have any information on filled_cells when considering
    if it is stuck. we should actually do something like a hash value...
    =#
    threat_level = 1
    max_threat_level = 3

    # loop until stuck or a mistake is found
    prev_p = string(P)

    cbs = get_cellbags(P)
    comparable_cbtypes = determine_comparable_cellbag_pairs(P)

    while true
        operate_on_cells(P)
        operate_between_cellbags(comparable_cbtypes, cbs)
        operate_within_cellbags(cbs, threat_level)

        current_p = string(P)
        if iscompleted(P)
            check_correctness(P)
            return current_p
        end

        if current_p == prev_p
            if threat_level == max_threat_level
                throw(StuckPuzzleException(P, "Classic puzzle solver is stuck!"))
            end
            threat_level += 1
        else
            threat_level = 1
        end
        prev_p = current_p
    end
end
