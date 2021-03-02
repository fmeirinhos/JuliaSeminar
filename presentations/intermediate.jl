### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ 9f0c419c-7b51-11eb-1313-1f0e4af52ff5
begin
	using Plots
	
	dj = 0.06
	
	# ps = hcat([[[jz, j₊] ; kondo_rg([jz, j₊])] for j₊ in 0.0:dj:1.0 for jz in -dj-j₊:-dj:-1.0]...)
	
	plot(ps[[1,3],:], ps[[2,4],:];
		xlims = (-1,dj),
		ylims=(-dj,1),
		framestyle = :origin,
		legend=false)
end

# ╔═╡ 9ba8170a-7b50-11eb-0aac-adc493e1f386
md"""
# Higher order functions

A higher-order function is a function that takes other functions as arguments or returns a function as result.
"""

# ╔═╡ b58a861c-7b50-11eb-286d-c5a5dd03429f
md"""
### Fixed points

A fixed point of a function is an element of the function's domain that is mapped to itself by the function.

$ x,\;f(x),\;f \circ f(x),\;f \circ f \circ f(x),\;... \rightarrow x^*$

Let's write a `Julia` function that finds the fixed point of some function `f`
"""

# ╔═╡ cb3f9392-7b50-11eb-04d4-2bbee8e0438d
# Identity operator
const id = x -> x

# ╔═╡ dbdd21a8-7b50-11eb-3b79-0ba82fecd7c1
# Ideally... Why will it fail?
function ideal_fixed_point(f::Function)
    fix(x) = f ∘ fix(x)
    return fix
end

# ╔═╡ e9028cc4-7b50-11eb-1212-632d91f3f917
begin
	# Need a stopping criterion
	function fixed_point(f::Function)
		function fix(xᵢ)
			xᵢ₊₁ = f(xᵢ)
			if xᵢ₊₁ == xᵢ
				return xᵢ
			else
				return fix(xᵢ₊₁)
			end
		end
		return fix
	end

	good_g = fixed_point(id)
	@show good_g(3);
	
	# TODO: Write this function as a 1-liner!
	fixed_point(f::Function) = nothing
end

# ╔═╡ e0037c1e-7b50-11eb-32f4-593f6dbe6322
bad_g = fixed_point(id)
# @show bad_g(3) why will it fail??

# ╔═╡ 436ced30-7b51-11eb-0443-ff78d6611555
begin
	# The equality condition is too strict for computations! Change it for an approximation (\approx)
	approx_fixed_point(f::Function) = fix(xᵢ) = (xᵢ₊₁ = f(xᵢ)) ≈ xᵢ ? xᵢ : fix(xᵢ₊₁)

	g = approx_fixed_point(id)
	@show g(3);
end

# ╔═╡ 758c920c-7b51-11eb-2e87-e39f2eca37f9
begin
	# Add another stopping criteria to avoid getting stuck
	approx_stop_fixed_point(f::Function; maxᵢ=10^4) = fix(xᵢ, i=1) = (xᵢ₊₁ = f(xᵢ)) ≈ xᵢ || i == maxᵢ ? xᵢ : fix(xᵢ₊₁, i+1)
end

# ╔═╡ 9704a6d6-7b51-11eb-1d4e-57d678e451b8
begin
	# Kondo poor-man's scaling equations
	kondo_rg_eqs(x; dk=-10^-3) = x .+ dk * [-2 * x[2]^2, -2 * x[1] * x[2]]
	kondo_rg = approx_stop_fixed_point(kondo_rg_eqs)
end

# ╔═╡ b693098e-7b51-11eb-0ab9-399ac06a39d7
# Another example
logistic_map(r) = approx_stop_fixed_point(x -> r * x * (1-x))

# ╔═╡ d6cc24f6-7b51-11eb-128e-b395e6fb6b6e
md"""
### [Folding](https://en.wikipedia.org/wiki/Fold_(higher-order_function))

Analyze a recursive data structure and through use of a given combining operation, recombine the results of recursively processing its constituent parts, building up a return value.
"""

# ╔═╡ d6cbb6c4-7b51-11eb-0beb-f90fa8e3f94b
md"""
### Reducing
"""

# ╔═╡ Cell order:
# ╠═9ba8170a-7b50-11eb-0aac-adc493e1f386
# ╠═b58a861c-7b50-11eb-286d-c5a5dd03429f
# ╠═cb3f9392-7b50-11eb-04d4-2bbee8e0438d
# ╠═dbdd21a8-7b50-11eb-3b79-0ba82fecd7c1
# ╠═e0037c1e-7b50-11eb-32f4-593f6dbe6322
# ╠═e9028cc4-7b50-11eb-1212-632d91f3f917
# ╠═436ced30-7b51-11eb-0443-ff78d6611555
# ╠═758c920c-7b51-11eb-2e87-e39f2eca37f9
# ╠═9704a6d6-7b51-11eb-1d4e-57d678e451b8
# ╠═9f0c419c-7b51-11eb-1313-1f0e4af52ff5
# ╠═b693098e-7b51-11eb-0ab9-399ac06a39d7
# ╠═d6cc24f6-7b51-11eb-128e-b395e6fb6b6e
# ╠═d6cbb6c4-7b51-11eb-0beb-f90fa8e3f94b
