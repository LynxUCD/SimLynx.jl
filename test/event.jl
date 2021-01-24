@testset "event.jl" begin

    @event test_process() begin
        return "We did it!"
    end

    @test test_process().name == "test_process()"
    @test test_process().proc() == "We did it!"

    @testset "Event Errors" begin
        try
            include("resources/event/sig_error.jl")
        catch e
            @test e.error.error == ArgumentError("the first argument must be a signature, given foo")
        end

        try
            include("resources/event/body_error.jl")
        catch e # XXX: this isn't failing and it should
            @show e.error.error == ArgumentError("the second argument must be a body, given :notabody")
        end

    end

end
