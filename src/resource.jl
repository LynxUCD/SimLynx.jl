# resource.jl

# Resources
# This is a simple resource implementation that only allows unit allocations
# and deallocations.

"A (unit) allocation of the resource to a process."
struct Allocation
    time::Float64
    process::Process
end

"""
A sharable resource with a fixed number of allocatable units. The queue
maintains a list of processes waiting for the resource.
"""
mutable struct Resource
    name::String
    units::Int64
    available::Variable{Int64}
    allocated::Variable{Int64}
    queue_length::Variable{Int64}
    queue::Array{Allocation,1}
    wait::Variable{Float64}
    function Resource(units::Int64, name::String = "resource")
        new(name,
            units,
            Variable{Int64}(units),
            Variable{Int64}(0),
            Variable{Int64}(0, history=true),
            Array{Allocation,1}(undef, 0),
            Variable{Float64}(0.0, history=true))
    end
    function Resource(name::String = "resource")
        new(name,
            typemax(Int64),
            Variable{Int64}(typemax(Int64), data=:none),
            Variable{Int64}(0, history=true),
            Variable{Int64}(0, data=:none),
            Array{Allocation,1}(undef, 0),
            Variable{Float64}(0.0, data=:none))
    end
end

Base.show(io::IO, res::Resource) =
    print(io, "Resource $(res.name)")

"Allocate a unit of the resource to a process."
function allocate(resource::Resource, process::Process)
    if current_trace()
        @printf("%9.3f: %s acquired %s\n", current_time(),
                process, resource)
    end
    if resource.available.value < typemax(Int64)
        decrement!(resource.available, 1)
    end
    increment!(resource.allocated, 1)
end

"Deallocate a unit of the resource from a process."
function deallocate(resource::Resource, process::Process)
    if current_trace()
        @printf("%9.3f: %s released %s\n", current_time(),
                process, resource)
    end
    if resource.available.value < typemax(Int64)
        increment!(resource.available, 1)
    end
    decrement!(resource.allocated, 1)
end

"""
    request(resource::Resource)

Request a unit of the resource. If a unit of the resource is not available, then
queue the request.
"""
function request(resource::Resource)
    process = current_process()
    if resource.available.value > 0
        allocate(resource, process)
        resource.wait.value = 0.0
    else
        process_state!(current_simulation.notice.element, :delayed)
        push!(resource.queue, Allocation(current_time(), process))
        increment!(resource.queue_length, 1)
        yieldto(current_simulation.control_task)
    end
end

"""
    release(resource::Resource)

Release a unit of the resource. If there are process queued for the resource,
then allocate a unit of the resource to the longest waiting process. Note that
this works for unit allocations.
"""
function release(resource::Resource)
    process = current_notice().element
    deallocate(resource, process)
    if length(resource.queue) > 0
        queued = popfirst!(resource.queue)
        wait_time = current_time() - queued.time
        if wait_time > 0.0
            resource.wait.value = wait_time
        end
        decrement!(resource.queue_length, 1)
        allocate(resource, queued.process)
        @schedule now queued.process
    end
end

"""
    @with_resource resource begin
        body
    end

Wrap the body in a request / release pair for the resource.
"""
macro with_resource(resource, body)
    quote
        request($(esc(resource)))
        try
            $(esc(body))
        finally
            release($(esc(resource)))
        end
    end
end

