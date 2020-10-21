# example-5.jl
# Example open-loop simulation model

#=
This is an example on an open-loop simulation model. This example gathers
statistics on the maximum number of tellers needed for no customer waiting.
=#

using SimLynx

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
    @with_resource tellers begin
        work(rand(Uniform(2.0, 10.0)))
    end
end

"Run the simulation for n customers."
function run_simulation(n₁::Integer, n₂::Integer)
    @with_new_simulation begin
        max_tellers = Variable{Int64}(data=:tally, history=true)
        for i = 1:n₁
            @with_new_simulation begin
                global tellers = Resource("tellers")
                @schedule at 0.0 generator(n₂)
                start_simulation()
                sync!(tellers.allocated)
                set!(max_tellers, tellers.allocated.stats.max)
            end
        end
        print_stats(max_tellers)
        plot_history(max_tellers, "max_tellers.png")
    end
end

@time run_simulation(10_000, 1_000)
