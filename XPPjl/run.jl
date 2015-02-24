export runSimulation

@doc doc"""
Function for running a simulation from the current model definition and parsing the output data into new SimulationData-structure
"""->
function runSimulation(M::Model)
    # Save current version of mpdel to odefile
    toOdeFile(M)
    #Update the vars list to match the order in the ode file
    M.vars = getVariables(M)
    #Run the simulation
    odefile = M.name
    run(`xppaut $odefile -silent`)
    #Open and parse output file into new SimulationData-structure
    f = open("output.dat")
    M = parseOutputFile(f, M)
    close(f)
    return(M)
end
