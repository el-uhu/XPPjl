export runSimulation!, simulate!

@doc doc"""
Function for running a simulation from the current model definition and parsing the output data into new SimulationData-structure

    ModelInstance = runsimulation(ModelInstance)
"""->
function runSimulation!(M::Model, name; plot = false, pars = false, vars = false, xlim = false, ylim =false, colors = false, linewidth = 2)
    # Save current version of mpdel to odefile
    toOdeFile(M)
    #Update the vars list to match the order in the ode file
    M.vars = getVariables(M)
    #Run the simulation
    odefile = M.name * ".ode"
    xppcall = os[OS_NAME].xppcall
    options = os[OS_NAME].options
    run(`$xppcall $odefile $options`)
    #Open and parse output file into new SimulationData-structure
    f = open("output.dat")
    M = parseOutputFile(f, M, name)
    close(f)
    if plot
        plotModel(M, name; pars = pars, vars = vars, xlim = xlim, ylim = ylim, colors =colors, linewidth = linewidth)
    end
    run(`rm output.dat`)
    n = M.name
    run(`rm $n.ode`)
    run(`rm log.txt`)
end

"""
Simulate the system using ODE.jl package
"""
function simulate!(M::Model, name, trange; solver = ode23s, plot = false, pars = false, vars = false, xlim = false, ylim =false, colors = false, linewidth = 2)
    #Update parameters
    p = Float64[M.pars[p] for p in M.p_names]
    #Update initials
    y0 = Float64[M.init[y] for y in M.y_names]
    #Convert F into necessary form (only dependent on t and y)
    F(t,y) = M.F(t, y, p)
    #Uses ode23s by default for other available solver consult ODE module: https://github.com/JuliaLang/ODE.jl
    t,y = solver(F, y0, trange)
    if plot != false
        plotModel(M, name; pars = pars, vars = vars, xlim = xlim, ylim = ylim, colors =colors, linewidth = linewidth)
    end
    #Retrieve results
    M = parseODEOutput(t, y, M, name)
    return(M)
end

"""
Get vectorised output and store it in SimulationData structure
"""
function parseODEOutput(t, ysim, M::Model, name)
    if name == false
        #Get the new key for the dict
        k = length(M.sims) + 1
    else
        #Overwrite the last simulation
        k = name
    end
    #Instantiate new SimulationData-structure
    M.sims[k] = SimulationData(M, name)
    M.sims[k].D["t"] = t
    for (i,y) in enumerate(M.y_names)
      M.sims[k].D[y] = [y[i] for y in ysim]
    end
    return(M)
end
