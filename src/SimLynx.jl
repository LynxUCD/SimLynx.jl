# SimLynx/src/SimLynx.jl
# Licensed under the MIT License. See LICENSE.md file in the project root for
# full license information.

__precompile__()

"A Hybrid Simulation Engine and Language in Julia"
module SimLynx

import Base: wait

using Plots
using Printf
using MacroTools

# Application Program Interface (API)
#
# These are the exported elements of SimLynx needed to run all of the examples
# for v0.5.0. We may need to export additional elements in the future -
# particularly for things like statistics and histories.

# notice.jl
export Notice

# event.jl
export Event
export @event

# activity.jl (future use)

# process.jl
export Process
export process_store
export process_store!
export @process

# simulation.jl
export current_trace
export current_trace!
export current_time
export current_notice
export current_process
export current_process_store
export current_process_store!
export @simulation

# control.jl
export @schedule
export wait
export work
export start_simulation
export stop_simulation
export suspend
export interrupt
export resume

# rendezvous.jl
export @accept
export @send

# variable.jl
export Variable
export plot_history
export print_stats

# queue.jl
export Queue
export FifoQueue
export LifoQueue
export add!
export remove!
export enqueue!
export dequeue!

# resource.jl
export Resource
export request
export release
export @with_resource

# SimLynx.jl (this file)
export greet
export seed

"Print the SimLynx greeting."
function greet()
    println(raw"""
                           _____ _           _                        _ _
          `\.      ,/'    /  ___(_)         | |                      (_) |
           |\\____//|     \ `--. _ _ __ ___ | |    _   _ _ __ __  __  _| |
           )/_ `' _\(      `--. \ | '_ ` _ \| |   | | | | '_ \\ \/ / | | |
          ,'/-`__'-\`\    /\__/ / | | | | | | |___| |_| | | | |>  < _| | |
          /. (_><_) ,\    \____/|_|_| |_| |_\_____/\__, |_| |_/_/\_(_) |_|
          '`)/`--'\(`'                              __/ |           _/ |
            '      '                               |___/           |__/

        A Hybrid Simulation Engine and Language in Julia
        SimLynx.jl Version 0.5.0 2020-12-15
        University of Colorado in Denver
        Dr. Doug Williams, Anthony Dupont, Trystan Kaes
        """)
end

"""
    @thunk ex

Return a thunk (i.e., a function with no arguments) that executes the expression
when called. This is (currently) only used by the @event macro but may be useful
elsewhere in the future. So, we have it here at the top-level.
"""
macro thunk(ex)
    :(() -> $(esc(ex)))
end

# Abstract data type declarations

abstract type ActiveElement end
abstract type AbstractMessage end

include("notice.jl")

# Include the active elements

include("event.jl")
include("activity.jl")
include("process.jl")

# Include the simulation framework

include("simulation.jl")
include("control.jl")
include("rendezvous.jl")
include("variable.jl")
include("queue.jl")
include("resource.jl")

"Helper function to initialize random seeds."
function seed(int::Integer...)::Array{UInt32, 1}
    return [UInt32(s) for s in [int...]]
end

end # module
