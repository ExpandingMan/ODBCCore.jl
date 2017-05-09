#===================================================================================================
Some conventions:
    -All C data structs are wrapped in Julia data structs.
    -The lowest level functions should always be exposed.
    -In C functions where output is passed as an argument, we instead return the output, doing
        standard error checking of the status.

TODO
    I've left a lot of these unfinished, want to see how they typically get used first.
===================================================================================================#



"""
ODBC API Function Definitions
By Jacob Quinn, 2016
In general, the ODBC functions are implemented to mirror the C header files (sql.h,sqlext.h,sqltypes.h,sqlucode.h)
A few liberties are taken in utliizing standard Julia functions and idioms
Format:
  * function name
  * URL reference
  * short function description
  * valid const definitions
  * relevant notes
  * working and tested status
  * function definition code

Contents
 * Macros and Utility Functions
 * Handle Functions
 * Connection Functions
 * Resultset Metadata Functions
 * Query Functions
 * Resultset Retrieval Functions
 * DBMS Meta Functions
 * Error Handling and Diagnostics
"""


# TODO these first few seem complicated
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms712400(v=vs.85).aspx"
function SQLDrivers(env::Ptr{Void},
                    dir,
                    driver_desc::Ptr{SQLWCHAR},
                    desclen,
                    desc_length::Ref{SQLSMALLINT},
                    driver_attr::Ptr{SQLWCHAR},
                    attrlen,
                    attr_length::Ref{SQLSMALLINT})
    @odbc(:SQLDriversW,
                (Ptr{Void}, SQLUSMALLINT, Ptr{SQLWCHAR}, SQLSMALLINT, Ref{SQLSMALLINT}, Ptr{SQLWCHAR},
                 SQLSMALLINT, Ref{SQLSMALLINT}),
                env, dir, driver_desc, desclen, desc_length, driver_attr, attrlen, attr_length)
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms711004(v=vs.85).aspx"
function SQLDataSources(env::Ptr{Void},
                        dir,
                        dsn_desc::Ptr{SQLWCHAR},
                        desclen,
                        desc_length::Ref{SQLSMALLINT},
                        dsn_attr::Ptr{SQLWCHAR},
                        attrlen,
                        attr_length::Ref{SQLSMALLINT})
    @odbc(:SQLDataSourcesW,
                (Ptr{Void}, SQLUSMALLINT, Ptr{SQLWCHAR}, SQLSMALLINT, Ref{SQLSMALLINT}, Ptr{SQLWCHAR},
                 SQLSMALLINT, Ref{SQLSMALLINT}),
                env, dir, dsn_desc, desclen, desc_length, dsn_attr, attrlen, attr_length)
end

#### Handle Functions ####

function SQLAllocHandle(handletype::SQLSMALLINT, parenthandle::Ptr{Void}, handle::Ref{Ptr{Void}})
    @odbc(:SQLAllocHandle,
                (SQLSMALLINT, Ptr{Void}, Ref{Ptr{Void}}),
                handletype, parenthandle, handle)
end
function SQLAllocHandle(parenthandle::AbstractSQLHandle)
    hdl = Ref{Ptr{Void}}()
    htype = handletype(parenthandle)
    @check parenthandle SQLAllocHandle(handletype(parenthandle), parenthandle.ptr, hdl)
    makehandle(parenthandle, hdl[])
end


"""
# SQLFreeHandle
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms710123(v=vs.85).aspx"

Frees resources associated with a specific environment, connection, statement, or descriptor handle
See SQLAllocHandle for valid handle types
"""
function SQLFreeHandle(handletype::SQLSMALLINT,handle::Ptr{Void})
    @odbc(:SQLFreeHandle,
                (SQLSMALLINT, Ptr{Void}),
                handletype, handle)
end
SQLFreeHandle(hdl::AbstractSQLHandle) = SQLFreeHandle(handletype(hdl), hdl.ptr)


function SQLSetEnvAttr{T<:Union{Int,UInt}}(env_handle::Ptr{Void}, attribute::Int, value::T)
    @odbc(:SQLSetEnvAttr,
                (Ptr{Void}, Int, T, Int), env_handle, attribute, value, 0)
end
function SQLSetEnvAttr{T<:Union{Int,UInt}}(env_handle::SQLEnvironement, attribute::Integer, value::T)
    SQLSetEnvAttr(env_handle.ptr, attribute, value)
