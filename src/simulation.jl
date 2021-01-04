# simulation.jl
# Licensed under the MIT License. See LICENSE.md file in the project root for
# full license information.

"""
    Simulation

A simulation represents the state of an execution. Specifically, it contains
the current time, current event, future event list, and control task for the
simulation.

# Fields

- `running::Bool`: true if this simulation is currently running
- `trace::Bool`: simulation execution steps will be printed of true - not that
      this may produce a lot of output
- `time::Float64`: the simulation clock (i.e., current simulation time)
- `notice::Union{Notice, Nothing}`: the notice currently being executed or
      nothing
- `process::Union{Process, Nothing}`: the process currently being executed or
      nothing
- `now_event_list::Array{Notice, 1}`: the now event list
- `future_event_list::Array{Notice, 1}`: the future event list
- `control_task::Task`: the task executing the simulation

You should generally use the @simulation macro to create a new simulation.
"""
mutable struct Simulation
    running::Bool
    trace::Bool
    time::Float64
    notice::Union{Notice, Nothing}
    process::Union{Process, Nothing}
    now_event_list::Array{Notice, 1}
    future_event_list::Array{Notice, 1}
    control_task::Task
    Simulation() = new(false,                      # running
                       false,                      # trace
                       0.0,                        # time
                       nothing,                    # notice
                       nothing,                    # process
                       Array{Notice, 1}(undef, 0), # now_event_list
                       Array{Notice, 1}(undef, 0), # future_event_list
                       current_task())             # control_task
end

# The current simulation is a global variable designating the currently active
# simulation. Unfortunately, there is no way (currently) to associate a type
# with a global variable but we would like to have:
# current_simulation::Union{Simulation, Nothing} = nothing

"The current active simulation."
current_simulation = nothing

# Shortcut functions to fields in the current simulation

"Returns the trace field of the current simulation."
current_trace() = current_simulation.trace

"Sets the trace field of the current simulation."
current_trace!(trace::Bool) = current_simulation.trace = trace

"Returns the time field of the current simulation."
current_time() = current_simulation.time

"Returns the notice field of the current simulation."
current_notice() = current_simulation.notice

"Returns the process field of the current simulation."
current_process() = current_simulation.process

"Return the value of the property key for the current process."
current_process_store(key::Symbol) = current_process().storage[key]

"Sets the value of the property key for the current process."
function current_process_store!(key::Symbol, value)
    current_process().storage[key] = value
end

"Returns the control_task field of the current simulation."
control_task() = current_simulation.control_task

# @simulation macro

"""
    @simulation begin
        <body>
    end

Executes the body within a new simulation environment. This is the easiest way
to ensure a clean simulation environment.
"""
macro simulation(body)
    quote
        control_task = @async begin
            global current_simulation
            old_simulation = current_simulation
            current_simulation = Simulation()
            try
                $(esc(body))
            catch e
                showerror(stdout, e, catch_backtrace())
            finally
                current_simulation = old_simulation
            end
        end
        wait(control_task)
    end
end

"""
    @simulation sim begin
        <body>
    end

Executes the body within the specified simulation environment. 
"""
macro simulation(sim, body)
    quote
        control_task = @async begin
            global current_simulation
            old_simulation = current_simulation
            current_simulation = sim
            try
                $(esc(body))
            catch e
                showerror(stdout, e, catch_backtrace())
            finally
                current_simulation = old_simulation
            end
        end
        wait(control_task)
    end
end
