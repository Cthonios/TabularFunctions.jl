module TabularFunctionsRecipesBaseExt

using RecipesBase
using TabularFunctions

@recipe function f(x, func::TabularFunctions.AbstractTabularFunction)
    xlabel --> "x"
    ylabel --> "y"

    @series begin
        seriestype := :path
        x, func.(x)
    end
end 

end # module
