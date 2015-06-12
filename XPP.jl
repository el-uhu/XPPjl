module XPP

if VERSION < v"0.4.0"
    using Docile
end

#OS-compatibility
include("os.jl")

#Definition of Core-Types
include("typedefs.jl")

#Parse ODE-Files
include("parse.jl")

#Write model to Auto-compatible f90-file
include("auto_parser.jl")

#Routines for running simulations using XPP
include("run.jl")

#Model I/O - JSON
include("io.jl")

#Plotting Functions
include("plot.jl")

#Utility Functions
include("utils.jl")

end
