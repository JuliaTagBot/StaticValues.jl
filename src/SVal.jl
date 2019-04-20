struct SNothing{nothing,Nothing}
    SNothing() = SNothing{nothing,Nothing}()
end

struct SChar{V,T<:AbstractChar} <: AbstractChar
    SChar{V} = 
end

const SVal{V,T} = Union{SInteger{V,T},SFloat{V,T}}

struct SVal{V,T} <: StaticValue{T}
    function SVal{V,T}() where {V,T}
        !(typeof(V) === T) && throw(ArgumentError("val must be of type T"))
        new{V,T}()
    end
end
SVal(val::T) where T = SVal{val,T}()
SVal{V}() where {V} = SVal{V,typeof(V)}()
SVal(::Val{V}) where {V} = SVal{V}()
SVal(::Type{SVal{V,T}}) where {V,T}  = SVal{V,T}()
SVal(::SVal{V}) where {V} = SVal{V}()


(::Type{T})(x::SVal{V,T2}) where {T<:Number,T2,V} = T(V)::T
(::Type{SVal{<:Any,T1}})(x::SVal{V,T2}) where {T1,V,T2} = SVal{T1(V),T1}()
(::Type{SVal{<:Any,T}})(x::SVal{V,T}) where {T,V} = x


const SReal{V} = SVal{V,<:Real}

const SBigFloat{V} = SVal{V,BigFloat}
const SBigInt{V} = SVal{V,BigInt}

const SNothing = SVal{nothing,Nothing}

const SOne = SVal{1,Int}()
SOne(::Type{T}) where T = SVal{T(1),T}()
SOne(::SVal{V,T}) where {V,T} = SVal{T(1),T}()
SOne(::Type{SVal{V,T}}) where {V,T} = SVal{T(1),T}()
SOne(x::T) where T = SVal{T(1),T}()

const SZero = SVal{0,Int}()
SZero(::Type{T}) where T = SVal{T(0),T}()
SZero(::SVal{V,T}) where {V,T} = SVal{T(0),T}()
SZero(::Type{SVal{V,T}}) where {V,T} = SVal{T(0),T}()
SZero(x::T) where T = SVal{T(0),T}()

Base.length(::SVal{V,T}) where {V,T} = length(V)

Base.iterate(v::SVal) = (v, nothing)
Base.iterate(v::SVal, ::Nothing) = nothing


Base.big(::SVal{V,T}) where {V,T} = SVal{big(V)}()
Base.float(::SVal{V,T}) where {V,T} = SVal{float(V)}()

Base.oftype(x::T, ::SVal{V}) where {T,V} = SVal{T(V),T}()

function Base.promote(::SVal{V1,T1}, ::SVal{V2,T2}) where {V1,T1,V2,T2}
    T3 = promote_type(T1,T2)
    SVal{T3(V1),T3}(), SVal{T3(V2),T3}()
end

function Base.promote(::SVal{V1,T1}, ::SVal{V2,T2}, ::SVal{V3,T3}) where {V1,T1,V2,T2,V3,T3}
    T4 = promote_type(T1,T2,T3)
    SVal{T4(V1),T4}(), SVal{T4(V2),T4}(), SVal{T4(V3),T4}()
end


@pure Base.get(::SVal{V,T}) where {V,T} = V::T
@pure Base.get(::Type{<:SVal{V,T}}) where {V,T} = V::T

@pure Base.eltype(::SVal{V,T}) where {V,T} = T
@pure Base.eltype(::Type{<:SVal{V,T}}) where {V,T} = T

Base.convert(::Type{SVal{V,T}}, x) where {V,T} = SVal{oftype(V, x),T}()
Base.convert(::Type{SVal{V,T}}, ::SVal{V2,T2}) where {V,T,V2,T2} = SVal{T(V2),T}()
Base.convert(::Type{T}, x::SVal{V,T}) where {V,T} = V
Base.convert(::Type{T1}, x::SVal{V,T2}) where {V,T1,T2} = T2(V)



#=
for f in (:*, :^, :\, :div)
    @eval begin
        @inline function ($f)(::SVal{V,T}, x::Real) where {V,T}
            vnew = $f(V, x)
            SVal{vnew,typeof(vnew)}()
        end
        @inline function ($f)(x::Real, ::SVal{V,T}) where {V,T}
            vnew = $f(x, V)
            SVal{vnew,typeof(vnew)}()
        end

        @inline function ($f)(::SVal{V1,T1}, ::SVal{V2,T2}) where {V1,T1,V2,T2}
            vnew = $f(V1, V2)
            SVal{vnew,typeof(vnew)}()
        end
    end
end
=#


