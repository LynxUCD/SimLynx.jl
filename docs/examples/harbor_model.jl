"""
The Harbor Model is an example simulation that leverages the resume, suspend, and interrupt methods of SimLynx.
"""
using SimLynx

using Distributions: Exponential, Uniform
using Random

cycle_time = nothing

dock = nothing
queue = nothing

@process scheduler() begin
    i = 1
    while true
        @schedule in 0.0 ship(i)
        work(rand(Exponential(4.0 / 3.0)))
        i += 1
    end
end

@process ship(i::Integer) begin
    arrival_time = current_time()
    current_process_store(:unloading_time, rand(Uniform(1.0, 2.5)))
    if !harbor_master(current_process(), :arriving)
        enqueue!(queue, current_process())
        suspend()
    end
    work(current_process_store(:unloading_time))
    remove(dock, current_process())
    set!(cycle_time, current_time() - arrival_time)
    harbor_master(current_process(), :leaving)
    return nothing
end

function harbor_master(ship::Process, action::Symbol)
    if action == :arriving
        if length(dock.data) < 2
            # The dock is not full
            if isempty(dock)
                process_store(ship,
                              :unloading_time,
                              process_store(ship, :unloading_time) / 2)
            else
                other_ship = first(dock)
                notice = interrupt(other_ship)
                notice.time = current_time() + 2*notice.time
                resume(other_ship, notice)
            end
            enqueue!(dock, ship)
            return true
        else
            # The dock is full
            return false
        end
    elseif action == :leaving
        if isempty(queue)
            if !isempty(dock)
                other_ship = first(dock)
                notice = interrupt(other_ship)
                notice.time = current_time() + 2/notice.time
                resume(other_ship, notice)
            end
        else
            next_ship = dequeue!(queue)
            enqueue!(dock, next_ship)
            resume(next_ship, Notice(current_time(), next_ship))
        end
        return true
    else
        error("harbor_master: illegal action value $action")
    end
end

@event stop_sim() begin
    println("Harbor Model - report after $(current_time()) - $(cycle_time.stats.n)")
    println("Minimum unload time was $(cycle_time.stats.min)")
    println("Maximum unload time was $(cycle_time.stats.max)")
    println("Average unload time was $(cycle_time.stats.max)")
    println("Average queue of ships waiting to be unloaded was $(mean(queue.n.stats))")
    println("Maximum queue of ships waiting to be unloaded was $(queue.n.stats.max)")
    plot_history(queue.n, "harbor-history.png")
    stop_simulation()
end

function run_simulation()
    @with_new_simulation begin
        # current_trace!(true)
        global cycle_time = Variable{Float64}(data=:tally)
        global dock = FifoQueue{Process}()
        global queue = FifoQueue{Process}()
        @schedule at 0.0 scheduler()
        @schedule at 80.0 stop_sim()
        start_simulation()
    end
end

run_simulation()
