@testset "process.jl" begin

    @process helloWorld() begin
        return "Goodbye world"
    end

    @test helloWorld().name == "helloWorld()"
    # Still need to test out the Task attribute and all the other ones, although some will be null

    @testset "Process Sig Error" begin
        try
            eval(:(@process 4 :4))  # first arg is wrong
        catch e
            @test typeof(e.error) === ArgumentError
        end

    end

    # This testset isn't running... why?
    @testset "Process Body Error" begin
        try
            eval(:(@process helloWorld() 4))    # missing begin/end
        catch
            @test typeof(e.error) === ArgumentError
        end
    end
end