# bool
for f in (:(==), :<, :isless)
    @eval begin
        @inline function $f(::SVal{V,T}, x::Real) where {V,T}
            $(f)(V, x)
        end

        @inline function $f(x::Real, ::SVal{V,T}) where {V,T}
            $(f)(x, V)
        end

        @pure function $f(::SVal{V1,T1}, ::SVal{V2,T2}) where {V1,T1,V2,T2}
            $(f)(V1, V2)
        end
    end
end

Base.max(r::SVal{V,T}, x::Real) where {V,T} = max(V, r)
Base.max(x::Real, r::SVal{V,T}) where {V,T} = ifelse(x > V, x, r)
Base.max(x1::SVal{V1,T1}, x2::SVal{V2,T2}) where {V1,T1,V2,T2} = V1 < V2 ? x2 : x1


Base.min(r::SVal{V,T}, x::Real) where {V,T} = min(x, r)
Base.min(x::Real, r::SVal{V,T}) where {V,T} = ifelse(x > V, x, r)
Base.min(x1::SVal{V1,T1}, x2::SVal{V2,T2}) where {V1,T1,V2,T2} = V1 < V2 ? x1 : x2

+(::SVal{V,T}, y::Number) where {V,T} = SVal{V+y}()
+(x::Number, y::SVal) = y+x

+(x::SVal{V1,T}, y::SVal{V2,T}) where {V1,V2,T} = SVal{V1+V2}()
+(x::SVal{V1,T1}, y::SVal{V2,T2}) where {V1,V2,T1,T2} = +(promote(x, y)...)

+(x::SVal{V1,Char}, y::SVal{V2,<:Number}) where {V1,V2} = SVal{V1+V2}()
+(y::SVal{V2,<:Number}, x::SVal{V1,Char}) where {V1,V2} = SVal{V1+V2}()


# fallback
+(x::SVal{V,T}, y) where {V,T} = SVal{V + y}()
+(x, y::SVal{V,T}) where {V,T} = SVal{V + x}()



-(x::SVal{V,T}) where {V,T} = SVal{-V,T}()

-(x::SVal{V1,T1}, y::SVal{V2,T2}) where {V1,T1,V2,T2}= SVal{V1 - V2}()
-(x::Number, y::SVal) = x + (-y)
-(x::SVal, y::Number) = x + (-y)

*(x::SVal{V,T}, v::Number) where {V,T} = SVal{V*v}()
*(v::Number, x::SVal) = x*v
*(x::SVal{V1,T1}, y::SVal{V2,T2}) where {V1,V2,T1,T2} = *(promote(x, y)...)
*(x::SVal{V1,T}, y::SVal{V2,T}) where {V1,V2,T} = SVal{V1*V2}()

/(x::SVal{V,T}, v::Number) where {V,T} = x / SVal(oftype(V/v, v))
/(v::Number, x::SVal{V,T}) where {V,T} = SVal(oftype(V/v, v)) / x
/(x::SVal{V1,T1}, y::SVal{V2,T2}) where {V1,T1,V2,T2} = /(promote(x, y)...)
/(x::SVal{V1,T}, y::SVal{V2,T}) where {V1,V2,T} = SVal{V1/V2}()

copy(::SVal{V,T}) where {V,T} = SVal{V,T}()

abs(::SVal{V,T}) where {V,T}= SVal{abs(V)}()
abs2(::SVal{V,T}) where {V,T} = SVal{abs2(V),T}()

Base.ceil(::SVal{V,T}) where {V,T} = SVal{ceil(V)}()
Base.ceil(::Type{T}, ::SVal{V}) where {V,T} = SVal{ceil(T, V)}()

Base.floor(::SVal{V,T}) where {V,T} = SVal{floor(V)}()
Base.floor(::Type{T}, ::SVal{V}) where {V,T} = SVal{floor(T, V)}()




const BASE2 = log(2)
const BASE10 = log(10)
@generated function Base.log(::SVal{V,T}) where {V,T}
    x = log(V)
    :(SVal{$x}())
end

# version from base erros on @code_inference
@generated function Base.log2(::SVal{V,T}) where {V,T}
    x = log2(V)
    :(SVal{$x}())
end
Base.log10(::SVal{V,T}) where {V,T} = SVal{log(V) / BASE10}()
Base.log1p(::SVal{V,T}) where {V,T} = SVal{logp(V)}()

Base.rem(::SVal{V1,T1}, ::SVal{V2,T2}) where {V1,T1,V2,T2} = SVal{rem(V1::T1,V2::T2)}()
Base.rem(::SVal{V,T1}, x::T2) where {V,T1,T2} = SVal{rem(V::T1,x)}()
Base.rem(x::T1, ::SVal{V,T2}) where {V,T1,T2} = SVal{rem(x,V::T2)}()

