# Variables
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

"Return the current value of a variable."
Base.get(var::Variable) = var.value

"""
Synchronize the history and statistics for a variable. This is called before
the value of a variable is changed, via set!, and before the history or
statistics are used.
"""
function sync!(var::Variable)
    duration = current_time() - var.prev_update
    if duration > 0.0
        if isa(var.history, AccumulatedHistory)
            update!(var.history, var.value, duration)
        end
        if isa(var.stats, AccumulatedStats)
            update!(var.stats, var.value, duration)
        end
        var.prev_update = current_time()
    end
    return nothing
end

"Set the value of a variable."
function set!(var::Variable, value)
    sync!(var)
    var.value = value
    if isa(var.history, AccumulatedHistory)
        update!(var.history, var.value, 0.0)
    end
    if isa(var.history, TalliedHistory)
        update!(var.history, var.value)
    end
    if isa(var.stats, AccumulatedStats)
        update!(var.stats, var.value, 0.0)
    end
    if isa(var.stats, TalliedStats)
        update!(var.stats, var.value)
    end
    nothing
end

increment!(var::Variable, x) = set!(var, var.value + x)
decrement!(var::Variable, x) = set!(var, var.value - x)

function print_stats(var::Variable,
                     title::String = "Statistics")
    sync!(var)
    print_stats(var.stats)
end

function plot_history(var::Variable,
                      file::Union{String, Nothing}=nothing,
                      title = "History")
    sync!(var)
    if isa(var.history, AccumulatedHistory)
        plot_history(var.history, file, title)
    end
    if isa(var.history, TalliedHistory)
        plot_histogram(var.history, file, title)
    end
end
