@testset "event.jl" begin

    @event test_event() begin
        return true
    end

    @test test_event().name == "test_event()"
    @test test_event().proc() === true
    @test typeof(test_event()) === Event

    @testset "Event Errors" begin
        @test_throws ArgumentError @m_throw @event foo begin true end
    end


    @testset "Macro Side Effects" begin
        @event foo() 4

        @test foo().proc() === 4
    end
end
