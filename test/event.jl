@testset "event.jl" begin

    @event test_process() begin
        return "We did it!"
    end

    @test test_process().name == "test_process()"
    @test test_process().proc() == "We did it!"
    @test typeof(test_process()) === Event

    @testset "Event Errors" begin
        try
            include("resources/event/sig_error.jl")
        catch e
            @test typeof(e.error.error) === ArgumentError
        end
    end


    @testset "Macro Side Effects" begin
        @event foo() 4

        @test foo().proc() === 4
    end


end
