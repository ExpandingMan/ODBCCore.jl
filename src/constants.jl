
"""
# MAXFETCHSIZE sets the default rowset fetch size
# used in retrieving resultset blocks from queries
"""
const MAXFETCHSIZE = 65535

# success codes
const SQL_SUCCESS           = Int16(0)
const SQL_SUCCESS_WITH_INFO = Int16(1)

# error codes
const SQL_ERROR             = Int16(-1)
const SQL_INVALID_HANDLE    = Int16(-2)

# status codes
const SQL_STILL_EXECUTING   = Int16(2)
const SQL_NO_DATA           = Int16(100)

const RETURN_VALUES = Dict(SQL_ERROR   => "SQL_ERROR",
                           SQL_NO_DATA => "SQL_NO_DATA",
                           SQL_INVALID_HANDLE  => "SQL_INVALID_HANDLE",
                           SQL_STILL_EXECUTING => "SQL_STILL_EXECUTING")


# SQLAllocHandle
#"http://msdn.microsoft.com/en-us/library/windows/desktop/ms712455(v=vs.85).aspx"
# Description: allocates an environment, connection, statement, or descriptor handle
# Valid handle types
const SQL_HANDLE_ENV  = Int16(1)
const SQL_HANDLE_DBC  = Int16(2)
const SQL_HANDLE_STMT = Int16(3)
const SQL_HANDLE_DESC = Int16(4)
const SQL_NULL_HANDLE = C_NULL

# SQLSetEnvAttr
#"http://msdn.microsoft.com/en-us/library/windows/desktop/ms709285(v=vs.85).aspx"
# Description: sets attributes that govern aspects of environments
# Valid attributes; valid values for attribute are indented
const SQL_ATTR_CONNECTION_POOLING = 201
const SQL_CP_OFF = UInt(0)
const SQL_CP_ONE_PER_DRIVER = UInt(1)
const SQL_CP_ONE_PER_HENV = UInt(2)
const SQL_CP_DEFAULT = SQL_CP_OFF
const SQL_ATTR_CP_MATCH = 202
const SQL_CP_RELAXED_MATCH = UInt(1)
const SQL_CP_STRICT_MATCH = UInt(0)
const SQL_ATTR_ODBC_VERSION = 200
const SQL_OV_ODBC2 = 2
const SQL_OV_ODBC3 = 3
const SQL_ATTR_OUTPUT_NTS = 10001
const SQL_TRUE = 1
const SQL_FALSE = 0

# Valid attributes
const SQL_ATTR_ACCESS_MODE = 101
const SQL_MODE_READ_ONLY = UInt(1)
const SQL_MODE_READ_WRITE = UInt(0)
#const SQL_ATTR_ASYNC_DBC_EVENT
#pointer
#const SQL_ATTR_ASYNC_DBC_FUNCTIONS_ENABLE
#const SQL_ASYNC_DBC_ENABLE_ON = UInt()
#const SQL_ASYNC_DBC_ENABLE_OFF = UInt()
#const SQL_ATTR_ASYNC_DBC_PCALLBACK
#pointer
#const SQL_ATTR_ASYNC_DBC_PCONTEXT
#pointer
const SQL_ATTR_ASYNC_ENABLE = 4
const SQL_ASYNC_ENABLE_OFF = UInt(0)
const SQL_ASYNC_ENABLE_ON = UInt(1)
const SQL_ATTR_AUTOCOMMIT = 102
const SQL_AUTOCOMMIT_OFF = UInt(0)
const SQL_AUTOCOMMIT_ON = UInt(1)
const SQL_ATTR_CONNECTION_TIMEOUT = 113
#uint of how long you want the connection timeout
const SQL_ATTR_CURRENT_CATALOG = 109
#string/Ptr{UInt8} of default database to use
#const SQL_ATTR_DBC_INFO_TOKEN
#pointer
const SQL_ATTR_ENLIST_IN_DTC = 1207
#pointer: Pass a DTC OLE transaction object that specifies the transaction to export to
# SQL Server, or SQL_DTC_DONE to end the connection's DTC association.
const SQL_ATTR_LOGIN_TIMEOUT = 103
#uint of how long you want the login timeout
const SQL_ATTR_METADATA_ID = 10014
#SQL_TRUE, SQL_FALSE
const SQL_ATTR_ODBC_CURSORS = 110
const SQL_CUR_USE_IF_NEEDED = UInt(0)
const SQL_CUR_USE_ODBC = UInt(1)
const SQL_CUR_USE_DRIVER = UInt(2)
const SQL_ATTR_PACKET_SIZE = 112
#uint for network packet size
const SQL_ATTR_QUIET_MODE = 111
#window handle pointer
const SQL_ATTR_TRACE = 104
const SQL_OPT_TRACE_OFF = UInt(0)
const SQL_OPT_TRACE_ON = UInt(1)
const SQL_ATTR_TRACEFILE = 105
#A null-terminated character string containing the name of the trace file.
const SQL_ATTR_TRANSLATE_LIB = 106
# A null-terminated character string containing the name of a library containing the functions SQLDriverToDataSource and
# SQLDataSourceToDriver that the driver accesses to perform tasks such as character set translation.
const SQL_ATTR_TRANSLATE_OPTION = 107
#A 32-bit flag value that is passed to the translation DLL.
const SQL_ATTR_TXN_ISOLATION = 108
#A 32-bit bitmask that sets the transaction isolation level for the current connection.