end


"""
# SQLGetEnvAttr
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms709276(v=vs.85).aspx"

Returns the current setting of an environment attribute
"""
function SQLGetEnvAttr(env::Ptr{Void},attribute::Int,value::Array{Int,1},bytes_returned::Array{Int,1})
    @odbc(:SQLGetEnvAttr,
                (Ptr{Void}, Int, Ptr{Int}, Int, Ptr{Int}),
                env, attribute, value, 0, bytes_returned)
end
function SQLGetEnvAttr(env::SQLEnvironement, attribute::Int, val::Vector{Int},
                       bytes_returned::Vector{Int})
    SQLGetEnvAttr(env.ptr, attribute, val, bytes_returned)
end


"""
# SQLSetConnectAttr
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms713605(v=vs.85).aspx"

Sets attributes that govern aspects of connections.
length of string or binary stream
"""
function SQLSetConnectAttr(dbc::Ptr{Void},attribute::Int,value::UInt,value_length::Int)
    @odbc(:SQLSetConnectAttrW,
                (Ptr{Void},Int,UInt,Int),
                dbc,attribute,value,value_length)
end
function SQLSetConnectAttr(dbc::Ptr{Void},attribute::Int,value::Array{Int},value_length::Int)
    @odbc(:SQLSetConnectAttrW,
                (Ptr{Void},Int,Ptr{Int},Int),
                dbc,attribute,value,value_length)
end
function SQLSetConnectAttr(dbc::SQLConnection, attribute::Int, value::Array{Int}, value_length::Int)
    SQLSetConnectAttr(dbc.ptr, attribute, value, value_length)
end


"""
# SQLGetConnectAttr
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms710297(v=vs.85).aspx"

Returns the current setting of a connection attribute.
"""
function SQLGetConnectAttr{T,N}(dbc::Ptr{Void}, attribute::Int, value::Array{T,N},
                                bytes_returned::Vector{Int})
    @odbc(:SQLGetConnectAttrW,
                (Ptr{Void},Int,Ptr{T},Int,Ptr{Int}),
                dbc,attribute,value,sizeof(T)*N,bytes_returned)
end
function SQLGetConnectAttr{T,N}(dbc::SQLConnection, attribute::Int, val::Array{T,N},
                                bytes_returned::Vector{Int})
    SQLGetConnectAttr(dbc.ptr, attribute, val, bytes_returned)
end


"""
# SQLSetStmtAttr
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms712631(v=vs.85).aspx"

Sets attributes related to a statement.
**this sets the rowset size for ExtendedFetch and FetchScroll**
See SQLSetConnectAttr; SQL_IS_POINTER, SQL_IS_INTEGER, SQL_IS_UINTEGER, SQL_NTS
"""
function SQLSetStmtAttr(stmt::Ptr{Void}, attribute::Int, value::Ref{SQLLEN}, value_length::Int)
    @odbc(:SQLSetStmtAttrW,
                (Ptr{Void},SQLINTEGER,Ref{SQLLEN},SQLINTEGER),
                stmt,attribute,value,value_length)
end
function SQLSetStmtAttr(stmt::Ptr{Void}, attribute::Int, value::Int, value_length::Int)
    @odbc(:SQLSetStmtAttrW,
                (Ptr{Void},SQLINTEGER,SQLULEN,SQLINTEGER),
                stmt,attribute,value,value_length)
end
function SQLSetStmtAttr(stmt::SQLStatement, attribute::Int, value::Union{Ref{SQLLEN},Int},
                        value_length::Int)
    SQLSetStmtAttr(stmt.ptr, attribute, value, value_length)
end


"""
# SQLGetStmtAttr

http://msdn.microsoft.com/en-us/library/windows/desktop/ms715438(v=vs.85).aspx
"""
function SQLGetStmtAttr{T,N}(stmt::Ptr{Void}, attribute::Int, value::Array{T,N},
                             bytes_returned::Vector{Int})
    @odbc(:SQLGetStmtAttrW,
                (Ptr{Void},Int,Ptr{T},Int,Ptr{Int}),
                stmt,attribute,value,sizeof(T)*N,bytes_returned)
end
function SQLGetStmtAttr{T,N}(stmt::SQLStatement, attribute::Int, value::Array{T,N},
                             bytes_returned::Vector{Int})
    SQLGetStmtAttr(stmt.ptr, attribute, value, bytes_returned)
