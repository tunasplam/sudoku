#=
Rows, Columns, and Diagonals (all lines that stretch from one end to the other)
have pretty much the same logic
=#

abstract type LinearCellBag <: CellBag end

get_cells(::LinearCellBag) = error("Must implement get_cells for LinearCellBag")
create_all(::LinearCellBag) = error("Must implement create_all for LinearCellBag")

# compare trait among LinearCellBags is redundant with checking wihin a LinearCellBag
compare_trait(::Type{T1}, ::Type{T2}) where {T1<:LinearCellBag, T2<:LinearCellBag} = MissingCompare()

function iscorrect(b::LinearCellBag)::Bool
    filled_cell_values = map(c -> c._value, filled_cells(b))
    if length(filled_cell_values) != length(unique(filled_cell_values))
        return false
    end
    return true
end

Base.size(b::LinearCellBag) = size(b.cells)
Base.length(b::LinearCellBag) = length(b.cells)
Base.iterate(b::LinearCellBag, i=1) = i > length(b) ? nothing : (get_cells(b)[i], i+1)
# needed for safely calling zip and isempty
Base.isdone(b::LinearCellBag, i) = i == length(b)
Base.pairs(b::LinearCellBag) = enumerate(b.cells)
Base.getindex(b::LinearCellBag, i::Int) = b.cells[i]

"""
remove_possible_values!(b::LinearCellBag)

Using filled cells within the cellbag, removes filled values from possible values of
empty cells within the cellbag.
"""
function remove_possible_values!(c::LinearCellBag)
    fcs = filled_cells(c)
    ecs = empty_cells(c)

    while ! isempty(fcs)
        fc = pop!(fcs)
        map(ec -> remove_possible_value(ec, fc._value), ecs)
    end
end
