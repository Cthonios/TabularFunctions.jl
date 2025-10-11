# TabularFunctions.jl

## Description
This is a small package to help define julia functions via
either tabular data, e.g. (x, y) pairs, or tables of functions
to aid in simply writing piecewise analytic functions.

## Installation
Currently ```TabularFunctions.jl``` has not been registered. To install, one
can do the following in the package manager
```julia
pkg> add https://github.com/Cthonios/TabularFunctions.jl/
```

## Future installation instructions
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

```jldoctest analytic
using TabularFunctions
func = @piecewise_analytic begin
    0.0, x -> x
    1.0, x -> x^2
end;
nothing
# output

```

and this can be used like a regular julia function as follows
```jldoctest analytic
x = 0.5
y = func(x)

# output
0.5
```

```jldoctest analytic
x = 1.5
y = func(x)

# output
2.25
```

Note that closures are not necessary in the macro definition. The following is also valid syntax for the ```@piecewise_analytic``` macro
```jldoctest; output=false 
using TabularFunctions
func = @piecewise_analytic begin
    0.0, sin
    1.0, cos
end
nothing

# output

```

## PiecewiseLinearFunction
If instead you need to define a function simply from sparse tabular data, you can use the ```@piecewise_linear``` macro. This creates a simple function that will exactly reproduce values at the supplied points and linearly interpolate when provided with values between those points. If the provided input lies outside the bounds, the lower or upper bound is returned respectively. An example of a triangle wave is shown below

```jldoctest linear
using TabularFunctions
func = @piecewise_linear begin
    0.0, 0.0
    0.5, 1.0
    1.0, 0.0
end
nothing

# output

```

```jldoctest linear
x = -1.0
y = func(x)
# output
0.0
```
```jldoctest linear
x = 0.0
y = func(x)
# output
0.0
```
```jldoctest linear
x = 0.25
y = func(x)
# output
0.5
```
```jldoctest linear
x = 0.5
y = func(x)
# output
1.0
```
```jldoctest linear
x = 0.75
y = func(x)
# output
0.5
```
```jldoctest linear
x = 1.0
y = func(x)
# output
0.0
```
```jldoctest linear
x = 2.0
y = func(x)
# output
0.0
```

# Reference
```@autodocs
Modules = [TabularFunctions]
Order = [:module, :type, :function, :macro]
```
