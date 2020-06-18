using Phonetics
using Test
using DelimitedFiles
using StatsBase
using DataFrames
using Statistics
using Random

@testset "Vowel space and density" begin

  f = Formants("sample_formants.txt")
  v = VowelSpace(f)
  @test area(v, unstandardize=true) ≈ 1920.3803415872135
  @test vdi(v, unstandardize=true) ≈ 766.8716362331788
end

@testset "Normalization" begin

  f = readdlm("sample_formants.txt")
  f1 = f[:, 1]
  f2 = f[:, 2]
  vowel = repeat(["i"], length(f1))
  speaker = repeat([1], length(f1))

  lobCustom = DataFrame(f1=zscore(f1), f2=zscore(f2), vowel=vowel, speaker=speaker)
  lobFunc = lobanov(f1, f2, vowel, speaker)
  # use check for approximate equality because sum and related functions
  # called on the view genereated by `groupby` produces a different value
  # than sum called on the original array (due to how the view is generated
  #  and how order matters when performing sequential floating point operations).
  @test lobCustom.f1 ≈ lobFunc.f1
  @test lobCustom.f2 ≈ lobFunc.f2
  @test lobCustom.vowel == lobfunc.vowel
  @test lobCustom.speaker == lobFunc.speaker

  nICustom = DataFrame(f1=log.(f1) .- mean(log.(f1)), f2=log.(f2) .- mean(log.(f2)), vowel=vowel, speaker=speaker)
  nIFunc = neareyI(f1, f2, vowel, speaker)
  @test nICustom.f1 ≈ nIFunc.f1
  @test nICustom.f2 ≈ nIFunc.f2
  @test nICustom.vowel == nIFunc.vowel
  @test nICustom.speaker == nIFunc.speaker

  nECustom = DataFrame(f1=log.(f1) .- mean(log.([f1; f2])), f2=log.(f2) .- mean(log.([f1; f2])), vowel=vowel, speaker=speaker)
  nEFunc = neareyE(f1, f2, vowel, speaker)
  @test nECustom.f1 ≈ nEFunc.f1
  @test nECustom.f2 ≈ nEFunc.f2
  @test nECustom.vowel == nEFunc.vowel
  @test nECustom.speaker == nEFunc.speaker
end

@testset "Acoustic distance" begin

  Random.seed!(9)
  x = rand(1000)
  y = rand(3000)
  z = rand(10000)
  a = [Sound(x, 8000), Sound(y, 8000), Sound(z, 8000)]
  @test acdist(a[1], a[2]) ≈ 20478.541722315666
  @test distinctiveness(a[1], a[2:3]) ≈ mean([acdist(a[1], a[2]), acdist(a[1], a[3])])
end

const SAMPLE_CORPUS = [
["K", "AE1", "T"], # cat
["K", "AA1", "B"], # cob
["B", "AE1", "T"], # bat
["T", "AE1", "T", "S"], # tats
["M", "AA1", "R", "K"], # mark
["K", "AE1", "B"], # cab
]

@testset "Uniqueness point" begin

  ## Unique at second character
  desired = DataFrame(Query=[["K", "AA1", "B"]], UPT=[2])
  @test upt(SAMPLE_CORPUS, [["K", "AA1", "B"]]; inCorpus=true) == desired

  ## Unique at first character
  desired = DataFrame(Query=[["HH", "AE1", "T"]], UPT=[1])
  @test upt(SAMPLE_CORPUS, [["HH", "AE1", "T"]]; inCorpus=false) == desired

  ## Unique at the last character
  desired = DataFrame(Query=[["K", "AE1", "D"]], UPT=[3])
  @test upt(SAMPLE_CORPUS, [["K", "AE1", "D"]]; inCorpus=false) == desired

  ## Not unique
  desired = DataFrame(Query=[["T", "AE1", "T"]], UPT=[4])
  @test upt(SAMPLE_CORPUS, [["T", "AE1", "T"]]; inCorpus=false) == desired
end

@testset "Phonological neighborhood density" begin

  # Showing progress

  ## Neighbors with bat and cab
  desired = DataFrame(Query=[["K", "AE1", "T"]], PND=[2])
  @test pnd(SAMPLE_CORPUS, [["K", "AE1", "T"]]; progress=true) == desired

  ### Neighbors with cat and bat
  desired = DataFrame(Query=[["HH", "AE1", "T"]], PND=[2])
  @test pnd(SAMPLE_CORPUS, [["HH", "AE1", "T"]]; progress=true) == desired

  ### No neighbors
  desired = DataFrame(Query=[["L", "IH1", "V"]], PND=[0])
  @test pnd(SAMPLE_CORPUS, [["L", "IH1", "V"]]; progress=true) == desired

  ## Not showing progress

  ### Neighbors with bat and cab
  desired = DataFrame(Query=[["K", "AE1", "T"]], PND=[2])
  @test pnd(SAMPLE_CORPUS, [["K", "AE1", "T"]]; progress=false) == desired

  ### Neighbors with cat and bat
  desired = DataFrame(Query=[["HH", "AE1", "T"]], PND=[2])
  @test pnd(SAMPLE_CORPUS, [["HH", "AE1", "T"]]; progress=false) == desired

  ### No neighbors
  desired = DataFrame(Query=[["L", "IH1", "V"]], PND=[0])
  @test pnd(SAMPLE_CORPUS, [["L", "IH1", "V"]]; progress=false) == desired
