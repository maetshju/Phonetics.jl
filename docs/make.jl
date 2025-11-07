using Documenter, Phonetics

ENV["GKSwstype"] = "100"

makedocs(sitename = "Phonetics.jl",
         pages = ["index.md", "vowelplot.md", "acd.md", "lc.md", "textvptree.md", "phon_spectrogram.md", "plotting_tips.md"],
         repo = "https://github.com/maetshju/Phonetics.jl")

deploydocs(
repo = "github.com/maetshju/Phonetics.jl.git"
)
