# Test Scheduling

using SimLynx
SimLynx.greet()

@event test_process(i) begin
    println("$(current_time()): Event $i occurred")
end

function main()
    println("--- Test Scheduling ---")
    println("The events should execute in order.")
    @simulation begin
        # Future events
        @schedule at 0.0 test_process(4)
        @schedule at 0.0 test_process(5)
        @schedule at 0.5 test_process(7)
        @schedule at 2.0 test_process(9)
        @schedule at 1.0 test_process(8)
        @schedule in 0.0 test_process(6)
        @schedule in 2.0 test_process(10)
        # Now events
        @schedule now test_process(2)
        @schedule now test_process(3)
        @schedule immediate test_process(1)
        start_simulation()
    end
end

main()
