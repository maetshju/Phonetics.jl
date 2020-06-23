# Vowel plotting

The function provided for plotting vowels diplays offers a variety of visualization techniques for displaying a two-dimensional plot for vowel tokens. Traditionally, it is F1 and F2 that are plotted, but any two pairs of data can be plotted, such as F2 and F3, F2-F1 and F3, etc.

## Examples

```@example
using Phonetics # hide
using Plots # hide
data = generateFormants(30, gender=[:w], seed=56) # hide
vowelPlot(data.f1, data.f2, data.vowel, xlab="F1 (Hz)", ylab="F2 (Hz)")
savefig("vanilla_vowel_plot.svg") # hide
nothing # hide
```
![Vanilla vowel plot](vanilla_vowel_plot.svg)

This is a traditional vowel plot, with F1 on the x-axis in increasing order and F2 on the y-axis in increasing order. Note that simulated data were generated using the `generateFormants` function. Specifying a seed value makes the results reproducible. (Keep in mind that if you are generating values for different experiments, reports, studies, etc., the seed value needs to be changed (or left unspecified) so that the same data are not generated every time when they shouldn't be reproducible.)

For those inclined to use the alternate axes configuration with F2 decreasing on the x-axis and F1 decreasing on the y-axis, the `xflip` and `yflip` arguments that the `Plots.jl` package makes use of can be passed in to force the axes to be decreasing, the F2 values can be passed into the first argument slot, and the F1 values can be passed into the second argument slot.

```@example
using Phonetics # hide
using Plots # hide
data = generateFormants(30, gender=[:w], seed=56) # hide
vowelPlot(data.f2, data.f1, data.vowel,
  xflip=true, yflip=true, xlab="F2 (Hz)", ylab="F1 (Hz)")
savefig("alt_axes_vowel_plot.svg") # hide
nothing # hide
```

![Vowel plot with alternate axes](alt_axes_vowel_plot.svg)

I don't personally prefer to look at vowel plots in this manner because I think it unfairly privileges articulatory characteristics of vowel production when examining acoustic characteristics, so subsequent examples will not be presented using this axis configuration. However, the same principle applies to switching the axes around.

The `vowelPlot` function also allows for ellipses to be plotted around the values with the `ell` and `ellPercent` arguments. The `ell` argument takes a `true` or `false` value. The `ellPercent` argument should be a value between greater than 0 and less than 1, and it represents the approximate percentage of the data the should be contained within the ellipse. This is in contrast to some packages available in `R` that allow you to specify the number of standard deviations that the ellipse should be stretched to. The reason is that the traditional cutoff values of 1 standard deviation for 67%, 2 standard deviations for 95%, etc. for univariate Gaussian distributions does not carry over to multiple dimensions. While, the appropriate amount of stretching of the ellipse can be determined from the percentage of data to contain (Wang et al., 2015).

```@example
using Phonetics # hide
using Plots # hide
data = generateFormants(30, gender=[:w], seed=56) # hide
vowelPlot(data.f1, data.f2, data.vowel, ell=true, ellPercent=0.67,
  xlab="F1 (Hz)", ylab="F2 (Hz)")
savefig("ellipse_vowel_plot.svg") # hide
nothing # hide
```

![Vowel plot with ellipses](ellipse_vowel_plot.svg)

Each of the data clouds in the scatter have an ellipse overlaid on them so as to contain 67% of the data. The ellipse calculation process is given in Friendly et al. (2013).

One final feature to point out is that the `vowelplot` function can also plot just the mean value of each vowel category with the `meansOnly` argument. Additionally, a label can be added to each category with the `addLabels` argument, which bases the labels on the category given in the `cats` argument.

```@example
using Phonetics # hide
using Plots # hide
data = generateFormants(30, gender=[:w], seed=56) # hide
vowelPlot(data.f1, data.f2, data.vowel, ell=true,
  meansOnly=true, addLabels=true, xlab="F1 (Hz)", ylab="F2 (Hz)")
savefig("means_only_ellipse_vowel_plot.svg") # hide
nothing # hide
```

![Vowel plot with ellipses and markers only for mean values](means_only_ellipse_vowel_plot.svg)

The labels are offset from the mean value a bit so as to not cover up the marker showing where the mean value is.

## Function documentation

```@docs
vowelPlot(f1, f2, cats; [meansOnly=false, addLabels=true, ell=false,
  ellPercent=0.67, nEllPts=500, markersize=1, linewidth=2, kw...])
```

```@docs
ellipsePts(f1, f2; percent=0.95, nPoints=500)
```

## References

Friendly, M., Monette, G., & Fox, J. (2013). Elliptical insights: understanding statistical methods through elliptical geometry. *Statistical Science, 28*(1), 1-39.

Wang, B., Shi, W., & Miao, Z. (2015). Confidence analysis of standard deviational ellipse and its extension into higher dimensional Euclidean space. *PLOS ONE, 10*(3), e0118537. [https://doi.org/10.1371/journal.pone.0118537](https://doi.org/10.1371/journal.pone.0118537)