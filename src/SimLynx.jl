module SimLynx

using Plots; gr();
using Printf


include("statistics.jl")
include("histories.jl")

include("core.jl")

include("variables.jl")
include("queues.jl")
include("resources.jl")


end
