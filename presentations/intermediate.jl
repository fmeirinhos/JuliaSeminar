### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# ╔═╡ 59afc220-9195-11eb-2384-29ae6f4aa263
md"""
### REPL 101

- `]` enters the package manager
- `;` enters the terminal
- `?` gives you the documentation of a function
"""

# ╔═╡ e5c840d8-8978-11eb-37fa-77fb05a3d821
md"""
# Multi-dimensional `Array`s
_continuation_ ([read more](https://docs.julialang.org/en/v1/manual/arrays/))

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
When exactly one index `i` is provided, that index no longer represents a location in a particular dimension of the array but the `i`th element using the **column-major order**
```julia
A = [2 6; 4 7; 3 1]

A[5] == vec(A)[5] == 7
```

- Question: How to understand the matrix-creation notation (for example with `A`) from the concatenation operator `;`?

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
"""

# ╔═╡ 540516aa-8b38-11eb-26f8-d31b72022689
md"""
#### Exercise: 
  - Convince yourself that the loop is indeed fused by `@time`ing a complex `dot`ed expression vs the expression terms seperately computed. Run the code once beforehand to avoid timing the compilation time!
"""

# ╔═╡ 53f03512-8b38-11eb-031b-55d81ef5aeac
md"""
##### Solution:

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

# Make sure they are doing the same thing
@assert f(a) == g(a)

@time f(a);
@time g(a);
```
"""

# ╔═╡ 533f5a58-8b38-11eb-1c75-61000cf8394f
md"""

# `using LinearAlgebra`

"High-level" mathematical functions to operate on (multi-)dimensional `Array`s.

Assume that when you call methods from [`LinearAlgebra`](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/) that libraries like OpenBLAS (default) will be called for standard types such as `Float64`.

If your life depends on OpenBLAS-like operations its worth to check other implementations such as Intel's MKL or even pure Julia's like `Octavian.jl` (especially if your matrices are more interesting than dense ones).

### `LinearAlgebra` vs `GenericLinearAlgebra`

Generic programming allied with multiple dispatch allows one to share types with generic algorithms. An example of this is `GenericLinearAlgebra`, which implements some of `LinearAlgebra` functions in pure Julia.
"""

# ╔═╡ e6cc166a-8ed2-11eb-23be-2d657eb00795
md"""
#### Exercise: Quantum Ising

- Consider a finite ``1``D spin-chain Hamiltonian with ``N`` sites coupled to a magnetic field `` H_N = -\sum^N_i \sigma^z_i \otimes \sigma^z_{i+1} - h \sum^N_i \sigma^x_i`` with ``\sigma^z_i \otimes \sigma^z_{i+1} := ... \otimes \mathbb{1}_{i-1} \otimes \sigma^z_i \otimes \sigma^z_{i+1} \otimes \mathbb{1}_{i+1}  \otimes ...``

  - Define the identity ``\mathbb{1}_2`` and Pauli matrices.
  - Take the Kronecker products using the function `kron` at all sites `i` and sum them.
  - Diagonalise the Hamiltonian `using LinearAlgebra`'s `eigen` function
    - Which states (columns of the eigenvectors matrix) have the lowest energy for ``h=0`` and ``h \gg 1``?
"""

# ╔═╡ 247b2cf8-8ed3-11eb-19ee-fd0f17cec519
#= md"""
##### Solution:

```julia
function H(;N,h)
	id = [1 0; 0 1]
	σˣ = [0 1; 1 0]
    σᶻ = [1 0; 0 -1]
	
	# final Hamiltonian
	hamiltonian = zeros(Float64, 2^N, 2^N)
	
	# kinetic term: sum only until (N-1) because there's no site to the right of N
	for i in 1:(N-1)
		
		# For each site contribution, σᶻ will be at position k and k+1
		mat(k) = k == i || k == (i + 1) ? σᶻ : id
		
		# kronecker products
		out = mat(1)
		for j in 2:N
			out = kron(out, mat(j))
		end

		# Add contribution to the Hamiltonian
		hamiltonian -= out
	end
	
	# magnetic term: can take sum everywhere
	for i in 1:N
	
		# For each site contribution, σᶜ will be at position k
		mat(k) = k == i ? σˣ : id
		
		# kronecker products
		out = mat(1)
		for j in 2:N
			out = kron(out, mat(j))
		end
		
		# Add contribution to the Hamiltonian
		hamiltonian -= h .* out
	end
	return hamiltonian
end
```

