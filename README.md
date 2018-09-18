# PyVirtualenv

[![Travis Status][travis-img]][travis-url]
[![AppVeyor Status][appveyor-img]][appveyor-url]
[![Coverage Status][coveralls-img]][coveralls-url]
[![codecov.io][codecov-img]][codecov-url]

## Usage

```julia
julia> using PyVirtualenv
julia> PyVirtualenv.activate("PATH/TO/bin/python")
julia> using PyCall
```


[travis-img]: https://travis-ci.org/tkf/PyVirtualenv.jl.svg?branch=master
[travis-url]: https://travis-ci.org/tkf/PyVirtualenv.jl
[appveyor-img]: https://ci.appveyor.com/api/projects/status/ju6capo97ao6wgjn/branch/master?svg=true
[appveyor-url]: https://ci.appveyor.com/project/tkf/pyvirtualenv-jl/branch/master
[coveralls-img]: https://coveralls.io/repos/tkf/PyVirtualenv.jl/badge.svg?branch=master&service=github
[coveralls-url]: https://coveralls.io/github/tkf/PyVirtualenv.jl?branch=master
[codecov-img]: http://codecov.io/github/tkf/PyVirtualenv.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/tkf/PyVirtualenv.jl?branch=master
