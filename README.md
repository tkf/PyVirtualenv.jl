# PyVirtualenv

[![Travis Status][travis-img]][travis-url]
[![AppVeyor Status][appveyor-img]][appveyor-url]
[![Coverage Status][coveralls-img]][coveralls-url]
[![codecov.io][codecov-img]][codecov-url]

## Usage

### Activate a Python virtualenv in Julia REPL

```julia
julia> using PyVirtualenv
julia> PyVirtualenv.activate("PATH/TO/bin/python")
julia> using PyCall
```

### Activate a Python virtualenv via [Pipenv]

[Pipenv]: https://pipenv.readthedocs.io/en/latest/

```julia
julia> using PyVirtualenv
julia> PyVirtualenv.activate_pipenv("PATH/TO/Pipfile")
julia> using PyCall
```

### Automate environment activation

In the directory `$PROJECT` where `Project.toml` and `Pipfile` exist,
create a file called `activate.jl` with:

```julia
import Pkg
Pkg.activate(@__DIR__)
import PyVirtualenv
PyVirtualenv.activate_pipenv(@__DIR__)
```

Then you can start a Julia REPL with Julia and Python environments
activated together by:

```console
$ cd $PROJECT
$ julia -i activate.jl
```

To run a Julia script with all Julia and Python dependencies of `$PROJECT`,
run

```julia
include("$PROJECT/activate.jl")
```

in the very beginning of the script.

Note that `pkg> instantiate` and `shell> pipenv install` still have to
be run manually when using the project for the first time.


[travis-img]: https://travis-ci.org/tkf/PyVirtualenv.jl.svg?branch=master
[travis-url]: https://travis-ci.org/tkf/PyVirtualenv.jl
[appveyor-img]: https://ci.appveyor.com/api/projects/status/ju6capo97ao6wgjn/branch/master?svg=true
[appveyor-url]: https://ci.appveyor.com/project/tkf/pyvirtualenv-jl/branch/master
[coveralls-img]: https://coveralls.io/repos/tkf/PyVirtualenv.jl/badge.svg?branch=master&service=github
[coveralls-url]: https://coveralls.io/github/tkf/PyVirtualenv.jl?branch=master
[codecov-img]: http://codecov.io/github/tkf/PyVirtualenv.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/tkf/PyVirtualenv.jl?branch=master
