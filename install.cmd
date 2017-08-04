@ECHO OFF

REM #
REM # Data Gathering Agent F5.IsHandler.dll on an IIS 8.0 or 8.5 server
REM #

SETLOCAL EnableDelayedExpansion
CLS

SET APPCMD=%SystemRoot%\System32\inetsrv\appcmd.exe

SET "SCRIPT_NAME=F5.IsHandler.dll"
SET "SCRIPT_PATH=%SystemDrive%\inetpub\scripts"
SET "SITE_NAME=Default Web Site"
SET "SITE_PATH=f5wmi"
SET "POOL_NAME=F5 Application Pool"

ECHO.
ECHO F5 BIG-IP Data Gathering Agent Installation Script
ECHO.
ECHO Please select IIS version:
ECHO.
ECHO 1. IIS 6.0
ECHO 2. IIS 7.0
ECHO 3. IIS 7.5
ECHO 4. IIS 8.0 or 8.5
ECHO 5. Exit
ECHO.
ECHO.

SET /P "M=Select option and press ENTER: "
IF %M%==1 GOTO IIS60
IF %M%==2 GOTO IIS70
IF %M%==3 GOTO IIS75
IF %M%==4 GOTO IIS80
IF %M%==5 GOTO EOF

:IIS60

REM #
REM # IIS Server 6.0
REM #

:IIS70

REM #
REM # IIS Server 7.0
REM #

:IIS75

REM #
REM # IIS Server 7.5
REM #

:IIS80

REM #
REM # IIS Server 8.0 or 8.5
REM #

CALL :SUB_INPUT
CALL :SUB_CHECK
CALL :SUB_COPY

REM Set up a new application pool for the file F5.IsHandler.dll
%APPCMD% add apppool /name:"%POOL_NAME%"
%APPCMD% set apppool /apppool.name:"%POOL_NAME%" /processModel.identityType:NetworkService

REM Create a new application named scripts
%APPCMD% add app /site.name:"%SITE_NAME%" /path:"/%SITE_PATH%" /physicalPath:"%SCRIPT_PATH%"
%APPCMD% set app /app.name:"%SITE_NAME%/%SITE_PATH%" /applicationPool:"%POOL_NAME%"

REM Allow anonymous authentication
%APPCMD% set config "%SITE_NAME%/%SITE_PATH%" /section:anonymousAuthentication /overrideMode:Allow /commit:APPHOST

REM Change the Authentication setting to Basic Authentication
%APPCMD% set config "%SITE_NAME%/%SITE_PATH%" /section:anonymousAuthentication /enabled:"False" /commit:APPHOST
%APPCMD% set config "%SITE_NAME%/%SITE_PATH%" /section:basicAuthentication /enabled:"True" /commit:APPHOST
%APPCMD% set config "%SITE_NAME%/%SITE_PATH%" /section:windowsAuthentication /enabled:"False" /commit:APPHOST

REM Add a handler mapping
%APPCMD% set config "%SITE_NAME%/%SITE_PATH%" -section:system.webServer/handlers /+"[name='F5 IsHandler',path='F5Isapi.dll',verb='*',type='F5.IsHandler',preCondition='']"

GOTO EOF

:SUB_INPUT

REM #
REM # Subroutine SUB_INPUT
REM #
REM # Inputs user data and sets appropriate variables
REM #

SET /P "SCRIPT_PATH=Enter script path (without trailing slash) [%SCRIPT_PATH%]: "
SET /P "SITE_NAME=Enter site name [%SITE_NAME%]: "
SET /P "SITE_PATH=Enter site path [%SITE_PATH%]: "

EXIT /B

:SUB_CHECK

REM #
REM # Subroutine SUB_CHECK
REM #
REM # Prints used variables and waits for user continue
REM #

ECHO.
ECHO Using variables:
ECHO   SCRIPT_NAME = %SCRIPT_NAME%
ECHO   SCRIPT_PATH = %SCRIPT_PATH%
ECHO   SITE_NAME = %SITE_NAME%
ECHO   SITE_PATH = %SITE_PATH%
ECHO   POOL_NAME = %POOL_NAME%
ECHO.

PAUSE
ECHO.

EXIT /B

:SUB_COPY

REM #
REM # Subroutine SUB_COPY
REM #
REM # Copies script to specified dir. If script already exists it just updates it
REM #

IF NOT EXIST "%SCRIPT_PATH%\bin" (
	MKDIR "%SCRIPT_PATH%\bin"
)

COPY /B %SCRIPT_NAME% "%SCRIPT_PATH%\bin"

EXIT /B

:EOF
