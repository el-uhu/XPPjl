type f90_subroutine
    name::String
    args::String
    header::String
end

function declareNumericalArguments(M)
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

function parseAlgs(M)
    parsed = ""
    for a in keys(M.alg)
        eq = M.alg[a]
        parsed *= "\t$a = $eq\n"
    end
    return(parsed)
end

function parseVars(M)
    parsed = ""
    for var in enumerate(keys(M.odes))
        var_name = var[2]
        var_i = var[1]
        parsed *= "\t$var_name = U($var_i)\n"
    end
    return(parsed)
end

function parseVarsPt(M, values)
    parsed = ""
    for var in enumerate(keys(M.odes))
        var_i = var[1]
        var_val = values[var_i]
        parsed *= "\tU($var_i)=$var_val\n"
    end
    return(parsed)
end

function parsePars(M)
    parsed = ""
    for par in enumerate(keys(M.pars))
        par_name = par[2]
        par_i = par[1]
        parsed *= "\t$par_name = P($par_i)\n"
    end
    return(parsed)
end

function parseParsPt(M)
    parsed = ""
    for par in enumerate(keys(M.pars))
        par_i = par[1]
        par_val = M.pars[par[2]]
        parsed *= "\tP($par_i)=$par_val\n"
    end
    return(parsed)
end

function assembleSubroutine(routine::f90_subroutine, body::String)
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

function parseSubroutine(routine_name, header_table, M, values)
    if routine_name == "FUNC"
        body = "\n" * declareNumericalArguments(M) * "\n" * parseAlgs(M) * "\n" *  parseVars(M) * "\n" * parsePars(M)
    elseif routine_name == "STPNT"
        body = "\n" * parseParsPt(M) * "\n" *parseVarsPt(M, values)
    else
        body = ""
    end
    return(assembleSubroutine(header_table[routine_name], body))
end

function parseToAUTO(M, values, header_table)
    parsed = "!-------------------\n !\tGenerated with XPPjl\n"
    for routine_name in keys(header_table)
        parsed *= parseSubroutine(routine_name, header_table, M, values) * "\n\n"
    end
    model_name = M.name
    f = open(model_name * ".f90", "w")
    print(parsed)
    write(f, parsed)
    close(f)
end

fortranHF = Dict([
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
    ])