end


"""
# SQLFreeStmt
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms709284(v=vs.85).aspx"

Sops processing associated with a specific statement,
closes any open cursors associated with the statement,
discards pending results, or, optionally,
frees all resources associated with the statement handle.
"""
function SQLFreeStmt(stmt::Ptr{Void},param::UInt16)
    @odbc(:SQLFreeStmt,
                (Ptr{Void},UInt16),
                stmt, param)
end
SQLFreeStmt(stmt::SQLStatement, param::UInt16) = SQLFreeStmt(stmt, param)


"""
# SQLSetDescField
http://msdn.microsoft.com/en-us/library/windows/desktop/ms713560(v=vs.85).aspx
"""
function SQLSetDescField{T,N}(desc::Ptr{Void}, i::Int16, field_id::Int16, value::Array{T,N},
                              value_length::Vector{Int})
    @odbc(:SQLSetDescFieldW,
                (Ptr{Void},Int16,Int16,Ptr{T},Int),
                desc,field_id,value,value_length)
end
function SQLSetDescField{T,N}(desc::SQLDescriptor, i::Int16, field_id::Int16, value::Array{T,N},
                              value_length::Vector{Int})
    SQLSetDescField(desc.ptr, i, field_id, value, value_length)
end


"""
# SQLGetDescField

http://msdn.microsoft.com/en-us/library/windows/desktop/ms716370(v=vs.85).aspx
"""
function SQLGetDescField{T,N}(desc::Ptr{Void}, i::Int16, attribute::Int16, value::Array{T,N},
                              bytes_returned::Array{Int,1})
    @odbc(:SQLGetDescFieldW,
                (Ptr{Void},Int16,Int16,Ptr{T},Int,Ptr{Int}),
                desc,attribute,value,sizeof(T)*N,bytes_returned)
end
function SQLGetDescField{T,N}(desc::SQLDescriptor, i::Int16, attribute::Int16, value::Array{T,N},
                              bytes_returned::Vector{Int})
    SQLGetDescField(desc.ptr, i, attribute, value, bytes_returned)
end


"""
# SQLGetDescRec

http://msdn.microsoft.com/en-us/library/windows/desktop/ms710921(v=vs.85).aspx
"""
function SQLGetDescRec(desc::Ptr{Void}, i::Int16, name::Vector{UInt8},
                       name_length::Vector{Int16}, type_ptr::Vector{Int16},
                       subtype_ptr::Vector{Int16}, length_ptr::Vector{Int},
                       precision_ptr::Vector{Int16}, scale_ptr::Vector{Int16},
                       nullable_ptr::Vector{Int16})
    @odbc(:SQLGetDescRecW,
                (Ptr{Void},Int16,Ptr{UInt8},Int16,Ptr{Int16},Ptr{Int16},Ptr{Int16},
                 Ptr{Int},Ptr{Int16},Ptr{Int16},Ptr{Int16}),
                desc,i,name,length(name),name_length,type_ptr,subtype_ptr,length_ptr,
                precision_ptr,scale_ptr,nullable_ptr)
end
function SQLGetDescRec(desc::SQLDescriptor, i::Int16, name::Vector{UInt8},
                       name_length::Vector{Int16}, type_ptr::Vector{Int16},
                       subtype_ptr::Vector{Int16}, length_ptr::Vector{Int},
                       precision_ptr::Vector{Int16}, scale_ptr::Vector{Int16},
                       nullable_ptr::Vector{Int16})
    SQLGetDescRec(desc.ptr, i, name, name_length, type_ptr, subtype_ptr, length_ptr,
                  precision_ptr, scale_ptr, nullable_ptr)
end


"""
# SQLCopyDesc

http://msdn.microsoft.com/en-us/library/windows/desktop/ms715378(v=vs.85).aspx
"""
function SQLCopyDesc(source_desc::Ptr{Void},dest_desc::Ptr{Void})
    @odbc(:SQLCopyDesc,
                (Ptr{Void},Ptr{Void}),
                source_desc,dest_desc)
end
function SQLCopyDesc(source_desc::SQLDescriptor, dest_desc::SQLDescriptor)
    SQLCopyDesc(source_desc.ptr, dest_desc.ptr)
end


### Connection Functions ###

