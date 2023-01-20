




# function _ls_raw(s::AbstractString=""; uniloc::UniLoc=UNILOC)
#     stanza = StanzaUCM(path(uniloc)*">ls $(s)")
#     tr = trans(stanza; ucb=uniloc.ucb)
#     return tr.transouts |> fl(x->occursin('(', x)) |> fl(x->occursin(')', x))
# end
# function _ls(s::AbstractString=""; uniloc::UniLoc=UNILOC)
#     ss = _ls_raw(s; uniloc=uniloc) 
#     RET = AbstractUEntity[]
#     for s in ss
#         i,name,desc = split(s)
#         desc == "(builtin type)"  &&  ( push!(RET, UTypeBuiltin(name));  continue )
#         desc == "(type)"          &&  ( push!(RET, UType(name));  continue )
#         desc == "(Doc)"           &&  ( push!(RET, UDoc(name));  continue )
#         desc == "(patch)"         &&  ( push!(RET, UPatch(name));  continue )
#         #operator '/' vs namespace
#         endswith(name, "./")      &&  ( push!(RET, UTerm(name, desc));  continue )
#         endswith(name, "/")       &&  ( push!(RET, UNamespace(name, desc));  continue )   

#         push!(RET)
#     end
#     return RET
# end
# ls(s::AbstractString=""; kwargs...) = _ls(s; kwargs...) |> human
# ll(args...; kwargs...) = ls(args...; kwargs...)




function _find_raw(s::AbstractString="."; uniloc::UniLoc=UNILOC)
    s = strip(s);  s == ""  &&  ( s = "." )
    stanza = StanzaUCM(path(uniloc)*">find $(s)")
    tr = trans(stanza; ucb=uniloc.ucb)
    return tr.transouts
end
function _find(s::AbstractString="."; kwargs...)
    ss0 = _find_raw(s; kwargs...) |> mp(strip) |> fl(!=("")) |> fl(!sw("```")) |> drwhile(!sw("1. "))
    ss = Vector{Vector{String}}()
    expi = 1
    for s in ss0
        if startswith(s, tostr(expi)*". ")
            push!(ss, [s])
            expi += 1
        else    
            @assert length(ss) > 0
            push!(ss[end], s)
        end
    end
    return ss |> mp(jn(' '))
end
find(s::AbstractString="."; kwargs...) = _find(s; kwargs...) |> out




function codebase(s::AbstractString)
    uniloc = UniLoc(s)
    global UNILOC = uniloc
    return uniloc
end
cb(args...) = codebase(args...)




function unisplitpath(s::AbstractString)
    s2 = replace(s, '.'=>'/')
    ss = splitpath(s2)
    if length(ss) > 0
        ss[1] == "/"  &&  ( ss[1] = "." )
    end
    return ss
end
function unijoinpath(ss::AbstractVector{<:AbstractString})
    if length(ss) > 0
        ss[1] == "."  &&  ( ss[1] = "/" )
    end
    s = joinpath(ss)
    return replace(s, '/'=>'.')
end
unijoinpath(ss::AbstractString...) = unijoinpath(ss)

function cd(s::AbstractString=".")
    s = strip(s);  s == ""  &&  ( s = "." )

    if startswith(s, "..")
        # up
        n = div(count(==('.'), s),2)
        oldpath = path(UNILOC)
        nlevels = count(==('.'), oldpath)
        nup = min(n, nlevels)
        
        ss = unisplitpath(oldpath)[1:end-nup]
        newpath = unijoinpath(ss)

    elseif startswith(s, '.')  
        # absolute
        newpath = s
    else
        # relative
        if path(UNILOC) != "."
            newpath = path(UNILOC)*"."*s
        else
            newpath =              "."*s
        end
    end

    uniloc = UniLoc(UNILOC.ucb, UniPath(newpath))
    global UNILOC = uniloc
    return uniloc
end




function eval(s::AbstractString; ucb::UniCodebase=UNICODEBASE)
    stanza = StanzaUnison(">$(s)")
    tr = trans(stanza; ucb=ucb)

    result = nothing
    for i in 2:length(tr.transouts)
        sm1 = tr.transouts[i-1]
        s = tr.transouts[i]
        '⧩' in sm1  &&  ( result = strip(s) )
    end
    result === nothing  &&  ( display(tr);  erroruser("unable to find watch expression evaluation; check output above") )
    return result
end
