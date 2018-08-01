#define _DEFAULT_SOURCE
#include <limits.h>
#include <stdlib.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/alloc.h>


value ml_realpath(value path){
    CAMLparam1(path);
    CAMLlocal1(p);
    char *ps = realpath(String_val(path), NULL);
    if (!ps){
        caml_failwith("Invalid path");
    }
    p = caml_copy_string(ps);
    free(ps);
    CAMLreturn(p);
}