"""
# SQLConnect
http://msdn.microsoft.com/en-us/library/windows/desktop/ms711810(v=vs.85).aspx

establishes connections to a driver and a data source
"""
function SQLConnect(dbc::Ptr{Void}, servername::AbstractString, username::AbstractString,
                    password::AbstractString)
    @odbc(:SQLConnectW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16),
                dbc,transcode(SQLWCHAR,servername),length(transcode(SQLWCHAR,servername)),
                transcode(SQLWCHAR,username),length(transcode(SQLWCHAR,username)),
                transcode(SQLWCHAR,password),length(transcode(SQLWCHAR,password)))
end
function SQLConnect(dbc::SQLConnection, servername::AbstractString, username::AbstractString,
                    password::AbstractString)
    SQLConnect(dbc.ptr, servername, username, password)
end


"""
# SQLDriverConnect

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms715433(v=vs.85).aspx"
"""
function SQLDriverConnect(dbc::Ptr{Void}, window_handle::Ptr{Void}, conn_string,
                          out_conn::Ptr{SQLWCHAR}, out_len, out_buff::Ref{Int16},
                          driver_prompt)
    @odbc(:SQLDriverConnectW,
                (Ptr{Void},Ptr{Void},Ptr{SQLWCHAR},SQLSMALLINT,Ptr{SQLWCHAR},SQLSMALLINT,
                 Ptr{SQLSMALLINT},SQLUSMALLINT),
                dbc,window_handle,transcode(SQLWCHAR,conn_string),
                length(transcode(SQLWCHAR,conn_string)),out_conn,out_len,out_buff,driver_prompt)
end
# TODO continue from here!


#SQLBrowseConnect
 "http://msdn.microsoft.com/en-us/library/windows/desktop/ms714565(v=vs.85).aspx"
 #Description: supports an iterative method of discovering and enumerating the attributes and attribute values required to connect to a data source
 #Status:
function SQLBrowseConnect(dbc::Ptr{Void},instring::AbstractString,outstring::Array{SQLWCHAR,1},indicator::Array{Int16,1})
    @odbc(:SQLBrowseConnectW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{Int16}),
                dbc,transcode(SQLWCHAR,instring),length(transcode(SQLWCHAR,instring)),transcode(SQLWCHAR,outstring),length(transcode(SQLWCHAR,outstring)),indicator)
end
#SQLDisconnect
 "http://msdn.microsoft.com/en-us/library/windows/desktop/ms713946(v=vs.85).aspx"
 #Description: closes the connection associated with a specific connection handle
 #Status:
function SQLDisconnect(dbc::Ptr{Void})
    @odbc(:SQLDisconnect,
                (Ptr{Void},),
                dbc)
end
#SQLGetFunctions
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms709291(v=vs.85).aspx"
#Descriptions:
#Valid functionid

#supported will be SQL_TRUE or SQL_FALSE
#Status:
function SQLGetFunctions(dbc::Ptr{Void},functionid::UInt16,supported::Array{UInt16,1})
    @odbc(:SQLGetFunctions,
                (Ptr{Void},UInt16,Ptr{UInt16}),
                dbc,functionid,supported)
end

#SQLGetInfo
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms711681(v=vs.85).aspx"
#Description:
#Status:
function SQLGetInfo{T,N}(dbc::Ptr{Void},attribute::Int,value::Array{T,N},bytes_returned::Array{Int,1})
    @odbc(:SQLGetInfoW,
                (Ptr{Void},Int,Ptr{T},Int,Ptr{Int}),
                dbc,attribute,value,sizeof(T)*N,bytes_returned)
end

#### Query Functions ####
#SQLNativeSql
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms714575(v=vs.85).aspx"
#Description: returns the SQL string as modified by the driver
#Status:
function SQLNativeSql(dbc::Ptr{Void}, query_string::AbstractString,
                      output_string::Array{SQLWCHAR,1}, length_ind::Array{Int,1})
    @odbc(:SQLNativeSql,
                (Ptr{Void},Ptr{SQLWCHAR},Int,Ptr{SQLWCHAR},Int,Ptr{Int}),
                dbc,transcode(SQLWCHAR,query_string),length(transcode(SQLWCHAR,query_string)),
                output_string,length(output_string),length_ind)
end

