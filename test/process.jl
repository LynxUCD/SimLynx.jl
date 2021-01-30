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
        customerList = []
        tellers = nothing
        # I have removed Exponential and Uniform distribution for this test. Hopefully it's okay
        @event generate(i:: Integer, n::Integer) begin
            @schedule now customer(i)
            if i < n
                @schedule in rand(1:9) generate(i + 1, n)
                # push!(customerList, customer(i))
            end
        end

        "The ith customer into the system."
        @process customer(i::Integer) begin
            @with_resource tellers begin
                work(rand(1:4))
                #push!(customerList, customer(i))
            end
            #println("State of this customer: ", customer(i).state)
        end

        # @with_resource customer(1) begin
        #     return true
        # end

        # for i = 1:10
        #     println(customer(i))
        # end

        #everything is stuck under current_simulation so I cannot use things like @with_resource 
        #to trigger a request, to get a process_state! changed from created to active or delayed etc

        @simulation begin
            current_trace!(true)
            tellers = Resource(2, "tellers")
            @schedule at 0.0 generate(1, 10)
            start_simulation()
            println(customer(1).state)  # I would think the state of this would be terminated but it's still stuck at created
        end
        println(customer(1).state)  # even outside the simulation scope, the process is still set to :created

        # statusList = [:active, :working, :delayed, :interrupted, :suspended, :terminated]
        # # These are currently failing.. but I suspect it's because we don't export this function (hence why I have to SimLynx.something) 
        # # And possible helloWorld() is being updated in a different scope. SimLynx module vs Main module. So I can only test it through a simulation
        # # (trace-mixed-event-process-based-bank-model works)
        # for status in statusList
        #     SimLynx.process_state!(helloWorld(), status)
        #     helloWorld().task
        #     @test helloWorld().state == status
        # end
    end

    @testset "Process Sig Error" begin
        @test_throws ArgumentError @m_throw @process foo :bar
    end

end
