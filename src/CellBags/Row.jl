#=
How they are indexed:
 id
 1   xxx
 2   xxx
 3   xxx
=#

mutable struct Row{Cell} <: LinearCellBag
    id::Int
    cells::Vector{Cell}

    """
        Row(id::Int, cells::SubArray)

    Creating using views of a matric representing the puzzle
    """
    function Row(id::Int, cells::SubArray)
        r = new{Cell}(id, cells)
        remove_possible_values!(r, 1)
        return r
    end

    """
        Row(id::Int, cells::Vector{Cell})

    For creating a row explicitly off of cells (testing and dev only)
    """
    function Row(id::Int, cells::Vector{Cell})
        r = new{Cell}(id, cells)
        remove_possible_values!(r, 1)
        return r
    end
end

get_cells(r::Row) = r.cells

"""
    create_all(::Type{Row}, cells::Matrix{Cell})::Vector{Row}

Given a grid that represents the initial state of the puzzle,
instantiates all Rows
"""
function create_all(::Type{Row}, cells::Matrix{Cell})::Vector{Row}
    rows = [Row(i, r) for (i, r) in enumerate(eachrow(cells))]
    for r ∈ rows, c ∈ get_cells(r)
        push!(c.cellbags, WeakRef(r))
    end
    return rows
end
