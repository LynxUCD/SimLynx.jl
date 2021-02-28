@testset "queue.jl" begin
    queue = Queue{Int64}()
    enqueue!(queue, 2)
    add!(queue, 3)
    add!(queue, 2)
    @test first(queue) == 2
    remove!(queue, 2)
    @test length(queue) == 2
    @test last(queue) == 2
    dequeue!(queue)
    @test isempty(queue) == false
    dequeue!(queue)
    @test isempty(queue) == true

    lifo = LifoQueue{Int64}()

    enqueue!(lifo, 2)
    @test lifo.n.value == 1
    @test lifo.data[1] == 2
    dequeue!(lifo)
    @test lifo.n.value == 0

end
