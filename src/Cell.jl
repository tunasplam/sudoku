#=
    0 means empty
=#

mutable struct Cell
    _value::Int
    # TODO using a set may be better. also for cells in CellBag.
    _possible_values::Vector{Int}
    _max_possible_value::Int
    cellbags::Vector{WeakRef}

    function Cell(value::Int, max_possible_value::Int=9)
        return value == 0 ?
            new(value, collect(1:max_possible_value), max_possible_value, CellBag[]) :
            new(value, Int[], max_possible_value, CellBag[])
    end

    # should only be used for testing and development only 
    Cell(value::Int, possible_values::Vector{Int}, max_possible_value::Int) = 
        new(value, possible_values, max_possible_value, CellBag[])
end

"""
    get_possible_values(c::Cell)::Vector{Int}

Returns possible_values for a given cell. Never access _possible_values directly.
possible_values does not get updated to reflect changes from is surrounding cells and cellbags.
This method cleans up _possible_values and returns it.
"""
function get_possible_values(c::Cell)::Vector{Int}
    update_possible_values(c)
    return c._possible_values
end

function update_possible_values(c::Cell)
    pvs = c._possible_values
    for cb ∈ c.cellbags, fc ∈ filled_cells(cb.value)
        if (i = findfirst(pv -> pv == fc._value, pvs)) !== nothing
            deleteat!(c._possible_values, i)
        end
    end
end

"""
    set_value(c::Cell, x::Int)

Sets a cell's value, clears its possible values, and removes its value
as a possible value for all other member cells in its cellbags.
"""
function set_value(c::Cell, x::Int)
    c._value = x
    empty!(c._possible_values)
end

"""
    remove_possible_value(c::Cell, x::Int)

Remove a possible value for a cell
"""
function remove_possible_value(c::Cell, x::Int)
    # return if not present in possible_values
    if (i = findfirst(v -> v == x, get_possible_values(c))) === nothing
        return
    end
    deleteat!(c._possible_values, i)
end

function set_if_only_one_option_left(c::Cell)
    pvs = get_possible_values(c)
    if length(pvs) == 1
        set_value(c, pvs[begin])
    end
end

Base.isempty(c::Cell)::Bool = c._value == 0

# this formats how printing out a cell looks in console. avoids infinite recursion
# due to circular relationship btwn cells and cellbags
function Base.show(io::IO, c::Cell)
    print(io, "\n\tCell(", c._value, ", ", c._possible_values, ")")
end