#SQLGetTypeInfo
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms714632(v=vs.85).aspx"
#Description:
#valid sqltype
#const SQL_ALL_TYPES =
#Status:
function SQLGetTypeInfo(stmt::Ptr{Void},sqltype::Int16)
    @odbc(:SQLGetTypeInfo,
                (Ptr{Void},Int16),
                stmt,sqltype)
end
SQLGetTypeInfo(stmt::SQLStatement, sqltype::Int16) = SQLGetTypeInfo(stmt.ptr, sqltype)


"http://msdn.microsoft.com/en-us/library/windows/desktop/ms713824(v=vs.85).aspx"
function SQLPutData{T}(stmt::Ptr{Void},data::Array{T},data_length::Int)
    @odbc(:SQLPutData,
                (Ptr{Void},Ptr{T},Int),
                stmt,data,data_length)
end


"http://msdn.microsoft.com/en-us/library/windows/desktop/ms710926(v=vs.85).aspx"
function SQLPrepare(stmt::Ptr{Void},query_string::AbstractString)
    @odbc(:SQLPrepareW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16),
                stmt,transcode(SQLWCHAR,query_string),length(transcode(SQLWCHAR,query_string)))
end
SQLPrepare(stmt::SQLStatement, query_string::AbstractString) = SQLPrepare(stmt.ptr, query_string)


"http://msdn.microsoft.com/en-us/library/windows/desktop/ms713584(v=vs.85).aspx"
function SQLExecute(stmt::Ptr{Void})
    @odbc(:SQLExecute,
                (Ptr{Void},),
                stmt)
end
SQLExecute(stmt::SQLStatement) = SQLExecute(stmt.ptr)

#SQLExecDirect
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms713611(v=vs.85).aspx"
#Description: executes a preparable statement
#Status:
function SQLExecDirect(stmt::Ptr{Void},query::AbstractString)
    @odbc(:SQLExecDirectW,
                (Ptr{Void},Ptr{SQLWCHAR},Int),
                stmt,transcode(SQLWCHAR,query),length(transcode(SQLWCHAR,query)))
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms714112(v=vs.85).aspx"
function SQLCancel(stmt::Ptr{Void})
    @odbc(:SQLCancel,
                (Ptr{Void},),
                stmt)
end

#### Resultset Metadata Functions ####
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms715393(v=vs.85).aspx"
function SQLNumResultCols(stmt::Ptr{Void},cols::Ref{Int16})
    @odbc(:SQLNumResultCols,
                (Ptr{Void},Ref{Int16}),
                stmt, cols)
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms711835(v=vs.85).aspx"
function SQLRowCount(stmt::Ptr{Void},rows::Ref{Int})
    @odbc(:SQLRowCount,
                (Ptr{Void},Ref{Int}),
                stmt, rows)
end

# "http://msdn.microsoft.com/en-us/library/windows/desktop/ms713558(v=vs.85).aspx"
# function SQLColAttribute(stmt::Ptr{Void},x::Int,)
# = @odbc(:SQLColAttributeW,
#                 (Ptr{Void},UInt16,UInt16,Ptr,Int16,Ptr{Int16},Ptr{Int}),
#                 stmt,x,)
# end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms716289(v=vs.85).aspx"
function SQLDescribeCol(stmt,x,nm::Ptr{SQLWCHAR},nmlen,len::Ref{Int16},dt::Ref{Int16},cs::Ref{SQLULEN},dd::Ref{Int16},nul::Ref{Int16})
    @odbc(:SQLDescribeColW,
                (Ptr{Void},SQLUSMALLINT,Ptr{SQLWCHAR},SQLSMALLINT,Ref{SQLSMALLINT},Ref{SQLSMALLINT},Ref{SQLULEN},Ref{SQLSMALLINT},Ref{SQLSMALLINT}),
                stmt,x,nm,nmlen,len,dt,cs,dd,nul)
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms710188(v=vs.85).aspx"
function SQLDescribeParam(stmt::Ptr{Void},x::Int,sqltype::Array{Int16,1},column_size::Array{Int,1},decimal_digits::Array{Int16,1},nullable::Array{Int16,1})
    @odbc(:SQLDescribeParam,
                (Ptr{Void},UInt16,Ptr{Int16},Ptr{Int},Ptr{Int16},Ptr{Int16}),
                stmt,x,sqltype,column_size,decimal_digits,nullable)
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms712366(v=vs.85).aspx"
function SQLParamData(stmt::Ptr{Void},ptr_buffer::Array{Ptr{Void},1})
    @odbc(:SQLParamData,
                (Ptr{Void},Ptr{Void}),
                stmt,ptr_buffer)
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms715409(v=vs.85).aspx"
function SQLNumParams(stmt::Ptr{Void},param_count::Array{Int16,1})
    @odbc(:SQLNumParams,
                (Ptr{Void},Ptr{Int16}),
                stmt,param_count)
