export getReadyForAuto!


auto_default_specs = Dict([
# Dimension of the system of equations as specified in the user-supplied routine FUNC
"NDIM" => 0,
# The number of boundary conditions as specified in the user-supplied routine BCND.
"NBC" => 0,
# The number of integral conditions as specified in the user-supplied routine ICND.
"NINT" => 0,
# Maximum parameter number that can be used in all user-supplied routines.
"NPAR" => 0,
# Used to indicate whether derivatives are supplied by the user or to be obtained by differencing
"JAC" => 0,
# The number of mesh intervals used for discretization.
"NTST" => 50,
# The number of Gauss collocation points per mesh interval, (2 ≤ NCOL ≤ 7).
"NCOL" => 4,
# This constant controls the mesh adaption
"IAD" => 3,
# Relative convergence criterion for equation parameters in the Newton/Chord method.
"EPSL" => 10e-7,
# Relative convergence criterion for solution components in the Newton/Chord method
"EPSU" =>10e-7,
# Relative arclength convergence criterion for the detection of special solutions.
"EPSS" =>10e-5,
# The maximum number of iterations allowed in the accurate location of special solutions,
# such as bifurcations, folds, and user output points, by Müller’s method with bracketing.
"ITMX" => 8,
# After NWTN Newton iterations the Jacobian is frozen, i.e., AUTO uses full Newton for the first
# NWTN iterations and the Chord method for iterations NWTN+1 to ITNW.
"NWTN" => 3,
# The maximum number of combined Newton-Chord iterations
"ITNW" =>5,
# AUTO uses pseudo-arclength continuation for following solution families. The pseudo-arclength
# stepsize is the distance between the current solution and the next solution on a family. By
# default, this distance includes all state variables (or state functions) and all free parameters.
# The constant DS defines the pseudo-arclength stepsize to be used for the first attempted step
# along any family. (Note that if IADS>0 then DS will automatically be adapted for subsequent
# steps and for failed steps.) DS may be chosen positive or negative; changing its sign reverses the
# direction of computation. The relation DSMIN ≤ | DS | ≤ DSMAX must be satisfied. The precise
# choice of DS is problem-dependent; the demos use a value that was found appropriate after some
# experimentation.
"DS" => 0.01,
# This is minimum allowable absolute value of the pseudo-arclength stepsize
"DSMIN" => 0.001,
# The maximum allowable absolute value of the pseudo-arclength stepsize
"DSMAX" =>0.1,
# This constant controls the frequency of adaption of the pseudo-arclength stepsize
"IADS" => 1,
# By default, the pseudo-arclength stepsize includes all state variables (or state functions) and all
# free parameters. Under certain circumstances one may want to modify the weight accorded to
# individual parameters in the definition of stepsize. For this purpose, THL defines the parameters
# whose weight is to be modified. If THL={} then all weights will have default value 1.0, else one
# must enter pairs, {Parameter Index : Weight, ...} .
"THL" => "",
# Under certain circumstances one may want to modify the weight accorded to individual state
# variables (or state functions) in the definition of stepsize. For this purpose, THU defines the
# number of states whose weight is to be modified. If THU={} then all weights will have default
# value 1.0, else one must enter pairs, {State Index : Weight, ...} . At present none of the demos
# use this option.
"THU" => "",
# This constant adds stopping conditions. It is specified as a list of bifurcation type strings fol-
# lowed by a number n greater than zero. These strings specify that the contination should stop
# as soon as the nth bifurcation of the associated type has been reached. Example:
# STOP=[’HB3’,’UZ3’] Stop at the third Hopf bifurcation or third user defined point (see Sec-
# tion 10.9.11), whichever comes first.
"STOP" => "[]",
#The maximum number of steps to be taken along any family.
"NMX" =>200,
# The lower bound on the principal continuation parameter. (This is the parameter which appears
# first in the ICP list; see Section 10.7.1.)
"RLO" =>0,
# The upper bound on the principal continuation parameter
"RL1" =>0,
# The lower bound on the principal solution measure.
"A0" =>0,
# The upper bound on the principal solution measure.
"A1" =>0,
])

function floatFromTerminal()
    return(float(split(readline(STDIN), "\n")[1]))
end

function stringFromTerminal()
    return(split(readline(STDIN), "\n")[1])
end

function getReadyForAuto!(M::Model; specs = auto_default_specs, interactive = true, sol = None)
    M.auto_specs = auto_default_specs
    M.auto_specs["NDIM"] = length(M.odes)
    M.auto_specs["NPAR"] = minimum([length(M.pars), 36])
    if interactive == true
        println("Which parameters do you want to vary?")
        par = stringFromTerminal()
        println("Minimum for this parameter?")
        M.auto_specs["RL0"] = floatFromTerminal()
        println("Maximum for this parameter?")
        M.auto_specs["RL1"] = floatFromTerminal()
        println("What's your prinicpal solution measure?")
        var = stringFromTerminal()
        println("Minimum for this variable?")
        M.auto_specs["A0"] = floatFromTerminal()
        println("Maximum for this variable?")
        M.auto_specs["A1"] = floatFromTerminal()
        println("stepsize (DS)?")
        M.auto_specs["DS"] = floatFromTerminal()
        println("Minimum stepsize (DSMin, absolute value)?")
        M.auto_specs["DSMIN"] = floatFromTerminal()
        println("Maximum stepsize (DSMAX, absolute value)?")
        M.auto_specs["DSMAX"] = floatFromTerminal()
    end
    if sol != None
        parseToAUTO(M, sol)
    end
    return(M)
end
