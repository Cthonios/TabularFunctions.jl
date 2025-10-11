using Documenter
using TabularFunctions

DocMeta.setdocmeta!(TabularFunctions, :DocTestSetup, :(using TabularFunctions); recursive=true)
# meshes_ext = Base.get_extension(Exodus, :ExodusMeshesExt)
# unitful_ext = Base.get_extension(Exodus, :ExodusUnitfulExt)
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
        # "Exodus"           => "index.md",
        # "Installation"     => "installation.md",
        # "Opening Files"    => "opening_files.md",
        # "Reading Data"     => "reading_data.md",
        # "Writing Data"     => "writing_data.md",
        # "Use With MPI"     => "use_with_mpi.md",
        # "Exodus Methods"   => "methods.md",
        # "Exodus Types"     => "types.md",
        # "ExodusMeshesExt"  => "meshes_ext.md",
        # "ExodusUnitfulExt" => "unitful_ext.md",
        # "Glossary"         => "glossary.md"
        # "README" => "../README.md"
        "TabularFunctions" => "index.md"
    ],
)

deploydocs(;
    repo="github.com/Cthonios/TabularFunctions.jl",
    devbranch="main"
)
