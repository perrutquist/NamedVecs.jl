# What are `NamedVec`s

This package provides vector wrapper type called a `NamedVec`, which, in addition to acting like a vector, can act like a `NamedTuple` in some circumstances.

For example, `p = NamedVec(x=1.0, y=2.0)` will create an object that behaves like the vector `[1.0, 2.0]`, but where the fields `p.x`, and `p.y` can also be accessed individually.

The fields can either be scalars (as in the above example), arrays, or `NamedVec`s. (More types can be supported on request. Just file an issue or write a pull request.)

```
using NamedVecs, DifferentialEquations, LinearAlgebra

function f(u)
   udot = similar(u)
   udot.position = u.velocity
   udot.velocity = -u.position ./ norm(u.position)^3
   return udot
end

u0 = NamedVec(position=[1.0, 0.0], velocity=[0.0, 0.5])

tspan = (0.0, 10.0)

sol = solve(ODEProblem(f, u0, tspan))
```
