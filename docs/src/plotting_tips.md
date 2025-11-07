# Plotting tips

The plots in `Phonetics.jl` are created from `RecipesBase.jl`, which means they benefit from the full set of features available to plots created with `Plots.jl`. A significant amount of information about how plots work is contained in [the documentation for `Plots.jl`](https://docs.juliaplots.org/latest/).

The tips here are written with phoneticians and the kinds of plots we make in mind. In general, these tips are highlighting specific features that come from `Plots.jl`.

## Errors about combinations of argument types

If you run code similar to the following, you will get an error:

```julia
using Phonetics
using WAV
s, fs = wavread("assets/iwantaspectrogram.wav")
s = s[:,1]
phonspec(s, fs)
```

The error would look similar to the following:

```
ERROR: MethodError: no method matching plot(::Phonetics.PhonSpec)
The function `plot` exists, but no method is defined for this combination of argument types.
Stacktrace:
 [1] phonspec(::Vector{Float64}, ::Vararg{Any}; kw::@Kwargs{})
   @ Phonetics ~/.julia/packages/RecipesBase/BRe07/src/RecipesBase.jl:380
 [2] top-level scope
   @ REPL[11]:1
```

### Resolution

To resolve this, you simply need to run `using Plots` before you use a function like `phonspec`.

```@example
using Phonetics
using Plots
using WAV
s, fs = wavread("assets/iwantaspectrogram.wav")
s = s[:,1]
phonspec(s, fs)
```

The reason for this is that the code in `Phonetics.jl` contains instructions for `Plots.jl` for how to make plots like the spectrogram. However, the code does not literally create the plot, which `Plots.jl` is required for. This choice was made so as to make the `Phonetics.jl` package less heavy and take less time to compile, by avoiding relying on `Plots.jl` directly.

## Creating a waveform plot

A basic waveform plot can be created using the samples from an audio file, with no need for functions or structs from `Phonetics.jl`

```@example
using Phonetics # hide
using WAV
using Plots
s, fs = wavread("assets/iwantaspectrogram.wav")
s = s[:,1]
t = (1:length(s)) ./ fs
plot(t, s, xlab="Time (s)", ylab="Amplitude", label="")
```

Consult the [`Plots.jl`](https://docs.juliaplots.org/latest/) documentation for more information on customizing a plot like this.

## Combining a spectrogram and waveform plot

A waveform can be plotted in a grid with a spectrogram using [layouts](https://docs.juliaplots.org/latest/layouts/) from `Plots.jl`. A basic example might look like this. **Note**: The `widen=false` argument for the waveform is necessary to ensure that the beginning and end of the waveform line up with the spectrogram.

```@example
using Phonetics # hide
using WAV
using Plots
s, fs = wavread("assets/iwantaspectrogram.wav")
s = s[:,1]
t = (1:length(s)) ./ fs
waveform = plot(t, s, xlab="Time (s)", ylab="Amplitude", label="", grid=false, widen=false)
spectrogram = phonspec(s, fs, xlab="Time (s)", ylab="Frequency (Hz)", colorbar=false)
plot(waveform, spectrogram, layout=grid(2, 1, heights=[0.3, 0.7]))
```

These plots can actually be called directly inside of another `plot` function.

```@example
using Phonetics # hide
using WAV # hide
using Plots # hide
s, fs = wavread("assets/iwantaspectrogram.wav") # hide
s = s[:,1] # hide
t = (1:length(s)) ./ fs # hide
plot(
    plot(t, s, xlab="Time (s)", ylab="Amplitude", label="", grid=false, widen=false),
    phonspec(s, fs, xlab="Time (s)", ylab="Frequency (Hz)", colorbar=false),
    layout=grid(2, 1, heights=[0.3, 0.7])
)
```

The relative sizes and placements can be controlled using the different layout functionalities in `Plots.jl`.

The axes can be removed from the waveform with the `xaxis` and `yaxis` arguments if desired.

```@example
using Phonetics # hide
using WAV # hide
using Plots # hide
s, fs = wavread("assets/iwantaspectrogram.wav") # hide
s = s[:,1] # hide
t = (1:length(s)) ./ fs # hide
plot(
    plot(t, s, xaxis=false, yaxis=false, xlab="Time (s)", ylab="Amplitude", label="", grid=false, widen=false),
    phonspec(s, fs, xlab="Time (s)", ylab="Frequency (Hz)", colorbar=false),
    layout=grid(2, 1, heights=[0.3, 0.7])
)
```
