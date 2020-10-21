# example-4.jl
# Example nested simulation models with data collection

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
        avg_wait = Variable{Float64}(data=:tally, history=true)
        for i = 1:n₁
            @with_new_simulation begin
                global tellers = Resource(N_TELLERS, "tellers")
                @schedule at 0.0 generator(n₂)
                start_simulation()
                set!(avg_wait, mean(tellers.wait.stats))
            end
        end
        print_stats(avg_wait)
        plot_history(avg_wait, "avg-weight.png")
    end
end

@time run_simulation(10_000, 1_000)
