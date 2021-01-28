@testset "event.jl" begin

    @event test_event() begin
        return true
    end

    @test test_event().name == "test_event()"
    @test test_event().proc() === true
    @test typeof(test_event()) === Event

    @testset "Event Errors" begin
        err = nothing
        try
            include("resources/event/sig_error.jl")
        catch e
            err = e
        end

        @test typeof(err.error.error) === ArgumentError

    end


    @testset "Macro Side Effects" begin
        @event foo() 4

        @test foo().proc() === 4
    end


end
