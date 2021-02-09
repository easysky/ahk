;============================================================
; 组件初始段代码应包含：
; 1、加入组件计数变量： _LIB_COUNT+=1
; 2、加入扩展功能序列号（可选）： _LIB_SETINDEX+=1
; 3、加入添加到主程序的菜单。菜单分两类：
; 	_Menu_LIBSET——组件设置菜单；
;	SubMenu_Extend——扩展功能菜单
;============================================================

#NoTrayIcon
#SingleInstance Ignore
#NoEnv
CoordMode,Mouse,Screen
CoordMode,ToolTip,Screen
CoordMode,Pixel,Screen
SetWorkingDir %A_ScriptDir%
Global _INI_PATH:=A_ScriptDir . "\z" . (A_Is64BitOs?"64":"32") . "_" . A_UserName . ".ini"	;配置文件
,dir_Lib:=A_ScriptDir . "\Lib"	;组件目录
,path_LibList:=A_ScriptDir . "\_zList.inc"	;已启用组件列表（该文件自动生成）
,path_LibInit:=A_ScriptDir . "\_zInit.inc"	;已启用组件加载代码（该文件自动生成）
,dir_Scripts:=A_ScriptDir . "\Scripts"	;附加脚本目录
,_INI_Scripts:=A_ScriptDir . "\Scripts\Data\exScriptSet.ini"	;附加脚本配置文件
,_LIB_COUNT:=0	;已启用的组件数量。此全局变量值需在组件中计数（+1）
,_LIB_SETINDEX:=1	;添加到扩展中的菜单序号。此全局变量值需在组件中计数（+1）
,_App_NAME:=SubStr(A_ScriptName,1,-4)	;程序/文件名
,mWALeft,mWABottom

_VERSION:="v0.3.2"	;定义版本变量(升级时仅改动此处)
;;获取系统信息
SysGet,_HEIGHT_OF_TITLEBAR,4	;标题栏高度
SysGet,mWA,MonitorWorkArea	;工作区大小
;lsbColor:=ColorHex(DllCall("GetSysColor","Int",15))	;窗口默认背景颜色

;检测必需文件
If !(getStr1:=FileExist(path_LibList)) Or !(getStr2:=FileExist(path_LibInit))
{
	If !getStr1
		FileAppend,,%path_LibList%,UTF-8
	If !getStr2
		FileAppend,,%path_LibInit%,UTF-8
	Reload
}
getStr1:=getStr2:=""

; ------------- 读取配置 -----

;菜单图标显隐状态
IniRead,b_HMI,%_INI_PATH%,General,HideMenuIcons,0
If b_HMI not in 0,1
	b_HMI:=0

;托盘图标显隐状态
IniRead,b_HTI,%_INI_PATH%,General,HideTrayIcon,0
If b_HTI not in 0,1
	b_HTI:=0