end

#### Resultset Retrieval Functions ####
#SQLBindParameter
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms710963(v=vs.85).aspx"
#Description:
#Status:
function SQLBindParameter(stmt::Ptr{Void},x::Int,iotype::Int16,ctype::Int16,sqltype::Int16,column_size::Int,decimal_digits::Int,param_value,param_size::Int,len::Ref{SQLLEN})
    @odbc(:SQLBindParameter,
                (Ptr{Void},UInt16,Int16,Int16,Int16,UInt,Int16,Ptr{Void},Int,Ptr{SQLLEN}),
                stmt,x,iotype,ctype,sqltype,column_size,decimal_digits,param_value,param_size,len)
end
SQLSetParam = SQLBindParameter

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms711010(v=vs.85).aspx"
function SQLBindCols(stmt::Ptr{Void},x,ctype,mem,jlsize,indicator::Vector{SQLLEN})
    @odbc(:SQLBindCol,
                (Ptr{Void},SQLUSMALLINT,SQLSMALLINT,Ptr{Void},SQLLEN,Ptr{SQLLEN}),
                stmt,x,ctype,mem,jlsize,indicator)
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms711707(v=vs.85).aspx"
function SQLSetCursorName(stmt::Ptr{Void},cursor::AbstractString)
    @odbc(:SQLSetCursorNameW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16),
                stmt,transcode(SQLWCHAR,cursor),length(transcode(SQLWCHAR,cursor)))
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms716209(v=vs.85).aspx"
function SQLGetCursorName(stmt::Ptr{Void},cursor::Array{UInt8,1},cursor_length::Array{Int16,1})
    @odbc(:SQLGetCursorNameW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16,Ptr{Int16}),
                stmt,transcode(SQLWCHAR,cursor),length(transcode(SQLWCHAR,cursor)),cursor_length)
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms715441(v=vs.85).aspx"
function SQLGetData(stmt::Ptr{Void},i,ctype,mem,jlsize,indicator::Ref{SQLLEN})
    @odbc(:SQLGetData,
                (Ptr{Void},SQLUSMALLINT,SQLSMALLINT,Ptr{Void},SQLLEN,Ptr{SQLLEN}),
                stmt,i,ctype,mem,jlsize,indicator)
end

#SQLFetchScroll
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms714682(v=vs.85).aspx"
#Description:
#Status:
function SQLFetchScroll(stmt::Ptr{Void},fetch_orientation::Int16,fetch_offset::Int)
    @odbc(:SQLFetchScroll,
                (Ptr{Void},Int16,Int),
                stmt,fetch_orientation,fetch_offset)
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms713591(v=vs.85).aspx"
function SQLExtendedFetch(stmt::Ptr{Void},fetch_orientation::UInt16,fetch_offset::Int,row_count_ptr::Array{Int,1},row_status_array::Array{Int16,1})
    @odbc(:SQLExtendedFetch,
                (Ptr{Void},UInt16,Int,Ptr{Int},Ptr{Int16}),
                stmt,fetch_orientation,fetch_offset,row_count_ptr,row_status_array)
end

#SQLSetPos
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms713507(v=vs.85).aspx"
#Description:
#valid operation
#Status
function SQLSetPos{T}(stmt::Ptr{Void},rownumber::T,operation::UInt16,lock_type::UInt16)
    @odbc(:SQLSetPos,
                (Ptr{Void},T,UInt16,UInt16),
                stmt,rownumber,operation,lock_type)
end #T can be Uint64 or UInt16 it seems

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms714673(v=vs.85).aspx"
function SQLMoreResults(stmt::Ptr{Void})
    @odbc(:SQLMoreResults,
                (Ptr{Void},),
                stmt)
end

