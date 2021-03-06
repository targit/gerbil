;;; -*- Scheme -*-
;;; (C) vyzo at hackzen.org
;;; SQLite FFI

;; compile: -ld-options "-lsqlite3"

(declare
  (block)
  (standard-bindings)
  (extended-bindings)
  (not safe))

(namespace ("std/db/_sqlite#"))
(##namespace ("" define-macro define let let* if or and
              quote quasiquote unquote unquote-splicing
              c-lambda c-define-type c-declare c-initialize 
              ))

(c-declare #<<END-C
#include <stdio.h>
#include <string.h>           
#include <sqlite3.h>

#define U8_DATA(obj) ___CAST (___U8*, ___BODY_AS (obj, ___tSUBTYPED))
#define U8_LEN(obj) ___HD_BYTES (___HEADER (obj))

static int ffi_last_error;
END-C
)

(c-initialize #<<END-C
ffi_last_error = 0;
if (sqlite3_initialize () != SQLITE_OK) {
  fprintf (stderr, "Warning: error initializing sqlite3 library\n");
}

END-C
)

(define-macro (define-c-lambda id args ret #!optional (name #f))
  (let ((name (or name (##symbol->string id))))
    `(define ,id
       (c-lambda ,args ,ret ,name))))

(define-macro (define-const symbol)
  (let* ((str (##symbol->string symbol))
         (ref (##string-append "___return (" str ");")))
    `(define ,symbol
       ((c-lambda () int ,ref)))))

(define-const SQLITE_OPEN_READONLY)
(define-const SQLITE_OPEN_READWRITE)
(define-const SQLITE_OPEN_CREATE)
(define-const SQLITE_OPEN_URI)
(define-const SQLITE_OPEN_MEMORY)
(define-const SQLITE_OPEN_NOMUTEX)
(define-const SQLITE_OPEN_FULLMUTEX)
(define-const SQLITE_OPEN_SHAREDCACHE)
(define-const SQLITE_OPEN_PRIVATECACHE)

(define-const SQLITE_OK)
(define-const SQLITE_ROW)
(define-const SQLITE_DONE)

(define-const SQLITE_INTEGER)
(define-const SQLITE_FLOAT)
(define-const SQLITE_BLOB)
(define-const SQLITE_NULL)
(define-const SQLITE_TEXT)

(c-declare #<<END-C
static sqlite3* ffi_sqlite3_open (const char *path, int flags);
static sqlite3_stmt* ffi_sqlite3_prepare (sqlite3* db, const char *sql);
static int ffi_sqlite3_bind_blob (sqlite3_stmt* stmt, int col, ___SCMOBJ data);
static int ffi_sqlite3_bind_text (sqlite3_stmt* stmt, int col, const char *str);
static void ffi_sqlite3_column_blob (sqlite3_stmt* stmt, int col, ___SCMOBJ bytes);
END-C
)

(c-define-type sqlite3 "sqlite3")
(c-define-type sqlite3*
  (pointer sqlite3 (sqlite3*)))
(c-define-type sqlite3_stmt "sqlite3_stmt")
(c-define-type sqlite3_stmt*
  (pointer sqlite3_stmt (sqlite3_stmt*)))

(define-c-lambda sqlite3_errstr (int) UTF-8-string
  "___return ((char*)sqlite3_errstr (___arg1));")
(define-c-lambda sqlite3_last_error () int
  "___return (ffi_last_error);")
(define-c-lambda sqlite3_open (char-string int) sqlite3*
  "ffi_sqlite3_open")
(define-c-lambda sqlite3_close (sqlite3*) int
  "sqlite3_close_v2")
(define-c-lambda sqlite3_prepare (sqlite3* UTF-8-string) sqlite3_stmt*
  "ffi_sqlite3_prepare")
(define-c-lambda sqlite3_stmt_readonly (sqlite3_stmt*) bool
  "sqlite3_stmt_readonly")
(define-c-lambda sqlite3_stmt_busy (sqlite3_stmt*) bool
  "sqlite3_stmt_busy")
(define-c-lambda sqlite3_bind_blob (sqlite3_stmt* int scheme-object) int
  "ffi_sqlite3_bind_blob")
(define-c-lambda sqlite3_bind_int (sqlite3_stmt* int int) int
  "sqlite3_bind_int")
(define-c-lambda sqlite3_bind_int64 (sqlite3_stmt* int int64) int
  "sqlite3_bind_int64")
(define-c-lambda sqlite3_bind_double (sqlite3_stmt* int double) int
  "sqlite3_bind_double")
(define-c-lambda sqlite3_bind_null (sqlite3_stmt* int) int
  "sqlite3_bind_null")
(define-c-lambda sqlite3_bind_text (sqlite3_stmt* int UTF-8-string) int
  "ffi_sqlite3_bind_text")
(define-c-lambda sqlite3_bind_zeroblob (sqlite3_stmt* int int) int
  "sqlite3_bind_zeroblob")
(define-c-lambda sqlite3_bind_parameter_count (sqlite3_stmt*) int
  "sqlite3_bind_parameter_count")
(define-c-lambda sqlite3_clear_bindings (sqlite3_stmt*) int
  "sqlite3_clear_bindings")
(define-c-lambda sqlite3_column_count (sqlite3_stmt*) int
  "sqlite3_column_count")
(define-c-lambda sqlite3_column_name (sqlite3_stmt* int) UTF-8-string
  "___return ((char*)sqlite3_column_name (___arg1, ___arg2));")
(define-c-lambda sqlite3_column_decltype (sqlite3_stmt* int) UTF-8-string
  "___return ((char*)sqlite3_column_decltype (___arg1, ___arg2));")
(define-c-lambda sqlite3_step (sqlite3_stmt*) int
  "sqlite3_step")
(define-c-lambda sqlite3_data_count (sqlite3_stmt*) int
  "sqlite3_data_count")
(define-c-lambda sqlite3_column_type (sqlite3_stmt* int) int
  "sqlite3_column_type")
(define-c-lambda sqlite3_column_bytes (sqlite3_stmt* int) int
  "sqlite3_column_bytes")
(define-c-lambda sqlite3_column_blob (sqlite3_stmt* int scheme-object) void
  "ffi_sqlite3_column_blob")
(define-c-lambda sqlite3_column_text (sqlite3_stmt* int) UTF-8-string
  "___return ((char*)sqlite3_column_text (___arg1, ___arg2));")
(define-c-lambda sqlite3_column_int (sqlite3_stmt* int) int
  "sqlite3_column_int")
(define-c-lambda sqlite3_column_int64 (sqlite3_stmt* int) int64
  "sqlite3_column_int64")
(define-c-lambda sqlite3_column_double (sqlite3_stmt* int) double
  "sqlite3_column_double")
(define-c-lambda sqlite3_finalize (sqlite3_stmt*) int
  "sqlite3_finalize")
(define-c-lambda sqlite3_reset (sqlite3_stmt*) int
  "sqlite3_reset")

(c-declare #<<END-C
static sqlite3* ffi_sqlite3_open (const char *path, int flags)
{
 sqlite3 *db;
 int r = sqlite3_open_v2 (path, &db, flags, NULL);
 if (r == SQLITE_OK) {
  return db;
 } else {
  ffi_last_error = r;               
  sqlite3_close_v2 (db);
  return NULL;                        
 }
}

static sqlite3_stmt* ffi_sqlite3_prepare (sqlite3* db, const char *sql)
{
 sqlite3_stmt* stmt;
 int r = sqlite3_prepare_v2 (db, sql, strlen (sql), &stmt, NULL);
 if (r == SQLITE_OK) {
  return stmt;
 } else {
  ffi_last_error = r;               
  sqlite3_finalize (stmt);
  return NULL;
 }                
}

static int ffi_sqlite3_bind_blob (sqlite3_stmt* stmt, int col, ___SCMOBJ data)
{
 return sqlite3_bind_blob (stmt, col, U8_DATA (data), U8_LEN (data), SQLITE_TRANSIENT);
}

static int ffi_sqlite3_bind_text (sqlite3_stmt* stmt, int col, const char *str)
{
 return sqlite3_bind_text (stmt, col, str, strlen (str), SQLITE_TRANSIENT);
}

static void ffi_sqlite3_column_blob (sqlite3_stmt* stmt, int col, ___SCMOBJ bytes)
{
 const void *blob = sqlite3_column_blob (stmt, col);
 memcpy (U8_DATA (bytes), blob, U8_LEN (bytes));
}

END-C
)
