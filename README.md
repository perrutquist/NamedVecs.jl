# What are NamedVecs ?

This package provides a type called a `NamedVec`, which is a subtype of `AbstractVector`, but which also has some of the traits of a `NamedTuple`.

For example, `p = NamedVec(x=1.0, y=2.0)` will create an object that behaves like the vector `[1.0, 2.0]`, but where the fields `p.x`, and `p.y` can also be accessed individually.

The fields can either be scalars, arrays, or other `NamedVec`s. (More types might be supported in the future.)

Example:
```
using NamedVecs, DifferentialEquations, LinearAlgebra

function f(u, p, t)
   NamedVec(position = u.velocity, velocity = -u.position ./ norm(u.position)^3)
end

u0 = NamedVec(position=[1.0, 0.0], velocity=[0.0, 0.5])

tspan = (0.0, 10.0)

sol = solve(ODEProblem(f, u0, tspan))
```

The fields `position` and `velocity` are defined when `u0` is created. They simply pass through the DifferentialEquations code (which knows nothing about NamedVecs) until `u` reaches our function `f` that uses those field names to get views into parts of the vector. The returned $\partial u / \partial t$ is also a `NamedVec`, which the ODE solver treats just like any other vector. 

If we wanted to work with 3D position/velocity instead, we would only need to define a new `u0`. There would be no need to pass sizes as a separate parameter to `f`.
