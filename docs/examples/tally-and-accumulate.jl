"""
Example usage of the test and accumulate functionality of SimLynx
"""
using SimLynx

tallied = nothing
accumulated = nothing

@process test_process(value_durations) begin
    for (value, duration) in value_durations
        set!(tallied, value)
        set!(accumulated, value)
        work(duration)
    end
end

function main(value_durations)
    @with_new_simulation begin
        global tallied = Variable{Int64}(data=:tally, history=true)
        global accumulated = Variable{Int64}(0, history=true)
        @schedule at 0.0 test_process(value_durations)
        start_simulation()
        println("--- Test Tally and Accumulate ---")
        println("--- Tally ---")
        println("N    = $(tallied.stats.n)")
        println("Sum  = $(tallied.stats.sum)")
        println("Mean = $(mean(tallied.stats))")
        plot_history(tallied, "tallied.png", "Tallied History")
        println("--- Accumulate ---")
        sync!(accumulated) # Retrieving slots does not sync
        println("N    = $(accumulated.stats.n)")
        println("Sum  = $(accumulated.stats.sum)")
        println("Mean = $(mean(accumulated.stats))")
        plot_history(accumulated, "accumulated.png", "Accumulated History")
    end
end

main([(1, 2.0), (2, 1.0), (3, 2.0), (4, 3.0)])
