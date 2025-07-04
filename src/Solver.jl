#=

Here we have all possible defined solvers. Solver is the interface for them.
Each solver subtypes Solver interface and has a ruleset which contains
the modules of all CellBags that are being used by the solver.

Search InvalidInputException to find assumptions that are being made about the
puzzle that are not outlined explicitly in the ruleset.

=#

abstract type Solver end

# this forces you to implement these functions in all subtypes which extend Solver
_instantiate_cells(::Solver) = error("Must implement _instantiate_cells for Solver")
_instantiate_cellbags(::Solver) = error("Must implement _instantiate_cellbags for Solver")
get_cellbags(::Solver) = error("Must implement get_cellbags for Solver")
get_cells(::Solver) = error("Must implement get_cells for Solver")
solve(::Solver) = error("Must implement solve for Solver")

import Base.string

"""
    string(s::Solver)::String

Returns a string representing the puzzle in its current state
"""
function string(s::Solver)::String
    # we hack this by calling println to a text buffer and then returning that as a string
    cs = map(c -> c._value, get_cells(s))
    io = IOBuffer()
    show(io, "text/plain", cs)
    return "\n\n" * String(take!(io)) * '\n'
end

"""
    check_correctness(s::Solver)

Checks if everything is correct by validating all CellBags
"""
function check_correctness(s::Solver)
    for (k, v) in get_cellbags(s)
        if ! all(map(iscorrect, v))
            throw(InvalidPuzzleException(s, "An invalid $k was found"))
        end
    end
end

"""
    determine_comparable_cellbag_pairs(s::Solver)::Vector{Tuple{Type, Type}}

Returns a list of pairs of CellBagTypes which can be operated on using ↔
"""
function determine_comparable_cellbag_pairs(s::Solver)::Vector{Tuple{Type, Type}}
    cbs = get_cellbags(s)
    return filter(
        t -> compare_trait(t...) == HasCompare(),
        [(t1, t2) for (t1, _) ∈ cbs for (t2, _) ∈ cbs]
    )
end

function operate_between_cellbags(
    comparable_cbtypes::Vector{Tuple{Type, Type}},
    cbs::Dict{Type, Vector{CellBag}}
)
    for (t1, t2) ∈ comparable_cbtypes
        for cb1 ∈ cbs[t1], cb2 ∈ cbs[t2]
            ↔(cb1, cb2, HasCompare())
        end
    end
end

function operate_within_cellbags(cbs_dict::Dict{Type, Vector{CellBag}}, threat_level::Int)
    for (_, cbs) ∈ cbs_dict, cb ∈ cbs
        remove_possible_values!(cb, threat_level)
        set_if_only_one_option_left(cb)
    end
end

function iscompleted(s::Solver)::Bool
    # a puzzle is completed if all cells are filled
    return all(map(c -> ! isempty(c), get_cells(s)))
end

"""
    operate_on_cells(s::Solver)

Checks if any cells only have one option left and sets their value.
"""
function operate_on_cells(s::Solver)
    map(set_if_only_one_option_left, get_cells(s))
end

"""
    InvalidPuzzleException

Thrown if an `iscorrect()` check finds a mistake. 
"""
struct InvalidPuzzleException <: Exception
    s::Solver
    msg::String
end

Base.showerror(io::IO, e::InvalidPuzzleException) = print(
    io, "InvalidPuzzleException: ", e.msg, string(e.s)
)

"""
    StuckPuzzleException

Thrown if at any point a Solver is considered "stuck".
"""
struct StuckPuzzleException <: Exception
    s::Solver
    msg::String
end

Base.showerror(io::IO, e::StuckPuzzleException) = print(
    io, "StuckPuzzleException", e.msg, string(e.s)
)
