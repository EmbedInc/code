@echo off
rem
rem   BUILD_LIB
rem
rem   Build the CODE library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_pas %srcdir% %libname%_alloc
call src_pas %srcdir% %libname%_comm
call src_pas %srcdir% %libname%_lib
call src_pas %srcdir% %libname%_memadr

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%
