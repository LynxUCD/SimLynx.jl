# mixed-event-process-based-bank-model.jl
# SimLynx.jl Mixed Event and Process Based Simulation Model

using SimLynx
SimLynx.greet()

using Distributions: Exponential, Uniform
using Random

const N_TELLERS = 2
const MEAN_INTERARRIVAL_TIME = 4.0
const MIN_SERVICE_TIME = 2.0
const MAX_SERVICE_TIME = 10.0

tellers = nothing

generator_dist = Exponential(MEAN_INTERARRIVAL_TIME)

"Generate the ith customer and schedule the next arrival."
@event generate(i:: Integer, n::Integer) begin
    @schedule now customer(i)
    if i < n
        @schedule in rand(generator_dist) generate(i + 1, n)
    end
end

"The ith customer into the system."
@process customer(i::Integer) begin
    dist = Uniform(MIN_SERVICE_TIME, MAX_SERVICE_TIME)
    @with_resource tellers begin
        work(rand(dist))
    end
end

"Run the simulation."
function run_simulation(n::Integer)
    @assert n > 0
    println("SimLynx Mixed Event and Process Based Simulation Example")
    println("$N_TELLERS Teller, Single Queue Bank Model")
    println("  Inter-arrival time = Exponential($MEAN_INTERARRIVAL_TIME)")
    println("  Service time = Uniform($MIN_SERVICE_TIME, $MAX_SERVICE_TIME)")
    println("  Number of customers = $n")
    @simulation begin
        current_trace!(true)
        global tellers = Resource(N_TELLERS, "tellers")
        @schedule at 0.0 generate(1, n)
        start_simulation()
        print_stats(tellers.allocated, title="Allocated Statistics")
        print_stats(tellers.queue_length, title="Queue Length Statistics")
        plot_history(tellers.queue_length, title="Queue Length History")
    end
end

run_simulation(10)
