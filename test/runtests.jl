using NamedVecs
using Test

@testset "NamedVecs.jl" begin
    v = NamedVec((a=[1], b=[2, 3]))
    @test v == [1, 2, 3]
    @test v.a == [1]
    @test v.b == [2, 3]
    v[2] = 5
    @test v == [1, 5, 3]
    @test v.b == [5, 3]
    @test 2v == [2, 10, 6]
    @test (2v).b == [10, 6]
end
