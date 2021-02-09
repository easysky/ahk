; @title:	杂项功能
; --------------------

_init_Mussy()
{
	Global arr_Mussy:=[],__Is_MenuInfo:=0
	IniRead,tempStr,%_INI_PATH%,Mussy,Option,0000
	If !RegexMatch(tempStr,"^[01]{4}$")
		tempStr:="0000"
	If (tempStr<>"0000"){
		arr_Mussy:=StrSplit(tempStr),tempStr:=""
		If arr_Mussy[4]
			Gosub _init_SysInfo
	}
	_LIB_COUNT+=1	;组件计数
	Menu,_Menu_LIBSET,Add,%_LIB_COUNT% - 杂项功能,Mussy_Set	;组件菜单
}

Mussy_Set:
Gui,Mussy:New
Gui,Mussy:-MinimizeBox +AlwaysOnTop +Owner
Gui,Mussy:Font,,Tahoma
Gui,Mussy:Font,,微软雅黑
Gui,Mussy:Add,GroupBox,x10 y0 w250 h165,
tempStr:=arr_Mussy.haskey(1)?arr_Mussy[1]:0
Gui,Mussy:Add,CheckBox,x25 y25 Checked%tempStr% vMussyFunc_1,[Alt+鼠标左键]%A_Space%%A_Space%移动窗口(&F)
tempStr:=arr_Mussy.haskey(2)?arr_Mussy[2]:0
Gui,Mussy:Add,CheckBox,x25 y55 Checked%tempStr% vMussyFunc_2,[Alt+右键]%A_Space%%A_Space%改变窗口大小(&T)
tempStr:=arr_Mussy.haskey(3)?arr_Mussy[3]:0
Gui,Mussy:Add,CheckBox,x25 y85 Checked%tempStr% vMussyFunc_3,[Ctrl+Alt+LWin]%A_Space%%A_Space%显示鼠标下信息(&P)
tempStr:=arr_Mussy.haskey(4)?arr_Mussy[4]:0
Gui,Mussy:Add,CheckBox,x25 y115 Checked%tempStr% vMussyFunc_4,[Ctrl+Alt]%A_Space%%A_Space%当鼠标位于窗口左上角时`n显示系统信息
Gui,Mussy:Add,Button,x75 y170 w100 Default gMussy_Save,确定
Gui,Mussy:Add,Button,x180 y170 w80 gMussy_Cancel,取消
Gui,Mussy:Show,,杂项功能设置
tempStr=
Return

Mussy_Save:
Loop,4
{
	GuiControlGet,getStr%A_Index%,Mussy:,MussyFunc_%A_Index%
	arr_Mussy[A_Index]:=getStr%A_Index%
}
Gosub MussyGuiClose
IniWrite,%getStr1%%getStr2%%getStr3%%getStr4%,%_INI_PATH%,Mussy,Option
getStr1:=getStr2:=getStr3:=getStr4:=""
If !arr_Mussy[4] And __Is_MenuInfo
{
	Menu,menu_Info,Delete
	__Is_MenuInfo:=0
}
If arr_Mussy[4] And !__Is_MenuInfo
	Gosub _init_SysInfo
Return

MussyGuiClose:
MussyGuiEscape:
Mussy_Cancel:
Gui,Mussy:Destroy
Return

;----- Alt+左键移动窗口 -----

#if arr_Mussy[1]
!Lbutton::
SetWinDelay,0
MouseGetPos,dX,dY,mID
WinGet,EM_tempStr,MinMax,ahk_id %mID%
If EM_tempStr
{
	dX:=dY:=mID:=EM_tempStr:=""
	Return
}
; 获取初始的窗口位置.
WinGetPos,mX,mY,,,ahk_id %mID%
Loop
{
	GetKeyState,EM_tempStr,LButton,P ; 如果按钮已经被松开了则退出.
	If EM_tempStr=U
	    Break
	MouseGetPos,dX2,dY2 ; 获取当前的鼠标位置.
	; 得到距离原来鼠标位置的偏移.把这个偏移应用到窗口位置.
	dX2-=dX,dY2-=dY,EM_getStr1:=(mX+dX2),EM_getStr2:=(mY+dY2)
	WinMove,ahk_id %mID%,,%EM_getStr1%,%EM_getStr2%
}
dX:=dY:=dX2:=dY2:=mX:=mY:=mID:=EM_getStr1:=EM_getStr2:=EM_tempStr:=""
SetWinDelay,%last_WinDelay%
Return
#If

;----- Alt+右键改变窗口尺寸 -----

#if arr_Mussy[2]
!Rbutton::
; 获取初始的鼠标位置和窗口 id,并
; 在窗口处于最大化状态时返回.
SetWinDelay,0
MouseGetPos,dX,dY,mID
WinGetClass,ER_tempStr,ahk_id %mID%
If ER_tempStr In Progman,WorkerW,Shell_TrayWnd,#32770,BaseBar,AU3Reveal,Au3Info
{
	dX:=dY:=mID:=ER_tempStr:=""
	Return
}
WinGet,ER_tempStr,MinMax,ahk_id %mID%
If (ER_tempStr=1){
	dX:=dY:=mID:=ER_tempStr:=""
	Return
}
; 获取初始的窗口位置和大小.
WinGetPos,KDE_WinX1,KDE_WinY1,dW,dH,ahk_id %mID%
If (dX<KDE_WinX1+dW / 2)
	KDE_WinLeft:=1
Else
	KDE_WinLeft:=-1
If (dY<KDE_WinY1+dH / 2)
	KDE_WinUp:=1
Else
	KDE_WinUp:=-1
Loop
{
	GetKeyState,ER_tempStr,RButton,P ; 如果按钮已经松开了则退出.
	If ER_tempStr=U
	    Break
	MouseGetPos,KDE_X2,KDE_Y2 ; 获取当前鼠标位置.
	; 获取当前的窗口位置和大小.
	WinGetPos,KDE_WinX1,KDE_WinY1,dW,dH,ahk_id %mID%
	; 得到距离原来鼠标位置的偏移.
	KDE_X2-=dX,KDE_Y2-=dY
	; 然后根据已定义区域进行动作.
	WinMove,ahk_id %mID%,,KDE_WinX1+(KDE_WinLeft+1)/2*KDE_X2  ; 大小调整后窗口的 X 坐标
		,KDE_WinY1+  (KDE_WinUp+1)/2*KDE_Y2  ; 大小调整后窗口的 Y 坐标
		,dW  -     KDE_WinLeft  *KDE_X2  ; 大小调整后窗口的 W (宽度)
		,dH  -       KDE_WinUp  *KDE_Y2  ; 大小调整后窗口的 H (高度)
	; 为下一次的重复重新设置初始位置.
	dX:=(KDE_X2+dX),dY:=(KDE_Y2+dY)
}
dX:=dY:=mID:=ER_tempStr:=KDE_WinX1:=KDE_WinY1:=KDE_WinLeft:=KDE_WinUp:=dW:=dH:=KDE_X2:=KDE_Y2:=""
SetWinDelay,%last_WinDelay%
Return
#if

;----- 鼠标信息 -----

#if arr_Mussy[3] And GetKeyState("Alt","P")
Ctrl & Lwin::
curr_CooM:=A_CoordModeMouse,dX:=dY:=dWin:=dCtrl:=dW:=dH:=""
CoordMode,Mouse,Screen
MouseGetPos,dX,dY,dWin,dCtrl
Gui,MouseInfo_Win:New
Gui,MouseInfo_Win:-Caption +Border +ToolWindow +AlwaysOnTop +HwndMI_Win
Gui,MouseInfo_Win:Font,,Microsoft Yahei
Gui,MouseInfo_Win:Add,GroupBox,x10 y10 w400 h250 c000088,窗口信息
Gui,MouseInfo_Win:Add,Text,x30 y43,Title
WinGetTitle,tempStr,Ahk_Id %dWin%
Gui,MouseInfo_Win:Add,Edit,x95 y40 w295 ReadOnly r1,% (tempStr="")?"<空>":tempStr
Gui,MouseInfo_Win:Add,Text,x30 y73,Ahk_Class
WinGetClass,tempStr,Ahk_Id %dWin%
Gui,MouseInfo_Win:Add,Edit,x95 y70 w295 ReadOnly r1,%tempStr%
Gui,MouseInfo_Win:Add,Text,x30 y103,Ahk_Id
Gui,MouseInfo_Win:Add,Edit,x95 y100 w295 ReadOnly r1,%dWin%
Gui,MouseInfo_Win:Add,Text,x30 y133,Ahk_Pid
WinGet,tempStr,PID,Ahk_Id %dWin%
Gui,MouseInfo_Win:Add,Edit,x95 y130 w295 ReadOnly r1,%tempStr%
Gui,MouseInfo_Win:Add,Text,x30 y163,Ahk_Exe
WinGet,tempStr,ProcessName,Ahk_Id %dWin%
Gui,MouseInfo_Win:Add,Edit,x95 y160 w295 ReadOnly r1,%tempStr%
Gui,MouseInfo_Win:Add,Text,x30 y193,程序路径
WinGet,tempStr,ProcessPath,Ahk_Id %dWin%
Gui,MouseInfo_Win:Add,Edit,x95 y190 w295 ReadOnly r1,%tempStr%
WinGetPos,wX,wY,dW,dH,Ahk_Id %dWin%
Gui,MouseInfo_Win:Add,Text,x30 y228,窗口位置
Gui,MouseInfo_Win:Add,Edit,x95 y225 w60 ReadOnly Center r1,%wX%`,%wY%
Gui,MouseInfo_Win:Add,Text,x180 y228,窗口宽
Gui,MouseInfo_Win:Add,Edit,x225 y225 w50 ReadOnly Center r1,%dW%
Gui,MouseInfo_Win:Add,Text,x300 y228,窗口高
Gui,MouseInfo_Win:Add,Edit,x340 y225 w50 ReadOnly Center r1,%dH%
Gui,MouseInfo_Win:Add,GroupBox,x10 y265 w400 h180 c000088,控件信息
Gui,MouseInfo_Win:Add,Text,x30 y298,控件文本
Gui,MouseInfo_Win:Add,Edit,x95 y295 w295 ReadOnly r2,% _getCtrl(5)
Gui,MouseInfo_Win:Add,Text,x30 y348,ClassNN
Gui,MouseInfo_Win:Add,Edit,x95 y345 w295 ReadOnly r1,% _getCtrl(0)
Gui,MouseInfo_Win:Add,Text,x30 y378,HWND
Gui,MouseInfo_Win:Add,Edit,x95 y375 w295 ReadOnly r1,% _getCtrl(1)
Gui,MouseInfo_Win:Add,Text,x30 y413,控件坐标
Gui,MouseInfo_Win:Add,Edit,x95 y410 w60 ReadOnly Center r1,% _getCtrl(2)
Gui,MouseInfo_Win:Add,Text,x180 y413,控件宽
Gui,MouseInfo_Win:Add,Edit,x225 y410 w50 ReadOnly Center r1,% _getCtrl(3)
Gui,MouseInfo_Win:Add,Text,x300 y413,控件高
Gui,MouseInfo_Win:Add,Edit,x340 y410 w50 ReadOnly Center r1,% _getCtrl(4)
Gui,MouseInfo_Win:Add,GroupBox,x10 y450 w400 h100 c000088,鼠标和颜色
Gui,MouseInfo_Win:Add,Text,x30 y483,鼠标位置
Gui,MouseInfo_Win:Add,Edit,x95 y480 w100 ReadOnly r1 Center,%dX%`,%dY%
Gui,MouseInfo_Win:Add,Text,x200 y483,[屏幕]
CoordMode,Mouse,Window
MouseGetPos,dX,dY
Gui,MouseInfo_Win:Add,Edit,x250 y480 w100 ReadOnly r1 Center,%dX%`,%dY%
Gui,MouseInfo_Win:Add,Text,x355 y483,[窗口]
Gui,MouseInfo_Win:Add,Text,x30 y513,鼠标取色
PixelGetColor,_mGetColor,dX,dY,RGB
If ErrorLevel Or (_mGetColor="")
	PixelGetColor,_mGetColor,%dX%,%dY%,slow RGB
