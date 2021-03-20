### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ 9ba8170a-7b50-11eb-0aac-adc493e1f386
md"""
# Higher order functions
_A first taste of functional programming_

A higher-order function is a function that
- takes other functions as arguments
and/or
- returns a function as result


## Function composition and piping
Many times in scientific code it's required that functions are chained together.

This can be quite of eye sore
```julia
sqrt(abs(sum([1,2,3])))
```

Function composition `\circ`
```julia
(sqrt ∘ abs ∘ sum)([1,2,3])
```

and piping
```julia
sum([1,2,3]) |> abs |> sqrt
```
alleviate this problem for _unary_ (single-arugment) functions.
"""

# ╔═╡ c9862c2a-897e-11eb-3592-ada39cc0637b
md"""
#### Exercise: Becoming a pastry chef
(Re)create some syntatic sugar such as
- a function composition operator `∘` for _unary_ functions
- a reverse pipe `<|`

Note: infix operators such as `∘` need to be wrapped around `()` in function definitions for parsing reasons
"""

# ╔═╡ 44b9eb9c-8980-11eb-17b8-1937532d3a28
#= md"""
```julia
(∘)(f::Function, g::Function) = (x...)->f(g(x...))

(<|)(f::Function, args...) = f(args...)
```
""" =#

# ╔═╡ af38a46c-8981-11eb-26de-35f9e487423c
md"""
To better understand these functions, it's better to look at their function signature

### map
`map: (a -> b) × [a] -> [b]` 

`map: ((a × b × ...) -> c) × [a] × [b] × ... -> [c]`

Map a function over the elements of a container and collect the results

```julia
map(x -> x + 1, [1, 2, 3]) == [2, 3, 4]
map((x, y) -> x * y, [1,2,3], [1, 10, 100]) == [1, 20, 300]
```

### foreach
`foreach: (a -> b) × [a] -> nothing` 

Map a function over the elements of a container

```julia
foreach(println, [1, 2, 3]) # prints
```

### reduce
`reduce: ((a × a) -> a) × [a] -> a`

Can only use non-associative operations since you can't guarantee what
`reduce(-,[1,2,3])` will get reduced to `(1-2)-3` or `1-(2-3)`

```julia
reduce(+, [1, 2, 3, 4]) == 10 # `sum`
reduce(*, [1, 2, 3, 4]) == 24 # `factorial`
reduce(*, [1, 2, 3, 4]; init=-1) == -24
```

### foldl and foldr
`foldl: ((b × a) -> b) × [a] -> b`

`foldr: ((a × b) -> b) × [a] -> b`

Basically a left- and right- associative reduce.

```julia
foldl(=>, 1:4) == ((1 => 2) => 3) => 4
foldr(=>, 1:4) == 1 => (2 => (3 => 4))
```

It doesn't end here: check also `filter`, `mapreduce` and possible multiple chains with `Transducers.jl`.
"""

# ╔═╡ aeed2776-8981-11eb-0546-f74714090a43
md"""
#### Exercise: Folding left and right

- Define a function `sum²(n)` that takes an integer and performs the sum $ 1^2 + 2^2 + 3^2 + ... + n^2 $

- Use a folding operator to find the minimum element in a container
"""

# ╔═╡ 0b0781fa-8996-11eb-1808-25a3d8fa7497
#= md"""
```julia
sum²(n) = foldl((x,y) -> x + y^2, 1:n; init=0)

min_fold(c) = foldl((x,y) -> x <= y ? x : y, c)
```
""" =#

# ╔═╡ 4eb2573e-8998-11eb-2274-379a03bed49c
md"""
# Iteration Utilities
For more examples see [here](https://docs.julialang.org/en/v1/base/iterators/)

### zip
Run multiple iterators at the same time, until any of them is exhausted
```julia
a = [1,2,3]
b = (10,20,30)

for z in zip(a,b)
	println(z) # (1,10) ... (2, 20) ... (3, 30)
end
```

Question: What is the mathematical operation equivalent of zipping?

### enumerate
An iterator that yields `(i, x)` where `i` is a counter starting at `1`, and `x` is the `i`-th value from the given iterator
```julia
a = [10, 20, 30]

for (i, aᵢ) in enumerate(a)
	println("The $i-th entry of a is $aᵢ)
end
```
"""

# ╔═╡ e5c840d8-8978-11eb-37fa-77fb05a3d821
md"""
# `using LinearAlgebra`
"""

# ╔═╡ 8ac22e72-8978-11eb-1674-e1b95403e215
md"""
# Performance

## Profiling

## Hardware

## Threading
"""

# ╔═╡ b58a861c-7b50-11eb-286d-c5a5dd03429f
md"""
# Fixed points

A fixed point of a function is an element of the function's domain that is mapped to itself by the function.

$ x,\;f(x),\;f \circ f(x),\;f \circ f \circ f(x),\;... \rightarrow x^*$

Let's write a `Julia` function that finds the fixed point of some function `f`

```julia

# Identity operator
const id = x -> x

# Ideally... Why will it fail?
function ideal_fixed_point(f::Function)
    fix(x) = f ∘ fix(x)
    return fix
end

bad_g = fixed_point(id)
# @show bad_g(3) why will it fail??
```

```julia
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
```

```julia
# The equality condition is too strict for computations! Change it for an approximation (\approx)
approx_fixed_point(f::Function) = fix(xᵢ) = (xᵢ₊₁ = f(xᵢ)) ≈ xᵢ ? xᵢ : fix(xᵢ₊₁)

g = approx_fixed_point(id)
@show g(3);
```

```julia
# Add another stopping criteria to avoid getting stuck
approx_stop_fixed_point(f::Function; maxᵢ=10^4) = fix(xᵢ, i=1) = (xᵢ₊₁ = f(xᵢ)) ≈ xᵢ || i == maxᵢ ? xᵢ : fix(xᵢ₊₁, i+1)

# Kondo poor-man's scaling equations
kondo_rg_eqs(x; dk=-10^-3) = x .+ dk * [-2 * x[2]^2, -2 * x[1] * x[2]]
kondo_rg = approx_stop_fixed_point(kondo_rg_eqs)
```

```julia
using Plots

dj = 0.06

# ps = hcat([[[jz, j₊] ; kondo_rg([jz, j₊])] for j₊ in 0.0:dj:1.0 for jz in -dj-j₊:-dj:-1.0]...)

plot(ps[[1,3],:], ps[[2,4],:];
	xlims = (-1,dj),
	ylims=(-dj,1),
	framestyle = :origin,
	legend=false)
```

```julia
# Another example
logistic_map(r) = approx_stop_fixed_point(x -> r * x * (1-x))
```
"""

# ╔═╡ Cell order:
# ╟─9ba8170a-7b50-11eb-0aac-adc493e1f386
# ╟─c9862c2a-897e-11eb-3592-ada39cc0637b
# ╟─44b9eb9c-8980-11eb-17b8-1937532d3a28
# ╟─af38a46c-8981-11eb-26de-35f9e487423c
# ╟─aeed2776-8981-11eb-0546-f74714090a43
# ╟─0b0781fa-8996-11eb-1808-25a3d8fa7497
# ╟─4eb2573e-8998-11eb-2274-379a03bed49c
# ╟─e5c840d8-8978-11eb-37fa-77fb05a3d821
# ╟─8ac22e72-8978-11eb-1674-e1b95403e215
# ╟─b58a861c-7b50-11eb-286d-c5a5dd03429f
