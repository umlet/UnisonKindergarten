import REPL
import REPL.LineEdit
import REPL.LineEditREPL
import Base.display


function unireplinit(repl)
    parser::Function=unireplparse
    prompt_text = "myrepl> "
    prompt_color = :cyan
    start_key = '.'
    repl = Base.active_repl
    mode_name = :unison
    show_function = nothing
    show_function_io = stdout
    valid_input_checker::Function = complete_unison #(s -> true)
    keymap::Dict = REPL.LineEdit.default_keymap_dict
    completion_provider = REPL.REPLCompletionProvider()
    sticky_mode = true
    startup_text = true

    ##########
    color = Base.text_colors[prompt_color]
    if !isdefined(repl, :interface)
        repl.interface = REPL.setup_interface(repl)
    end
    julia_mode = repl.interface.modes[1]
    prefix = repl.hascolor ? color : ""
    suffix = repl.hascolor ? (repl.envcolors ? Base.input_color : repl.input_color()) : ""



    ##########
    lang_mode = LineEdit.Prompt(prompt_text;
                                prompt_prefix    = prefix,
                                prompt_suffix    = suffix,
                                keymap_dict      = keymap,
                                on_enter         = valid_input_checker,
                                complete         = completion_provider,
                                sticky           = sticky_mode
                                )
    lang_mode.on_done = REPL.respond(parser, repl, lang_mode)
    push!(repl.interface.modes, lang_mode)


    hp                     = julia_mode.hist
    hp.mode_mapping[mode_name |> Symbol] = lang_mode
    lang_mode.hist         = hp



    # KEYMAPS!!!!!
    search_prompt, skeymap = LineEdit.setup_search_keymap(hp)

    prefix_prompt, prefix_keymap = LineEdit.setup_prefix_keymap(hp, lang_mode)

    mk = REPL.mode_keymap(julia_mode)

    # alt() is a function!
    normalized_start_key = LineEdit.normalize_key(start_key)
    alt = get_nested_key(julia_mode.keymap_dict, normalized_start_key)
    if alt !== nothing
        @warn "REPL key '$start_key' overwritten."
        alt = deepcopy(alt)
    else
        alt = (s, args...) -> LineEdit.edit_insert(s, normalized_start_key)
    end
    lang_keymap = Dict{Any,Any}(
        normalized_start_key => (s, args...) ->
            if isempty(s) || position(LineEdit.buffer(s)) == 0
                enter_mode!(s, lang_mode)
            else
                alt(s, args...)
            end
    )

    uni_custom_keymap = Dict{Any, Any}(
        #"j"  =>  (s,o...)->LineEdit.edit_clear(s),
        "^K"  =>  (s,o...)->LineEdit.edit_clear(s)
    )

    lang_mode.keymap_dict = LineEdit.keymap(Dict{Any,Any}[
        uni_custom_keymap,          # 1st is winner!!! (ctrl-K already used below in the defaults)
        skeymap,                    # search keymap???
        mk,                         # from Julia mode
        prefix_keymap,              # what is prefix keymap???
        LineEdit.history_keymap,
        LineEdit.default_keymap,
        LineEdit.escape_defaults,
    ])
    #lang_mode.keymap_dict = LineEdit.keymap_merge(lang_mode.keymap_dict, mk)

    julia_mode.keymap_dict = LineEdit.keymap_merge(julia_mode.keymap_dict, lang_keymap)

    startup_text  &&  ( @info "Unison REPL mode v0.00 ready; press '$start_key' to enter and backspace to exit." )


    # TEST
    #repl.interface.modes[1].prompt = () -> "ن $( codebase_short() ) $( path_short() )> "
    lang_mode.prompt = () -> #=Base.text_colors[:green]*=#"ن $( codebase_short() ) $( path_short() )> "
    #return

    #return lang_mode
    return nothing
end
atreplinit(unireplinit)



function get_nested_key(keymap::Dict, key::Union{String, Char})
    y = iterate(key)
    while y !== nothing
        c, i = y
        y = iterate(key, i)
        tmp = get(keymap, c, nothing)
        if (y === nothing) == isa(tmp, Dict)
            error("Conflicting definitions for keyseq " * escape_string(key) *
                  " within one keymap")
        end
        if y === nothing
            return tmp
        end
        keymap = tmp
    end
end

function enter_mode!(f, s :: LineEdit.MIState, lang_mode)
  LineEdit.transition(f, s, lang_mode)
end

function enter_mode!(s :: LineEdit.MIState, lang_mode)
  buf = copy(LineEdit.buffer(s))
  function default_trans_action()
    LineEdit.state(s, lang_mode).input_buffer = buf
  end
  enter_mode!(default_trans_action, s, lang_mode)
end

function enter_mode!(lang_mode)
  enter_mode!(Base.active_repl.mistate, lang_mode)
end



function complete_julia(s)
    input = String(take!(copy(LineEdit.buffer(s))))
    iscomplete(Meta.parse(input))
end

iscomplete(x) = true
function iscomplete(ex::Expr)
    if ex.head == :incomplete
        false
    else
        true
    end
end

function complete_unison(x) # STATE, not string!
    s = String(take!(copy(LineEdit.buffer(x))))
    ('=' in s)  &&  ( return false )
    return true
end





