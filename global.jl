struct UniCodebase
    s::String
    function UniCodebase(s::AbstractString)
        !isdir(s)  &&  erroruser("Unison codebase dir '$(s)' not found")
        return new(s)
    end
end
fntrans(x::UniCodebase)     = x.s * ".___uu_transcript___.md"
fntrans_out(x::UniCodebase) = x.s * ".___uu_transcript___.output.md"

struct UniPath  # TODO run stanza to check if valid path!!!
    s::String
    function UniPath(s::AbstractString)
        !startswith(s, '.')  &&  erroruser("invalid Unison path '$(s)'")
        occursin("..", s)  &&  erroruser("invalid Unison path '$(s)'")
        return new(s)
    end
end

struct UniLoc
    ucb::UniCodebase
    upath::UniPath
end
UniLoc(s::AbstractString) = UniLoc(UniCodebase(s), UniPath("."))

codebase_short(x::UniLoc=UNILOC) = basename(x.ucb.s)
path_short(x::UniLoc=UNILOC) = x.upath.s == "."  ?  "."  :  split(x.upath.s, '.')[end]

codebase(x::UniLoc=UNILOC) = x.ucb.s
path(x::UniLoc=UNILOC) = x.upath.s

# codebase_short(x::UniCodebase=UNICODEBASE) = basename(x.s)
# path_short(x::UniPath=UNIPATH) = x.s == "."  ?  "."  :  split(x.s, '.')[end]


# UNICODEBASE::UniCodebase = UniCodebase("_uu_SCRATCH.ucb")
# UNIPATH::UniPath = UniPath(".")


UNILOC::UniLoc = UniLoc("_uu_SCRATCH.ucb")