;隐藏窗口参数 初始化
Global arr_HiddenWin:=[]
IniRead,tempStr,%_INI_PATH%,HiddenWin
If (tempStr<>""){
	Loop,Parse,tempStr,`n
	{
		Loop,Parse,A_LoopField,=
			getStr%A_Index%:=Trim(A_LoopField)
		If (getStr1="") Or (getStr2="") Or !WinExist("Ahk_Id " getStr1)
			Continue
		arr_HiddenWin.Push(["w_" . getStr1,getStr2])
	}
	IniDelete,%_INI_PATH%,HiddenWin
}
tempStr:=getStr1:=getStr2:=""

;搜索选中文本初始化
IniRead,str_SSTEngine,%_INI_PATH%,General,SearchEngine,%A_Space%
str_SSTEngine=%str_SSTEngine%
	
;音量调节幅度
IniRead,_Snd_Count,%_INI_PATH%,General,VolumeRange,5
If RegexMatch(_Snd_Count,"[^\d]") Or (_Snd_Count<1) Or (_Snd_Count>50)
	_Snd_Count:=5

;窗口透明度
IniRead,_Trans_Value,%_INI_PATH%,General,WinTransValue,128
If RegexMatch(_Trans_Value,"[^\d]") Or (_Trans_Value<1) Or (_Trans_Value>255)
	_Trans_Value:=128

; ------------- 托盘菜单 -----

Menu,Tray,NoStandard
Menu,Tray,Add,快速程序菜单,ahk_ShowAppList
Menu,Tray,Icon,快速程序菜单,shell32.dll,-255
Menu,Tray,Add
Menu,Tray,Add,鼠标菜单触发设置,MouseMenuSet_Win
Menu,Tray,Add
Menu,_Menu_LIBSET,Add,组件状态管理,cmd_LibSwitch
Menu,_Menu_LIBSET,Add,
Menu,Tray,Add,组件设置,:_Menu_LIBSET
Menu,Tray,Add
Menu,Tray,Add,隐藏菜单图标,cmd_ToggleMenuIcon
Menu,Tray,Add,隐藏托盘图标,ahk_ToggleTrayIcon
Menu,Tray,Check,隐藏托盘图标
Menu,Tray,Add
;创建可编辑文件列表二级菜单
		Loop,Files,%dir_Lib%\*.ahk,F
			Menu,menu_Lib,Add,%A_Index%- %A_LoopFileName%,cmd_EditLib
		Loop,Files,%dir_Scripts%\*.ahk,F
			Menu,menu_Script,Add,%A_Index%- %A_LoopFileName%,cmd_EditScript
		SplitPath,_INI_PATH,tempStr
		Menu,menu_IniSet,Add,%tempStr%,cmd_EditSet
		SplitPath,_INI_Scripts,tempStr
		Menu,menu_IniSet,Add,%tempStr%,cmd_EditSet
		tempStr=
;创建可编辑文件列表一级菜单
	Menu,menu_Edit,Add,主脚本%A_Space%%A_ScriptName%,cmd_EditMain
	Menu,menu_Edit,Add
	Menu,menu_Edit,Add,组件,:menu_Lib
	Menu,menu_Edit,Add,附加脚本,:menu_Script
	Menu,menu_Edit,Add,
	Menu,menu_Edit,Add,配置,:menu_IniSet
Menu,Tray,Add,编辑源码,:menu_Edit
Menu,Tray,Add
Menu,Run_User,Add,当前用户,cmd_AddToAutoRun
Menu,Run_User,Add,所有用户,cmd_AddToAutoRun
Menu,Run_User,Add
Menu,Run_User,Add,关闭,cmd_AddToAutoRun
Menu,Tray,Add,随系统启动,:Run_User
Menu,Tray,Add
Menu,Tray,Add,关于 zBox,cmd_About
Menu,Tray,Add
Menu,Tray,Add,禁用,ahk_Suspend
Menu,Tray,Add,退出,cmd_Exit
Menu,Tray,Add
Menu,Tray,Add,重载,cmd_Reload

Menu,Tray,Default,快速程序菜单
Menu,Tray,Click,1
Menu,Tray,Tip,%_App_NAME% %_VERSION% by Cui
Menu,Tray,Icon,shell32.dll,-242

If b_HMI
	Menu,Tray,Check,隐藏菜单图标
If !b_HTI
{
	Menu,Tray,UnCheck,隐藏托盘图标
	Menu,Tray,Icon
}

; ------------- 创建副菜单 -----

Gosub sub_CreatToolsMenu
Gosub sub_CreatExtendMenu

; ------------- 加载组件 -----

#Include %A_ScriptDir%
#Include *i _zInit.inc

; ------------- 创建主菜单 -----

Gosub sub_CreatBasicMenu

; ------------- 检测 开机启动 -----

Is_ScriptAutoRun:=0,str_Sname:=SubStr(A_ScriptName,1,-4)
Try
{
	RegRead,tempStr,Hkcu\SOFTWARE\Microsoft\Windows\CurrentVersion\Run,%str_Sname%
	If (tempStr=A_ScriptFullPath){
		Is_ScriptAutoRun:=1
		Menu,Run_User,Check,1&
	}
}Catch{
	Try
	{
		RegRead,tempStr,HKLM,SOFTWARE\Microsoft\Windows\CurrentVersion\Run,%str_Sname%
		If (tempStr=A_ScriptFullPath)
		{
			Menu,Run_User,Check,2&
			Is_ScriptAutoRun:=2
		}
	}Catch
		Menu,Run_User,Check,4&
}
str_Sname:=tempStr:=""

; ------------- 加载鼠标菜单触发设置 -----

IniRead,Mouse_Trigger,%_INI_PATH%,General,MouseMenuTrigger,PSDT
If RegexMatch(Mouse_Trigger,"i)[^PSDT]")
	Mouse_Trigger:="PSDT"

; ------------- 其他 -----

EmptyMem()
SetTimer,EmptyMem,600000
OnExit("ExitFunc")
Return

; ------------- 菜单命令 -----

cmd_ToggleMenuIcon:
Menu,Tray,ToggleCheck,隐藏菜单图标
arr_Apps:=[],b_HMI:=1-b_HMI,func_ShowInfoTip((b_HMI?"隐藏":"显示") . "菜单图标，即将重启脚本后生效"),nCount:=A_TickCount
IniWrite,%b_HMI%,%_INI_PATH%,General,HideMenuIcons
Loop
{
	If (A_TickCount-nCount>2000)
		Break
}
Reload
Return

cmd_About:
Menu,Tray,Disable,%A_ThisMenuItem%
;FileGetTime,tempStr,%A_ScriptFullPath%
;FormatTime,tempStr,%tempStr%,yyyy/M/d HH:mm:ss
help_word=
(
%_App_NAME% %_VERSION% (2021-2-9)
Copyright © 2013-%A_yyyy% by Cui@Easysky
Powered by AutoHotkey (https://autohotkey.com)
`nE-mail: easysky@foxmail.com
QQ: 3121356095#easysky
`n系统 AutoHotkey 版本: %A_AhkVersion%
脚本主窗口HWND: %A_ScriptHwnd%
`n主脚本及组件包含文件：
%A_ScriptFullPath%
%path_LibList%
%path_LibInit%
`n组件目录：
%dir_Lib%
`n附加脚本目录及数据目录：
%dir_Scripts%
%dir_Scripts%\Data
`n配置文件：
%_INI_PATH%
%_INI_Scripts%
)
Gui,+OwnDialogs
MsgBox,262208,关于 zBox,%help_word%
Menu,Tray,Enable,%A_ThisMenuItem%
help_word:=tempStr:=""
Return

cmd_Exit:
Gui,+OwnDialogs
MsgBox,262180,退出程序,确定要退出 %_App_NAME% 程序？
IfMsgBox,Yes
	ExitApp
Return

cmd_Reload:
Reload
Return

cmd_SysTools:
If (A_ThisMenuItemPos=1)
	tempStr:="Control"
Else If (A_ThisMenuItemPos=3)
	tempStr:="taskmgr.exe"
Else If (A_ThisMenuItemPos=4)
	tempStr:="explorer.exe"
Else If (A_ThisMenuItemPos=6)
	tempStr:="compmgmt.msc"
Else If (A_ThisMenuItemPos=7)
	tempStr:="devmgmt.msc"
Else If (A_ThisMenuItemPos=8)
	tempStr:="diskmgmt.msc"
Else If (A_ThisMenuItemPos=9)
	tempStr:="lusrmgr.msc"
Else If (A_ThisMenuItemPos=10)
	tempStr:="Control printers"
Else If (A_ThisMenuItemPos=12)
	tempStr:="cmd.exe"
Else If (A_ThisMenuItemPos=18)
	tempStr:="osk.exe"
Else If (A_ThisMenuItemPos=20){
	If (Is_ShowHiddenFiles=1)
		Is_ShowHiddenFiles:=2
	Else
		Is_ShowHiddenFiles:=1
	RegWrite,REG_DWORD,HKCU,Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced,Hidden,%Is_ShowHiddenFiles%
	Menu,SubMenu_Tools,% (Is_ShowHiddenFiles=1)?"check":"UnCheck",%A_ThisMenuItem%
	_iCount:=1
	setTimer,sub_UpdateSys,1000
}Else If (A_ThisMenuItemPos=21){
	Is_ShowSystemFiles:=1-Is_ShowSystemFiles
	RegWrite,REG_DWORD,HKCU,Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced,ShowSuperHidden,%Is_ShowSystemFiles%
	Menu,SubMenu_Tools,% Is_ShowSystemFiles?"check":"UnCheck",%A_ThisMenuItem%
	_iCount:=1
	setTimer,sub_UpdateSys,1000
}Else If (A_ThisMenuItemPos=22){
	Is_ShowFileExtension:=1-Is_ShowFileExtension
	RegWrite,REG_DWORD,HKCU,Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced,HideFileExt,%Is_ShowFileExtension%
	Menu,SubMenu_Tools,% Is_ShowFileExtension?"uncheck":"check",%A_ThisMenuItem%
	_iCount:=1
	setTimer,sub_UpdateSys,1000
}Else If (A_ThisMenuItemPos=24)
	Gosub ahk_CloseLCD
Else If (A_ThisMenuItemPos=25)
	Gosub ahk_LockPC
Else If (A_ThisMenuItemPos=26)
	Gosub ahk_CloseLCDAndLockPC
Else
	func_ShutDown(A_ThisMenuItemPos-27,A_ThisMenuItem)

If A_ThisMenuItemPos In 1,3,4,6,7,8,9,10,12,18
{
	Try
	{
		If (A_ThisMenuItemPos=12)
			Run,%tempStr%,% SubStr(A_Appdata,1,InStr(A_Appdata,"\",0,1,3)-1),,tempPID_CMD
		Else
			Run,%tempStr%
	}
	Catch
		func_ShowInfoTip("运行“" A_ThisMenuItem " [" tempStr "]”出错！",5000,,,0)
	tempStr=
}
Return

cmd_SysTools_1:
If (A_ThisMenuItemPos=1)
	tempStr:="appwiz.cpl"
Else If (A_ThisMenuItemPos=2)
	tempStr:="firewall.cpl"
Else If (A_ThisMenuItemPos=4)
	tempStr:="regedit.exe"
Else If (A_ThisMenuItemPos=5)
	tempStr:="msconfig.exe"
Else If (A_ThisMenuItemPos=6)
	tempStr:="services.msc"
Else If (A_ThisMenuItemPos=7)
	tempStr:="netplwiz"
Else If (A_ThisMenuItemPos=8)
	tempStr:="secpol.msc"
Else If (A_ThisMenuItemPos=10)
	tempStr:="eventvwr"
Else If (A_ThisMenuItemPos=11)
	tempStr:="dcomcnfg"
Else If (A_ThisMenuItemPos=12)
	tempStr:="certmgr.msc"
Else If (A_ThisMenuItemPos=13)
	tempStr:="perfmon.msc"
Else If (A_ThisMenuItemPos=15)
	tempStr:="cleanmgr"
Else If (A_ThisMenuItemPos=16)
	tempStr:="chkdsk.exe"
Else If (A_ThisMenuItemPos=17)
	tempStr:="sfc /scannow"
Else If (A_ThisMenuItemPos=18)
	tempStr:="sigverif"
Try
	Run,%tempStr%
Catch
	func_ShowInfoTip("运行“" A_ThisMenuItem " [" tempStr "]”出错！",5000,,,0)
tempStr=
Return

cmd_SysTools_2:
If (A_ThisMenuItemPos=1)
	tempStr:="ncpa.cpl"
Else If (A_ThisMenuItemPos=2)
	tempStr:="fsmgmt.msc"
Else If (A_ThisMenuItemPos=3)
	tempStr:="Nslookup"
Try
	Run,%tempStr%
Catch
	func_ShowInfoTip("运行“" A_ThisMenuItem " [" tempStr "]”出错！",5000,,,0)
tempStr=
Return

cmd_SysTools_3:
If (A_ThisMenuItemPos=1)
	tempStr:="timedate.cpl"
Else If (A_ThisMenuItemPos=2)
	tempStr:="intl.cpl"
Else If (A_ThisMenuItemPos=4)
	tempStr:="rundll32.exe shell32.dll,Control_RunDLL desk.cpl,,3"
Else If (A_ThisMenuItemPos=5)
	tempStr:="rundll32.exe shell32.dll,Control_RunDLL desk.cpl,,2"
Else If (A_ThisMenuItemPos=6)
	tempStr:="rundll32.exe shell32.dll,Control_RunDLL desk.cpl,,0"
Else If (A_ThisMenuItemPos=7)
	tempStr:="rundll32.exe shell32.dll,Control_RunDLL desk.cpl,,1"
Else If (A_ThisMenuItemPos=9)
	tempStr:="rundll32.exe shell32.dll,Control_RunDLL main.cpl @0"
Else If (A_ThisMenuItemPos=10)
	tempStr:="rundll32.exe shell32.dll,Control_RunDLL main.cpl @1"
Else If (A_ThisMenuItemPos=12)
	tempStr:="rundll32.exe shell32.dll,Control_RunDLL mmsys.cpl,,0"
Else If (A_ThisMenuItemPos=13)
	tempStr:="dxdiag"
Else If (A_ThisMenuItemPos=15)
	tempStr:="magnify"
Else If (A_ThisMenuItemPos=16)
	tempStr:="narrator"
Else If (A_ThisMenuItemPos=18)
	tempStr:="eudcedit"
Else If (A_ThisMenuItemPos=19)
	tempStr:="charmap"
Else If (A_ThisMenuItemPos=21)
	tempStr:="winver"
Try
	Run,%tempStr%
Catch
	func_ShowInfoTip("运行“" A_ThisMenuItem " [" tempStr "]”出错！",5000,,,0)
tempStr=
Return

cmd_AddToAutoRun:
Gui,+OwnDialogs
If !A_IsAdmin
{
	func_ShowInfoTip("非管理员账户无法操作注册表！",,,,0)
	Return
}
tempStr:=(A_ThisMenuItemPos=4)?0:A_ThisMenuItemPos
If (tempStr=Is_ScriptAutoRun)
	Return
tempText:=SubStr(A_ScriptName,1,-4)
If (Is_ScriptAutoRun<>0){	;将要开机启动
	RegDelete,% (Is_ScriptAutoRun=1)?"HKCU":"HKLM",SOFTWARE\Microsoft\Windows\CurrentVersion\Run,%tempText%
	If ErrorLevel
	{
		func_ShowInfoTip("设置启动项出错！`n`n请检查后重试！",,,,0)
		Return
	}
	Menu,Run_User,UnCheck,% (Is_ScriptAutoRun=1)?"当前用户":"所有用户"
}
If (tempStr=0){
	func_ShowInfoTip("程序已成功从 [" . ((Is_ScriptAutoRun=1)?"当前用户":"所有用户") .  "] 启动项中删除！")
	Menu,Run_User,Check,关闭
}Else{
	RegWrite,REG_SZ,% (tempStr=1)?"HKCU":"HKLM",SOFTWARE\Microsoft\Windows\CurrentVersion\Run,%tempText%,%A_ScriptFullPath%
	If ErrorLevel
		func_ShowInfoTip("添加到启动项出错！`n`n请检查后重试！",,,,0)
	Else{
		func_ShowInfoTip("程序已成功添加到 [" A_ThisMenuItem "] 启动项！",2500)
		Menu,Run_User,Check,%A_ThisMenuItem%
		Menu,Run_User,UnCheck,关闭
	}
}
Is_ScriptAutoRun:=tempStr,tempStr:=tempText:=""
Return

cmd_Scripts:
Try
	Run,% arr_Scripts[A_ThisMenuItemPos]
Catch
	func_ShowInfoTip("执行附加脚本出错！",5000,,,0)
Return

; ------------- 创建菜单 -----

sub_CreatExtendMenu:
Menu,SubMenu_Extend,Add,搜索引擎设置,SearchSelText_Set
Menu,SubMenu_Extend,Add,音量调节幅度设置,Volume_Set
Menu,SubMenu_Extend,Add,窗口透明度设置,WinTrans_Set
If !b_HMI
{
	Menu,SubMenu_Extend,Icon,1&,shell32.dll,-281
	Menu,SubMenu_Extend,Icon,2&,shell32.dll,-277
	Menu,SubMenu_Extend,Icon,3&,shell32.dll,-35
}
Menu,SubMenu_Extend,Add,
Menu,Menu_HiddenWinList,Add,还原所有隐藏窗口,cmd_HiddenWin
Menu,Menu_HiddenWinList,Add,
If (arr_HiddenWin.Length()=0)
	Menu,Menu_HiddenWinList,Disable,还原所有隐藏窗口
Else{
	Loop,% arr_HiddenWin.Length()
		Menu,Menu_HiddenWinList,Add,% arr_HiddenWin[A_index][2],cmd_HiddenWin
}
Menu,SubMenu_Extend,Add,1 - 隐藏窗口列表,:Menu_HiddenWinList
Return

sub_CreatToolsMenu:
Menu,SubMenu_Tools,Add,控制面板首页,cmd_SysTools
Menu,SubMenu_Tools,Add,
Menu,SubMenu_Tools,Add,任务管理器,cmd_SysTools
Menu,SubMenu_Tools,Add,资源管理器,cmd_SysTools
Menu,SubMenu_Tools,Add
Menu,SubMenu_Tools,Add,计算机管理,cmd_SysTools
Menu,SubMenu_Tools,Add,设备管理,cmd_SysTools
Menu,SubMenu_Tools,Add,磁盘管理,cmd_SysTools
Menu,SubMenu_Tools,Add,本地用户管理,cmd_SysTools
Menu,SubMenu_Tools,Add,打印机和传真,cmd_SysTools
Menu,SubMenu_Tools,Add,
Menu,SubMenu_Tools,Add,CMD 命令提示符 +,cmd_SysTools
Menu,SubMenu_Tools,Add,
Menu,SubMenu_Tools_1,Add,安装/卸载程序,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,Windows 防火墙,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add
Menu,SubMenu_Tools_1,Add,注册表编辑器,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,系统配置实用程序,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,服务管理,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,本地用户管理「高级」,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,本地安全策略,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,
Menu,SubMenu_Tools_1,Add,事件查看器,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,系统组件服务,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,证书管理,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,性能监视器,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,
Menu,SubMenu_Tools_1,Add,磁盘垃圾整理,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,磁盘检查,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,系统文件检查与修复,cmd_SysTools_1
Menu,SubMenu_Tools_1,Add,文件签名验证,cmd_SysTools_1
Menu,SubMenu_Tools,Add,系统工具,:SubMenu_Tools_1

Menu,SubMenu_Tools_2,Add,网络连接管理,cmd_SysTools_2
Menu,SubMenu_Tools_2,Add,共享文件夹管理,cmd_SysTools_2
Menu,SubMenu_Tools_2,Add,IP 地址侦测器,cmd_SysTools_2
Menu,SubMenu_Tools,Add,网络工具,:SubMenu_Tools_2

Menu,SubMenu_Tools_3,Add,调整时间/日期,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,区域和语言选项,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,
Menu,SubMenu_Tools_3,Add,显示器设置,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,屏幕外观设置,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,桌面图标设置,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,屏幕保护设置,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,
Menu,SubMenu_Tools_3,Add,鼠标属性设置,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,键盘属性设置,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,
Menu,SubMenu_Tools_3,Add,声音设置,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,DirectX 信息,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,
Menu,SubMenu_Tools_3,Add,放大镜,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,屏幕“讲述人” ,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,
Menu,SubMenu_Tools_3,Add,专用字符编辑程序,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,字符映射表,cmd_SysTools_3
Menu,SubMenu_Tools_3,Add,
Menu,SubMenu_Tools_3,Add,Windows 版本,cmd_SysTools_3
Menu,SubMenu_Tools,Add,其他工具,:SubMenu_Tools_3

Menu,SubMenu_Tools,Add,
Menu,SubMenu_Tools,Add,屏幕键盘,cmd_SysTools
Menu,SubMenu_Tools,Add,
Menu,SubMenu_Tools,Add,显示隐藏的文件/文件夹,cmd_SysTools
Menu,SubMenu_Tools,Add,显示受保护的系统文件,cmd_SysTools
Menu,SubMenu_Tools,Add,显示文件扩展名,cmd_SysTools
Menu,SubMenu_Tools,Add,
Menu,SubMenu_Tools,Add,关闭显示器,cmd_SysTools
Menu,SubMenu_Tools,Add,锁定计算机,cmd_SysTools
Menu,SubMenu_Tools,Add,锁定计算机并关闭显示器,cmd_SysTools
Menu,SubMenu_Tools,Add,
Menu,SubMenu_Tools,Add,注销系统,cmd_SysTools
Menu,SubMenu_Tools,Add,重启系统,cmd_SysTools
Menu,SubMenu_Tools,Add,关闭系统,cmd_SysTools
Return

sub_CreatBasicMenu:
Menu,G1,Add,系统控制管理,:SubMenu_Tools
Menu,G1,Add,扩展功能与设置,:SubMenu_Extend
If FileExist(dir_Scripts . "\*.ahk")
{
	arr_Scripts:=[]
	Loop,Files,%dir_Scripts%\*.ahk
	{
		FileReadLine,tempStr,%A_LoopFileLongPath%,1
		Menu,ex_Script,Add,% A_Index " - " ((ErrorLevel Or !RegexMatch(tempStr,"i)^;\s*@title:\s*(.*)",getStr))?A_LoopFileName:getStr1),cmd_Scripts
		arr_Scripts.push(A_LoopFileLongPath)
	}
	tempStr:=getStr:=getStr1:=""
	Menu,G1,Add,自定义脚本,:ex_Script
	If !b_HMI
		Menu,G1,Icon,自定义脚本,shell32.dll,-242
}
Menu,G1,Add,
Menu,G1,Add,程序选项,:Tray
If !b_HMI	;添加图标到主菜单
{
	Menu,G1,Icon,系统控制管理,SHELL32.dll,-137
	Menu,G1,Icon,扩展功能与设置,SHELL32.dll,-239
	Menu,G1,Icon,程序选项,SHELL32.dll,-153
}
Return

;增强 CMD 命令提示符
#if WinActive("Ahk_Pid " . tempPID_CMD)
~Lbutton::
If (A_ThisHotkey=A_PriorHotkey) and (A_TimeSincePriorHotkey<300)
	SendInput {Rbutton}k
Return
^c::SendInput {Enter}
^v::SendInput %Clipboard%
^x::
WinGetTitle,tempStr,Ahk_Pid %tempPID_CMD%
If (SubStr(Trim(tempStr),1,2)="选定"){
	SendInput {Enter}
	tempStr:=StrLen(Clipboard)
	SendInput {BackSpace %tempStr%}
}
tempStr=
Return
#if

; ------------- 内部功能组成部分 -----

sub_getSetFrReg:
;获取系统文件设置（隐藏/保护文件/扩展名显隐）
RegRead,Is_ShowHiddenFiles,HKCU,Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced,Hidden
Menu,SubMenu_Tools,% (!ErrorLevel And (Is_ShowHiddenFiles=1))?"Check":"UnCheck",显示隐藏的文件/文件夹
RegRead,Is_ShowSystemFiles,HKCU,Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced,ShowSuperHidden
Menu,SubMenu_Tools,% (!ErrorLevel And (Is_ShowSystemFiles=1))?"Check":"UnCheck",显示受保护的系统文件
RegRead,Is_ShowFileExtension,HKCU,Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced,HideFileExt
Menu,SubMenu_Tools,% (!ErrorLevel And (Is_ShowFileExtension=0))?"Check":"UnCheck",显示文件扩展名
Return

sub_HideTray:
tempStr:=dir_Lib . "\Hotkeys.ahk",errFlag:=0
If FileExist(tempStr)
{
	Loop,Read,%tempStr%
	{
		If InStr(A_LoopReadLine,"ahk_ToggleTrayIcon")
		{
			RegexMatch(Trim(A_LoopReadLine),"^([^:]+)::.*$",s),s1:=Trim(s1)
			Break
		}
	}
	If (s1="") Or (SubStr(s1,1,1)=";")
		errFlag:=1
}Else
	errFlag:=1
func_ShowInfoTip("即将隐藏程序托盘图标"  . (errFlag?" ……":("。使用以下快捷键恢复:`n" . keys_Switch(s1,0))),5000),s:=s1:=tempStr:=errFlag:=""
SetTimer,sub_RemoveTrayIcon,-5000
Return

sub_RemoveTrayIcon:
Menu,Tray,NoIcon
Menu,Tray,Check,隐藏托盘图标
IniWrite,1,%_INI_PATH%,General,HideTrayIcon
Return

sub_UpdateSys:
If (_iCount>=10){
	SetTimer,sub_UpdateSys,Off
	_iCount:=1
}Else{
	WinGetClass,curr_Class,A
	If curr_Class In Progman,CabinetWClass,ExploreWClass
	{
		SendInput {F5}
		SetTimer,sub_UpdateSys,Off
		_iCount:=1
	}Else
		_iCount+=1
	curr_Class=
}
Return

func_ShutDown(i,s){
	Gui,+OwnDialogs
	MsgBox,262196,确认操作,确定要 %s% ？,10
	IfMsgBox,Yes
	{
		If (i=1)
			Shutdown,0
		Else If (i=2)
			Shutdown,2
		Else If (i=3)
			Shutdown,9
	}
}

EmptyMem:
EmptyMem()
Return

RemoveToolTip:
ToolTip
Return

RemoveTrayTip:
TrayTip
Return

RemoveSplashImg:
SplashImage,Off
Return

#If WinExist(_App_NAME "_TIPINFO_WIN")
~Lbutton Up::
SplashImage,Off
Return
#if

;挂起
^!+Insert::
+Pause::
ahk_Suspend:
Suspend
func_ShowInfoTip(_App_NAME " 已" . (A_IsSuspended?"禁用":"启用") . "`n可使用 Shift+Pause、Ctrl+Alt+Shift+Insert 键切换状态",3500,450)
Menu,Tray,Rename,% A_IsSuspended?"禁用":"启用",% A_IsSuspended?"启用":"禁用"
Return


; ------------- 外部功能 -----

;;;重启程序
ahk_ReloadScript:
Reload
Return

;弹出系统主菜单
ahk_ShowMainMenu:
Menu,Tray,Show
Return

;弹出快速程序菜单
ahk_ShowAppList:
Gosub sub_getSetFrReg
Menu,G1,Show
Return

;弹出系统控制管理菜单
ahk_ShowSysContrl:
Menu,SubMenu_Tools,Show
Return

;弹出扩展功能与设置菜单
ahk_ShowExtendMenu:
Menu,SubMenu_Extend,Show
Return

;关闭显示器/锁定电脑
ahk_CloseLCD:
ahk_LockPC:
ahk_CloseLCDAndLockPC:
func_ShowInfoTip("即将" . ((A_ThisLabel="ahk_CloseLCD")?"关闭显示器":((A_ThisLabel="ahk_LockPC")?"锁定计算机":"锁定计算机并关闭显示器")))
tempStr:=A_TickCount
Loop
{
	If (A_TickCount-tempStr>1000)
		Break
}
tempStr=
If A_ThisLabel In ahk_CloseLCD,ahk_CloseLCDAndLockPC
	SendMessage,0x112,0xF170,2,,Program Manager
If A_ThisLabel In ahk_LockPC,ahk_CloseLCDAndLockPC
	Run,rundll32.exe user32.dll`,LockWorkStation
;BlockInput,Off
; 0x112 is WM_SYSCOMMAND,0xF170 is SC_MONITORPOWER.
; Note for the above: Use -1 in place of 2 to turn the monitor on.
; Use 1 in place of 2 to activate the monitor's low-power mode.
Return

ahk_ToggleTrayIcon:
;;;显示/隐藏程序托盘图标
If !A_IconHidden
	GoSub sub_HideTray
Else{
	Menu,Tray,Icon
	Menu,Tray,UnCheck,隐藏托盘图标
	IniWrite,0,%_INI_PATH%,General,HideTrayIcon
}
Return

;清空剪贴板
ahk_ClearClip:
Clipboard=
func_ShowInfoTip("剪贴板内容已清空",1500,200)
Return

;-╔══ 搜索选中文本 ══╗

ahk_SearchSelText:
_MultiSearch(getStrFromClip())
Return

SearchSelText_Set:
If IsWin_SearchSelTextSet_Show
	Return
If (str_SSTEngine<>""){
	tempStr=
	Loop,Parse,str_SSTEngine,|
	{
		tempText:=Trim(A_LoopField)
		If (tempText="")
			Continue
		tempStr .= StrReplace(tempText,"∥","|") . "`n"
	}
	tempStr:=SubStr(tempStr,1,-1)
}Else
	tempStr:="~https://cn.bing.com/search?q=%s`n~https://www.dogedoge.com/results?q=%s`n~https://magi.com/search?q=%s`n~https://mengso.com/search?q=%s"

