



let ___UNIPATH::Union{UniPath, Nothing} = nothing  # should disappear from namespace in a module

    global function SET_UNICODEBASE(s::AbstractString)
        ucb = UniCodebase(s)
        unipath = UniPath(ucb, ".")

        ___UNIPATH = unipath
    end

    global function SET_PATH(s::AbstractString)
        unipath_old = ___UNIPATH
        isnothing(unipath_old)  &&  erroruser("Unison codebase not set")

        ucb_old = unipath_old.ucb
        unipath_new = UniPath(ucb_old, s)

        ___UNIPATH = unipath_new
    end

    #global UCB()   = isnothing(___UNIPATH)  ?  erroruser("Unison codebase not set")  :  ___UNIPATH.ucb
    #global UPATH() = isnothing(___UNIPATH)  ?  erroruser("Unison codebase not set")  :  ___UNIPATH
    global UNIPATH() = isnothing(___UNIPATH)  ?  erroruser("Unison codebase not set")  :  ___UNIPATH
end


# convenience, in addition to UNIPATH()
UCB() = UNIPATH().ucb
PATH() = path(UNIPATH())

function REPL_UCB()
    isnothing(UNIPATH())  &&  ( return "[<ucb not set>]" )
    return basename(UNIPATH().ucb)
end
function REPL_PATH()
    isnothing(UNIPATH())  &&  ( return "?" )
    s = path(UNIPATH())
    s == "."  &&  ( return s )
    return basename(UNIPATH())
end




SET_UNICODEBASE("_uu_SCRATCH.ucb")  # resets codebase and defaults path to root
