
macro odbc(func,args,vals...)
    if is_windows()
        esc(quote
            ret = ccall( ($func, odbc_dm), stdcall, SQLRETURN, $args, $(vals...))
        end)
    else
        esc(quote
            ret = ccall( ($func, odbc_dm),          SQLRETURN, $args, $(vals...))
        end)
    end
end


macro check(handle, func)
    str = string(func)
    esc(quote
        ret = $func
        if ret ∉ [SQL_SUCCESS, SQL_SUCCESS_WITH_INFO] && ODBCError($handle)
            throw(ODBCError("$str failed; return code: $ret => $(RETURN_VALUES[ret])"))
        end
        nothing
    end)
end