Gui,MouseInfo_Win:Add,Edit,x95 y510 w100 ReadOnly r1 Center,% _getColor(0)
Gui,MouseInfo_Win:Add,Edit,x200 y510 w60 ReadOnly r1 Center,% _getColor(1)
Gui,MouseInfo_Win:Add,Edit,x270 y510 w100 ReadOnly r1 Center,% _getColor(2)
Gui,MouseInfo_Win:Add,Text,% "x375 y513 c" _getColor(1),▇▇
Gui,MouseInfo_Win:Show,NA,%A_Space%
CoordMode,Mouse,%curr_CooM%
OnMessage(0x201,"move_Win")
Return
#if

MouseInfo_WinGuiClose:
MouseInfo_WinGuiEscape:
Gui,MouseInfo_Win:Destroy
Return

#If WinExist("ahk_id" MI_Win)
ESC::Gosub MouseInfo_WinGuiClose
#if

_getCtrl(b){
	;b=0——ClassNN；1——Hwnd；2——坐标；3——宽；4——高；5——文本
	Global dWin,dCtrl
	If (dCtrl="")
		Return "<空>"
	If (b=0)
		r:=dCtrl
	Else If (b=1)
		ControlGet,r,Hwnd,,%dCtrl%,Ahk_Id %dWin%
	Else If b In 2,3,4
	{
		ControlGetPos,dX,dY,dW,dH,%dCtrl%,Ahk_Id %dWin%
		r:=(b=2)?(dX "," dY):((b=3)?dW:dH)
	}Else If (b=5){
		ControlGetText,r,%dCtrl%,Ahk_Id %dWin%
		If (r="")
			r:="<空>"
	}
	Return r
}

