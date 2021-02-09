; @title:	鼠标手势
; -------------------

_init_Gesture()
{
	Global b_TimeChk,b_ShowTrace,b_ShowTip,b_FixPos,gst_TimeOut,str_gTraceWeight,arr_GstCmd,arr_GstAction,arr_NoMGWin,str_gColor,gdi_Color,last_EGOption
	;读取窗口列表到字符串
	IniRead,last_EGOption,%_INI_PATH%,Gesture,Option,%A_Space%
	last_EGOption=%last_EGOption%
	If (last_EGOption="") Or !RegexMatch(last_EGOption,"i)^([01]{4})\|(\d?)\|([0-9a-f]{6})\|(\d{3,})$",getStr)
		last_EGOption:="1110|3|556FC7|1200",getStr1:="1110",getStr2:=3,getStr3:="556FC7",getStr4:=1200
	b_TimeChk:=SubStr(getStr1,1,1),b_ShowTrace:=SubStr(getStr1,2,1),b_ShowTip:=SubStr(getStr1,3,1),b_FixPos:=SubStr(getStr1,4,1),str_gTraceWeight:=getStr2,str_gColor:=getStr3,gdi_Color:=gdi_GetColor(getStr3),gst_TimeOut:=getStr4,getStr1:=getStr2:=getStr3:=getStr4:=getStr:=""
	If (str_gTraceWeight<1) Or (str_gTraceWeight>9)
		str_gTraceWeight:=3
	If (gst_TimeOut<>0){
		If (gst_TimeOut<500) Or (gst_TimeOut>5000)
			gst_TimeOut:=1200
		gst_TimeOut:=Round(gst_TimeOut/1000,1)
	}Else
		b_TimeChk:=0
	arr_GstCmd:=[["win_Max","最大化/还原窗口"]
	,["win_Min","最小化当前窗口"]
	,["win_MinAll","显示桌面"]
	,["win_Switch","切换窗口"]
	,["win_Hide","隐藏活动窗口"]
	,["win_HiddenList","显示隐藏窗口列表"]
	,["win_TopOn","窗口置顶切换"]
	,["win_Trans","窗口透明切换"]
	,["win_Close","关闭窗口"]
	,["key_Hotkey","发送热键"]
	,["key_SendKey","发送连续按键"]
	,["vol_Up","增大音量"]
	,["vol_Down","减小音量"]
	,["vol_Mute","切换静音"]
	,["file_Web","打开网页"]
	,["file_RunApp","运行程序/打开文件或目录"]
	,["file_Url","跳转到选中网址"]
	,["file_Search","搜索选中文本"]
	,["sys_ClearClip","清空剪贴板"]
	,["sys_CloseLCD","关闭显示器"]
	,["sys_LockPC","锁定计算机"]
	,["sys_CloseLock","锁定计算机并关闭显示器"]
	,["sys_NoInput","锁定鼠标键盘"]
	,["sys_Logout","注销系统"]
	,["sys_Rebot","重启系统"]
	,["sys_ShutDown","关闭系统"]]
	,arr_GstAction:=[],arr_NoMGWin:=[]	;arr_GstAction——所有窗口及动作；arr_NoMGWin——禁用手势的窗口
	IniRead,tempStr,%_INI_PATH%,Gesture,0	;读取禁用手势窗口
	tempStr=%tempStr%
	If (tempStr<>""){
		Loop,Parse,tempStr,|
		{
			s1:=s2:=s3:=""
			Loop,Parse,A_LoopField,@
				s%A_Index%:=Trim(A_LoopField)
			If (s1<>"") And (s2<>"")
			{
				Loop,Parse,s1,`,
					arr_NoMGWin[A_LoopField]:=1
				;arr_NoMGWin["TTOTAL_CMD"]:=1
				;arr_NoMGWin["Warcraft III"]:=1
				;arr_NoMGWin["MangaMeeya"]:=1
				;arr_NoMGWin["VirtualBox.exe"]:=1
			}
		}
	}
	;获取 默认窗口手势命令 到数组
	IniRead,tempStr,%_INI_PATH%,Gesture,Default
	tempStr=%tempStr%
	If (tempStr<>"")
		arr_GstAction["Default"]:=parse_Cmd2Arr(tempStr)
		;arr_GstAction["Default"]["DL"]:=["19","close{enter}","关闭当前页"]
		;arr_GstAction["Default"]["U"]:=["1","","最大化/还原"]
		;……
	;获取 自定义窗口手势命令 到数组
	Loop
	{
		IniRead,tempStr,%_INI_PATH%,Gesture,%A_Index%
		If (tempStr="ERROR")
			Break
		tempStr:=Trim(tempStr),s1:=s4:=""
		;s1——窗口标识；s2——窗口标识类型；s3——窗口名；s4——对应手势
		Loop,Parse,tempStr,|
			s%A_Index%:=Trim(A_LoopField)
		arr_Temp:=parse_Cmd2Arr(s4)
		Loop,Parse,s1,`,	;可能存在多个窗口标识共用
		{
			If (A_LoopField<>"")
				arr_GstAction[A_LoopField]:=arr_Temp	;arr_Temp["DL"]:=["19","close{enter}","关闭当前页"]
		}
	}
	tempStr:=s1:=s2:=s3:=s4:="",arr_Temp:=[]
	,_LIB_COUNT+=1	;组件计数
	Menu,_Menu_LIBSET,Add,%_LIB_COUNT% - 鼠标手势,EasyGesture_Set	;组件菜单
	If b_ShowTrace
		gdi_New()
}

; ---------- 鼠标手势核心模块 -----

#if _IS_MGActive()
Rbutton::
gst_Flag:=0,gst_GetTrack:=""
If b_ShowTrace
	gdi_Show()
if b_ShowTip
	gst_Get_X0:=gst_Get_X1,gst_Get_Y0:=gst_Get_Y1,gst_GetAct:=""
SetTimer,sub_GetTrack,30

KeyWait,RButton,% b_TimeChk?("T" . gst_TimeOut):""
errFlag:=ErrorLevel
SetTimer,sub_GetTrack,Off
If b_ShowTrace
	gdi_Empty(),gdi_Update(),gdi_Hide()
If errFlag
{
	If b_ShowTip
		ToolTip,,,,17
}Else{
	If (gst_GetTrack<>"")
		gst_Flag:=1
}

errFlag=
If gst_Flag
	Gosub gst_Act
Else
	Send {RButton}
If b_ShowTip
{
	ToolTip,,,,17
	gst_GetAct:=gst_Get_X0:=gst_Get_Y0:=""
}
Return
#if

sub_GetTrack:
MouseGetPos,gst_Get_X2,gst_Get_Y2
If (gst_Get_X2=gst_Get_X1) And (gst_Get_Y2=gst_Get_Y1)
	Return
If abs(gst_Get_Y2-gst_Get_Y1) >= abs(gst_Get_X2-gst_Get_X1)
	gtrack:=(gst_Get_Y2<gst_Get_Y1)?"U":"D"
Else
	gtrack:=(gst_Get_X2<gst_Get_X1)?"L":"R"
If b_ShowTrace
	gdi_Draw(gst_Get_X1,gst_Get_Y1,gst_Get_X2,gst_Get_Y2,gdi_Color),gdi_Update()
If ((Abs(gst_Get_Y2-gst_Get_Y1)>5) Or (Abs(gst_Get_X2-gst_Get_X1)>5)) And (gtrack<>SubStr(gst_GetTrack,0,1))
{
	gst_GetTrack .= gtrack
	If b_ShowTip	;如需显示手势提示
	{
		gst_GetAct .= Action2Symbol(1,gtrack)
		If arr_GstAction[gst_GetWinLogo].Haskey(gst_GetTrack)	;["acad.exe"]["dr"]
			tempStr:=_gst_GetTip(gst_GetWinLogo)
		Else{
			If arr_GstAction["Default"].Haskey(gst_GetTrack)
				tempStr:=_gst_GetTip("Default")
			Else
				tempStr:="未定义"
		}
		ToolTip,%gst_GetAct%%A_Space%%A_Space%[%tempStr%],% b_FixPos?(mWALeft+2):gst_Get_X0,% b_FixPos?(mWABottom-22):gst_Get_Y0,17
		tempStr=
	}
}
gst_Get_X1:=gst_Get_X2,gst_Get_Y1:=gst_Get_Y2,gtrack:=gst_Get_X2:=gst_Get_Y2:=""
Return

_gst_GetTip(s){
	Global arr_GstAction,gst_GetTrack,arr_GstCmd
	If (arr_GstAction[s][gst_GetTrack][1]="0")
		s1:="无动作"
	Else{
		s1:=arr_GstAction[s][gst_GetTrack][3]
		If (s1="")
			s2:=(arr_GstAction[s][gst_GetTrack][1]=18)?keys_Switch(arr_GstAction[s][gst_GetTrack][2],0):arr_GstAction[s][gst_GetTrack][2]
			,s1:=arr_GstCmd[arr_GstAction[s][gst_GetTrack][1]][2] . ((arr_GstAction[s][gst_GetTrack][2]="")?"":(A_Space . "[" . s2 . "]"))
	}
	Return s1
}

gst_Act:
If arr_GstAction[gst_GetWinLogo].Haskey(gst_GetTrack)
	str_CMD:=gst_GetWinLogo
Else{
	If arr_GstAction["Default"].Haskey(gst_GetTrack)
		str_CMD:=arr_GstAction["Default"].Haskey(gst_GetTrack)?"Default":""
}
If (str_CMD<>""){
	str_CMD:=arr_GstCmd[arr_GstAction[str_CMD][gst_GetTrack][1]][1]
	If (str_CMD="win_Max"){
		If gst_GetClass in Progman,WorkerW,Shell_TrayWnd
			WinMinimizeAllUndo
		Else{
			WinGet,tempStr,MinMax,ahk_id %gst_GetWinID%
			if (tempStr=1)
				WinRestore,ahk_id %gst_GetWinID%
			else
				WinMaximize,ahk_id %gst_GetWinID%
			tempStr=
		}
	}Else If (str_CMD="win_Min"){
		if gst_GetClass in Progman,WorkerW,Shell_TrayWnd
			WinMinimizeAll
		Else
			WinMinimize,ahk_id %gst_GetWinID%
	}Else If (str_CMD="win_MinAll")
		WinMinimizeAll
	Else If (str_CMD="win_Switch"){
		WinGet,tempStr_,List
		arr_TempID:=[]
		Loop,%tempStr_%
		{
			sID:=tempStr_%A_Index%
			WinGet,tempStr,Style,Ahk_Id %sID%
			If (tempStr & 0xC00000)
			{
				WinGetTitle,tempStr,Ahk_Id %sID%
				Menu,gMenu,Add,% _Text_Cut(tempStr),cmd_Gst
				arr_TempID.push(sID)
				WinGet,tempStr,ProcessPath,Ahk_Id %sID%
				Menu,gMenu,Icon,% arr_TempID.length() "&",%tempStr%
			}
		}
		Menu,gMenu,Show
		Menu,gMenu,Delete
		sID:=tempStr:=""
	}Else If (str_CMD="win_Hide"){
		WinActivate,Ahk_Id %gst_GetWinID%
		Gosub ahk_HideThisWin
	}Else If (str_CMD="win_HiddenList")
		Gosub ahk_HiddenWinMan
	Else If (str_CMD="win_TopOn"){
		WinActivate,Ahk_Id %gst_GetWinID%
		Gosub ahk_TopOnThisWin
	}Else If (str_CMD="win_Trans"){
		WinActivate,Ahk_Id %gst_GetWinID%
		Gosub ahk_TransparentThisWin
	}Else If (str_CMD="win_Close")
		WinClose,ahk_id %gst_GetWinID%
	Else If str_CMD In key_Hotkey,key_SendKey
	{
		WinActivate,ahk_id %gst_GetWinID%
		StringLower,tempStr,% arr_GstAction[gst_GetWinLogo][gst_GetTrack][2]
		SendInPut %tempStr%
		tempStr=
	}Else If (str_CMD="vol_Up")
		Gosub ahk_VolumeUp	
	Else If (str_CMD="vol_Down")
		Gosub ahk_VolumeDown	
	Else If (str_CMD="vol_Mute")
		SoundSet,+1,,mute
	Else If str_CMD In file_Web,file_RunApp
	{
		tempStr:=Trim(arr_GstAction[gst_GetWinLogo][gst_GetTrack][2])
		If (tempStr=""){
			func_ShowInfoTip("未指定" . (tempStr="file_Web")?"网址":"程序/文件",,,,0)
			Return
		}
		Loop,Parse,tempStr,``
		{
			getStr1:=Trim(A_LoopField)
			If (getStr1="")
				Continue
			If (str_CMD="file_Web"){
				If (SubStr(getStr1,1,4)<>"http")
					getStr1:="http://" . getStr1
				Run,%getStr1%
			}Else
				func_RunApp(getStr1)
		}
		tempStr:=getStr1:=""
	}Else If (str_CMD="file_Url")
		Gosub ahk_BrowseSelUrl
	Else If (str_CMD="file_Search")
		Gosub ahk_SearchSelText	
	Else If (str_CMD="sys_ClearClip")
		Gosub ahk_ClearClip
	Else If (str_CMD="sys_CloseLCD")
		Gosub ahk_CloseLCD
	Else If (str_CMD="sys_LockPC")
		Gosub ahk_LockPC
	Else If (str_CMD="sys_CloseLock")
		Gosub ahk_CloseLCDAndLockPC
	Else If (str_CMD="sys_NoInput")
		Gosub ahk_LockInput	
	Else If (str_CMD="sys_Logout")
		func_ShutDown(1,"注销系统")
	Else If (str_CMD="sys_Rebot")
		func_ShutDown(2,"重启系统")
	Else If (str_CMD="sys_ShutDown")
		func_ShutDown(3,"关闭系统")
	str_CMD=
}
Return

cmd_Gst:
WinActivate,% "Ahk_Id " arr_TempID[A_ThisMenuItemPos]
arr_TempID:=[]
Return

_IS_MGActive(){
	Global gst_GetWinID,gst_GetClass,gst_Get_X1,gst_Get_Y1,arr_GstAction,arr_NoMGWin,gst_GetWinLogo:=""
	b:=1
	MouseGetPos,gst_Get_X1,gst_Get_Y1,gst_GetWinID
	WinGetClass,gst_GetClass,ahk_id %gst_GetWinID%
	If arr_NoMGWin[gst_GetClass]	;验证 窗口类
		b:=0	;为禁用手势窗口
	Else{
		If arr_GstAction.Haskey(gst_GetClass)
			gst_GetWinLogo:=gst_GetClass	;如此窗口已定义手势，则明确窗口标识
	}
	If b	;验证 文件名
	{
		WinGet,tempStr,ProcessName,ahk_id %gst_GetWinID%
		If arr_NoMGWin[tempStr]
			b:=0
		Else{
			If (gst_GetWinLogo="") And arr_GstAction.Haskey(tempStr)
				gst_GetWinLogo:=tempStr
		}
	}
	If b	;验证 窗口标题
	{
		WinGetTitle,tempStr,ahk_id %gst_GetWinID%
		If arr_NoMGWin[tempStr]
			b:=0
		Else{
			If (gst_GetWinLogo="") And arr_GstAction.Haskey(tempStr)
				gst_GetWinLogo:=tempStr
		}
	}
	If b And (gst_GetWinLogo="")
		gst_GetWinLogo:="Default"
	Return b
}

Action2Symbol(i,s)
{
	Return i?StrReplace(StrReplace(StrReplace(StrReplace(s,"U","↑"),"D","↓"),"L","←"),"R","→"):StrReplace(StrReplace(StrReplace(StrReplace(s,"↑","U"),"↓","D"),"←","L"),"→","R")
}

parse_Cmd2Arr(s){
	arr_Temp:=[]
	Loop,Parse,s,`,
	{
		s1:=s2:=s3:=""
		Loop,Parse,A_LoopField,@
			s%A_Index%:=A_LoopField	;s1——"DL"; s2——"19:close{enter}"; s3——"关闭当前页"
		str1:=str2:="",RegexMatch(s2,"(^\d+):?(.*)",str),arr_Temp[s1]:=[str1,str2,s3]	;arr_Temp["DL"]:=["19","close{enter}","关闭当前页"]
	}
	Return arr_Temp
}

; ---------- 鼠标手势管理模块 -----

EasyGesture_Set:
Gui,GST_Set:New
Gui,GST_Set:+Resize +Minsize +HwndGST_ID
Gui,GST_Set:Font,,Tahoma
Gui,GST_Set:Font,,Microsoft Yahei
Gui,GST_Set:Add,ListBox,x0 y0 w200 0x100 AltSubmit ggst_Do vctrl_GSTWin,
Gui,GST_Set:Add,ListView,x205 y0 Grid AltSubmit -Multi ggst_Do vctrl_GSTList,手势|动作|手势提示
Lv_ModifyCol(1,100),Lv_ModifyCol(3,180)
Gui,GST_Set:Add,GroupBox,x5 w195 h158 vg_GSTOption,选项
Gui,GST_Set:Add,CheckBox,x20 Checked%b_TimeChk% ggst_Do vg_TimeChk,手势超时(&T)
Gui,GST_Set:Add,Edit,x108 w50 h20 Disabled Number ggst_Do vg_TimeOut,% Round(gst_TimeOut*1000,0)
Gui,GST_Set:Add,Text,x163 vg_TimeOutTxt,毫秒
Gui,GST_Set:Add,CheckBox,x20 Checked%b_ShowTrace% ggst_Do vg_ShowTrace,显示轨迹(&R)
Gui,GST_Set:Add,Edit,x110 w40 h20 Limit1 Number ggst_Do vg_TraceWeight,
Gui,GST_Set:Add,UpDown,range1-9 vg_TWS,%str_gTraceWeight%
Gui,GST_Set:Add,Text,x160 c%str_gColor% ggst_Do vg_Color,▇▇
Gui,GST_Set:Add,CheckBox,x20 Checked%b_ShowTip% ggst_Do vg_ShowTip,显示手势动作和提示(&I)
Gui,GST_Set:Add,CheckBox,x20 Checked%b_FixPos% ggst_Do vg_FixPos,固定提示位置到左下角(&F)

Menu,g_MenuWin,Add,编辑窗口(&E),gcmd_MenuWin
Menu,g_MenuWin,Add,添加窗口(&N),gcmd_MenuWin
Menu,g_MenuWin,Add,
Menu,g_MenuWin,Add,移除窗口(&D),gcmd_MenuWin

Menu,g_MenuGST,Add,编辑手势(&E),gcmd_MenuGST
Menu,g_MenuGST,Add,添加手势(&N),gcmd_MenuGST
Menu,g_MenuGST,Add,
Menu,g_MenuGST,Add,剪切(&X),gcmd_MenuGST
Menu,g_MenuGST,Add,复制(&C),gcmd_MenuGST
Menu,g_MenuGST,Add,
Menu,g_MenuGST,Add,粘贴(&P),gcmd_MenuGST
Menu,g_MenuGST,Disable,粘贴(&P)
Menu,g_MenuGST,Add,
Menu,g_MenuGST,Add,删除手势(&D),gcmd_MenuGST

Gui,GST_Set:Show,h500 w750,鼠标手势管理器 - [通用]
GuiControl,GST_Set:Enable%b_TimeChk%,g_TimeOut
GuiControl,GST_Set:Enable%b_ShowTip%,g_FixPos
arr_GstWins:=[],arr_GstExWins:=[]
;;获取使用鼠标手势的窗口
IniRead,tempStr,%_INI_PATH%,Gesture,Default
tempStr=%tempStr%
arr_GstWins.push(["Default",0,"通用",tempStr])	;窗口标识|标识类别|显示名称|该窗口已定义手势字符串
;Default——添加默认窗口
Loop
{
	IniRead,tempStr,%_INI_PATH%,Gesture,%A_Index%
	If (tempStr="ERROR")
		Break
	tempStr:=Trim(tempStr),getStr1:=getStr2:=getStr3:=getStr4:=""
	Loop,Parse,tempStr,|
		getStr%A_Index%:=Trim(A_LoopField)
	arr_GstWins.push([getStr1,getStr2,getStr3,getStr4])	;窗口标识|标识类别|显示名称|该窗口已定义手势字符串
	;arr_GstWins=[["Default",0,"通用","手势"],["acad.exe,gcad.exe,ZWCAD.exe",2,"手势"],["KenPlayer",1,"手势"]]
}
;;获取禁用鼠标手势的窗口
IniRead,tempStr,%_INI_PATH%,Gesture,0
tempStr=%tempStr%
If (tempStr<>""){
	Loop,Parse,tempStr,|
	{
		getStr1:=getStr2:=getStr3:="",RegexMatch(A_LoopField,"([^@]+)@([^@]+)@?(.*)",getStr),getStr1:=Trim(getStr1),getStr2:=Trim(getStr2),getStr3:=Trim(getStr3)
		If getStr2 Not In 1,2,3
			Continue
		If (getStr1<>"") And (getStr2<>"") And RegexMatch(getStr2,"^[1-3]{1}$")
			arr_GstExWins.push([getStr1,getStr2,getStr3])	;窗口标识|标识类别|显示名称
			;arr_GstExWins:=[["TTOTAL_CMD,Warcraft III,MangaMeeya",1,常用],["vmwindow.exe,VirtualBox.exe",2,虚拟机]]
	}
}
Gosub gst_WinsUpdate
GuiControl,GST_Set:Choose,ctrl_GSTWin,1
arr_GSTList:=gst_GetGST(1),str_GSTGetWinIndex:=curr_WinIndex:=1,arr_Clip:=[],arr_ListClip:=[],str_Clip:=tempStr:=getStr1:=getStr2:=getStr3:=getStr4:=""
Return

GST_SetGuiSize:
GuiControl,GST_Set:Move,ctrl_GSTWin,% "h" A_GuiHeight-168
GuiControl,GST_Set:Move,ctrl_GSTList,% "w" A_GuiWidth-205 "h" A_GuiHeight
GuiControl,GST_Set:MoveDraw,g_GSTOption,% "y" A_GuiHeight-163
GuiControl,GST_Set:MoveDraw,g_TimeChk,% "y" A_GuiHeight-128
GuiControl,GST_Set:MoveDraw,g_TimeOut,% "y" A_GuiHeight-130
GuiControl,GST_Set:MoveDraw,g_TimeOutTxt,% "y" A_GuiHeight-128
GuiControl,GST_Set:MoveDraw,g_ShowTrace,% "y" A_GuiHeight-98
GuiControl,GST_Set:MoveDraw,g_TraceWeight,% "y" A_GuiHeight-100
GuiControl,GST_Set:MoveDraw,g_TWS,% "y" A_GuiHeight-100
GuiControl,GST_Set:MoveDraw,g_Color,% "y" A_GuiHeight-100
GuiControl,GST_Set:MoveDraw,g_ShowTip,% "y" A_GuiHeight-70
GuiControl,GST_Set:MoveDraw,g_FixPos,% "y" A_GuiHeight-42
Lv_ModifyCol(2,A_GuiWidth-520)
Return

GST_SetGuiContextMenu:
If (A_GuiControl="ctrl_GSTWin"){
	GuiControl,GST_Set:Choose,ctrl_GSTWin,%str_GSTGetWinIndex%
	Menu,g_MenuWin,% (str_GSTGetWinIndex=1)?"Disable":"Enable",编辑窗口(&E)
	Menu,g_MenuWin,% (str_GSTGetWinIndex=1)?"Disable":"Enable",移除窗口(&D)
	Menu,g_MenuWin,Show
}
If (A_GuiControl="ctrl_GSTList"){
	GuiControlGet,tempStr,GST_Set:Enabled,ctrl_GSTList
	If !tempStr
		Return
	str_GSTEditIndex:=Lv_GetNext()
	If (str_GSTEditIndex>0)
		Lv_GetText(str_GstKey,str_GSTEditIndex)
	Menu,g_MenuGST,% (str_GSTEditIndex>0)?"Enable":"Disable",编辑手势(&E)
	Menu,g_MenuGST,% (str_GSTEditIndex>0)?"Enable":"Disable",删除手势(&D)
	Menu,g_MenuGST,% (str_GSTEditIndex>0)?"Enable":"Disable",复制(&C)
	Menu,g_MenuGST,% (str_GSTEditIndex>0)?"Enable":"Disable",剪切(&X)
	Menu,g_MenuGST,Show
}
Return

gst_Do:
If (A_GuiControl="ctrl_GSTWin"){
	If A_GuiEvent In DoubleClick
	{
		If (A_EventInfo=1)
			Return
		str_GSTGetWinIndex:=A_EventInfo,Is_GstAddWin:=0
		Gosub GestureEdit_Win
		Return
	}
	GuiControlGet,str_GSTGetWinIndex,GST_Set:,ctrl_GSTWin	;str_GSTGetWinIndex——当前点击的窗口在列表中的序号
	If (str_GSTGetWinIndex<>curr_WinIndex)	;curr_WinIndex:——已保存的窗口序号
	{
		curr_WinIndex:=str_GSTGetWinIndex,Lv_Delete()
		If (str_GSTGetWinIndex>arr_GstWins.Length())	;当前为禁用手势窗口
		{	;curr_WinArrName——窗口数组名，便于调用
			;curr_WinArrIndex——当前窗口在自身类别中的序号
			;b_IsWinArr——标识，是否为使用手势的窗口
			Lv_Add("","不使用鼠标手势"),curr_WinArrName:="arr_GstExWins"
			,curr_WinArrIndex:=str_GSTGetWinIndex-arr_GstWins.Length(),b_IsWinArr:=0
			GuiControl,GST_Set:Disable,ctrl_GSTList
		}Else{
			arr_GSTList:=gst_GetGST(str_GSTGetWinIndex),curr_WinArrName:="arr_GstWins"
			,curr_WinArrIndex:=str_GSTGetWinIndex,b_IsWinArr:=1
			GuiControl,GST_Set:Enable,ctrl_GSTList
		}
		Gui,GST_Set:Show,,% "鼠标手势管理器 - [" . ((%curr_WinArrName%[curr_WinArrIndex][3]="")?%curr_WinArrName%[curr_WinArrIndex][1]:%curr_WinArrName%[curr_WinArrIndex][3]) . "]"
	}
}Else If (A_GuiControl="ctrl_GSTList"){
	If A_GuiEvent In DoubleClick
	{
		str_GSTEditIndex:=Lv_GetNext()
		If (str_GSTEditIndex>0){
			Is_GSTEdit:=1,Lv_GetText(str_GstKey,str_GSTEditIndex)
			Gosub GestureEdit_GST
		}
	}
}Else If (A_GuiControl="g_TimeChk"){
	GuiControlGet,b_TimeChk,GST_Set:,%A_GuiControl%
	GuiControl,GST_Set:Enable%b_TimeChk%,g_TimeOut
}Else If (A_GuiControl="g_TimeOut"){
	GuiControlGet,tempStr,GST_Set:,%A_GuiControl%
	tempStr=%tempStr%
	If (tempStr="") Or RegExMatch(tempStr,"[^\d]") Or (tempStr<500) Or (tempStr>5000)
	{
		gst_TimeOut:=1.2
		GuiControl,GST_Set:,g_TimeOut,1200
	}Else
		gst_TimeOut:=Round(tempStr/1000,1)
	tempStr=
}Else If (A_GuiControl="g_ShowTrace"){
	GuiControlGet,b_ShowTrace,GST_Set:,%A_GuiControl%
	GuiControl,GST_Set:Show%b_ShowTrace%,g_Color
	GuiControl,GST_Set:Show%b_ShowTrace%,g_TraceWeight
	GuiControl,GST_Set:Show%b_ShowTrace%,g_TWS
}Else If (A_GuiControl="g_TraceWeight"){
	GuiControlGet,str_gTraceWeight,GST_Set:,%A_GuiControl%
	If (str_gTraceWeight<1) Or (str_gTraceWeight>9)
	{
		GuiControl,GST_Set:,g_TraceWeight,3
		str_gTraceWeight:=3
	}
}Else If (A_GuiControl="g_Color"){
	Gui,GST_Set:+OwnDialogs
	InputBox,tempStr,鼠标轨迹颜色（HTML格式）,,,250,100,,,,,%str_gColor%
	If ErrorLevel
		Return
	tempStr=%tempStr%
	If (tempStr="") Or RegexMatch(tempStr,"i)^[0-9a-f]{6}$")
	{
		If (tempStr="")
			tempStr:="556FC7"
		Gui,Font,c%tempStr%
		GuiControl,gst_Set:Font,g_Color
		str_gColor:=tempStr,gdi_Color:=gdi_GetColor(tempStr),tempStr:=""
	}
}Else If (A_GuiControl="g_ShowTip"){
	GuiControlGet,b_ShowTip,GST_Set:,%A_GuiControl%
	GuiControl,GST_Set:Enable%b_ShowTip%,g_FixPos
	If !b_ShowTip
		ToolTip,,,,17
}Else If (A_GuiControl="g_FixPos")
	GuiControlGet,b_FixPos,GST_Set:,%A_GuiControl%
Return

gcmd_MenuWin:
If A_ThisMenuItemPos In 1,2		;编辑/添加窗口
{
	Is_GstAddWin:=A_ThisMenuItemPos-1
	Gosub GestureEdit_Win
}Else{		;移除窗口
	Gui,GST_Set:+OwnDialogs
	MsgBox,262180,移除窗口,确定要移除选择的窗口？
	IfMsgBox,No
		Return
	If !b_IsWinArr	;移除的是禁用手势窗口
	{
		Loop,Parse,% arr_GstExWins[curr_WinArrIndex][1],`,
			arr_NoMGWin.Delete(A_LoopField)
	}Else{	;移除的是手势窗口
		Loop,Parse,% arr_GstWins[str_GSTGetWinIndex][1],`,
			arr_GstAction.Delete(A_LoopField)
		nCount:=arr_GstWins.Length()
	}
	%curr_WinArrName%.RemoveAt(curr_WinArrIndex)
	If !b_IsWinArr
		Gosub gst_ExWins2Ini
	Else{
		Loop,%nCount%
			IniDelete,%_INI_PATH%,Gesture,%A_Index%
		Loop,% arr_GstWins.Length()
		{
			If (A_Index=1)
				Continue
			IniWrite,% arr_GstWins[A_index][1] . "|" . arr_GstWins[A_index][2] . "|" . arr_GstWins[A_index][3] . "|" . arr_GstWins[A_index][4],%_INI_PATH%,Gesture,% A_Index-1
		}
	}
	nCount:="",str_GSTGetWinIndex:=1,curr_WinIndex:=0
	Gui,GST_Set:Show,,鼠标手势管理器 - [通用]
	Gosub gst_WinsUpdate
	GuiControl,GST_Set:Choose,ctrl_GSTWin,1
	Gui,GST_Set:Default
	Lv_Delete(),arr_GSTList:=gst_GetGST(1)
	GuiControl,GST_Set:Enable,ctrl_GSTList
}
Return

gcmd_MenuGST:
If A_ThisMenuItemPos In 1,2	;编辑/添加手势
{
	Is_GSTEdit:=Abs(A_ThisMenuItemPos-2)
	Gosub GestureEdit_GST
}Else If A_ThisMenuItemPos In 4,5	;剪切/复制手势
{
	Gui,GST_Set:Default
	str_Clip:=str_GstKey,arr_Clip:=arr_GSTList[str_GstKey]
	,Lv_GetText(getStr1,str_GSTEditIndex,2),Lv_GetText(getStr2,str_GSTEditIndex,3)
	,arr_ListClip:=[getStr1,getStr2]
	If (A_ThisMenuItemPos=4)
		Gosub gst_DelGST
	Menu,g_MenuGST,Enable,粘贴(&P)
}Else If (A_ThisMenuItemPos=7){	;粘贴手势
	If arr_GSTList.Haskey(str_Clip)
	{
		func_ShowInfoTip("待粘贴手势“" str_Clip "”已存在！",,,,0)
		Return
	}
	;arr_Clip:=["19","close{enter}","关闭当前页"]
	;arr_GSTList["DL"]:=["19","close{enter}","关闭当前页"]
	;--------
	Gui,GST_Set:Default
	Lv_Add("Select Focus",str_Clip,arr_ListClip[1],arr_ListClip[2])
	arr_GSTList[str_Clip]:=arr_Clip
	Loop,Parse,% arr_GstWins[str_GSTGetWinIndex][1],`,
		arr_GstAction[A_LoopField][str_Clip]:=arr_Clip
	arr_GstWins[str_GSTGetWinIndex][4] .= "," . str_Clip . "@" . arr_Clip[1] . ((arr_Clip[2]="")?"":(":" . arr_Clip[2])) . ((arr_Clip[3]="")?"":("@" . arr_Clip[3]))
	If (str_GSTGetWinIndex=1)
		IniWrite,% arr_GstWins[str_GSTGetWinIndex][4],%_INI_PATH%,Gesture,Default
	Else
		IniWrite,% arr_GstWins[str_GSTGetWinIndex][1] . "|" . arr_GstWins[str_GSTGetWinIndex][2] . "|" . arr_GstWins[str_GSTGetWinIndex][3] . "|" . arr_GstWins[str_GSTGetWinIndex][4],%_INI_PATH%,Gesture,% str_GSTGetWinIndex-1
	str_Clip:="",arr_Clip:=[],arr_ListClip:=[]
	Menu,g_MenuGST,Disable,粘贴(&P)
}Else If (A_ThisMenuItemPos=9){	;删除手势
	Gui,GST_Set:+OwnDialogs
	MsgBox,262180,移除手势,确定要移除选择的手势？`n注意：该操作无法恢复！
	IfMsgBox,No
		Return
	Gosub gst_DelGST
}
Return

gst_WinsUpdate:	;更新窗口列表
GuiControl,GST_Set:-ReDraw,ctrl_GSTWin
GuiControl,GST_Set:,ctrl_GSTWin,|
Loop,% arr_GstWins.Length()
	GuiControl,GST_Set:,ctrl_GSTWin,% (arr_GstWins[A_index][3]="")?arr_GstWins[A_index][1]:arr_GstWins[A_index][3]
Loop,% arr_GstExWins.Length()
{
	nCount:=1
	GuiControl,GST_Set:,ctrl_GSTWin,% "~" . ((arr_GstExWins[A_index][3]="")?("禁用手势窗口" . nCount):arr_GstExWins[A_index][3]),nCount+=1
}
GuiControl,GST_Set:+ReDraw,ctrl_GSTWin
nCount=
Return

gst_GetGST(i){
	;获取指定窗口已定义的手势数据（数组），并添加到列表
	Global arr_GstWins,arr_GstCmd
	arr_Temp:=parse_Cmd2Arr(arr_GstWins[i][4])	;arr_Temp["DL"]:=["19","close{enter}","关闭当前页"]
	GuiControl,GST_Set:-ReDraw,ctrl_GSTList
	For s1,s2 In arr_Temp
		Lv_Add("",s1,(s2[1]=0)?"不执行任何动作":(arr_GstCmd[s2[1]][2] . ((arr_GstCmd[s2[1]][1]="key_Hotkey")?("【" . keys_Switch(s2[2],0) . "】"):((arr_GstCmd[s2[1]][1]="key_SendKey")?("【" . s2[2] . "】"):""))),s2[3])
	GuiControl,GST_Set:+ReDraw,ctrl_GSTList
	s1:=s2:=""
	Return arr_Temp
}

gst_ExWins2Ini:
tempStr=
Loop,% arr_GstExWins.Length()
	tempStr .= ((A_Index=1)?"":"|") . arr_GstExWins[A_index][1] . "@" . arr_GstExWins[A_index][2] . ((arr_GstExWins[A_index][3]="")?"":("@" . arr_GstExWins[A_index][3]))
IniWrite,%tempStr%,%_INI_PATH%,Gesture,0
tempStr=
Return

GST_SetGuiClose:
GST_SetGuiEscape:
tempStr:=b_TimeChk . b_ShowTrace . b_ShowTip . b_FixPos . "|" .  str_gTraceWeight . "|" . str_gColor . "|" . Round(gst_TimeOut*1000,0)
If (tempStr<>last_EGOption){
	IniWrite,%tempStr%,%_INI_PATH%,Gesture,Option
	last_EGOption:=tempStr
}
arr_GstWins:=[],arr_GstExWins:=[],arr_GSTList:=[],str_Clip:=0,arr_Clip:=[],str_GSTGetWinIndex:=str_GSTEditIndex:=str_GstKey:=tempStr:=""
Menu,g_MenuWin,Delete
Menu,g_MenuGST,Delete
Gui,GST_Set:Destroy
ToolTip,,,,17
Return

; ------------- 鼠标手势窗口编辑 -----

GestureEdit_Win:
FullIco_File:=A_Temp . "\g_Full.ico",NullIco_File:=A_Temp . "\g_Null.ico"
IfNotExist,%FullIco_File%
	Full_ico:="0000010001002020100000000000E8020000160000002800000020000000400000000100040000000000000200000000000000000000100000001000000000000000000080000080000000808000800000008000800080800000C0C0C000808080000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00000000000000000000000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFF00000FFFFFFFFFFFF000FFFFFFFFFF00FF0FF00FFFFFFFFFF000FFFFFFFFF0FF00000FF0FFFFFFFFF000FFFFFFFF0FFFFF0FFFFF0FFFFFFFF000FFFFFFF0FFFF00000FFFF0FFFFFFF000FFFFFFF0FFFFFF0FFFFFF0FFFFFFF000FFFFFF0F0F0FF000FF0F0F0FFFFFF000FFFFFF0F0F0F0FFF0F0F0F0FFFFFF000FFFFFF0000000F0F0000000FFFFFF000FFFFFF0F0F0F0FFF0F0F0F0FFFFFF000FFFFFF0F0F0FF000FF0F0F0FFFFFF000FFFFFFF0FFFFFF0FFFFFF0FFFFFFF000FFFFFFF0FFFF00000FFFF0FFFFFFF000FFFFFFFF0FFFFF0FFFFF0FFFFFFFF000FFFFFFFFF0FF00000FF0FFFFFFFFF000FFFFFFFFFF00FF0FF00FFFFFFFFFF000FFFFFFFFFFFF00000FFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000000000000007770CCCCCCCCCCCCCCCCCCCCC07770007070CCCCCCCCCCCCCCCCCCCCC07070007770CCCCCCCCCCCCCCCCCCCCC0777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFFFFFFF80000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000FFFFFFFFFFFFFFFFFFFFFFFF",BYTE_TO_FILE(StrToBin(Full_ico),FullIco_File),Full_ico:=""
IfNotExist,%NullIco_File%
	Null_ico:="0000010001002020100000000000E8020000160000002800000020000000400000000100040000000000000200000000000000000000100000001000000000000000000080000080000000808000800000008000800080800000C0C0C000808080000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00000000000000000000000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000000000000007770CCCCCCCCCCCCCCCCCCCCC07770007070CCCCCCCCCCCCCCCCCCCCC07070007770CCCCCCCCCCCCCCCCCCCCC0777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFFFFFFF80000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000800000008000000080000000FFFFFFFFFFFFFFFFFFFFFFFF",BYTE_TO_FILE(StrToBin(Null_ico),NullIco_File),Null_ico:=""
Gosub ahk_CurSet
Gui,GST_Set:+Disabled
Gui,GST_EditWin:New
Gui,GST_EditWin:-MinimizeBox +Owner%GST_ID% +Hwndgst_GetWin
Gui,GST_EditWin:Font,,Tahoma
Gui,GST_EditWin:Font,,Microsoft Yahei
Gui,GST_EditWin:Add,GroupBox,x10 y2 w317 h233,
Gui,GST_EditWin:Font,Bold
Gui,GST_EditWin:Add,Text,x20 y24,# 窗口别名(&F):
Gui,GST_EditWin:Font,Normal
Gui,GST_EditWin:Add,Edit,x105 y20 w210 r1 vgst_WinTit,% Is_GstAddWin?"":%curr_WinArrName%[curr_WinArrIndex][3]
Gui,GST_EditWin:Add,Text,x20 y55 w220,支持使用窗口类、文件名或窗口标题来指定应用程序窗口。拖动探测工具到程序窗口上可获取该窗口标识。
Gui,GST_EditWin:Add,GroupBox,x250 y53 w65 h60 c000080,探测工具
Gui,GST_EditWin:Add,Picture,x266 y73 w32 h-1 Icon1 ggst_WinDo vgst_SwitchICO,%FullIco_File%
Gui,GST_EditWin:Font,Bold
Gui,GST_EditWin:Add,Text,x20 y120,# 窗口标识(&I): 
Gui,GST_EditWin:Font,Normal
Gui,GST_EditWin:Add,Text,x115 y120,支持多个同类别窗口，每行一个
Gui,GST_EditWin:Add,Edit,x115 y145 w200 -Wrap r4 hwndg_WinName vgst_WinName,% Is_GstAddWin?"":(StrReplace(%curr_WinArrName%[curr_WinArrIndex][1],",","`n") . "`n")
Gui,GST_EditWin:Add,Radio,x25 y145 ggst_WinDo vgst_Type1,窗口类(&L)
Gui,GST_EditWin:Add,Radio,x25 y170 ggst_WinDo vgst_Type2,文件名(&N)
Gui,GST_EditWin:Add,Radio,x25 y195 ggst_WinDo vgst_Type3,窗口标题(&T)
Gui,GST_EditWin:Font,bold
tempStr:=1-Is_GstAddWin
Gui,GST_EditWin:Add,CheckBox,x12 y255 Disabled%tempStr% vgst_ExcWin,禁用手势(&X)
Gui,GST_EditWin:Font,Norm
Gui,GST_EditWin:Add,Button,x160 y245 w90 ggst_WinDo vgst_WinSave,保存(&S)
Gui,GST_EditWin:Add,Button,x255 y245 w70 ggst_WinDo vgst_WinCancel,取消(&C)
tempStr:=Is_GstAddWin?1:%curr_WinArrName%[curr_WinArrIndex][2]
GuiControl,GST_EditWin:,gst_Type%tempStr%,1
tempStr=
GuiControl,GST_EditWin:,gst_ExcWin,% Is_GstAddWin?0:!b_IsWinArr
Gui,GST_EditWin:Show,w335,% Is_GstAddWin?"添加窗口":"编辑窗口"
Return

gst_WinDo:
If (A_GuiControl="gst_SwitchICO"){
	IfNotExist,%CUR_File%
		BYTE_TO_FILE(StrToBin(Cross_CUR),CUR_File)
	IfNotExist,%NullIco_File%
		BYTE_TO_FILE(StrToBin(Null_ico),NullIco_File)
	GuiControl,GST_EditWin:,gst_SwitchICO,%NullIco_File%
	;设置鼠标指针为十字标
	CursorHandle:=DllCall("LoadCursorFromFile",Str,CUR_File),DllCall("SetSystemCursor",Uint,CursorHandle,Int,32512)
	;等待左键弹起
	KeyWait,Lbutton
	MouseGetPos,,,gst_GetWinID
	;还原鼠标指针
	DllCall("SystemParametersInfo",UInt,0x57,UInt,0,UInt,0,UInt,0)
	;图标设置为原样
	IfNotExist,%FullIco_File%
		BYTE_TO_FILE(StrToBin(Full_ico),FullIco_File)
	GuiControl,GST_EditWin:,gst_SwitchICO,%FullIco_File%
	If (gst_GetWinID=gst_GetWin)
		Return
	GuiControl,GST_EditWin:Focus,gst_WinName
	SendInput ^{End}
	Loop,3
	{
		GuiControlGet,tempStr,GST_EditWin:,gst_Type%A_Index%
		If (tempStr=1){
			gst_TypeGetIndex:=A_Index
			Break
		}
	}
	errFlag:=0
	If (gst_TypeGetIndex=1){
		WinGetClass,tempStr,Ahk_Id %gst_GetWinID%
		If (SubStr(tempStr,1,4)="Afx:"){
			Gui,+OwnDialogs
			MsgBox,262192,添加程序窗口,
	(
	当前窗口的类名:“%tempStr%”
	为可变类，使用可变类名作为标识符可能造成窗口识别不准确！
	`n请选用“文件名”或“窗口标题”作为窗口标识符。
	)
			GuiControl,GST_EditWin:,Type_2,1
			errFlag:=1
		}
	}Else If (gst_TypeGetIndex=2)
		WinGet,tempStr,ProcessName,Ahk_Id %gst_GetWinID%
	Else If (gst_TypeGetIndex=3)
		WinGetTitle,tempStr,Ahk_Id %gst_GetWinID%
	If (errFlag=0){
		Control,EditPaste,%tempStr%`n,,Ahk_Id%g_WinName%
		tempStr:=StrLen(tempStr)+1
		SendInput +{Left %tempStr%}
	}
	tempStr:=errFlag:=gst_GetWinID:=gst_TypeGetIndex:=""
}Else If (SubStr(A_GuiControl,1,-1)="gst_Type"){
	GuiControlGet,tempStr,GST_EditWin:,gst_WinName
	tempStr=%tempStr%
	If (tempStr<>""){
		Gui,+OwnDialogs
		MsgBox,262192,多窗口标识,已存在窗口标识，添加多个窗口须保持类别一致！
	}
	tempStr=
}Else If (A_GuiControl="gst_WinSave"){
	GuiControlGet,getStr1,GST_EditWin:,gst_WinName	;getStr1——窗口标识
	getStr1:=Trim(StrReplace(getStr1,"`n","`,") ,"`t `,")
	If (getStr1=""){
		GuiControl,GST_EditWin:Focus,gst_WinName
		Return
	}
	Loop,3
	{
		GuiControlGet,tempStr,GST_EditWin:,gst_Type%A_Index%
		If tempStr
		{
			getStr2:=A_Index	;getStr2——窗口标识类型
			Break
		}
	}
	GuiControlGet,getStr3,GST_EditWin:,gst_WinTit	;getStr3——窗口标题
	getStr3=%getStr3%
	GuiControlGet,getStr4,GST_EditWin:,gst_ExcWin	;getStr4——是否禁用手势的窗口
	Gosub GST_EditWinGuiClose
	Gui,GST_Set:Default
	If Is_GstAddWin	;添加新窗口
	{
		Lv_Delete()
		If getStr4	;禁用手势的窗口
		{
			Lv_Add("","不使用鼠标手势"),arr_GstExWins.Push([getStr1,getStr2,getStr3])
			,curr_WinArrName:="arr_GstExWins",str_GSTGetWinIndex:=arr_GstWins.Length()+arr_GstExWins.Length()
			,curr_WinArrIndex:=arr_GstExWins.Length(),b_IsWinArr:=0
			Loop,Parse,getStr1,`,
				arr_NoMGWin[A_LoopField]:=1
			GuiControl,GST_Set:Disable,ctrl_GSTList
		}Else{	;手势窗口
			arr_GstWins.Push([getStr1,getStr2,getStr3]),curr_WinArrName:="arr_GstWins"
			,str_GSTGetWinIndex:=curr_WinArrIndex:=arr_GstWins.Length(),b_IsWinArr:=1,arr_GSTList:=[]
			Loop,Parse,getStr1,`,
			{
				If (A_LoopField<>"")
					arr_GstAction[A_LoopField]:=[]
			}
			IniWrite,% getStr1 . "|" . getStr2 . "|" . getStr3 . "|",%_INI_PATH%,Gesture,% arr_GstWins.Length()-1
		}
	}Else{	;编辑已有窗口
		tempStr:=%curr_WinArrName%[curr_WinArrIndex][1]
		If (getStr1<>tempStr)	;窗口标识改变，则删除原来的窗口定义，并更新为新窗口
		{
			;处理手势数组
			If getStr4	;如为禁用手势窗口
			{
				Loop,Parse,tempStr,`,
					arr_NoMGWin.Delete(A_LoopField)
				Loop,Parse,getStr1,`,
					arr_NoMGWin[A_LoopField]:=1
			}Else{
				Loop,Parse,tempStr,`,
					arr_Temp:=arr_GstAction.Delete(A_LoopField)
				Loop,Parse,getStr1,`,
					arr_GstAction[A_LoopField]:=arr_Temp
			}
		}
		;更新窗口数组的窗口特征，手势不变
		Loop,3
			%curr_WinArrName%[curr_WinArrIndex][A_index]:=getStr%A_Index%
		If !getStr4	;手势窗口
			IniWrite,% getStr1 . "|" . getStr2 . "|" . getStr3 . "|" . arr_GstWins[curr_WinArrIndex][4],%_INI_PATH%,Gesture,% str_GSTGetWinIndex-1
	}
	If getStr4	;禁用手势的窗口
		Gosub gst_ExWins2Ini
	Gui,GST_Set:Show,,% "鼠标手势管理器 - [" . ((getStr3="")?getStr1:getStr3) . "]"
	Gosub gst_WinsUpdate
	GuiControl,GST_Set:Choose,ctrl_GSTWin,%str_GSTGetWinIndex%
	arr_Temp:=[],getStr1:=getStr2:=getStr3:=getStr4:=tempStr:=""
}Else If (A_GuiControl="gst_WinCancel")
	Gosub GST_EditWinGuiClose
Return

ahk_CurSet:
CUR_File:=A_Temp . "\g_Cross.cur"
IfNotExist,%CUR_File%
{
	Cross_CUR:="000002000100202002000F00100034010000160000002800000020000000400000000100010000000000800000000000000000000000020000000200000000000000FFFFFF000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF83FFFFFE6CFFFFFD837FFFFBEFBFFFF783DFFFF7EFDFFFEAC6AFFFEABAAFFFE0280FFFEABAAFFFEAC6AFFFF7EFDFFFF783DFFFFBEFBFFFFD837FFFFE6CFFFFFF83FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF28000000"
	BYTE_TO_FILE(StrToBin(Cross_CUR),CUR_File),Cross_CUR:=""
}
Return

GST_EditWinGuiClose:
GST_EditWinGuiEscape:
Gui,GST_Set:-Disabled
Gui,GST_EditWin:Destroy
Return

; ------------- 鼠标手势编辑 -----

GestureEdit_GST:
Gui,GST_Set:+Disabled
Gui,GST_EditGST:New
Gui,GST_EditGST:-MinimizeBox +Owner%GST_ID% +HwndGSTEdit_ID
Gui,GST_EditGST:Font,,Tahoma
Gui,GST_EditGST:Font,,Microsoft Yahei

Gui,GST_EditGST:Add,GroupBox,x10 y5 w280 h95,手势组合(&G)
Gui,GST_EditGST:Add,Edit,x20 y35 w260 r1 UpperCase Disabled%Is_GSTEdit% vgst_GST,% Is_GSTEdit?str_GstKey:""
Gui,GST_EditGST:Add,Text,x22 y75,U—上；  D—下；  L—左；  R—右

Gui,GST_EditGST:Add,GroupBox,x10 y110 w280 h155,执行动作(&Z)
Gui,GST_EditGST:Add,DropDownList,x20 y140 w260 AltSubmit ggst_CMD vgst_CMD,0 - 无||
Gui,GST_EditGST:Font,Bold
Gui,GST_EditGST:Add,Edit,x20 y175 w260 r4 WantReturn Disabled hwndGst_Attr vgst_Para,
Gui,GST_EditGST:Font,Norm

Gui,GST_EditGST:Add,GroupBox,x10 y275 w280 h75,（可选）手势提示文字(&P)
Gui,GST_EditGST:Add,Edit,x20 y305 w260 r1 vgst_GSTTip,% Is_GSTEdit?arr_GSTList[str_GstKey][3]:""

Gui,GST_EditGST:Add,Link,x10 y370 Hidden ggst_Help vgst_Help,<a>？说明</a>
Gui,GST_EditGST:Add,Button,x125 y360 w90 ggst_EditSave,保存(&S)
Gui,GST_EditGST:Add,Button,x220 y360 w70 ggst_EditCancel,取消(&C)
Gui,GST_EditGST:Show,w300,鼠标手势编辑器
Loop,% arr_GstCmd.Length()
	GuiControl,GST_EditGST:,gst_CMD,% A_Index . " - " . arr_GstCmd[A_index][2]
If Is_GSTEdit	;编辑手势
{
	tempStr:=arr_GSTList[str_GstKey][1]+1	;arr_GSTList["DL"]:=["19","close{enter}","关闭当前页"]
	GuiControl,GST_EditGST:Choose,gst_CMD,%tempStr%
	GuiControl,% (tempStr=1)?"GST_EditGST:Disable":"GST_EditGST:Enable",gst_GSTTip
	tempStr-=1,tempStr:=arr_GstCmd[tempStr][1]
	If tempStr In key_Hotkey,key_SendKey,file_Web,file_RunApp
	{
		GuiControl,GST_EditGST:Enable,gst_Para
		GuiControl,GST_EditGST:,gst_Para,% StrReplace(arr_GSTList[str_GstKey][2],"``","`n")
		If tempStr In file_Web,file_RunApp
			GuiControl,GST_EditGST:Show,gst_Help
	}
	tempStr=
}
Return

