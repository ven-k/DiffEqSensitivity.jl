SensitivityAlg(args...;kwargs...) = @error("The SensitivtyAlg choice mechanism was completely overhauled. Please consult the local sensitivity documentation for more information")

abstract type AbstractForwardSensitivityAlgorithm{CS,AD,FDT} <: DiffEqBase.AbstractSensitivityAlgorithm{CS,AD,FDT} end
abstract type AbstractAdjointSensitivityAlgorithm{CS,AD,FDT} <: DiffEqBase.AbstractSensitivityAlgorithm{CS,AD,FDT} end
abstract type AbstractSecondOrderSensitivityAlgorithm{CS,AD,FDT} <: DiffEqBase.AbstractSensitivityAlgorithm{CS,AD,FDT} end

struct ForwardSensitivity{CS,AD,FDT} <: AbstractForwardSensitivityAlgorithm{CS,AD,FDT}
  autojacvec::Bool
  autojacmat::Bool
end
Base.@pure function ForwardSensitivity(;
                                       chunk_size=0,autodiff=true,
                                       diff_type=Val{:central},
                                       autojacvec=autodiff,
                                       autojacmat=false)
  autojacvec && autojacmat && error("Choose either Jacobian matrix products or Jacobian vector products,
                                      autojacmat and autojacvec cannot both be true")
  ForwardSensitivity{chunk_size,autodiff,diff_type}(autojacvec,autojacmat)
end

struct ForwardDiffSensitivity{CS,CTS} <: AbstractForwardSensitivityAlgorithm{CS,Nothing,Nothing}
end
Base.@pure function ForwardDiffSensitivity(;chunk_size=0,convert_tspan=nothing)
  ForwardDiffSensitivity{chunk_size,convert_tspan}()
end

"""
ODE:
 Rackauckas, C. and Ma, Y. and Martensen, J. and Warner, C. and Zubov, K. and Supekar,
 R. and Skinner, D. and Ramadhana, A. and Edelman, A., Universal Differential Equations
 for Scientific Machine Learning,	arXiv:2001.04385

 Hindmarsh, A. C. and Brown, P. N. and Grant, K. E. and Lee, S. L. and Serban, R.
 and Shumaker, D. E. and Woodward, C. S., SUNDIALS: Suite of nonlinear and
 differential/algebraic equation solvers, ACM Transactions on Mathematical
 Software (TOMS), 31, pp:363–396 (2005)

 Chen, R.T.Q. and Rubanova, Y. and Bettencourt, J. and Duvenaud, D. K.,
 Neural ordinary differential equations. In Advances in neural information processing
 systems, pp. 6571–6583 (2018)

 Pontryagin, L. S. and Mishchenko, E.F. and Boltyanskii, V.G. and Gamkrelidze, R.V.
 The mathematical theory of optimal processes. Routledge, (1962)

 Rackauckas, C. and Ma, Y. and Dixit, V. and Guo, X. and Innes, M. and Revels, J.
 and Nyberg, J. and Ivaturi, V., A comparison of automatic differentiation and
 continuous sensitivity analysis for derivatives of differential equation solutions,
 arXiv:1812.01892

DAE:
 Cao, Y. and Li, S. and Petzold, L. and Serban, R., Adjoint sensitivity analysis
 for differential-algebraic equations: The adjoint DAE system and its numerical
 solution, SIAM journal on scientific computing 24 pp: 1076-1089 (2003)

SDE:
 Gobet, E. and Munos, R., Sensitivity Analysis Using Ito-Malliavin Calculus and
 Martingales, and Application to Stochastic Optimal Control,
 SIAM Journal on control and optimization, 43, pp. 1676-1713 (2005)

 Li, X. and Wong, T.-K. L.and Chen, R. T. Q. and Duvenaud, D.,
 Scalable Gradients for Stochastic Differential Equations,
 PMLR 108, pp. 3870-3882 (2020), http://proceedings.mlr.press/v108/li20i.html
"""
struct BacksolveAdjoint{CS,AD,FDT,VJP,NOISE} <: AbstractAdjointSensitivityAlgorithm{CS,AD,FDT}
  autojacvec::VJP
  checkpointing::Bool
  noise::NOISE
  noisemixing::Bool
end
Base.@pure function BacksolveAdjoint(;chunk_size=0,autodiff=true,
                                      diff_type=Val{:central},
                                      autojacvec=autodiff,
                                      checkpointing=true, noise=true,noisemixing=false)
  BacksolveAdjoint{chunk_size,autodiff,diff_type,typeof(autojacvec),typeof(noise)}(autojacvec,checkpointing,noise,noisemixing)
end

"""
 Rackauckas, C. and Ma, Y. and Martensen, J. and Warner, C. and Zubov, K. and Supekar,
 R. and Skinner, D. and Ramadhana, A. and Edelman, A., Universal Differential Equations
 for Scientific Machine Learning,	arXiv:2001.04385

 Hindmarsh, A. C. and Brown, P. N. and Grant, K. E. and Lee, S. L. and Serban, R.
 and Shumaker, D. E. and Woodward, C. S., SUNDIALS: Suite of nonlinear and
 differential/algebraic equation solvers, ACM Transactions on Mathematical
 Software (TOMS), 31, pp:363–396 (2005)

 Rackauckas, C. and Ma, Y. and Dixit, V. and Guo, X. and Innes, M. and Revels, J.
 and Nyberg, J. and Ivaturi, V., A comparison of automatic differentiation and
 continuous sensitivity analysis for derivatives of differential equation solutions,
 arXiv:1812.01892
"""
struct InterpolatingAdjoint{CS,AD,FDT,VJP,NOISE} <: AbstractAdjointSensitivityAlgorithm{CS,AD,FDT}
  autojacvec::VJP
  checkpointing::Bool
  noise::NOISE
  noisemixing::Bool
end
Base.@pure function InterpolatingAdjoint(;chunk_size=0,autodiff=true,
                                         diff_type=Val{:central},
                                         autojacvec=autodiff,
                                         checkpointing=false, noise=true,noisemixing=false)
  InterpolatingAdjoint{chunk_size,autodiff,diff_type,typeof(autojacvec),typeof(noise)}(autojacvec,checkpointing,noise,noisemixing)
end

struct QuadratureAdjoint{CS,AD,FDT,VJP} <: AbstractAdjointSensitivityAlgorithm{CS,AD,FDT}
  autojacvec::VJP
  abstol::Float64
  reltol::Float64
  compile::Bool
end
Base.@pure function QuadratureAdjoint(;chunk_size=0,autodiff=true,
                                         diff_type=Val{:central},
                                         autojacvec=autodiff,abstol=1e-6,
                                         reltol=1e-3,compile=false)
  QuadratureAdjoint{chunk_size,autodiff,diff_type,typeof(autojacvec)}(autojacvec,abstol,reltol,compile)
end

struct TrackerAdjoint <: AbstractAdjointSensitivityAlgorithm{nothing,true,nothing} end
struct ReverseDiffAdjoint <: AbstractAdjointSensitivityAlgorithm{nothing,true,nothing} end
struct ZygoteAdjoint <: AbstractAdjointSensitivityAlgorithm{nothing,true,nothing} end

"""
Wang, Q., Hu, R., and Blonigan, P. Least squares shadowing sensitivity analysis of
chaotic limit cycle oscillations. Journal of Computational Physics, 267, 210-224 (2014).
"""
struct ForwardLSS{CS,AD,FDT,aType} <: AbstractForwardSensitivityAlgorithm{CS,AD,FDT}
  alpha::aType # alpha: weight of the time dilation term in LSS.
end
Base.@pure function ForwardLSS(;
                                chunk_size=0,autodiff=true,
                                diff_type=Val{:central},
                                alpha=CosWindowing())
  ForwardLSS{chunk_size,autodiff,diff_type,typeof(alpha)}(alpha)
end

"""
Wang, Q., Hu, R., and Blonigan, P. Least squares shadowing sensitivity analysis of
chaotic limit cycle oscillations. Journal of Computational Physics, 267, 210-224 (2014).
"""
struct AdjointLSS{CS,AD,FDT,aType} <: AbstractAdjointSensitivityAlgorithm{CS,AD,FDT}
  alpha::aType # alpha: weight of the time dilation term in LSS.
end
Base.@pure function AdjointLSS(;
                                chunk_size=0,autodiff=true,
                                diff_type=Val{:central},
                                alpha=10.0)
  AdjointLSS{chunk_size,autodiff,diff_type,typeof(alpha)}(alpha)
end

abstract type WindowingChoice end
struct CosWindowing <: WindowingChoice end
struct Cos2Windowing <: WindowingChoice end

"""
Ni, A., and Wang, Q. Sensitivity analysis on chaotic dynamical systems by Non-Intrusive
Least Squares Shadowing (NILSS). Journal of Computational Physics 347, 56-77 (2017).
"""
struct NILSS{CS,AD,FDT,RNG} <: AbstractAdjointSensitivityAlgorithm{CS,AD,FDT}
  rng::RNG
  nseg::Int
  nstep::Int
  autojacvec::Bool
end
Base.@pure function NILSS(nseg, nstep; rng = Xorshifts.Xoroshiro128Plus(rand(UInt64)),
                                chunk_size=0,autodiff=true,
                                diff_type=Val{:central},
                                autojacvec = autodiff
                                )
  NILSS{chunk_size,autodiff,diff_type,typeof(rng)}(rng, nseg, nstep, autojacvec)
end

"""
Ni, A., and Talnikar, C., Adjoint sensitivity analysis on chaotic dynamical systems 
by Non-Intrusive Least Squares Adjoint Shadowing (NILSAS). Journal of Computational 
Physics 395, 690-709 (2019).
"""
struct NILSAS{CS,AD,FDT,RNG,SENSE} <: AbstractAdjointSensitivityAlgorithm{CS,AD,FDT}
  rng::RNG
  adjoint_sensealg::SENSE
  M::Int
  nseg::Int
  nstep::Int
  autojacvec::Bool
end
Base.@pure function NILSAS(nseg, nstep, M=nothing; rng = Xorshifts.Xoroshiro128Plus(rand(UInt64)),
                                adjoint_sensealg = BacksolveAdjoint(),
                                chunk_size=0,autodiff=true,
                                diff_type=Val{:central},
                                autojacvec = autodiff
                                )
  # integer dimension of the unstable subspace
  M === nothing && error("Please provide an `M` with `M >= nus + 1`, where nus is the number of unstable covariant Lyapunov vectors.")

  NILSAS{chunk_size,autodiff,diff_type,typeof(rng),typeof(adjoint_sensealg)}(rng, adjoint_sensealg, M, 
    nseg, nstep, autojacvec)
end

"""
 Johnson, S. G., Notes on Adjoint Methods for 18.336, Online at
 http://math.mit.edu/stevenj/18.336/adjoint.pdf (2007)
"""
struct SteadyStateAdjoint{CS,AD,FDT,VJP,LS} <: AbstractAdjointSensitivityAlgorithm{CS,AD,FDT}
  autojacvec::VJP
  linsolve::LS
end

Base.@pure function SteadyStateAdjoint(;chunk_size = 0, autodiff = true, diff_type = Val{:central},
                                        autojacvec = autodiff, linsolve = nothing)
  SteadyStateAdjoint{chunk_size,autodiff,diff_type,typeof(autojacvec),typeof(linsolve)}(autojacvec,linsolve)
end

abstract type VJPChoice end
struct ZygoteVJP <: VJPChoice end
struct EnzymeVJP <: VJPChoice end
struct TrackerVJP <: VJPChoice end
struct ReverseDiffVJP{compile} <: VJPChoice
  ReverseDiffVJP(compile=false) = new{compile}()
end

abstract type NoiseChoice end
struct ZygoteNoise <: NoiseChoice end
struct ReverseDiffNoise{compile} <: NoiseChoice
  ReverseDiffNoise(compile=false) = new{compile}()
end

@inline convert_tspan(::ForwardDiffSensitivity{CS,CTS}) where {CS,CTS} = CTS
@inline convert_tspan(::Any) = nothing
@inline alg_autodiff(alg::DiffEqBase.AbstractSensitivityAlgorithm{CS,AD,FDT}) where {CS,AD,FDT} = AD
@inline get_chunksize(alg::DiffEqBase.AbstractSensitivityAlgorithm{CS,AD,FDT}) where {CS,AD,FDT} = CS
@inline diff_type(alg::DiffEqBase.AbstractSensitivityAlgorithm{CS,AD,FDT}) where {CS,AD,FDT} = FDT
@inline function get_jacvec(alg::DiffEqBase.AbstractSensitivityAlgorithm)
  alg.autojacvec isa Bool ? alg.autojacvec : true
end
@inline function get_jacmat(alg::DiffEqBase.AbstractSensitivityAlgorithm)
  alg.autojacmat isa Bool ? alg.autojacmat : true
end
@inline ischeckpointing(alg::DiffEqBase.AbstractSensitivityAlgorithm, sol=nothing) = false
@inline ischeckpointing(alg::InterpolatingAdjoint) = alg.checkpointing
@inline ischeckpointing(alg::InterpolatingAdjoint, sol) = alg.checkpointing || !sol.dense
@inline ischeckpointing(alg::BacksolveAdjoint, sol=nothing) = alg.checkpointing

@inline isnoise(alg::DiffEqBase.AbstractSensitivityAlgorithm) = false
@inline isnoise(alg::InterpolatingAdjoint) = alg.noise
@inline isnoise(alg::BacksolveAdjoint) = alg.noise

@inline isnoisemixing(alg::DiffEqBase.AbstractSensitivityAlgorithm) = false
@inline isnoisemixing(alg::InterpolatingAdjoint) = alg.noisemixing
@inline isnoisemixing(alg::BacksolveAdjoint) = alg.noisemixing

@inline compile_tape(vjp::ReverseDiffVJP{compile}) where compile = compile
@inline compile_tape(noise::ReverseDiffNoise{compile}) where compile = compile
@inline compile_tape(autojacvec::Bool) = false
@inline compile_tape(sensealg::QuadratureAdjoint) = sensealg.compile

struct ForwardDiffOverAdjoint{A} <: AbstractSecondOrderSensitivityAlgorithm{nothing,true,nothing}
  adjalg::A
end
