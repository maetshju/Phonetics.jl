using Plots
using DataFrames
using LinearAlgebra
using Distributions

"""
    vowelPlot(f1, f2, cats; [meansOnly=false, addLabels=true, ell=false, ellPercent=0.67, nEllPts=500, kw...])

Create an F1-by-F2 vowel plot. The `f1` values are displayed along the x-axis, and the `f2` values are displayed along the y-axis, with each unique vowel class in `cats` being represented with a new color. The series labels in the legend will take on the unique values contained in `cats`. The alternate display whereby reversed F2 is on the x-axis and reversed F1 is on the y-axis can be created by passing the F2 values in for the `f1` argument and F1 values in for the `f2` argument, and then using the `:flip` magic argument provided by the `Plots` package.

If `meansOnly` is set to true, only the mean values for each vowel category are plotted. Using `ell=true` will plot a data ellipse that approximately encompases the percentage of data specified by `ellPercent`. The ellipse is represented by a number of points specified with `nEllPts`. Other arguments to `plot` are passed in through the splatted `kw` argument. Setting the `addLabels` argument to `true` will add the text label of the vowel category above and to the right of the mean.

Args
======

* `f1` The F1 values, or otherwise the values to plot on the x-axis
* `f2` The F2 values, or otherwise the values to plot on the y-axis
* `cats` The vowel categories associated with each F1, F2 pair
* `meansOnly` (keyword) Plot only mean value for each category
* `addLabels` (keyword) Add labels for each category to the plot near the mean
* `ell` (keyword) Whether to add data ellipses to the plot
* `ellPercent` (keyword) How much of the data distribution the ellipse should cover (approximately)
* `nEllPts` (keyword) How many points should be used when plotting the ellipse
"""
function vowelPlot(f1, f2, cats; meansOnly=false, addLabels=false, ell=false, ellPercent=0.67, nEllPts=500, kw...)
  d = DataFrame(f1=f1, f2=f2, cat=cats)
  groups = groupby(d, :cat)

  if meansOnly
    p = Plots.scatter([mean(groups[1].f1)], [mean(groups[1].f2)], label=groups[1].cat[1]; kw...)
  else
    p = Plots.scatter(groups[1].f1, groups[1].f2, label=groups[1].cat[1]; kw...)
  end

  jt1 = abs(mean(f1) / 20)
  jt2 = abs(mean(f2) / 20)

  if addLabels
    p = annotate!(mean(groups[1].f1) + jt1, mean(groups[1].f2) + jt2, text(groups[1].cat[1], color=palette(:auto)[1]))
  end

  if ell
    e = ellipsePts(groups[1].f1, groups[1].f2, percent=ellPercent, nPoints=nEllPts)
    p = Plots.plot!(e[:,1], e[:,2], label="", color=1)
  end

  for (i, g) in enumerate(groups)
    if i == 1 continue end

    if meansOnly
      p = Plots.scatter!([mean(g.f1)], [mean(g.f2)], label=g.cat[1], color=i)
    else
      p = Plots.scatter!(g.f1, g.f2, label=g.cat[1], color=i)
    end

    if addLabels
      p = annotate!(mean(g.f1) + jt1, mean(g.f2) + jt2, text(g.cat[1], color=palette(:auto)[i]))
    end

    if ell
      e = ellipsePts(g.f1, g.f2, percent=ellPercent, nPoints=nEllPts)
      p = Plots.plot!(e[:,1], e[:,2], label="", color=i)
    end
  end
  return p
end

"""
    ellipsePts(f1, f2; percent=0.95, nPoints=500)

Calculates `nPoints` points of the perimeter of a data ellipse for `f1` and `f2` with approximately the percent of the data spcified by `percent` contained within the ellipse. Points are returned in counter-clockwise order as the polar angle of rotation moves from 0 to 2π.

See Friendly, Monette, and Fox (2013, Elliptical insights: Understanding statistical methods through elliptical geometry, Statistical science 28(1), 1-39) for more information on the calculation process.

Args
======

* `f1` The F1 values or otherwise x-axis values
* `f2` The F2 values or otherwise y-axis values
* `percent` (keyword) Percent of the data distribution the ellipse should approximately cover
* `nPoints` (keyword) How many points to use when drawing the ellipse
"""
function ellipsePts(f1, f2; percent=0.95, nPoints=500)
  Σ = cov(hcat(f1, f2))
  L = cholesky(Σ).L

  # we have two dimensions (F1 and F2), so the chisq distribution has
  # two degrees of freedom
  r = sqrt(quantile(Chisq(2), percent))
  t = range(0, 2π, length=nPoints)
  S = hcat(cos.(t), sin.(t)) .* r

  pts = L * S'
  pts[1,:] .+= mean(f1)
  pts[2,:] .+= mean(f2)
  return Array(pts')
end