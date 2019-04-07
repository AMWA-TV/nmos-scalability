@ECHO OFF
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

:: Usage When no parameters
if [%1] EQU [] (
    echo.
    echo.  Usage: %~n0 ^<.ovf file^> ^<Virtual Machine Name^>
    echo.
    echo.    Environment variables can be used to enable options
    echo.      e.g. To set number of CPU's and MEMORY at import first set the environconv variables NMOS_MININET_CPUS and NMOS_MININET_MEMORY (in MB^) e.g.
    echo.        set NMOS_MININET_CPUS=12
    echo.        set NMOS_MININET_MEMORY=40000
    echo.      Shared Folder:
    echo.        To setup a folder to share with the VM:
    echo.          set NMOS_MININET_SHARED_DIR=c:\MyPath\MySharedDir
    echo.        To use a different name from 'MySharedDir' inside the VM additionally set:
    echo.         set NMOS_MININET_SHARED_DIR_NAME=MyNewName
    exit /B
)

::******************************************************************************
:: Default Environment Variables

:: Full path to VboxManage executable
set VBOXMANAGE_EXE="%PROGRAMFILES%\Oracle\VirtualBox\VBoxManage.exe"
if not exist %VBOXMANAGE_EXE% (
  echo could not find VBoxManage.exe at:
  echo     %VBOXMANAGE_EXE%
  exit /B
)

IF [%2]==[] (
  set VIRTUAL_MACHINE_NAME=Mininet-VM
) else (
  set VIRTUAL_MACHINE_NAME=%2
  :: When renaming imported VM we need to supply the fullpath for the virtual image
  FOR /F "tokens=*" %%g IN ('%%VBOXMANAGE_EXE%% list systemproperties ^| find "Default machine folder"') do (SET NMOS_MININET_VM_DIR=%%g)
  set NMOS_MININET_VM_DIR=!NMOS_MININET_VM_DIR:Default machine folder:=!
  for /f "tokens=* delims= " %%a in ("!NMOS_MININET_VM_DIR!") do set NMOS_MININET_VM_DIR=%%a
  set NMOS_MININET_VM_DISK_IMAGE_FILE_CMD=--unit 7 --disk "!NMOS_MININET_VM_DIR!\!VIRTUAL_MACHINE_NAME!\!VIRTUAL_MACHINE_NAME!-disk001.vmdk"
)

echo Virtual Machine Name is: %VIRTUAL_MACHINE_NAME%

:: How many CPUs for VM to use (uses standard default (1) when no parameter set)
if [%NMOS_MININET_CPUS%] == [] (set VM_CPUS_CMD=) else (set VM_CPUS_CMD= --cpus %NMOS_MININET_CPUS% )

:: How much memory for VM to use (uses standard default (1024 MB) when no parameter set)
if [%NMOS_MININET_MEMORY%] == [] (set VM_MEMORY_CMD=) else (set VM_MEMORY_CMD= --memory %NMOS_MININET_MEMORY% )



:: If a Shared directory is defined, check it exists
if defined NMOS_MININET_SHARED_DIR (
  if not exist %NMOS_MININET_SHARED_DIR%\  (
    echo directory defined by environment variable NMOS_MININET_SHARED_DIR does not exist
    exit /B
  )
  if not defined NMOS_MININET_SHARED_DIR_NAME (
    :: no separate directury name supplied, use top folder name
    For %%A in ("%NMOS_MININET_SHARED_DIR%") do (
      set NMOS_MININET_SHARED_DIR_NAME=%%~nxA
    )
  )
)

:: Guest Additions ISO location
set VIRTUAM_MACHINE_GUEST_ADDITIONS_ISO_FILE="%PROGRAMFILES%\Oracle\VirtualBox\VBoxGuestAdditions.iso"

:: Check file exists
if not exist %VIRTUAM_MACHINE_GUEST_ADDITIONS_ISO_FILE% (
  echo could not find Guest Additions ISO at:
  echo %VIRTUAM_MACHINE_GUEST_ADDITIONS_ISO_FILE%
  exit /B
)

:: Import VM
%VBOXMANAGE_EXE% import --vsys 0 %VM_CPUS_CMD% %VM_MEMORY_CMD% -vmname %VIRTUAL_MACHINE_NAME% %1 %NMOS_MININET_VM_DISK_IMAGE_FILE_CMD%
if %ERRORLEVEL% NEQ 0 (
  echo FAILED TO CREATE VIRTUAL MACHINE
  exit /B
)

%VBOXMANAGE_EXE% modifyvm %VIRTUAL_MACHINE_NAME% --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" --nicpromisc2 allow-all
%VBOXMANAGE_EXE% modifyvm %VIRTUAL_MACHINE_NAME% --natnet1 "10.10/16"
%VBOXMANAGE_EXE% storageattach %VIRTUAL_MACHINE_NAME% --storagectl SCSI --port 1 --device 0 --type dvddrive --medium %VIRTUAM_MACHINE_GUEST_ADDITIONS_ISO_FILE%

if defined NMOS_MININET_SHARED_DIR (
  %VBOXMANAGE_EXE% sharedfolder add %VIRTUAL_MACHINE_NAME% --name %NMOS_MININET_SHARED_DIR_NAME% --hostpath %NMOS_MININET_SHARED_DIR% --automount
  %VBOXMANAGE_EXE% setextradata %VIRTUAL_MACHINE_NAME% VBoxInternal2/SharedFoldersEnableSymlinksCreate/%NMOS_MININET_SHARED_DIR_NAME% 1
)

echo.
echo.ENTER to start VM, CTRL-C to quit
pause
%VBOXMANAGE_EXE% startvm %VIRTUAL_MACHINE_NAME%


