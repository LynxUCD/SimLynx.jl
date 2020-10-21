# simlynx.jl
# A Hybrid Simulation Engine and Language in Julia

#=  Version History
    0.1.0   simple-simulation.jl
    0.2.0   Minimum Viable Product (MVP)
    0.3.0
        + Old simple-simulation version 0.7.0
        + Code cleanup - consistent naming
        + Split variables and resources into separate files
        + Added ActiveElement abstract data type as the parent of Event,
          Activity (which is stubbed), and Process
=#


"""
    @thunk ex

Return a thunk (i.e., a function with no arguments) that executes the expression
when called.
"""
macro thunk(ex)
    :(() -> $(esc(ex)))
end

# Active Elements

abstract type ActiveElement
end

#=
Events

Events are represented by a function and doesn't need a separate representation.
Similarly, we don't need an @event macro. We will just just ordinary functions.
=#

struct Event <: ActiveElement
    name::String
    proc::Function
end

Base.show(io::IO, event::Event) =
    print(io, "Event $(event.name)")

"""
    @event <sig> begin
        <body>
    end

Define a simulation event with the specified signature and implemented by the
given body.
"""
macro event(sig, body)
    :($(esc(sig)) = Event($(string(sig)),
                          @thunk $(esc(body))))
end

#=
Activities

This is a stub for now.
=#

struct Activity <: ActiveElement
    name::String
    enter::Union{Event, Nothing}
    duration::Function
    exit::Union{Event, Nothing}
end

Base.show(io::IO, activity::Activity) =
    print(io, "Activity $(activity.name)")

macro activity(sig, body)
end

#=
Processes

    state        |  description
    -------------+--
    created      |  the process has been created but not yet running
    active       |  the process is running
    working      |  the process is working or waiting
    delayed      |  the process is delayed
    interrupted
    suspended
    terminated

We had a choice here between a function style:

  @process function generator(n::Integer)
  ...
  end

or without the function keyword:

  @process generator(n::Integer) begin
  ...
  end

I have opted for the latter for now. It is easy for us to change back if we
want to later.

Also, the body of the macro is not what I expected. There is an issue / bug
(depending of who you ask) that prevents us from defining the function using
the function keyword and instead have to use the short form using =. It is a
workaround that works but seems like a kludge.

The issue is #25080, Interpolation of signature into `function...end` Expr causes
syntax error if there is a function body.
=#

mutable struct Process <: ActiveElement
    name::String
    task::Task
    storage::IdDict{Symbol, Any}
    state::Symbol
    Process(form::String, task::Task) =
        new(form, task, IdDict{Symbol, Any}(), :created)
end

current_process_store(key::Symbol) =
    current_process().storage[key]
process_store(process::Process, key::Symbol) =
    process.storage[key]

current_process_store(key::Symbol, value) =
    current_process().storage[key] = value
process_store(process::Process, key::Symbol, value) =
    process.storage[key] = value

#=
Base.show(io::IO, process::Process) =
    print(io, "Process $(process.name) state = $(process.state)")
=#

process_state(process::Process) = process.state
function process_state!(process::Process, state::Symbol)
    process.state = state
    if current_trace()
        @printf("%9.3f: %s\n", current_time(), current_notice().element)
    end
end

"""
    @process <sig> begin
        <body>
    end

Define a simulation process with the specified signature and implemented by the
given body.
"""
macro process(sig, body)
    :($(esc(sig)) = Process($(string(sig)),
                            @task begin
                                try
                                    $(esc(body))
                                catch e
                                    showerror(stdout, e, catch_backtrace())
                                finally
                                    yieldto(current_simulation.control_task)
                                end
                            end))
end

#=
Event Notice Definition and Scheduling

An event notice represents the execution of an event at some (simulated) future
time. Generally we will use 'ev' (as in event) for event notice variables.
=#

"A notice represents the execution of an event at some (simulated) future time."
mutable struct Notice
    time::Float64
    element::Union{ActiveElement, Nothing}
end

"Ascending order function for event lists."
islessorequal(notice_1::Notice, notice_2::Notice) =
    notice_1.time <= notice_2.time

"""
A simulation represents the state of an execution. Specifically, it contains
the current time, current event, future event list, and control task for the
simulation.
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
    Simulation() = new(false,                      #running
                       false,                      # trace
                       0.0,                        # time
                       nothing,                    # notice
                       nothing,                    # process
                       Array{Notice, 1}(undef, 0), # now_event_list
                       Array{Notice, 1}(undef, 0), # future_event_list
                       current_task())             # control_task
end

"The current active simulation."
current_simulation = Simulation() # default simulation environment
current_trace() = current_simulation.trace
current_trace!(trace::Bool) = current_simulation.trace = trace
current_time() = current_simulation.time
current_notice() = current_simulation.notice
current_process() = current_simulation.process
control_task() = current_simulation.control_task

# The implementation of the with_new_simulation macro isn't exactly what we
# want in the long term, but it does illustrate the concept we want.

"""
    @with_new_simulation begin
        <body>
    end

