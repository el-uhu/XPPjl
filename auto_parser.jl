export parseToAUTO

#Custom type to hold f90-code components
type f90_subroutine
    name::AbstractString
    args::AbstractString
    header::AbstractString
end

#Function that returns a sequence of all numerical arguments of the model
function declareNumericalArguments(M::Model)
    declare = "\tDOUBLE PRECISION "
    for var in keys(M.odes)
        declare *= var * ", "
    end
    for alg in keys(M.alg)
        declare *= alg * ", "
    end
    for par in keys(M.pars)
        declare *= par * ", "
    end
    declare *= "\n"
    return(declare)
end

#Parse algebraic equations
function parseAlgs(M::Model)
    parsed = ""
    for a in keys(M.alg)
        eq = M.alg[a]
        parsed *= "\t$a = $eq\n"
    end
    return(parsed)
end

#Parse Variables (declaration)
function parseVars(M::Model)
    parsed = ""
    for var in enumerate(keys(M.odes))
        var_name = var[2]
        var_i = var[1]
        parsed *= "\t$var_name = U($var_i)\n"
    end
    return(parsed)
end

#Parse singular point solutions for variables
function parseVarsPt(M::Model, values)
    parsed = ""
    for var in enumerate(keys(M.odes))
        var_i = var[1]
        var_val = values[var_i]
        parsed *= "\tU($var_i)=$var_val\n"
    end
    return(parsed)
end

#Parse parameters (declaration)
function parsePars(M::Model)
    parsed = ""
    for par in enumerate(keys(M.pars))
        par_name = par[2]
        par_i = par[1]
        parsed *= "\t$par_name = P($par_i)\n"
    end
    return(parsed)
end

#Parse parameter set corresponding to singular point solutions
function parseParsPt(M::Model)
    parsed = ""
    for par in enumerate(keys(M.pars))
        par_i = par[1]
        par_val = M.pars[par[2]]
        parsed *= "\tP($par_i)=$par_val\n"
    end
    return(parsed)
end

#Assemble f90 subroutines (generic)
function assembleSubroutine(routine::f90_subroutine, body::AbstractString)
    name = routine.name
    args = routine.args
    header = routine.header
    footer = "END SUBROUTINE $name"
    if header == ""
        R = "SUBROUTINE $name\n$footer\n"
    else
        R = "SUBROUTINE $name($args)\n$header\n$body\n$footer"
    end
    return(R)
end

#Assemble subroutines specifically
function parseSubroutine(routine_name, header_table, M::Model, values)
    if routine_name == "FUNC"
        body = "\n" * declareNumericalArguments(M) * "\n" * parseAlgs(M) * "\n" *  parseVars(M) * "\n" * parsePars(M)
    elseif routine_name == "STPNT"
        body = "\n" * parseParsPt(M) * "\n" *parseVarsPt(M, values)
    else
        body = ""
    end
    return(assembleSubroutine(header_table[routine_name], body))
end

#Top-level wrapper function for parsing model to f90-file
function parseToAUTO(M::Model, values, header_table = f90_header_table)
    parsed = "!--------------------------------------\n!\tGenerated with XPPjl\n!--------------------------------------\n\n"
    for routine_name in keys(header_table)
        parsed *= parseSubroutine(routine_name, header_table, M, values) * "\n\n"
    end
    model_name = M.name
    f = open(model_name * ".f90", "w")
    print(parsed)
    write(f, parsed)
    close(f)

    #Make parameter file
    pars = ""
    for p in keys(M.auto_specs)
        pars *= p * "= " * string(M.auto_specs[p]) * ", "
    end
    println(pars)
    f = open("c."*model_name, "w")
    write(f, pars)
    close(f)
end

f90_header_table= Dict(
    "FUNC" => f90_subroutine(
        "FUNC",
        "NDIM,U,ICP,PAR,IJAC,F,DFDU,DFDP",
        "\tIMPLICIT NONE
        INTEGER, INTENT(IN) :: NDIM, ICP(*), IJAC
        DOUBLE PRECISION, INTENT(IN) :: U(NDIM), PAR(*)
        DOUBLE PRECISION, INTENT(OUT) :: F(NDIM)
        DOUBLE PRECISION, INTENT(INOUT) :: DFDU(NDIM,NDIM), DFDP(NDIM,*)",
        ),
    "STPNT" => f90_subroutine(
        "STPNT",
        "NDIM,U,PAR,T",
        "\tIMPLICIT NONE
        INTEGER, INTENT(IN) :: NDIM
        DOUBLE PRECISION, INTENT(INOUT) :: U(NDIM),PAR(*)
        DOUBLE PRECISION, INTENT(IN) :: T"
        ),
    "BCND" => f90_subroutine("BCND", "", ""),
    "ICND" => f90_subroutine("ICND", "", ""),
    "FOPT" => f90_subroutine("FOPT", "", ""),
    "PVLS" => f90_subroutine("PVLS", "", ""),
    )
