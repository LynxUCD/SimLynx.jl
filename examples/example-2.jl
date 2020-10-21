# example-2.jl
# Example simulation model

#=
Like example-1.jl but using @event instead of @process for the generate
functionality. Also uses the (experimental) trace functionality.

To Do:
--- (1)
We get the following error when we use
'using Distributions: Exponential, Uniform'
but not when we use
'using Distributions'

ERROR: LoadError: TaskFailedException:
UndefVarError: Distributions not defined
Stacktrace:
 [1] macro expansion at C:\Users\doug\Develop\SimLynx\example-2.jl:23 [inlined]
 [2] (::var"#26#28"{Int64})() at C:\Users\doug\Develop\SimLynx\SimLynx.jl:41
 [3] start_simulation() at C:\Users\doug\Develop\SimLynx\SimLynx.jl:349
 [4] macro expansion at C:\Users\doug\Develop\SimLynx\example-2.jl:41 [inlined]
 [5] macro expansion at C:\Users\doug\Develop\SimLynx\SimLynx.jl:246 [inlined]
 [6] (::var"#33#34")() at .\task.jl:356
Stacktrace:
 [1] wait at .\task.jl:267 [inlined]
 [2] macro expansion at C:\Users\doug\Develop\SimLynx\SimLynx.jl:251 [inlined]
 [3] run_simulation() at C:\Users\doug\Develop\SimLynx\example-2.jl:37
 [4] top-level scope at C:\Users\doug\Develop\SimLynx\example-2.jl:49
 [5] include_string(::Function, ::Module, ::String, ::String) at .\loading.jl:1088
in expression starting at C:\Users\doug\Develop\SimLynx\example-2.jl:49
--- (1)
=#

include("../src/simlynx.jl")

using Distributions
using Random

const N_TELLERS = 2
const N_CUSTOMERS = 10

tellers = nothing

"Generate the ith customer and schedule the next arrival."
@event generate(i::Integer) begin
    if i <= N_CUSTOMERS
        @schedule now customer(i)
        @schedule in rand(Distributions.Exponential(4.0)) generate(i + 1)
    end
end

"The ith customer into the system."
@process customer(i::Integer) begin
    dist = Distributions.Uniform(2.0, 10.0)
    @with_resource tellers begin
        work(rand(dist))
    end
end

"Run the simulation."
function run_simulation()
    @with_new_simulation begin
        current_trace!(true)
        global tellers = Resource(N_TELLERS, "tellers")
        @schedule at 0.0 generate(1)
        start_simulation()
        print_stats(tellers.allocated, "Allocated Statistics")
        print_stats(tellers.queue_length, "Queue Length Statistics")
        plot_history(tellers.queue_length, "queue_length.png",
            "Queue Length History")
    end
end

run_simulation()
