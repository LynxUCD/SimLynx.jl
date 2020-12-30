# notice.jl

"""
    Notice

Represents the execution of an event at some (simulated) future time. Note that
an event may be an active element: Event, Activity, or Process.

# Fields
- `time::Float64`: the (simulated) time for the event to be executed
- `element::Union{ActiveElement, Nothing}`: the ActiveElement to be executed or
      nothing (as a placeholder)

We need to check if nothing is ever an actual value that is used.
"""
mutable struct Notice
    time::Float64
    element::Union{ActiveElement, Nothing}
end

"Ascending order function for event lists."
islessorequal(notice_1::Notice, notice_2::Notice) =
    notice_1.time <= notice_2.time

