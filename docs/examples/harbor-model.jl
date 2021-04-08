# harbor-model.jl
# SimLynx.jl Harbor Model

using SimLynx
SimLynx.greet()

using Distributions: Exponential, Uniform
using Random

const MEAN_INTERARRIVAL_TIME = 4.0 / 3.0 # days
const MIN_UNLOADING_TIME = 1.0 # days
const MAX_UNLOADING_TIME = 2.5 # days

cycle_time = nothing

dock = nothing
queue = nothing

@process scheduler() begin
    dist = Exponential(MEAN_INTERARRIVAL_TIME)
    i = 1
    while true
        @schedule in 0.0 ship(i)
        work(rand(dist))
        i += 1
    end
end

@process ship(i::Integer) begin
    dist = Uniform(MIN_UNLOADING_TIME, MAX_UNLOADING_TIME)
    arrival_time = current_time()
    current_process_store!(:unloading_time, rand(dist))
    if !harbor_master(current_process(), :arriving)
        enqueue!(queue, current_process())
        suspend()
    end
    work(current_process_store(:unloading_time))
    remove!(dock, current_process())
    cycle_time.value = current_time() - arrival_time
    harbor_master(current_process(), :leaving)
    return nothing
end

function harbor_master(ship::Process, action::Symbol)
    if action == :arriving
        if length(dock) < 2
            # The dock is not full
            if isempty(dock)
                process_store!(ship,
                               :unloading_time,
                               process_store(ship, :unloading_time) / 2)
            else
                other_ship = first(dock)
                notice = interrupt(other_ship)
               notice.time = current_time() + 2*notice.time
                resume(other_ship, notice)
            end
            add!(dock, ship)
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
    println("Harbor Model - report after $(current_time()) days - $(cycle_time.stats.n) ships unloaded")
    println("Minimum unload time was $(cycle_time.stats.min)")
    println("Maximum unload time was $(cycle_time.stats.max)")
    println("Average unload time was $(cycle_time.stats.mean)")
    println("Average queue of ships waiting to be unloaded was $(queue.n.stats.mean)")
    println("Maximum queue of ships waiting to be unloaded was $(queue.n.stats.max)")
    plot_history(queue.n, title="Queue of Ships History")
    stop_simulation()
end

function run_simulation()
    @simulation begin
        current_trace!(true)
        global cycle_time = Variable{Float64}(data=:tally)
        global dock = Queue{Process}()
        global queue = FifoQueue{Process}()
        @schedule at 0.0 scheduler()
        @schedule at 80.0 stop_sim()
        start_simulation()
    end
end

run_simulation()
