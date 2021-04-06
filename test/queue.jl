@testset "queue.jl" begin

    @testset "fifo" begin
        queue = Queue{Int64}()
        @test enqueue!(queue, 2) == [2]
        @test enqueue!(queue, 3) == [2, 3]
        @test add!(queue, 4) == [2, 3, 4]
        @test first(queue) == 2
        @test last(queue) == 4
        @test length(queue) == 3
        @test dequeue!(queue) == 2
        @test dequeue!(queue) == 3
        @test dequeue!(queue) == 4
        @test isempty(queue) == true
    end

    @testset "lifo" begin
        lifo = LifoQueue{Int64}()
        @test enqueue!(lifo, 2) == [2]
        @test enqueue!(lifo, 3) == [2, 3]
        @test first(lifo) == 2
        @test last(lifo) == 3
        @test length(lifo) == 2
        @test dequeue!(lifo) == 3
        @test dequeue!(lifo) == 2
        @test isempty(lifo) == true
    end

end
