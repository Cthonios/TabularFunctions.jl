module TabularFunctions

export PiecewiseAnalyticFunction
export @piecewise_analytic
export PiecewiseLinearFunction
export @piecewise_linear

using Adapt
using DocStringExtensions
using KernelAbstractions

# Error helpers
struct XsNotMonotonicallyIncreasing <: Exception
end

function Base.show(io::IO, ::XsNotMonotonicallyIncreasing)
    println(io, "The vector of x values provided is not monotonically increasing")
end

function _monotonic_error()
    throw(XsNotMonotonicallyIncreasing())
end

# Abstract types
abstract type AbstractTabularFunction{
    V <: AbstractVector{<:Number}
} end


function KernelAbstractions.get_backend(f::AbstractTabularFunction)
    return get_backend(f.x_vals)
end

struct PiecewiseAnalyticFunction{
    V <: AbstractVector{<:Number},
    # Funcs <: NamedTuple
    Funcs
} <: AbstractTabularFunction{V}
    x_vals::V
    funcs::Funcs
end

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

function (func::PiecewiseAnalyticFunction{V1, Funcs})(x::T) where {
    T <: Number,
    V1 <: AbstractVector{T}, 
    Funcs
}
    return _func(func, x, get_backend(func.x_vals))
end

# Piecewise Linear
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

function (func::PiecewiseLinearFunction{V1, V2})(x::T) where {
    T <: Number,
    V1 <: AbstractVector{T}, 
    V2
}
    return _func(func, x, get_backend(func.x_vals))
end

# Macros
macro piecewise_analytic(expr)
    # Extract expressions inside the block
    lines = expr isa Expr && expr.head == :block ? expr.args : [expr]

    xs = Any[]
    fs = Any[]

    for line in lines
        args = if line isa Expr && line.head == :tuple
            line.args
        # elseif line isa Expr && line.head == :call && line.args[1] === :(,)
        #     line.args[2:3]  # skip the first element, which is the comma operator
        elseif line isa LineNumberNode
            continue
        else
            error("@piecewise_analytic: each line must be 'x, func'")
        end
    
        x_expr = esc(args[1])
        f_expr = esc(args[2])
        # wrap numbers into constant functions
        if f_expr isa Number
            f_expr = :(x -> $(f_expr))
        end
    
        push!(xs, x_expr)
        push!(fs, f_expr)
    end

    return :(PiecewiseAnalyticFunction([$(xs...)], [$(fs...)]))
    # end
end

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
            error("@piecewise_linear: each line must be 'x, y'")
        end
    end

    return :(PiecewiseLinearFunction([$(xs...)], [$(ys...)]))
end

end # module TabularFunctions