With a function that can generate the Hamiltonian generally, it's easy to check for the eigenstates.

Since the eigenvalues are sorted by ascending value, we just need to look at the first terms

```julia
using LinearAlgebra

h1 = H(N=8, h=0.0);
h2 = H(N=8, h=100);

vals1, vecs1 = eigen(h1);
vals2, vecs2 = eigen(h2);

@show vecs1[:,1]; # Vectors all pointing in the same direction
@show vecs2[:,1]; # Vectors aligned with σˣ (equal super-position of eigenstates)
```
""" =#

# ╔═╡ 9ba8170a-7b50-11eb-0aac-adc493e1f386
md"""
# A first taste of functional programming

**Functional programming** a programming paradigm where programs are constructed by applying and composing functions.

Function definitions are trees of expressions that map values to other values.
Unlike imperative programming, in which a sequence of imperative statements which updates the running state of the program.

There are 2 main conceptes from FP which have clear benefits for scientific code
- Higher-order functions
- Pure functions

## Higher order functions

In Julia the functions are already first-class citizens (can pass them as arguments, return them and assign them to variable names).

A higher-order function is a function that
- takes other functions as arguments
and/or
- returns a function as result


### Function composition and piping
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
md"""
##### Solution:
```julia
(∘)(f::Function, g::Function) = (x...) -> f(g(x...))

(<|)(f::Function, args...) = f(args...)
```
"""

# ╔═╡ af38a46c-8981-11eb-26de-35f9e487423c
md"""
One of the most glaring differences between functional and imperative programming is that functional avoids _side effects_, which are needed in imperative style to control the state of the program.

Here are examples of higher-order functions that take us closer to the functional heaven.

### map

`map(f, [a1,a2,...]) = [f(a1), f(a2), ...]`

`map(g, [a1,a2,...], [b1,b2,...]) = [g(a1,b1), g(a2,b2), ...]`

Maps a function over the elements of a container and collect the results

```julia
# data
v1 = [1, 2, 3]
v2 = [10, 20, 30]

# imperative
out = zero(v1)
for i in eachindex(v1) # equivalent to 1:length(v1)
	out[i] = v1[i] + v2[i]
end

# functional
out = map(+, v1, v2)
```

##### `map` vs `broadcast`
  - Broadcast only handles containers with th "shapes" `M×N×...` (i.e., a size and dimensionality) while map is more general (unknown length iterator)
  - Map requires all arguments to have the same length (and hence cannot combine arrays and scalars)

### foreach
`foreach(f, [a1,a2,...]) = f(a1); f(a2); ...; nothing` 

Map a function over the elements of a container but without collecting the results

```julia
# data
v = [1, 2, 3]

# imperative
for i in eachindex(v)
	println(v[i])
end

# functional
foreach(println, v)
```

### foldl and foldr
`foldl(op, [a1, a2, a3, ...]) = op(op(op(a1, a2), a3), ...)`

`foldr(op, [a1, a2, a3, ...]) = op(a1, op(a2, op(a3, op(...))))`

Folds are ubiquitous in functional and scientific programming. They are a class of functions that process some data structure and return a value. Basically a left- and right- associative reduce.

```julia
# data
v = [1, 2, 3, 4]

# binary function
op = *

# imperative
out = v[1]
for i in 2:length(v)
	out = op(out, v[i])
end

# functional
out = foldl(op, v)
```

Question: why is there a distinction between left and right folds?

For most cases these binary functions are not associative!

We implicitely have left- and right- associativeness hard coded in our brain. What's `0 - 1 - 2 - 3 - 4` ?
- left-associative `((((0 - 1) - 2) - 3) - 4) == -10`
- right-associative `(0 - (1 - (2 - (3 - 4)))) == 2`

An initial value cal also be passed as a _keyword_
```julia
foldl(=>, 1:4) == ((1 => 2) => 3) => 4
foldl(=>, 1:4; init=0) == (((0 => 1) => 2) => 3) => 4
```
"""