Gui,SST_Win:New
Gui,SST_Win:-MinimizeBox +HwndSST_ID +AlwaysOnTop +Owner
Gui,SST_Win:Font,,Tahoma
Gui,SST_Win:Font,,微软雅黑
Gui,SST_Win:Add,Text,x10 y8,※ 支持定义多个搜索引擎，按行分隔；用“`%s”代替搜索关键词(&E)：`n%A_Space%%A_Space%在每行开头加上半角“!”或“~”可临时禁用该搜索引擎。
Gui,SST_Win:Add,Edit,x10 y50 w400 h165 HScroll vSST_Box,%tempStr%
Gui,SST_Win:Add,Link,x12 y230 gSST_Info,<a>→ 示例</a>
Gui,SST_Win:Add,Text,x70 y230,（默认百度搜索引擎）
Gui,SST_Win:Add,Button,x225 y225 w100 gSST_Save,保存(&S)
Gui,SST_Win:Add,Button,x330 y225 w80 gSST_Cancel,取消(&C)
Gui,SST_Win:Show,,自定义搜索引擎
tempText:=tempStr:="",IsWin_SearchSelTextSet_Show:=1
Return

SST_Info:
Gui,SST_Win:+OwnDialogs
MsgBox,262208,添加搜索引擎示例,
(
如同时使用 百度 与 Bing 进行搜索，可按如下格式填写：
`nhttp://www.baidu.com/s?&wd=`%s
http://cn.bing.com/search?q=`%s
`n如只想使用 百度 而同时保留 Bing，则改成以下格式：
`nhttp://www.baidu.com/s?&wd=`%s
!http://cn.bing.com/search?q=`%s
`n移除前面的“!”以后即可再次启用 Bing 搜索引擎。
)
Return

SST_Save:
GuiControlGet,tempStr,SST_Win:,SST_Box
tempStr:=Trim(tempStr,"`r`n `t")
If (tempStr="") And (str_SSTEngine<>"")
{
	IniDelete,%_INI_PATH%,General,SearchEngine
	Gosub SST_WinGuiClose
	str_SSTEngine=
	Return
}
Gosub SST_WinGuiClose
tempStr_SSTEngine=
Loop,Parse,tempStr,`n
{
	tempText:=Trim(A_LoopField)
	If (tempText="")
		Continue
	tempStr_SSTEngine .= StrReplace(tempText,"|","∥") . "|"
}
tempStr_SSTEngine:=SubStr(tempStr_SSTEngine,1,-1)
If (tempStr_SSTEngine=str_SSTEngine){
	tempStr_SSTEngine:=tempText:=tempStr:=""
	Return
}
IniWrite,%tempStr_SSTEngine%,%_INI_PATH%,General,SearchEngine
str_SSTEngine:=tempStr_SSTEngine,tempStr_SSTEngine:=""
Return

SST_Cancel:
SST_WinGuiClose:
SST_WinGuiEscape:
Gui,SST_Win:Destroy
IsWin_SearchSelTextSet_Show:=0
Return

_MultiSearch(s){
;多引擎搜素
	Global str_SSTEngine
	If (s="")
		Return
	If (str_SSTEngine="")
		Run,http://www.baidu.com/s?wd=%s%
	Else{
		Loop,Parse,str_SSTEngine,|
		{
			r:=Trim(A_LoopField)
			If (r="") Or (SubStr(r,1,1)="!") Or (SubStr(r,1,1)="~")
				Continue
			If (SubStr(r,1,4)<>"http")
				r:="http://" . r
			Run,% StrReplace(StrReplace(r,"^","|"),"`%s",s)
		}
	}
}

