@testset "statistics.jl" begin
    @testset "TalliedStats" begin
        global tallied = Variable{Int64}(data=:tally, history=false)

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

        @test tallied.stats.min == 1
        @test tallied.stats.max == 4
        @test tallied.stats.sum == 30.0
        @test tallied.stats.mean == 2.5
        @test tallied.stats.variance == 1.25
        @test tallied.stats.stddev == 1.118033988749895
        @test tallied.stats.sum_squares == 90.0
    end

    @testset "AccumulatedStats" begin
        global tallied = Variable{Int64}(0, history=false)

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

        @test tallied.stats.min == 1
        @test tallied.stats.max == 4
        @test tallied.stats.sum == 32.0
        @test tallied.stats.mean == 2.909090909090909
        @test tallied.stats.variance == 1.1735537190082646
        @test tallied.stats.stddev == 1.083306844346635
        @test tallied.stats.sum_squares == 106.0
    end
end
