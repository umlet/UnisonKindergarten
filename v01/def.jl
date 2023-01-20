function splitterm(s::AbstractString)
    r = s
    r = replace(r, "==="=>"___")
    r = replace(r, "!=="=>"___")

    r = replace(r, "=="=>"__")
    r = replace(r, "!="=>"__")
    r = replace(r, ">="=>"__")
    r = replace(r, "<="=>"__")

    ss =split(r, '=')
    return ss
end


function addable(transouts::AbstractVector{<:AbstractString})
    ss = transouts |> fl(x->occursin("new", x))
    if length(ss) == 1
        ss = transouts |> fl(x->occursin(" : ", x))
        length(ss) != 1  &&  error("UNREACHABLE: addable #1")
        return (:okadd, strip(ss[1]))
    end

    ss = transouts |> fl(x->occursin("already", x))
    if length(ss) == 1
        ss = transouts |> fl(x->occursin(" : ", x))
        length(ss) != 1  &&  error("UNREACHABLE: addable #2")
        return (:okupdate, strip(ss[1]))
    end

    ss = transouts |> fl(x->occursin("previously", x))
    if length(ss) == 1  
        return (:okexists, "")
    end

    return nothing
end

struct UTypesig  s::String  end
struct UDef  s::String  end

function get_utypesig_udef(tr::TransResult)
    ss = tr.transouts |> fl(x->occursin(" : ", x))
    length(ss) != 1  &&  errortrans(tr, "unable to parse type signature; check output above")

    tt = tr.transouts |> fl(x->occursin(" = ", x))  # TODO multiline
    length(tt) != 1  &&  errortrans(tr, "unable to parse type definition; check output above")

    return (UTypesig(strip(ss[1])), UDef(strip(tt[1])))
end



abstract type AbstractDef end

struct DefTerm <: AbstractDef
    s::String
    name::String
    utypesig::UTypesig
    udef::UDef

    # NOTE: initial parsing is context-dependent (upath..); however, after success, adding works in other locations as well!
    function DefTerm(s::AbstractString; ucb::UniCodebase=UNICODEBASE, upath::UniPath=UNIPATH)
        ss = splitterm(s)
        name = split(strip(ss[1]))[1]

        stanza = StanzaUnison(s)   #, StanzaUCM(upath.s*">view $(name)")]
        tr = trans(stanza; ucb=ucb)

        # add/update/exist?
        aue = addable(tr.transouts)
        aue === nothing  &&  errortrans(tr, "unable to check/parse addability of new term; check output above")
        (!(aue isa Tuple)  ||  !(aue[1] in (:okadd, :okupdate, :okexists)) )  &&  errortrans(tr, "invalid addable code: '$(string(aue)); check output above'")

        if aue[1] == :okexists
            @info "term definition exists; nothing to do"
            stanza_ucm = StanzaUCM(upath.s*">view $(name)")
            tr = trans(stanza_ucm; ucb=ucb)
            utypesig,udef = get_utypesig_udef(tr)
            return new(s, name, utypesig, udef)
        end
        if aue[1] == :okadd
            @info "term definition new; will be added"
            stanzas = [stanza, StanzaUCM(upath.s*">add"), StanzaUCM(upath.s*">view $(name)")]
            tr = trans(stanzas; ucb=ucb)
            utypesig,udef = get_utypesig_udef(tr)
            return new(s, name, utypesig, udef)
        end
        # :okupdate
        @info "term definition changed; will be updated"
        stanzas = [stanza, StanzaUCM(upath.s*">update"), StanzaUCM(upath.s*">view $(name)")]
        tr = trans(stanzas; ucb=ucb)
        utypesig,udef = get_utypesig_udef(tr)
        return new(s, name, utypesig, udef)
    end
end

