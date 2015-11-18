# XPPjl
### Toolkit for modelling of dynamical systems in Julia

XPPjl is a julia module that facilitates modelling of dynamical systems in julia.
It started out as a simple interface to allow programmatic access to modelling in Bart Ermentrout's software [XPPAut](http://www.math.pitt.edu/~bard/xpp/xpp.html), but now also includes options for simulating dyamical systems in pure julia.

###Functionality
* Represent models as flexible custom data types in julia
* Simulate dynamical systems using XPPAuto or in pure julia (using ODE-Module)
* Store simulation data in easily accessible and well-defined way
* Save models along with simulations (data + parameters) as json files
* Import saved models

###Planned features
* AUTO integration

##XPP-Interface

XPP uses text-files - so called [ODE-files](http://www.math.pitt.edu/~bard/bardware/tut/xpptut.html#odefile) to specify mathematical models. In most cases, these ODE-files specify systems of ordinary differential equations (ODEs), along with definitions of parameters, initial conditions and settings for the numerical solver, but can also be used for stochastic simulations based on [Gillespie's algorithm](https://en.wikipedia.org/wiki/Gillespie_algorithm).

XPPjl allows for programmatic access to modelling routines in XPP by parsing ODE-Files into julia and representing them as `Model`-Types:

```julia
type Model
    odes::Dict #Dict that stores the odes
    init::Dict #Dict that stores the initial conditions
    pars::Dict #Dict that stores parameters
    name::AbstractString #Model name, used for writing ode-files and json
    aux::Dict #Auxilliary eqn
    alg::Dict #Algebraic eqn.
    spec::Dict #XPP settings
    vars::Array{Any,1} #Variables
    sims::Dict #Dict that stores simulations

    #Vector representation of the model
    #....
    F::Function #System of equations
    y_names::Array{AbstractString,1} #Array of variable names
    A::Function #Vectroised algebraic equations
    a_names::Array{AbstractString,1} #Names of algebraic equations
    y0::Array{Float64,1} #Vector of initial states
    p_names::Array{AbstractString,1} #Array of parameter names
    p::Array{Float64,1} #Array of parameters

    originalState::Dict #Store original state of model

    #Under development
    auto_specs::Dict#Store Parameters required for running AUTO
end
```

Exposed this way in julia, the properties of models can be changed programatically and a series of simulations can be run and managed from julia.  

```julia
#Load CaChannel-example from ODE-file
M = fromOdeFile("CaChannel.ode");

#Run simulations from a set of different initial conditions
for v in [-60, -40, -20]
  M.init["v"] = v
  runSimulation!(M, "running from v(0) = $v")
end
```

This changes the definition of the initial state of the model, writes a temporary ODE-file `ModelName_xppjl.ode`, prompts XPP to run in *silent* mode (i.e. without GUI), and instructs XPP to save the simulation data in a temporary `output.dat`-file. Once the simulation is finished, XPPjl will read the output file and store the data as a `SimulationData` - type, that is stored in the field `M.sims["SimulationName"]` of the model:

```julia
type SimulationData
    N::AbstractString #Simulation name
    I::Dict # Dict of initial conditions used in the simulation
    P::Dict # Dict of parameters used in the simulation
    D::Dict # Dict of data-vectors generated in the simulations (variables and auxilliary variables)
end
```
Hence, the simulation data become a natural part of the model-instance.

For convenience, XPPjl provides functions for saving whole model objects as json-files, plotting functions, and a comprehensive default printing routine to provide an overview of the model in the REPL:

```julia
#Show model
M

#Save model as json-file
saveModel(M, "myModel.json")

#Load a model from json, instead of ode
M2 = loadModel("myModel.json")

#Plot model
plotModel(M, "running from -40", vars = ["v"], colors = ["v" => "g"])
```

##Running simulations in pure julia
When performing many simulations repeatedly, as when using parameter optimisation algorithms, file I/O becomes limiting for the execution speed. Therefore, XPPjl provides functionality to simulate models in pure julia, using the [ODE-Module](https://github.com/JuliaLang/ODE.jl). Upon instantiation, models defined in an ODE-file, or exported json-models are automatically converted into vectorised form (Fields `F`, `y_names`, `A`, `a_names`, `y0`, `p_names`, `p` of the `Model`-type)

```julia
type Model
    odes::Dict #Dict that stores the odes
    init::Dict #Dict that stores the initial conditions
    pars::Dict #Dict that stores parameters
    name::AbstractString #Model name, used for writing ode-files and json
    aux::Dict #Auxilliary eqn
    alg::Dict #Algebraic eqn.
    spec::Dict #XPP settings
    vars::Array{Any,1} #Variables
    sims::Dict #Dict that stores simulations

    #Vector representation of the model
    #....
    F::Function #System of equations
    y_names::Array{AbstractString,1} #Array of variable names
    A::Function #Vectroised algebraic equations
    a_names::Array{AbstractString,1} #Names of algebraic equations
    y0::Array{Float64,1} #Vector of initial states
    p_names::Array{AbstractString,1} #Array of parameter names
    p::Array{Float64,1} #Array of parameters

    originalState::Dict #Store original state of model

    #Under development
    auto_specs::Dict#Store Parameters required for running AUTO
end
```

Calling `simulate!` instead of `runSimulation!` will use pure julia to solve the system numerically:

```julia
#Load CaChannel-example from ODE-file
M = fromOdeFile("CaChannel.ode");
trange = collect(0:0.1:50)

simulate!(M, "SimulationName", trange)
```

The default solver is `ode23s`. Custom solvers can be specified using the optional argument `solver`.

###Structure of the module

* `XPP.jl` - main module file for module `XPP` , wraps around the following components
* `typedefs.jl` - type specification for two custom types:
  * `Model` - a structured representation of an XPP-model, including, ODEs, Initials, Parameters, Settings, Auxilliaries and Data
  * `SimulationData` - A datastructure that stores data from simulations generated by XPP with the corresponding variable names, initial conditions and parameters.
* `parse.jl` - functions used for importing a Model-instance from an ode-file, generating an ode-file from a model instance and parsing the output of XPP-simualtions into a SimulationData-structure.
* `run.jl` - routine for running a simulation of a model in XPPAut, and processing the output
* `io.jl` - functions for storing a model instance (including simulations) as a json file, as well as loading a model instance from such a json file
