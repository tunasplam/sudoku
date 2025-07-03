# Sudoku

A library for building generic sudoku solvers that work for different variants.

# Philosophy and Structure

## Solvers
Solver is an abstract type representing all of the solvers for different sudoku variants. Each subtype of solver represents a puzzle of a specific sudoku variant that is to be solved. They define the ruleset for the variant, and contain the puzzle's Cells and CellBags (more on that later). Each solver defines the following methods:
- how to instantiate the puzzle from a given input string
- how to solve the puzzle

The puzzles are solved using functions inherited from the abstract type and functions defined for each subtype of CellBag.

## Puzzles
At their core, each puzzle is a grid of Cell objects. The puzzle is completed once all cells are filled.

## Cells
Each cell contains a value (which is empty is the cell is unsolved) and a list of possible values that could go into the cell.

## CellBags
The puzzles also have contain sets of CellBags, which are collections of pointers to cells in the puzzle where specific criteria need to be met in order for the solution to be valid. Some exmaples of cellbags and their requirements are Rows which require one of the number 1-9 within them. There are two common operations on CellBags:
- using cells within a CellBag to inform empty cells within the same CellBag.
- comparing two CellBags by using cells in one CellBag to inform the cells in another CellBag.

Sudoku variant rulesets are defined by which CellBags the puzzle contains. For example, the Classic ruleset is defined by `[Row, Column, Box]` whereas Diagonals is defined by `[Row, Column, Box, Diagonal]`.

## Roadmap

Benchmarks for classic sudoku solver
- all 100 PE96 problems
- find some tougher benchmarks

Random Generator for sudoku puzzles of given type

