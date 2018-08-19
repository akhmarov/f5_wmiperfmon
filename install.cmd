@ECHO OFF

REM #
REM # Data Gathering Agent F5.IsHandler.dll
REM #

SETLOCAL EnableDelayedExpansion
CLS

SET "IIS_POOL_NAME=F5 WMI Monitor"
SET "IIS_SITE_NAME=Default Web Site"
SET "IIS_SITE_PATH=f5wmi"

SET "OS_APPCMD=%SystemRoot%\System32\inetsrv\appcmd.exe"
SET "OS_CONFIG_IIS6=web_iis6.config"
SET "OS_CONFIG_IIS7=web_iis7.config"
SET "OS_CONFIG_TARGET=web.config"
SET "OS_SCRIPT_NAME=F5.IsHandler.dll"
SET "OS_SCRIPT_PATH=%SystemDrive%\inetpub\scripts\%IIS_SITE_PATH%"

ECHO.
ECHO F5 BIG-IP Data Gathering Agent Installation Script
ECHO.
ECHO Please select IIS version:
ECHO.
ECHO 1. IIS 6.0
ECHO 2. IIS 7.0 / 7.5
ECHO 3. IIS 8.0 / 8.5
ECHO 4. Exit
ECHO.
ECHO.

SET /P "M=Select option and press ENTER: "
IF %M%==1 GOTO L_IIS60
IF %M%==2 GOTO L_IIS70
IF %M%==3 GOTO L_IIS80
IF %M%==4 GOTO L_EOF

:L_IIS60

REM #
REM # IIS 6.0
REM #

CALL :SUB_INPUT
CALL :SUB_CHECK
CALL :SUB_COPY_DLL
CALL :SUB_COPY_IIS6
CALL :SUB_APPCMD

:L_IIS70

REM #
REM # IIS 7.0 / 7.5
REM #

CALL :SUB_INPUT
CALL :SUB_CHECK
CALL :SUB_COPY_DLL
CALL :SUB_COPY_IIS7
CALL :SUB_APPCMD

:L_IIS80

REM #
REM # IIS 8.0 / 8.5
REM #

CALL :SUB_INPUT
CALL :SUB_CHECK
CALL :SUB_COPY_DLL
CALL :SUB_APPCMD

GOTO L_EOF

:SUB_INPUT

REM #
REM # Subroutine SUB_INPUT
REM #
REM # Inputs user data and sets appropriate variables
REM #

SET /P "IIS_POOL_NAME=Enter IIS pool name [%IIS_POOL_NAME%]: "
SET /P "IIS_SITE_NAME=Enter IIS site name [%IIS_SITE_NAME%]: "
SET /P "IIS_SITE_PATH=Enter IIS site path [%IIS_SITE_PATH%]: "

EXIT /B

:SUB_CHECK

REM #
REM # Subroutine SUB_CHECK
REM #
REM # Prints used variables and waits for user continue
REM #

ECHO.
ECHO Using variables:
ECHO   IIS_POOL_NAME = %IIS_POOL_NAME%
ECHO   IIS_SITE_NAME = %IIS_SITE_NAME%
ECHO   IIS_SITE_PATH = %IIS_SITE_PATH%
ECHO   OS_SCRIPT_NAME = %OS_SCRIPT_NAME%
ECHO   OS_SCRIPT_PATH = %OS_SCRIPT_PATH%
ECHO.

PAUSE
ECHO.

EXIT /B

:SUB_COPY_DLL

REM #
REM # Subroutine SUB_COPY_DLL
REM #
REM # Copies script to specified dir. If script already exists it just updates it
REM #

IF NOT EXIST "%OS_SCRIPT_PATH%\bin" (
	MKDIR "%OS_SCRIPT_PATH%\bin"
)

COPY /B %OS_SCRIPT_NAME% "%OS_SCRIPT_PATH%\bin"

EXIT /B

:SUB_COPY_IIS6

REM #
REM # Subroutine SUB_COPY_IIS6
REM #
REM # Copies IIS 6.0 web.config file
REM #

COPY /B %OS_CONFIG_IIS6% "%OS_SCRIPT_PATH%\%OS_CONFIG_TARGET%"

EXIT /B

:SUB_COPY_IIS7

REM #
REM # Subroutine SUB_COPY_IIS7
REM #
REM # Copies IIS 7.0 / 7.5 web.config file
REM #

COPY /B %OS_CONFIG_IIS7% "%OS_SCRIPT_PATH%\%OS_CONFIG_TARGET%"

EXIT /B

:SUB_APPCMD

REM #
REM # Subroutine SUB_APPCMD
REM #
REM # Configures IIS 7.0 / 7.5 / 8.0 / 8.5
REM #

REM Create a new application pool
%OS_APPCMD% add apppool /name:"%IIS_POOL_NAME%"
%OS_APPCMD% set apppool /apppool.name:"%IIS_POOL_NAME%" /processModel.identityType:NetworkService
%OS_APPCMD% set config -section:system.applicationHost/applicationPools /[name='"%IIS_POOL_NAME%"'].enableConfigurationOverride:"False" /commit:APPHOST

REM Create a new application for previous application pool
%OS_APPCMD% add app /site.name:"%IIS_SITE_NAME%" /path:"/%IIS_SITE_PATH%" /physicalPath:"%OS_SCRIPT_PATH%"
%OS_APPCMD% set app /app.name:"%IIS_SITE_NAME%/%IIS_SITE_PATH%" /applicationPool:"%IIS_POOL_NAME%"

REM Set only Basic Authentication for previous application
%OS_APPCMD% set config "%IIS_SITE_NAME%/%IIS_SITE_PATH%" /section:anonymousAuthentication /overrideMode:Allow /commit:APPHOST
%OS_APPCMD% set config "%IIS_SITE_NAME%/%IIS_SITE_PATH%" /section:anonymousAuthentication /enabled:"False" /commit:APPHOST
%OS_APPCMD% set config "%IIS_SITE_NAME%/%IIS_SITE_PATH%" /section:system.web/authentication /mode:Windows
%OS_APPCMD% set config "%IIS_SITE_NAME%/%IIS_SITE_PATH%" /section:windowsAuthentication /enabled:"False" /commit:APPHOST
%OS_APPCMD% set config "%IIS_SITE_NAME%/%IIS_SITE_PATH%" /section:basicAuthentication /enabled:"True" /commit:APPHOST

REM Create a new handler mapping for created application
%OS_APPCMD% set config "%IIS_SITE_NAME%/%IIS_SITE_PATH%" -section:system.webServer/handlers /overrideMode:Allow /commit:APPHOST
%OS_APPCMD% set config "%IIS_SITE_NAME%/%IIS_SITE_PATH%" -section:system.webServer/handlers /+"[name='F5 IsHandler',path='%IIS_SITE_PATH%/F5Isapi.dll',verb='POST',type='F5.IsHandler',preCondition='']"

EXIT /B

:L_EOF