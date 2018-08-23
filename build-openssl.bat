:: Configurable Options
:: If you have jom available, set it to jom - it speeds up the build.
@set JOM=nmake
:: Choose a static or dynamic build
@set LIBTYPE=dynamic
:: OpenSSL version in the 1.0.2 series
@set SRC=openssl-1.0.2n

@if "%VSCMD_ARG_TGT_ARCH%"=="x86" (
    @set BITS=32
    @set DST=OpenSSL-Win32
    @set CONFIG=VC-WIN32
    @set SETUP=ms\do_nasm
) else if "%VSCMD_ARG_TGT_ARCH%"=="x64" (
    @set BITS=64
    @set DST=OpenSSL-Win64
    @set CONFIG=VC-WIN64A
    @set SETUP=ms\do_win64a
) else goto no_vscmd

@if "%LIBTYPE%"=="static" (
    @set LIBTYPE=nt
) else if "%LIBTYPE%"=="dynamic" (
    @set LIBTYPE=ntdll
) else goto no_libtype

@echo Building %SRC% for %BITS% bits.

@echo - Downloading
@perl ^
    -e "use LWP::Simple;" ^
    -e "mirror('https://www.openssl.org/source/%SRC%.tar.gz', '%SRC%.tar.gz');"

@echo - Decompressing
@if not exist %SRC%.tar.gz goto no_archive
@rmdir /S /Q %SRC% %DST% 2>NUL
@7z x -bsp2 -y %SRC%.tar.gz >NUL && ^
7z x -bsp2 -y %SRC%.tar     >NUL && ^
del %SRC%.tar
@if errorlevel 1 goto unpack_failed
@if not exist %SRC% goto no_source

@echo - Building
@pushd %SRC%
@perl Configure %CONFIG% --prefix=%~dp0..\%DST% && ^
call %SETUP% && ^
nmake -f ms\%LIBTYPE%.mak init && ^
%JOM% -f ms\%LIBTYPE%.mak "CC=cl /FS" && ^
%JOM% -f ms\%LIBTYPE%.mak test && ^
nmake -f ms\%LIBTYPE%.mak install || goto build_failed
@popd
@rmdir /S /Q %SRC%

@echo Build has succeeded.
@goto :eof

:no_libtype
@echo Error: LIBTYPE must be either "static" or "dynamic">&2
@exit /b 1    

:no_archive
@echo Error: can't find %SRC%.tar.gz - the download has failed :(>&2
@exit /b 1

:unpack_failed
@echo Error: unpacking has failed.>&2
@exit /b %errorlevel%

:no_source
@echo Error: can't find %SRC%\>&2
@exit /b 1

:build_failed
@echo The build had failed.>&2
@popd
@exit /b 2

:no_vscmd
@echo Use vcvarsall x86 or vcvarsall x64 to set up the Visual Studio>&2
@echo build environment first.>&2
@exit /b 100
