using Documenter, Phonetics

makedocs(sitename = "Phonetics.jl",
         pages = ["index.md", "pnd.md", "upt.md", "phnprb.md", "textvptree.md"],
         repo = "https://github.com/maetshju/Phonetics.jl")

deploydocs(
repo = "github.com/maetshju/Phonetics.jl.git",
julia = "1.4"
)