;-╚══ 搜索选中文本 ══╝

;打开选中网址
ahk_BrowseSelUrl:
tempStr:=getStrFromClip()
If (tempStr="")
	Return
If (SubStr(tempStr,1,4)<>"http")
	tempStr:="http://" . tempStr
Run,%tempStr%
tempStr=
Return

;-╔══ 隐藏窗口 ══╗

ahk_HideThisWin:
WinGet,curr_ID,ID,A
WinGetClass,curr_Class,Ahk_Id %curr_ID%
If curr_Class in Progman,WorkerW,Shell_TrayWnd,BaseBar,#32770,#32768
{
	curr_ID:=curr_Class:=""
	Return
}
WinGetTitle,curr_Title,Ahk_Id %curr_ID%
If (curr_Title="")
	curr_Title:=curr_Class
If !IsObject(arr_HiddenWin)
	arr_HiddenWin:=[]
curr_Title:=_Text_Cut(curr_Title),arr_HiddenWin.Push(["w_" . curr_ID,curr_Title])
Menu,Menu_HiddenWinList,Add,%curr_Title%,cmd_HiddenWin
WinHide,ahk_id %curr_ID%
If (arr_HiddenWin.Length()>0)
	Menu,Menu_HiddenWinList,Enable,还原所有隐藏窗口
