#=
How they are indexed:
id
 1
    - -
     -
    - -
 2
=#

mutable struct Diagonal{Cell} <: LinearCellBag
    id::Int
    cells::Vector{Cell}

    function Diagonal(id::Int, cells::Vector{Cell})
        d = new(id, cells)
        for clue in filled_cells(d), cell in empty_cells(d)
            remove_possible_value(cell, clue._value)
        end
        return d
    end
end

get_cells(d::Diagonal) = d.cells

"""
    create_all(::Type{Diagonal}, cells::Matrix{Cell})::Vector{Diagonal}

Given a grid that represents the initial state of the puzzle,
instantiates all Diagonals
"""
function create_all(::Type{Diagonal}, cells::Matrix{Cell})::Vector{Diagonal}
    # TODO This one is not as straight forward
    #return [Diagonal(i, d) for (i, d) in enumerate(cells)]
    return 
end