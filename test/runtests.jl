using Test
using sudoku

@testset "Row" begin
    r1 = Row(1, [Cell(1, 1, 3), Cell(2, 0, 3), Cell(3, 2, 3)])
    r2 = Row(2, [Cell(1, 2, 3), Cell(2, 3, 3), Cell(3, 1, 3)])
    r3 = Row(3, [Cell(1, 1, 3), Cell(2, 1, 3), Cell(3, 0, 3)])
    r4 = Row(4, [Cell(1, 1, 4), Cell(2, 1, 4), Cell(3, 0, 4), Cell(4, 0, 4)])
    r5 = Row(5, [Cell(1, 0, 4), Cell(2, 3, 4), Cell(3, 0, 4), Cell(4, 0, 4)])
    r6 = Row(6, [Cell(1, 1, 4), Cell(2, 0, 4), Cell(3, 0, 4), Cell(4, 0, 4)])

    @test iscorrect(r1)
    @test iscorrect(r2)
    @test ! iscorrect(r3)
    @test ! iscorrect(r4)
    @test iscorrect(r5)

end

@testset "Cell" begin
    c1 = Cell(1, 1, Vector{Int}([]), 9)
    c2 = Cell(2, 0, Vector{Int}([3,4,5]), 9)
    c3 = Cell(3, 3, Vector{Int}([]), 9)
    c4 = Cell(4, 2, Vector{Int}([1,2]), 9)

    @test isempty(c2)
    @test !isempty(c1)

end

@testset "Classic" begin
    # sourced from grid 01 and grid 02 from project euler problem 96
    p1_in = """003020600
900305001
001806400
008102900
700000008
006708200
002609500
800203009
005010300"""

    p2_in = """200080300
060070084
030500209
000105408
000000000
402706000
301007040
720040060
004010003"""

    p3_in = """111
000
111"""

    p1 = Classic(p1_in)
    p2 = Classic(p2_in)
    @test_throws InvalidPuzzleException Classic(p3_in)

    print(string(p1))
    print(string(p2))

    print(solve(p1))
    print(solve(p2))

end

@testset "Classic_PE" begin
    # https://projecteuler.net/project/resources/p096_sudoku.txt
    path = joinpath(@__DIR__, "resources", "pe_classic_sudoku.txt")
    puzzles = split(read(path, String), '-')

    # TODO getting stuck on puzzle with this as first column:
    # 043080250

    #=
        stuck state:

        0  6  2  9  3  4  8  0  5
        4  0  0  0  0  1  2  0  3
        3  0  0  0  0  0  0  0  4
        9  4  0  0  6  2  5  0  8
        8  2  0  0  0  0  0  0  9
        0  5  1  4  8  9  0  0  0
        2  0  0  0  0  0  0  0  7
        5  0  9  7  0  0  0  0  1
        0  0  4  0  0  3  0  5  0
    =#
    # first string is empty
    for puzzle_in in puzzles
        @show puzzle_in
        p = Classic(String(puzzle_in))
        solve(p)
    end
    @test true
end
