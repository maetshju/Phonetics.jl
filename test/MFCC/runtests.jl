## runtests.jl  Unit tests for MFCC
## (c) 2015 David A. van Leeuwen
##
## Licensed under the MIT software license, see LICENSE.md in MFCC module
##
## Updated (trivially) 2022 by Matthew C. Kelley

using WAV
using SpecialFunctions
using Statistics

base, _ = splitdir(@__FILE__)
x, meta, params = feacalc(joinpath(base, "bl2.wav"), normtype=:none, method=:wav, augtype=:none, sadtype=:none)
y = feaload(joinpath(base, "bl2.mfcc"))

@assert x == y

z = warp(x)
z = deltas(x)
z = znorm(x)
z = stmvn(x)

x = randn(100000)
p = powspec(x)
a = audspec(p)

println("Tests passed")