GST_EditGSTGuiDropFiles:
If (A_GuiControl="gst_Para") And _gst_InsertFile()
{
	tempStr:=A_GuiEvent
	Control,EditPaste,% strReplace(tempStr,"`n","`r`n"),,Ahk_Id %Gst_Attr%
	tempStr:=StrLen(tempStr)
	SendInput +{Left %tempStr%}
	tempStr=
}
Return

gst_CMD:
GuiControlGet,tempStr,GST_EditGST:,gst_CMD
GuiControl,% (tempStr=1)?"GST_EditGST:Disable":"GST_EditGST:Enable",gst_GSTTip
GuiControl,GST_EditGST:Hide,gst_Help
tempStr-=1,tempText:=arr_GstCmd[tempStr][1]
If tempText In key_Hotkey,key_SendKey,file_Web,file_RunApp
{
	GuiControl,GST_EditGST:Enable,gst_Para
	GuiControl,GST_EditGST:,gst_Para,% (Is_GSTEdit And (tempStr=arr_GSTList[str_GstKey][1]))?(StrReplace(arr_GSTList[str_GstKey][2],"``","`n")):""
	If tempText In file_Web,file_RunApp
		GuiControl,GST_EditGST:Show,gst_Help
}Else{
	GuiControl,GST_EditGST:,gst_Para,
	GuiControl,GST_EditGST:Disable,gst_Para
}
GuiControl,GST_EditGST:,gst_GSTTip,% (Is_GSTEdit And (tempStr=arr_GSTList[str_GstKey][1]))?arr_GSTList[str_GstKey][3]:""
tempStr:=tempText:=""
Return

