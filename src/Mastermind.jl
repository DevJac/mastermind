module Mastermind

export Correctness, correct, misplaced, wrong
export guess_my_code, print_puzzle, correct_guess, correct_guess_ordered

include("Bags.jl"); using .Bags

using Printf
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
    corrected = countmap([i[2] for i in corrected_guess_ordered])
    (get(corrected, correct, 0), get(corrected, misplaced, 0), get(corrected, wrong, 0))
end

function test_correct_guess()
    @test correct_guess([1, 2, 3, 4], [1, 2, 3, 4]) == (4, 0, 0)
    @test correct_guess([1, 2, 3, 4], [1, 2, 3, 3]) == (3, 0, 1)
    @test correct_guess([1, 2, 3, 4], [5, 5, 5, 5]) == (0, 0, 4)
    @test correct_guess([1, 2, 2, 2], [3, 3, 1, 1]) == (0, 1, 3)
end

function print_puzzle()
    marbles = Bag{Int}(c for c=1:6, _=1:20)
    secret = sample_remove!(marbles, 4)
    possible_secrets = Set(Iterators.product(Iterators.repeated(1:6, 4)...))
    print(secret)
    print("\n"^40)
    while length(marbles) >= 4
        guess = sample_remove!(marbles, 4)
        corrected = correct_guess(secret, guess)
        for possible_secret in possible_secrets
            if correct_guess(possible_secret, guess) != corrected
                pop!(possible_secrets, possible_secret)
            end
        end
        @printf("%s %s %6d\n", guess, corrected, length(possible_secrets))
        if length(possible_secrets) <= 1
            @assert collect(first(possible_secrets)) == secret
            break
        end
    end
end

const possible_corrections = collect(
    Iterators.filter(x -> sum(x) == 4, Iterators.product(Iterators.repeated(0:4, 3)...)))

function score_guess(guess, possible_secrets)
    some_secrets = length(possible_secrets) > 100 ? rand(possible_secrets, 100) : possible_secrets
    min_elimed = -1
    for correction in possible_corrections
        # We assume correct_guess(actual_secret, guess) == correction.
        # We will count how many possible_secrets are eliminated by this correction.
        elimed = 0
        for possible_secret in some_secrets
            if correct_guess(possible_secret, guess) != correction
                # We assume correct_guess(actual_secret, guess) == correction,
                # so the fact that correct_guess(possible_secret, guess) != correction
                # means that possible_secret is not the secret code.
                # Thus, we have eliminated one possible_secret.
                elimed += 1
            end
        end
        if min_elimed == -1 || elimed < min_elimed
            min_elimed = elimed
        end
    end
    min_elimed
end

function guess_my_code()
    possible_guesses = collect(Iterators.product(Iterators.repeated(1:6, 4)...))
    possible_secrets = Set(possible_guesses)
    guesses_taken = 0
    while true
        @printf("Your code must be 1 of %d possible codes.\n", length(possible_secrets))
        if length(possible_secrets) <= 1
            if length(possible_secrets) == 1
                @printf("Your code is: %s\n", first(possible_secrets))
                @printf("I identified your code in %d guesses.", guesses_taken)
            else
                println("You have given me inconsistent corrections.")
            end
            break
        end
        guess = possible_guesses[argmax(map(g -> score_guess(g, possible_secrets), possible_guesses))]
        @printf("My guess is: %s\n", guess)
        print("Correct my guess: ")
        corrected = tuple(map(s -> parse(Int, s), split(readline()))...)
        @assert sum(corrected) == 4
        for possible_secret in possible_secrets
            if correct_guess(possible_secret, guess) != corrected
                pop!(possible_secrets, possible_secret)
            end
        end
        guesses_taken += 1
    end
end

function test()
    test_correct_guess_ordered()
    test_correct_guess()
end

test()

end # module
