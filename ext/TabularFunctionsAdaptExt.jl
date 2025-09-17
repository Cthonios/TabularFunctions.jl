module TabularFunctionsAdaptExt

using Adapt
using TabularFunctions

function Adapt.adapt_structure(to, f::PiecewiseLinearFunction)
    return PiecewiseLinearFunction(adapt(to, f.x_vals), adapt(to, f.y_vals))
end

end # module
