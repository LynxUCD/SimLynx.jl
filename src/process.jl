# process.jl

"""
    Acceptor

Represents the function to accept a message to a process.

# Fields
- `name::Symbol`: the name of the message to be accepted
- `proc::Union{Function, Nothing}`: the function to be executed to accept a
      message from a process or nothing if there is no critical section
"""
struct Acceptor
    name::Symbol
    proc::Union{Function, Nothing}
end

"""
    Process

Represents a process in a simulation.

# Fields
- `name::String`: the name of the process (used in tracing)
- `state::Symbol`: the process state
- `task::Task`: the task executing the process
- `notice::Notice`: the notice used to schedule the process
- `queue::Array{AbstractMessage, 1}`: the queue of messages to the process
- `acceptors::Array{Acceptor, 1}`: the list of current acceptors for the process
- `response::Any`: the response to a message send to a process
- `storage::IdDict{Symbol, Any}`: an IdDict to store the process properties

# States
- `:created`: the process has been created but is not yet running
- `:active`: the process is running
- `:working`: the process is working or waiting
- `:delayed`: the process is delayed (waiting for some resource)
- `:interrupted`: the process has been interrupted by another process
- `:suspended`: the process has suspended itself
- `:terminated`: the process has terminated
"""
mutable struct Process <: ActiveElement
    name::String
    state::Symbol
    task::Task
    notice::Notice
    queue::Array{AbstractMessage, 1}
    acceptors::Array{Acceptor, 1}
    response::Any
    storage::IdDict{Symbol, Any}
    function Process(form::String, task::Task)
        x = new(form,
                :created,
                task)
        x.notice = Notice(0.0, x)
        x.queue = Array{AbstractMessage, 1}(undef, 0)
        x.acceptors = Array{Acceptor, 1}(undef, 0)
        x.response = nothing
        x.storage = IdDict{Symbol, Any}()
        return x
    end
end

"Return the value of the property key for the specified process."
process_store(process::Process, key::Symbol) = process.storage[key]

"Sets the value of the property key for the specified process."
function process_store!(process::Process, key::Symbol, value)
    process.storage[key] = value
end

"Prints the process name and state to the IO stream."
Base.show(io::IO, process::Process) =
    print(io, "Process $(process.name) [$(process.state)]")

"Return the process state for the specified process."
process_state(process::Process) = process.state

"Set the process state for a the specified process."
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
    if !(isa(sig, Expr) && sig.head === :call)
        throw(ArgumentError("the first argument must be a signature, " *
                            "given $sig"))
    end
    if !isa(body, Expr)
        throw(ArgumentError("the second argument must be a body, " *
                            "given $body"))
    end
    args = [isa(sig, Symbol) ? sig : sig.args[1] for sig in sig.args[2:end]]
    quote
        $(esc(sig)) =
            let _argvals = [$(esc.(args)...)]
                Process(string($(esc(sig.args[1]))) * "(" *
                               join(string.(_argvals), ", ") * ")",
                        @task begin
                            try
                                $(esc(body))
                            catch e
                                showerror(stdout, e, catch_backtrace())
                            finally
                                process_state!(current_process(), :terminated)
                                yieldto(current_simulation.control_task)
                            end
                        end)
            end
    end
end

