# activity.jl

# This is a placeholder for the future definition of an activity.

"""
    Activity

Represents an activity in a simulation.

# Fields
- `name::String`: the name of the activity (used in tracing)
- `enter::Union{Event, Nothing}`: the enter event for the activity
- `duration::Function': the function to compute the activity duration
- `enter::Union{Event, Nothing}`: the enter event for the activity
"""
struct Activity <: ActiveElement
    name::String
    enter::Union{Event, Nothing}
    duration::Function
    exit::Union{Event, Nothing}
end

"Prints the activity name to the IO stream."
Base.show(io::IO, activity::Activity) =
    print(io, "Activity $(activity.name)")

"""
    @activity <sig> begin
        <body>
    end

Define a simulation event with the specified signature and implemented by the
given body. The exact format is TBD.
"""
macro activity(sig, body)
end

