export toOdeFile, fromOdeFile, parseOutputFile

newline = os[OS_NAME].newline

#-------------------------------------------------------------------------------
#
#                       Parsing XPPjl-model to ODE-file
#
#-------------------------------------------------------------------------------

@doc doc"""
Function for writing a Model-instance to an .ode file

    toOdeFile(ModelInstance)

...will write the model instance to an ode file with the name ModelInstance.name
"""->
function toOdeFile(M::Model)
    file = "#" * M.name * newline * "#generated using XPPjl" * newline * newline * "#ODEs:$newline"
    for r in M.odes
        file *= r[1] * "\'=" * r[2] * newline
    end
    #Algebraic equation automatically also auxvars
    file *= newline * newline * "#Algebraic and auxilliary equations:" * newline
    for a in M.alg
        file *=  a[1] * "=" * a[2] * newline
    end
    for x in M.aux
        file *= "aux " * x[1] * "=" * x[1] * newline
    end
    #Parameters
    file *= newline * newline * "#Parameters:\n"
    for p in M.pars
        file *= "p " * p[1] * "=" * string(p[2]) *newline
    end
    #Initials
    file *= newline * newline * "#Initials:\n"
    for i in M.init
        file *= "init " * i[1] * "=" * string(i[2]) *newline
    end
    #Settings
    file *= newline * newline * "#Settings:\n"
    for s in M.spec
        file *= "@ " * s[1] * "=" * string(s[2]) *newline
    end
    file *= "done" * newline
    f = open(M.name * ".ode", "w")
    write(f, file)
    close(f)
end

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


@doc doc"""
High-level routine for generating a model instance from an existing .ode-file

    ModelName = fromOdeFile(\"odeFilenameAsString.ode\")

Syntax requirements:

    - odes are specified with ' instead of dVar/dt

    - parameters are specified with the 'p '-prefix

    - settings are specified with the '@ '-prefix

    - initial conditions are specified with the 'init '-prefix

    - every line can only contain a single specification, i.e. no concatentation of multiple parameter/initial/setting specifiactions in a single line

"""->
function fromOdeFile(filename::String)
     f = open(filename)
     name = split(filename, ".ode")[1] * "_xppjl"
     M = parseOdeFile(f, name)
     close(f)
     return(M)
end

#-------------------------------------------------------------------------------
#
#                       Parsing ODE-file to XPPjl
#
#-------------------------------------------------------------------------------



#                       Parsing subfunctions
#-------------------------------------------------------------------------------

type ParsedLine
    b::Bool
    name::String
    value::Any
end
function ignore(l)
    b = length(l) < 3 || l[1] == '#' || contains(l, "aux ")  || contains(l, "done")
    name = ""
    value = ""
    return(ParsedLine(b, name, value))
end

function parameter(l)
    b = l[1:2] == "p "
    name = ""
    value = ""
    if b
        parts = split(l, "=")
        name = parts[1][3:end]
        value = float(parts[2])
    end
    return(ParsedLine(b, name, value))
end

function initial(l)
    b = l[1:5] == "init "
    name = ""
    value = ""
    if b
        parts = split(l, "=")
        name = parts[1][6:end]
        value = float(parts[2])
    end
    return(ParsedLine(b, name, value))
end

function method(l)
    b = l[1:2] == "@ "
    name = ""
    value = ""
    if b
        parts = split(l, "=")
        name = parts[1][3:end]
        value = parts[2]
    end
    return(ParsedLine(b, name, value))
end

function variable(l)
    b = split(l, "=")[1][end] == '\''
    name = ""
    value = ""
    if b
        parts = split(l, "=")
        name = parts[1][1:end-1]
        value = parts[2]
    end
    return(ParsedLine(b, name, value))
end

function auxilliary(l)
    b = l[1:4] == "aux "
    name = ""
    value = ""
    if b
        parts = split(l, "=")
        name = parts[1]
        value = parts[2]
    end
    return(ParsedLine(b, name, value))
end

function algebraic(l)
    b = length(split(l, "=")) == 2
    name = ""
    value = ""
    if b
        parts = split(l, "=")
        name = parts[1]
        value = parts[2]
    end
    return(ParsedLine(b, name, value))
end

#                       High-level routine
#-------------------------------------------------------------------------------

@doc doc"""
Function for parsing .ode files that obey the following rules:

    - odes are specified with \' instead of dVar/dt

    - parameters are specified with the 'p '-prefix

    - settings are specified with the '@ '-prefix

    - initial conditions are specified with the 'init '-prefix

    - every line can only contain a single specification, i.e. no concatentation of multiple parameter/initial/setting specifiactions in a single line

"""->
function parseOdeFile(f::IOStream, modelname::String)
    odes = Dict()
    init = Dict()
    pars = Dict()
    aux = Dict()
    alg =Dict()
    spec = Dict()
    vars = Any[]
    for l in eachline(f)
        l = split(string(l), newline)[1];
        if ignore(l).b
            #comment or empty line: do nothing
            #both auxilliary and algebraic equation treated as the same
        elseif parameter(l).b
            pars[parameter(l).name] = parameter(l).value
        elseif initial(l).b
            init[initial(l).name] = initial(l).value
        elseif method(l).b
            spec[method(l).name] = method(l).value
        elseif variable(l).b
            push!(vars, variable(l).name)
            odes[variable(l).name] = variable(l).value
        elseif auxilliary(l).b
            push!(vars, auxilliary(l).name)
            aux[auxilliary(l).name] = auxilliary(l).value
        elseif algebraic(l).b
            alg[algebraic(l).name] = algebraic(l).value
        end
    end
    M = Model(odes, init, pars; name = modelname, aux = aux, alg = alg, spec = spec, vars = vars)
    return(M)
end

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
#
#                       Parsing Output-file to XPPjl
#
#-------------------------------------------------------------------------------


@doc doc"""
Parse output file and store it as new SimulationData-instance in the Model.sims-dict

    SimulationDataInstance = parseOutputFile(file-IOstream, ModelInstance)
"""->
function parseOutputFile(f::IOStream, M::Model, name = false)
    if name == false
        #Get the new key for the dict
        k = length(M.sims) + 1
    else
        #Overwrite the last simulation
        k = name
    end
    #Instantiate new SimulationData-structure
    M.sims[k] = SimulationData(M)
    #loop over lines in file
    for l in eachline(f)
        #Remove newline and space at the end of each line
        l = split(string(l), " \n")[1];
        #Split line to get data points
        pts = split(l, " ");
        #Loop over var-list & append to SimulationData.D-instance based on index
        for v in M.vars
            i = findfirst(M.vars, v)
            push!(M.sims[k].D[v], float(pts[i]))
        end
    end
    return(M)
end

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