curr_ID:=curr_Title:=""
Return

;显示隐藏窗口菜单
ahk_HiddenWinMan:
Menu,Menu_HiddenWinList,Show
Return

;还原点击的隐藏窗口
cmd_HiddenWin:
If (A_ThisMenuItemPos=1)
	Gosub restoreAllHiddenWins
Else{
	tempStr:=SubStr(arr_HiddenWin.RemoveAt(A_ThisMenuItemPos-2)[1],3)
	Try
	{
		WinShow,Ahk_Id%tempStr%
		WinActivate,Ahk_Id%tempStr%
	}Catch
		func_ShowInfoTip("窗口“" arr_HiddenWin[A_index][2] "”不存在或已经显示。",3000,,,0)
	Menu,Menu_HiddenWinList,Delete,%A_ThisMenuItem%
	If (arr_HiddenWin.Length()=0)
		Gosub clear_HiddenWins
	tempStr=
}
Return

;还原所有隐藏窗口
restoreAllHiddenWins:
Loop,% arr_HiddenWin.Length()
{
	tempStr:=SubStr(arr_HiddenWin[A_index][1],3)
	Try
	{
		WinShow,Ahk_Id%tempStr%
		WinActivate,Ahk_Id%tempStr%
	}Catch
		func_ShowInfoTip("无法显示窗口: " arr_HiddenWin[A_index][2],,,,0)
	Menu,Menu_HiddenWinList,Delete,% arr_HiddenWin[A_index][2]
}
Gosub clear_HiddenWins
tempStr=
Return

