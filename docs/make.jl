using Documenter, Phonetics

makedocs(sitename = "Phonetics.jl",
         pages = ["index.md", "vowelplot.md", "acd.md", "lc.md", "textvptree.md"],
         repo = "https://github.com/maetshju/Phonetics.jl")

deploydocs(
repo = "github.com/maetshju/Phonetics.jl.git"
)
