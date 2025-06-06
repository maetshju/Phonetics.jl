# Spectrograms

A basic function is provided to plot spectrograms that look familiar to phoneticians. It makes use of the `spectrogram` function from `DSP.jl` to perform the short-time Fourier analysis. The plot specification is given using `RecipesBase.jl` to avoid depending on `Plots.jl`. It is necessary to specify `using Plots` before spectrograms can be plotted.

## Examples	

A standard broadband spectrogram can be created without using optional parameters.

```@example
using Phonetics # hide
using WAV
using Plots
s, fs = wavread("assets/iwantaspectrogram.wav")
s = s[:,1]
phonspec(s, fs, xlab="Time (s)", ylab="Frequency (Hz)")
```

A color scheme more similar to the Praat grayscale can be achieved using the `color` argument from `Plots.jl` and the `:binary` color scheme. These spectrograms are created using the `heatmap` function from `Plots.jl`, so [any color scheme available in the Plots package](https://docs.juliaplots.org/stable/generated/colorschemes/) can be used, though not all of them produce legible spectrograms.

```@example
using Phonetics # hide
using WAV # hide
s, fs = wavread("assets/iwantaspectrogram.wav") # hide
s = vec(s) # hide
using Plots # hide
phonspec(s, fs, xlab="Time (s)", ylab="Frequency (Hz)", color=:binary)
```

A narrowband style spectrogram can be plotted using the `winlen` argument:

```@example
using Phonetics # hide
using WAV # hide
s, fs = wavread("assets/iwantaspectrogram.wav") # hide
s = s[:,1] # hide
using Plots # hide
phonspec(s, fs, xlab="Time (s)", ylab="Frequency (Hz)", winlen=0.03)
```

And, the pre-emphasis can be disabled by passing in a value of 0 for the `pre_emph` argument. Pre-emphasis will boost the prevalence of the higher frequencies in comparison to the lower frequencies.

```@example
using Phonetics # hide
using WAV # hide
using Plots # hide
s, fs = wavread("assets/iwantaspectrogram.wav") # hide
s = s[:,1] # hide
phonspec(s, fs, pre_emph=0, xlab="Time (s)", ylab="Frequency (Hz)")
```

The dB scale can be made to reflect one more similar to Praat's using the `db` argument set to `:spl`. The spectrogram image does not change, and the `dbr` argument will function the same, but the scale on the legend for the heatmap will change and be similar to how Praats calculates dB.

```@example
using Phonetics # hide
using WAV # hide
using Plots # hide
s, fs = wavread("assets/iwantaspectrogram.wav") # hide
s = s[:,1] # hide
phonspec(s, fs, xlab="Time (s)", ylab="Frequency (Hz)", db=:spl)
```

# Function documentation

```@docs
phonspec
```
