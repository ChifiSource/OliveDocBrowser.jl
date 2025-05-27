module OliveDocBrowser
using Olive.Toolips
using Olive.ToolipsSession
using Olive
using Olive.ToolipsServables
using Olive: getname, Project, build_tab, open_project, Directory, Cell
import Olive: build, build_tab, style_tab_closed!

function julia_interpolator(raw::String, tm::Olive.Highlighter)
    set_text!(tm, raw)
    Olive.OliveHighlighters.mark_julia!(tm)
    ret::String = string(tm)
    Olive.OliveHighlighters.clear!(tm)
    jl_container = div("jlcont", text = ret)
    style!(jl_container, "background-color" => "#f48fb1", "font-size" => 10pt, "padding" => 25px, 
    "margin" => 25px, "overflow" => "auto", "max-height" => 25percent, "border-radius" => 3px)
    string(jl_container)::String
end

build(c::Connection, om::Olive.OliveModifier, oe::Olive.OliveExtension{:docbrowser}) = begin
    explorericon = Olive.topbar_icon("docico", "newspaper")
    on(c, explorericon, "click") do cm::ComponentModifier
        if "doctab" in cm
            olive_notify!(cm, "you already have documentation open, you cannot open two docbrowsers at once.", color = "red")
            return
        end
        mods = [begin 
            if :mod in keys(p.data)
                p.data[:mod]
            else
                nothing
            end
        end for p in c[:OliveCore].open[getname(c)].projects]
        filter!(x::Any -> ~(isnothing(x)), mods)
        cells = Vector{Cell}([Cell{:docmanager}("")])
        for mod in mods
            
        end
        home_direc = Directory(c[:OliveCore].data["home"])
        projdict::Dict{Symbol, Any} = Dict{Symbol, Any}(:cells => cells,
        :path => home_direc.uri, :env => home_direc.uri, :pane => "one")
        myproj::Project{:doc} = Project{:doc}("docs", projdict)
        push!(c[:OliveCore].open[getname(c)].projects, myproj)
        tab::Component{:div} = build_tab(c, myproj)
        Olive.open_project(c, cm, myproj, tab)
    end
    insert!(om, "rightmenu", 1, explorericon)
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:docdirectory}, proj::Project{<:Any})

end

