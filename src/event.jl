# SimLynx/src/event.jl
# Licensed under the MIT License. See LICENSE.md file in the project root for
# full license information.

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
    @event <sig> <body>

Define a simulation event with the specified signature and implemented by the
given body.
"""
macro event(sig, body)
    @capture(sig, f_Symbol(xs__)) ||
        throw(ArgumentError("the first argument must be a signature, " *
                            "given $sig"))

    # XXX: This is ineffective. @event foo() 4 is valid.
    # @capture(body, begin exprs__ end) ||
    #     throw(ArgumentError("the second argument must be a body, " *
    #                         "given $body"))
    # Extract the argument identifiers
    args = [isa(arg, Symbol) ? arg : arg.args[1] for arg in xs]
    quote
        $(esc(sig)) =
            let _argvals = [$(esc.(args)...)] # Build array of argument values
                Event(string($(esc(f))) * "(" * join(string.(_argvals), ", ") * ")",
                      @thunk $(esc(body)))
            end
    end
end
