export runSimulation!

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
end
