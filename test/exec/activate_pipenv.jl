using Pkg
using Test

mkdir("workspace")
cd("workspace")
isempty(readdir()) || error("workspace not empty")

# Put Pipenv under the current directory.
ENV["PIPENV_VENV_IN_PROJECT"] = "true"
# See: https://pipenv.readthedocs.io/en/latest/advanced/#pipenv.environments.PIPENV_VENV_IN_PROJECT

# Setup Python packages
write("Pipfile", """
[[source]]
url = "https://pypi.org/simple"
verify_ssl = true
name = "pypi"

[packages]

[dev-packages]
""")

run(`pipenv install`)

# Setup Julia packages
write("Project.toml", """
[deps]
PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
""")

Pkg.activate(".")
Pkg.add(PackageSpec(url=ENV["PYVIRTUALENV_JL_TEST_TARGET"]))


@debug "Importing PyVirtualenv..."
import PyVirtualenv
PyVirtualenv.activate_pipenv()

@debug "Importing PyCall..."
using PyCall

sys = pyimport("sys")
@testset for key in [:executable, :prefix, :exec_prefix]
    # Note that this works because PIPENV_VENV_IN_PROJECT is set.
    @test startswith(sys[key], pwd())
end

# Cleaning up. Not required, but handy when it's manually invoked:
cd("..")
rm("workspace"; force=true, recursive=true)
