# SimLynx.jl Process-Based Discrete-Event Simulation Example

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
SimLynx.greet()

using Distributions: Exponential, Uniform
using Random

const N_TELLERS = 2
const MEAN_INTERARRIVAL_TIME = 4.0
const MIN_SERVICE_TIME = 2.0
const MAX_SERVICE_TIME = 10.0

tellers = nothing

"Process to generate n customers arriving into the system."
@process generator(n::Integer) begin
    dist = Exponential(MEAN_INTERARRIVAL_TIME)
    for i = 1:n
        @schedule now customer(i)
        if i < n
            work(rand(dist))
        end
    end
end

"The ith customer into the system."
@process customer(i::Integer) begin
    dist = Uniform(MIN_SERVICE_TIME, MAX_SERVICE_TIME)
    @with_resource tellers begin
        work(rand(dist))
    end
end

"Run the simulation for n customers."
function run_simulation(n::Integer)
    println("SimLynx.jl Process-Based Discrete-Event Simulation Example")
    println("$N_TELLERS Teller, Single Queue Bank Model")
    println("  Inter-arrival time = Exponential($MEAN_INTERARRIVAL_TIME)")
    println("  Service time = Uniform($MIN_SERVICE_TIME, $MAX_SERVICE_TIME)")
    println("  Number of customers = $n")
    @simulation begin
        global tellers = Resource(N_TELLERS, "tellers")
        current_trace!(true)
        @schedule at 0.0 generator(n)
        start_simulation()
        println("--- Simulation results after $(current_time()) minutes ---")
        print_stats(tellers.allocated, title="Teller Allocation Statistics")
        print_stats(tellers.queue_length, title="Teller Queue Length Statistics")
        plot_history(tellers.queue_length, title="Teller Queue Length History")
        print_stats(tellers.wait, title="Teller Queue Wait Time Statistics")
        plot_history(tellers.wait, title="Teller Queue Wait Time History")
    end
end

run_simulation(10)
