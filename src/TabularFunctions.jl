module TabularFunctions

export PiecewiseLinearFunction

struct XsNotMonotonicallyIncreasing <: Exception
end

function Base.show(io::IO, ::XsNotMonotonicallyIncreasing)
    println(io, "The vector of x values provided is not monotonically increasing")
end

function _monotonic_error()
    throw(XsNotMonotonicallyIncreasing())
end

abstract type AbstractTabularFunction{
    T1 <: Number, 
    T2 <: Number,
    V1 <: AbstractVector{T1},
    V2 <: AbstractVector{T2}
} end

struct PiecewiseLinearFunction{
    T1 <: Number, 
    T2 <: Number,
    V1 <: AbstractVector{T1},
    V2 <: AbstractVector{T2}
} <: AbstractTabularFunction{T1, T2, V1, V2}
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

        # check for monotonically increasing
        if !all(xs[i] < xs[i + 1] for i in 1:length(xs) - 1)
            _monotonic_error()
        end

        T1 = eltype(xs)
        T2 = eltype(ys)
        new{T1, T2, V1, V2}(xs, ys)
    end
end

function (func::PiecewiseLinearFunction{T1, T2, V1, V2})(x::T1) where {T1 <: Number, T2, V1, V2}
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

end # module TabularFunctions
