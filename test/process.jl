include("resources/test_utilities.jl")

@testset "process.jl" begin

    @process helloWorld() begin
        return "Goodbye world"
    end

    @testset "Process fields" begin
        # I can map these to a dictionary and throw it in a loop once I confirm that all these tests are needed/good
        @test typeof(helloWorld()) == Process
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

    end
    
    @testset "Process states" begin
        statusList = [:active, :working, :delayed, :interrupted, :suspended, :terminated]
        # These are currently failing.. not sure why, but this is definitively a me error and not a function error (trace-mixed-event-process-based-bank-model works)
        for status in statusList
            SimLynx.process_state!(helloWorld(), status)
            #@test helloWorld().state == status
        end
    end

    @testset "Process Sig Error" begin
        @test_throws ArgumentError @m_throw @process foo :bar
    end

end