#SQLEndTran
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms716544(v=vs.85).aspx"
#Description:
#Status:
function SQLEndTran(handletype::Int16,handle::Ptr{Void},completion_type::Int16)
    @odbc(:SQLEndTran,
                (Int16,Ptr{Void},Int16),
                handletype,handle,completion_type)
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms709301(v=vs.85).aspx"
function SQLCloseCursor(stmt::Ptr{Void})
    @odbc(:SQLCloseCursor,
                (Ptr{Void},),
                stmt)
end

#SQLBulkOperations
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms712471(v=vs.85).aspx"
#Description:
#valid operation
const SQL_ADD = UInt16(4) #SQLBulkOperations
const SQL_UPDATE_BY_BOOKMARK = UInt16(5) #SQLBulkOperations
const SQL_DELETE_BY_BOOKMARK = UInt16(6) #SQLBulkOperations
const SQL_FETCH_BY_BOOKMARK = UInt16(7) #SQLBulkOperations
#Status:
function SQLBulkOperations(stmt::Ptr{Void},operation::UInt16)
    @odbc(:SQLBulkOperations,
                (Ptr{Void},UInt16),
                stmt,operation)
end

#### DBMS Meta Functions ####
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms711683(v=vs.85).aspx"
function SQLColumns(stmt::Ptr{Void},catalog::AbstractString,schema::AbstractString,table::AbstractString,column::AbstractString)
    @odbc(:SQLColumnsW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16),
                stmt,transcode(SQLWCHAR,catalog),length(transcode(SQLWCHAR,catalog)),transcode(SQLWCHAR,schema),length(transcode(SQLWCHAR,schema)),transcode(SQLWCHAR,table),length(transcode(SQLWCHAR,table)),transcode(SQLWCHAR,column),length(transcode(SQLWCHAR,column)))
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms716336(v=vs.85).aspx"
function SQLColumnPrivileges(stmt::Ptr{Void},catalog::AbstractString,schema::AbstractString,table::AbstractString,column::AbstractString)
    @odbc(:SQLColumnPrivilegesW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16),
                stmt,transcode(SQLWCHAR,catalog),length(transcode(SQLWCHAR,catalog)),transcode(SQLWCHAR,schema),length(transcode(SQLWCHAR,schema)),transcode(SQLWCHAR,table),length(transcode(SQLWCHAR,table)),transcode(SQLWCHAR,column),length(transcode(SQLWCHAR,column)))
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms709315(v=vs.85).aspx"
function SQLForeignKeys(stmt::Ptr{Void},pkcatalog::AbstractString,pkschema::AbstractString,pktable::AbstractString,fkcatalog::AbstractString,fkschema::AbstractString,fktable::AbstractString)
    @odbc(:SQLForeignKeysW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16),
                stmt,transcode(SQLWCHAR,catalog),length(transcode(SQLWCHAR,pkcatalog)),transcode(SQLWCHAR,schema),length(transcode(SQLWCHAR,pkschema)),transcode(SQLWCHAR,table),length(transcode(SQLWCHAR,pktable)),transcode(SQLWCHAR,catalog),length(transcode(SQLWCHAR,fkcatalog)),transcode(SQLWCHAR,schema),length(transcode(SQLWCHAR,fkschema)),transcode(SQLWCHAR,table),length(transcode(SQLWCHAR,fktable)))
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms711005(v=vs.85).aspx"
function SQLPrimaryKeys(stmt::Ptr{Void},catalog::AbstractString,schema::AbstractString,table::AbstractString)
    @odbc(:SQLPrimaryKeysW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16),
                stmt,transcode(SQLWCHAR,catalog),length(transcode(SQLWCHAR,catalog)),transcode(SQLWCHAR,schema),length(transcode(SQLWCHAR,schema)),transcode(SQLWCHAR,table),length(transcode(SQLWCHAR,table)))
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms711701(v=vs.85).aspx"
function SQLProcedureColumns(stmt::Ptr{Void},catalog::AbstractString,schema::AbstractString,proc::AbstractString,column::AbstractString)
    @odbc(:SQLProcedureColumnsW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16),
                stmt,transcode(SQLWCHAR,catalog),length(transcode(SQLWCHAR,catalog)),transcode(SQLWCHAR,schema),length(transcode(SQLWCHAR,schema)),proc,length(proc),transcode(SQLWCHAR,column),length(transcode(SQLWCHAR,column)))
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms715368(v=vs.85).aspx"
function SQLProcedures(stmt::Ptr{Void},catalog::AbstractString,schema::AbstractString,proc::AbstractString)
    @odbc(:SQLProceduresW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16),
                stmt,transcode(SQLWCHAR,catalog),length(transcode(SQLWCHAR,catalog)),transcode(SQLWCHAR,schema),length(transcode(SQLWCHAR,schema)),proc,length(proc))
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms711831(v=vs.85).aspx"
function SQLTables(stmt::Ptr{Void},catalog::AbstractString,schema::AbstractString,table::AbstractString,table_type::AbstractString)
    @odbc(:SQLTablesW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16),
                stmt,transcode(SQLWCHAR,catalog),length(transcode(SQLWCHAR,catalog)),transcode(SQLWCHAR,schema),length(transcode(SQLWCHAR,schema)),transcode(SQLWCHAR,table),length(transcode(SQLWCHAR,table)),table_type,length(table_type))
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms713565(v=vs.85).aspx"
function SQLTablePrivileges(stmt::Ptr{Void},catalog::AbstractString,schema::AbstractString,table::AbstractString)
    @odbc(:SQLTablePrivilegesW,
                (Ptr{Void},Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16),
                stmt,transcode(SQLWCHAR,catalog),length(transcode(SQLWCHAR,catalog)),transcode(SQLWCHAR,schema),length(transcode(SQLWCHAR,schema)),transcode(SQLWCHAR,table),length(transcode(SQLWCHAR,table)))
