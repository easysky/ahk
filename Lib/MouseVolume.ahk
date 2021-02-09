; @title:	鼠标音量调节
; ----------------------

_init_MouseVolume()
{
	Global SndM_Trigger
	SysGet,tempStr,MonitorCount
	IniRead,SndM_Trigger,%_INI_PATH%,SoundVolume,Trigger
	If (SndM_Trigger="ERROR") Or (SndM_Trigger="") Or RegexMatch(SndM_Trigger,"i)[^UBLR]")
		SndM_Trigger:=(tempStr>1)?"":"B"
	Else{
		If (tempStr>1){
			If InStr(SndM_Trigger,"L")
				SndM_Trigger:="L"
			Else
				SndM_Trigger=
		}
	}
	tempStr:=""
	,_LIB_COUNT+=1	;组件计数
	Menu,_Menu_LIBSET,Add,%_LIB_COUNT% - 鼠标音量调节,MouseVolume_Set	;组件菜单
}

; ------------- 鼠标调节音量模块 -----
	
MouseVolume_Set:
Gui,SndM_Set_Win:New
Gui,SndM_Set_Win:-MinimizeBox +AlwaysOnTop +Owner
Gui,SndM_Set_Win:Font,,Tahoma
Gui,SndM_Set_Win:Font,,微软雅黑
Gui,SndM_Set_Win:Add,GroupBox,x10 y0 w150 h130 
Gui,SndM_Set_Win:Add,CheckBox,x65 y25 vSndM_Pos_U,上(&U)
Gui,SndM_Set_Win:Add,CheckBox,x65 y95 vSndM_Pos_B,下(&B)
Gui,SndM_Set_Win:Add,CheckBox,x20 y60 vSndM_Pos_L,左(&L)
Gui,SndM_Set_Win:Add,CheckBox,x105 y60 vSndM_Pos_R,右(&R)
Gui,SndM_Set_Win:Add,Button,x100 y140 w60 h25 gSndM_Cancel,取消
Gui,SndM_Set_Win:Add,Button,x10 y140 w85 h25 gSndM_OK,更新(&S)
Gui,SndM_Set_Win:Show,,鼠标音量触发设置
If (SndM_Trigger<>""){
	Loop,Parse,SndM_Trigger
		GuiControl,SndM_Set_Win:,SndM_Pos_%A_LoopField%,1
}
Return

SndM_OK:
getStr1:="UBLR",SndM_Trigger:=""
Loop,Parse,getStr1
{
	GuiControlGet,tempStr,SndM_Set_Win:,SndM_Pos_%A_LoopField%
	If tempStr
		SndM_Trigger .= A_LoopField
}
IniWrite,%SndM_Trigger%,%_INI_PATH%,SoundVolume,Trigger
tempStr:=getStr1:=""
Gosub SndM_Set_WinGuiClose
Return

SndM_Set_WinGuiClose:
SndM_Set_WinGuiEscape:
SndM_Cancel:
Gui,SndM_Set_Win:Destroy
Return

#If SndM_Trigger_GetPos() And !get_SndMute()
WheelDown::
AjustSound(0)
Return

WheelUp::
AjustSound(1)
Return
#If

#If SndM_Trigger_GetPos()
^MButton::
SoundSet,+1,,MUTE
func_ShowInfoTip("已" . (get_SndMute()?"静音":"取消静音"),1000,150)
Return
#if

AjustSound(b){
;b:	0 - 调低音量；	1 - 调高音量
	SoundGet,s
	i:=(A_ThisHotkey<>A_PriorHotkey)?0:((A_TimeSincePriorHotkey<=50)?2:((A_TimeSincePriorHotkey>=350)?0.1:1))
	,s:=b?(s+i):(s-i),s:=Round(s,(i=0.1)?1:0)
	If (s<=0)
		s:=0
	Else If (s>=100)
		s:=100
	Else
		SoundSet,%s%
	ToolTip,% "主音量" . A_Space . A_Space . s
	SetTimer,RemoveToolTip,-800
}

SndM_Trigger_GetPos()
{
	Global SndM_Trigger
	If (SndM_Trigger="")
		Return 0
	MouseGetPos,dX,dY
	Return ((dY>=A_ScreenHeight-30) And InStr(SndM_Trigger,"B")) Or ((dY<=5) And InStr(SndM_Trigger,"U")) Or ((dX<=5) And InStr(SndM_Trigger,"L")) Or ((dX>=A_ScreenWidth-5) And InStr(SndM_Trigger,"R"))
}