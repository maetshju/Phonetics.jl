using LexicalCharacteristics
using Distances
using Statistics
using DelimitedFiles
using LinearAlgebra
using QHull
using GeometricalPredicates
using Plots
using Measures
using ProgressBars
using Base

mutable struct Formants
  formants
  medians
  Formants(f, m) = new(f, m)
end

function Base.getindex(f::Formants, inds...)
  return f.formants[inds...]
end

mutable struct VowelSpace
  formants
  f1
  f2
  hull
  hullpts
  density
  ∂z∂f1
  ∂z∂f2
end

function densityPlot(v::VowelSpace; standardize_axes=true, scale_densities=false)

  f1vals = v.f1
  f2vals = v.f2

  if standardize_axes
    f1vals = f1vals .* v.formants.medians[1] .+ v.formants.medians[1]
    f2vals = f2vals .* v.formants.medians[2] .+ v.formants.medians[2]
  end

  vd = round(vdi(v, unstandardize=standardize_axes), digits=2)
  a = round(area(v, unstandardize=standardize_axes), digits=2)

  density = v.density
  if scale_densities
    density /= maximum(density)
  end

  # density is currently stored with f1 measured as changes in rows
  # while f2 is measured as changes in columns
  # need to transpose the matrix for f1 to be indexed with columns
  # and f2 to be indexed with rows
  heatmap(f1vals, f2vals, density', title="A=$a Hz², VDI=$vd", xlab="F1", ylab="F2")

  hullpts = Vector()
  for vtx in v.hull.vertices
    push!(hullpts, v.hull.points[vtx, :]')
  end

  push!(hullpts, hullpts[1])

  hullpts = reduce(vcat, hullpts)

  if standardize_axes
    hullpts[:,1] = hullpts[:,1] .* v.formants.medians[1] .+ v.formants.medians[1]
    hullpts[:,2] = hullpts[:,2] .* v.formants.medians[2] .+ v.formants.medians[2]
  end

  plot!(hullpts[:,1], hullpts[:,2], line=(3, :path), label="Threshold")
end

function vdi(v::VowelSpace; unstandardize=true)
  if unstandardize
    f1vals = v.f1[1:2] .* v.formants.medians[1] .+ v.formants.medians[1]
    Δf1 = diff(f1vals)
    f2vals = v.f2[1:2] .* v.formants.medians[2] .+ v.formants.medians[2]
    Δf2 = diff(f2vals)
  else
    Δf1 = diff(v.f1[1:2])
    Δf2 = diff(v.f2[1:2])
  end
  scaled_∂z∂f1 = v.∂z∂f1 ./ Δf1
  scaled_∂z∂f2 = v.∂z∂f2 ./ Δf2

  m = maximum(v.density)
  for (i, d) in enumerate(v.density)
    if d / m < 0.25
      scaled_∂z∂f1[i] = 0
      scaled_∂z∂f2[i] = 0
    end
  end

  return sqrt(sum(scaled_∂z∂f1.^2  .+ scaled_∂z∂f2.^2))
end

function area(v::VowelSpace; unstandardize=true)
  if unstandardize
    hullpts = Vector()
    for vtx in v.hull.vertices
      push!(hullpts, v.hull.points[vtx, :]')
    end

    push!(hullpts, hullpts[1])

    hullpts = reduce(vcat, hullpts)
    hullpts[:,1] = hullpts[:,1] .* v.formants.medians[1] .+ v.formants.medians[1]
    hullpts[:,2] = hullpts[:,2] .* v.formants.medians[2] .+ v.formants.medians[2]
    return(chull(hullpts).area)
  else
    return v.hull.area
  end
end

function VowelSpace(formants; temporalNorm=true)
  
  minF1 = minimum(formants[:,1])
  maxF1 = maximum(formants[:,1])

  minF2 = minimum(formants[:,2])
  maxF2 = maximum(formants[:,2])

  dur = size(formants.formants, 1)

  densityGrid = createDensityGrid(formants.formants)

  # what do we do with formantNorm here?

  local hullGrid

  if temporalNorm
    normGrid = densityGrid / size(formants.formants, 1)
    hullGrid = map(x -> x < 0.25 ? zero(x) : x, normGrid ./ maximum(normGrid))
  else
    
    normGrid = densityGrid ./ maximum(densityGrid)
    hullGrid = map(x -> x < 0.25 ? zero(x) : x, densityGrid)
  end

  f1vals = collect(range(minF1, maxF1, length=size(densityGrid, 1)))
  f2vals = collect(range(minF2, maxF2, length=size(densityGrid, 2)))

  densityPoints = Vector()
  for i in CartesianIndices(hullGrid)
    if hullGrid[i] > 0
      f1 = f1vals[i[1]]
      f2 = f2vals[i[2]]
      push!(densityPoints, [f1 f2])
    end
  end
  
  densityPoints = reduce(vcat, densityPoints)
  hull = chull(densityPoints)
  h1pts = Array{CartesianIndex{2},1}()

  h1poly = Polygon2D([Point(Float64.(hull.points[i,:])...) for i in hull.vertices]...)

  for i in CartesianIndices(densityGrid)
    densityGrid[i] / maximum(densityGrid) < 0.25 && continue
    currX = f1vals[i[1]]
    currY = f2vals[i[2]]
    currPt = Point2D(currX, currY)
    if inpolygon(h1poly, currPt)
      push!(h1pts, i)
    end
  end

  # moving from row 1 to row 2, etc., changes f1
  # so, diff over dim1
  ∂z∂f1 = diff(densityGrid, dims=1)
  ∂z∂f1 = vcat(∂z∂f1, zeros(typeof(densityGrid[1]), size(densityGrid, 2))')

  # moving from column 1 to column 2, etc., changes f2
  # so, diff over dim2
  ∂z∂f2 = diff(densityGrid, dims=2)
  ∂z∂f2 = hcat(∂z∂f2, zeros(typeof(densityGrid[2]), size(densityGrid, 1)))

  return VowelSpace(formants, f1vals, f2vals, hull, h1pts, densityGrid, ∂z∂f1, ∂z∂f2)
end

function threeMdnNorm(x)
  filtered = [median([x[1], x[1], x[2]])]
  for i=1:(length(x)-2)
    push!(filtered, median(x[i:i+2]))
  end
  push!(filtered, median([x[end-1], x[end], x[end]]))
  return filtered
end

function fiveSpanMovingAvg(x)
  filtered = [x[1]]
  push!(filtered, mean(x[1:3]))
  for i=3:length(x)-2
    push!(filtered, mean(x[i-2:i+2]))
  end
  push!(filtered, mean(x[end-2:end]))
  push!(filtered, x[end])
end

function createDensityGrid(formants, gridInterval=0.01, densityRadius=0.05)

  pointsTree = TextVPTree([formants[i,:] for i=1:size(formants, 1)], euclidean)

  minF1 = minimum(formants[:,1])
  maxF1 = maximum(formants[:,1])

  minF2 = minimum(formants[:,2])
  maxF2 = maximum(formants[:,2])

  nXvals = round(Int64, (maxF1 - minF1) / gridInterval)
  nYvals = round(Int64, (maxF2 - minF2) / gridInterval)

  densityGrid = zeros(nXvals, nYvals)

  for i=1:size(densityGrid, 1)
    xVal = minF1 + (i-1)*gridInterval
    for j=1:size(densityGrid, 2)
      yVal = minF2 + (j-1)*gridInterval
      densityGrid[i,j] = length(radiusSearch(pointsTree, [xVal, yVal], densityRadius))
    end
  end
  return densityGrid
end

function Formants(fname; mdnFilt=true, avgFilt=true, outlierFilt=false)
  open(fname, "r") do f
    formants = DelimitedFiles.readdlm(f, '\t')
  end

  if mdnFilt
    formants = mapslices(threeMdnNorm, formants, dims=1)
  end

  if avgFilt
    formants = mapslices(fiveSpanMovingAvg, formants, dims=1)
  end

  if outlierFilt
    formants = formants[findall(x -> x < 800, formants[:,1]),:]
    formants = formants[findall(x -> x < 2300, formants[:,2]),:]
  end

  md1 = median(formants[:,1])
  md2 = median(formants[:,2])
  formants = mapslices(x -> (x .- median(x)) ./ median(x), formants, dims=1)
  return Formants(formants, [md1, md2])
end
