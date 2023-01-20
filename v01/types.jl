


struct UniCodebase
    s::String
    function UniCodebase(s::AbstractString)
        !isdir(s)  &&  erroruser("Unison codebase dir '$(s)' not found")
        return new(s)
    end
end
fntrans(x::UniCodebase)     = x.s * ".___uu_transcript___.md"
fntrans_out(x::UniCodebase) = x.s * ".___uu_transcript___.output.md"

path(x::UniCodebase) = x.s
Base.Filesystem.basename(x::UniCodebase) = basename(path(x))









struct UniPath  # TODO run stanza to check if valid path!!!
    ucb::UniCodebase
    ss::Vector{String}
    global _UniPath(ucb::UniCodebase, ss::AbstractVector{<:AbstractString}) = new(ucb, ss)
end

function UniPath(ucb::UniCodebase, s::AbstractString; ucm_check=true)
    s == "."  &&  return _UniPath(ucb, String[])

    # checks for non-root
    !startswith(s, '.')  &&  erroruser("invalid Unison path '$(s)': not absolute")
    occursin("..", s)    &&  erroruser("invalid Unison path '$(s)': contains '..'")
    occursin(" ", s)     &&  erroruser("invalid Unison path '$(s)': contains ' '")
    endswith(s, '.')     &&  erroruser("invalid Unison path '$(s)': ends in '.'")

    if ucm_check  # end-to-end check if valid UCM path
        transouts = ucm([".>cd $(s)"]; ucb=ucb)  # does not throw error, unlike 'ls' inside non-exist. dir
    end

    ss = split(s, '.')[2:end]
    @assert minimum(length.(ss)) > 0
    return _UniPath(ucb, ss)
end






path(x::UniPath) = isempty(x.ss)  ?  "."  :  join('.' .* x.ss)
Base.Filesystem.dirname(x::UniPath)::UniPath = isempty(x.ss)  ?  error("UniPath='.' at top level; no superdir available")  :  _UniPath(x.ucb, x.ss[begin:end-1])
Base.Filesystem.basename(x::UniPath)::String = isempty(x.ss)  ?  error("UniPath='.' at top level; no base available")  :  x.ss[end]



function u_isabspath(s::AbstractString)
    startswith(s, "..")  &&  return false
    startswith(s, ".")  &&  return true
    return false
end



function u_abspath(s; unipath::UniPath=UNIPATH())::UniPath
    u_isabspath(s)  &&  return UniPath(unipath.ucb, s)
    return joinpath(unipath, s)
end



function u_joinpath(x::UniPath, s::AbstractString)
    s = strip(s)
    s == ""  &&  ( return x )  # TODO empty string checks somewhere else

    if startswith(s, "..")
        return joinpath(dirname(x), s[3:end])
    end
    @assert !startswith(s, ".")

    s_orig = path(x)
    return UniPath(x.ucb, s_orig * '.' * s)
end









# struct UniLoc
#     ucb::UniCodebase
#     upath::UniPath
# end
# UniLoc(s::AbstractString) = UniLoc(UniCodebase(s), UniPath("."))

# codebase_short(x::UniLoc=UNILOC) = basename(x.ucb.s)
# path_short(x::UniLoc=UNILOC) = x.upath.s == "."  ?  "."  :  split(x.upath.s, '.')[end]

# codebase(x::UniLoc=UNILOC) = x.ucb.s
# path(x::UniLoc=UNILOC) = x.upath.s









abstract type AbstractUEntity end
abstract type AbstractUType <: AbstractUEntity end

struct UTypeBuiltin <: AbstractUType  s::String  end
struct UType <: AbstractUType  s::String  end

struct UTerm <: AbstractUEntity  s::String; type::String  end  # TODO Typesig?
struct UNamespace <: AbstractUEntity  s::String;  content::String  end
struct UDoc <: AbstractUEntity  s::String  end
struct UPatch <: AbstractUEntity  s::String  end


human(x::UTypeBuiltin)  = println("_tp $(x.s)")
human(x::UType)         = println("typ $(x.s)")
human(x::UDoc)          = println("doc $(x.s)")
human(x::UPatch)        = println("ptc $(x.s)")
human(x::UNamespace)    = println("nsp $(x.s)")
human(x::UTerm)         = println("trm $(x.s)")
function human(X::AbstractVector{<:AbstractUEntity})
    for x in X
        human(x)
    end
end

