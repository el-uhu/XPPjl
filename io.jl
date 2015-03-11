export saveModel, loadModel
using JSON

@doc doc"""
Function to save a model instance to a jsonFile

    saveModel(ModelName, \"jsonFilenameAsString.json\")
"""->
function saveModel(M::Model, jsonFile::String)
    # Save a Dict as json file
    f = open(jsonFile, "w")
    write(f, JSON.json(M))
    close(f)
end

@doc doc"""
Function to load a model instance from a json file

    M = loadModel(\"jsonFilenameAsString.json\")
"""->
function loadModel(jsonFile::String)
    # Save a Dict as json file
    f = open(jsonFile, "r")
    D = JSON.parse(f)
    Sims = Dict([k => SimulationData(D["sims"][k]["I"], D["sims"][k]["P"], D["sims"][k]["D"]) for k in keys(D["sims"])])
    close(f)
    M = Model(D["odes"], D["init"], D["pars"], D["name"], D["aux"], D["spec"], D["vars"], Sims)
    return(M)
end
