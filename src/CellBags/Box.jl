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

# a trait for box is that ↔ is defined for these combinations of types...
compare_trait(::Type{Box}, ::Type{T}) where {T<:LinearCellBag} = HasCompare()
compare_trait(::Type{T}, ::Type{Box}) where {T<:LinearCellBag} = HasCompare()
# ... but not for this one.
compare_trait(::Type{Box}, ::Type{Box}) = MissingCompare()
unique_values_trait(::Type{Box{Cell}}) = ValuesUnique()

import Base: ↔

"""
    ↔(b::Box{Cell}, r::LinearCellBag, ::HasCompare)::Tuple{Box{Cell}, LinearCellBag}

Update the intersecting cells using the information from the non-intersecting
LinearCellBag cells
"""
function ↔(b::Box{Cell}, r::LinearCellBag, ::HasCompare)::Tuple{Box{Cell}, LinearCellBag}
    bcs = get_cells(b)
    rcs = get_cells(r)
    # for all of the non empty cells in the complement
    for rc ∈ filter(c -> ! isempty(c), rcs \ bcs)
        # for all of the empty cells in the intersection
        for bc ∈ filter(c -> isempty(c), rcs ∩ bcs)
            remove_possible_value(bc, rc._value)
        end
    end
    return (b, r)
end

↔(r::LinearCellBag, b::Box{Cell}, ::HasCompare)::Tuple{LinearCellBag, Box{Cell}} = reverse(↔(b, r, HasCompare()))

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