;还原所有隐藏窗口后的扫尾工作
clear_HiddenWins:
Menu,Menu_HiddenWinList,Disable,还原所有隐藏窗口
arr_HiddenWin:=[]
Return

;-╚══ 隐藏窗口 ══╝

;活动窗口置顶
ahk_TopOnThisWin:
WinGet,curr_ID,ID,A
If (curr_ID=TransWin_ID)
	Return
WinGetClass,curr_Class,ahk_id %curr_ID%
If curr_Class In Progman,WorkerW,Shell_TrayWnd,BaseBar,#32770,#32768
{
	curr_ID:=curr_Class:=""
	Return
}
WinGetTitle,tempStr,Ahk_Id %curr_ID%
WinGet,b_Flag,ExStyle,ahk_id %curr_ID%
WinSet,AlwaysOnTop,% (b_Flag & 0x8)?On:Off,ahk_id %curr_ID%
func_ShowInfoTip(((b_Flag & 0x8)?"✖ 窗口取消置顶" :"✔ 窗口已置顶") .  "！`n「" . tempStr . "」",3000)
curr_ID:=curr_Class:=tempStr:=b_Flag:=""
Return

;-╔══ 活动窗口透明 ══╗

ahk_TransparentThisWin:
WinGet,curr_ID,ID,A
If (curr_ID=TransWin_ID){
	curr_ID=
	Return
}
WinGetClass,tempStr,Ahk_Id %curr_ID%
If tempStr In Progman,WorkerW,#32768
{
	curr_ID:=tempStr:=""
	Return
}
WinGet,b_Flag,Transparent,ahk_id %curr_ID%
If (b_Flag="")	;未设置透明度
	WinSet,Transparent,%_Trans_Value%,ahk_id %curr_ID%
Else{
	WinSet,Transparent,255,ahk_id %curr_ID%
	WinSet,Transparent,Off,ahk_id %curr_ID%
}
WinGetTitle,tempStr,ahk_id %curr_ID%
func_ShowInfoTip("窗口“" . _Text_Cut(tempStr) . "”已" . ((b_Flag="")?"设为":"取消") . "透明" . ((b_Flag="")?(" [" . _Trans_Value . "]"):""),4000,500),curr_ID:=tempStr:=b_Flag:=""
Return

WinTrans_Set:
Gui,+OwnDialogs
InputBox,tempStr,设置窗口透明度（1-255）,,,280,100,,,,,%_Trans_Value%
If ErrorLevel
	Return
tempStr=%tempStr%
If RegexMatch(tempStr,"[^\d]") Or (tempStr<1) Or (tempStr>255)
{
	func_ShowInfoTip("仅支持输入数字，范围 1-255",,,,0)
	Return
}
If (tempStr<>_Trans_Value)
{
	IniWrite,%tempStr%,%_INI_PATH%,General,WinTransValue
	func_ShowInfoTip("窗口透明度值已设置为为 " tempStr "%",2500,300)
}
_Trans_Value:=tempStr,tempStr:=""
Return

;-╚══ 活动窗口透明 ══╝
;-╔══ 音量调节 ══╗

ahk_VolumeUp:
ahk_VolumeDown:
If get_SndMute()
{
	func_ShowInfoTip("已静音",500,100)
	Return
}
If (A_ThisLabel="ahk_VolumeUp")
	SoundSet,+%_Snd_Count%
Else
	SoundSet,-%_Snd_Count%
SoundGet,tempStr
func_ShowInfoTip("主音量" . A_Tab . Round(tempStr),,200)
tempStr=
Return

Volume_Set:
Gui,+OwnDialogs
InputBox,tempStr,设置音量调节幅度百分比（1-100）,,,280,100,,,,,%_Snd_Count%
If ErrorLevel
	Return
tempStr=%tempStr%
If RegexMatch(tempStr,"[^\d]") Or (tempStr<1) Or (tempStr>100)
{
	func_ShowInfoTip("仅支持输入数字，范围 1-100")
	Return
}
If (tempStr<>_Snd_Count)
{
	IniWrite,%tempStr%,%_INI_PATH%,General,VolumeRange
	func_ShowInfoTip("音量调节幅度已设置为 " tempStr "%",2500,300)
}
_Snd_Count:=tempStr,tempStr:=""
Return

;-╚══ 音量调节 ══╝

;-╔══ 禁止输入 ══╗

ahk_LockInput:
Gui,+OwnDialogs
InputBox,str_LockDelay,设置屏蔽鼠标键盘输入时长（单位：秒）,时长设为 0 时需按 [Ctrl+Alt+Delete] 手动解锁,,320,130,,,,,60
If ErrorLevel
	Return
str_LockDelay=%str_LockDelay%
If RegexMatch(Trim(str_LockDelay),"[^\d]")
{
	func_ShowInfoTip("仅支持输入数字")
	Return
}
BlockInput,On
If (str_LockDelay>0){
	ToolTip,%str_LockDelay%,,,6
	str_LockCount:=0
}Else
	ToolTip,已屏蔽输入，按 [Ctrl+Alt+Delete] 手动解锁,,,6