function build_tab(c::Connection, p::Project{:doc}; hidden::Bool = false)
    fname::String = p.id
    tabbody::Component{:div} = div("tab$(fname)", class = "tabopen", 
    style = "background-color:#216934;")
    if(hidden)
        tabbody[:class]::String = "tabclosed"
    end
    tablabel::Component{:a} = a("tablabel$(fname)", text = p.name, class = "tablabel", 
    style = "color:white;")
    push!(tabbody, tablabel)
    on(c, tabbody, "click") do cm::ComponentModifier
        projects::Vector{Project{<:Any}} = c[:OliveCore].open[getname(c)].projects
        inpane = findall(proj::Project{<:Any} -> proj[:pane] == p[:pane], projects)
        [begin
            if projects[e].id != p.id 
                style_tab_closed!(cm, projects[e])
            end
            nothing
        end  for e in inpane]
        projbuild::Component{:div} = build(c, cm, p)
        set_children!(cm, "pane_$(p[:pane])", [projbuild])
        cm["tab$(fname)"] = :class => "tabopen"
        if length(p.data[:cells]) > 0
            focus!(cm, "cell$(p[:cells][1].id)")
        end
    end
    on(c, tabbody, "dblclick") do cm::ComponentModifier
        if "$(fname)dec" in cm
            return
        end
        decollapse_button::Component{:span} = span("$(fname)dec", text = "arrow_left", class = "tablabel")
        on(c, decollapse_button, "click") do cm2::ComponentModifier
            remove!(cm2, "$(fname)close")
            remove!(cm2, "$(fname)add")
            remove!(cm2, "$(fname)restart")
            remove!(cm2, "$(fname)run")
            remove!(cm2, "$(fname)switch")
            remove!(cm2, "$(fname)dec")
        end
        style!(decollapse_button, "color" => "blue")
        controls::Vector{<:AbstractComponent} = Olive.tab_controls(c, p)
        insert!(controls, 1, decollapse_button)
        [begin append!(cm, tabbody, serv); nothing end for serv in controls]
    end
    tabbody::Component{:div}
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:docmodule}, proj::Project{<:Any})
    mainbox::Component{:div} = div("cellcontainer$(cell.id)", align = "left")
    style!(mainbox, "border" => "1px solid #1e1e1e", "height" => 10percent, "overflow-y" => "visible")
    current_module = cell.outputs[2]
    n::Vector{Symbol} = names(current_module, all = true)
    remove::Vector{Symbol} =  [Symbol("#eval"), Symbol("#include"), :eval, :example, :include, Symbol(string(cell.outputs))]
    filter!(x -> ~(x in remove) && ~(contains(string(x), "#")), n)
    selectorbuttons::Vector{Servable} = [begin
        docdiv = div("doc$name", text = string(name))
        style!(docdiv, "cursor" => "pointer", "padding" => 1percent, "color" => "white", "font-size" => 16pt, 
        "border-radius" => 1px)
        if isdefined(cell.outputs[2], name)
            f = getfield(current_module, name)
            if f isa Function
                style!(docdiv, "background-color" => "#2c6eab")
            elseif f isa Type
                style!(docdiv, "background-color" => "#ab812c")
            else
                style!(docdiv, "background-color" => "#b02774")
            end
            on(c, docdiv, "click") do cm2::ComponentModifier
                if "docs$name" in cm2
                    remove!(cm2, "docs$name")
                    return
                end
                exp = Meta.parse("""t = eval(Meta.parse("$name")); @doc(t)""")
                docs = current_module.eval(exp)
                docum = tmd("docs$name", string(docs))
                style!(docum, "padding" => 1.5percent)
                docum[:text] = Olive.Components.rep_in(docum[:text])
                interp(s::String) = julia_interpolator(s, c[:OliveCore].client_data[Olive.getname(c)]["highlighters"]["julia"])
                interpolate!(docum, "julia" => interp, "example" => interp)
                append!(cm2, docdiv, docum)
            end
        else
            style!(docdiv, "background-color" => "#474647")
            docdiv[:text] = "could not find definition ($(docdiv[:text]))"
        end
        docdiv
    end for name in n]
    deleter = span("$(cell.outputs[1])del", text = "delete", align = "right", class = "material-icons topbaricons")
    on(c, deleter, "click") do cm2::ComponentModifier
        Olive.cell_delete!(c, cm2, cell, proj[:cells])
    end
    select_container = div("select$(cell.outputs[1])", children = selectorbuttons)
    style!(select_container, "opacity" => 0percent, "overflow-x" => "hidden", "overflow-y" => "visible", "height" => 0percent, 
    "transition" => 600ms)
    container_collapse = span("$(cell.outputs[1])col", text = "arrow_downward", align = "center", class = "material-icons topbaricons")
    on(c, container_collapse, "click") do cm::ComponentModifier
        if cm[container_collapse]["text"] == "arrow_downward"
            style!(cm, select_container, "height" => 80percent, "opacity" => 100percent)
            style!(cm, mainbox, "height" => "auto")
            set_text!(cm, container_collapse, "arrow_upward")
            return
        end
        style!(cm, select_container, "height" => 0percent, "opacity" => 0percent)
        style!(cm, mainbox, "height" => 10percent)
        set_text!(cm, container_collapse, "arrow_downward")
    end
    style!(container_collapse, "background-color" => "#1e1e1e", "color" => "white", "padding" => .5percent, "width" => 98percent, 
    "font-size" => 17pt)
    style!(select_container, "border-radius" => 0px, "overflow-x" => "hidden", "overflow-y" => "scroll")
    style!(deleter, "color" => "red", "width" => 80percent, "font-size" => 14pt, "margin-top" => 1percent)
    style!(mainbox, "display" => "grid", "grid-column" => 4)
    mainbox[:children] = [Components.element("cell$(cell.id)"), deleter,
        h2("$(cell.outputs[1])", text = string(cell.outputs[1]), align = "center"), container_collapse, select_container]
    mainbox
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:docmanager}, proj::Project{<:Any})
    refb = span("clsman", text = "update", align = "right", class = "material-icons topbaricons")
    cellbuttons = div("cellbutts")
    container = div("cellcontainer$(cell.id)", children = Vector{Components.AbstractComponent}([Components.element("cell$(cell.id)"), refb, cellbuttons]))
    style!(refb, "color" => "blue", "width" => 80percent, "font-size" => 14pt, "margin-top" => 1percent)
    on(c, refb, "click") do cm2::ComponentModifier
        container = Vector{AbstractComponent}()
        mods = filter!(x -> ~(isnothing(x)), [begin 
            if :mod in keys(p.data)
                p.name => p.data[:mod]
            else
                nothing
            end
        end for p in c[:OliveCore].open[getname(c)].projects])
        for mod in mods[begin:end]
            current_module = mod[2]
            for name in names(current_module)
                if isdefined(current_module, name) && getfield(current_module, name) isa Module
                    f = getfield(current_module, name)
                    push!(mods, string(f) => f)
                    push!(container, make_module_button(c, cell, proj, string(f)))
                end
            end
            push!(container, make_module_button(c, cell, proj, mod[1]))
        end
        if length(cell.outputs) == length(mods)
            Olive.olive_notify!(cm2, "not seeing your modules? Make sure they are exported in your project.", color = "#1e1e1e")
        end
        set_children!(cm2, "cellbutts", container)
        cell.outputs = mods
    end
    style!(container, "padding" => 3percent, "border" => "1px solid #333333")
    if cell.outputs != ""
        push!(cellbuttons, (make_module_button(c, cell, proj, out[1]) for out in cell.outputs) ...)
        return(container)
    end
    mods = filter!(x -> ~(isnothing(x)), [begin 
            if :mod in keys(p.data)
                p.name => p.data[:mod]
            else
                nothing
            end
        end for p in c[:OliveCore].open[getname(c)].projects])
    for mod in mods[begin:end]
        current_module = mod[2]
        for name in names(current_module)
            if isdefined(current_module, name) && getfield(current_module, name) isa Module
                f = getfield(current_module, name)
                push!(mods, string(f) => f)
                push!(cellbuttons, make_module_button(c, cell, proj, string(f)))
            end
        end
        push!(cellbuttons, make_module_button(c, cell, proj, mod[1]))
    end
    cell.outputs = mods
    container
end

function build(c::AbstractConnection, cm::ComponentModifier, p::Project{:doc})
    frstcells::Vector{Cell} = p[:cells]
    retvs = Vector{Servable}([begin
       c[:OliveCore].olmod.build(c, cm, cell, p)::Component{<:Any}
    end for cell in frstcells])
    main = div(p.id, children = retvs, class = "projectwindow", align = "center")::Component{:div}
end

function make_module_button(c::AbstractConnection, cell::Cell{:docmanager}, proj::Project{:doc}, name::String)
    mod_b = button("make-$name", text = name)
    style!(mod_b, "padding" => 2percent, "color" => "white", 
    "font-weight" => "bold", "width" => 60percent)
    on(c, mod_b, "click") do cm::ComponentModifier
        if "$(name)del" in cm
            olive_notify!(cm, "documentation for $name is already open.", color = "darkred")
            return
        end
        cells = proj[:cells]
        found_mod = findfirst(n -> n[1] == name, cell.outputs)
        found_mod = cell.outputs[found_mod]
        new_cell = Cell{:docmodule}("", found_mod)
        push!(cells, new_cell)
        append!(cm, proj.id, build(c, cm, new_cell, proj))
    end
    mod_b::Component{:button}
end

end # module OliveDocBrowser
