# cellphone.jl
# Cellphone simulation from PySim

# Parameters

Nchannels = 4
maxN = 1_000
lam = 1.0
mu = 0.6667
meanLifeTime = inv(mu)
Nhours = 10
interv = 60.0
gap = 15.0

# Globals

Nfree = Nchannels
totalBusyVisits = 0
totalBusyTime = 0.0
busyStartTime = 0.0
busyEndTime = 0.0

# Statistics

m = nothing
bn = nothing

@process generator(n::Integer) begin
    iatime = inv(lam)
    for i in 1:n
        @schedule now job(i)
        work(rand(Exponential(iatime)))
    end
end

@process job(i::Integer) begin
    global Nfree, totalBusyVisits, totalBusyTime, busyStartTime, busyEndTime
    if Nfree > 0
        Nfree -= 1
        if Nfree == 0
            # Start busy period
            busyStartTime = current_time()
            totalBusyVisits += 1
            interIdleTime = current_time() - busyEndTime
        end
        work(rand(Exponential(inv(mu))))
        if Nfree == 0
            # End busy period
            busyEndTime = current_time()
            busy = current_time() - busy_start_time
            totalBusyTime += busy
        end
        Nfree += 1
    end
end

@process statistician() begin
    global Nfree, totalBusyVisits, totalBusyTime, busyStartTime, busyEndTime
    for i = 1:Nhours
        # Wait the specified gap time
        work(gap)
        # Initialize
        totalBusyTime = 0.0
        totalBusyVisits = 0
        if Nfree == 0
            busyStartTime = current_time()
        end
        # Wait the specified interval time
        work(interv)
        # Trace busy time and busy visits
        if Nfree == 0
            totalBusyTime += current_time() - busyStartTime
        end
        println("$(current_time()): busy time = $totalBusyTime; busy visits = $totalBusyVisits")
        # Tally statistics
        m.value = totalBusyTime
        bn.value = totalBusyVisits
    end
    # Print final statistics
    println("Busy time:   mean = $(m.mean), variance = $(m.variance)")
    println("Busy number: mean = $(bn.mean), variance = $(bn.variance)")
end

@event stop_sim() begin
    stop_simulation()
end

function run_simulation()
    global Nfree, totalBusyVisits, totalBusyTime, busyStartTime, busyEndTime
    global m, bn
    @simulation begin
        # Print parameters
        println("lambda = $lam")
        println("mu     = $mu")
        println("s      = $s")
        println("NHours = $Nhours")
        println("interv = $interv")
        println("gap    = $gap")
        # Initialize the global variables
        Nfree = Nchannels
        totalBusyVisits = 0
        totalBusyTime = 0.0
        busyEndTime = 0.0
        # Create statistics
        m = Variable{Int64}(data=:tally, history=true)
        bn = Variable{Float64}(data=:tally, history=true)
        # Create initial processes and start the execution
        @schedule at 0.0 generator(maxN)
        @schedule at 0.0 statistician()
        @schedule at 10_000.0 stop_sim()
        start_simulation()
    end
end