# ╔═╡ afc5f13c-8ee2-11eb-2dfe-0dcbc74c120e
md"""
#### Exercise: folding left and right
- Use a folding operator to find the `min`imum element in a container
  - Define your own `min(a,b)` function or use Julia's
"""

# ╔═╡ bded83c2-8ee2-11eb-3b00-a7681ba476dc
md"""
##### Solution:

```julia
my_min(x,y) = x < y ? x : y
min_fold(c) = foldl(my_min, c)
```
"""

# ╔═╡ 0d6a34a4-8ee3-11eb-08ae-2763ca230fd5
md"""
### mapreduce
`mapreduce(f, op, [a1, a2, a3, ...]) = op(op(op(f(a1), f(a2)), f(a3)), ...)`

Applies a function `f` to each element of the container and `reduces` the result using a binary function `op`.

```julia
# data
v = [1, 2, 3, 4]

# operations
f = sin
op = *

# imperative
out = 1.0
for i in eachindex(v)
	out = op(out, f(v[i]))
end

# functional
out = mapreduce(f, op, v; init=1.0)
```

Unlike a `fold`, a `reduce` operation **assumes associativity** with the binary operations. If this cannot be guaranteed, a `mapfoldl` or `mapfoldr` can be used instead.

Question: Where could a `reduce` operation be preferred (computationally!) over a fold?


It doesn't end here: check also `filter`, `reduce` and possible multiple chains with `Transducers.jl`.
"""

# ╔═╡ 59e7aaf0-8cac-11eb-0ea8-3fb87d36ad90
md"""
#### Exercise: Wilson chains 
- Consider a finite ``1``D Wilson chain with ``N`` sites `` H_N = -\sum^N_i \alpha^{-i} \sigma^z_i \otimes \sigma^z_{i+1}`` for ``\alpha \ge 1``
  - Build the Hamiltonian in a functional way. Suggestion:
    - Use `mapfold` or `fold` to take the Kronecker products

- Numerically renormalize the problem by iterating
  - Diagonalise ``H_N =: U_N D_N U^\dagger_N`` `using LinearAlgebra`'s `eigen` function
  - Truncate ``H_N \rightarrow \tilde{H}_N`` by taking only the half lowest eigenvalues
  - Coupling ``\tilde{H}_N`` to a next site in the chain ``H_{N+1} = \tilde{D}_N \otimes \mathbb{1}_2 - \alpha^{-(N+1)} \tilde{\sigma}^z_N \otimes \sigma^z_{N+1}`` where ``\tilde{\sigma}^z_N = \tilde{U}_N \sigma^z_N \tilde{U}_N^†``

Tip: A diagonal matrix can be created out of the vector of eigenvalues with the `diagm` function and the adjoint of a matrix is achieved with the `adjoint` function or `'` operator after the matrix.
"""

# ╔═╡ 45c45594-8ca4-11eb-1db9-6187459bf306
#= md"""
##### Solution:

```julia
using LinearAlgebra

const id = [1 0; 0 1]
const σᶻ = [1 0; 0 -1]

# Wilson chain Hamiltonian
function H(N, α)
	T(i) = -α^(-i) * mapreduce(j -> j == i || j == i + 1 ? σᶻ : id, kron, 1:N)
	return mapreduce(T, +, 1:(N-1))
end

# Couple H to the chain site `n`
function add_chain(H, n, α)
	# truncates half of the highest eigenvalues
	λ̃, Ũ = let
		λ, U = eigen(H)
		N₂ = length(λ) ÷ 2
		λ[1:N₂], U[1:N₂, 1:N₂]
	end

	σᶻₙ = let
		n = ceil(Int, log2(length(λ̃))) # number of sites in H̃
		mapreduce(i -> i == n ? σᶻ : id, kron, 1:n)
	end
	
	# Rotate σᶻ → σ̃ᶻₙ and add chain
	return kron(diagm(λ̃), id) - α^(-(n+1)) * kron(Ũ * σᶻₙ * Ũ', σᶻ)
end

# Numerical renormalization group
rg(;N,α,steps=0) = foldl((h, i) -> add_chain(h, N+i, α), 1:steps; init=H(N, α))
```
""" =#

# ╔═╡ 4bee5324-8eeb-11eb-326b-efba53215f34
md"""
### Pure functions
_Pure thoughts_