gst_Help:
Gui,GST_EditGST:+OwnDialogs
MsgBox,262208,说明,
(
* 在文本框内输入网址或文件路径，每行一个
* 在文本框上按下「Insert」键可打开文件对话框选择文件
)
Return

gst_EditSave:
Gui,GST_EditGST:+OwnDialogs
If !Is_GSTEdit	;添加新手势
{
	GuiControlGet,str_GstKey,GST_EditGST:,gst_GST	;str_GstKey——手势
	str_GstKey=%str_GstKey%
	If (str_GstKey=""){
		GuiControl,GST_EditGST:Focus,gst_GST
		Return
	}
	If RegExMatch(str_GstKey,"[^LRUD]")
	{
		func_ShowInfoTip("手势只能包含“LRUD”四个符号！",,,,0)
		GuiControl,GST_EditGST:Focus,gst_GST
		SendInput ^a
		Return
	}
	If arr_GSTList.Haskey(str_GstKey)
	{
		func_ShowInfoTip("手势“" str_GstKey "”已存在，请勿重复定义！",,,,0)
		GuiControl,GST_EditGST:Focus,gst_GST
		SendInput ^a
		Return
	}
}
GuiControlGet,getStr1,GST_EditGST:,gst_CMD	;getStr1——命令
getStr1-=1,tempStr:=arr_GstCmd[getStr1][1]
If tempStr In key_Hotkey,key_SendKey,file_Web,file_RunApp
{
	GuiControlGet,tempPara,GST_EditGST:,gst_Para
	tempPara:=Trim(tempPara,"`n `t")
	If (tempPara=""){
		func_ShowInfoTip("该动作需附加参数！",,,,0)
		GuiControl,GST_EditGST:Focus,gst_GST
		Return
	}
	tempPara:=StrReplace(tempPara,"`n","``"),tempStr:=""
	If (arr_GstCmd[getStr1][1]="key_Hotkey"){	;发送热键
		StringLower,tempPara,tempPara
		tempText:=RegexReplace(tempPara,"[!\^\+#]"),tempPara:=StrReplace(tempPara,tempText)
		If (StrLen(tempText)>1)
			tempText:="{" . tempText . "}"
		tempPara.=tempText,tempStr:="【" . keys_Switch(tempPara,0) . "】",tempText:=""
	}Else If (arr_GstCmd[getStr1][1]="key_SendKey")
		tempStr:="【" . tempPara . "】"
	str_AttCmd:=arr_GstCmd[getStr1][2] . tempStr,tempStr:=""
}Else
	tempPara:="",str_AttCmd:=(getStr1=0)?"不执行任何动作":arr_GstCmd[getStr1][2]
