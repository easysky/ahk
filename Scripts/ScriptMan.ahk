; @title: 脚本管理器
; -------------------

#NoTrayIcon
#SingleInstance Ignore
Menu,Tray,Icon,shell32.dll,-155
_INI_PATH:=A_ScriptDir . "\Data\exScriptSet.ini"

Gui,Font,,微软雅黑
Gui,Add,ListView,xm ym+10 w500 r20 Grid -Multi AltSubmit gSM_List vSM_List,状态|窗口句柄|脚本
LV_ModifyCol(1,40),LV_ModifyCol(2,80),LV_ModifyCol(3,350)
Gui,Add,GroupBox,x+10 yp-8 w100 h265,脚本操作
Gui,Add,Button,xp+10 yp+30 w80 Disabled gSM_Do vSM_Run,运行(&G)
Gui,Add,Button,xp y+10 w80 Disabled gSM_Do vSM_Reload,重启(&R)
Gui,Add,Button,xp y+10 w80 Disabled gSM_Do vSM_End,停止(&X)
Gui,Add,Button,xp y+10 w80 Disabled gSM_Do vSM_Edit,编辑(&E)
Gui,Add,Button,xp y+10 w80 gSM_Do vSM_Add,添加(&A)
Gui,Add,Button,xp y+10 w80 Disabled gSM_Do vSM_Del,删除(&D)
Gui,Add,GroupBox,Xp-10 y+20 w100 h150,列表操作
Gui,Add,Button,xp+10 yp+30 w80 gSM_Do vSM_Update,刷新(&U)
Gui,Add,Button,xp y+10 w80 gSM_Do vSM_Save,保存(&S)
Gui,Add,Button,xp y+10 w80 gSM_Do vSM_Clear,清空(&C)
Gui,Show,,脚本管理器
getScriptList()
Return

SM_List:
If A_GuiEvent In Normal,RightClick
{
	If (Lv_GetNext()=0){
		GuiControl,Disable,SM_Run
		GuiControl,Disable,SM_Reload
		GuiControl,Disable,SM_End
		GuiControl,Disable,SM_Edit
		GuiControl,Disable,SM_Del
	}Else{
		GuiControl,Enable,SM_Edit
		GuiControl,Enable,SM_Del
		Lv_GetText(tempStr,A_EventInfo,1),tempStr:=(tempStr="✓")?1:0,SM_Switch(tempStr)
	}
}
Return

ScriptMan_WinGuiDropFiles:
If (A_GuiControl<>"SM_List")
	Return
GuiControl,-ReDraw,SM_List
Loop,Parse,A_GuiEvent,`n
	Lv_Add("","✗",,A_LoopField)
GuiControl,+ReDraw,SM_List
Return

SM_Do:
If A_GuiControl In SM_Run,SM_Reload,SM_End,SM_Edit,SM_Del
{
	sRow:=LV_GetNext()
	If A_GuiControl In SM_Reload,SM_End
	{
		LV_GetText(cWnd,sRow,2)
		DetectHiddenWindows,On
	}
	Else If A_GuiControl In SM_Run,SM_Edit
		LV_GetText(sPath,sRow,3)
}
If (A_GuiControl="SM_Run"){
	Run,%sPath%,,UseErrorLevel,tPid
	If (ErrorLevel="ERROR")
		Lv_Modify(sRow,"","✗")
	Else{
		WinWait Ahk_Pid %tPid%
		WinGet,tID,ID
		Lv_Modify(sRow,"","✓",tID),SM_Switch(1),tPid:=""
	}
}Else If (A_GuiControl="SM_Reload"){
	getStr1:=A_TickCount
	WinGetTitle,tTitle,ahk_id %cWnd%
	Lv_Modify(sRow,"col2","......")
	PostMessage,0x111,65400,,,ahk_id %cWnd%
	Loop
	{
		If (A_TickCount-getStr1>=800)
			Break
	}
	WinGet,cWnd,,%tTitle%
	Lv_Modify(sRow,"col2",cWnd),getStr1:=tTitle:=""
}Else If (A_GuiControl="SM_End"){
	PostMessage,0x111,65405,,,ahk_id %cWnd%	;65307
	Lv_Modify(sRow,"","✗",""),SM_Switch(0)
}Else If (A_GuiControl="SM_Edit"){
	try	Run,Edit %sPath%
	Catch
		Run,notepad.exe %tempStr%
}Else If (A_GuiControl="SM_Update")
	getScriptList()
Else If (A_GuiControl="SM_Add"){
	Gui,+OwnDialogs
	FileSelectFile,tempStr,M32,,选择文件,AHK 脚本文件 (*.ahk)
	tempStr=%tempStr%
	If ErrorLevel Or (tempStr="")
		Return
	sPath=
	GuiControl,-ReDraw,SM_List
	Loop,parse,tempStr,`n
	{
		If (A_Index=1)
			sPath:=RegexReplace(A_LoopField,"\\$") . "\"
		Else
			Lv_Add("","✗","",sPath . A_LoopField)
	}
	GuiControl,+ReDraw,SM_List
}Else If (A_GuiControl="SM_Del"){
	Gui,+OwnDialogs
	MsgBox,262196,移除脚本,确定要移除当前选择脚本？`n注意：改操作仅影响脚本列表，不影响运行脚本的状态！
	IfMsgBox,No
		Return
	Lv_Delete(sRow)
	Gosub SM_SaveList
}Else If (A_GuiControl="SM_Save")
	Gosub SM_SaveList
Else If (A_GuiControl="SM_Clear"){
	Gui,+OwnDialogs
	MsgBox,262196,清空列表,确定要清空列表？`n注意：该操作将删除已保存的列表数据！
	IfMsgBox,No
		Return
	Lv_Delete()
	IniDelete,%_INI_PATH%,Scripts
}
GuiControl,Focus,SM_List
If A_GuiControl In SM_Reload,SM_End
	DetectHiddenWindows,Off
sRow:=cWnd:=sPath:=""
Return

SM_SaveList:
IniDelete,%_INI_PATH%,Scripts
Loop % LV_GetCount()
{
	LV_GetText(tempStr,A_Index,3)
	IniWrite,%tempStr%,%_INI_PATH%,Scripts,%A_Index%
}
tempStr:=A_TickCount
SplashImage,,b1 w200 fs10 cwffffcc FM10,列表已保存,,,Microsoft Yahei
Loop
{
	If (A_TickCount-tempStr>=2000)
	{
		SplashImage,Off
		Break
	}
}
tempStr=
Return

SM_Switch(b){
	GuiControl,% b?"Enable":"Disable",SM_Reload
	GuiControl,% b?"Enable":"Disable",SM_End
	GuiControl,% b?"Disable":"Enable",SM_Run
}

getScriptList(){
	a:=[]
	Loop
	{
		IniRead,s,%_INI_PATH%,Scripts,%A_Index%
		If (s="ERROR")
			Break
		s:=Trim(s),a[s]:=1
	}
	LV_Delete()
	GuiControl,-ReDraw,SM_List
	DetectHiddenWindows,On
	WinGet,n,List,ahk_class AutoHotkey
	Loop,%n%
	{
		i:=n%A_Index%
		WinGetTitle,t,ahk_id %i%
		s:=StrSplit(t," - ")[1],LV_Add("","✓",i,s)
		If a[s]
			a.Delete(s)
	}
	For s In a
		LV_Add("","✗",,s)
	GuiControl,+ReDraw,SM_List
	DetectHiddenWindows,Off
}

GuiClose:
ExitApp
Return