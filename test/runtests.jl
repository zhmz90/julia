# This file is a part of Julia. License is MIT: http://julialang.org/license

include("choosetests.jl")
tests, net_on = choosetests(ARGS)
cd(dirname(@__FILE__)) do
    n = 1
    if net_on
        n = min(8, CPU_CORES, length(tests))
        if n > 1
            set_interconnect(IC_ALL_TO_ALL)
            addprocs(n; exeflags=`--check-bounds=yes`)
        end
    end

    @everywhere include("testdefs.jl")

    reduce(propagate_errors, nothing, pmap(runtests, tests; err_retry=false, err_stop=true))

    @unix_only n > 1 && rmprocs(workers(), waitfor=5.0)
    println("    \033[32;1mSUCCESS\033[0m")
end