Another great tool of functional programming we should steal for scientifc programming is the concept of pure functions. These functions are very close to mathematical functions.

- The function return values are identical for identical arguments
- The application of the function has no side effects
  - No mutation of non-local variables or mutable reference arguments

Examples of _indecent thoughts_:

Mutation of non local variables ⚰️⚰️⚰️
```julia
f() = x[1] += 1

x = [1]
@show x

f()
@show x
```

Different return values with identical arguments 🪦🪦🪦
```julia
f() = x

x = 1
@show f()

x = 2
@show f()
```

##### Why do I care?
- Becase you're not a sociopath
- If the result of a pure expression is not used, it can be removed without affecting other expressions.
- Pure functions have no side-effects and you can intelectually refeer to them as being _referentially transparent_, just like mathematical functions
- Since they only depend on their arguments, different function calls can't interfer with each other (great for parallel programming!)
- No side effects means your compiler can, theoretically, safely apply 
- Unit tests are valid and can be injected anywhere
"""

# ╔═╡ 28f63950-8eef-11eb-0481-55fad44619d5
md"""
### Meta-discussion: mutable vs immutable/pure algorithms

Immutability doesn't really exist: immutability implies time-independence... and there's nothing really stopping time (at least until the heat-death of the universe).

The very process of storing information (that is ordering bits) requires mutation.
But we can achieve immutability at least syntatically.


##### Tips to scientific code right, denying mutation and and promoting good hygiene

- Use `let` blocks to reduce global scope pollution
    - Global variables are **very** prone to be mutated since they don't have to be passed as an argument explicitely


- Pure thoughts: decompose programs into (pure) functions:
    - Break software into chunks to fit into the most limited memory: human memory.


- Give functions and variables meaningful names
    - Use `Pluto` notebooks to prototype


- Use tuples / structs to avoid repetition
    - `a1 = 1, a2 = 2` becomes `as = (1, 2)`


- Be defensive
    - Add `@assert`s to ensure validity of your inputs / results
    - Generate unit tests for your functions: these are as important as the problem you are ultimately solving


- Be smart by not oversmarting yourself:
    - avoid _premature optimisation_: write clear and concise code and only think about optimisations after unit testing
    - avoid _premature pessimisation_: take a chill pill and sketch on paper the data structures / algorithm design before writing any code
    - require of your code the same standards you require others' calculations / experiments / general care in life


