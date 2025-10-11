import TabularFunctions: BadMacroInput
import TabularFunctions: XsNotMonotonicallyIncreasing
using Adapt
using Aqua
using TabularFunctions
using Test

@testset "Adapt PiecewiseAnalyticFunction - CPU" begin
    xs = [0., 1.]
    funcs = [sin, cos]
    f = PiecewiseAnalyticFunction(xs, funcs)
    f_new = adapt(Array, f)
end

@testset "Adapt PiecewiseLinearFunction - CPU" begin
    xs = 0.:0.1:1. |> collect
    ys = 0.:0.1:1. |> collect

    f = PiecewiseLinearFunction(xs, ys)
    f_new = adapt(Array, f)
    @test all(f.x_vals .== f_new.x_vals)
    @test all(f.y_vals .== f_new.y_vals)
end

@testset "Error checking" begin
    @test_throws AssertionError PiecewiseLinearFunction([0., 1.], [0., 1., 2.])
    @test_throws XsNotMonotonicallyIncreasing PiecewiseLinearFunction([0., 0.1, -0.1, 1.], [0., 0., 0., 0.])

    code = """
    @piecewise_analytic begin
        0.0          # malformed
        1.0, cos
    end
    """
    @test_throws LoadError eval(Meta.parse(code))

    # code = """
    # @piecewise_linear begin
    #     0.0
    #     1.0, 1.0
    # end
    # """
    # @test_throws LoadError eval(Meta.parse(code))
end

@testset "Macros" begin 
    func = @piecewise_analytic begin
        0.0, sin
        1.0, cos
    end
    @test func(0.5) == sin(0.5)
    @test func(1.5) == cos(1.5)

    func = @piecewise_analytic begin
        0.0, x -> sin(x)
        1.0, x -> cos(x)
    end
    @test func(0.5) == sin(0.5)
    @test func(1.5) == cos(1.5)

    func = @piecewise_analytic begin
        0.0, 0.0
        1.0, sin
    end
    @test func(0.5) == 0.0
    @test func(1.5) == sin(1.5)

    func = @piecewise_linear begin
        0.0,  0.0
        0.25, 0.25
        1.0,  1.0
    end
    @test func(0.5) == 0.5
end

@testset "PiecewiseAnalyticFunction - Identity function" begin
    # xs = 0.:0.1:1. |> collect
    f = PiecewiseAnalyticFunction([0.], [identity])
    xs = -1.:0.1:1. |> collect
    @test all(f.(xs) .== xs)
end

@testset "PiecewiseLinearFunction - Identity function" begin
    xs = 0.:0.1:1. |> collect
    ys = 0.:0.1:1. |> collect

    f = PiecewiseLinearFunction(xs, ys)

    @test all(f.(xs) .== ys)
    temp_xs = 0.:0.01:1.
    @test all(f.(temp_xs) .== temp_xs)
end

@testset "PiecewiseAnalyticFunction - Switching trig" begin
    xs = [0., 1.]
    funcs = [sin, cos]
    f = PiecewiseAnalyticFunction(xs, funcs)

    xs = -1.:0.1:0.9 |> collect
    @test all(f.(xs) .== sin.(xs))

    xs = 1.:0.1:2. |> collect
    @test all(f.(xs) .== cos.(xs))
end

@testset "PiecewiseLinearFunction - Parabola function" begin
    xs = 0.:0.1:1. |> collect
    ys = map(x -> x * x, xs)
    f = PiecewiseLinearFunction(xs, ys)

    @test all(f.(xs) .== ys)
    temp_xs = 0.:0.01:1. 

    @test f(-0.05) ≈ 0.0
    @test f(0.05) ≈ 0.005
    @test f(0.15) ≈ 0.025
    @test f(0.25) ≈ 0.065
    @test f(0.35) ≈ 0.125
    @test f(0.45) ≈ 0.205
    @test f(0.55) ≈ 0.305
    @test f(0.65) ≈ 0.425
    @test f(0.75) ≈ 0.565
    @test f(0.85) ≈ 0.725
    @test f(0.95) ≈ 0.905
    @test f(1.05) ≈ 1.
end

# Aqua testing
@testset "Aqua.jl" begin
    Aqua.test_all(TabularFunctions)
end
