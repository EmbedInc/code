@echo off
rem
rem   Build everything from this source directory.
rem
setlocal
call godir "(cog)source/code"

call build_lib
call build_progs
