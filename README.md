[![Build Status](https://github.com/maetshju/Phonetics.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/maetshju/Phonetics.jl/actions/workflows/ci.yml)

[![codecov](https://codecov.io/gh/maetshju/Phonetics.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/maetshju/Phonetics.jl)

[![docs](https://img.shields.io/badge/docs-release-green)](https://maetshju.github.io/Phonetics.jl)

<img src="imgs/logo.svg" width="100" alt="Phonetics.jl logo: A capital P with a sine wave traveling through it">

Currently under development. Some function interfaces may break from time to time while in an alpha-release state.

This package is currently unregistered. Install with

```julia
] add https://github.com/maetshju/phonetics.jl
```

Phonetics.jl is a collection of functions that are useful for processing phonetic data. "Phonetic data" is a term used in a broad sense to include, for example, transcriptions, sound files, and acoustic measurements like formant values. Functions are added to this package over time. Most functions are described in the documentation.

As an example, a recording of the sentence "I want a spectrogram" can be plotted with the following bit of code:

```
using Phonetics
using WAV
s, fs = wavread("iwantaspectrogram.wav")
s = vec(s)
phonspec(s, fs)
```

![A spectrogram of the phrase "I want a spectrogram"](imgs/iwantaspectrogram.png)