using RecipesBase
using DataFrames
using LinearAlgebra
using Distributions

"""
    vowelplot(f1, f2, cats; meansOnly=false, addLabels=true, ell=false, ellPercent=0.67, nEllPts=500, kw...)

Create an F1-by-F2 vowel plot. The `f1` values are displayed along the x-axis, and the `f2` values are displayed along the y-axis, with each unique vowel class in `cats` being represented with a new color. The series labels in the legend will take on the unique values contained in `cats`. The alternate display whereby reversed F2 is on the x-axis and reversed F1 is on the y-axis can be created by passing the F2 values in for the `f1` argument and F1 values in for the `f2` argument, and then using the `:flip` magic argument provided by the `Plots` package.

If `meansOnly` is set to true, only the mean values for each vowel category are plotted. Using `ell=true` will plot a data ellipse that approximately encompases the percentage of data specified by `ellPercent`. The ellipse is represented by a number of points specified with `nEllPts`. Other arguments to `plot` are passed in through the splatted `kw` argument. Setting the `addLabels` argument to `true` will add the text label of the vowel category above and to the right of the mean.

Argument structure inferred from using plot recipe. Parameters such as `xlim`, `ylim`, `color`, and `size` should be passed as keyword arguments, as with standard calls to `plot`. Plot parameters `markersize` defaults to `3` and `linewidth` defaults to 3.

Args
======

* `f1` The F1 values, or otherwise the values to plot on the x-axis
* `f2` The F2 values, or otherwise the values to plot on the y-axis
* `cats` The vowel categories associated with each F1, F2 pair
* `meansOnly` Plot only mean value for each category
* `addLabels` Add labels for each category to the plot near the mean
* `ell` Whether to add data ellipses to the plot
* `ellPercent` Percentage of the data distribution the ellipse should cover (approximately)
* `nEllPts` How many points should be used when plotting the ellipse
"""
vowelplot

@userplot VowelPlot
@recipe function f(v::VowelPlot; meansOnly=false, addLabels=false, ell=false, ellPercent=0.67, nEllPts=500)
	if length(v.args) != 3
		error("Must pass 3 arguments: `f1` the F1 values, `f2` the F2 values, and `cats` the vowel categories")
	end
	f1, f2, cats = v.args
	d = DataFrame(f1=f1, f2=f2, cat=cats)
	groups = groupby(d, :cat)

	# Jitter amount for group labels
	jt1 = abs(mean(f1) / 20)
	jt2 = abs(mean(f2) / 20)

	for (i, g) in enumerate(groups)

		if meansOnly
			@series begin
				seriestype := :scatter
				label := g.cat[1]
				markersize --> 3
				color := i
				[mean(g.f1)], [mean(g.f2)]
			end
		else
			@series begin
				seriestype := :scatter
				label := g.cat[1]
				markersize --> 3
				color := i
				g.f1, g.f2
			end
		end

		if ell
			e = ellipsePts(g.f1, g.f2, percent=ellPercent, nPoints=nEllPts)
			@series begin
				seriestype := :path
				label := ""
				color := i
				linewidth --> 3
				e[:,1], e[:,2]
			end
		end
	end
	
	# Add annotations in a new series where each point is the jittered
	# mean for a category
	if addLabels
		@series begin
			mns = combine(groups, [:f1, :f2] .=> mean)
			seriestype := :scatter
			markersize := 0
			label := ""
			series_annotations := [mns.cat[i] for i in 1:size(mns, 1)]
			mns.f1_mean .+ jt1, mns.f2_mean .+ jt2
		end
	end
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
function ellipsePts(f1, f2; percent=0.67, nPoints=500)
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

"""
    vowelhull(f1, f2; kw...)

Plot a convex hull around the F1-F2 space specified with `f1` and `f2`. Accepts standard keyword arguments for plots from `Plots.jl`.

Args
======

* `f1` The F1 values, or otherwise the values to plot on the x-axis
* `f2` The F2 values, or otherwise the values to plot on the y-axis
"""
vowelhull

@userplot VowelHull
@recipe function f(v::VowelHull)

	f1, f2 = v.args
	d = DataFrame(f1=f1, f2=f2)
	
	h = chull([d.f1 d.f2])
	
	idxs = [h.vertices; h.vertices[1]]
	d_sub = d[idxs, :]
	
	
	@series begin
		seriestype = :scatter
		[d_sub.f1], [d_sub.f2]
	end
end


"""
    hullarea(f1, f2)
	
Returns the area of the convex hull around the (by default) F1-F2 space specified by `f1` and `f2`. Areas/volumes of hulls in other spaces, such as speicfied by F1-F2-F3 or F1-F2-duration can also be calculated.

Args
======

* `f1` The F1 values, or otherwise the first variable/dimension for the hull
* `f2` The F2 values, or otherwise the second variable/dimension for the hull
* `x...` Additional variable to include in the hull, such as duration or F3
"""
hullarea(f1, f2, x...) = chull(hcat(f1, f2, x...)).area