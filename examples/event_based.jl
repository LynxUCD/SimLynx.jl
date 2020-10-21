# event-based.jl
# Example event-based simulation

using SimLynx

using Distributions
using Random

const N_TELLERS = 2
const N_CUSTOMERS = 10

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

@event generate(i::Integer) begin
    if i <= N_CUSTOMERS
        @schedule now arrival(Customer(i))
        @schedule in rand(Distributions.Exponential(4.0)) generate(i + 1)
    end
end

@event arrival(customer::Customer) begin
    println("$(current_time()): $customer arrives")
    teller = available_teller()
    if isnothing(teller)
        enqueue!(teller_queue, customer)
    else
        @schedule now service(teller, customer)
    end
end

@event service(teller::Teller, customer::Customer) begin
    println("$(current_time()): $teller starts servicing $customer")
    teller.serving = customer
    @schedule in rand(Distributions.Uniform(2.0, 10.0)) departure(teller, customer)
end

@event departure(teller::Teller, customer::Customer) begin
    println("$(current_time()): $teller finishes servicing $customer")
    if isempty(teller_queue)
        teller.serving = nothing
    else
        next_customer = dequeue!(teller_queue)
        teller.serving = next_customer
        @schedule now service(teller, customer)
    end
end

function main()
    @with_new_simulation begin
        global tellers = [Teller(i) for i = 1:N_TELLERS]
        global teller_queue = FifoQueue{Customer}()
        @schedule at 0.0 generate(1)
        println("Hello world?")
        start_simulation()
        print_stats(teller_queue.n)
        plot_history(teller_queue.n, "event_based.png")
    end
end

main()
