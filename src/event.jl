# event.jl

"""
    Event

Represents a discrete event in a simulation.

# Fields
- `name::String`: the name of the event (used in tracing)
- `proc::Function`: the function to be executed
"""
struct Event <: ActiveElement
    name::String
    proc::Function
end

"Prints the event name to the IO stream."
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
                Event(string($(esc(sig.args[1]))) * "(" *
                             join(string.(_argvals), ", ") * ")",
                      @thunk $(esc(body)))
            end
    end
end

