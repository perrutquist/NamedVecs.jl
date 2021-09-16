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
f((;a, b)) = 2a .+ b # This notation requires Julia 1.7
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
function NamedVec(::Type{T}, xs::NamedTuple{Names, <:Tuple{Any, Vararg{Any}}}) where {T<:AbstractVector, Names}
    ns = map(length, Tuple(xs)) # TODO: should look at number of elements actually used.
    lastix = cumsum(ns)
    firstix = lastix .- ns .+ 1
    data = similar(T isa UnionAll ? T{promote_type(eltype.(Tuple(xs))...)} : T, (sum(ns),))
    maps = ntuple(length(xs)) do i
        (xs[i] isa Real ? firstix[i] : firstix[i]:lastix[i]) => viewfun(xs[i])
    end
    v = NamedVec(data, Names, maps)
    for n in Names
        setproperty!(v, n, getproperty(xs, n))
    end
    v
end

"NamedVec, if the vector type is not specified, uses `Vector`."
function NamedVec(xs::NamedTuple{Names, <:Tuple{Any, Vararg{Any}}}) where {Names}
    E = promote_type(eltype.(Tuple(xs))...)
    NamedVec(Vector{E}, xs)
end

NamedVec(::Type{T}; kwargs...) where {T<:AbstractVector} = NamedVec(T, NamedTuple(kwargs))
NamedVec(; kwargs...) = NamedVec(NamedTuple(kwargs))

"""
`viewfun(x)` - Returns a function that create an object that is like `x`, from a vector 
with the correct number of elements.
"""
function viewfun(x::AbstractArray)
    let sz = size(x)
        v -> reshape(v, sz)
    end
end

function viewfun(x::NamedVec)
    let m = maps(x)
        v -> NamedVec(v, m)
    end
end 

viewfun(::AbstractVector{<:Real}) = identity

viewfun(::Real) = getindex

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

Base.eltype(::NamedVec{T}) where {T} = T
Base.length(v::NamedVec) = length(vec(v))
Base.eachindex(v::NamedVec) = eachindex(vec(v))
Base.size(v::NamedVec) = size(vec(v))
Base.size(v::NamedVec, dim::Integer) = size(vec(v), dim)
Base.getindex(v::NamedVec, ix::Integer) = getindex(vec(v), ix)
Base.setindex!(v::NamedVec, y, ix::Integer) = setindex!(vec(v), y, ix)

Base.:*(a::Number, v::NamedVec) = NamedVec(a * vec(v), maps(v))
Base.:+(a::NamedVec{Names}, b::NamedVec{Names}) where {Names} = NamedVec(vec(a) + vec(b), maps(a))

Base.similar(a::NamedVec) = NamedVec(similar(vec(a)), maps(a)) 
Base.copy(a::NamedVec) = NamedVec(copy(vec(a)), maps(a)) 

# Vector-like broadcasting

struct NamedVecStyle <: Broadcast.AbstractArrayStyle{1}
end

Base.Broadcast.BroadcastStyle(::Type{<:NamedVec}) = NamedVecStyle()
Base.Broadcast.BroadcastStyle(a::NamedVecs.NamedVecStyle, ::Base.Broadcast.DefaultArrayStyle{0}) = a
Base.Broadcast.BroadcastStyle(a::NamedVecs.NamedVecStyle, ::Base.Broadcast.DefaultArrayStyle{1}) = a
Base.Broadcast.BroadcastStyle(::NamedVecs.NamedVecStyle, b::Base.Broadcast.DefaultArrayStyle) = b

function Base.similar(bc::Broadcast.Broadcasted{NamedVecStyle}, ::Type{T}) where {T}
    # TOOD: We should maybe check that there are not conflicting sets of names.
    v = getnv(bc)
    NamedVec(similar(vec(v), T), maps(v))
end

"getnv extracts the first NamedVec it can find in a Broadcasted object"
getnv(::Any) = nothing
getnv(x::NamedVec) = x
function getnv(bc::Broadcast.Broadcasted{NamedVecStyle})
    for a in bc.args
        y = getnv(a)
        y isa NamedVec && return y
    end
    nothing
end

# NamedTuple-like

Base.propertynames(::NamedVec{<:Any, Names}, ::Bool=false) where {Names} = Names

function Base.getproperty(v::NamedVec, s::Symbol) 
    ix, f = getproperty(maps(v), s)
    f(view(vec(v), ix))
end

function Base.setproperty!(v::NamedVec, s::Symbol, y) 
    ix, f = getproperty(maps(v), s)
    if f === getindex
        vec(v)[ix] = y
    else
        f(view(vec(v), ix)) .= y
    end
end

# Utility functions
# (Unexported and mainly for internal use)

maps(v::NamedVec) = getfield(v, :maps)

end # modulev
