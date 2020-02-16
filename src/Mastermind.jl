module Mastermind

export Correctness, correct, misplaced, wrong
export correct_guess, correct_guess_ordered

include("Bags.jl"); using .Bags

using Random
using StatsBase
using Test: @test

@enum Correctness correct misplaced wrong

const Guess = Tuple{Int, Correctness}

function correct_guess_ordered(secret, guess)
    @assert length(secret) == length(guess)
    corrected_guess = Vector{Union{Nothing, Guess}}(nothing, length(guess))
    unused_secrets = Bag(secret)
    unused_guesses = Bag(guess)
    for i in 1:length(guess)
        if secret[i] == guess[i]
            corrected_guess[i] = (guess[i], correct)
            remove!(unused_secrets, secret[i])
            remove!(unused_guesses, guess[i])
        end
    end
    while true
        unused_intersection = intersect(unused_secrets, unused_guesses)
        length(unused_intersection) == 0 && break
        misplaced_color = unused_intersection[1]
        for i in shuffle(1:length(guess))
            if guess[i] == misplaced_color && isnothing(corrected_guess[i])
                corrected_guess[i] = (misplaced_color, misplaced)
                remove!(unused_secrets, misplaced_color)
                remove!(unused_guesses, misplaced_color)
                break
            end
        end
    end
    for i in 1:length(guess)
        if isnothing(corrected_guess[i])
            corrected_guess[i] = (guess[i], wrong)
        end
    end
    corrected_guess
end

function test_correct_guess_ordered()
    @test correct_guess_ordered([1, 2, 3, 4], [1, 2, 3, 4]) == [(1, correct), (2, correct), (3, correct), (4, correct)]
    @test correct_guess_ordered([1, 2, 3, 4], [1, 2, 3, 3]) == [(1, correct), (2, correct), (3, correct), (3, wrong)]
    @test correct_guess_ordered([1, 2, 3, 4], [5, 5, 5, 5]) == [(5, wrong), (5, wrong), (5, wrong), (5, wrong)]
    matched = 0
    for _ in 1:100
        if correct_guess_ordered([1, 2, 2, 2], [3, 3, 1, 1]) == [(3, wrong), (3, wrong), (1, misplaced), (1, wrong)]
            matched += 1
        end
    end
    @test 10 <= matched <= 90
end

function correct_guess(secret, guess)
    corrected_guess_ordered = correct_guess_ordered(secret, guess)
    countmap([i[2] for i in corrected_guess_ordered])
end

function test_correct_guess()
    @test correct_guess([1, 2, 3, 4], [1, 2, 3, 4]) == Dict(correct => 4)
    @test correct_guess([1, 2, 3, 4], [1, 2, 3, 3]) == Dict(correct => 3, wrong => 1)
    @test correct_guess([1, 2, 3, 4], [5, 5, 5, 5]) == Dict(wrong => 4)
    @test correct_guess([1, 2, 2, 2], [3, 3, 1, 1]) == Dict(wrong => 3, misplaced => 1)
end

function test()
    test_correct_guess_ordered()
    test_correct_guess()
end

test()

end # module
