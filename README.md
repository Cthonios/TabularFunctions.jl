[![Build Status](https://github.com/cthonios/TabularFunctions.jl/workflows/CI/badge.svg)](https://github.com/cthonios/TabularFunctions.jl/actions?query=workflow%3ACI)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Coverage](https://codecov.io/gh/cthonios/TabularFunctions.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/cthonios/TabularFunctions.jl) 
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cthonios.github.io/TabularFunctions.jl/dev/) 


# TabularFunctions.jl
1. [Description](#descrption)
2. [Installation](#installation)
3. [Examples](#examples)

# Description
This is a small package to help define julia functions via
either tabular data, e.g. (x, y) pairs, or tables of functions
to aid in simply writing piecewise analytic functions.

# Installation
Currently ```TabularFunctions.jl``` has not been registered. To install, one
can do the following in the package manager
```julia
pkg> add https://github.com/Cthonios/TabularFunctions.jl/
```

## Future instructions
From the package manager simply type
```julia
pkg> add TabularFunctions
```

Or from the REPL
```julia
julia> using Pkg
julia> Pkg.add("TabularFunctions") 
```

# Examples

## PiecewiseAnalyticFunction
Suppose we like to define a piecewise analytic function such that
$$
f(x) =
\begin{cases}
x, & \text{if } x < 1 \\
x^2, & \text{if } x \ge 1
\end{cases}
$$

then we can use the maco ```@piecewise_analytic``` to define the above function as follows

```julia
func = @piecewise_analytic begin
    0.0, x -> x
    1.0, x -> x^2
end
```

and this can be used like a regular julia function as follows
```julia
x = 0.5
y = func(x)
# y = 0.5
x = 1.5
y = func(x)
# y = 2.25
```

Note that closures are not necessary in the macro definition. The following is also valid syntax for the ```@piecewise_analytic``` macro
```julia
func = @piecewise_analytic begin
    0.0, sin(x)
    1.0, cos(x)
end
```

## PiecewiseLinearFunction
If instead you need to define a function simply from sparse tabular data, you can use the ```@piecewise_linear``` macro. This creates a simple function that will exactly reproduce values at the supplied points and linearly interpolate when provided with values between those points. If the provided input lies outside the bounds, the lower or upper bound is returned respectively. An example of a triangle wave is shown below

```julia
func = @piecewise_linear begin
    0.0, 0.0
    0.5, 1.0
    1.0, 0.0
end

x = -1.0
y = func(x)
# y = 0.0
x = 0.0
y = func(x)
# y = 0.0
x = 0.25
y = func(x)
# y = 0.5
x = 0.5
y = func(x)
# y = 1.0
x = 0.75
y = func(x)
# y = 0.5
x = 1.0
y = func(x)
# y = 0.0
x = 2.0
y = func(x)
# y = 0.0
```
