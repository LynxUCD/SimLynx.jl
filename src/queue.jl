import Base: length, isempty, first, last

abstract type AbstractQueue{T<:Any}
end

length(queue::AbstractQueue) = length(queue.data)
isempty(queue::AbstractQueue) = length(queue.data) == 0
first(queue::AbstractQueue) = queue.data[1]
last(queue::AbstractQueue) = queue.data[end]

add!(queue::AbstractQueue{T}, item::T) where {T<:Any} =
    push!(queue.data, item)

function remove!(queue::AbstractQueue{T}, item::T) where {T<:Any}
    ndx = findfirst(x -> x === item, queue.data)
    decrement!(queue.n, 1)
    deleteat!(queue.data, ndx)
end

mutable struct Queue{T<:Any} <: AbstractQueue{T}
    n::Variable{Int64}
    data::Vector{T}
    Queue{T}() where {T<:Any} =
        new(Variable{Int64}(0, history=true),
        Vector{T}(undef,0))
end

function enqueue!(queue::Queue{T}, item::T) where {T<:Any}
    increment!(queue.n, 1)
    push!(queue.data, item)
end

function dequeue!(queue::Queue{T})::T where {T<:Any}
    decrement!(queue.n, 1)
    popfirst!(queue.data)
end

FifoQueue = Queue

mutable struct LifoQueue{T<:Any} <: AbstractQueue{T}
    n::Variable{Int64}
    data::Vector{T}
    LifoQueue{T}() where {T<:Any} =
        new(Variable{Int64}(0, history=true),
        Vector{T}(undef,0))
end

function enqueue!(queue::LifoQueue{T}, item::T) where {T<:Any}
    increment!(queue.n, 1)
    push!(queue.data, item)
end

function dequeue!(queue::LifoQueue{T})::T where {T<:Any}
    decrement!(queue.n, 1)
    pop!(queue.data)
end
