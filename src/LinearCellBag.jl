#=
Rows, Columns, and Diagonals (all lines that stretch from one end to the other)
have pretty much the same logic
=#

abstract type LinearCellBag <: CellBag end

get_cells(::LinearCellBag) = error("Must implement get_cells for LinearCellBag")
create_all(::LinearCellBag) = error("Must implement create_all for LinearCellBag")

# compare trait among LinearCellBags is redundant with checking wihin a LinearCellBag
compare_trait(::Type{T1}, ::Type{T2}) where {T1<:LinearCellBag, T2<:LinearCellBag} = MissingCompare()
unique_values_trait(::Type{T}) where {T<:LinearCellBag} = ValuesUnique()

Base.size(b::LinearCellBag) = size(b.cells)
Base.length(b::LinearCellBag) = length(b.cells)
Base.iterate(b::LinearCellBag, i=1) = i > length(b) ? nothing : (get_cells(b)[i], i+1)
# needed for safely calling zip and isempty
Base.isdone(b::LinearCellBag, i) = i == length(b)
Base.pairs(b::LinearCellBag) = enumerate(b.cells)
Base.getindex(b::LinearCellBag, i::Int) = b.cells[i]