_getColor(b){
	;b=0——十进制；1——HTML；2——RGB
	Global _mGetColor
	If (_mGetColor="")
		Return "<空>"
	If (b=0)
		Return _mGetColor+0
	r:=SubStr(_mGetColor,3)
	If (b=1)
		Return r
	Return Hex2Dec("0x" . SubStr(r,1,2)) "`," Hex2Dec("0x" . SubStr(r,3,2)) "`," Hex2Dec("0x" . SubStr(r,5,2))
}

move_Win()
{
	PostMessage,0xA1,2
}

Hex2Dec(strIn){
	Return strIn+0
}

;----- Ctrl+Alt显示系统信息 -----

#If arr_Mussy[4] And MouseIsOnZero()
Ctrl & Alt::
If (n_Mon<>0){
	Loop,% n_Mon-1
		Menu,menu_Info,Delete,% (4+A_Index) "&"
}
SysGet,n_Mon,MonitorCount
Menu,menu_Info,ReName,3&,总显示器数量`t`t%n_Mon%
Loop,% n_Mon
{
	If (A_Index=1)
		Continue
	SysGet,s1,MonitorName,%A_Index%
	SysGet,s2,Monitor,%A_Index%
	Menu,menu_Info,Insert,5&,% "副显示器 [ " s1  " ]`t`t" (s2right-s2left) " × " (s2bottom-s2top),cmd_sysInfo
}
SysGet,s1,78
SysGet,s2,79
Menu,menu_Info,ReName,% (n_Mon+4) "&",总显示器区域`t`t%s1% × %s2%,cmd_sysInfo
FormatTime,tempStr,%A_Now%,yyyy/M/d（ddd）HH:mm
Menu,menu_Info,ReName,% (n_Mon+9) "&",系统时间`t`t%tempStr%
s1:=Floor(A_TickCount/1000),s2:=Floor(s1/3600),s3:=s2 . " 小时 ",s1:=s1-s2*3600,s2:=Floor(s1/60),s3.=s2 . " 分钟"
Menu,menu_Info,ReName,% (n_Mon+10) "&",系统已启动`t`t%s3%,cmd_sysInfo
Menu,menu_Info,Show
tempStr:=s1:=s2:=s3:=""
Return
#if

