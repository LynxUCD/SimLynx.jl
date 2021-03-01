@testset "history.jl" begin

        @testset ":tally" begin
            global tallied = Variable{Int64}(data=:tally, history=true)

            @process test_process(value_durations) begin
                for (value, duration) in value_durations
                    tallied.value = value
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

            want = [1, 1, 2, 1, 2, 3, 3, 2, 4, 4, 3, 4]
            @test tallied.history.data == want
        end

        @testset ":accumulate" begin
            # XXX: Shouldn't Variable{Int64}(data=:accumulate, history=true) work here?
            global accumulated = Variable{Int64}(0, history=true)

            @process test_process(value_durations) begin
                for (value, duration) in value_durations
                    accumulated.value = value
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

            want = [0, 1, 2, 1, 2, 3, 2, 4, 3, 4]
            @test accumulated.history.data == want

            want = [0.0, 2.0, 1.0, 0.0, 0.0, 2.0, 0.0, 1.0, 2.0, 3.0]
            @test accumulated.history.durations == want
        end
end
