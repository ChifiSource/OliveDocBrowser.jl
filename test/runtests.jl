using Test
using OliveDocBrowser
using OliveDocBrowser.Olive: build, Project, Cell
# A pretty difficult thing to test,
# considering we need the `Connection` and real testing
#   requires an active user on a single-page app.
# these tests will be load + 'binding exists' tests.

@testset "Olive Documentation Browser" verbose = true begin
    f = findfirst(x -> Project{:doc} in x.sig.parameters, methods(build))
    @test ~(isnothing(f))
    f = findfirst(x -> Cell{:docmodule} in x.sig.parameters, methods(build))
    @test ~(isnothing(f))
    f = findfirst(x -> Cell{:docmanager} in x.sig.parameters, methods(build))
    @test ~(isnothing(f))
end