# variable.jl

include("statistics.jl")
include("history.jl")

"""
A variable automatically maintains the history and statistics of its value over
time.
"""
mutable struct Variable{T<:Real}
    value::T
    prev_update::Float64
    history::Union{History{T}, Nothing}
    stats::Union{Stats{T}, Nothing}
    function Variable{T}(value::T;
                         data=:accumulate,
                         history=false,
                         stats=true) where {T<:Real}
        if data == :none
            return new(value, 0.0, nothing, nothing)
        elseif data == :tally
            return new(value, 0.0,
                       history ? TalliedHistory{T}(value) : nothing,
                       stats ? TalliedStats{T}(value) : nothing)
        elseif data == :accumulate
            return new(value, 0.0,
                       history ? AccumulatedHistory{T}(value) : nothing,
                       stats ? AccumulatedStats{T}(value) : nothing)
        else
            throw(ArgumentError("expected :none, :tally, or :accumulate, got $data"))
        end
    end
    function Variable{T}(;
                         data=:accumulate,
                         history=false,
                         stats=true) where {T<:Real}
        if data == :none
            return new(zero(T), 0.0, nothing, nothing)
        elseif data == :tally
            return new(zero(T), 0.0,
                       history ? TalliedHistory{T}() : nothing,
                       stats ? TalliedStats{T}() : nothing)
        elseif data == :accumulate
            return new(zero(T), 0.0,
                       history ? AccumulatedHistory{T}() : nothing,
                       stats ? AccumulatedStats{T}() : nothing)
        else
            throw(ArgumentError("expected :none, :tally, or :accumulate, got $data"))
        end
    end
end

function Base.getproperty(var::Variable{T}, name::Symbol) where T<:Real
    value = getfield(var, :value)
    # If they just want the value, return it.
    if name == :value
        return value
    end
    prev_update = getfield(var, :prev_update)
    # If they just want the previous update time, return it.
    if name == :prev_update
        return prev_update
    end
    # Otherwise, synchronize the variable and return the requested field.
    history = getfield(var, :history)
    stats = getfield(var, :stats)
    duration = current_time() - prev_update
    if duration > 0.0
        if isa(history, AccumulatedHistory)
            update!(history, value, duration)
        end
        if isa(stats, AccumulatedStats)
            update!(stats, value, duration)
        end
        setfield!(var, :prev_update, current_time())
    end
    if name == :history
        return history
    elseif name == :stats
        return stats
    else
        throw(ArgumentError("expected a Variable field, given $name"))
    end
end

"Return the current value of a variable. (deprecated)"
# get(var::Variable) = var.value

function Base.setproperty!(var::Variable{T}, name::Symbol, value::T) where T<:Real
    if name!= :value
        throw(ArgumentError("expected Variable field :value, given $name"))
    end
    # Synchronize the variable
    old_value = getfield(var, :value)
    prev_update = getfield(var, :prev_update)
    history = getfield(var, :history)
    stats = getfield(var, :stats)
    duration = current_time() - prev_update
    if duration > 0.0
        if isa(history, AccumulatedHistory)
            update!(history, old_value, duration)
        end
        if isa(stats, AccumulatedStats)
            update!(stats, old_value, duration)
        end
        setfield!(var, :prev_update, current_time())
    end
    # Update the variable's value
    setfield!(var, :value, value)
    if isa(history, AccumulatedHistory)
        update!(history, var.value, 0.0)
    end
    if isa(history, TalliedHistory)
        update!(history, var.value)
    end
    if isa(stats, AccumulatedStats)
        update!(stats, var.value, 0.0)
    end
    if isa(stats, TalliedStats)
        update!(stats, var.value)
    end
    return nothing
end

"Set the value of a variable. (deprecated)"
# set!(var::Variable, value) = var.value = value

increment!(var::Variable, x) = var.value += x
decrement!(var::Variable, x) = var.value -= x

function print_stats(var::Variable;
                     title::String="Statistics")
    stats = var.stats
    if !isnothing(stats)
        print_stats(stats, title=title)
    end
    return nothing
end

function plot_history(var::Variable;
                      file::Union{String, Nothing}=nothing,
                      title="History")
    history = var.history
    if !isnothing(history)
        plot_history(history, file=file, title=title)
    end
    return nothing
end

