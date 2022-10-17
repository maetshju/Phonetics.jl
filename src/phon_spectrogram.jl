using DSP
using Plots

"""
	phonspec(s, fs; pre_emph=0.97, col=:magma, style=:broadband, dbr=55, size=(600, 400))
	
Rudimentary functionality to plot a spectrogram, with parameters familiar to phoneticians.
Includes a pre-emphasis routine which helps increase the intensity of the
higher frequencies in the display. Uses a Kaiser window with a parameter
value of 2.

Args
=====

* `s` A vector containing the samples of a sound
* `fs` Sampling frequency of `s` in Hz
* `pre_emph` The α coefficient for pre-emmphasis; default value of 0.97 corresponds to a cutoff frequency of approximately 213 Hz before the 6 dB / octave increase begins
* `col` Color scheme for the spectrogram
* `style` Either `:broadband` or `:narrowband`; will affect the window length and window stride
* `dbr` The dynamic range; all frequencies that are `dbr` decibels quieter than the loudest frequency will not be displayed
* `size` Size of plot in pixels; passed to `heatmap` call
"""
function phonspec(s::Vector, fs; pre_emph=0.97, col=:magma, style=:broadband, dbr=55, size=(600, 400))
	pre_emph_filt = PolynomialRatio([1, -pre_emph], [1])
	s = filt(pre_emph_filt, s)
	if style == :broadband
		winlen = 0.005
	elseif style == :narrowband
		winlen = 0.05
	end
	nfft = max(1024, nextpow(2, winlen * fs))
	n = floor(Int, winlen*fs)
	nov = n - floor(Int, 0.002 * fs)
	spec = spectrogram(s, n, nov, fs=fs, window = n -> kaiser(n, 2), nfft=nfft)
	spec_mx = maximum(spec.power)
	db = 10 .* log10.(spec.power ./ spec_mx)
	heatmap(spec.time, spec.freq, db, color=cgrad(col), ylim=(0, 5000), clim=(-dbr, 0), size=size)
end
