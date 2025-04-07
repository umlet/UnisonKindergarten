#!/usr/bin/env julia


using OrderedCollections
using JSON


using CommandLiner: getopt, getarg, getargs, @mn, erroruser


# TODO: 
# use expicit structs
# make cmd part of ret value, so nice error/errorassert on those structs possible
module Exey
    struct ResultFast
        rc::Int64
        out::String
        err::String
        ok::Bool
        error::Bool
        cmd::Cmd
    end
    struct ResultFull
        rc::Int64
        out::String
        err::String
        ok::Bool
        error::Bool
        outs::Vector{String}
        errs::Vector{String}
        out1::Union{String, Nothing}
        cmd::Cmd
    end

    function debug(R::Union{ResultFast, ResultFull})
        s = "exe: system command:\n$(string(R.cmd))\nexited with code $(R.rc)\n---stdout:---\n$(R.out)\n---stderr:---\n$(R.err)"
        return s
    end

    function exe(cmd::Cmd; fail::Bool=false, okexits::Vector{Int64}=Int64[], fast::Bool=false)
        bufout = IOBuffer()                                                     ; buferr = IOBuffer()
        process = run(pipeline(ignorestatus(cmd), stdout=bufout, stderr=buferr))
        rc::Int64 = process.exitcode
        
        out::String = String(take!(bufout))                                     ; err::String = String(take!(buferr))
        close(bufout)                                                           ; close(buferr)

        ok::Bool = rc == 0  ||  rc in okexits
        _error::Bool = !ok
        if fail  &&  _error
            error("exe: OS system command:\n'$(join(cmd.exec, " "))'\nfailed with exitcode $(rc) => stderr output:\n$(err)")
        end

        fast  &&  return ResultFast(rc, out, err, ok, _error, cmd)

        outs::Vector{String} = eachline(IOBuffer(out)) |> collect               ; errs::Vector{String} = eachline(IOBuffer(err)) |> collect
        out1::Union{String, Nothing} = isempty(outs)  ?  nothing  :  first(outs)
        return ResultFull(rc, out, err, ok, _error, outs, errs, out1, cmd)
    end
    exe(ss::AbstractVector{<:AbstractString}; kwargs...) = exe(Cmd(ss); kwargs...)
    exe(s::AbstractString; kwargs...) = exe([s]; kwargs...)

    exebash(s::AbstractString; kwargs...) = exe(Cmd(["bash", "-c", s]); kwargs...)
end
using .Exey: exe, exebash



module _UCM
    using CommandLiner: erroruser
    using ..Exey: exe

    _checked::Bool = false
    _found::Bool = false
    function isinstalled()
        _checked  &&  return _found
        global _checked = true
        global _found = exe(`ucm version`).ok
        return _found
    end
end




module Codebase
    using CommandLiner: erroruser
    using ..Exey: exe
    import .._UCM

    _statefile::String = joinpath(expanduser("~"), ".ucmfront.codebase")

    _codebase::Union{String, Nothing} = nothing

    function _check(s::AbstractString; fail=true)::Bool
        if !isdir(s)  
            fail  &&  erroruser("dir '$(s)' not found")
            return false
        end

        R = exe(`ucm -c $(s) --exit`)
        R.ok  &&  return true
        # error:
        if fail
            R.out1 !== nothing  &&  startswith(R.out1, "no codebase exists")  &&  erroruser("no codebase exists in '$(s)'; create with '-C <dir>'")
            error(debug(R))
        end
        return false
    end

    function set(s::AbstractString)
        !_UCM.isinstalled()  &&  erroruser("UCM not installed")

        s = abspath(expanduser(s))
        _check(s)

        write(_statefile, s)
        nothing
    end

    function get()
        !_UCM.isinstalled()  &&  erroruser("UCM not installed")
        !isfile(_statefile)  &&  erroruser("codebase not set yet; use '-c <dir>' or '-C <dir>'")

        ss = eachline(_statefile) |> collect
        length(ss) != 1  &&  erroruser("invalid codebase format in '$(_statefile)'; recreate with '-c <dir>' or '-C <dir>'")
        s = ss[1]
        _check(s)
        return s
    end

    function create(s::AbstractString)
        !_UCM.isinstalled()  &&  erroruser("UCM not installed")

        s = abspath(expanduser(s))
        !isdir(s)  &&  mkdir(s)

        R = exe(`ucm -C $(s) --exit`)
        R.error  &&  erroruser("UCM failed to create codebase\n---stderr:---\n$(R.err)")

        write(_statefile, s)
        nothing
    end
end



function mn()
    if length(ARGS) == 0
        println(
"""
Usage:
> uu -i             # info
> uu -c <dir>       # set existing Unison codebase dir
> uu -C <dir>       # create and set Unison codebase dir

  -v
"""
        )
        exit(2)
    end

    !exe(`ucm version`).ok  &&  erroruser("UCM not installed")

    while length(ARGS) > 0
        opt = getopt()

        if opt in ["-c"]
            Codebase.set(getarg())
            println("current codebase set to: '$(Codebase.get())'")
        elseif opt in ["-C"]
            s = getarg()
            wasok = Codebase._check(s; fail=false)
            Codebase.create(s)
            if wasok
                println("current codebase set to: '$(Codebase.get())'")
            else
                println("current codebase created and set to: '$(Codebase.get())'")
            end


        elseif opt in ["-i"]
            s = Codebase.get()
            println("current codebase dir: '$(s)'")




        elseif opt === nothing
            ss = getargs()
            if ss[1] == "pwd"
                length(ss) != 1  &&  erroruser("pwd: 1 arg only")
                R = exebash("ucm -c $(Codebase.get()) </dev/null")
                R.error  &&  erroruser("$(R.err)")
                println(R.outs[end])
            else
                erroruser("unknown command '$(ss[1])'")
            end


        else
            erroruser("unknown command line option '$(opt)'")
        end
    end
end

@mn

######
# pull unison.public.base.latest lib.base

## BETTER
# ```ucm:hide
# .> builtins.merge
# ```
