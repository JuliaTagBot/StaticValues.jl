module StaticValues

import Base: TwicePrecision, promote_rule
import Base: ==, +, -, *, /, ^, <, ~, :, abs, abs2, isless, max, min, div, rem
import Base: eltype, values, log10, isfinite, zero, iszero

export SInt128, SInt16, SInt32, SInt64, SInt, SInt8,
       SUInt128, SUInt64, SUInt, SUInt32, SUInt16, SUInt8,
       SFloat16, SFloat32, SFloat64,
       SSigned, SUnsigned, SInteger, SFloat, SReal,
       SVal

include("int.jl")
include("float.jl")
include("promote.jl")
include("functions.jl")

end
