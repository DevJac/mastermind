module Bags

export Bag
export add!, remove!
export sample_remove!

import StatsBase: sample, Weights

using Printf
using Test: @test

mutable struct Bag{T}
    contents :: Dict{T, Int}

    Bag{T}(_::UndefInitializer) where T = new{T}()
    Bag{T}() where T = new{T}(Dict())
end

Bag() = Bag{Any}(Dict())
Bag(iter) = Bag{eltype(iter)}(iter)

function Bag{T}(iter) where T
    new_bag = Bag{T}()
    for item in iter
        add!(new_bag, item)
    end
    new_bag
end

Base.in(i, bag::Bag) = i in keys(bag.contents)
Base.:(==)(a::Bag, b::Bag) = a.contents == b.contents
Base.length(bag::Bag) = sum(values(bag.contents))
Base.collect(bag::Bag{T}) where T = collect(T, bag)
Base.eltype(bag::Bag{T}) where T = T
Base.iterate(bag::Bag) = iterate(bag, 1)
Base.iterate(bag::Bag, i) = i > length(bag) ? nothing : (bag[i], i+1)

function Base.getindex(bag::Bag, index)
    if index < 1
        throw(BoundsError(bag, index))
    end
    i = index
    for (item, count) in bag.contents
        if i <= count
            @assert count > 0
            return item
        end
        @assert count < i
        i -= count
    end
    throw(BoundsError(bag, index))
end

function Base.filter(f, bag::Bag{T}) where T
    filtered_bag = Bag{T}(undef)
    filtered_bag.contents = filter(pair -> f(pair.first), bag.contents)
    filtered_bag
end

function Base.filter!(f, bag::Bag)
    filter!(pair -> f(pair.first), bag.contents)
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
    @test eltype(b) == Any
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
    @test typeof(b) == Bag{Int}
    @test typeof(collect(b)) == Vector{Int}
    @test eltype(b) == Int
    @test filter(isodd, b) == Bag([1, 3, 3])
    filter!(isodd, b)
    @test b == Bag([1, 3, 3])
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
    b = Bag([1, 1, 1])
    s = sample_remove!(b, 3)
    @test s == [1, 1, 1]
end

function sample(bag::Bag, n; replace=true)
    sampled_indices = sample(1:length(bag), n; replace=replace)
    [bag[i] for i in sampled_indices]
end

function test()
    test_bag()
    test_sample_remove()
end

test()

end # module
