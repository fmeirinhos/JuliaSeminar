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
alleviate this problem for _unary_ (single-argument) functions.
"""

# ╔═╡ c9862c2a-897e-11eb-3592-ada39cc0637b
md"""
#### Exercise: Becoming a pastry chef
(Re)create some syntatic sugar such as
- a function composition operator `∘` for _unary_ functions
- a reverse pipe `<|`

Note: infix operators such as `∘` need to be wrapped around `()` in method definitions for parsing reasons.
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
### map

`map(f, [a1,a2,...]) = [f(a1), f(a2), ...]`

Map a function over the elements of a container and collect the results


```julia
map(x -> x + 1, [1, 2, 3]) == [2, 3, 4]
map((x, y) -> x * y, [1,2,3], [1, 10, 100]) == [1, 20, 300]
```

### foreach
`foreach(f, [a1,a2,...]) = f(a1); f(a2); ...; nothing` 

Map a function over the elements of a container but without collecting the results

```julia
foreach(println, [1, 2, 3]) # prints
```

### foldl and foldr
`foldl(f, [a1, a2, a3, ...]) = f(f(f(a1, a2), a3), ...)`

`foldr(f, [a1, a2, a3, ...]) = f(a1, f(a2, f(a3, f(...))))`

Basically a left- and right- associative reduce.

```julia
foldl(=>, 1:4) == ((1 => 2) => 3) => 4
foldl(=>, 1:4; init=0) == (((0 => 1) => 2) => 3) => 4

foldr(=>, 1:4) == 1 => (2 => (3 => 4))
```

It doesn't end here: check also `filter`, `reduce`, `mapreduce` and possible multiple chains with `Transducers.jl`.
"""

# ╔═╡ aeed2776-8981-11eb-0546-f74714090a43
md"""
#### Exercise: Folding left and right

- Use a folding operator to find the `min`imum element in a container
  - Define your own `min(a,b)` function or use Julia's


- Consider a finite ``1``D spin-chain Hamiltonian with ``N`` sites `` H_N = -\sum^N_i T^{(N)}_i = -\sum^N_i \sigma^z_i \otimes \sigma^z_{i+1}`` with ``\sigma^z_i \otimes \sigma^z_{i+1} := ... \otimes \mathbb{1}_{i-1} \otimes \sigma^z_i \otimes \sigma^z_{i+1} \otimes \mathbb{1}_{i+1}  \otimes ...``

  - Define the identity ``\mathbb{1}_2`` and Pauli matrices.
  - Define `T(i,N)`. Suggestion:
    - Create a generator `T(i,N)` which returns the to-be-kronecked matrices. This is simple because you definitely didn't forget about `if` (or ternary) clauses in generator / list comprehensions.
    - Redefine `T(i,N)` `kron`ecking away the generator using a `fold`
  - Define the Hamiltonian `H(N)` using `T(i,N)`
"""

# ╔═╡ 0b0781fa-8996-11eb-1808-25a3d8fa7497
#= md"""
```julia
min_fold(c) = foldl((x,y) -> x <= y ? x : y, c)
min_fold(c) = foldl(min, c)
```
""" =#

# ╔═╡ 45c45594-8ca4-11eb-1db9-6187459bf306
#= md"""
```julia
id = [1 0; 0 1]
σᶻ = [1 0; 0 -1]

T(i,N) = ((j == i || j == i + 1) ? σᶻ : id for j in 1:N)
T(i,N) = foldl(kron, ((j == i || j == i + 1) ? σᶻ : id for j in 1:N))
```

