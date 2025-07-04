# any sort of collection of Cells, i.e. rows, columns, boxes, diagonals, etc.
# this is an interface

#=

All CellBags are collections of Cells that hold views of the Matrix representing
the puzzle.

everything that extends this needs to have these functions
    - iscorrect()
    - create_all()
    - get_cells()
    - ↔()

Needs to have properites:
    - id Int
    - cells Vector{Cell}

TODO Some other CellBags that need to be implemented
    - mephistofel mumbo jumbo
=#

using Combinatorics

abstract type CellBag end

create_all(::CellBag) = error("Must implement create_all for CellBag")
get_cells(::CellBag) = error("Must implement get_cells for CellBag")
# TODO it is possible that several of these functions below are identical
# for all CellBags.
Base.iterate(::CellBag) = error("Must implement Base.iterate for CellBag!")
Base.length(::CellBag) = error("Must implement Base.length for CellBag!")
Base.size(::CellBag) = error("Must implement Base.size for CellBag!")
Base.isdone(::CellBag) = error("Must implement Base.isdone for CellBag!")
# required for findfirst
Base.pairs(::CellBag) = error("Must implement Base.pairs for CellBag")
# all CellBags have element type of Cell
Base.eltype(::CellBag) = Cell
Base.getindex(::CellBag, ::Int) = error("Must implement Base.getindex for CellBag")

#=
We need to be able to determine if ↔ is defined for two given CellBag subtypes,
but we also need to distinguish between these and the fallback error types above.
Thus, we use traits
=#

struct HasCompare end
struct MissingCompare end

↔(::CellBag, ::CellBag, ::MissingCompare) = error("Must implement some sort of comparison operation (↔) for CellBag")

# trait function: returns true is a pair of subtypes claim to support ↔
# a trait for this CellBag subtype is that ↔ is defined for these combinations
# override this in subtypes which do support ↔ (see def in Box for details)
#compare_trait(::Type{A}, ::Type{B}) where {A, B} = MissingCompare()

# if an invocation of ↔ is not valid, it returns false.
# when you are defining a possible invocation ↔, use ::HasCompare
↔(x, y, ::MissingCompare) = false

function filled_cells(C::CellBag)::Vector{Cell}
    # returns a collection of cells that are filled-in either as clues or by the solver.
    return filter(c -> c._value > 0, get_cells(C))
end

function empty_cells(C::CellBag)::Vector{Cell}
    return filter(c -> c._value == 0, get_cells(C))
end

function iscompleted(C::CellBag)::Bool
    return all(map(c -> ! isempty(c), get_cells(C)))
end

"""
    set_if_only_one_option_left(cb::CellBag)

If a value can only be in one place in the cellbag, then place it.
"""
function set_if_only_one_option_left(cb::CellBag)
    value_counts = possible_value_counts(cb)

    # place any with value_count of 1
    values_to_set = [k for (k, v) ∈ value_counts if v == 1]
    while ! isempty(values_to_set)
        x = pop!(values_to_set)
        # find the cell that the value would go into and set it.
        if (i = findfirst(c -> x ∈ c._possible_values, cb)) === nothing
            continue
        end
        set_value(get_cells(cb)[i], x)
        value_counts = possible_value_counts(cb)
    
        # setting a value may allow for a new value to be set.
        for (k, v) ∈ value_counts
            if v == 1 && v ∉ values_to_set
                push!(values_to_set, k)
            end
        end
    end
end

"""
    possible_value_counts(cb::CellBag)::Dict{Int, Int}

"value_counts" of possible_values in Cells within the given CellBag
"""
function possible_value_counts(cb::CellBag)::Dict{Int, Int}
    value_counts = Dict(
        i => 0 for i in 1:get_cells(cb)[1]._max_possible_value
    )
    for c ∈ cb, pv ∈ get_possible_values(c)
        value_counts[pv] += 1
    end
    return value_counts
end

struct ValuesUnique end
struct ValuesCanRepeat end

remove_possible_values!(::CellBag, ::Int, ::ValuesCanRepeat) = error("Must implement remove_possible_values! for CellBag")

"""
    remove_possible_values!(c::T<:CellBag, threat_level::Int) where {T<:CellBag}

Using filled cells within the cellbag, removes filled values from possible values of
empty cells within the cellbag. Assumes that all values within must be unique.
higher `threat_level` can allow for usage of methods that are less likely to yield
new information. 
"""
function remove_possible_values!(cb::T, threat_level::Int) where {T<:CellBag}
    # if the values must be unique, routes to the abstract type's method
    # o.w. use a type-specific implementation
    return remove_possible_values!(cb, threat_level, unique_values_trait(typeof(cb)))
end

function remove_possible_values!(cb::T, threat_level::Int, v::ValuesUnique) where {T<:CellBag}
    if iscompleted(cb)
        return
    end
    update_empty_cells_using_filled_cells(cb, v)
    update_empty_cells_using_groupings(cb, threat_level, v)
end

function update_empty_cells_using_filled_cells(cb::T, ::ValuesUnique) where {T<:CellBag}
    fcs = filled_cells(cb)
    ecs = empty_cells(cb)

    while ! isempty(fcs)
        fc = pop!(fcs)
        map(ec -> remove_possible_value(ec, fc._value), ecs)
    end
end

"""
    update_empty_cells_using_groupings(c::T, threat_level::Int, ::ValuesUnique) where {T<:CellBag}

If a pair of numbers can only be in two cells, then you can clear all other possible_values
in those cells. extensions to 3 + are possible but should only be checked with higher threat_level.

NOTE assumes that dimensions of puzzles are divisible by 3
"""
function update_empty_cells_using_groupings(cb::T, threat_level::Int, ::ValuesUnique) where {T<:CellBag}
    cs = empty_cells(cb)

    if length(cs) < 2
        return
    end

    # filter combination by size based on threat level
    combs_to_check = filter(
        t -> 1 < length(t) < 3 * threat_level,
        collect(combinations(get_distinct_possible_values(cs)))
    )

    for comb ∈ combs_to_check
        #=
        A combination of length k is a hit if all possible cells
        for x1 ... x_k are equal.
        =#
        # this object is list of sets of cells that each element in comb can reside in
        sets_target_cells = map(x -> Set(get_cells_with_possible_value(cs, x)), comb)
        for s ∈ sets_target_cells
            # if this comb of values can only reside in the same sets of cells, we have a hit
            if all(c == first(s) for c ∈ s)
                # remove all values in the target cells that are not in comb
                for c ∈ s, pv ∈ get_possible_values(c)
                    if pv ∉ comb
                        remove_possible_value(c, pv)
                    end
                end
            end
        end
    end
end

iscorrect(::CellBag, ::ValuesCanRepeat) = error("Must implement iscorrect for CellBag")

function iscorrect(c::T)::Bool where {T<:CellBag}
    return iscorrect(c, unique_values_trait(typeof(c)))
end

function iscorrect(b::T, ::ValuesUnique)::Bool where {T<:CellBag}
    filled_cell_values = map(c -> c._value, filled_cells(b))
    if length(filled_cell_values) != length(unique(filled_cell_values))
        return false
    end
    return true
end

"""
    InvalidInputException

For when a puzzle attempts to instantiate and invalid cellbag

NOTE this should not be used for checking for "correctness"
as iscorrect handles that and is called upon instantiation. This is for
assumptions such as "dimensions of puzzle must be divisible by 3".
"""
struct InvalidInputException <: Exception
    msg::String
end

Base.showerror(io::IO, e::InvalidInputException) = print(
    io, "InvalidInputException: ", e.msg
)
