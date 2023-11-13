module OliveDocBrowser
using Olive.Toolips
using Olive.ToolipsSession
using Olive
using Olive.ToolipsMarkdown
using Olive: getname, Project, build_tab, open_project, Directory, Cell, build_tab
import Olive: build

build(c::Connection, om::OliveModifier, oe::OliveExtension{:docbrowser}) = begin
    explorericon = Olive.topbar_icon("docico", "newspaper")
    on(c, explorericon, "click") do cm::ComponentModifier
        mods = [begin 
            if :mod in keys(p.data)
                p.data[:mod]
            else
                nothing
            end
        end for p in c[:OliveCore].open[getname(c)].projects]
        filter!(x::Any -> ~(isnothing(x)), mods)
        push!(mods, Olive, c[:OliveCore].olmod)
        cells = Vector{Cell}([Cell(e, "docmodule", "", mod) for (e, mod) in enumerate(mods)])
        home_direc = Directory(c[:OliveCore].data["home"])
        projdict::Dict{Symbol, Any} = Dict{Symbol, Any}(:cells => cells,
        :path => home_direc.uri, :env => home_direc.uri)
        myproj::Project{:doc} = Project{:doc}(home_direc.uri, projdict)
        push!(c[:OliveCore].open[getname(c)].projects, myproj)
        tab::Component{:div} = build_tab(c, myproj)
        Olive.open_project(c, cm, myproj, tab)
    end
    insert!(om, "rightmenu", 1, explorericon)
end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:docdirectory}, proj::Project{<:Any})

end

function build(c::Connection, cm::ComponentModifier, cell::Cell{:docmodule}, proj::Project{<:Any})
    mainbox::Component{:section} = section("cellcontainer$(cell.id)")
    n::Vector{Symbol} = names(cell.outputs, all = true)
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
    mainbox[:children] = vcat([h("$(cell.outputs)", 2, text = string(cell.outputs))], selectorbuttons)
    mainbox
end
end # module OliveDocBrowser
