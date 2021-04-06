@testset "resource.jl" begin
    shared = nothing
    nested = nothing
    sharedList = []
    nestedList = []
    @process control() begin
        @with_resource shared begin
            @with_resource nested begin
                push!(nestedList, nested.available.value)
                @schedule now nestedConsumer()
                work(2)
            end
            push!(nestedList, nested.available.value)
            push!(sharedList, shared.available.value)
            @schedule now Consumer()
            work(2)
        end
        # control has released its resource, went from 0 available to 1
        push!(sharedList, shared.available.value)
        
        request(shared)
        push!(sharedList, shared.available.value)
        release(shared)
        push!(sharedList, shared.available.value)
        
        # extra release
        release(shared)
        
    end

    @process Consumer() begin
        @with_resource shared begin
            push!(sharedList, shared.available.value)
            work(4)
        end
        # Consumer has released its resource, went from 1 available to 2
        push!(sharedList, shared.available.value)
    end

    @process nestedConsumer() begin
        @with_resource nested begin
            push!(nestedList, nested.available.value)
            work(4)
        end
        push!(nestedList, nested.available.value)
    end

    @simulation begin
        shared = Resource(2, "")
        nested = Resource(2, "")
        push!(nestedList, nested.available.value)
        push!(sharedList, shared.available.value)
        @schedule now control()
        start_simulation()
    end

    wantShared = [2,1,0,1,0,1,2]
    wantNested = [2,1,0,1,2]
    @test sharedList == wantShared
    @test nestedList == wantNested

end
