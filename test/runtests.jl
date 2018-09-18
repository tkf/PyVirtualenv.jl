module TestPyVirtualenv

using PyVirtualenv: _leak, pycall_deps_jl, Py_IsInitialized, activate

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

@testset "activate" begin
    was_inited = Py_IsInitialized()
    pyprogramname = pycall_deps_jl().pyprogramname
    if was_inited
        @warn """
        Python interpreter is already initialized (PyCall is already imported?).
        not testing `activate`.  Use `Pkg.test("PyVirtualenv")` to run all the
        tests.
        """
    else
        @test activate(pyprogramname) == nothing
        @test activate(pyprogramname) == nothing  # it's idempotent
    end
    @test_throws ErrorException activate("non-existing-python",
                                         "non-existing-home")

    local sys_executable
    @eval using PyCall
    sys_executable = pyimport("sys")[:executable]
    if !was_inited
        if Sys.iswindows()
            @info "sys.executable = $sys_executable"
            @test_broken sys_executable == pyprogramname
        else
            @test sys_executable == pyprogramname
        end
    end
end

@testset for file in sort([file for file in readdir(joinpath(@__DIR__, "exec"))
                           if endswith(file, ".jl")])
    script = """
    $(Base.load_path_setup_code())
    include($(repr(joinpath(@__DIR__, "exec", file))))
    """
    cmd = `$(Base.julia_cmd()) --startup-file=no -e $script`
    @debug "Running" cmd
    env = copy(ENV)
    env["PYVIRTUALENV_JL_TEST_TARGET"] = dirname(@__DIR__)
    mktempdir() do path
        cmd = setenv(cmd, env; dir=path)
        @test success(pipeline(cmd; stdout=stdout, stderr=stderr))
    end
end

end  # module