Executes the body within a new simulation environment. This is the easiest way
to ensure a clean simulation environment.
"""
macro with_new_simulation(body)
    quote
        control_task = @async begin
            global current_simulation
            old_simulation = current_simulation
            current_simulation = Simulation()
            try
                $(esc(body))
            finally
                current_simulation = old_simulation
            end
        end
        wait(control_task)
    end
end

"""
    event_schedule(notice::Notice, event_list::Array{Notice, 1})

Add a notice to the given event list. This routine keeps the event list in
sorted (ascending) order.
"""
function event_schedule(notice::Notice, event_list::Array{Notice, 1})
    index = searchsortedfirst(event_list, notice, lt = islessorequal)
    insert!(event_list, index, notice)
end

"""
    schedule(notice::Notice)
    schedule(sim::Simulation, notice::Notice)

Schedule the notice on the future event list for the specified simulation,
which defaults to the current simulation.
"""
Base.schedule(notice::Notice) = schedule(current_simulation, notice)
function Base.schedule(sim::Simulation, notice::Notice)
    event_schedule(notice, sim.future_event_list)
end

schedule_now(notice::Notice) = schedule_now(current_simulation, notice)
function schedule_now(sim::Simulation, notice::Notice)
    event_schedule(notice, sim.now_event_list)
end

"""
    @schedule now <expr>
    @schedule at <time> <expr>
    @schedule in <delta> <expr>

Schedule an event to occur in the future. The create an event and adds it to
the future event list at the specified time.
"""
macro schedule(sym::Symbol, expr::Expr)
    if sym == :now
        return :(schedule_now(Notice(current_time(), $(esc(expr)))))
    end
    throw(ArgumentError("Expected 'now' as @argument keyword, given: $sym"))
end

macro schedule(sym::Symbol, arg, expr::Expr)
    if sym == :at
        return :(schedule(Notice($(esc(arg)), $(esc(expr)))))
    end
    if sym == :in
        return :(schedule(Notice(current_time() + $(esc(arg)), $(esc(expr)))))
    end
    throw(ArgumentError("Expected 'at' or 'in' as @argument keyword, given: $sym"))
end

# Simulation control routines

"""
    work(delay::Real)

Simulate the delay while work is being done.  Add an event to return to this
task in the future to the event list.
"""
function work(delay::Real)
    process_state!(current_notice().element, :working)
    @schedule in delay current_notice().element
    yieldto(control_task())
end

"""
    start_simulation()

This is the main simulation loop.
"""
function start_simulation()
    current_simulation.running = true
    while current_simulation.running
        # Check now event list
        if !isempty(current_simulation.now_event_list)
            current_simulation.notice =
                popfirst!(current_simulation.now_event_list)
        # Check future event list
        elseif !isempty(current_simulation.future_event_list)
            current_simulation.notice =
                popfirst!(current_simulation.future_event_list)
        # Otherwise, there are no more events
        else
            break
        end
        # Update the simulation time
        current_simulation.time =
            current_simulation.notice.time
        # If it is a simple event, execute the event
        if isa(current_notice().element, Event)
            if current_trace()
                @printf( "%9.3f: %s\n", current_time(),
                         current_notice().element)
            end
            current_notice().element.proc()
        # If it is process, yield to that process's task
        elseif isa(current_notice().element, Process)
            current_simulation.process =
                current_simulation.notice.element
            process_state!(current_process(), :active)
            yieldto(current_simulation.process.task)
        else
            error("Event is not an Event or Process")
        end
        current_simulation.notice = nothing
        current_simulation.process = nothing
    end
    current_simulation.running = false
end

function stop_simulation()
    current_simulation.running = false
end


"Suspend the execution of the current process."
function suspend()
    process_state!(current_process(), :suspended)
    yieldto(control_task())
end

"Interrupt the execution of a waiting process."
function interrupt(process::Process)
    ndx = findfirst(notice -> notice.element === process,
                    current_simulation.future_event_list)
    notice = current_simulation.future_event_list[ndx]
    deleteat!(current_simulation.future_event_list, ndx)
    notice.time -= current_time()
    process_state!(process, :interrupted)
    return notice
end

"Resume the execution of a suspended or interrupted process."
function resume(process::Process, notice::Notice)
    process_state!(process, :active)
    schedule(notice)
end

include("variables.jl")
include("queues.jl")
include("resources.jl")