check_Flag:=0
MouseGetPos,li_x0,li_y0
SetTimer,check_LockInput,1000
Return

check_LockInput:
str_LockCount+=1
MouseGetPos,li_x1,li_y1
If (str_LockDelay>0){
	If (str_LockCount>=str_LockDelay)
		check_Flag:=1
	Else
		ToolTip,% str_LockDelay-str_LockCount,,,6
}
If (li_x1<>li_x0) Or (li_y1<>li_y0)
	check_Flag:=1
If check_Flag
{
	BlockInput,Off
	SetTimer,check_LockInput,Off
	str_LockCount:=0,li_x1:=li_x0:=li_y1:=li_y0:=check_Flag:=""
	ToolTip,,,,6
}
Return

;-╚══ 禁止输入 ══╝

; --------------- 鼠标菜单触发设置模块 -----

MouseMenuSet_Win:
Gui,MouseMenu:New
Gui,MouseMenu:-MinimizeBox +Owner%A_ScriptHwnd% +AlwaysOnTop
Gui,MouseMenu:Font,,Tahoma
Gui,MouseMenu:Font,,Microsoft Yahei
Gui,MouseMenu:Add,GroupBox,x10 y0 w150 h125,
Gui,MouseMenu:Add,CheckBox,x25 y20 vMouseMenu_P,&P - 桌面
Gui,MouseMenu:Add,CheckBox,x25 y45 vMouseMenu_S,&S - 任务栏
Gui,MouseMenu:Add,CheckBox,x25 y70 vMouseMenu_D,&D - 属性对话框
Gui,MouseMenu:Add,CheckBox,x25 y95 vMouseMenu_T,&T - 窗口标题栏
Gui,MouseMenu:Add,Button,x10 y135 w85 h25 Default gMouseMenu_Save,确定(&O)
Gui,MouseMenu:Add,Button,x100 y135 w60 h25 gMouseMenu_Cancel,关闭(&C)
Loop,Parse,Mouse_Trigger
	GuiControl,MouseMenu:,MouseMenu_%A_LoopField%,1
Gui,MouseMenu:Show,,鼠标菜单触发位置
Menu,Tray,Disable,3&
Return

MouseMenu_Save:
tempText:="PSDT",Mouse_Trigger:=""
Loop,Parse,tempText
{
	GuiControlGet,tempStr,MouseMenu:,MouseMenu_%A_LoopField%
	If tempStr
		Mouse_Trigger .= A_LoopField
}
IniWrite,%Mouse_Trigger%,%_INI_PATH%,General,MouseMenuTrigger
tempStr:=tempText:=""
Gosub MouseMenuGuiClose
Return

MouseMenu_Cancel:
MouseMenuGuiClose:
MouseMenuGuiEscape:
Gui,MouseMenu:Destroy
Menu,Tray,Enable,3&
Return

; --------------- 组件状态切换模块 -----

cmd_LibSwitch:
Gui,libSW_Win:Font,,Microsoft Yahei
Gui,libSW_Win:Add,ListView,x0 y0 w500 h360 Checked Grid NoSortHdr NoSort ReadOnly -Multi,模块组件|说明
Gui,libSW_Win:Add,Link,x10 y375 glib_Sel,<a Id="A">全选</a>%A_Space%%A_Space%%A_Space%%A_Space%<a Id="B">全不选</a>
Gui,libSW_Win:Add,Button,x310 y370 w100 Default glib_Save,确定
Gui,libSW_Win:Add,Button,x415 y370 w80 glib_Cancel,取消
Gui,libSW_Win:Show,w500 h405,组件状态管理
Gui,libSW_Win:Default
Lv_ModifyCol(1,200),Lv_ModifyCol(2,270)
;读取当前已启用组件
FileRead,tempStr,%path_LibList%
If !ErrorLevel
{
	tempStr:=Trim(tempStr),arr_LibOn:=[]
	Loop,Parse,tempStr,`n,`r
		arr_LibOn[Trim(A_LoopField,"#Include ")]:=1
}
;列举所有组件并读取配置
tempStr:="",arr_LibsInit:=[]
Loop,Files,%dir_Lib%\*.ahk,F
{
	n:=r:=0,__str:=""
	Loop,Read,%A_LoopFileLongPath%
	{
		;库文件标题和预加载函数名需在脚本前10行内
		If (n>10) Or ((__str!="") And r)	;读取超过10行或已经获取到内容
			Break
		If RegexMatch(A_LoopReadLine,"i)^;\s*@title:\s*(.*)",s)
			__str:=s1,s:=s1:=""
		If RegexMatch(A_LoopReadLine,"i)^\s*_init_" . SubStr(A_LoopFileName,1,-4) . "\(\)\s*\{?.*")
			r:=1
		n+=1
	}
	arr_LibsInit[A_LoopFileName]:=r,Lv_Add(arr_LibOn.haskey(A_LoopFileName)?"check":"",A_LoopFileName,__str)
}
tempStr:=__str:=r:=n:="",arr_LibOn:=[]
Return

lib_Sel:
Gui,libSW_Win:Default
LV_Modify(0,(ErrorLevel="A")?"check":"-check")
Return

lib_Save:
s1:="#Include %A_ScriptDir%\Lib",s2:="",r:=n:=0
Gui,libSW_Win:Default
Loop
{
	r:=LV_GetNext(r,"c")
	If Not r
		Break
	LV_GetText(__str,r),s1.="`n#Include " __str
	If arr_LibsInit[__str]
		n+=1,s2.=((n=1)?"":"`n`,") "_init_" SubStr(__str,1,-4) "()"
}
Try{
	FileDelete,%path_LibList%
	FileAppend,%s1%,%path_LibList%,UTF-8
	FileDelete,%path_LibInit%
	FileAppend,%s2%,%path_LibInit%,UTF-8
	Reload
}Catch{
	func_ShowInfoTip("组件状态切换出错，请检查！",,,,1)
	,s1:=s2:=r:=n:=__str:=""
}
Return

lib_Cancel:
libSW_WinGuiClose:
libSW_WinGuiEscape:
Gui,libSW_Win:Destroy
Return

;;------------ 脚本编辑 -------------

cmd_EditLib:
cmd_EditScript:
cmd_EditMain:
cmd_EditSet:
Switch A_ThisLabel
{
	Case "cmd_EditLib":tempStr:=dir_Lib "\" RegexReplace(A_ThisMenuItem,"^\d+-\s")
	Case "cmd_EditScript":tempStr:=dir_Scripts "\" RegexReplace(A_ThisMenuItem,"^\d+-\s")
	Case "cmd_EditSet":tempStr:=(A_ThisMenuItemPos=1)?_INI_PATH:_INI_Scripts
	Default:tempStr:=A_ScriptFullPath
}
try	Run,Edit %tempStr%
Catch
	Run,notepad.exe %tempStr%
tempStr=
Return

;-------

;;0x114 - 滚动水平滚动条
;;0x115 - 滚动垂直滚动条

; ------------------

~MButton::
If InStr(Mouse_Trigger,getCurrWin(0))
{
	Gosub sub_getSetFrReg
	Menu,G1,Show
}
Return

;;------------ 公用函数 -------------

