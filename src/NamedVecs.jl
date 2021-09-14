module NamedVecs

"""
A `NamedVec` is a kind of hybrid between a `Vector` and a `NamedTuple`. This can be useful, 
for example, in mathematical modelling where collections of parameters are some times treated 
as a single vector but at other times acessed individually.

`NamedVec` supports vector operations, such as `+` and `*`, that are useful in linear algebra.

At the same time, a `NamedVec` can be indexed by field names to obtain reshaped views into
parts of the vector. 

Example:
```
v = NamedVec((a=[1], b=[2, 3]))
v' * v # returns 14
f((;a, b)) = 2a .+ b
f(v) # returns [4, 5]
```

"""
struct NamedVec{T,D<:AbstractVector{T},V<:NamedTuple} <: AbstractVector{T}
    data::D
    views::V
    function NamedVec(data::D, views::V) where {D<:AbstractVector{T}, V} where T
        for v in views
            v isa AbstractArray{T} || error("Wrong type view")
        end
        new{T,D,V}(data, views)
    end
end

# Constructors

"""
A `NamedVec` can be created from a `NamedTuple` of arrays. The arrays are copied (not aliased) into the new object.
"""
function NamedVec(xs::NamedTuple{Names, Tuple{Vararg{<:AbstractArray}}})
    ns = map(length, xs)
    lastix = cumsum(ns)
    firstix = lastix .- ns
    data = similar(first(xs), (sum(ns),))
    views = NamedTuple{names}(ntuple(i->viewlike(xs[i], data, firstix[i]:lastix[i]), length(xs)))
    NamedVec(data, views)
end

NamedVec(::NamedTuple{(), Tuple{}}) = error("A NamedVec must have at least one filed.")

# Conversion

"`vec(v::NamedVec)` returns the underlying data `<:AbstractVector`."
Base.vec(v::NamedVec) = getfield(v, :data)

"`NamedTuple(v::NamedVec)` returns a `NamedTuple` of the views into `v`."
Base.NamedTuple(v::NamedVec) = getfield(v, :views)

# Display

function Base.show(io::IO, v::NamedVec)
    println(io, length(v), "-element NamedVec{", eltype(v), "}:")
    show(io, NamedTuple(v))
end

# Vector-like

Base.length(v::NamedVec) = length(vec(v))
Base.eltype(v::NamedVec) = eltype(vec(v))

# NamedTuple-like

Base.getproperty(v::NamedVec, s::Symbol) = getproperty(NamedTuple(v), s)
Base.getproperty(v::NamedVec, i::Integer) = getproperty(NamedTuple(v), i)

"""
`Tuple(v::NamedVec)` returns a tuple of the views into `v`.
For a tuple of the elements of the vector, use `Tuple(vec(v))`.
"""
Base.Tuple(v::NamedVec) = Tuple(NamedTuple(v))

end # module


# # Utility functions

# "`unanimous` is a utility function that checks that all elements of an iterable are identical, and returns one of them"
# function unanimous(v)
#     isempty(v) && throw("Vector must not be empty")
#     v1 = first(v)
#     length(v) == 1 && return v1
#     for u in v
#         u == v1 || error("Elements differ")
#     end
#     v1
# end
