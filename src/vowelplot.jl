using Plots
using DataFrames
using LinearAlgebra
using Distributions

function vowelPlot(f1, f2, cats; kw...)
  d = DataFrame(f1=f1, f2=f2, cat=cats)
  groups = groupby(d, :cat)
  p = Plots.scatter(groups[1].f1, groups[1].f2, type=:scatter; kw...)

  for g in groups[2:end]
    p = Plots.scatter!(g.f1, g.f2)
  end
  return p
end

"""
    ellipsePts(f1, f2; percent=0.95, nPoints=1000)

Calculates `nPoints` points of the perimeter of a data ellipse for `f1` and `f2` with `percent` amount of the data contained within the ellipse.

See Friendly, Monette, and Fox (2013, Elliptical insights: Understanding statistical methods through elliptical geometry, Statistical science 28(1), 1-39) for more information on the fitting process.

Args
=====

* `f1` F1 values to calculate the ellipse for
* `f2` F2 values to calculate the ellipse for
* `percent` (keyword) Percent (expressed as a decmial) of the data to be contained within the ellipse
* `nPoints` (keyword) Number of points to use when calculating the perimeter of the ellipse

Returns
========

An `nPoints`×2 `Array` of points along the perimeter of the ellipse, ordered counter-clockwise as the polar angle of rotation moves from 0 to 2π
"""
function ellipsePts(f1, f2; percent=0.95, nPoints=1000)
  Σ = cov(hcat(f1, f2))
  L = cholesky(Σ).L

  r = sqrt(quantile(Chisq(2), percent))
  t = range(0, 2π, length=nPoints)
  S = hcat(cos.(t), sin.(t)) .* r

  pts = L * S'
  pts[1,:] .+= mean(f1)
  pts[2,:] .+= mean(f2)
  Array(pts')
end