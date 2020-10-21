module SimLynx

using Base
using Plots; gr()
using Printf

export @event, @activity, @schedule, @with_new_simulation, @process
export current_process_store, process_store, process_state, event_schedule
export start_simulation, current_time, enqueue!, dequeue!, print_stats, plot_history
export FifoQueue, Process, Notice

include("statistics.jl")
include("histories.jl")

include("core.jl")

include("variables.jl")
include("queues.jl")
include("resources.jl")


end
