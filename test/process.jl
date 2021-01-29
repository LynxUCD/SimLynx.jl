@testset "process.jl" begin

    @process helloWorld() begin
        return "Goodbye world"
    end

    # Is there a better way to test out all of these fields?
    @test helloWorld().name == "helloWorld()"
    @test helloWorld().state == :created
    @test helloWorld().task.state == :runnable  #double check if this is enough, we're just checking that we created a task and it's runnable
    @test typeof(helloWorld().notice.element) == Process    #the element of our notice should be a Process
    @test typeof(helloWorld().queue) == Array{SimLynx.AbstractMessage,1}
    
    # do we prefer one over the other? Are both needed?
    @test helloWorld().acceptors == SimLynx.Acceptor[]
    @test typeof(helloWorld().acceptors) == Array{SimLynx.Acceptor,1}

    @test helloWorld().response === nothing
    @test helloWorld().storage == IdDict{Symbol, Any}()
    #println(typeof(helloWorld().queue))

    @schedule now helloWorld()
    println(helloWorld().state)
    

    @testset "Process Sig Error" begin
        error = nothing
        try
            include("resources/process/argument_error.jl")
        catch e
            # insert function here to unwrap the error
            error = e.error.error
        end
        @test typeof(error) === ArgumentError
    end

    # Currently can't throw a body error
    # @testset "Process Body Error" begin
    #     try
    #         eval(:(@process helloWorld() 4))    # missing begin/end
    #     catch
    #         @test typeof(e.error) === ArgumentError
    #     end
    # end
end
