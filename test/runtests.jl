using Phonetics
using Test
using DelimitedFiles
using StatsBase
using DataFrames
using Statistics
using Random
using DynamicAxisWarping
using Distances

@testset "Vowel space and density" begin

  f = Formants("sample_formants.txt")
  v = VowelSpace(f)
  @test area(v, unstandardize=true) ≈ 1920.3803415872135
  @test vdi(v, unstandardize=true) ≈ 766.8716362331788
end

@testset "Random formant generation" begin

  dat = generateFormants(10^7, cats=[:uw], gender=[:w])
  datμ = mean(Array(dat[:, 1:2]), dims=1)
  @test isapprox(datμ, [459.67 1105.52], atol=1)

  dat = generateFormants(10^7, cats=[:aa], gender=[:w])
  datμ = mean(Array(dat[:, 1:2]), dims=1)
  @test isapprox(datμ, [916.36 1525.83], atol=1)

  dat = generateFormants(30, cats=[:iy, :aa], gender=[:w, :m])
  @test dat.vowel == repeat([:iy, :aa], inner=60)
  @test dat.gender == repeat([:w, :m], inner=30, outer=2)
end

@testset "Normalization" begin

  dat = generateFormants(50)
  # Use gender as speaker for tests to give two separate speakers

  lobCustom = copy(dat)
  rename!(lobCustom, :gender => :speaker)

  lobCustom[lobCustom.speaker .== :m, :f1] = zscore(lobCustom[lobCustom.speaker .== :m, :f1])
  lobCustom[lobCustom.speaker .== :w, :f1] = zscore(lobCustom[lobCustom.speaker .== :w, :f1])

  lobCustom[lobCustom.speaker .== :m, :f2] = zscore(lobCustom[lobCustom.speaker .== :m, :f2])
  lobCustom[lobCustom.speaker .== :w, :f2] = zscore(lobCustom[lobCustom.speaker .== :w, :f2])

  lobFunc = lobanov(dat.f1, dat.f2, dat.vowel, dat.gender)
  # check for approximate equality because sum and related functions
  # called on the view genereated by `groupby` produces a different value
  # than sum called on the original array (due to how the view is generated
  #  and how order matters when performing sequential floating point operations).
  @test lobCustom.f1 ≈ lobFunc.f1
  @test lobCustom.f2 ≈ lobFunc.f2
  @test lobCustom.vowel == lobFunc.vowel
  @test lobCustom.speaker == lobFunc.speaker

  nICustom = copy(dat)
  rename!(nICustom, :gender => :speaker)

  mf1 = nICustom[nICustom.speaker .== :m, :f1]
  nICustom[nICustom.speaker .== :m, :f1] = log.(mf1) .- mean(log.(mf1))
  wf1 = nICustom[nICustom.speaker .== :w, :f1]
  nICustom[nICustom.speaker .== :w, :f1] = log.(wf1) .- mean(log.(wf1))

  mf2 = nICustom[nICustom.speaker .== :m, :f2]
  nICustom[nICustom.speaker .== :m, :f2] = log.(mf2) .- mean(log.(mf2))
  wf2 = nICustom[nICustom.speaker .== :w, :f2]
  nICustom[nICustom.speaker .== :w, :f2] = log.(wf2) .- mean(log.(wf2))
  
  nIFunc = neareyI(dat.f1, dat.f2, dat.vowel, dat.gender)
  @test nICustom.f1 ≈ nIFunc.f1
  @test nICustom.f2 ≈ nIFunc.f2
  @test nICustom.vowel == nIFunc.vowel
  @test nICustom.speaker == nIFunc.speaker

  nECustom = copy(dat)

  rename!(nECustom, :gender => :speaker)

  mf1 = nECustom[nECustom.speaker .== :m, :f1]
  mfall = [mf1; nECustom[nECustom.speaker .== :m, :f2]]
  nECustom[nECustom.speaker .== :m, :f1] = log.(mf1) .- mean(log.(mfall))

  wf1 = nECustom[nECustom.speaker .== :w, :f1]
  wfall = [wf1; nECustom[nECustom.speaker .== :w, :f2]]
  nECustom[nECustom.speaker .== :w, :f1] = log.(wf1) .- mean(log.(wfall))

  mf2 = nECustom[nECustom.speaker .== :m, :f2]
  nECustom[nECustom.speaker .== :m, :f2] = log.(mf2) .- mean(log.(mfall))

  wf2 = nECustom[nECustom.speaker .== :w, :f2]
  nECustom[nECustom.speaker .== :w, :f2] = log.(wf2) .- mean(log.(wfall))

  nEFunc = neareyE(dat.f1, dat.f2, dat.vowel, dat.gender)
  @test nECustom.f1 ≈ nEFunc.f1
  @test nECustom.f2 ≈ nEFunc.f2
  @test nECustom.vowel == nEFunc.vowel
  @test nECustom.speaker == nEFunc.speaker
end

@testset "Acoustic distance" begin

  rng = MersenneTwister(9)
  x = rand(rng, 1000)
  y = rand(rng, 3000)
  z = rand(rng, 10000)
  a = [Sound(x, 8000), Sound(y, 8000), Sound(z, 8000)]
  amfcc = Phonetics.sound2mfcc.(a)
  @test acdist(a[1], a[2]) ≈ dtw(amfcc[1], amfcc[2])[1]
  @test distinctiveness(a[1], a[2:3]) ≈ mean([acdist(a[1], a[2]), acdist(a[1], a[3])])
  dtwr = maximum(size(s, 2) for s in amfcc)
  @test avgseq(a) == dba(amfcc, DTW(dtwr, SqEuclidean()), init_center=amfcc[2], show_progress=false)[1]
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