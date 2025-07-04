#=
How they are indexed:
 id
    123
    xxx
    xxx
    xxx
=#

mutable struct Column{Cell} <: LinearCellBag
    id::Int
    cells::Vector{Cell}

    """
        Column(id::Int, cells::SubArray)

    Creating using views of a matric representing the puzzle
    """
    function Column(id::Int, cells::SubArray)
        c = new{Cell}(id, cells)
        remove_possible_values!(c, 1)
        return c        
    end

    """
        Column(id::Int, cells::Vector{Cell})

    For creating a row explicitly off of cells (testing and dev only)
    """
    function Column(id::Int, cells::Vector{Cell})
        c = new{Cell}(id, cells)
        remove_possible_values!(c, 1)
        return c
    end
end

get_cells(c::Column) = c.cells

"""
    create_all(::Type{Column}, cells::Matrix{Cell})::Vector{Column}

Given a grid that represents the initial state of the puzzle,
instantiates all Columns
"""
function create_all(::Type{Column}, cells::Matrix{Cell})::Vector{Column}
    cols = [Column(i, r) for (i, r) in enumerate(eachcol(cells))]
    for C ∈ cols, c ∈ get_cells(C)
        push!(c.cellbags, WeakRef(C))
    end
    return cols
end
