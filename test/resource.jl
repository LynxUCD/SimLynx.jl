@testset "resource.jl" begin
    # Note to self:
        # -release is being tested by checking that the available unit goes back up (increments) after a process finishes working which calls deallocate
        # -request is tested in the @with_resource macro which also allocates resources

    shared = nothing
    resourceList = []
    @process control() begin
        @with_resource shared begin # control takes the first available resource from shared
            push!(resourceList, shared.available.value) 
            @schedule now resourceConsumer()
            work(2)
        end
        # control has released its resource, went from 0 available to 1
        push!(resourceList, shared.available.value)
    end 
    
    @process resourceConsumer() begin
        @with_resource shared begin # resourceConsumer takes the second available resource from shared
            push!(resourceList, shared.available.value)
            work(4)
        end
        # resourceConsumer has released its resource, went from 1 available to 2
        push!(resourceList, shared.available.value)
    end

    @simulation begin
        shared = Resource(2, "")
        push!(resourceList, shared.available.value)
        println("Amount of resources available: ", shared.available.value)
        @schedule now control()
        start_simulation()
    end

    want = [2,1,0,1,2]
    @test resourceList == want

end
