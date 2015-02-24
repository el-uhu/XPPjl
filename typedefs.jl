export Model, SimulationData, getVariables


@doc doc"""
Custom type Model, used for specifying dynamical systems model to be simulated using XPP.
Minimal requirement: Dict of odes, dict of initial conditions, dict of parameters, model name.
Auxilliary equations or algebraic equations are both by default.
Provides interface for reading from an ode file, writing the model to an ode file.
Furthermore the model, along with simulations can be stored in, and loaded from a json file

Instantiation:

    ModelName = Model(odeDict, initialConditionsDict, parameterDict, modelName)

    ModelName = Model(odeDict, initialConditionsDict, parameterDict, modelName, auxDict)

    ModelName = Model(odeDict, initialConditionsDict, parameterDict, modelName, auxDict, settingsDict)
"""->
type Model
    odes::Dict #Dict that stores the odes
    init::Dict #Dict that stores the initial conditions
    pars::Dict #Dict that stores parameters
    name::String #Model name, used for writing ode, json
    aux::Dict #Auxilliary eqn / algebraic eqn.
    spec::Dict #settings
    vars::Array{Any,1} #Variables
    sims::Dict #Dict that stores simulations
end
#Instantiate model from minimal set of definitions (odes, initials, parameters, name)
Model(odes::Dict, init::Dict, pars::Dict, name::String) = Model(odes, init, pars, name*".ode", Dict(), Dict(), getVariables(odes, Dict()), Dict())
#...instantiate from minimal set of definitions +auxilliary equations
Model(odes::Dict, init::Dict, pars::Dict, name::String, aux::Dict) = Model(odes, init, pars, name*".ode", aux, Dict(), getVariables(odes, aux), Dict())
#...instantiate from minimal set of definitions + auxilliary equations + specifications
Model(odes::Dict, init::Dict, pars::Dict, name::String, aux::Dict, spec::Dict) = Model(odes, init, pars, name*".ode", aux, spec, getVariables(odes, aux), Dict())

Model(odes::Dict, init::Dict, pars::Dict, name::String, aux::Dict, spec::Dict, vars::Array) = Model(odes, init, pars, name*".ode", aux, spec, vars, Dict())

@doc doc"""
Simple function to  obtain a list of dynamical and auxilliary variables, which determines the handling of simulation data
"""->
function getVariables(M::Model)
    v = [k for k in keys(M.odes)]
    append!(v,[k for k in keys(M.aux)])
    return(v)
end

@doc doc"""
Custom type SimulationData serves as a datastructure to store data from timecourse simulations along with the initial conditions and the parameterset used in the simulation

Instantiation:

    D = SimulationData(initialConditionsDict, parameterDict, dataDict)
"""->
type SimulationData
    I::Dict
    P::Dict
    D::Dict
end
function SimulationData(M::Model)
    I = M.init
    P = M.pars
    D = Dict([v => [] for v in M.vars])
    return(SimulationData(I, P, D))
end
