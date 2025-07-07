#=
boxes within puzzle are indexed left-to-right and then down.
cells within puzzle are indexed the same way.

the way that we constructs these assumes that the width and height of puzzles
are divisible by 3

=#

mutable struct Box{Cell} <: CellBag
    id::Int
    cells::Vector{Cell}

    # TODO we are using actual Vector{Cell}() instead of subarrays.
    # things are working fine though.
    function Box(id::Int, cells::Vector{Cell})
        b = new{Cell}(id, cells)
        remove_possible_values!(b, 1)
        return b
    end
end

get_cells(b::Box) = b.cells

# a trait for box is that compare is defined for these combinations of types...
compare_trait(::Type{Box}, ::Type{T}) where {T<:LinearCellBag} = HasCompare()
compare_trait(::Type{T}, ::Type{Box}) where {T<:LinearCellBag} = HasCompare()
# ... but not for this one.
compare_trait(::Type{Box}, ::Type{Box}) = MissingCompare()
unique_values_trait(::Type{Box{Cell}}) = ValuesUnique()

import Base: compare

"""
    compare(b::Box{Cell}, r::LinearCellBag, threat_level::Int, ::HasCompare)

Update the intersecting cells using the information from the non-intersecting
LinearCellBag cells
"""
function compare(b::Box{Cell}, l::LinearCellBag, threat_level::Int, ::HasCompare)
    update_empty_cells_using_filled_cells(b, l)
    update_empty_cells_using_groupings(b, l, threat_level)
    update_empty_cells_using_groupings(l, b, threat_level)
    update_empty_cells_using_single_values(b, l)
    update_empty_cells_using_single_values(l, b)
end

compare(r::LinearCellBag, b::Box{Cell}, threat_level::Int, ::HasCompare) = 
    compare(b, r, threat_level, HasCompare())

"""
If a grouping exists entirely in the intersection of two cellbags,
then all cells in the complement can have the values from the grouping
removed from their possible values.

NOTE this is not symmetric. comparing a box to a row can give different information
than comparing the same row to the same box.
"""
# these "gateways" below ensure that the work function is never given two objects of the same type.
update_empty_cells_using_groupings(b::Box{Cell}, l::LinearCellBag, threat_level::Int) =
    _update_empty_cells_using_groupings(b, l, threat_level)
update_empty_cells_using_groupings(l::LinearCellBag, b::Box{Cell}, threat_level::Int) =
    _update_empty_cells_using_groupings(l, b, threat_level)

function _update_empty_cells_using_groupings(
    cb1::Union{Box{Cell}, LinearCellBag},
    cb2::Union{Box{Cell}, LinearCellBag},
    threat_level::Int
)
    cb_int = cb1 ∩ cb2
    
    isempty(cb_int) && return

    for (comb, g) ∈ possible_value_groupings(cb1, threat_level, ValuesUnique())
        if g ⊆ cb_int
            for ec ∈ filter(c -> isempty(c), cb2 \ cb1), v ∈ get_possible_values(ec)
                if v ∈ comb
                    remove_possible_value(ec, v)
                end
            end
        end
    end
end

"""
If a value can only reside within the intersection of two cell bags, then it can be removed
from possible_values of all other cells in the two cell bags.

NOTE this is not symmetric. comparing a box to a row can give different information
than comparing the same row to the same box.
"""
update_empty_cells_using_single_values(b::Box{Cell}, l::LinearCellBag) = 
    _update_empty_cells_using_single_values(b, l)
update_empty_cells_using_single_values(l::LinearCellBag, b::Box{Cell}) = 
    _update_empty_cells_using_single_values(l, b)

function _update_empty_cells_using_single_values(
    cb1::Union{Box{Cell}, LinearCellBag},
    cb2::Union{Box{Cell}, LinearCellBag}
)
    pvs_cb_int = map(get_possible_values, cb1 ∩ cb2)

    isempty(pvs_cb_int) && return

    # check if a value can only reside within the intersection of the two
    # cellbags
    for v in 1:get_cells(cb1)[1]._max_possible_value
        if all(v ∈ cpvs for cpvs ∈ pvs_cb_int) &&
           v ∉ get_distinct_possible_values(cb1 \ cb2)
            map(c -> remove_possible_value(c, v), cb2 \ cb1)
        end
    end
end

function update_empty_cells_using_filled_cells(b::Box{Cell}, l::LinearCellBag)
    # for all of the filled cells in the complement
    for fc ∈ filter(c -> ! isempty(c), l \ b)
        # for all of the empty cells in the intersection
        for ec ∈ filter(c -> isempty(c), l ∩ b)
            remove_possible_value(ec, fc._value)
        end
    end
end

function create_all(::Type{Box}, cells::Matrix{Cell})::Vector{Box}
    # dimensions of puzzle must be division by 3. there will always be 9
    if ! all(map(x -> x % 3 == 0, size(cells)))
        throw(InvalidInputException("Attempted to instantiate an invalid box. Dimensions must be divisible by 3."))
    end

    boxes = [Box(i, Vector{Cell}()) for i in 1:9]
    N = size(cells)[1]
    for (i, r) ∈ enumerate(eachrow(cells)), (j, c) ∈ enumerate(r)
        target_box = boxes[determine_box_id(N,i,j)]
        push!(get_cells(target_box), c)
        push!(c.cellbags, WeakRef(target_box))
    end
    return boxes
end

"""
    determine_box_id(N::Int, i::Int, j::Int)::Int

Given positional index of a cell in an NxN grid, returns id of box it belongs to
"""
function determine_box_id(N::Int, i::Int, j::Int)::Int
    d = N ÷ 3
    r = 0

    # sort into the correct row and then adjust by column
    if j ≤ d
        r = 1
    elseif d < j ≤ 2d
        r = 4
    else
        r = 7
    end

    if i ≤ d
        return r
    elseif d < i ≤ 2d
        return r + 1
    else
        return r + 2
    end
end


# for dimensions of the box
Base.size(b::Box) = size(b.cells)
# for how far the iterator needs to go when iterating cells
Base.length(b::Box) = length(b.cells)
Base.iterate(b::Box, i=1) = i > length(b) ? nothing : (get_cells(b)[i], i+1)
Base.isdone(b::Box, i) = i == length(b)
Base.pairs(b::Box) = enumerate(b.cells)
Base.getindex(b::Box, i::Int) = b.cells[i]
