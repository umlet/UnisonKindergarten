


function unireplparse(s::AbstractString)
    ( s == "ls"   ||  startswith(s, "ls ") )   &&  ( return parse_cmd_ls(s) )
    ( s == "ls0"  ||  startswith(s, "ls0 ") )  &&  ( return parse_cmd_ls0(s) )

    #println(typeof(s))
    if s == "f"
        StanzaUnison("f13 x = 5")
    else
        println("CAN'T UNDERSTAND: '$(s)'")
    end
end

function parse_cmd_ls(s::AbstractString)
    ss = split(s); popfirst!(ss)

    length(ss) == 0  &&  ( return ls() )
    length(ss) == 1  &&  ( return ls(ss[1]) )
    @assert false
end
function parse_cmd_ls0(s::AbstractString)
    ss = split(s); popfirst!(ss)

    length(ss) == 0  &&  ( _ls_raw() |> out;  return )
    length(ss) == 1  &&  ( _ls_raw(ss[1]) |> out;  return )
    @assert false
end