GuiControlGet,getStr2,GST_EditGST:,gst_GSTTip	;getStr2——手势提示
getStr2=%getStr2%
Gosub GST_EditGSTGuiClose
;获取数据完成，开始后处理
Gui,GST_Set:Default
;获取手势字符串赋值变量 tempStr
tempStr:=str_GstKey . "@" . getStr1 . ((tempPara="")?"":(":" . tempPara)) . ((getStr2="")?"":("@" . getStr2))
If Is_GSTEdit	;编辑
{
	;arr_GSTList["DL"]:=["19","close{enter}","关闭当前页"]
	;arr_GstAction["Default"]["DL"]:=["19","close{enter}","关闭当前页"]
	;arr_GstWins=[["Default",0,"通用","手势"],["acad.exe,gcad.exe,ZWCAD.exe",2,"手势"],["KenPlayer",1,"手势"]]
	;--------
	Lv_Modify(str_GSTEditIndex,"Select Focus col2",str_AttCmd),Lv_Modify(str_GSTEditIndex,"Select Focus col3",getStr2)
	,arr_GstWins[str_GSTGetWinIndex][4]:=Trim(StrReplace("," . arr_GstWins[str_GSTGetWinIndex][4] . ",","," . (str_GstKey . "@" . arr_GSTList[str_GstKey][1] . ((arr_GSTList[str_GstKey][2]="")?"":(":" . arr_GSTList[str_GstKey][2])) . ((arr_GSTList[str_GstKey][3]="")?"":("@" . arr_GSTList[str_GstKey][3]))) . ",","," . tempStr . ","),",")
	,arr_GSTList[str_GstKey]:=[getStr1,tempPara,getStr2]
}Else	;添加
	Lv_Add("Select Focus",str_GstKey,str_AttCmd,getStr2),arr_GstWins[str_GSTGetWinIndex][4].="," . tempStr,arr_GSTList[str_GstKey]:=[getStr1,tempPara,getStr2]