end

@testset "Phonotactic probability" begin

  #=
  **Co-occurrence**

  20 total monophones
  K:      4
  AE1:    4
  T:      4
  S:      1
  M:      1
  AA1:    2
  B:      3
  R:      1

  ["K", "AE1", "T"], get counts
  [4, 4, 4], divide by total monophones
  [0.2, 0.2, 0.2], take product
  0.2^3 = 0.008
  =#
  freq = [1,1,1,1,1,1]
  p = prod([4,4,4] / 20)
  desired = DataFrame(Query=[["K", "AE1", "T"]], Probability=[p])
  prb = phnprb(SAMPLE_CORPUS, freq, [["K", "AE1", "T"]])
  @test prb == desired

  #=

  **Co-occurrence diphones**

  26 total diphones
  . K:    3
  K  AE1: 2
  AE1 T:  3
  T .:    2
  K AA1:  1
  AA1 B:  1
  B .:    2
  . B:    1
  B AE1:  1
  . T:    1
  T AE1:  1
  T S:    1
  S .:    1
  . M:    1
  M AA1:  1
  AA1 R:  1
  R K:    1
  K .:    1
  AE1 B:  1

  [(., K), (K, AE1), (AE1, T), (T .)]
  [3, 2, 3, 2]
  [3/26, 2/26, 3/26, 2/26]
  36/(26^4) = 7.9e-5
  =#
  p = prod([3,2,3,2]/26)
  desired = DataFrame(Query=[["K", "AE1", "T"]], Probability=[p])
  prb = phnprb(SAMPLE_CORPUS, freq, [["K", "AE1", "T"]]; nchar=2)
  @test prb == desired

  #=
  **Co-occurrence diphones, no padding**

  14 total diphones
  K  AE1: 2
  AE1 T:  3
  K AA1:  1
  AA1 B:  1
  B AE1:  1
  T AE1:  1
  T S:    1
  M AA1:  1
  AA1 R:  1
  R K:    1
  AE1 B:  1

  [(K, AE1), (AE1, T)]
  [2, 3]
  [3/14, 2/14] # take product
  6/(14^2) = 7.9e-5
  =#
  p = prod([3,2]/14)
  desired = DataFrame(Query=[["K", "AE1", "T"]], Probability=[p])
  prb = phnprb(SAMPLE_CORPUS, freq, [["K", "AE1", "T"]]; nchar=2, pad=false)
  @test prb == desired

  #=
  **Positional*

  20 total monophones
  K 1:    3
  AE1 2:  4
  AA1 2:  2
  B 3:    2
  B 1:    1
  T 3:    3
  T 1:    1
  S 4:    1
  M 1:    1
  R 3:    1
  K 4:    1

  ["K", "AE1", "T"], get counts
  [3, 4, 3], divide by total monophones
  [3/20, 4/20, 3/20], take product
  36/8000 = 0.0045
  =#
  p = prod([3,4,3]/20)
  desired = DataFrame(Query=[["K", "AE1", "T"]], Probability=[p])
  prb = phnprb(SAMPLE_CORPUS, freq, [["K", "AE1", "T"]]; positional=true)
  @test prb == desired

  # Phone not in corpus
  p = 0
  desired = DataFrame(Query=[["K", "AE1", "F"]], Probability=[p])
  @test phnprb(SAMPLE_CORPUS, freq, [["K", "AE1", "F"]]) == desired

  # With non-1 frequencies; doubling each frequency should produce same output
  freq = [2,2,2,2,2,2]
  p = prod([8,8,8] / 40)
  desired = DataFrame(Query=[["K", "AE1", "T"]], Probability=[p])
  prb = phnprb(SAMPLE_CORPUS, freq, [["K", "AE1", "T"]])
  @test prb == desired

end

@testset "Vantage point tree" begin

  tree = TextVPTree(SAMPLE_CORPUS, lev)

  # Test nneighbors
  res = collect(keys(nneighbors(tree, ["K", "AE1", "T"], 2)))
  res = sort(join.(res, " "))
  @test res == ["B AE1 T", "K AE1 B"]

  ## Test on point not inside of the tree
  res = collect(keys(nneighbors(tree, ["HH", "AE1", "T"], 2)))
  res = sort(join.(res, " "))
  @test res == ["B AE1 T", "K AE1 T"]

  # Test radius search
  res = radiusSearch(tree, ["K", "AE1", "T"], 1)
  res = sort(join.(res, " "))
  @test res == ["B AE1 T", "K AE1 B"]

  ## Test on point not inside of the tree
  res = radiusSearch(tree, ["HH", "AE1", "T"], 1)
  res = sort(join.(res, " "))
  @test res == ["B AE1 T", "K AE1 T"]

end