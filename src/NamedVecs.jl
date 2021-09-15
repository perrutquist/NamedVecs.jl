module NamedVecs

export NamedVec

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
struct NamedVec{T,Names,D<:AbstractVector{T},M} <: AbstractVector{T}
    data::D
    maps::NamedTuple{Names, M}
end

# Constructors

function NamedVec(data::AbstractVector, names::NTuple{N, Symbol}, maps::Tuple{Vararg{Any,N}}) where {N}
    NamedVec(data, NamedTuple{names}(maps))
end

"""
A `NamedVec` can be created from a `NamedTuple` of arrays. The arrays are copied (not aliased) into the new object.
"""
function NamedVec(xs::NamedTuple{Names, <:Tuple{AbstractArray, Vararg{AbstractArray}}}) where {Names}
    ns = map(length, Tuple(xs))
    lastix = cumsum(ns)
    firstix = lastix .- ns .+ 1
    T = promote_type(eltype.(Tuple(xs))...)
    data = similar(first(xs), T, (sum(ns),))
    v = NamedVec(data, Names, ntuple(i->(firstix[i]:lastix[i] => viewfun(xs[i])), length(xs)))
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

viewfun(::AbstractVector) = identity

# Conversion

"`vec(v::NamedVec)` returns the underlying data vector of a NamedVec"
Base.vec(v::NamedVec) = getfield(v, :data)

"oftype(x::NamedVec, y) converts a vector y into a NamedVec with the names and indices of x"
function Base.oftype(v::NamedVec{Names, <:Tuple{Vararg{AbstractArray}}}, w::AbstractVector) where {Names}
    @boundscheck eachindex(v) == eachindex(w) || error("Size missmatch.")
    NamedVec(w, maps(v))
end

"""
`Tuple(v::NamedVec)` returns a tuple of the views into `v`.
For a tuple of the elements of the vector, use `Tuple(vec(v))`.
"""
function Base.Tuple(v::NamedVec) 
    let data=vec(v)
        map(m->m[2](view(data, m[1])), maps(v))
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
Base.getindex(v::NamedVec, ix::Integer) = getindex(vec(v), ix)
Base.setindex!(v::NamedVec, y, ix::Integer) = setindex!(vec(v), y, ix)

#Base.:*(a::Number, v::NamedVec) = NamedVec(a * vec(v),

# NamedTuple-like

function Base.getproperty(v::NamedVec, s::Symbol) 
    ix, f = getproperty(maps(v), s)
    f(view(vec(v), ix))
end

# Utility functions
# (These are unexported and mainly for internal use)

maps(v::NamedVec) = getfield(v, :maps)

end # modulev
