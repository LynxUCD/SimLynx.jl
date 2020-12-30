abstract type History{T<:Real}
end

mutable struct AccumulatedHistory{T<:Real} <: History{T}
    data::Array{T,1}
    durations::Array{Float64,1}
    AccumulatedHistory{T}(x::T) where {T<:Real} =
        new([x], [0.0])
end

function update!(hist::AccumulatedHistory{T}, x::T, t::Float64) where {T<:Real}
    if t < 0.0
        throw(ArgumentError("weight t cannot be negative, given $t"))
    end
    if x == hist.data[end]
        hist.durations[end] += t
    else
        push!(hist.data, x)
        push!(hist.durations, t)
    end
    return nothing
end

function plot_history(hist::AccumulatedHistory;
                      file::Union{String, Nothing} = nothing,
                      title::String = "History")
    println("Displaying $title plot")
    flush(stdout)
    t = 0.0
    x = []
    y = []
    for (value, duration) in zip(hist.data, hist.durations)
        push!(x, t); push!(y, value)
        t += duration
        push!(x, t); push!(y, value)
    end
    p = plot(x,  y, title = title,
             xlabel = "Time", ylabel = "Value",
             legend = false)
    display(p)
    if !isnothing(file)
        println("Writing $title plot to file \"$file\"")
        savefig(p, file)
    end
    return nothing
end

mutable struct TalliedHistory{T<:Real} <: History{T}
    data::Array{T,1}
    TalliedHistory{T}() where {T<:Real} =
        new(Array{T,1}(undef,0))
end

function update!(hist::TalliedHistory{T}, x::T) where {T<:Real}
    push!(hist.data, x)
    return nothing
end

function plot_history(hist::TalliedHistory{T};
                      file::Union{String, Nothing}=nothing,
                      title::String="Histogram") where {T<:Integer}
    low, high = extrema(hist.data) # minimum and maximum data values
    n = high-low+1 # range of data values
    histo = zeros(Int64,n) # empty histogram
    # Construct the histogram counts
    for item in hist.data
        histo[item-low+1] += 1
    end
    # Build the bar chart
    p = bar(range(low, stop=high),histo, title=title,
            xlabel="Value", ylabel="Count",
            legend=false)
    println("Displaying $title plot")
    flush(stdout)
    display(p)
    if !isnothing(file)
        println("Writing $title plot to file \"$file\"")
        savefig(p, file)
    end
    return nothing
end

function plot_history(hist::TalliedHistory{T};
                      file::Union{String, Nothing}=nothing,
                      title::String="Histogram") where {T<:Real}
    # Build the histogram
    p = histogram(hist.data, bins=100, title=title,
                  xlabel="Value", ylabel="Count",
                  legend=false)
    println("Displaying $title plot")
    flush(stdout)
    display(p)
    if !isnothing(file)
        println("Writing $title plot to file \"$file\"")
        savefig(p, file)
    end
    return nothing
end

