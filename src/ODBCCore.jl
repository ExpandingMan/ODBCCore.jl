module ODBCCore

using NullableArrays
using WeakRefStrings
# this is the IEEE decimal floating-point package
using DecFP

include("constants.jl")
include("ctypes.jl")
include("wrapper.jl")
include("boilerplate.jl")
include("api.jl")

end # module
