module OliveDocBrowser
using Olive.Toolips
using Olive.ToolipsSession
using Olive
using Olive.ToolipsServables
using Olive: getname, Project, build_tab, open_project, Directory, Cell
import Olive: build, build_tab, style_tab_closed!

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
    mainbox::Component{:section} = section("cellcontainer$(cell.id)")
    n::Vector{Symbol} = names(cell.outputs[2], all = true)
    remove::Vector{Symbol} =  [Symbol("#eval"), Symbol("#include"), :eval, :example, :include, Symbol(string(cell.outputs))]
    filter!(x -> ~(x in remove) && ~(contains(string(x), "#")), n)
    selectorbuttons::Vector{Servable} = [begin
        docdiv = div("doc$name", text = string(name))
        on(c, docdiv, "click") do cm2::ComponentModifier
            exp = Meta.parse("""t = eval(Meta.parse("$name")); @doc(t)""")
            docs = cell.outputs.eval(exp)
            docum = tmd("docs$name", string(docs))
            append!(cm2, docdiv, docum)
        end
        docdiv
    end for name in n]
    mainbox[:children] = vcat([h2("$(cell.outputs[1])", text = string(cell.outputs))], selectorbuttons)
    mainbox
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:docmanager}, proj::Project{<:Any})
    container = div("cell$(cell.id)")
    style!(container, "padding" => 3percent)
    if cell.outputs != ""

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
        for name in names(current_module, all = true)
            if isdefined(current_module, name) && getfield(current_module, name) isa Module
                f = getfield(current_module, name)
                push!(mods, string(f) => f)
                push!(container, make_module_button(c, cell, proj, string(f)))
            end
        end
        push!(container, make_module_button(c, cell, proj, mod[1]))
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
    cells = proj[:cells]
    mod_b = button("make-$name", text = name)
    style!(mod_b, "padding" => 2percent, "color" => "white", 
    "font-weight" => "bold", "width" => 60percent)
    on(c, mod_b, "click") do cm::ComponentModifier
        found_mod = findfirst(n -> n[1] == name, cell.outputs)
        found_mod = cell.outputs[found_mod]
        new_cell = Cell{:docmodule}("", found_mod)
        push!(cells, new_cell)
        append!(cm, proj.id, build(c, cm, new_cell, proj))
    end
    mod_b::Component{:button}
end

end # module OliveDocBrowser
