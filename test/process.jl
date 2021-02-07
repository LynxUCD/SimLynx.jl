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
        # TODO: 
           # use a state list instead
           # use two processes, control and test process
            # control can look at the test process state and lock the state of the process
            # and release to check if the test process is set properly to :create, :delayed, etc...

        stateList = []
        proc_list = []
        tellers = nothing

        "The ith customer into the system."
        @process control(i::Integer) begin
            @with_resource tellers begin
                # current process in here is the control process... how to look at testProcess after scheduling?
                test1 = testProcess(1)
                test2 = testProcess(2)
                @schedule in 0.0 test1 # gets scheduled and will be delayed due to control taking the resource
                @schedule immediate test2   # control(1) should get interrupted
                work(rand(1:4)) # takes up the only resource

                # use the variable that stored the process to access testProcess(1) and push it's delayed state in the state list
                push!(stateList, current_process().state)   # :active
                push!(stateList, test1.state)   # delayed
            end
        end

        @process testProcess(i::Integer) begin
            @with_resource tellers begin
                work(rand(1:4))
                push!(proc_list, current_process()) # if I push the state, it will remain as :active and we'll never see it being updated to terminated
            end
        end


        @simulation begin
            current_trace!(true)
            tellers = Resource(1, "tellers")
            @schedule now control(1)
            start_simulation()
            println(stateList)
            println(proc_list)
        end

        @test stateList[1] == :active
        @test stateList[2] == :delayed
        @test proc_list[1].state == :terminated

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
