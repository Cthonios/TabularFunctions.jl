module TabularFunctions

export PiecewiseAnalyticFunction
export @piecewise_analytic
export PiecewiseLinearFunction
export @piecewise_linear

using Adapt
using DocStringExtensions
using KernelAbstractions

# Error helpers
"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct XsNotMonotonicallyIncreasing <: Exception
end

function Base.show(io::IO, ::XsNotMonotonicallyIncreasing)
    println(io, "The vector of x values provided is not monotonically increasing")
end

function _monotonic_error()
    exc = XsNotMonotonicallyIncreasing()
    @show exc
    throw(exc)
end

# Abstract types
"""
$(TYPEDEF)
"""
abstract type AbstractTabularFunction{
    V <: AbstractVector{<:Number}
} end

"""
$(TYPEDSIGNATURES)
"""
function KernelAbstractions.get_backend(f::AbstractTabularFunction)
    return get_backend(f.x_vals)
end

"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct PiecewiseAnalyticFunction{
    V <: AbstractVector{<:Number},
    Funcs
} <: AbstractTabularFunction{V}
    x_vals::V
    funcs::Funcs
end

"""
$(TYPEDSIGNATURES)
"""
function PiecewiseAnalyticFunction(
    xs::V, funcs::Funcs
) where {
    V <: AbstractVector{<:Number},
    Funcs <: AbstractVector
}
    # ensure there's one func for each point
    @assert length(xs) == length(funcs)

    # check for monotonically increasing
    if !all(xs[i] < xs[i + 1] for i in 1:length(xs) - 1)
        _monotonic_error()
    end

    syms = map(x -> Symbol("func_$x"), 1:length(funcs))
    funcs = NamedTuple{tuple(syms...)}(tuple(funcs...))
    # new{V, typeof(funcs)}(xs, funcs)
    return PiecewiseAnalyticFunction(xs, funcs)
end

"""
$(TYPEDSIGNATURES)
"""
function Adapt.adapt_structure(to, func::PiecewiseAnalyticFunction)
    return PiecewiseAnalyticFunction(
        adapt(to, func.x_vals),
        adapt(to, func.funcs)
    )
end

function _func(func::PiecewiseAnalyticFunction, x, ::CPU)
    if x <= func.x_vals[1]
        return values(func.funcs)[1](x)
    elseif x >= func.x_vals[end]
        return values(func.funcs)[end](x)
    else
        i = searchsortedlast(func.x_vals, x)
        return values(func.funcs)[i](x)
    end
end

"""
$(TYPEDSIGNATURES)
"""
function (func::PiecewiseAnalyticFunction{V1, Funcs})(x::T) where {
    T <: Number,
    V1 <: AbstractVector{T}, 
    Funcs
}
    return _func(func, x, get_backend(func.x_vals))
end

# Piecewise Linear
"""
$(TYPEDEF)
$(TYPEDFIELDS)
"""
struct PiecewiseLinearFunction{
    V1 <: AbstractVector{<:Number},
    V2 <: AbstractVector{<:Number}
} <: AbstractTabularFunction{V1}
    x_vals::V1
    y_vals::V2

    function PiecewiseLinearFunction(
        xs::V1, ys::V2
    ) where {
        V1 <: AbstractVector{<:Number},
        V2 <: AbstractVector{<:Number}
    }
        # ensure x and y values are the same length
        @assert length(xs) == length(ys)
        @assert get_backend(xs) == get_backend(ys)

        # check for monotonically increasing
        if !all(xs[i] < xs[i + 1] for i in 1:length(xs) - 1)
            _monotonic_error()
        end

        new{V1, V2}(xs, ys)
    end
end

"""
$(TYPEDSIGNATURES)
"""
function Adapt.adapt_structure(to, f::PiecewiseLinearFunction)
    return PiecewiseLinearFunction(
        adapt(to, f.x_vals), 
        adapt(to, f.y_vals)
    )
end

# CPU implementation
# function (func::PiecewiseLinearFunction{T1, T2, V1, V2})(x::T1) where {T1 <: Number, T2, V1, V2}
function _func(func::PiecewiseLinearFunction, x, ::CPU)
    if x <= func.x_vals[1]
        return func.y_vals[1]
    elseif x >= func.x_vals[end]
        return func.y_vals[end]
    else
        i = searchsortedlast(func.x_vals, x)
        x0, x1 = func.x_vals[i], func.x_vals[i+1]
        y0, y1 = func.y_vals[i], func.y_vals[i+1]
    
        # linear interpolation
        t = (x - x0) / (x1 - x0)
        return y0 + t * (y1 - y0)
    end
end

# @kernel function _func_kernel(func, x)
#     I = @index(Global)

#     if I == 1

#     elseif I == length(func.y_vals)

#     end
# end

function _func(func, x, ::Backend)
    @assert false "Implement me"
    # kernel! = _func_kernel(func, x)
    # kernel!(func, x, ndrange = length(func.x_vals) + 1)
end

"""
$(TYPEDSIGNATURES)
"""
function (func::PiecewiseLinearFunction{V1, V2})(x::T) where {
    T <: Number,
    V1 <: AbstractVector{T}, 
    V2
}
    return _func(func, x, get_backend(func.x_vals))
end

# Macros
function _is_number_expr(ex)
    # unwrap top-level :$ and :escape wrappers
    while ex isa Expr && ex.head in (:escape, :$, :quote)
        ex = ex.args[1]
    end

    return ex isa Number
end

struct BadMacroInput <: Exception
    msg::String
end

function _bad_macro_input(msg::String)
    throw(BadMacroInput(msg))
end

"""
$(TYPEDSIGNATURES)
Example:
Define a function that switches between a linear and quadratic function
```jldoctest
func = @piecewise_analytic begin
    0.0, x -> x
    1.0, x -> x^2
end

func(0.)

# output
0.0

```
"""
macro piecewise_analytic(expr)
    # Extract expressions inside the block
    lines = expr isa Expr && expr.head == :block ? expr.args : [expr]

    xs = Any[]
    fs = Any[]

    for line in lines
        args = if line isa Expr && line.head == :tuple
            line.args
        elseif line isa LineNumberNode
            continue
        else
            _bad_macro_input(
                "@piecewise_analytic: each line must be 'x, func'" *
                "\nbad line provided: $line"
            )
        end
    
        x_expr = esc(args[1])
        f_expr = esc(args[2])
        # wrap numbers into constant functions

        if _is_number_expr(f_expr)
            f_expr = :(x -> $(f_expr))
        end
    
        push!(xs, x_expr)
        push!(fs, f_expr)
    end

    return :(PiecewiseAnalyticFunction([$(xs...)], [$(fs...)]))
    # end
end

"""
$(TYPEDSIGNATURES)
Example:
Define a triangular wave of a single period
```julia
func = @piecewise_linear begin
    0.0, 0.0
    0.5, 1.0
    1.0, 0.0
end
```
"""
macro piecewise_linear(expr)
    # Get the expressions inside the block
    pairs = expr isa Expr && expr.head == :block ? expr.args : [expr]

    # Filter out line-number expressions etc.
    pairs = [p for p in pairs if p isa Expr && p.head == :tuple]

    xs = Any[]
    ys = Any[]

    for p in pairs
        if length(p.args) == 2
            push!(xs, esc(p.args[1]))
            push!(ys, esc(p.args[2]))
        else
            _bad_macro_input(
                "@piecewise_linear: each line must be 'x, y'" *
                "\nbad line provided: $line"
            )
        end
    end

    return :(PiecewiseLinearFunction([$(xs...)], [$(ys...)]))
end

end # module TabularFunctions
