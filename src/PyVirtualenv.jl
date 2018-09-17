module PyVirtualenv

using Libdl

const _pycall_deps_jl = Ref{Module}()

""" Get path to `PyCall/deps/deps.jl` """
function pycall_deps_jl_path()
    modpath = Base.locate_package(Base.identify_package("PyCall"))
    return joinpath(dirname(modpath), "..", "deps", "deps.jl")
end
# e.g., ~/.julia/dev/PyCall/deps/deps.jl

""" Load `PyCall/deps/deps.jl` namespace. """
function pycall_deps_jl()
    if isdefined(_pycall_deps_jl, 1)
        return _pycall_deps_jl[]
    end
    mod = Module()
    Base.include(mod, pycall_deps_jl_path())
    _pycall_deps_jl[] = mod
    return mod
end

_clength(x::Cstring) = ccall(:strlen, Csize_t, (Cstring,), x) + 1
_clength(x) = length(x)

function __leak(::Type{T}, x) where T
    n = _clength(x)
    ptr = ccall(:malloc, Ptr{T}, (Csize_t,), n * sizeof(T))
    unsafe_copyto!(ptr, pointer(x), n)
    return ptr
end

"""
    _leak(T::Type, x::AbstractString) :: Ptr
    _leak(x::Array) :: Ptr

Leak `x` from Julia's GCer.
"""
_leak(x::Union{Cstring, Array}) = __leak(eltype(x), x)
_leak(T::Type, x::AbstractString) =
    _leak(Base.unsafe_convert(T, Base.cconvert(T, x)))
_leak(::Type{Cwstring}, x::AbstractString) =
    _leak(Base.cconvert(Cwstring, x))

function pythonhome_of(pyprogramname::AbstractString)
    if Sys.iswindows()
        script = """
        import sys
        sys.stdout.write(sys.prefix)
        sys.stdout.write(":")
        sys.stdout.write(sys.exec_prefix)
        """
        # [[~/.julia/dev/PyCall/deps/build.jl::PYTHONHOME]]
    else
        script = """
        import sys
        sys.stdout.write(sys.prefix)
        """
    end
    return read(open(`$pyprogramname -c $script`), String)
end

"""
    activate(pyprogramname::String, [PYTHONHOME::String])

Activate virtual environment of Python program at `pyprogramname`; it MUST
be compatible with the Python program configured for PyCall.jl.
"""
function activate(pyprogramname::AbstractString,
                  PYTHONHOME::AbstractString = pythonhome_of(pyprogramname))
    libpython = pycall_deps_jl().libpython
    handle = Libdl.dlopen(libpython, Libdl.RTLD_LAZY|Libdl.RTLD_DEEPBIND|Libdl.RTLD_GLOBAL)

    fp(f::Symbol) = Libdl.dlsym(handle, f)

    already_inited = 0 != ccall(fp(:Py_IsInitialized), Cint, ())
    if already_inited
        error("Re-activation not supported.")
    end

    is_py2 = pycall_deps_jl().pyversion_build.major < 3

    if is_py2
        ccall(fp(:Py_SetPythonHome), Cvoid, (Cstring,),
              _leak(Cstring, PYTHONHOME))
    else
        ccall(fp(:Py_SetPythonHome), Cvoid, (Ptr{Cwchar_t},),
              _leak(Cwstring, PYTHONHOME))
    end

    if is_py2
        ccall(fp(:Py_SetProgramName), Cvoid, (Cstring,),
              _leak(Cstring, pyprogramname))
    else
        ccall(fp(:Py_SetProgramName), Cvoid, (Ptr{Cwchar_t},),
              _leak(Cwstring, pyprogramname))
    end
    ccall(fp(:Py_InitializeEx), Cvoid, (Cint,), 0)
end

end  # module