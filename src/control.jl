# SimLynx/src/control.jl
# Licensed under the MIT License. See LICENSE.md file in the project root for
# full license information.

"""
    event_schedule(notice::Notice, event_list::Array{Notice, 1})

Add a notice to the given event list. This routine keeps the event list in
sorted (ascending) order.
"""
function event_schedule(notice::Notice, event_list::Array{Notice, 1})
    index = searchsortedfirst(event_list, notice, lt=islessorequal)
    insert!(event_list, index, notice)
    return notice.element
end

"""
    schedule(notice::Notice)
    schedule(sim::Simulation, notice::Notice)

Schedule the notice on the future event list for the specified simulation,
which defaults to the current simulation.
"""
schedule(notice::Notice) = schedule(current_simulation, notice)
function schedule(sim::Simulation, notice::Notice)
    notice.time >= sim.time ||
        error("event time ($(notice.time)) less than simulation time ($(sim.time))")
    event_schedule(notice, sim.future_event_list)
end

"""
    schedule_now(notice::Notice)
    schedule_now(sim::Simulation, notice::Notice)

Schedule the notice on the now event list for the specified simulation, which
defaults to the current simulation. The notice is added at the end of the list.
"""
schedule_now(notice::Notice) = schedule_now(current_simulation, notice)
function schedule_now(sim::Simulation, notice::Notice)
    notice.time = current_time()
    push!(sim.now_event_list, notice)
    return notice.element
end

"""
    schedule_immediate(notice::Notice)
    schedule_immediate(sim::Simulation, notice::Notice)

Schedule the notice on the now event list for the specified simulation, which
defaults to the current simulation. The notice is added at the beginning of the
list.
"""
schedule_immediate(notice::Notice) = schedule_immediate(current_simulation, notice)
function schedule_immediate(sim::Simulation, notice::Notice)
    notice.time = current_time()
    pushfirst!(sim.now_event_list, notice)
    return notice.element
end

"""
    @schedule now <expr>
    @schedule immediate <expr>

Schedule an event to occur now. This create an event notice and adds it to the
now event list. The keywork :immediate will add the notice at the front of the
now even list and :now will add the end.
"""
macro schedule(sym::Symbol, expr)
    if sym === :now
        return quote
            let element = $(esc(expr))
                if isa(element, Process)
                    schedule_now(element.notice)
                else
                    schedule_now(Notice(current_time(), $(esc(expr))))
                end
            end
        end
    end
    if sym === :immediate
        return quote
            let element = $(esc(expr))
                if isa(element, Process)
                    schedule_immediate(element.notice)
                else
                    schedule_immediate(Notice(current_time(),$(esc(expr))))
                end
            end
        end
    end
    throw(ArgumentError("Expected 'now' or 'immediate' as @argument keyword, given: $sym"))
end

"""
    @schedule at <time> <expr>
    @schedule in <delta> <expr>

Schedule an event to occur in the future.
"""
macro schedule(sym::Symbol, arg, expr)
    if sym === :at
        return quote
            let element = $(esc(expr))
                if isa(element, Process)
                    element.notice.time = $(esc(arg))
                    schedule(element.notice)
                else
                    schedule(Notice($(esc(arg)), element))
                end
            end
        end
    end
    if sym === :in
         return quote
            let element = $(esc(expr))
                if isa(element, Process)
                    element.notice.time = current_time() + $(esc(arg))
                    schedule(element.notice)
                else
                    schedule(Notice(current_time() + $(esc(arg)), element))
                end
            end
        end
    end
    throw(ArgumentError("Expected 'at' or 'in' as @argument keyword, given: $sym"))
end

# Simulation control routines

"""
    wait(delay::Real)
    work(delay::Real)

Simulate the delay while work is being done.  Add an event to return to this
task in the future to the event list.
"""
function wait_or_work(delay::Real)
    if isnothing(current_process())
        Error("call to work must be within a process")
    end
    process_state!(current_process(), :working)
    @schedule in delay current_process()
    yieldto(control_task())
end
wait(delay::Real) = wait_or_work(delay)
work(delay::Real) = wait_or_work(delay)

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

"Stop the execution of the current simulation."
function stop_simulation()
    current_simulation.running = false
end

# Advanced process control

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
    process_state!(process, :working)
    schedule(notice)
end
