# SimLynx/src/queue.jl
# Licensed under the MIT License. See LICENSE.md file in the project root for
# full license information.

import Base: length, isempty, first, last

abstract type AbstractQueue{T<:Any} end

# Abstract Queue Operations

length(queue::AbstractQueue) = length(queue.data)
isempty(queue::AbstractQueue) = length(queue.data) == 0
first(queue::AbstractQueue) = queue.data[1]
last(queue::AbstractQueue) = queue.data[end]

"Add an item to the queue."
add!(queue::AbstractQueue{T}, item::T) where {T<:Any} =
    push!(queue.data, item)

"Remove an item from the queue."
function remove!(queue::AbstractQueue{T}, item::T) where {T<:Any}
    ndx = findfirst(x -> x === item, queue.data)
    decrement!(queue.n, 1)
    deleteat!(queue.data, ndx)
end

# Queue (equivalent to a FifoQueue)

"""
    Queue{T<:Any} <: AbstractQueue{T}

    Queue()

A general queue (actually a deque).

# Fields
- `n::Variable{Int64}`: a variable containing the number of items in the queue
- `data::Vector{T}`: the array holding the queue
"""
mutable struct Queue{T<:Any} <: AbstractQueue{T}
    n::Variable{Int64}
    data::Vector{T}
    Queue{T}() where {T<:Any} =
        new(Variable{Int64}(0, history=true),
        Vector{T}(undef,0))
end

"Add an item to the queue."
function enqueue!(queue::Queue{T}, item::T) where {T<:Any}
    increment!(queue.n, 1)
    push!(queue.data, item)
end

"Remove an item from the queue."
function dequeue!(queue::Queue{T})::T where {T<:Any}
    decrement!(queue.n, 1)
    popfirst!(queue.data)
end

"""
    FifoQueue{T<:Any} <: AbstractQueue{T}

    FifoQueue()

A first-in-first-out queue.

# Fields
- `n::Variable{Int64}`: a variable containing the number of items in the queue
- `data::Vector{T}`: the array holding the queue
"""
FifoQueue = Queue

# LifoQueue

"""
    LifoQueue{T<:Any} <: AbstractQueue{T}

    LifoQueue()

A last-in-first-out queue (i.e., a stack).

# Fields
- `n::Variable{Int64}`: a variable containing the number of items in the queue
- `data::Vector{T}`: the array holding the queue
"""
mutable struct LifoQueue{T<:Any} <: AbstractQueue{T}
    n::Variable{Int64}
    data::Vector{T}
    LifoQueue{T}() where {T<:Any} =
        new(Variable{Int64}(0, history=true),
        Vector{T}(undef,0))
end

"Add an item to the queue."
function enqueue!(queue::LifoQueue{T}, item::T) where {T<:Any}
    increment!(queue.n, 1)
    push!(queue.data, item)
end

"Remove an item from the queue."
function dequeue!(queue::LifoQueue{T})::T where {T<:Any}
    decrement!(queue.n, 1)
    pop!(queue.data)
end
