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
struct NamedVec{T,Names,D<:AbstractVector{T},I,F} <: AbstractVector{T}
    data::D
    indices::NamedTuple{Names, I}
    unvecs::NamedTuple{Names, F}
end

# Constructors

function NamedVec(data::AbstractVector, names::NTuple{N, Symbol}, indices::Tuple{Vararg{Any,N}}, unvecs::Tuple{Vararg{Any,N}}) where {N}
    NamedVec(data, NamedTuple{names}(indices), NamedTuple{names}(unvecs))
end

"""
A `NamedVec` can be created from a `NamedTuple` of arrays. The arrays are copied (not aliased) into the new object.
"""
function NamedVec(xs::NamedTuple{Names, <:Tuple{AbstractArray, Vararg{AbstractArray}}}) where {Names}
    ns = map(length, Tuple(xs))
    lastix = cumsum(ns)
    firstix = lastix .- ns .+ 1
    data = similar(first(xs), (sum(ns),))
    v = NamedVec(data, Names, ntuple(i->firstix[i]:lastix[i], length(xs)), viewfun.(Tuple(xs)))
    for n in Names
        getproperty(v, n) .= getproperty(xs, n)
    end
    v
end

"""
`viewfun(x)` - Returns a function that create an object that is like `x`, from a vector 
with the correct number of elements.
"""
function viewfun(x::AbstractArray)
    let sz = size(x)
        v -> reshape(v, sz)
    end
end

viewfun(x::AbstractVector) = identity

# Conversion

"`vec(v::NamedVec)` returns the underlying data vector of a NamedVec"
Base.vec(v::NamedVec) = getfield(v, :data)

"oftype(x::NamedVec, y) converts a vector y into a NamedVec with the names and indices of x"
function Base.oftype(v::NamedVec{Names, <:Tuple{Vararg{AbstractArray}}}, w::AbstractVector) where {Names}
    @boundscheck eachindex(v) == eachindex(w) || error("Size missmatch.")
    NamedVec(w, indices(v), unvecs(v))
end

"""
`Tuple(v::NamedVec)` returns a tuple of the views into `v`.
For a tuple of the elements of the vector, use `Tuple(vec(v))`.
"""
function Base.Tuple(v::NamedVec) 
    let data=vec(v)
        map((i,f)->f(data[i]), Tuple(getfield(v, :indices)), Tuple(getfield(v, :unvecs)))
    end
end

"`NamedTuple(v::NamedVec)` returns a `NamedTuple` of the views into `v`."
Base.NamedTuple(v::NamedVec{<:Any,Names}) where {Names} = NamedTuple{Names}(Tuple(v))

# Display

function Base.show(io::IO, ::MIME"text/plain", v::NamedVec)
    println(io, length(v), "-element NamedVec{", eltype(v), "}:")
    show(io, NamedTuple(v))
end

# Vector-like

Base.length(v::NamedVec) = length(vec(v))
Base.eachindex(v::NamedVec) = eachindex(vec(v))
Base.eltype(v::NamedVec) = eltype(vec(v))
Base.size(v::NamedVec) = size(vec(v))
Base.size(v::NamedVec, dim::Integer) = size(vec(v), dim)

#Base.:*(a::Number, v::NamedVec) = NamedVec(a * vec(v),

# NamedTuple-like

Base.getproperty(v::NamedVec, s::Symbol) = view(vec(v), getproperty(indices(v), s)) |> getproperty(unvecs(v), s)

# Utility functions
# (These are unexported and mainly for internal use)

indices(v::NamedVec) = getfield(v, :indices)
unvecs(v::NamedVec) = getfield(v, :unvecs)

end # modulev
