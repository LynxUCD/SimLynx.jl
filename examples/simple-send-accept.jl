# Simple Send and Accept

using SimLynx
SimLynx.greet()

using Distributions: Exponential, Uniform
using Random

@process lock() begin
    while true
        @accept caller lock()
        @accept caller unlock()
    end
end

the_lock = Nothing

@process p1(i::Integer) begin
    println("$(current_time()): Process p1($i) started")
    @send the_lock lock()
    println("$(current_time()): Process p1($i) acquired lock")
    work(rand(Uniform(1.0, 10.0)))
    println("$(current_time()): Process p1($i) released lock")
    @send the_lock unlock()
    println("$(current_time()): Process p1($i) ended")
end

function run_simulation(n::Integer)
    @simulation begin
        # current_trace!(true)
        global the_lock = @schedule now lock()
        for i = 1:n
            @schedule at rand(Uniform(0.0, 10.0)) p1(i)
        end
        start_simulation()
    end
end

run_simulation(10)
