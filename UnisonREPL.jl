#!/bin/bash
#=  #start of bash code
exec julia  "${BASH_SOURCE[0]}"  --  "$@"
=#  #end of bash code

using Juliettine


include("repl.jl")

include("global.jl")

include("trans.jl")

include("ucmd.jl")

include("def.jl")



include("parse.jl")




function main()


    while length(ARGS) > 0
        opt = getopt()

        # if opt === nothing
        #     args = getargs()  # commands!
        #     for arg in args  run_unison(arg)  end

        if opt in ("--codebase", "-c")
            global UNICODEBASE = UniCodebase(getarg())
        elseif opt in ("--path", "-p")
            global UNIPATH = UniPath(getarg())

        elseif opt in ("--find",)
            ss = getargs0()
            length(ss) > 1  &&  erroruser("must be called with 0 or 1 argument")
            length(ss) == 1  ?  find(ss[1])  :  find()
        elseif opt in ("--find0",)
            _find() |> out

        elseif opt in ("--defterm",)
            defs = DefTerm.(getargs())
            #append!(DEFS, defs)
        # elseif opt in ("--def-print", "-dp")
        #     foreach(println, DEFS)


        elseif opt == "-su"
            args = getargs()
            stz = StanzaUnison(join(args, '\n'))
            push!(STANZAS, stz)
        elseif opt == "-sx"
            args = getargs()
            stz = StanzaUCM(join(args, '\n'))
            push!(STANZAS, stz)
        elseif opt in ("-sp",)
            println(tostr(STANZAS))

        elseif opt in ("-t",)
            trans(STANZAS, CODEBASE, TRANS)

        else  erroruser("unknown command line option '$(opt)'")
        end
    end
end
###############################################################################
if abspath(PROGRAM_FILE) == @__FILE__
    main()  
end
###############################################################################
# v 0.1.0


