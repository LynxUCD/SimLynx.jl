abstract type Queue{T<:Any}
end

mutable struct FifoQueue{T<:Any} <: Queue{T}
    n::Variable{Int64}
    data::Array{T,1}
    FifoQueue{T}() where {T<:Any} =
        new(Variable{Int64}(0, history=true),
        Array{T,1}(undef,0))
end

function enqueue!(queue::FifoQueue{T}, item::T) where {T<:Any}
    increment!(queue.n, 1)
    push!(queue.data, item)
    return nothing
end

function dequeue!(queue::FifoQueue{T})::T where {T<:Any}
    decrement!(queue.n, 1)
    popfirst!(queue.data)
end

function Base.isempty(queue::FifoQueue)
    return length(queue.data) == 0
end

function first(queue::FifoQueue{T})::T where {T<:Any}
    return queue.data[1]
end

function last(queue::FifoQueue{T})::T where {T<:Any}
    return queue.data[end]
end

function remove(queue::FifoQueue{T}, item::T) where {T<:Any}
    ndx = findfirst(x -> x === item, queue.data)
    decrement!(queue.n, 1)
    deleteat!(queue.data, ndx)
    return nothing
end

mutable struct LifoQueue{T<:Any}
    n::Variable{Int64}
    data::Array{T,1}
end

function enqueue!(queue::LifoQueue{T}, item::T) where {T<:Any}
    increment!(queue.n, 1)
    push!(queue.data, item)
    return nothing
end

function dequeue!(queue::LifoQueue{T})::T where {T<:Any}
    decrement!(queue.n, 1)
    pop!(queue.data)
end

#=
mutable struct PriorityQueue{T<:Any}
    n::Variable{Int64}
    data::Array{T,1}
end
=#
