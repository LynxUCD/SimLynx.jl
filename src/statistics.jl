abstract type Stats{T<:Real}
end

mutable struct AccumulatedStats{T<:Real} <: Stats{T}
    min::T
    max::T
    n::Float64
    sum::Float64
    sum_squares::Float64
    AccumulatedStats{T}() where {T<:Real} =
        new(zero(T), zero(T), 0.0, 0.0, 0.0)
    AccumulatedStats{T}(value::T) where {T<:Real} =
        new(value, value, 0.0, 0.0, 0.0)
end

"Accumulate running statistics over a time duration."
function update!(stats::AccumulatedStats{T}, x::T, t::Float64) where {T<:Real}
    if t < 0.0
        throw(ArgumentError("weight t cannot be negative, got $t"))
    end
    if stats.n > 0.0
        stats.min = min(x, stats.min)
        stats.max = max(x, stats.max)
    else
        stats.min = x
        stats.max = x
    end
    stats.n += t
    stats.sum += x * t
    stats.sum_squares += x^2 * t
    return nothing
end

mutable struct TalliedStats{T<:Real} <: Stats{T}
    min::T
    max::T
    n::Int64
    sum::Float64
    sum_squares::Float64
    TalliedStats{T}() where {T<:Real} =
        new(zero(T), zero(T), 0.0, 0.0, 0.0)
    TalliedStats{T}(value::T) where {T<:Real} =
        new(value, value, 1, value, value^2)
end

"Tally running statistics."
function update!(stats::TalliedStats{T}, x::T) where {T<:Real}
    if stats.n > 0
        stats.min = min(x, stats.min)
        stats.max = max(x, stats.max)
    else
        stats.min = x
        stats.max = x
    end
    stats.n += 1
    stats.sum += x
    stats.sum_squares += x^2
    return nothing
end

mean(stats::Stats) = stats.sum / stats.n
mean_square(stats::Stats) = stats.sum_squares / stats.n
variance(stats::Stats) = mean_square(stats) - mean(stats)^2
stddev(stats::Stats) = sqrt(variance(stats))

function Base.getproperty(stats::Stats, name::Symbol)
    if name === :mean
        return mean(stats)
    elseif name === :variance
        return variance(stats)
    elseif name === :stddev
        return stddev(stats)
   else # fallback to getfield
       return getfield(stats, name)
   end
end


"Print the accumulates statistics for a variable."
function print_stats(stats::Stats;
                     format="%f",
                     title="Statistics")
    println(title)
    println("     min = $(stats.min)")
    println("     max = $(stats.max)")
    println("       n = $(stats.n)")
    println("    mean = $(stats.mean)")
    println("variance = $(stats.variance)")
    println("  stddev = $(stats.stddev)")
    flush(stdout)
end

