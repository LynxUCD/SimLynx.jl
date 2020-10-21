"""
A simple implementation of an event-based simulation. This program simulates a bank.
"""
using SimLynx

using Distributions: Exponential, Uniform
using Random

const N_TELLERS = 2
tellers = nothing

"Process to generate n customers arriving into the system."
@process generator(n::Integer) begin
    for i = 1:n
        work(rand(Exponential(4.0)))
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
        global tellers = Resource(N_TELLERS, "tellers")
        @schedule at 0.0 generator(n)
        start_simulation()
        print_stats(tellers.allocated, "Allocated Statistics")
        print_stats(tellers.queue_length, "Queue Length Statistics")
        plot_history(tellers.queue_length, "queue_length.png",
            "Queue Length History")
    end
end

run_simulation(100)
