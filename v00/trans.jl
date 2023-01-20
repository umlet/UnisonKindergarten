


import Juliettine.Conv.tostr  #to add methods below

abstract type AbstractStanza end

struct StanzaUnison <: AbstractStanza  v::Vector{String}  end
StanzaUnison(s::AbstractString) = StanzaUnison([s])
tostr(x::StanzaUnison) = string("```unison", '\n', join(x.v, '\n'), '\n', "```")

struct StanzaUCM <: AbstractStanza  v::Vector{String}  end
StanzaUCM(s::AbstractString) = StanzaUCM([s])
tostr(x::StanzaUCM) = string("```ucm", '\n', join(x.v, '\n'), '\n', "```")

function _show(io::IO, x::AbstractStanza; compact=false)
    if compact
        print(io, typeof(x), '(', string(x.v), ')')
        return
    end
    print(io, typeof(x), '(', '\n', tostr(x), '\n', ')')
end

Base.show(io::IO, ::MIME"text/plain", x::AbstractStanza) = _show(io, x; compact=get(io, :compact, false))

tostr(X::AbstractVector{<:AbstractStanza}) = tostr.(X) |> jn('\n')






function _unigrepv_outs(X::AbstractVector{<:AbstractString})
    ss = String[]
    for s in X
        s in (  "  \e[0m\e[31m _____\e[0m\e[93m     _             \e[0m" ,
                "  \e[0m\e[31m|  |  |\e[0m\e[91m___\e[0m\e[93m|_|\e[0m\e[92m___ \e[0m\e[36m___ \e[0m\e[35m___ \e[0m" ,
                "  \e[0m\e[31m|  |  |   \e[0m\e[93m| |\e[0m\e[92m_ -\e[0m\e[36m| . |\e[0m\e[35m   |\e[0m" ,
                "  \e[0m\e[31m|_____|\e[0m\e[91m_|_\e[0m\e[93m|_|\e[0m\e[92m___\e[0m\e[36m|___|\e[0m\e[35m_|_|\e[0m" ,
                "  " 
                )  &&  continue

        push!(ss, s)
    end
    return ss
end


struct TransResult
    scmd::String
    save_codebase_mode::Symbol
    exitcode::Int64
    outs::Vector{String}
    errs::Vector{String}
    transouts::Union{Vector{String}, Nothing}
    suniloc_new::Union{String, Nothing}
end
function _show(io::IO, x::TransResult; compact=false)
    println("TransResult(..):")

    w = displaysize(stdout)[2]

    println()
    println(rpad("command: ", w, '-'))
    println("`$(x.scmd)`")

    println()
    println(rpad("save-codebase-mode: ", w, '-'))
    println(":" * string(x.save_codebase_mode))

    println()
    println(rpad("exitcode: ", w, '-'))
    println(x.exitcode)

    println()
    println(rpad("stdout: ", w, '-'))
    foreach(println, _unigrepv_outs(x.outs))

    println()
    println(rpad("stderr: ", w, '-'))
    foreach(println, x.errs)

    println()
    println(rpad("trans output: ", w, '-'))
    if x.transouts === nothing
        println("<ERROR: transcript output not found>")
    else
        foreach(println, x.transouts)
    end

    println()
    println(rpad("new unison location: ", w, '-'))
    if x.suniloc_new === nothing
        if x.save_codebase_mode == :no
            println("<OK: not needed/available>")
        else
            println("<ERROR: expected, but unable to parse from stdout>")
        end
    else
        println(x.suniloc_new)
    end
end
Base.show(io::IO, ::MIME"text/plain", x::TransResult) = _show(io, x; compact=get(io, :compact, false))

function trans(S::AbstractVector{<:AbstractStanza}; ucb::UniCodebase=UNICODEBASE, save_codebase_mode::Symbol=:no)  # :no :copy :OVERWRITE
    #!(save_codebase in (0, 1, 99)  &&  error("invalid 'save_codebase' value; must be 0 [none], 1 [keep], or 99 [keep & replace orig]")
    ft_out = fntrans_out(ucb)
    rm(ft_out; force=true)

    # base command
    ft = fntrans(ucb)
    save(ft, tostr(S))
    if save_codebase_mode == :no
        scmd = "ucm transcript.fork $(ft) --codebase $(ucb.s)"
    elseif save_codebase_mode == :copy
        scmd = "ucm transcript.fork --save-codebase $(ft) --codebase $(ucb.s)"
    elseif save_codebase_mode == :OVERWRITE
        scmd = "ucm transcript.fork --save-codebase $(ft) --codebase $(ucb.s)"
    else
        error("invalid 'save_codebase_mode': $( ":" * string(save_codebase_mode) )")
    end
    result = exe(scmd; fail=false)

    # get transcript output
    transouts = String[]
    try 
        append!(transouts, readlines(ft_out))
    catch
        transouts = nothing
    end

    # get new tmp location if needed
    suniloc_new = nothing
    if save_codebase_mode in (:copy, :OVERWRITE)
        ss = result.outs |> fl(X->occursin("You can run `ucm --codebase", X))
        length(ss) == 1  &&  ( suniloc_new = chop(split(ss[1])[6]) )
    end

    tr = TransResult(scmd, save_codebase_mode, result.exitcode, result.outs, result.errs, transouts, suniloc_new)

    if result.exitcode != 0 
        display(tr);  erroruser("exit code != 0; check output above")
    elseif transouts === nothing
        display(tr);  erroruser("transcript output not found")
    elseif save_codebase_mode in (:copy, :OVERWRITE)  &&  suniloc_new === nothing
        display(tr);  erroruser("new codebase not found")
    end

    # OVERWRITE OLD CODEBASE
    if save_codebase_mode == :OVERWRITE
        orig = uni.codebase
        orig_backup = orig * ".___uu_backup_TMP___"
        new = tr.suniloc_new

        mv(orig, orig_backup)
        mv(new, orig)
        rm(orig_backup; recursive=true)
    end

    return tr
end
trans(x::AbstractStanza; ucb::UniCodebase=UNICODEBASE, save_codebase_mode::Symbol=:no) = trans([x]; ucb=ucb, save_codebase_mode=save_codebase_mode)

function errortrans(tr::TransResult, msg::AbstractString)
    display(tr)
    erroruser(msg)
end


