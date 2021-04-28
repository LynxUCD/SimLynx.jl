# Tally and Accumulate

using SimLynx
SimLynx.greet()

tallied = nothing
accumulated = nothing

@process test_process(value_durations) begin
    for (value, duration) in value_durations
        tallied.value = value
        accumulated.value = value
        work(duration)
    end
end

function main(value_durations)
    println("--- Test Tally and Accumulate ---")
    @simulation begin
        # Create tallied and accumulated variables
        global tallied = Variable{Int64}(data=:tally, history=true)
        global accumulated = Variable{Int64}(0, history=true)
        # Schedule the test process and start the simulation
        @schedule at 0.0 test_process(value_durations)
        start_simulation()
        # Print and plot the tallied results
        println("--- Tally ---")
        print_stats(tallied, title="Tallied Statistics")
        plot_history(tallied, title="Tallied History")
        # Print and plot the accumulated results
        println("--- Accumulate ---")
        print_stats(accumulated, title="Accumulated Statistics")
        plot_history(accumulated, title="Accumulated History")
    end
end

main([(1, 2.0), (2, 1.0), (3, 2.0), (4, 3.0)])