#Valid value_length
const SQL_IS_POINTER = -4
const SQL_IS_INTEGER = -6
const SQL_IS_UINTEGER = -5
const SQL_NTS = -3

#Valid driver_prompt
const SQL_DRIVER_COMPLETE = UInt16(1)
const SQL_DRIVER_COMPLETE_REQUIRED = UInt16(3)
const SQL_DRIVER_NOPROMPT = UInt16(0)
const SQL_DRIVER_PROMPT = UInt16(2)

#valid iotype
const SQL_PARAM_INPUT = Int16(1)
const SQL_PARAM_OUTPUT = Int16(4)
const SQL_PARAM_INPUT_OUTPUT = Int16(2)
#const SQL_PARAM_INPUT_OUTPUT_STREAM = Int16()
#const SQL_PARAM_OUTPUT_STREAM = Int16()

#valid fetch_orientation
const SQL_FETCH_NEXT = Int16(1)
const SQL_FETCH_PRIOR = Int16(4)
const SQL_FETCH_FIRST = Int16(2)
const SQL_FETCH_LAST = Int16(3)
const SQL_FETCH_ABSOLUTE = Int16(5)
const SQL_FETCH_RELATIVE = Int16(6)
const SQL_FETCH_BOOKMARK = Int16(8)

const SQL_POSITION = UInt16(0) #SQLSetPos
const SQL_REFRESH = UInt16(1) #SQLSetPos
const SQL_UPDATE = UInt16(2) #SQLSetPos
const SQL_DELETE = UInt16(3) #SQLSetPos
#valid lock_type
const SQL_LOCK_NO_CHANGE = UInt16(0) #SQLSetPos
const SQL_LOCK_EXCLUSIVE = UInt16(1) #SQLSetPos
const SQL_LOCK_UNLOCK = UInt16(2) #SQLSetPos

#valid completion_type
const SQL_COMMIT = Int16(0) #SQLEndTran
const SQL_ROLLBACK = Int16(1) #SQLEndTran

#valid unique
const SQL_INDEX_ALL = UInt16(1)
const SQL_INDEX_CLUSTERED = UInt16(1)
const SQL_INDEX_HASHED = UInt16(2)
const SQL_INDEX_OTHER = UInt16(3)
const SQL_INDEX_UNIQUE = UInt16(0)
#valid reserved
const SQL_ENSURE = UInt16(1)
const SQL_QUICK = UInt16(0)

#valid id_type
const SQL_BEST_ROWID        = Int16(1) #SQLSpecialColumns
const SQL_ROWVER            = Int16(2) #SQLSpecialColumns
#valid scope
const SQL_SCOPE_CURROW      = Int16(0) #SQLSpecialColumns
const SQL_SCOPE_SESSION     = Int16(2) #SQLSpecialColumns
const SQL_SCOPE_TRANSACTION = Int16(1) #SQLSpecialColumns
#valid nullable
const SQL_NO_NULLS          = Int16(0) #SQLSpecialColumns
const SQL_NULLABLE          = Int16(1) #SQLSpecialColumns
#const SQL_NULLABLE_UNKNOWN = Int16() #SQLSpecialColumns

const SQL_ATTR_AUTO_IPD = 10001
#SQL_TRUE, SQL_FALSE
const SQL_ATTR_CONNECTION_DEAD = 1209
const SQL_CD_TRUE = 1
const SQL_CD_FALSE = 0

const SQL_ATTR_ROW_STATUS_PTR = 25
const SQL_ATTR_ROWS_FETCHED_PTR  = 26
const SQL_ATTR_ROW_ARRAY_SIZE = 27

const SQL_CLOSE = UInt16(0)
const SQL_RESET_PARAMS = UInt16(3)
const SQL_UNBIND = UInt16(2)



