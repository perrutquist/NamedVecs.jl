using NamedVecs
using Test

@testset "NamedVecs.jl" begin
    v = NamedVec((a=[1], b=[2, 3], c=4))
    @test v == [1, 2, 3, 4]
    @test v.a == [1]
    @test v.b == [2, 3]
    @test v.c === 4
    v[2] = 5
    @test v == [1, 5, 3, 4]
    @test v.b == [5, 3]
    @test 2v == [2, 10, 6, 8]
    @test (2v).b == [10, 6]
    @test (2v).c === 8
end
