@testset "variable.jl" begin
    @testset ":tallied" begin
        global tallied = Variable{Int64}(data=:tally, history=true)

        update_list = []
        final_value = nothing

        @process test_process(value_durations) begin
            for (value, duration) in value_durations
                tallied.value = final_value = value
                push!(update_list, tallied.prev_update)
                work(duration)
            end
        end

        @simulation begin
            value_durations = [(1, 2.0), (2, 1.0), (3, 2.0), (4, 3.0)]

            @schedule now test_process(value_durations)
            @schedule at 1.0 test_process(value_durations)
            @schedule in 3.0 test_process(value_durations)

            start_simulation()
        end


        want = [0.0, 1.0, 2.0, 3.0, 3.0, 3.0, 4.0, 5.0, 5.0, 6.0, 6.0, 8.0]
        @test update_list == want

        decrement!(tallied, 1)
        @test tallied.value == final_value - 1

        increment!(tallied, 1)
        @test tallied.value == final_value

        @test typeof(tallied.history) == SimLynx.TalliedHistory{Int64}
        @test typeof(tallied.stats) == SimLynx.TalliedStats{Int64}



    end

    @testset ":accumulate" begin
        global accumulated = Variable{Int64}(0, history=true)

        update_list = []
        final_value = nothing

        @process test_process(value_durations) begin
            for (value, duration) in value_durations
                accumulated.value = final_value = value
                push!(update_list, accumulated.prev_update)
                work(duration)
            end
        end

        @simulation begin
            value_durations = [(1, 2.0), (2, 1.0), (3, 2.0), (4, 3.0)]

            @schedule now test_process(value_durations)
            @schedule at 1.0 test_process(value_durations)
            @schedule in 3.0 test_process(value_durations)

            start_simulation()
        end


        want = [0.0, 1.0, 2.0, 3.0, 3.0, 3.0, 4.0, 5.0, 5.0, 6.0, 6.0, 8.0]
        @test update_list == want

        decrement!(accumulated, 1)
        @test accumulated.value == final_value - 1

        increment!(accumulated, 1)
        @test accumulated.value == final_value

        @test typeof(accumulated.history) == SimLynx.AccumulatedHistory{Int64}
        @test typeof(accumulated.stats) == SimLynx.AccumulatedStats{Int64}
    end
end
