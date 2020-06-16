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
  speaker = repeat([1], length(f1))

  lobCustom = DataFrame(f1=zscore(f1), f2=zscore(f2), speaker=speaker)
  lobFunc = lobanov(f1, f2, speaker)
  # use check for approximate equality because sum and related functions
  # called on the view genereated by `groupby` produces a different value
  # than sum called on the original array (due to how the view is generated
  #  and how order matters when performing sequential floating point operations).
  @test lobCustom.f1 ≈ lobFunc.f1
  @test lobCustom.f2 ≈ lobFunc.f2
  @test lobCustom.speaker ≈ lobFunc.speaker

  nICustom = DataFrame(f1=log.(f1) .- mean(log.(f1)), f2=log.(f2) .- mean(log.(f2)), speaker=speaker)
  nIFunc = neareyI(f1, f2, speaker)
  @test nICustom.f1 ≈ nIFunc.f1
  @test nICustom.f2 ≈ nIFunc.f2
  @test nICustom.speaker ≈ nIFunc.speaker

  nECustom = DataFrame(f1=log.(f1) .- mean(log.([f1; f2])), f2=log.(f2) .- mean(log.([f1; f2])), speaker=speaker)
  nEFunc = neareyE(f1, f2, speaker)
  @test nECustom.f1 ≈ nEFunc.f1
  @test nECustom.f2 ≈ nEFunc.f2
  @test nECustom.speaker ≈ nEFunc.speaker
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