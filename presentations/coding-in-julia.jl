### A Pluto.jl notebook ###
# v0.12.20

using Markdown
using InteractiveUtils

# ╔═╡ 036555ee-7758-11eb-11e0-194ebe3d6f15
html"<button onclick='present()'>present</button>"

# ╔═╡ 1fc8fccc-7758-11eb-3d10-b1c72df65ebd
md"""
# Programming scientifically in Julia

- Julia is easy to read and write (but so are Python or Matlab)
- Julia is performant and scalable* (but so are C or Fortran)
- Julia is interactive (but so are Python or Mathematica)

> Researchers often find themselves coding algorithms in one programming language, only to have to rewrite them in a faster one.

**Julia** solves the two-language problem.
"""

# ╔═╡ cf2303d2-7b45-11eb-3301-89fab00d5c9d
md"""
## Power of (a good) Language

Abelman and Sussman, Structure and Interpretation of Computer Programs
> Programs must be written for people to read, and only incidentally for machines to execute.

Bertrand Russell
> Language serves not only to express thoughts, but to make possible thoughts which could not exist without it.

Ludwig Wittgenstein
> The limits of my language mean the limits of my world.
"""

# ╔═╡ 1340a278-7b47-11eb-2958-cff4ccdd630a
md"""
## So why exactly is Julia great?

#### Julia is easy to learn

This easiness arrises from a clear and concise syntax (similar but quite more refined than Python), which results in small but clear code.
"""

# ╔═╡ be149b64-7b47-11eb-14cc-2ba364843de5
md"""
## So why exactly is Julia great?

#### Julia is (easily) fast
Tricky definition: 
- Most languages are "equivalent" on a theoretical level but in practise greatly differ
- One can write terribly slow programs in languages that are supposed to be fast

The norm is that something in pure Julia will run a lot faster than in most dynamic languages.

**Native Julia can beat highly optimised libraries** (some of the fastest BLAS-like operations are in `LoopVectorization.jl`). No magic: Julia shares the same LLVM backend with e.g. C++ so the compiled performances can be very similar.

Don't focus on the fact that Julia is faster or not but **that it's simply much simpler to write high-performant and clear code in Julia than in other languages**.
"""

# ╔═╡ 528ae93c-7b49-11eb-12f2-63a759823973
md"""
## So why exactly is Julia great?

#### Julia is (easily) fast

Calculate the mean of an array ignoring NaNs [in Julia](https://github.com/mlubin/NaNMath.jl/blob/master/src/NaNMath.jl#L216)

```
function mean_count(x::AbstractArray{T}) where T<:AbstractFloat
    z = zero(eltype(x))
    sum = z
    count = 0
    @simd for i in x
        count += ifelse(isnan(i), 0, 1)
        sum += ifelse(isnan(i), z, i)
    end
    result = sum / count
    return (result, count)
end
```
"""

# ╔═╡ 8b1823f0-7b49-11eb-227f-ab9723138570
md"""
## So why exactly is Julia great?

#### Julia is (easily) fast

Calculate the mean of an array ignoring NaNs [in Python (Numpy)]
(https://github.com/pydata/bottleneck/blob/b62427287f61ad9c12b8101b5c94a6b7b90c9a14/bottleneck/src/reduce_template.c#L213-L314)

```
/* dtype = [['float64'], ['float32']] */
REDUCE_ALL(nanmean, DTYPE0) {
    Py_ssize_t count = 0;
    npy_DTYPE0 ai, asum = 0;
    INIT_ALL
    BN_BEGIN_ALLOW_THREADS
    WHILE {
        FOR {
            ai = AI(DTYPE0);
            if (!bn_isnan(ai)) {
                asum += ai;
                count += 1;
            }
        }
        NEXT
    }
    BN_END_ALLOW_THREADS
    if (count > 0) {
        return PyFloat_FromDouble(asum / count);
    } else {
        return PyFloat_FromDouble(BN_NAN);
    }
}

REDUCE_ONE(nanmean, DTYPE0) {
    Py_ssize_t count;
    npy_DTYPE0 ai, asum;
    INIT_ONE(DTYPE0, DTYPE0)
    BN_BEGIN_ALLOW_THREADS
    if (LENGTH == 0) {
        FILL_Y(BN_NAN)
    } else {
        WHILE {
            count = 0;
            asum = 0;
            FOR {
                ai = AI(DTYPE0);
                if (!bn_isnan(ai)) {
                    asum += ai;
                    count += 1;
                }
            }
            if (count > 0) {
                asum /= count;
            } else {
                asum = BN_NAN;
            }
            YPP = asum;
            NEXT
        }
    }
    BN_END_ALLOW_THREADS
    return y;
}
/* dtype end */

/* dtype = [['int64', 'float64'], ['int32', 'float64']] */
REDUCE_ALL(nanmean, DTYPE0) {
    Py_ssize_t total_length = 0;
    npy_DTYPE1 asum = 0;
    INIT_ALL
    BN_BEGIN_ALLOW_THREADS
    WHILE {
        FOR asum += AI(DTYPE0);
        total_length += LENGTH;
        NEXT
    }
    BN_END_ALLOW_THREADS
    if (total_length > 0) {
        return PyFloat_FromDouble(asum / total_length);
    } else {
        return PyFloat_FromDouble(BN_NAN);
    }
}

REDUCE_ONE(nanmean, DTYPE0) {
    npy_DTYPE1 asum;
    INIT_ONE(DTYPE1, DTYPE1)
    BN_BEGIN_ALLOW_THREADS
    if (LENGTH == 0) {
        FILL_Y(BN_NAN)
    } else {
        WHILE {
            asum = 0;
            FOR asum += AI(DTYPE0);
            if (LENGTH > 0) {
                asum /= LENGTH;
            } else {
                asum = BN_NAN;
            }
            YPP = asum;
            NEXT
        }
    }
    BN_END_ALLOW_THREADS
    return y;
}
/* dtype end */
```
"""

