# rendezvous.jl

struct Message <: AbstractMessage
    time::Float64
    caller::Process
    name::Symbol
    args::Array{Any, 1}
end

"Check for interprocess communications rendezvous."
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

macro accept(caller, sig)
    if !isa(caller, Symbol)
        throw(ArgumentError("first argument must be a symbol, " *
                            "given $caller"))
    end
    if !(isa(sig, Expr) &&
             sig.head === :call &&
             length(sig.args) > 0 &&
             isa(sig.args[1], Symbol))
        throw(ArgumentError("second argument must be a signature, " *
                            "given $sig"))
    end
    quote
        current_process().acceptors = [Acceptor(Symbol($(esc(sig.args[1]))),
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

macro accept(caller, sig, body)
    if !isa(caller, Symbol)
        throw(ArgumentError("first argument must be a symbol, " *
                            "given $caller"))
    end
    if !(isa(sig, Expr) &&
             sig.head === :call &&
             length(sig.args) > 0 &&
             isa(sig.args[1], Symbol))
        throw(ArgumentError("second argument must be a signature, " *
                            "given $sig"))
    end
    proc = Expr(:->, sig.args[2], body)
    quote
        current_process().acceptors =
            [Acceptor(Symbol($(esc(sig.args[1]))),
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

