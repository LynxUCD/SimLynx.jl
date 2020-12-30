# example-4.jl
# Example nested simulation models with data collection

using SimLynx
SimLynx.greet()

using Distributions: Exponential, Uniform
using Random

const N_TELLERS = 2
const MEAN_INTERARRIVAL_TIME = 4.0
const MIN_SERVICE_TIME = 2.0
const MAX_SERVICE_TIME = 10.0

run_number = 0
const GENERATOR_RNG = 1
const CUSTOMER_RNG = 2

"Process to generate n customers arriving into the system."
@process generator(n::Integer) begin
    rng = MersenneTwister(seed(run_number, GENERATOR_RNG))
    dist = Exponential(MEAN_INTERARRIVAL_TIME)
    for i = 1:n
        work(rand(rng, dist))
        @schedule now customer(i)
    end
end

"The ith customer into the system."
@process customer(i::Integer) begin
    rng = MersenneTwister(seed(run_number, CUSTOMER_RNG, i))
    dist = Uniform(MIN_SERVICE_TIME, MAX_SERVICE_TIME)
    @with_resource tellers begin
        work(rand(rng, dist))
    end
end

"Run the simulation for n customers."
function run_simulation(n1::Integer, n2::Integer)
    println("SimLynx Repeatable Open Loop Processing Example")
    println("Number of runs = $n1, number of customers = $n2")
    println("Single Queue, $N_TELLERS Teller Bank Model")
    @simulation begin
        avg_wait = Variable{Float64}(data=:tally, history=true)
        for i = 1:n1
            global run_number = i
            @simulation begin
                global tellers = Resource(N_TELLERS, "tellers")
                @schedule at 0.0 generator(n2)
                start_simulation()
                avg_wait.value = tellers.wait.stats.mean
            end
        end
        print_stats(avg_wait, title="Average Wait Statistics")
        plot_history(avg_wait, title="Average Wait History")
    end
end

run_simulation(10_000, 100)
