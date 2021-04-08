@testset "rendezvous.jl" begin

    # @testset "experiment" begin

        @process lock() begin
            while true
                @accept caller lock(i::Integer) begin
                    println("locked for p1($i)")
                end
                @accept caller unlock()
            end
        end

        the_lock = Nothing

        @process p1(i::Integer) begin
            println("$(current_time()): Process p1($i) started")
            @send the_lock lock(i)
            println("$(current_time()): Process p1($i) acquired lock")
            work(rand(Uniform(1.0, 10.0)))
            println("$(current_time()): Process p1($i) released lock")
            @send the_lock unlock()
            println("$(current_time()): Process p1($i) ended")
        end

        @simulation begin
            # current_trace!(true)
            global the_lock = @schedule now lock()
            for i = 1:10
                @schedule at rand(0:10) p1(i)
            end
            start_simulation()
        end
    # end
    # @testset "experiment" begin

    #     function Hello end

    #     @process MessageCenter() begin
    #         while true
    #             @accept caller Hello(s::String) begin
    #                 println(s)
    #             end
    #         end
    #     end

    #     message_center = Nothing

    #     @process p(i::Integer) begin
    #         @send message_center Hello("Hello from $i !")
    #     end

    #     @simulation begin
    #         global message_center = @schedule now MessageCenter()
    #         for i = 1:10
    #             @schedule at rand(1.0:10.0) p(i)
    #         end
    #         start_simulation()
    #     end
    # end
end
