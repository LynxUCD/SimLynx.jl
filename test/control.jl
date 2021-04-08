@testset "control.jl" begin

    @testset "Scheduling Symbols" begin
        got = Int64[]
        want = [1,2,3,4,5,6,7,8,9,10]

        @event test_process(i, _got) begin
            push!(_got, i)
        end

        @simulation begin
            # Future events
            @schedule at 0.0 test_process(4, got)
            @schedule at 0.0 test_process(5, got)
            @schedule at 0.5 test_process(7, got)
            @schedule at 2.0 test_process(9, got)
            @schedule at 1.0 test_process(8, got)
            @schedule in 0.0 test_process(6, got)
            @schedule in 2.0 test_process(10, got)
            # Now events
            @schedule now test_process(2, got)
            @schedule now test_process(3, got)
            @schedule immediate test_process(1, got)
            start_simulation()

            @test got == want # Tests complete functionality of control.jl
        end
    end

    @testset "schedule returns" begin
        testcases = [
            Dict(
                "notice" =>  :(@process test_process() begin
                                return true
                            end),
                "type" => Process
            ),
            Dict(
                "notice" => :(@event test_event() begin
                                return true
                            end),
                "type" => Event
            )
        ]

        for want in testcases
            got = @schedule now eval(want["notice"])()
            @test typeof(got) === eval(want["type"])
        end
    end

    @testset "schedule errors" begin
        @event test_process() begin true end

        @test_throws ArgumentError @m_throw @schedule nope test_process()
        @test_throws MethodError @m_throw @schedule now :nope
    end
end
