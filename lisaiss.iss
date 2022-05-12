; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!
#define MyAppName "Lisa & Plugin-Zephyr"
#define MyAppVersion "2.3.0 & 1.4.1"
#define MyAppPublisher "zbzhao"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{A829E4E1-45F6-4C1A-9864-230C967ADE26}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={code:MyDestDir}..\..\..\.listenai
DisableDirPage=yes
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
UsedUserAreasWarning=no
ChangesEnvironment=yes
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
OutputBaseFilename=Lisa Installer
; SetupIconFile=D:\Program Files\Inno Setup 6\SetupClassicIcon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
; Name: "chinesesimp"; MessagesFile: "chinese.isl"
Name: "chinesesimp"; MessagesFile: "Default.zh-cn.isl"

[Files]
Source: "###pwd###"; DestDir: "{app}\lisa"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "###zephyrPwd###"; DestDir: "{app}\lisa-zephyr"; Flags: ignoreversion recursesubdirs createallsubdirs
;Source: "installerScripts\*"; DestDir: "{app}\installerScripts";
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Tasks]
Name: modifypath; Description: &添加环境变量; Flags: checkablealone
[Run]
;Filename: "{app}\installerScripts\install.bat"; Description: "启动安装后初始化"; StatusMsg: "正在执行安装后[install]进程，请稍候..."; Flags: skipifdoesntexist runhidden
;Filename: "{app}\installerScripts\info.bat"; Description: "启动安装后初始化"; StatusMsg: "正在执行安装后[info]进程，请稍候..."; Flags: skipifdoesntexist runhidden
Filename: "cmd.exe"; Parameters: "/c lisa zep install"; Flags: nowait postinstall skipifsilent runascurrentuser; 

[Code]

function MyDestDir(SubDir:String):String;
begin
  Result := ExpandConstant('{userappdata}')
end;

function ModPathDir(): TArrayOfString;
var
  Dir:	TArrayOfString;
begin
  setArrayLength(Dir, 1)  //此处的1代表添加1个路径
  Dir[0] := ExpandConstant('{app}\lisa\bin');
  Result := Dir;
end;

function getNewPath(oldPath,addPath:String):String;
var
	newpath:	String;
  i:		Integer;
  pathArr:	TArrayOfString;
begin
  oldpath := oldpath + ';';
  i := 0;
  while (Pos(';', oldpath) > 0) do begin
    //获取Path路径中的一个路径，并判断与要添加的路径是否相等
    SetArrayLength(pathArr, i+1);
    pathArr[i] := Copy(oldpath, 0, Pos(';', oldpath)-1);
    oldpath := Copy(oldpath, Pos(';', oldpath)+1, Length(oldpath));
    i := i + 1;
    if addPath = pathArr[i-1] then begin //若路径已存在
      if IsUninstaller() = true then begin  //若为卸载，则删除目录
        continue;
      end else begin  //若为安装，则停止重复添加路径
        abort;
      end;
    end;
    //将所有应保留的路径存入newpath
    if i = 1 then begin
      newpath := pathArr[i-1];
    end else begin
      newpath := newpath + ';' + pathArr[i-1];
    end;
  end; 
  // 获得Path新路径newpath
  if IsUninstaller() = false then  //若为安装，则加入此路径
    newpath := addPath + ';' + newpath;
    Result := newpath
end;

procedure ModPath();
var
	oldpath:	String;
	newpath:	String;
	aExecFile:	String;
	aExecArr:	TArrayOfString;
	i, d:		Integer;
  pathArr:	TArrayOfString;
  pathdir:	TArrayOfString;
begin  	
	pathdir := ModPathDir();  //获取软件安装路径到pathdir
	for d := 0 to GetArrayLength(pathdir)-1 do begin //逐一添加路径
   //若为winNT内核。winXP,win7,win8,win10都有winNT内核        
		if UsingWinNT() = true then begin
      //添加或删除用户环境变量Path中的路径
			RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', oldpath);//获取当前路径 
			newpath := getNewPath(oldpath,pathdir[d]);                             //获取添加路径后的新路径 			
			RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', newpath);// 将新路径添加写入环境变量中
      //添加或删除用户环境变量Path中的路径
     	//获取当前路径
			RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'Path', oldpath);
      newpath := getNewPath(oldpath,pathdir[d]);                             //获取添加路径后的新路径
			// 将新路径添加写入环境变量中
			RegWriteStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'Path', newpath);   

		//若为win9X内核，可能只添加入系统环境变量Path
		end else begin

			// Convert to shortened dirname
			pathdir[d] := GetShortName(pathdir[d]);

			// If autoexec.bat exists, check if app dir already exists in path
			aExecFile := 'C:\AUTOEXEC.BAT';
			if FileExists(aExecFile) then begin
				LoadStringsFromFile(aExecFile, aExecArr);
				for i := 0 to GetArrayLength(aExecArr)-1 do begin
					if IsUninstaller() = false then begin
						// If app dir already exists while installing, abort add
						if (Pos(pathdir[d], aExecArr[i]) > 0) then
							abort;
					end else begin
						// If app dir exists and = what we originally set, then delete at uninstall
						if aExecArr[i] = 'SET PATH=%PATH%;' + pathdir[d] then
							aExecArr[i] := '';
					end;
				end;
			end;

			// If app dir not found, or autoexec.bat didn't exist, then (create and) append to current path
			if IsUninstaller() = false then begin
				SaveStringToFile(aExecFile, #13#10 + 'SET PATH=%PATH%;' + pathdir[d], True);

			// If uninstalling, write the full autoexec out
			end else begin
				SaveStringsToFile(aExecFile, aExecArr, False);
			end;
		end;

		// Write file to flag modifypath was selected
		//   Workaround since IsTaskSelected() cannot be called at uninstall and AppName and AppId cannot be "read" in Code section
		if IsUninstaller() = false then
			SaveStringToFile(ExpandConstant('{app}') + '\uninsTasks.txt', WizardSelectedTasks(False), False);
	end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
	if CurStep = ssPostInstall then
		if WizardIsTaskSelected('modifypath') then
			ModPath();
end;
