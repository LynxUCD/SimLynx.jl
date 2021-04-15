# nested-simulations.jl
# SimLynx Nested Simulation Environments Example

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
        # We don't want to wait after the last customer, which could extend the
        # simulation time past the last customer leaving.
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
function run_simulation(n1::Integer, n2::Integer)
    @assert n1 > 0 && n2 > 0
    println("SimLynx Nested Simulation Environments Example")
    println("Number of runs = $n1, number of customers = $n2")
    println("Single Queue, $N_TELLERS Teller Bank Model")
    @simulation begin
        for i = 1:n1
            @simulation begin
                global tellers = Resource(N_TELLERS, "tellers")
                @schedule at 0.0 generator(n2)
                start_simulation()
                print_stats(tellers.allocated, title="Allocated Statistics")
                print_stats(tellers.queue_length, title="Queue Length Statistics")
                plot_history(tellers.queue_length, title="Queue Length History")
                print_stats(tellers.wait, title="Queue Wait Statistics")
            end
        end
    end
end

run_simulation(10, 100)
