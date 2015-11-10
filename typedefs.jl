export Model, SimulationData, getVariables, show

import Base.show

global t,y,p

function vectorise_model(odes::Dict, pars::Dict, alg::Dict, init::Dict, aux::Dict)
  v_odes = [v for (k,v) in odes]
  var_names = AbstractString[]
  y0 = Float64[]
  par_names = AbstractString[]
  par_values = Float64[]
  v_aux = [v for (k,v) in aux]
  a_names = [k for (k,v) in aux]

  #Get parameter list
  for (n,p) in enumerate(keys(pars))
    par_names = [par_names; p]
    par_values = [par_values; pars[p]]
  end

  #Vectorise odes
  for (i,k) in enumerate(keys(odes))
    var_names = [var_names; k]
    #Substitute algebraics
    for (n,p) in enumerate(keys(alg))
      v_odes[i] = replace(v_odes[i], Regex("\\b" * p * "\\b"), "($(alg[p]))")
    end
    #Substitute parameters
    for (n,p) in enumerate(keys(pars))
      v_odes[i] = replace(v_odes[i], Regex("\\b" * p * "\\b"), "p[$n]")
    end
    #Substitute variable names
    for (n,p) in enumerate(keys(odes))
      v_odes[i] = replace(v_odes[i], Regex("\\b" * p * "\\b"), "y[$n]")
    end
    # Add initial
    y0 = [y0; init[k]]
  end

  #Vectorise auxs
  for (i,k) in enumerate(a_names)
    #Substitute algebraics
    for (n,p) in enumerate(keys(alg))
      v_aux[i] = replace(v_aux[i], Regex("\\b" * p * "\\b"), "($(alg[p]))")
    end
    #Substitute parameters
    for (n,p) in enumerate(keys(pars))
      v_aux[i] = replace(v_aux[i], Regex("\\b" * p * "\\b"), "p[$n]")
    end
    #Substitute variable names
    for (n,p) in enumerate(keys(odes))
      v_aux[i] = replace(v_aux[i], Regex("\\b" * p * "\\b"), "y[$n]")
    end
  end

  v_aux = [eval(parse("a_$i" * "(t,y,p) = " * v )) for (i,v) in enumerate(v_aux)]
  A(t,y,p) = Float64[ai(t,y,p) for ai in v_aux]

  v_odes = [eval(parse("y_$i" * "(t,y,p) = " * v )) for (i,v) in enumerate(v_odes)]
  F(t,y,p) = Float64[yi(t,y,p) for yi in v_odes]
  return(F, var_names, A, a_names, y0, par_names, par_values)
end


"""
Custom type Model, used for specifying dynamical systems model to be simulated using XPP.
Minimal requirement: Dict of odes, dict of initial conditions, dict of parameters, model name.
Auxilliary equations or algebraic equations are both by default.
Provides interface for reading from an ode file, writing the model to an ode file.
Furthermore the model, along with simulations can be stored in, and loaded from a json file

Instantiation:

    ModelName = Model(odeDict, initialConditionsDict, parameterDict; modelName = "myName", ...)

"""
type Model
    odes::Dict #Dict that stores the odes
    init::Dict #Dict that stores the initial conditions
    pars::Dict #Dict that stores parameters
    name::AbstractString #Model name, used for writing ode, json
    aux::Dict #Auxilliary eqn
    alg::Dict #Algebraic eqn.
    spec::Dict #settings
    vars::Array{Any,1} #Variables
    sims::Dict #Dict that stores simulations
    F::Function
    y_names::Array{AbstractString,1}
    A::Function
    a_names::Array{AbstractString,1}
    y0::Array{Float64,1}
    p_names::Array{AbstractString,1}
    p::Array{Float64,1}
    originalState::Dict #Store original state of model
    auto_specs::Dict#Store Parameters required for running AUTO
end
vectorise_model(M::Model) = vectorise_model(M.odes, M.pars, M.alg, M.init)
#Instantiate model from minimal set of definitions (odes, initials, parameters, name)
function Model(odes::Dict, init::Dict, pars::Dict; name = "myModel", aux = Dict(),
               alg = Dict(), spec = Dict(), vars = [], sims = Dict(),
               originalState = Dict(), auto_specs = auto_default_specs)

  F, y_names, A, a_names, y0, p_names, p = vectorise_model(odes, pars, alg, init, aux)
  return Model(odes, init, pars, name, aux, alg, spec, vars, sims, F, y_names, A, a_names,y0, p_names, p, originalState, auto_specs)
end


"""
Simple function to  obtain a list of dynamical and auxilliary variables, which determines the handling of simulation data
"""
function getVariables(M::Model)
    v = ["t"]
    append!(v,[k for k in keys(M.odes)])
    append!(v,[k for k in keys(M.aux)])
    return(v)
end

function show(io::IO, M::Model)
    println(M.name)
    println("-"^60)
    println("ODES:")
    for var in keys(M.odes)
        println("\t$var = ", M.odes[var])
    end
    if length(M.alg) > 0
        println("-"^60)
        println("ALGEBRAIC EQUATIONS:")
        for alg in keys(M.alg)
            println("\t$alg = ", M.alg[alg])
        end
    end
    if length(M.aux) > 0
        println("-"^60)
        println("AUXILLIARY VARIABLES:")
        for aux in keys(M.aux)
            println("\t$aux = ", M.aux[aux])
        end
    end
    println("-"^60)
    println("INITIALS:")
    for var in keys(M.init)
        println("\t$var:\t", M.init[var])
    end
    println("-"^60)
    println("PARAMETERS:")
    for par in keys(M.pars)
        println("\t$par:", alignSpace(par, 15), M.pars[par])
    end
    println("-"^60)
    println("SETTINGS:")
    for spec in keys(M.spec)
        println("\t$spec:\t", M.spec[spec])
    end
    if length(M.sims) > 0
        println("-"^60)
        println("SIMULATIONS:")
        for sim in keys(M.sims)
            println("\t$sim")
        end
    end
    println("="^60)
end

"""
Custom type SimulationData serves as a datastructure to store data from timecourse simulations along with the initial conditions and the parameterset used in the simulation

Instantiation:

    D = SimulationData(initialConditionsDict, parameterDict, dataDict)
"""
type SimulationData
    N::AbstractString
    I::Dict
    P::Dict
    D::Dict
end
function SimulationData(M::Model, name)
    N = name
    I = deepcopy(M.init)
    P = deepcopy(M.pars)
    D = deepcopy(Dict([v => Any[] for v in M.vars]))
    return(SimulationData(N, I, P, D))
end

function show(io::IO, S::SimulationData)
    println(S.N)
    println("-"^60)
    println("INITIALS:")
    for var in keys(S.I)
        println("\t$var:\t", S.I[var])
    end
    println("-"^60)
    println("PARAMETERS:")
    for par in keys(S.P)
        println("\t$par:", alignSpace(par, 15), S.P[par])
    end
    println("-"^60)
    println("DATA:")
    println("\tt_max:\t", S.D["t"][end])
    println("="^60)
end

function alignSpace(myString::AbstractString, maxSpace)
    n = 40 - length(myString)
    return(" "^n)
end
