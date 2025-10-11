using Documenter
using Plots
using TabularFunctions

DocMeta.setdocmeta!(TabularFunctions, :DocTestSetup, :(using TabularFunctions); recursive=true)
# meshes_ext = Base.get_extension(Exodus, :ExodusMeshesExt)
# unitful_ext = Base.get_extension(Exodus, :ExodusUnitfulExt)
# recipes_ext = Base.get_extension(TabularFunctions, :TabularFunctionsRecipesBaseExt)
makedocs(;
    # modules=[Exodus, meshes_ext, unitful_ext],
    modules=[TabularFunctions],
    authors="Craig M. Hamel <cmhamel32@gmail.com> and contributors",
    repo="https://github.com/cthonios/TabularFunctions.jl/blob/{commit}{path}#{line}",
    sitename="TabularFunctions.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://cthonios.github.io/TabularFunctions.jl/stable",
        edit_link="main",
        assets=String[],
        size_threshold=nothing
    ),
    pages=[
        "TabularFunctions" => "index.md"
    ],
)

deploydocs(;
    repo="github.com/Cthonios/TabularFunctions.jl",
    devbranch="main"
)
