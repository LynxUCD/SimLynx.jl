# SimLynx.jl Event-Based Discrete-Event Simulation Example

using SimLynx
SimLynx.greet()

using Distributions: Exponential, Uniform
using Random

const N_TELLERS = 2
const MEAN_INTERARRIVAL_TIME = 4.0
const MIN_SERVICE_TIME = 2.0
const MAX_SERVICE_TIME = 10.0

struct Customer
    id::Int64
    Customer(id::Int64) = new(id)
end

Base.show(io::IO, customer::Customer) =
    print(io, "Customer($(customer.id))")

mutable struct Teller
    id::Int64
    serving::Union{Customer, Nothing}
    Teller(id::Int64) = new(id, nothing)
end

Base.show(io::IO, teller::Teller) =
    print(io, "Teller($(teller.id))")

tellers = nothing
teller_queue = nothing

function available_teller()::Union{Teller, Nothing}
    for teller in tellers
        if isnothing(teller.serving)
            return teller
        end
    end
    return nothing
end

generator_dist = Exponential(MEAN_INTERARRIVAL_TIME)

@event generate(i::Integer, n::Integer) begin
    @schedule now arrival(Customer(i))
    if i < n
        @schedule in rand(generator_dist) generate(i + 1, n)
    end
end

@event arrival(customer::Customer) begin
    teller = available_teller()
    if isnothing(teller)
        enqueue!(teller_queue, customer)
    else
        @schedule now service(teller, customer)
    end
end

@event service(teller::Teller, customer::Customer) begin
    dist = Uniform(MIN_SERVICE_TIME, MAX_SERVICE_TIME)
    teller.serving = customer
    @schedule in rand(dist) departure(teller, customer)
end

@event departure(teller::Teller, customer::Customer) begin
    if isempty(teller_queue)
        teller.serving = nothing
    else
        next_customer = dequeue!(teller_queue)
        teller.serving = next_customer
        @schedule now service(teller, next_customer)
    end
end

function run_simulation(n::Integer)
    @assert n > 0
    println("SimLynx.jl Event-Based Discrete-Event Simulation Example")
    println("$N_TELLERS Teller, Single Queue Bank Model")
    println("  Inter-arrival time = Exponential($MEAN_INTERARRIVAL_TIME)")
    println("  Service time = Uniform($MIN_SERVICE_TIME, $MAX_SERVICE_TIME)")
    println("  Number of customers = $n")
    @simulation begin
        global tellers = [Teller(i) for i = 1:N_TELLERS]
        global teller_queue = FifoQueue{Customer}()
        current_trace!(true)
        @schedule at 0.0 generate(1, n)
        start_simulation()
        print_stats(teller_queue.n, title="Teller Queue Length Statistics")
        plot_history(teller_queue.n, title="Teller Queue Length History")
    end
end

run_simulation(10)