end

#SQLStatistics
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms711022(v=vs.85).aspx"
#Description:
#Status:
function SQLStatistics(stmt::Ptr{Void},catalog::AbstractString,schema::AbstractString,table::AbstractString,unique::UInt16,reserved::UInt16)
    @odbc(:SQLStatisticsW,
                (Ptr{Void},Ptr{UInt8},Int16,Ptr{UInt8},Int16,Ptr{UInt8},Int16,UInt16,UInt16),
                stmt,transcode(SQLWCHAR,catalog),length(transcode(SQLWCHAR,catalog)),transcode(SQLWCHAR,schema),length(transcode(SQLWCHAR,schema)),transcode(SQLWCHAR,table),length(transcode(SQLWCHAR,table)),unique,reserved)
end

#SQLSpecialColumns
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms714602(v=vs.85).aspx"
#Description:
#Status:
function SQLSpecialColumns(stmt::Ptr{Void},id_type::Int16,catalog::AbstractString,schema::AbstractString,table::AbstractString,scope::Int16,nullable::Int16)
    @odbc(:SQLSpecialColumnsW,
                (Ptr{Void},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Ptr{SQLWCHAR},Int16,Int16,Int16),
                stmt,id_type,transcode(SQLWCHAR,catalog),length(transcode(SQLWCHAR,catalog)),transcode(SQLWCHAR,schema),length(transcode(SQLWCHAR,schema)),transcode(SQLWCHAR,table),length(transcode(SQLWCHAR,table)),scope,nullable)
end

#### Error Handling Functions ####
#TODO: add consts
"http://msdn.microsoft.com/en-us/library/windows/desktop/ms710181(v=vs.85).aspx"
function SQLGetDiagField(handletype::Int16,handle::Ptr{Void},i::Int16,diag_id::Int16,diag_info::Array{SQLWCHAR,1},buffer_length::Int16,diag_length::Array{Int16,1})
    @odbc(:SQLGetDiagFieldW,
                (Int16,Ptr{Void},Int16,Int16,Ptr{SQLWCHAR},Int16,Ptr{Int16}),
                handletype,handle,i,diag_id,transcode(SQLWCHAR,diag_info),buffer_length,transcode(SQLWCHAR,msg_length))
end

"http://msdn.microsoft.com/en-us/library/windows/desktop/ms716256(v=vs.85).aspx"
function SQLGetDiagRec(handletype,handle,i,state::Ptr{SQLWCHAR},native::Ref{SQLINTEGER},error_msg,errlen,msg_length)
    @odbc(:SQLGetDiagRecW,
                (SQLSMALLINT,Ptr{Void},SQLSMALLINT,Ptr{SQLWCHAR},Ref{SQLINTEGER},Ptr{SQLWCHAR},SQLSMALLINT,Ref{SQLSMALLINT}),
                handletype,handle,i,state,native,error_msg,errlen,msg_length)
end

