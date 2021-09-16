# What are `NamedVec`s

This package provides vector wrapper type called a `NamedVec`, which, in addition to acting like a vector, can act like a `NamedTuple` in some circumstances.

For example, `p = NamedVec(x=1.0, y=2.0)` will create an object that behaves like the vector `[1.0, 2.0]`, but where the fields `p.x`, and `p.y` can also be accessed individually.

The fields can either be scalars (as in the above example), arrays, or `NamedVec`s. (More types might be supported in the future.)

Example:
```
using NamedVecs, DifferentialEquations, LinearAlgebra

function f(u, p, t)
   udot = similar(u)
   udot.position = u.velocity
   udot.velocity = -u.position ./ norm(u.position)^3
   return udot
end

u0 = NamedVec(position=[1.0, 0.0], velocity=[0.0, 0.5])

tspan = (0.0, 10.0)

sol = solve(ODEProblem(f, u0, tspan))
```

(Note: This is just an illustrations. DifferentialEquations has an `@ode_def` macro that provides similar functionality.)

The fields `position` and `velocity` are defined when `u0` is created. They simply pass through the DifferentialEquations code (which knows nothing about NamedVecs) until `u` reaches our function `f` which uses those field names to extract parts of the vector. The returned `udot` is also a `NamedVec`, which the ODE solver treats just like any other vector. 

If we wanted to work with 3D position/velocity instead, we would only need to define a new `u0`. There is no need to pass sizes as a separate parameter to `f`.