function Base.clamp(::SVal{x,X}, ::SVal{lo,L}, ::SVal{hi,H}) where {x,X,lo,L,hi,H}
    if x > hi
        out  = Base.convert(promote_type(X,L,H), hi)
    elseif x < lo
        out = Base.convert(promote_type(X,L,H), lo)
    else
        out = Base.convert(promote_type(X,L,H), x)
    end
    SVal{out}()
end

Base.round(::Type{T}, ::SVal{V}) where {T,V} = SVal{round(T, V)}()

Base.isfinite(::SVal{V,T}) where {V,T} = isfinite(V)
Base.zero(::SVal{V,T}) where {V,T} = SVal{zero(V)}()
Base.iszero(::SVal{V,T}) where {V,T} = iszero(V)


Base.show(io::IO, r::SVal) = showsval(io, r)
Base.show(io::IO, ::MIME"text/plain", r::SVal) = showsval(io, r)

showsval(io::IO, r::SVal{V,T}) where {V,T} = print(io, "$V\t(static)")
showsval(io::IO, r::SNothing) where {V,T} = print(io, "SVal(nothing)")


Base.div(::SVal{A,T1}, ::SVal{B,T2}) where {A,T1,B,T2} = SVal{div(A,B)}()
Base.div(::SVal{A,T1}, b::T2) where {A,T1,T2} = SVal{div(A,b)}()
Base.div(a::T1, ::SVal{B,T2}) where {T1,B,T2} = SVal{div(a,B)}()

#Base.oneunit(::SVal{V,T}) where {V,T} = SVal{T(1)}()
Base.one(::SVal{V,T}) where {V,T} = SVal{T(1)}()

Base.one(::Type{SVal{V,T}}) where {V,T} = SVal{T(1)}()

Base.oneunit(::SVal{V,T}) where {V,T} = SVal{T(1)}()
Base.oneunit(::Type{SVal{V,T}}) where {V,T} = SVal{T(1)}()

Base.gcd(a::SVal{A,<:Integer}, b::SVal{B,<:Integer}) where {A,B} = gcd(promote(a,b)...)
function Base.gcd(a::SVal{A,T}, b::SVal{B,T}) where {A,B,T<:Integer}
    r = rem(a, b)
    if r == 0
        return b
    else
        return gcd(b, r)
    end
end

@inline function Base.gcdx(a::SVal{A,T}, b::SVal{B,T}) where {T<:Integer,A,B}
    # a0, b0 = a, b
    s0, s1 = oneunit(a), zero(a)
    t0, t1 = s1, s0
    _gcdx(a, b, s0, s1, t0, t1)
end

Base.gcdx(a::SInteger, b::SInteger) = gcdx(promote(a, b)...)

@inline function _gcdx(
    a::SVal{A,T}, b::SVal{B,T},
    s0::SVal{S0,T}, s1::SVal{S1,T},
    x0::SVal{X0,T}, x1::SVal{X1,T}
    ) where {A,B,S0,S1,X0,X1,T}
    z = SVal{T(0),T}()
    q = div(a, b)
    anew, bnew = b, rem(a, b)
    s0new, s1new = s1, s0 - q*s1
    x0new, x1new = x1, x0 - q*x1
    if bnew == z
        return a < z ? (-anew, -s0new, -x0new) : (anew, s0new, x0new)
    else
        _gcdx(anew, bnew, s0new, s1new, x0new, x1new)
    end
end


Base.lcm(a::SVal{A,<:Integer}, b::SVal{B,<:Integer}) where {A,B} = lcm(promote(a,b)...)
function Base.lcm(a::SVal{A,T}, b::SVal{B,T}) where {A,B,T<:Integer}
    # explicit a==0 test is to handle case of lcm(0,0) correctly
    if a == SVal{T(0),T}()
        return a
    else
        return abs(a * div(b, gcd(b,a)))
    end
end

function Base.cld(x::SVal{X,T}, y::SVal{Y,T}) where {X,Y,T<:Unsigned}
    d = div(x, y)
    return d + (d * y != x)
end

function Base.cld(x::SVal{X,T}, y::SVal{Y,T}) where {X,Y,T<:Integer}
    d = div(x, y)
    return d + (((x > 0) == (y > 0)) & (d * y != x))
end

unsigned(::SVal{V,T}) where {V,T} = SVal{Base.unsigned(V::T)}()

#=

x = SVal(3)
y = SVal(4)
z = SVal(1)
@inferred(fma(x,y,z))
=#
Base.fma(::SVal{x}, ::SVal{y}, ::SVal{z}) where {x,y,z} = SVal{fma(x, y,z)}()

Base.precision(x::SVal{X,T}) where {X,T<:AbstractFloat} = SVal{precision(T)}()

Base.mod(::SVal{X,T}, ::SVal{Y,T}) where {X,Y,T} = SVal{mod(X,Y)}()