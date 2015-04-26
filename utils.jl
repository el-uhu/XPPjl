export restoreModel!, continueSim!

function restoreModel!(M)
    for s in [:pars, :init, :spec]
        M.(s) = M.originalState[s]
    end
end

function continueSim!(M, t1, t2, name, inits2, pars2)
    original_pars = deepcopy(M.pars)
    original_inits = deepcopy(M.init)
    original_spec = deepcopy(M.spec)
    M.spec["total"] = t1
    n1 = name * "_1"
    n2 = name * "_2"
    runSimulation!(M, n1)
    M.init = inits2
    M.pars = pars2
    M.spec["total"] = t2
    runSimulation!(M, n2)
    M.sims[n2].D["t"] = M.sims[n2].D["t"] + t1
    M.sims[name] = SimulationData(M)
    for v in keys(M.sims[name].D)
        append!(M.sims[name].D[v], M.sims[n1].D[v])
        append!(M.sims[name].D[v], M.sims[n2].D[v])
    end
    M.pars = original_pars
    M.init = original_inits
    M.spec = original_spec
    return(M)
end
