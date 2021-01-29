using Test, SimLynx
const dir = joinpath(dirname(pathof(SimLynx)), "..", "test")


@testset "SimLynx" begin
    include("resources/test_utilities.jl")

    for f in ["activity.jl",
              "control.jl",
              "event.jl",
              "history.jl",
              "notice.jl",
              "process.jl",
              "queue.jl",
              "rendezvous.jl",
              "resource.jl",
              "SimLynx.jl",
              "simulation.jl",
              "statistics.jl",
              "variable.jl"]
        file = joinpath(dir, f)
        println("Running $file tests...")
        if isfile(file)
            include(file)
        else
            @show readdir(dirname(file))
        end
    end
end
