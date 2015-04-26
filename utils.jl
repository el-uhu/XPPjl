export checkpoint!, restoreModel!, continueSim!

function checkpoint!(M)
    for s in [:pars, :init, :spec]
        M.originalState[s] = deepcopy(M.(s))
    end
    return(M)
end

function restoreModel!(M)
    for s in [:pars, :init, :spec]
        M.(s) = deepcopy(M.originalState[s])
    end
    return(M)
end

function continueSim!(M, t1, t2, name, inits2, pars2)
    M.spec["total"] = t1
    n1 = name * "_1"
    n2 = name * "_2"
    runSimulation!(M, n1)
    M.init = Dict([v => M.sims[n1].D[v][end] for v in keys(M.odes)])
    if inits2 != false
        for k in keys(inits2)
            M.init[k] = inits2[k]
        end
    end
    M.pars = pars2
    M.spec["total"] = t2
    runSimulation!(M, n2)
    M.sims[n2].D["t"] = M.sims[n2].D["t"] + t1
    M.sims[name] = SimulationData(M)
    for v in keys(M.sims[name].D)
        append!(M.sims[name].D[v], M.sims[n1].D[v])
        append!(M.sims[name].D[v], M.sims[n2].D[v])
    end
    restoreModel!(M)
    return(M)
end