Loop,Parse,% arr_GstWins[str_GSTGetWinIndex][1],`,
	arr_GstAction[A_LoopField][str_GstKey]:=[getStr1,tempPara,getStr2]

If (str_GSTGetWinIndex=1)
	IniWrite,% arr_GstWins[str_GSTGetWinIndex][4],%_INI_PATH%,Gesture,Default
Else
	IniWrite,% arr_GstWins[str_GSTGetWinIndex][1] . "|" . arr_GstWins[str_GSTGetWinIndex][2] . "|" . arr_GstWins[str_GSTGetWinIndex][3] . "|" . arr_GstWins[str_GSTGetWinIndex][4],%_INI_PATH%,Gesture,% str_GSTGetWinIndex-1
tempStr:=getStr1:=getStr2:=str_AttCmd:=tempPara:=""
Return

gst_DelGST:
Gui,GST_Set:Default
Lv_Delete(str_GSTEditIndex),arr_GstWins[str_GSTGetWinIndex][4]:=Trim(StrReplace("," . arr_GstWins[str_GSTGetWinIndex][4] . ",","," . (str_GstKey . "@" . arr_GSTList[str_GstKey][1] . ((arr_GSTList[str_GstKey][2]="")?"":(":" . arr_GSTList[str_GstKey][2])) . ((arr_GSTList[str_GstKey][3]="")?"":("@" . arr_GSTList[str_GstKey][3]))) . ",",","),",")
,arr_GSTList.Delete(str_GstKey)
Loop,Parse,% arr_GstWins[str_GSTGetWinIndex][1],`,
	arr_GstAction[A_LoopField].Delete(str_GstKey)
