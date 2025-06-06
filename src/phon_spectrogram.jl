using DSP
using RecipesBase

"""
phonspec(s, fs; pre_emph=0.97, dbr=55, win=:gaussian,
			winparam=nothing, winlen=0.005, winstep=0.002,
			db=:rel, kw...)
	
Rudimentary functionality to plot a spectrogram, with parameters familiar to phoneticians. Includes a pre-emphasis routine which helps increase the intensity of the
higher frequencies in the display. Defaults to a Gaussian window with a standard deviation of 1/6.

For a **broadband** spectrogram, use a value around 0.005 for `winlen`. For a **narrowband** spectrogram, use a value around 0.03 for `winlen`.

Argument structure inferred from using plot recipe. Parameters such as `xlim`,
`ylim`, `color`, and `size` should be passed as keyword arguments, as with standard calls
to `plot`.

Args
=====

* `s` A vector containing the samples of a sound
* `fs` Sampling frequency of `s` in Hz
* `pre_emph` The α coefficient for pre-emmphasis; default value of 0.97 corresponds to a cutoff frequency of approximately 213 Hz before the 6 dB / octave increase begins
* `dbr` The dynamic range; all frequencies that are `dbr` decibels quieter than the loudest frequency will not be displayed; will specify the `clim` argument
* `win` The type of window to use; must be one of `:gaussian` or `:kaiser`
* `winparam` The parameter affecting the scale of the window; if nothing passed, uses 1/6 for a Gaussian window or 3 for a Kaiser window
* `winlen` The length of the window in seconds (note that this value gets doubled in the code)
* `winstep` How far apart each window is in seconds
* `db` How to calculate the scale for decibels; these options result in the same spectrogram image and same functionality of `dbr`, but the numbers on the heatmap scale will change
	* `:rel` will scale all intensities relative to the loudest frequency component
	* `:spl` will use a scale relative to Praat's normative threshold (that is, relative to (2e-5)^2 Pa), which produces a scale similar to Praat's
* `kw...` extra named parameters to pass to `heatmap`
"""
phonspec

@userplot PhonSpec
@recipe function f(p::PhonSpec; pre_emph=0.97, dbr=55, win=:gaussian,
					   winparam=nothing, winlen=0.005, winstep=0.002,
					   db=:rel)

	if length(p.args) != 2
		error("Must pass 2 arguments for spectrogram, `s` the samples and `fs` the sampling frequency")
	end
	s, fs = p.args

	pre_emph_filt = PolynomialRatio([1, -pre_emph], [1])
	s = filt(pre_emph_filt, s)

	nfft = max(1024, nextpow(2, winlen*2 * fs))
	n = ceil(Int, winlen*fs)
	nov = n*2 - floor(Int, winstep * fs)
	if win == :gaussian
		w = gaussian(n*2, isnothing(winparam) ? 1/6 : winparam)
	else
		w = kaiser(n*2, isnothing(winparam) ? 3 : winparam)
	end
	spec = spectrogram(s, n*2, nov, fs=fs, window = w, nfft=nfft)

	if db == :rel
		spec_mx = maximum(spec.power)
		db = 10 .* log10.(spec.power ./ spec_mx)
		clim := (-dbr, 0)
	elseif db == :spl
		db = 10 .* log10.(spec.power ./ 2e-5^2)
		spec_mx = maximum(db)
		clim := (spec_mx - dbr, spec_mx)
	end
	
	# Important to use ":heatmap" and not "heatmap";
	# "heatmap" is a function, not a symbol, and it
	# causes the plot to be patchy instead of throwing
	# an error
	seriestype := :heatmap
	ylim --> (0, 5000)
	spec.time, spec.freq, db
end

