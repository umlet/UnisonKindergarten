



function _ls(unipath::UniPath)
    RET = []

    # first check if potential dir is empty without raising error; done via cd
    transout = ucm([".>cd $( path(unipath) )"]; ucb=unipath.ucb)
    n = transout |> fl(x->occursin(" is empty.", x)) |> length
    n > 0  &&  ( return RET )

    transout = ucm([".>ls $( path(unipath) )"]; ucb=unipath.ucb)
    append!(RET, transout)
    return RET
end

                                                    
function ls(s::AbstractString=""; unipath::UniPath=UNIPATH())  # TODO allow abspath (then ignore unipath except ucb)
    tmppath = ujoinpath(unipath, s)                 # can be done via ABSPATH function!!
    v = _ls(tmppath)
    out(v)  # TODO print nicer
end





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


# function ls(s::AbstractString=""; uniloc::UniLoc=UNILOC)
#     transout = ucm(["$( path(uniloc) )>ls $(s)"])
# end

