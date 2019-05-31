seek_static_val(::Type{T}, val::Val) where T =
    error("elements of type $T are not currently supported")

SVal(val::SVal) = val

for (ST,BT) in zip(static_real, base_real)

    @eval begin
        Base.@pure Base.values(::$ST{V}) where V = V::$BT
        Base.@pure Base.values(::Type{$ST{V}}) where V = V::$BT

        Base.eltype(::$ST) = $BT
        Base.eltype(::Type{<:$ST}) = $BT
        Base.log10(::$ST{V}) where V = $ST{log(V::$BT)/log(10)}()
        Base.isfinite(::$ST{V}) where V = isfinite(V::$BT)
        Base.iszero(::$ST{V}) where V = iszero(V::$BT)

        Base.zero(::$ST) = $ST{zero($BT)}()
        Base.zero(::Type{<:$ST}) = $ST{zero($BT)}()

        Base.one(::$ST) = $ST{one($BT)}()
        Base.one(::Type{<:$ST}) = $ST{one($BT)}()

        Base.fma(::$ST{X}, ::$ST{Y}, ::$ST{Z}) where {X,Y,Z} =
            SVal(fma(X::$BT, Y::$BT, Z::$BT))

        Base.muladd(::$ST{X}, ::$ST{Y}, ::$ST{Z}) where {X,Y,Z} =
            SVal(muladd(X::$BT, Y::$BT, Z::$BT))

        Base.div(::$ST{X}, ::$ST{Y}) where {X,Y} = $ST{div(X::$BT, Y::$BT)}()

        Base.fld(::$ST{X}, ::$ST{Y}) where {X,Y} = $ST{fld(X::$BT, Y::$BT)}()

        Base.cld(::$ST{X}, ::$ST{Y}) where {X,Y} = $ST{cld(X::$BT, Y::$BT)}()

        Base.rem(::$ST{X}, ::$ST{Y}) where {X,Y} = $ST{rem(X::$BT, Y::$BT)}()

        Base.max(x::$ST{X}, y::$ST{Y}) where {X,Y} = X::$BT > Y::$BT ? x : y

        Base.min(x::$ST{X}, y::$ST{Y}) where {X,Y} = X::$BT > Y::$BT ? y : x

        Base.minmax(x::$ST{X}, y::$ST{Y}) where {X,Y} = X::$BT > Y::$BT ? (y, x) : (x, y)

        (*)(::$ST{V1}, ::$ST{V2}) where {V1,V2} = $ST{(*)(V1::$BT, V2::$BT)}()
        (+)(::$ST{V1}, ::$ST{V2}) where {V1,V2} = $ST{(+)(V1::$BT, V2::$BT)}()
        (-)(::$ST{V1}, ::$ST{V2}) where {V1,V2} = $ST{(-)(V1::$BT, V2::$BT)}()
        (-)(::$ST{V}) where V = $ST{-V::$BT}()


        # TODO: figure out return type inference for these (if possible)
        (\)(::$ST{V1}, ::$ST{V2}) where {V1,V2} = SVal((\)(V1::$BT, V2::$BT))
        (^)(::$ST{V1}, ::$ST{V2}) where {V1,V2} = SVal((^)(V1::$BT, V2::$BT))
        Base.mod(::$ST{X}, ::$ST{Y}) where {X,Y} = SVal(mod(X::$BT, Y::$BT))
        Base.mod1(::$ST{X}, ::$ST{Y}) where {X,Y} = SVal(mod1(X::$BT, Y::$BT))
        Base.fld1(::$ST{X}, ::$ST{Y}) where {X,Y} = SVal(fld1(X::$BT, Y::$BT))

        function add12(x::$ST, y::$ST)
            x, y = ifelse(abs(y) > abs(x), (y, x), (x, y))
            Base.canonicalize2(x, y)
        end

        (::Type{<:$ST})(val::Val{V}) where V = convert_static_val($BT, typeof(V), val)

        sone(::$ST) = $ST{one($BT)}()
        sone(::Type{<:$ST}) = $ST{one($BT)}()

        sone(::$BT) = $ST{one($BT)}()
        sone(::Type{$BT}) = $ST{one($BT)}()

        szero(::$ST) = $ST{zero($BT)}()
        szero(::Type{<:$ST}) = $ST{zero($BT)}()

        szero(::$BT) = $ST{zero($BT)}()
        szero(::Type{$BT}) = $ST{zero($BT)}()
    end

    # f(static) --> Bool
    for f in (:(==), :<, :(<=), :>, :(>=), :(!=), :isless)
        @eval begin
            $f(::$ST{V1}, ::$ST{V2}) where {V1,V2} = $f(V1::$BT, V2::$BT)
        end
    end

    # f(static, static) --> static
    for (ST2,BT2) in zip(static_real, base_real)
        if BT == BT2
            @eval begin
                (::Type{<:$ST{<:Any}})(val::$ST2) = val
                (::Type{<:$ST{<:Any}})(val::$BT2) = $ST{val}()

                Base.promote_rule(::Type{<:$ST}, ::Type{$BT2}) = $BT
                Base.flipsign(::$ST{V1}, ::$ST2{V2}) where {V1,V2} = flipsign(V1::$BT,V2::$BT2)


                # converts to the element type but does not change from static/non-static type
                ofeltype(::Type{$BT}, val::$ST) = val
                ofeltype(::Type{$BT}, val::$BT) = val
                ofeltype(::$BT, val::$ST) = val
                ofeltype(::$BT, val::$BT) = val

                ofeltype(::Type{<:$ST}, val::$ST) = val
                ofeltype(::Type{<:$ST}, val::$BT) = val
                ofeltype(::$ST, val::$ST) = val
                ofeltype(::$ST, val::$BT) = val

                (::Type{$BT2})(::$ST{V}) where V = V::$BT
            end
        else
            @eval begin
                ofeltype(::Type{$BT}, val::$ST2{V}) where V = $ST{$BT(V::$BT2)}()
                ofeltype(::Type{$BT}, val::$BT2) = $BT(val)
                ofeltype(::$BT, val::$ST2{V}) where V = $ST{$BT(V::$BT2)}()
                ofeltype(::$BT, val::$BT2) = $BT(val)

                ofeltype(::Type{$ST}, val::$ST2{V}) where V = $ST{$BT(V::$BT2)}()
                ofeltype(::Type{$ST}, val::$BT2) = $BT(val)
                ofeltype(::$ST, val::$ST2{V}) where V = $ST{$BT(V::$BT2)}()
                ofeltype(::$ST, val::$BT2) = $BT(val)

                (::Type{<:$ST{<:Any}})(::$ST2{V}) where V = $ST{$BT(V::$BT2)}()
                (::Type{<:$ST{<:Any}})(val::$BT2) = $ST{$BT(val)}()

                Base.promote_rule(::Type{<:$ST}, ::Type{$BT2}) = promote_type($BT, $BT2)
                Base.flipsign(::$ST{V1}, ::$ST2{V2}) where {V1,V2} = flipsign(V1::$BT,V2::$BT2)


                (::Type{$BT2})(::$ST{V}) where V = $BT2(V::$BT)

                # Given Val of different type convert to SVal
            end
        end
    end

    # only iterate over <:Integer
    for (ST2,BT2) in zip(static_integer, base_integer)
        @eval begin
            Base.round(::Type{$BT2}, ::$ST{V}) where V = $ST2{round($BT2, V::$BT)}()
        end
    end
end


for (ST,BT) in zip(static_integer, base_integer)
    @eval begin
        (/)(::$ST{V1}, ::$ST{V2}) where {V1,V2} = SFloat64{(/)(V1::$BT, V2::$BT)}()
    end
end
Base.promote_eltype(x::SVal, y::BaseNumber) = promote_type(eltype(x), eltype(y))
Base.promote_eltype(x::BaseNumber, y::SVal) = promote_type(eltype(x), eltype(y))
Base.promote_eltype(x::SVal, y::SVal) = promote_type(eltype(x), eltype(y))

Base.promote_eltype(x::Type{<:SVal}, y::Type{<:SVal}) = promote_type(eltype(x), eltype(y))

promote_toeltype(x, y) = promote_toeltype(promote_eltype(x, y), x, y)
promote_toeltype(::Type{T}, x, y) where T = ofeltype(T, x), ofeltype(T, y)

Base.trunc(::Type{T}, x::SVal) where T = SVal(trunc(T, values(x)))
