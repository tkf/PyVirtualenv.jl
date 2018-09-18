module TestPyVirtualenv

using PyVirtualenv: _leak

@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

N = 10000

@testset "_leak(Cstring, ...)" begin
    for i in 1:N
        x = String(rand('A':'z', rand(1:1000)))
        y = Base.unsafe_string(_leak(Cstring, x))
        @test x == y
    end
end

@testset "_leak(Cwstring, ...)" begin
    for i in 1:N
        x = String(rand('A':'z', rand(1:1000)))
        a = Base.cconvert(Cwstring, x)
        ptr = _leak(a)
        z = unsafe_wrap(Array, ptr, size(a))
        @test z[end] == 0
        y = transcode(String, z)[1:end-1]
        @test x == y
    end
end

end  # module
