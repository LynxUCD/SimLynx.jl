using SimLynx
using Documenter

"""
Loops through the files in the examples folder and adds them (with any header comments) to the examples.md
markdown file.
"""
function generateExamples()
    f = open(joinpath(@__DIR__, "src/examples.md"), "w")
    write(
        f,
        "```@meta
    # NOTE this file is autogenerated, do not edit examples.md directly. To make an example, upload the .jl file to the examples folder. Header comments may be included at the top of the file using \"\"\" syntax
``` ",
    )
    write(f, "\n")
    write(f, "# Examples")
    write(
        f,
        "\nBelow are some useful examples to give you an idea of how this package can be leveraged. The code for these examples can also be found on Github
 in the `docs/examples` folder.",
    )
    write(f, "\n")
    for (root, dirs, files) in walkdir(joinpath(@__DIR__, "examples"))

        for file in files
            println(file)
            #extract title from example
            write(f, "\n")
            title = file
            title = replace(title, "_" => " ")
            title = replace(title, ".jl" => "")
            title = titlecase(title)
            title = "## " * title * "\n"
            write(f, title)
            #open each file and read contents
            opened = open(joinpath(@__DIR__, "examples/") * file)
            lines = readlines(opened, keep = true)
            index = 1
            #find doc string intro if exists
            if "\"\"\"\n" in lines
                index = findall(isequal("\"\"\"\n"), lines)[2]
                print(index)
                for i = 2:index-1
                    write(f, lines[i])
                end
                lines = lines[index+1:end]
            end

            write(f, "```julia")
            write(f, "\n")
            for line in lines
                write(f, line)
            end
            write(f, "\n")
            write(f, "```")
            close(opened)
        end
    end
    close(f)
end

generateExamples()

makedocs(;
    modules=[SimLynx],
    authors="Trystan Kaes <trystanblkaes@gmail.com>, Anthony Dupont <anthony.dupont@ucdenver.edu>, Doug Williams <milton.williams@ucdenver.edu>",
    repo="https://github.com/LynxUCD/SimLynx.jl/blob/{commit}{path}#L{line}",
    sitename="SimLynx.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://LynxUCD.github.io/SimLynx.jl",
        assets=String[],
    ),
    # devbranch = "master",
    # devurl = "dev",
    versions = ["stable" => "v^", "v#.#", "dev" => "dev"],
    pages=[
        "Home" => "index.md",
        "Discrete Simulations" => "discrete.md",
        "Continuous Simulations" => "continuous.md",
        "Examples" => "examples.md",
    ],
    push_preview=true,
)

deploydocs(;
    repo="github.com/LynxUCD/SimLynx.jl",
)