If (str_GSTGetWinIndex=1)
	IniWrite,% arr_GstWins[str_GSTGetWinIndex][4],%_INI_PATH%,Gesture,Default
Else
	IniWrite,% arr_GstWins[str_GSTGetWinIndex][1] . "|" . arr_GstWins[str_GSTGetWinIndex][2] . "|" . arr_GstWins[str_GSTGetWinIndex][3] . "|" . arr_GstWins[str_GSTGetWinIndex][4],%_INI_PATH%,Gesture,% str_GSTGetWinIndex-1
Return

#if WinActive("ahk_id" . GSTEdit_ID)
^s::Gosub gst_EditSave
#If

#if _gst_InsertFile()
Insert::
Gui,GST_EditGST:+OwnDialogs
FileSelectFile,tempStr,32,,选择文件
If ErrorLevel Or (tempStr="")
	Return
Control,EditPaste,%tempStr%,,Ahk_Id %Gst_Attr%
tempStr:=StrLen(tempStr)
SendInput +{Left %tempStr%}
tempStr=
Return
#if

_gst_InsertFile(){
	Global arr_GstCmd
	GuiControlGet,s1,GST_EditGST:FocusV
	GuiControlGet,s2,GST_EditGST:,gst_CMD
	Return ((s1="gst_Para") And (arr_GstCmd[s2-1][1]="file_RunApp"))?1:0
}