```julia
function H(N)
	id = [1 0; 0 1]
	σᶻ = [1 0; 0 -1]

	T(i) = foldl(kron, ((j == i || j == i + 1) ? σᶻ : id for j in 1:N))

	return mapreduce(i -> -T(i), +, 1:(N-1)) #sum(map(T, 1:(N-1)))
end
```
""" =#

# ╔═╡ e5c840d8-8978-11eb-37fa-77fb05a3d821
md"""
# Multi-dimensional `Array`s
([read more](https://docs.julialang.org/en/v1/manual/arrays/))

There are a bunch of basic functions one has to know to effectively work with arrays.

##### Constructing arrays

```julia
A = zeros(T, sizes...)
B = ones(T, sizes...)
C = rand(T, sizes...)
D = copy(A)
E = reshape(A, new_sizes...)
```

##### Working with arrays
```julia
eltype(A)
length(A)
size(A)
eachindex(A) # iterator for visiting each position in A
```

##### Concatenating arrays
Arrays can be concatenated with the `;` syntax
```julia
A = rand(3)
B = zeros(3)
C = [A; B]
```

or with the `cat` functions
```julia
C = cat(A,B,dims=1) # What would happens if `dims=2`
```

### Linear indexing
When exactly one index `i` is provided, that index no longer represents a location in a particular dimension of the array but the `i`th element using the column-major order
```julia
A = [2 6; 4 7; 3 1]

A[5] == vec(A)[5] == 7
```

- Question: How to understand the matrix-creation notation `A` from the concatenation operator `;`?

### Array `@views`

**Slicing operations like x[1:2] create a copy by default in Julia**

A “view” is a data structure that acts like an array, but the underlying data is actually part of another array (reference!).

```julia
A = [1 2; 3 4]

b = view(A, :, 1)
b = @views A[:,1]

b[2] = 99
A
```

Note: Sometimes it's not faster to use `view`s!
"""

# ╔═╡ 8636e926-8b38-11eb-3f98-f58135f3d02e
md"""
### Broadcasting and loop fusions
It is common to have "vectorized" versions of functions, which simply `map` a function `f(x)` to each element of an array `a`. Unlike some languages, in `Julia` this is **not required** for performance: it's just a convenient for-loop.

This is achieved through the `dot` syntax
```julia
a = [0 π/2; -π/2 π/6]
sin.(a)
```

Due to historical (and parsing) reasons, the `dot` syntax for infix operators in on the left
```julia
a = [1.0, 2.0, 3.0]
a .^ 3 # NOT the power of a vector
```

On complicated expression with several `dot` calls, the operation is fused together (there will be a single loop)
```julia
b = 2 .* a.^2 .+ sin.(a)
```

The `@.` macro can be used to convert all function / operator calls in an expression to a `dot`-call
```julia
b = @. 2 * a^2 + sin(a)
```

and a `$` inserted to bypass the dot
```julia
@. sqrt(abs($sort(x))) # equivalent to sqrt.(abs.(sort(x)))
```

Naturally calls like
```julia
sin.(sort(cos.(X)))
```
can't be completely fused together.

**Singleton (size=1) and missing dimensions are expanded to match the extents of the other arguments by virtually repeating the value.**
```julia
a = rand(2,2)
b = zeros(2,2,3)
a .+ b
```

Dot calls are just syntatic sugar for `broadcast(f, As...)` so you can extend _broadcasting_ for custom types.

#### Map vs Broadcasting
No winner, each has things they can do that the other cannot
  - Broadcast only handles containers with th "shapes" M×N×⋯ (i.e., a size and dimensionality) while map is more general (unknown length iterator)
  - Map requires all arguments to have the same length (and hence cannot combine arrays and scalars)
"""

# ╔═╡ 540516aa-8b38-11eb-26f8-d31b72022689
md"""
#### Exercise: 
  - Convince yourself that the loop is indeed fused by `@time`ing a complex `dot`ed expression vs the expression terms seperately computed. Run the code once beforehand to avoid timing the compilation time!
  - Compute the spin-chain Hamiltonian for `N = [2, 4, 6, 7, 8]`
"""

# ╔═╡ 53f03512-8b38-11eb-031b-55d81ef5aeac
#= md"""
```julia
using BenchmarkTools
```

```julia
a = rand(100_000)

f(a) = @. a ^ 2 + sin(2a) / (a ^ 3)

function g(a)
	b = a .^ 2
	c = sin.(2a)
	d = a .^ 3
	e = c ./ d
	f = b + e
	return f
end

@assert f(a) == g(a)

# Interpolate global variables with `$`
# A global variable might have its value, and therefore its type, change at any point. # This makes it difficult for the compiler to optimize code using global variables
@btime f($a);
@btime g($a);
```

```julia
[1,2,3,4] .|> (x -> x^2, x -> 1/x, x -> 2x, x -> -x)
```
""" =#

# ╔═╡ 533f5a58-8b38-11eb-1c75-61000cf8394f
md"""

# `using LinearAlgebra`

"High-level" mathematical functions to operate on (multi-)dimensional `Array`s.

Assume that when you call methods from [`LinearAlgebra`](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/) that libraries like OpenBLAS (default) will be called for standard types such as `Float64`.

If your life depends on OpenBLAS-like operations its worth to check other implementations such as Intel's MKL or even pure Julia's like `Octavian.jl` (especially if your matrices are more interesting than dense ones).

### `LinearAlgebra` vs `GenericLinearAlgebra`

Generic programming allied with multiple dispatch allows one to share types with generic algorithms. An example of this is `GenericLinearAlgebra`, which implements some of `LinearAlgebra` functions in pure Julia.
"""

# ╔═╡ 59e7aaf0-8cac-11eb-0ea8-3fb87d36ad90
md"""
#### Exercise: Ising & Wilson chains 
- (Re) Consider a finite ``1``D spin-chain Hamiltonian with ``N`` sites coupled to a magnetic field `` H_N = -\sum^N_i \sigma^z_i \otimes \sigma^z_{i+1} + h \sum^N_i \sigma^x_i``
  - Construct this Hamiltonian
  - Diagonalise the Hamiltonian `using LinearAlgebra`'s `eigen` function
    - Which states (columns of the eigenvectors matrix) have the lowest energy for ``h=0`` and ``h \gg 1``?


- Consider a finite ``1``D spin-chain Hamiltonian with ``N`` sites `` H_N = -\sum^N_i \alpha^{-i} \sigma^z_i \otimes \sigma^z_{i+1}`` for ``\alpha \ge 1``
  - Diagonalise ``H_N =: U_N D_N U^\dagger_N`` `using LinearAlgebra`'s `eigen` function
  - Consider the ``\frac{2^N}{2}`` lowest-energy eigenvalue matrix ``D_N \rightarrow \tilde{D}_N`` and couple it to a next chain site ``H_{N+1} = \tilde{D}_N \otimes \mathbb{1}_2 - \alpha^{-(N+1)} \tilde{\sigma}_N \otimes \sigma^z_{N+1}`` where ``\tilde{\sigma}_N = \tilde{U} \sigma_N \tilde{U}^†``
  - Iterate the last step
"""

# ╔═╡ b0924ab0-8cac-11eb-17de-af8c6dddeab2
#= md"""
```julia
function H(N; h=0.0)
	id = [1 0; 0 1]
	σˣ = [0 1; 1 0]
	σᶻ = [1 0; 0 -1]

	T(i) = foldl(kron, ((j == i || j == i + 1) ? σᶻ : id for j in 1:N))
	M(i) = foldl(kron, j == i ? σˣ : id for j in 1:N)

	return mapreduce(M, +, 1:N) - mapreduce(T, +, 1:(N-1))
end
```

```julia
vs, ws = eigen(H(8; h=0.0))
```
""" =#

# ╔═╡ 971f2eec-8cbe-11eb-1030-ebcc770a64f8
#= md"""
```julia
id = [1 0; 0 1]
σᶻ = [1 0; 0 -1]

# Kinetic term T^N_i
T(i, N) = foldl(kron, ((j == i || j == i + 1) ? σᶻ : id for j in 1:N))

# (Base) Hamiltonian
H(;N, α=1.0) = mapreduce(i -> -α^(-i) * T(i, N), +, 1:(N-1))

# RG
function rg_step(Hₙ, n, α)
	# Diagonalize
	λs, U = eigen(Hₙ)

	# Truncation
	M = size(Hₙ, 1) ÷ 2
	H̃ = diagm(λs[1:M])
	Ũ = U[1:M, 1:M]
	
	# Project σ̃ᶻₙ
	idₘ = foldl(kron, (id for _ in 1:ceil(Int, log2(M))-1))
	σ̃ᶻₙ = Ũ * kron(idₘ, σᶻ) * Ũ'

	# Build H_{n+1}
	Hₙ₊₁ = kron(H̃, id) - α^(-(n+1)) * kron(σ̃ᶻₙ, σᶻ)
end

rg(;N,α,steps=0) = foldl((h, i) -> rg_step(h, N+i, α), 1:steps; init=H(N; α=α))
```
""" =#

# ╔═╡ 8ac22e72-8978-11eb-1674-e1b95403e215
md"""
# Performance

## Profiling

## Hardware

## Threading
"""

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
# ╟─45c45594-8ca4-11eb-1db9-6187459bf306
# ╟─e5c840d8-8978-11eb-37fa-77fb05a3d821
# ╟─8636e926-8b38-11eb-3f98-f58135f3d02e
# ╟─540516aa-8b38-11eb-26f8-d31b72022689
# ╟─53f03512-8b38-11eb-031b-55d81ef5aeac
# ╟─533f5a58-8b38-11eb-1c75-61000cf8394f
# ╟─59e7aaf0-8cac-11eb-0ea8-3fb87d36ad90
# ╟─b0924ab0-8cac-11eb-17de-af8c6dddeab2
# ╟─971f2eec-8cbe-11eb-1030-ebcc770a64f8
# ╟─8ac22e72-8978-11eb-1674-e1b95403e215
# ╟─4eb2573e-8998-11eb-2274-379a03bed49c
# ╟─b58a861c-7b50-11eb-286d-c5a5dd03429f
