@testset "process.jl" begin

    @testset "Process fields" begin
        @process helloWorld() begin
            return "Goodbye world"
        end

        @test typeof(helloWorld()) == Process
        @test helloWorld().name == "helloWorld()"
        @test helloWorld().state == :created
        @test helloWorld().task.state == :runnable
        @test typeof(helloWorld().notice.element) == Process
        @test typeof(helloWorld().queue) == Array{SimLynx.AbstractMessage,1}
        @test helloWorld().acceptors == SimLynx.Acceptor[]
        @test helloWorld().response === nothing
        @test helloWorld().storage == IdDict{Symbol, Any}()
    end

    @testset "discrete process states" begin
        stateList = []
        shared = nothing

        @process control() begin
            @with_resource shared begin
                add!(proc_list, current_process())

                delayedProcess = testProcess(1)
                @schedule now delayedProcess # due to control() taking resource
                @schedule now suspendProcess()
                @schedule now testProcess(2)
                @schedule now interruptProcess()
                work(3)

                # :active
                push!(stateList, current_process().state)

                # :delayed
                push!(stateList, delayedProcess.state)

                remove!(proc_list, current_process())
            end

            wait(8) # XXX: make this number precise

            # :suspended
            push!(stateList, first(proc_list).state)

            notice = first(proc_list).notice
            notice.time = current_time() + 1.0
            resume(first(proc_list), notice)
        end

        @process testProcess(i::Integer) begin
            if current_process().name == "testProcess(1)"

                # :working
                push!(stateList, controlProcess.state)

                # current_process()'s state will mutate to :terminated
                push!(stateList, current_process())
            end
            @with_resource shared begin
                add!(proc_list, current_process())
                work(3)
                remove!(proc_list, current_process())
            end
        end

        @process interruptProcess() begin
            wait(4)
            other_proc = first(proc_list)
            notice = interrupt(other_proc)
            notice.time = current_time() + 2.0

            work(2)
            push!(stateList, other_proc.state)
            resume(other_proc, notice)
        end

        @process suspendProcess() begin
            @with_resource shared begin
                add!(proc_list, current_process())
                suspend()
            end
        end

        @simulation begin
            shared = Resource(1, "")
            global proc_list = Queue{Process}()
            global controlProcess = @schedule now control()
            start_simulation()
        end

        # :terminated
        stateList[2] = stateList[2].state

        # :created
        push!(stateList, testProcess(0).state)

        @test stateList[1] == :working
        @test stateList[2] == :terminated
        @test stateList[3] == :active
        @test stateList[4] == :delayed
        @test stateList[5] == :interrupted
        @test stateList[6] == :suspended
        @test stateList[7] == :created

    end

    @testset "Process Sig Error" begin
        @test_throws ArgumentError @m_throw @process foo :bar
    end

end
