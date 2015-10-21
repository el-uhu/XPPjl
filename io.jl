export saveModel, loadModel
using JSON

"""
Function to save a model instance to a jsonFile

    saveModel(ModelName, \"jsonFilenameAsString.json\")
"""
function saveModel(M::Model, jsonFile::AbstractString)
    # Save a Dict as json file
    f = open(jsonFile, "w")
    write(f, JSON.json(M))
    close(f)
end

"""
Function to load a model instance from a json file

    M = loadModel(\"jsonFilenameAsString.json\")
"""
function loadModel(jsonFile::AbstractString)
    # Save a Dict as json file
    f = open(jsonFile, "r")
    D = JSON.parse(f)
    Sims = Dict([k => SimulationData(k, D["sims"][k]["I"],D["sims"][k]["P"], D["sims"][k]["D"]) for k in keys(D["sims"])])
    close(f)
    M = Model(D["odes"], D["init"], D["pars"]; name =  D["name"], aux = D["aux"], spec = D["spec"], vars = D["vars"], sims = Sims)
    return(M)
end
