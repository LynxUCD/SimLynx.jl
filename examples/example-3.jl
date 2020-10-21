# example-3.jl
# Example nested simulation models

#=
This example demonstrates nested simulations, which is used to run multiple
simulation runs to gather statistics (e.g., distributions) across the runs. This
example just executes the multiple runs without gathering additional data.
=#

include("../src/simlynx.jl")

using Distributions: Exponential, Uniform
using Random

const N_TELLERS = 2
tellers = nothing

"Process to generate n customers arriving into the system."
@process generator(n::Integer) begin
    dist = Exponential(4.0)
    for i = 1:n
        work(rand(dist))
        @schedule now customer(i)
    end
end

"The ith customer into the system."
@process customer(i::Integer) begin
    dist = Uniform(2.0, 10.0)
    @with_resource tellers begin
        work(rand(dist))
    end
end

"Run the simulation for n customers."
function run_simulation(n::Integer)
    @with_new_simulation begin
        for i = 1:10
            @with_new_simulation begin
                global tellers = Resource(N_TELLERS, "tellers")
                @schedule at 0.0 generator(n)
                start_simulation()
                print_stats(tellers.allocated, "Allocated Statistics")
                print_stats(tellers.queue_length, "Queue Length Statistics")
                plot_history(tellers.queue_length, "queue_length.png",
                    "Queue Length History")
                print_stats(tellers.wait, "Queue Wait Statistics")
            end
        end
    end
end

run_simulation(1_000)
