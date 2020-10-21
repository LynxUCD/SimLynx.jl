# example-1.jl
# Example Simulation Model

#=
This is a simple process-based discrete-event simulation of an N teller, single
queue bank.

There are two (2) processes:
    generator(n::Integer)
      Generates n arrivals into the system with exponentially distributed
      inter-arrival time with a mean of 4.0.
    customer(i::Integer)
      The process representing the ith customer in the system. Each customer
      acquires a teller and works a uniformly distributed time between 2.0 and
      10.0. It then releases the teller and exits.

There is a single resource, tellers, that represents the tellers in the bank.
The number if tellers is set by the N_TELLERS global variable.

Once the simulation runs, statistics are printed for the tellers allocation and
queue length as well as a plot of the queue length over time.
=#

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