Read more on good Scientific Practises
- [1](https://swcarpentry.github.io/good-enough-practices-in-scientific-computing/)
- [2](https://arxiv.org/pdf/1210.0530v3.pdf)
- [3](https://blog.higher-order.com/blog/2009/04/27/a-critique-of-impure-reason/)
"""

# ╔═╡ 8ac22e72-8978-11eb-1674-e1b95403e215
md"""
# Performance
We will step out of the beautiful pure world of functional programming and dive deep into the messy world of algorithm optimisation.

While some topics will be related to avoiding common pitfalls when writing in Julia, other universal topics on algorithm optimisation will also be covered.

## Profiling
In order to know where and what to optimise we need tools to diagnose time spent, memory allocations and possibly how machine code is being generated.

- For quick-and-dirty diagnostics (time and memory tracking) we can use the `@time` macro behind function calls
- For an accurate measure of the latter preferer `using BenchmarkTools` and the `@btime` macro (this will give you the lower bound of `@benchmark`, which is what you want to measure!)
- For more serious profiling tools, consider reading the [manual section](https://docs.julialang.org/en/v1/manual/profile/)


The code can be inspected at several stages with the macros
- The AST after parsing: `@macroexpand`
- The AST after type inference and some optimizations: `@code_typed` (prefer `@code_warntype`)
- The LLVM and assembly: `@code_llvm`, `@code_native`

Read more on [introspection](https://docs.julialang.org/en/v1/devdocs/reflection/)
"""

# ╔═╡ 8d9f2162-8f07-11eb-1c1d-b994b88811e1
md"""
#### Exercise: Not all "created" equal
Benchmark the different ways of mapping a function to a container and realise that computationally not all operations are equivalent
- `map`
- `broadcast`
- list comprehension
- explicit `for`-loop
"""

# ╔═╡ bff46124-8f08-11eb-1140-d78145e2fe05
#= md"""

```julia
using BenchmarkTools

fmap(x) = map(x -> 2x, x)

fdot(x) = 2 .* x

fcomprehension(x) = [2x for x in x]

function floop(x)
    y = similar(x) # prefer similar to zero as it only has to allocate (and not zero)
    for i in eachindex(x)
        y[i] = 2*x[i]
    end
    return y
end

x = rand(10_000)

# The $ interpolates values into the expression avoiding the global-variable problem

@btime fmap($x);
# > 7.977 μs (2 allocations: 78.20 KiB)
@btime fcomprehension($x);
# > 7.890 μs (2 allocations: 78.20 KiB)
@btime fdot($x);
# > 8.238 μs (2 allocations: 78.20 KiB)
@btime floop($x);
# > 9.495 μs (2 allocations: 78.20 KiB)
```
""" =#

# ╔═╡ fdfddce2-919d-11eb-1b48-5d31c8d4b250
md"""
### Global (`isa Any`) variables: Electric Boogaloo
_It's not over yet_

[1st performance tip](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-global-variables) on the Julia's official documentation: **Avoid global variables**

A global variable might have its value, and therefore its type, change at any point. This makes it difficult for the compiler to optimize code using global variables.
- Variables should be local
- Or passed as arguments to functions (this way the code will be specialized for the input types)

```julia
x = rand(100_000);

function sum_global()
	s = 0.0
	for i in x
	   s += i
	end
	return s
end

function sum_arg(x)
	s = 0.0
	for i in x
	   s += i
	end
	return s
end

@time sum_global()
# 0.016230 seconds (399.49 k allocations: 7.622 MiB)

@time sum_arg(x)
# 0.000123 seconds (1 allocation: 16 bytes)
```

This unfortunate dichotomy between the functions is due to one thing: Julia can't **specialize** the function `sum_global` since it cannot guarantee the type of `x`.
While for `sum_arg`, it will specialize it for the type of `x` that is encountered (a complex `x` would trigger compilation).

**Type inference did not require the type to be annotated!**

`@code_warntype` can detect these `isa Any` variables or the also related type instabilities!
"""

# ╔═╡ 8a97bcb8-91a3-11eb-37b4-4f9004e01e0b
md"""
#### Exercise: Purging type instabilities / "untyped" containers
- Remember that an array with abstract type (e.g. `Any` or `Real`) will end up being an array of pointers and can't be operated on efficiently. `abstract` types can also prevent Julia from triggering the appropriate function specialization. Compare the `@code_native` outputs from a simple function operating on the fields of
```julia
mutable struct MyAmbiguousType
   a::AbstractFloat # less ambiguous than `Any` but still ambiguous
end

mutable struct MyType{T<:AbstractFloat}
   a::T
end
```

- Can you spot the type instability? Fix it and consequently `@btime` and `@code_native` the new function vs the old one.
```julia
function f()
	x = 1
	for i = 1:10
		x = x/2
	end
	return x
end
```
"""

# ╔═╡ 0ae35bf0-91a6-11eb-1a75-235aaf78d346
#= md"""
##### Solution:

```julia
add1(m::MyType) = m.a + 1

@code_native add1(MyType{Float64}(0.3))
@code_native add1(MyType{AbstractFloat}(0.3))
```
""" =#

# ╔═╡ 700b1240-9197-11eb-0cfd-1bb3d7393084
md"""
## Understanding timecales
There's a rather famous table comparing computer with human timecales

| Action (3GHz) | Average latency | Human time |
|:---------- | ---------- |:------------:|
| 1 clock-cyle   | 0.3 ns | 1 s |
| L1 cache    | 0.9 ns  | 3 s |
| L2 cache    | 2.8 ns  | 9 s |
| L3 cache    | 12.9 ns  | 43 s |
| RAM    | 70-100 ns  | 3.5 to 5.5 min |
| SSD/IO | 7-150 μs | 2h to 2 days |
| Reboot | 30-60s | 1000-2000 years |

In a single cycle a photon can only travel <10 cms to the RAM better not be too far away (imagine an electron).

The slowness of RAM can be mitigated by transfering data into the caches. **BUT** when the CPU requests data from the RAM, it is checked if it's in the cache. If not, there will be a _cache miss_ and the program will stall until the data is fetched from the RAM.

Naturally, to reduce these cache misses, consider
- _Temporal locality_: If you need to access a piece of memory multiple times, do it close in time
- _Spatial locality_: Access memory which is close to each other (since the CPU fetches chunks of data at a time)

As a corollary
- Use little memory
- Access data sequentially (since the CPU can prefetch data that you may need)

It doesn't end here: read more on [alignment issues](https://biojulia.net/post/hardware/#alignment) [(show-in-class)](https://juliasimd.github.io/LoopVectorization.jl/stable/examples/matrix_multiplication/)

### Allocations
Memory allocation can be a significant bottleneck in critical operations.
Dynamic languages such as Julia usually employ a _garbage collector_ to allocate and deallocate objects in the RAM for us
```julia
a = [1,2,3] # allocation
a = nothing # the previous value of `a` is now garbage (since in this case no other variables are pointing at it) and shall be collected automatically
```
- Allocation and deallocation create _overhead_ which can be very costly
- More allocations results in more memory usage which results in more cache misses

The 3 most encountered problems where this can be fixed are

- When updating some value _inplace_
```julia
N = 1000
a = rand(10,10);

function f1(a, N)
	x = zero(a)
	for i in 1:N
		x += i * a # remember that updating operators such as `+=` reassign `x`
	end
	x
end

@btime f1($a, $N)
# 436.185 μs (2001 allocations: 1.71 MiB)
```

In this case use the **inplace (broadcasted) assignment**
```julia
function f2(a, N)
	x = zero(a)
	for i in 1:N
		x .+= i * a # "add element-wise to `x`
	end
	x
end

@btime f2($a, $N)
# 354.372 μs (1001 allocations: 875.88 KiB)
```

- When running a compution whose output memory can be recycled (see the exercise!)

- When taking slices (see the exercise!)


#### Single instruction, multiple data: `@simd`
CPUs operate on data present in registers inside the CPU, which are meant to hold small fixed size slots, like floats (see the `r`s in `@code_native`).
Since this is a major bottleneck, modern CPUs have bigger registries (instead of 64-bit, 256+), which allow a **S**ingle **I**nstruction operate on **M**ultiple **D**ata.

Show the difference of
```julia
using StaticArrays
a = @SVector Int32[1,2,3,4,5,6,7,8]
code_native(+, (typeof(a), typeof(a)), debuginfo=:none)

a = @SVector Int64[1,2,3,4,5,6,7,8]
code_native(+, (typeof(a), typeof(a)), debuginfo=:none)

a = @SVector Int64[1,2,3,4]
code_native(+, (typeof(a), typeof(a)), debuginfo=:none)
```

- SIMD needs uninterrupted iteration of fixed length
- Bound-checking causes branching so deactivate it with `@inbounds for i in ...` (This is also may be desirable for critical non-`@simd` loops)
  - Avoid branching at all costs. Even with _branch prediction_, a misprediction (common for random braches) will cost several CPU cycles.
- SIMD needs associative operations (since the loop will be reordered)
Since float addition is **not** associative, automatic `@simd` is not "automatically" on for, e.g., float addition
```julia
@show 0.1 + (0.2 + 0.3)
@show (0.1 + 0.2) + 0.3
```

Actually, IEEE 754 float arithmetic is tricky! Consider a number that is undefined or unrepresentable, a `NaN`
```julia
@show NaN == NaN # not even reflexive!
```

[Reference](https://biojulia.net/post/hardware/#simd)
"""

# ╔═╡ a3346d6a-919a-11eb-13e9-59293be49654
md"""
#### Exercise: The 3 ecology Rs: RECYCLE, REUSE and REDUCE

- Avoid extra allocations by _recycling_
  - Rewrite `loopinc` using an in-place version of `xinc` –> `xinc!`
  - Compare the performance of the new `loop` function
  - Note: The point is not to optimise away the `ret[2]` part so keep it!
```julia
xinc(x) = [x, x+1, x+2]
function loop()
	y = 0
	for i = 1:10^7
		ret = xinc(i)
		y += ret[2]
	end
	return y
end
```


- Avoid extra allocations by _reusing_
  - Create a `(50, 100_000)` `rand`om matrix `A` and a vector `x` with size `(100_000,)`
  - Compare the performance of ``\sum_i \sum^{80000}_{j=1}A_{ij}x_j`` using `slice`s and `@view`s
  - Note that performance from `@view` is just a [rule of thumb](https://docs.julialang.org/en/v1/manual/performance-tips/#Copying-data-is-not-always-bad).


- Optimise away by _reducing_ (and everything else)
```julia
function work()
	A = zeros(N,N)
	for i in 1:N
        for j in 1:N
            val = mod(v[i],256);
            A[i,j] = B[i,j]*(sin(val)*sin(val)-cos(val)*cos(val))
        end
	end
	return A
end
```

given the parameters
```julia
N = 4_000
B = [float(i-j) for i in 1:N, j in 1:N]
v = [i for i in 1:N]
```

Pro-tip: Compare different implementations of `work!` using the `≈` (`\approx`) operator, since the `==` may be too strict given the shenanigans we encountered with float arithmetics.
"""

# ╔═╡ fd81c0c0-91fd-11eb-1ddb-1546f52626af
#= md"""
##### Solution
This excellent exercise was adapted from [here](https://github.com/crstnbr/JuliaCologne21/blob/master/Day2/exercise_solutions/solution_optimization2.ipynb)

```julia
using Test
using BenchmarkTools

# Parameters
N = 1_000
B = [float(i-j) for i in 1:N, j in 1:N]
v = [i for i in 1:N]

# Base
function work()
	A = zeros(N,N)
	for i in 1:N
        for j in 1:N
            val = mod(v[i],256);
            A[i,j] = B[i,j]*(sin(val)*sin(val)-cos(val)*cos(val))
        end
	end
	return A
end

@btime work()
# 670.186 ms (11469981 allocations: 197.94 MiB)
```

- Purge globals!
```julia
@code_warntype work()

function work1(B, v, N)
	A = zeros(N,N)
	for i in 1:N
        for j in 1:N
            val = mod(v[i],256);
            A[i,j] = B[i,j]*(sin(val)*sin(val)-cos(val)*cos(val))
        end
	end
	return A
end

@code_warntype work(B, v, N)

@test work() ≈ work1(B, v, N)
@btime work1($B, $v, $N)
# 88.320 ms (2 allocations: 7.63 MiB)
```

- Analytic optimisations (these are the best)
```julia
@testset "My trig identities" begin
	x = rand()
	@test 1-2*cos(x)*cos(x) ≈ sin(x)*sin(x)-cos(x)*cos(x)
	@test -cos(2*x) ≈ sin(x)*sin(x)-cos(x)*cos(x)
end

function work2(B, v, N)
    A = zeros(N,N)
    for i in 1:N
        for j in 1:N
            val = mod(v[i],256);
            A[i,j] = B[i,j]*(-cos(2*val));
        end
    end
	return A
end

@test work() ≈ work2(B, v, N)
@btime work2($B, $v, $N)
# 37.520 ms (2 allocations: 7.63 MiB)
```

- Pull-out `val` computation
```julia
function work3(B, v, N)
    A = zeros(N,N)
    for i in 1:N
		val = -cos(2*mod(v[i],256))
        for j in 1:N
            A[i,j] = B[i,j]*val;
        end
    end
	return A
end

function work4(B, v, N)
	val = [-cos(2*mod(x,256)) for x in v]

    A = zeros(N,N)
    for i in 1:N
        for j in 1:N
            A[i,j] = B[i,j]*val[i];
        end
    end
	return A
end

@test work() ≈ work3(B, v, N)
@test work() ≈ work4(B, v, N)

@btime work3($B, $v, $N)
# 20.755 ms (2 allocations: 7.63 MiB)

@btime work4($B, $v, $N)
# 20.262 ms (3 allocations: 7.64 MiB)
```

- Switch order of the loops: favour data locality!
```julia
function work5(B, v, N)
	val = [-cos(2*mod(x,256)) for x in v]

    A = zeros(N,N)
    for j in 1:N
        for i in 1:N
            A[i,j] = B[i,j]*val[i];
        end
    end
	return A
end

@test work() ≈ work5(B, v, N)

@btime work5($B, $v, $N)
# 4.947 ms (3 allocations: 7.64 MiB)
```

- `@inbounds` and `@simd`
```julia
function work6(B, v, N)
	val = [-cos(2*mod(x,256)) for x in v]

    A = zeros(N,N)
    for j in 1:N
        for i in 1:N
            @inbounds A[i,j] = B[i,j] * val[i];
        end
    end
	return A
end

@test work() ≈ work6(B, v, N)

@btime work6($B, $v, $N)
# 3.298 ms (3 allocations: 7.64 MiB)
```

- Broadcast it for beauty points
```julia
work7(B, v) = return B .* [-cos(2*mod(x,256)) for x in v]

@test work() ≈ work7(B, v)

@btime work7($B, $v, $N)
# 2.019 ms (3 allocations: 7.64 MiB)
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

# ╔═╡ b58a861c-7b50-11eb-286d-c5a5dd03429f
#= md"""
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
""" =#

# ╔═╡ Cell order:
# ╟─59afc220-9195-11eb-2384-29ae6f4aa263
# ╟─e5c840d8-8978-11eb-37fa-77fb05a3d821
# ╟─8636e926-8b38-11eb-3f98-f58135f3d02e
# ╟─540516aa-8b38-11eb-26f8-d31b72022689
# ╟─53f03512-8b38-11eb-031b-55d81ef5aeac
# ╟─533f5a58-8b38-11eb-1c75-61000cf8394f
# ╟─e6cc166a-8ed2-11eb-23be-2d657eb00795
# ╟─247b2cf8-8ed3-11eb-19ee-fd0f17cec519
# ╟─9ba8170a-7b50-11eb-0aac-adc493e1f386
# ╟─c9862c2a-897e-11eb-3592-ada39cc0637b
# ╟─44b9eb9c-8980-11eb-17b8-1937532d3a28
# ╟─af38a46c-8981-11eb-26de-35f9e487423c
# ╟─afc5f13c-8ee2-11eb-2dfe-0dcbc74c120e
# ╟─bded83c2-8ee2-11eb-3b00-a7681ba476dc
# ╟─0d6a34a4-8ee3-11eb-08ae-2763ca230fd5
# ╟─59e7aaf0-8cac-11eb-0ea8-3fb87d36ad90
# ╟─45c45594-8ca4-11eb-1db9-6187459bf306
# ╟─4bee5324-8eeb-11eb-326b-efba53215f34
# ╟─28f63950-8eef-11eb-0481-55fad44619d5
# ╟─8ac22e72-8978-11eb-1674-e1b95403e215
# ╟─8d9f2162-8f07-11eb-1c1d-b994b88811e1
# ╟─bff46124-8f08-11eb-1140-d78145e2fe05
# ╟─fdfddce2-919d-11eb-1b48-5d31c8d4b250
# ╟─8a97bcb8-91a3-11eb-37b4-4f9004e01e0b
# ╟─0ae35bf0-91a6-11eb-1a75-235aaf78d346
# ╟─700b1240-9197-11eb-0cfd-1bb3d7393084
# ╟─a3346d6a-919a-11eb-13e9-59293be49654
# ╟─fd81c0c0-91fd-11eb-1ddb-1546f52626af
# ╟─4eb2573e-8998-11eb-2274-379a03bed49c
# ╟─b58a861c-7b50-11eb-286d-c5a5dd03429f
