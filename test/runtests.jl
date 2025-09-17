import TabularFunctions: XsNotMonotonicallyIncreasing
using Adapt
using TabularFunctions
using Test

@testset "Adapt - CPU" begin
    xs = 0.:0.1:1.
    ys = 0.:0.1:1.

    f = PiecewiseLinearFunction(xs, ys)
    f_new = adapt(Array, f)
    @test all(f.x_vals .== f_new.x_vals)
    @test all(f.y_vals .== f_new.y_vals)
end

@testset "Error checking" begin
    @test_throws AssertionError PiecewiseLinearFunction([0., 1.], [0., 1., 2.])
    @test_throws XsNotMonotonicallyIncreasing PiecewiseLinearFunction([0., 0.1, -0.1, 1.], [0., 0., 0., 0.])
end

@testset "Identity function" begin
    xs = 0.:0.1:1.
    ys = 0.:0.1:1.

    f = PiecewiseLinearFunction(xs, ys)

    @test all(f.(xs) .== ys)
    temp_xs = 0.:0.01:1.
    @test all(f.(temp_xs) .== temp_xs)
end

