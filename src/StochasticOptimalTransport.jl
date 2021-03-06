module StochasticOptimalTransport

using LogExpFunctions: LogExpFunctions

using LinearAlgebra: LinearAlgebra
using Random: Random
using Statistics: Statistics

include("utils.jl")
include("discrete.jl")
include("semidiscrete.jl")

@doc raw"""
    wasserstein([rng, ]c, μ, ν[, ε; kwargs...])

Estimate the (entropic regularization of the) Wasserstein distance
```math
W_{ε}(μ, ν) = \min_{π ∈ Π(μ,ν)} \int c(x, y) \,π(\mathrm{d}(x,y)) +
ε \mathrm{KL}(π \,|\, μ ⊗ ν)
```
with respect to cost function `c` using stochastic optimization.

If both measures `μ` and `ν` are [`DiscreteMeasure`](@ref)s, then the
Wasserstein distance is approximated with stochastic averaged gradient
descent (SAG). The convergence rate of SAG is ``O(1 / k)``, where
``k`` is the number of iterations, and hence converges faster than stochastic
gradient descent (SGD) at the price of increased memory consumption.

If only one of the measures `μ` and `ν` is a [`DiscreteMeasure`](@ref), then the
Wasserstein distance is approximated with stochastic gradient descent with
averaging (SGA). In this case, it is required that samples of the non-discrete measure `λ`
can be obtained with `rand(rng, λ)`. The convergence rate of SGA is ``O(1/√k)``,
where ``k`` is the number of iterations.

If `ε` is `nothing` (the default), then the unregularized Wasserstein distance is
approximated. Otherwise, the entropic regularization with `ε > 0` is estimated.

The SAG algorithm uses a constant step size, whereas the SGA algorithm uses the step size
schedule
```math
    τᵢ = \frac{τ₁}{1 + \sqrt{(i - 1) / w}}
```
for the ``i``th iteration, where ``τ₁`` corresponds to the initial step size and ``w``
indicates the number of iterations serving as a warm-up phase.

# Keyword arguments
- `maxiters::Int = 10_000`: maximum number of gradient steps
- `stepsize = 1`: constant stepsize of SAG or initial step size ``τ₁`` of SGA
- `warmup_phase = 1`: warm-up phase ``w`` of SGA
- `atol = 0`: absolute tolerance
- `rtol = iszero(atol) ? typeof(float(atol))(1 // 10_000) : 0`: relative tolerance
- `montecarlo_samples = 10_000`: Number of Monte Carlo samples from `μ` for approximating
  an expectation with respect to `μ` in the semi-discrete optimal transport problem

# References

Genevay et al. (2016). Stochastic Optimization for Large-Scale Optimal Transport. Advances in Neural Information Processing Systems (NIPS 2016), 29:3440-3448.

Peyré, Gabriel, & Marco Cuturi (2019). Computational Optimal Transport. Foundations and Trends in Machine Learning, 11(5-6):355-607.
"""
wasserstein(args...; kwargs...) = wasserstein(Random.GLOBAL_RNG, args...; kwargs...)
function wasserstein(
    rng::Random.AbstractRNG, c, μ, ν, ε::Union{Real,Nothing}=nothing; kwargs...
)
    # approximate solution `v` of the dual problem
    v = dual_v(rng, c, μ, ν, ε; kwargs...)

    # compute Wasserstein distance from dual solution
    cost = dual_cost(rng, c, v, μ, ν, ε; kwargs...)

    return cost
end

end