# ╔═╡ f9c5c958-7b47-11eb-05c5-59c9455b6ed1
md"""
## So why exactly is Julia great?

#### Julia is (uniquely) both strongly-typed and dynamic

- _static, compiled, user types_ (in C, Fortran, etc)
- _dynamic, interpreted, standard types_ (in Python, Mathematica, etc)
- **dynamic, compiled, user types** (Julia)

In dynamic languages the types of variables don't have to be known an runtime (type annotation is optional).

In compiled languages the functions are compiled (properly optimised) and don't suffer from interpretation overhead at runtime.

- Julia's type system has limits, no arrow types (f: Rⁿ → Rᵐ)
- The types has less dynamism than in Python (cannot add fields to a type)
"""
# . In Julia the number and type of fields are static such that their byte size and memory setups can be determined. So a concretely typed Vector{Float64} can be very fast (while in Python a List is essentially a Vector{Any} and one needs to resort to Numpy for speed). 

# ╔═╡ 21ec2982-7b49-11eb-2fc3-a799a8b09712
md"""
## So why exactly is Julia great?

#### Julia has multiple dispatch

> People come to Julia for speed but stay for the multiple dispatch

Difference from OOP (single-dispatch)
```
class Car 
    def __init__(self, color, brand):
		# instance variable unique to each instance
		self.color = color
		self.brand = brand

	def information(self):
		return "I'm a {} {}".format(self.color, self.brand)

car = Car("yellow", "mercedes")
car.information()
```

Philosophy: Methods shouldn’t belong to a specific data type:
> It makes little sense to artificially deem the operations to "belong" to one argument more than any of the others.

Since there are no classes in Julia, the structures only contain data but no methods
```julia
struct Car
	color
	brand
end

information(c::Car) = "I'm a $(c.color) $(c.brand)"

car = Car("yellow", "mercedes")
information(car)
```

##### Levels of dispatch
- none: `f(x1,x2,x3,...)` constant expressive power (e.g., Python functions)
- single: `(x1::T1).f(x2,x3,...)` linear expressive power (e.g., Python class methods)
- multiple `f(x1::T1,x2::T2,x3,...)` exponential expressive power (Julia's core  paradigm)

#### Sharing types
Much simpler to define **new** operations on existing types

- Extending existing operations
```julia
information(n::Number) = "I'm a number"
```
Give several functions the same name, because they perform conceptually similar tasks, but operate on different types.

- Defining new operations
```julia
is_beautiful(c::Car) = (c.color == "rose gold")
```

How to do it in OOP? With inheritance one needs to use another name (`NewCar`) or edit the original class or simply drop (single) dispatch. 
"""

# ╔═╡ 2cf41e6e-7b49-11eb-02bf-23174a7e8ce3
md"""
## So why exactly is Julia great?

#### Julia is garbage-collected
No need to worry about memory management.

#### Julia supports concurrent, parallel and distributed computing
Natively and with simple and clear syntax.

#### Julia interfaces particularly well with other languages
Can directly call Python or C.
"""

# ╔═╡ Cell order:
# ╟─036555ee-7758-11eb-11e0-194ebe3d6f15
# ╟─1fc8fccc-7758-11eb-3d10-b1c72df65ebd
# ╟─cf2303d2-7b45-11eb-3301-89fab00d5c9d
# ╟─1340a278-7b47-11eb-2958-cff4ccdd630a
# ╟─be149b64-7b47-11eb-14cc-2ba364843de5
# ╟─528ae93c-7b49-11eb-12f2-63a759823973
# ╟─8b1823f0-7b49-11eb-227f-ab9723138570
# ╟─f9c5c958-7b47-11eb-05c5-59c9455b6ed1
# ╟─21ec2982-7b49-11eb-2fc3-a799a8b09712
# ╟─2cf41e6e-7b49-11eb-02bf-23174a7e8ce3
