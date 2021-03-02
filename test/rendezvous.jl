@testset "rendezvous.jl" begin
    @testset "experiment" begin

        # @process lock() begin
        #     while true
        #         @accept caller lock()
        #         @accept caller unlock()
        #     end
        # end

        # the_lock = Nothing

        # @process p1(i::Integer) begin
        #     println("$(current_time()): Process p1($i) started")
        #     @send the_lock lock()
        #     println("$(current_time()): Process p1($i) acquired lock")
        #     work(10)
        #     println("$(current_time()): Process p1($i) released lock")
        #     @send the_lock unlock()
        #     println("$(current_time()): Process p1($i) ended")
        # end

        # @simulation begin
        #     current_trace!(true)
        #     global the_lock = @schedule now lock()
        #     for i = 1:10
        #         @schedule at rand(1:10) p1(i)
        #     end
        #     start_simulation()
        # end


    end
end
