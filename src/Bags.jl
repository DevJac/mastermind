module Bags

export Bag
export add!, remove!
export sample_remove!

import StatsBase: sample, Weights

using Printf
using Test: @test

mutable struct Bag{T}
    contents :: Dict{T, Int}
end

Bag() = Bag(Dict())

Bag(T::DataType) = Bag{T}(Dict())

function Bag(iter)
    T = eltype(iter)
    Bag(T, iter)
end

function Bag(T, iter)
    new_bag = Bag(T)
    for item in iter
        add!(new_bag, item)
    end
    new_bag
end

Base.in(i, bag::Bag) = i in keys(bag.contents)
Base.:(==)(a::Bag, b::Bag) = a.contents == b.contents
Base.length(bag::Bag) = sum(values(bag.contents))
Base.iterate(bag::Bag) = iterate(bag, 1)

function Base.iterate(bag::Bag, state)
    s = state
    for (item, count) in bag.contents
        if s <= count
            @assert count > 0
            return (item, state+1)
        end
        @assert count < s
        s -= count
    end
    nothing
end

function add!(bag::Bag, item)
    if !haskey(bag.contents, item)
        bag.contents[item] = 0
    end
    bag.contents[item] += 1
end

function remove!(bag::Bag, item)
    if !haskey(bag.contents, item)
        throw(KeyError(@sprintf("%s is not in the Bag", item)))
    end
    bag.contents[item] -= 1
    if bag.contents[item] <= 0
        delete!(bag.contents, item)
    end
end

function test_bag()
    b = Bag()
    @test length(b) == 0
    @test (3 in b) == false
    b = Bag([1, 2, 3])
    @test length(b) == 3
    @test (3 in b) == true
    b = Bag([1, 2, 3, 3])
    @test length(b) == 4
    @test length(collect(b)) == 4
    @test Set(collect(b)) == Set([1, 2, 3])
    @test sort(collect(b)) == [1, 2, 3, 3]
end

function sample_remove!(bag::Bag, n)
    s = sample(bag, n, replace=false)
    for i in s
        remove!(bag, i)
    end
    s
end

function test_sample_remove()
    b = Bag([1, 2, 3])
    @test length(b) == 3
    s = sample_remove!(b, 3)
    @test length(b) == 0
    @test b == Bag()
    @test Set(s) == Set([1, 2, 3])
end

function sample(bag::Bag, n; replace=true)
    sample(
        collect(keys(bag.contents)),
        Weights(collect(values(bag.contents))),
        n;
        replace=replace)
end

function test()
    test_bag()
    test_sample_remove()
end

test()

end # module
