# SimLynx/src/rendezvous.jl
# Licensed under the MIT License. See LICENSE.md file in the project root for
# full license information.

"""
    Message <: AbstractMessage

Represents a message being send to a process.

# Fields
- `time::Float64` - the time the message was sent
- `caller::Process` - the process sending the message
- `name::Symbol` - the type of message being send
- `args::Array{Any, 1}` - the arguments for the message
"""
struct Message <: AbstractMessage
    time::Float64
    caller::Process
    name::Symbol
    args::Array{Any, 1}
end

"""
Check for interprocess communications rendezvous. Returns the message and
acceptor and a Boolean indicating whether a rendezvous will occur. The first
two returned values are nothing of the Boolean is false.
"""
function rendezvous(process::Process)
    for (i, message) in enumerate(process.queue)
        for acceptor in process.acceptors
            if acceptor.name == message.name
                deleteat!(process.queue, i)
                return (message, acceptor, true)
            end
        end
    end
    return (nothing, nothing, false)
end

"""
    accept <caller> <signature>
"""
macro accept(caller::Symbol, sig)
   @capture(sig, f_Symbol(xs__)) ||
        throw(ArgumentError("second argument must be a signature, " *
                            "given $sig"))
    quote
        current_process().acceptors = [Acceptor(Symbol($(esc(f))),
                                                nothing)]
        while true
            message, acceptor, accepted = rendezvous(current_process())
            if accepted
                message.caller.response = nothing
                @schedule immediate message.caller
                break
            else
                yieldto(control_task())
            end
        end
    end
end

macro accept(caller::Symbol, sig, body)
    @capture(sig, f_Symbol(xs__)) ||
        throw(ArgumentError("second argument must be a signature, " *
                            "given $sig"))
    proc = Expr(:->, sig.args[2], body)
    quote
        current_process().acceptors =
            [Acceptor(Symbol($(esc(f))),
                      $(esc(proc)))]
        while true
            message, acceptor, accepted = rendezvous(current_process())
            if accepted
                if !isnothing(acceptor.proc)
                    message.caller.response = acceptor.proc(message.args...)
                else
                    message.caller.response = nothing
                end
                @schedule immediate message.caller
                break
            else
                yieldto(control_task())
            end
        end
    end
end

macro send(callee, sig)
    if !(isa(callee, Symbol) ||
         isa(callee, Expr))
        throw(ArgumentError("first argument must be a symbol or expression, " *
                            "given $callee"))
    end
    if !(isa(sig, Expr) &&
             sig.head === :call &&
             length(sig.args) > 0 &&
             isa(sig.args[1], Symbol))
        throw(ArgumentError("second argument must be a signature, " *
                            "given $sig"))
    end
    quote
        if isnothing(current_process())
            Error("call to send must be within a process")
        end
        let callee_process = $(esc(callee))
            message = Message(current_time(),
                              current_process(),
                              Symbol($(esc(sig.args[1]))),
                              [$(esc.(sig.args[2:end])...)])
            push!(callee_process.queue, message)
            process_state!(current_process(), :delayed)
            @schedule immediate callee_process
            yieldto(control_task())
            current_process().response
        end
    end
end
