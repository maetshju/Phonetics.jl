# Spectrograms

A basic function is provided to plot spectrograms that look familiar to phoneticians. It makes use of the `spectrogram` function from `DSP.jl` to perform the short-time Fourier analysis.

## Examples	

A standard broadband spectrogram can be created without using optional parameters.

```@example
using Phonetics # hide
using WAV
s, fs = wavread("assets/iwantaspectrogram.wav")
s = vec(s)
phonspec(s, fs)
```

A color scheme more similar to the Praat grayscale can be achieved using the `col` argument:

```@example
using Phonetics # hide
using WAV # hide
s, fs = wavread("assets/iwantaspectrogram.wav") # hide
s = vec(s) # hide
using Plots
rev_grays = reverse(cgrad(:grays))
phonspec(s, fs, col=rev_grays)
```

A narrowband style spectrogram can be plotted using the `style` argument:

```@example
using Phonetics # hide
using WAV # hide
s, fs = wavread("assets/iwantaspectrogram.wav") # hide
s = vec(s) # hide
phonspec(s, fs, style=:narrowband)
```

And, the pre-emphasis can be disabled by passing in a value of 0 for the `pre_emph` argument:

```@example
using Phonetics # hide
using WAV # hide
s, fs = wavread("assets/iwantaspectrogram.wav") # hide
s = vec(s) # hide
phonspec(s, fs, pre_emph=0)
```

# Function documentation

```@docs
phonspec(s::Vector, fs; pre_emph=0.97, col=:magma, style=:broadband, dbr=55, size=(600, 400))
```