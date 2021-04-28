# SimLynx.jl Repeatable Process-Based Discrete-Event Simulation Example

using SimLynx
SimLynx.greet()

using Distributions: Exponential, Uniform
using Random

const N_TELLERS = 2
const MEAN_INTERARRIVAL_TIME = 4.0
const MIN_SERVICE_TIME = 2.0
const MAX_SERVICE_TIME = 10.0

const GENERATOR_RNG = 1
const CUSTOMER_RNG = 2

tellers = nothing

"Process to generate n customers arriving into the system."
@process generator(n::Integer) begin
    rng = MersenneTwister(seed(GENERATOR_RNG))
    dist = Exponential(MEAN_INTERARRIVAL_TIME)
    for i = 1:n
        @schedule now customer(i)
        work(rand(rng, dist))
    end
end

"The ith customer into the system."
@process customer(i::Integer) begin
    rng = MersenneTwister(seed(CUSTOMER_RNG, i))
    dist = Uniform(MIN_SERVICE_TIME, MAX_SERVICE_TIME)
    @with_resource tellers begin
        work(rand(rng, dist))
    end
end

"Run the simulation for n customers."
function run_simulation(n::Integer)
    println("SimLynx.jl Repeatable Process-Based Discrete-Event Simulation Example")
    println("$N_TELLERS Teller, Single Queue Bank Model")
    println("  Inter-arrival time = Exponential($MEAN_INTERARRIVAL_TIME)")
    println("  Service time = Uniform($MIN_SERVICE_TIME, $MAX_SERVICE_TIME)")
    println("  Number of customers = $n")
    @simulation begin
        global tellers = Resource(N_TELLERS, "tellers")
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

run_simulation(100)
