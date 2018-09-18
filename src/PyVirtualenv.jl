module PyVirtualenv

using Base: PkgId, UUID
using Libdl

const _pycall_deps_jl = Ref{Module}()

""" Get path to `PyCall/deps/deps.jl` """
function pycall_deps_jl_path()
    modpath = Base.locate_package(Base.identify_package("PyCall"))
    if modpath === nothing
        error("PyCall not found")
    end
    @debug "PyCall.jl found at: $modpath"
    return joinpath(dirname(modpath), "..", "deps", "deps.jl")
end
# e.g., ~/.julia/dev/PyCall/deps/deps.jl

""" Load `PyCall/deps/deps.jl` namespace. """
function pycall_deps_jl()
    if isdefined(_pycall_deps_jl, 1)
        return _pycall_deps_jl[]
    end
    mod = Module(:__PyCall_deps__)
    Base.include(mod, pycall_deps_jl_path())
    _pycall_deps_jl[] = mod
    @debug "PyCall/deps/deps.jl:\n$(sprint(show_deps_jl, mod))"
    return mod
end

function show_deps_jl(io, mod)
    for name in sort(names(mod; all=true))
        val = try
            getproperty(mod, name)
        catch
            continue
        end
        if val isa Union{String, Bool}
            println(name, " =\t", val)
        end
    end
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
        sys.stdout.write(sys.exec_prefix)
        """
        # [[~/.julia/dev/PyCall/deps/build.jl::PYTHONHOME]]
    else
        script = """
        import sys
        sys.stdout.write(sys.prefix)
        sys.stdout.write(":")
        sys.stdout.write(sys.exec_prefix)
        """
        # https://docs.python.org/3/using/cmdline.html#envvar-PYTHONHOME
    end
    cmd = `$pyprogramname -c $script`
    @debug "Trying to find out PYTHONHOME." cmd

    # For Windows:
    env = copy(ENV)
    env["PYTHONIOENCODING"] = "UTF-8"
    cmd = setenv(cmd, env)

    return read(cmd, String)
end

function libpython_handle()
    libpython = pycall_deps_jl().libpython
    return Libdl.dlopen(libpython,
                        Libdl.RTLD_LAZY|Libdl.RTLD_DEEPBIND|Libdl.RTLD_GLOBAL)
end

function Py_IsInitialized(handle = libpython_handle())
    return ccall(Libdl.dlsym(handle, :Py_IsInitialized), Cint, ()) != 0
end

"""
    activate(pyprogramname::String, [PYTHONHOME::String])

Activate virtual environment of Python program at `pyprogramname`; it MUST
be compatible with the Python program configured for PyCall.jl.
"""
function activate(pyprogramname::AbstractString,
                  PYTHONHOME::AbstractString = pythonhome_of(pyprogramname))
    handle = libpython_handle()

    fp(f::Symbol) = Libdl.dlsym(handle, f)

    already_inited = Py_IsInitialized(handle)
    if already_inited
        error("Re-activation not supported.")
    end

    is_py2 = pycall_deps_jl().pyversion_build.major < 3

    @debug "Py_SetPythonHome($PYTHONHOME)"
    if is_py2
        ccall(fp(:Py_SetPythonHome), Cvoid, (Cstring,),
              _leak(Cstring, PYTHONHOME))
    else
        ccall(fp(:Py_SetPythonHome), Cvoid, (Ptr{Cwchar_t},),
              _leak(Cwstring, PYTHONHOME))
    end

    @debug "Py_SetProgramName($pyprogramname)"
    if is_py2
        ccall(fp(:Py_SetProgramName), Cvoid, (Cstring,),
              _leak(Cstring, pyprogramname))
    else
        ccall(fp(:Py_SetProgramName), Cvoid, (Ptr{Cwchar_t},),
              _leak(Cwstring, pyprogramname))
    end

    @debug "Py_InitializeEx()"
    ccall(fp(:Py_InitializeEx), Cvoid, (Cint,), 0)
end

function pipenv_python(path::AbstractString)
    dir = isdir(path) ? path : dirname(path)
    return rstrip(read(setenv(`pipenv --py`; dir=dir), String))
end

"""
    activate_pipenv([path::String = pwd()])
    activate_pipenv(module::Module)
    activate_pipenv(package::Symbol)

**WARNING**  Same restriction as `activate` applies here.

# Examples
```
julia> PyVirtualenv.activate_pipenv("PATH/TO/PROJECT/Pipfile")
julia> PyVirtualenv.activate_pipenv("PATH/TO/PROJECT/")  # equivalent
```

If you have `Pipfile` in the same directory as in `Project.toml`, you can
pass the module object to this function:

```
julia> using MyModule
julia> PyVirtualenv.activate_pipenv(MyModule)
```

However, if you use `PyCall` inside `MyModule`, above call to `activate_pipenv`
is too late.  One way of working around this problem is:

```
module MyModule

using PyVirtualenv

function __init__()
    PyVirtualenv.activate_pipenv(@__MODULE__)
    @eval using PyCall
end

end
```

Another way is to manually run `activate_pipenv(:MyModule)` (note that the
argument is a `Symbol`) before importing `MyModule`.

```
julia> PyVirtualenv.activate_pipenv(:MyModule)
julia> using MyModule
```
"""
function activate_pipenv(path::AbstractString = pwd())
    activate(pipenv_python(path))
end

activate_pipenv(m::Union{Module, Symbol}) = activate_pipenv(_pathof(m))

function _pathof(m)
    path = __pathof(m)
    if path === nothing
        error("Cannot find the path of module $m.")
    end
    return path
end

__pathof(m::Module) = pathof(m)
__pathof(m::Symbol) = Base.find_package(string(m))

const pycall_pkgid =
    PkgId(UUID("438e738f-606a-5dbb-bf0a-cddfbfd45ab0"), "PyCall")

function load_pycall()
    if !haskey(Base.loaded_modules, pycall_pkgid)
        error("PyCall not loaded.")
    end
    return Base.loaded_modules[pycall_pkgid]
end

"""
    pyexecfile(path, globals, [locals])

Works like Python 2 `execfile` except that `globals` is always required.
"""
pyexecfile(path::AbstractString, args...) =
    _pyexecfile(load_pycall(), path, args...)

function _pyexecfile(PyCall, path::AbstractString,
                     globals::AbstractDict,
                     locals::AbstractDict = globals)
    globals = convert(PyCall.PyDict, globals)
    locals = convert(PyCall.PyDict, locals)
    if PyCall.pyversion.major < 3
        PyCall.pybuiltin("execfile")(path, globals, locals)
    else
        src = read(path, String)
        code = PyCall.pybuiltin("compile")(src, path, "exec")
        PyCall.pybuiltin("exec")(code, globals, locals)
    end
end

"""
    activate_this(activate_this_py::String)

See:
https://virtualenv.pypa.io/en/stable/userguide/#using-virtualenv-without-bin-python

# Examples
```
julia> PyVirtualenv.activate_this("VIRTUAL_ENV/bin/activate_this.py")
```
"""
function activate_this(activate_this_py::AbstractString)
    pyexecfile(activate_this_py, Dict("__file__" => activate_this_py))
    return nothing
end

end  # module
