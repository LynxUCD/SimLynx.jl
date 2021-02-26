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
        stateList = []
        tellers = nothing

        "The ith customer into the system."
        @process control(i::Integer) begin
            @with_resource tellers begin
                add!(proc_list, current_process())

                test1 = testProcess(1)
                @schedule now test1 # will be delayed due to control taking the resource
                @schedule now doNothing(1)  # will suspend itself
                @schedule now testProcess(2)
                @schedule now rudeProcess(1)
                work(rand(2:4)) # takes up the only resource and gets set to :working
                # use the variable that stored the process to access testProcess(1) and push it's delayed state in the state list
                push!(stateList, current_process().state)   # :active
                push!(stateList, test1.state)   # delayed

                remove!(proc_list, current_process())
            end
            wait(8) # wait for other processes to happen
            push!(stateList, first(proc_list).state)
            notice = first(proc_list).notice
            notice.time = current_time() + 1.0
            resume(first(proc_list), notice)
        end

        @process testProcess(i::Integer) begin
            if current_process().name == "testProcess(1)"
                push!(stateList, controlProcess.state)  # pushing :working state
                push!(stateList, current_process()) #push process which will mutate to terminated eventually
            end
            @with_resource tellers begin
                add!(proc_list, current_process())
                work(rand(1:4))
                remove!(proc_list, current_process())
            end
        end

        @process rudeProcess(i::Integer) begin
            wait(4)
            #@with_resource tellers begin
            other_proc = first(proc_list)   # <- this needs to be a in working at this point to be able to be interrupted
            notice = interrupt(other_proc)
            notice.time = current_time() + 2.0
            work(2)
            # make sure to check for interrupted in other_proc before resuming
            push!(stateList, other_proc.state)
            resume(other_proc, notice)
            #end
        end

        @process doNothing(i::Integer) begin
            @with_resource tellers begin
                add!(proc_list, current_process())
                suspend()
                work(rand(1:4))
            end
        end

        @simulation begin
            #current_trace!(true)
            tellers = Resource(1, "tellers")
            global proc_list = Queue{Process}()
            global controlProcess = @schedule now control(1)
            start_simulation()
            #println(stateList)
        end

        @test testProcess(5).state == :created
        @test stateList[1] == :working
        @test stateList[2].state == :terminated
        @test stateList[3] == :active
        @test stateList[4] == :delayed
        @test stateList[5] == :interrupted
        @test stateList[6] == :suspended
        
    end

    @testset "Process Sig Error" begin
        @test_throws ArgumentError @m_throw @process foo :bar
    end

end