gst_EditCancel:
GST_EditGSTGuiClose:
GST_EditGSTGuiEscape:
Gui,GST_Set:-Disabled
Gui,GST_EditGST:Destroy
Return

; ------------- 计算函数 -----

gdi_GetColor(s){
	Return ToBase("0x" . SubStr(s,5,2) . SubStr(s,3,2) . SubStr(s,1,2),10)
}

ToBase(n,b){
	Return (n<b?"":ToBase(n//b,b)) . ((d:=Mod(n,b))<10?d:Chr(d+55))
}

; ------------- GDI -----

gdi_New()
{
	global my_gdi
	Gui,My_DrawingBoard:New
	Gui,+LastFound +AlwaysOnTop -Caption +ToolWindow +E0x80000 +OwnDialogs +Hwndmy_id +E0x20
	; 下面两行结合Bitblt更新与UpdateLayeredWindow更新互斥
	; Gui,Color,0x000000
	; WinSet,TransColor,0x000000
	SysGet,w,78
	SysGet,h,79
	;w:=A_ScreenWidth,h:=A_ScreenHeight
	Gui,Show,Hide x0 y0 w%w% h%h%,画板
	my_gdi:=new GDI(my_id,w,h),gdi_Empty()
	return
}

gdi_Show()
{
	Gui,My_DrawingBoard:Show,NA
}

gdi_Hide()
{
	Gui,My_DrawingBoard:Hide
}

gdi_Draw(x,y,x2,y2,color)
{
	global my_gdi,str_gTraceWeight
	my_gdi.DrawLine(x,y,x2,y2,color,str_gTraceWeight)
}

gdi_Update(color=0x000000)
{
	global my_gdi
	; my_gdi.Bitblt()
	my_gdi.UpdateLayeredWindow(0,0,0,0,color)
}

gdi_Empty(color=0x000000)
{
	global my_gdi
	my_gdi.FillRectangle(0,0,my_gdi.CliWidth,my_gdi.CliHeight,color)
}

class GDI
{
	__New(hWnd,CliWidth=0,CliHeight=0)
	{
		if !(CliWidth && CliHeight)
		{
			VarSetCapacity(Rect,16,0)
			DllCall("GetClientRect","Ptr",hWnd,"Ptr",&Rect)
			CliWidth:=NumGet(Rect,8,"Int")
			CliHeight:=NumGet(Rect,12,"Int")
		}
		this.hWnd:=hWnd
		this.CliWidth:=CliWidth
		this.CliHeight:=CliHeight
		this.hDC:=DllCall("GetDC","UPtr",this.hWnd,"UPtr")
		this.hMemDC:=DllCall("CreateCompatibleDC","UPtr",this.hDC,"UPtr")
		this.hBitmap:=DllCall("CreateCompatibleBitmap","UPtr",this.hDC,"Int",CliWidth,"Int",CliHeight,"UPtr")
		this.hOriginalBitmap:=DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",this.hBitmap)
		DllCall("ReleaseDC","UPtr",this.hWnd,"UPtr",this.hDC)
	}

	__Delete() {
		DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",this.hOriginalBitmap)
		DllCall("DeleteObject","UPtr",this.hBitmap)
		DllCall("DeleteObject","UPtr",this.hMemDC)
	}

	Resize(w,h)
	{
		this.CliWidth:=w
		this.CliHeight:=h
		this.hDC:=DllCall("GetDC","UPtr",this.hWnd,"UPtr")
		this.hBitmap:=DllCall("CreateCompatibleBitmap","UPtr",this.hDC,"Int",w,"Int",h,"UPtr")
		hPrevBitmap:=DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",this.hBitmap)
		DllCall("DeleteObject","UPtr",hPrevBitmap)
		DllCall("ReleaseDC","UPtr",this.hWnd,"UPtr",this.hDC)
	}

	BitBlt(x=0,y=0,w=0,h=0)
	{
		w:=w?w:this.CliWidth
		h:=h?h:this.CliHeight
		this.hDC:=DllCall("GetDC","UPtr",this.hWnd,"UPtr")
		DllCall("BitBlt","UPtr",this.hDC,"Int",x,"Int",y
		,"Int",w,"Int",h,"UPtr",this.hMemDC,"Int",0,"Int",0,"UInt",0xCC0020) ;SRCCOPY
		DllCall("ReleaseDC","UPtr",this.hWnd,"UPtr",this.hDC)
	}

	UpdateLayeredWindow(x=0,y=0,w=0,h=0,color=0,Alpha=255)
	{
		w:=w?w:this.CliWidth
		h:=h?h:this.CliHeight
		DllCall("UpdateLayeredWindow","UPtr",this.hWnd,"UPtr",0
		,"Int64*",x|y<<32,"Int64*",w|h<<32
		,"UPtr",this.hMemDC,"Int64*",0,"UInt",color
		,"UInt*",Alpha<<16|1<<24,"UInt",1)
	}

	DrawLine(x,y,x2,y2,Color,Width=1)
	{
		Pen:=new GDI.Pen(Color,Width)
		DllCall("MoveToEx","UPtr",this.hMemDC,"Int",this.TranslateX(x),"Int",this.TranslateY(y),"UPtr",0)
		hOriginalPen:=DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",Pen.Handle,"UPtr")
		DllCall("LineTo","UPtr",this.hMemDC,"Int",this.TranslateX(x2),"Int",this.TranslateY(y2))
		DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",hOriginalPen,"UPtr")
	}

	SetPixel(x,y,Color)
	{
		x:=this.TranslateX(x)
		y:=this.TranslateY(y,this.Invert) ; Move up 1 px if inverted (drawing "up" instead of down)
		DllCall("SetPixelV","UPtr",this.hMemDC,"Int",x,"Int",y,"UInt",Color)
	}

	FillRectangle(x,y,w,h,Color,BorderColor=-1)
	{
		if (w == 1 && h == 1)
		  return this.SetPixel(x,y,Color)
		Pen:=new this.Pen(BorderColor < 0?Color:BorderColor)
		Brush:=new this.Brush(Color)

		; Replace the original pen and brush with our own
		hOriginalPen:=DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",Pen.Handle,"UPtr")
		hOriginalBrush:=DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",Brush.Handle,"UPtr")

		x1:=this.TranslateX(x)
		y1:=this.TranslateY(y)
		x2:=this.TranslateX(x+w)
		y2:=this.TranslateY(y+h)

		DllCall("Rectangle","UPtr",this.hMemDC
		,"Int",x1,"Int",y1
		,"Int",x2,"Int",y2)

		; Reselect the original pen and brush
		DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",hOriginalPen,"UPtr")
		DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",hOriginalBrush,"UPtr")
	}

	FillEllipse(x,y,w,h,Color,BorderColor=-1)
	{
		Pen:=new this.Pen(BorderColor < 0?Color:BorderColor)
		Brush:=new this.Brush(Color)

		; Replace the original pen and brush with our own
		hOriginalPen:=DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",Pen.Handle,"UPtr")
		hOriginalBrush:=DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",Brush.Handle,"UPtr")

		x1:=this.TranslateX(x)
		y1:=this.TranslateY(y)
		x2:=this.TranslateX(x+w)
		y2:=this.TranslateY(y+h)

		DllCall("Ellipse","UPtr",this.hMemDC
		,"Int",x1,"Int",y1
		,"Int",x2,"Int",y2)

		; Reselect the original pen and brush
		DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",hOriginalPen,"UPtr")
		DllCall("SelectObject","UPtr",this.hMemDC,"UPtr",hOriginalBrush,"UPtr")
	}

	TranslateX(X)
	{
		return Floor(X)
	}

	TranslateY(Y,Offset=0)
	{
		if this.Invert
			return this.CliHeight - Floor(Y) - Offset
		return Floor(Y)
	}

	class Pen
	{
		__New(Color,Width=1,Style=0)
		{
			this.Handle:=DllCall("CreatePen","Int",Style,"Int",Width,"UInt",Color,"UPtr")
		}

		__Delete()
		{
			DllCall("DeleteObject","UPtr",this.Handle)
		}
	}

	class Brush
	{
		__New(Color)
		{
			this.Handle:=DllCall("CreateSolidBrush","UInt",Color,"UPtr")
		}

		__Delete()
		{
			DllCall("DeleteObject","UPtr",this.Handle)
		}
	}
}