_init_SysInfo:
n_Mon:=0
Menu,menu_Info,Add,% "操作系统`t`t" A_OSVersion " × " (A_Is64BitOs?"64":"32") A_Space,cmd_sysInfo	;1
Menu,menu_Info,Add,	;2
Menu,menu_Info,Add,显示器数量,cmd_sysInfo	;3
SysGet,tempStr,MonitorName
Menu,menu_Info,Add,% "主显示器 [ " tempStr  " ]`t`t" A_ScreenWidth " × " A_ScreenHeight,cmd_sysInfo	;4
;;动态菜单  (n_Mon-1)个
Menu,menu_Info,Add,总显示器区域,cmd_sysInfo	;n_Mon+4
Menu,menu_Info,Add,% "DPI 设置`t`t" A_ScreenDPI A_Space "dpi",cmd_sysInfo	;n_Mon+5
Menu,menu_Info,Add,	;n_Mon+6
Menu,menu_Info,Add,% "语言`t`t" (((A_Language="0804")?"":"非") . "简体中文（PRC）"),cmd_sysInfo	;n_Mon+7
Menu,menu_Info,Add,	;n_Mon+8
Menu,menu_Info,Add,系统时间,cmd_sysInfo	;n_Mon+9
Menu,menu_Info,Add,系统已启动,cmd_sysInfo	;n_Mon+10
Menu,menu_Info,Add,	;n_Mon+11
Menu,menu_Info,Add,% "计算机名`t`t" A_ComputerName,cmd_sysInfo	;n_Mon+12
Menu,menu_Info,Add,% "用户名`t`t" A_UserName A_Space (((A_IsAdmin)?"（":"（非") . "管理员）"),cmd_sysInfo	;n_Mon+13
Menu,menu_Info,Add,	;n_Mon+14
Loop,4
{
	If (A_IpAddress%A_Index%<>"0.0.0.0")
		Menu,menu_Info,Add,% "IP 地址 [" A_Index "/4]`t`t" A_IpAddress%A_Index%,cmd_sysInfo
}
Menu,menu_Info,Add,
Menu,menu_Info,Add,AutoHotkey 版本`t`tv%A_AhkVersion%,cmd_sysInfo
__Is_MenuInfo:=1
Return

cmd_sysInfo:
Clipboard:=Trim(SubStr(A_ThisMenuItem,InStr(A_ThisMenuItem,"`t`t")+2))
func_ShowInfoTip("已复制到剪贴板")
Return

MouseIsOnZero() {
	curr_CooM:=A_CoordModeMouse
	CoordMode,Mouse,Screen
	MouseGetPos,dX,dY
	CoordMode,Mouse,%curr_CooM%
	If (dX<=5) && (dY<=5)
		Return 1
	Return 0
}