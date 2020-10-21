using SimLynx
using Documenter

makedocs(;
    modules=[SimLynx],
    authors="Trystan Kaes <trystanblkaes@gmail.com>, Anthony Dupont <>"anthony.dupont@ucdenver.edu>, Doug Williams <milton.williams@ucdenver.edu>",
    repo="https://github.com/LynxUCD/SimLynx.jl/blob/{commit}{path}#L{line}",
    sitename="SimLynx.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://LynxUCD.github.io/SimLynx.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/LynxUCD/SimLynx.jl",
)
