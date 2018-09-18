# PyVirtualenv

[![Build Status][travis-img]][travis-url]
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
[coveralls-img]: https://coveralls.io/repos/tkf/PyVirtualenv.jl/badge.svg?branch=master&service=github
[coveralls-url]: https://coveralls.io/github/tkf/PyVirtualenv.jl?branch=master
[codecov-img]: http://codecov.io/github/tkf/PyVirtualenv.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/tkf/PyVirtualenv.jl?branch=master