getCurrWin(b){
;获取窗口。b=1：获取活动窗口；b=0：获取鼠标下窗口
	Global _ahk_GetWinID
	Global _HEIGHT_OF_TITLEBAR
	If b
		WinGetClass,gCls,A
	Else{
		MouseGetPos,dX,dY,_ahk_GetWinID
		WinGetClass,gCls,ahk_id %_ahk_GetWinID%
	}
	If gCls in Progman,WorkerW,#32769
		r:="P"	;桌面
	Else If gCls In Shell_TrayWnd,bbLeanBar
		r:="S"	;任务栏、bbleanbar
	Else If gCls in #32770,BaseBar,AU3Reveal,Au3Info,bbIconBox	;属性对话框/工具栏
		r:="D"
	Else{
		WinGetPos,mX,mY,dW,dH,A
		If !b
			r:=((dX >= mX) && (dX <= mX+dW) && (dY >= mY) && (dY <= mY+_HEIGHT_OF_TITLEBAR))?"T":0	; 4——标题栏; 0——非标题栏
		Else
			r:=0
	}
	dX:=dY:=dW:=dH:=mX:=mY:=""
	Return r
}

func_ShowInfoTip(s,t:=2000,w:=350,m:=1,c:=1){
	;s——内容；t：超时；w：宽度；m：文字居中；c：自定义颜色
	If c In 0,1
		c:=(c=1)?"2a2a2a":"f00000"
	Else{
		If !RegexMatch(c,"i)^[0-9a-f]{6}$")
			c:="2a2a2a"
	}
	SplashImage,,b w%w% c%m% fs10 cw%c% FM10 ctffffff,%s%,,%_App_NAME%_TIPINFO_WIN,Microsoft Yahei
	If (t<>0)
		SetTimer,RemoveSplashImg,-%t%
}

_Text_Cut(s,L:=45){
;长字符串减短成指定长度
	If (StrLen(s)>L){
		t1:=round((L-5)/2),t2:=(L-t1-6)*-1
		Return SubStr(s,1,t1) . " ... " . SubStr(s,t2)
	}
	Return s
}

TransformWin(b){
;窗口位置和尺寸变换
	Global mWALeft,mWARight,mWATop,mWABottom
	WinGetClass,gCls,A
	If gCls In Progman,Shell_TrayWnd,#32770,#32768
		Return
	WinGetActiveTitle,currWin
	If (currWin="")
		Return
	If (b=0){
		WinMinimize,%currWin%
		currWin=
		Return
	}

	WinGet,t,MinMax,%currWin%
	If (t=1){
		If (b=5){
			WinRestore,%currWin%
			Return
		}
		WinRestore,%currWin%
	}
	t=
	If (b=1)
		WinMove,%currWin%,,mWALeft,mWATop,(mWARight-mWALeft)/2,mWABottom-mWATop
	Else If (b=2)
		WinMove,%currWin%,,(mWARight-mWALeft)/2,mWATop,(mWARight-mWALeft)/2,mWABottom-mWATop
	Else If (b=3)
		WinMove,%currWin%,,mWALeft,mWATop,mWARight-mWALeft,(mWABottom-mWATop)/2
	Else If (b=4)
		WinMove,%currWin%,,mWALeft,(mWABottom-mWATop)/2,mWARight-mWALeft,(mWABottom-mWATop)/2
	Else If (b=5)
		WinMaximize,%currWin%
	currWin=
}

func_RunApp(s1)
{	;执行程序
	SplitPath,s1,,s2
	Try
		Run,%s1%,%s2%
	Catch
		func_ShowInfoTip("“" _Text_Cut(s1,40) "”运行失败，请检查后重试！",2500,,,0)
}

;ColorHex(s){
;;十进制转十六进制
;	SetFormat,integer,hex
;	r:=s+0
;	SetFormat,integer,d
;	s=%r%
;	s:=SubStr(s,3)
;	If (StrLen(s)<6){
;		Loop,% 6-StrLen(s)
;			s:="0" . s
;	}
;	r=
;	Loop
;	{
;		If (s="")
;			Break
;		r .= SubStr(s,-1),s:=SubStr(s,1,-2)
;	}
;	Return r
;}

getStrFromClip(){
;从剪贴板获取数据
	t:=ClipboardAll
	Clipboard=
	SendInput ^c
	ClipWait,1,1
	r:=ErrorLevel?"":Trim(Clipboard)
	Clipboard:=t
	t=
	Return r
}

str_SendASC(s){
;字符转ASC码
	r=
	Loop,Parse,s
	{
		tempStr:=Asc(A_LoopField)
		If (tempStr<=255)
			r .= "{Asc 0" . tempStr . "}"
		Else
			r .= A_LoopField
	}
	Return r
}

Is_CurrWin_Explorer(){
;判断活动窗口是否资源管理器
	WinGetClass,t,A
	If t In CabinetWClass,ExploreWClass
		Return 1
	Return 0
}

StrToBin(s){
;字符串转二进制图片
	XMLDOM:=ComObjCreate("Microsoft.XMLDOM")
	xmlver:="<?xml version=`"`"1.0`"`"?>"
	XMLDOM.loadXML(xmlver)
	t:=XMLDOM.createElement("pic"),t.dataType:="bin.hex",t.nodeTypedValue:=s,StrToByte:=t.nodeTypedValue,t:=""
	Return StrToByte
}

BYTE_TO_FILE(s,fp){
;数据流保存为文件
	Stream:=ComObjCreate("Adodb.Stream")
	Stream.Type:=1
	Stream.Open()
	Stream.Write(s)
	Stream.SaveToFile(fp,2)	;文件存在的就覆盖
	Stream.Close()
}

keys_Switch(s,b:=1){
;热键修饰符转换。b=0：简写转名称；b=1：名称转简写
	If b
		Return KeyFormat(StrReplace(StrReplace(StrReplace(StrReplace(s,"Shift+","+"),"Alt+","!"),"Ctrl+","^"),"Win+","#"))
	StringUpper,s,s,T
	Return StrReplace(StrReplace(StrReplace(StrReplace(s,"+","Shift+"),"!","Alt+"),"^","Ctrl+"),"#","Win+")
}

KeyFormat(s){
;对热键修饰符 ^!+# 进行排序
	If (s="")
		Return
	RegExMatch(s,"([!#^+]*)(.*)",r),r:=""
	If InStr(r1,"^")
		r .= "^"
	If InStr(r1,"!")
		r .= "!"
	If InStr(r1,"+")
		r .= "+"
	If InStr(r1,"#")
		r .= "#"
	r .= r2,r1:=r2:=s:=""
	StringLower,r,r
	Return r
}

EmptyMem(){
;清理内存
	h:=DllCall("OpenProcess","UInt",0x001F0FFF,"Int",0,"Int",DllCall("GetCurrentProcessId"))
	,DllCall("SetProcessWorkingSetSize","UInt",h,"Int",-1,"Int",-1)
	,DllCall("CloseHandle","Int",h)
}

get_SndMute()
;判断系统是否已静音
{
	SoundGet,r,,Mute
	Return (r="ON")?1:0
}

;;------------Exit-------------

ExitFunc(r,c)
{
	Global
	If r Not in Reload
	{
		If (arr_HiddenWin.Length()>0)	;恢复隐藏窗口显示
			Gosub restoreAllHiddenWins
	}Else{	;主程序 Reload
		If (arr_HiddenWin.Length()>0){
			Loop,% arr_HiddenWin.Length()
				IniWrite,% arr_HiddenWin[A_index][2],%_INI_PATH%,HiddenWin,% SubStr(arr_HiddenWin[A_index][1],3)
		}
	}
}

;;------------ 加载组件文件 -------------

#Include *i _zList.inc