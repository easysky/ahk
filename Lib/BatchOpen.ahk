; @title:	批量打开文件
; ---------------------

_init_BatchOpen()
{
	Global arr_BOpen:=[]
	_LIB_COUNT+=1	;组件计数
	Menu,_Menu_LIBSET,Add,%_LIB_COUNT% - 批量打开文件,BatchOpen_Set	;组件菜单
	IniRead,tempStr,%_INI_PATH%,BatchOpen
	tempStr=%tempStr%
	If (tempStr="")
		Return
	Loop,Parse,tempStr,`n
	{
		If RegexMatch(A_LoopField,"^([^=]+)=(.+)",s)
		{
			Loop,Parse,s1,@
				getStr%A_Index%:=Trim(A_LoopField)
			arr_BOpen.push([getStr1,getStr2,s2])
			;arr_BOpen[1]:=["PDF","c:\app.exe","1.pdf|2.pdf|3.pdf"]
			Menu,Menu_BOpen,Add,%getStr1%,cmd_BOpen
		}
	}
	_LIB_SETINDEX+=1
	Menu,SubMenu_Extend,Add,%_LIB_SETINDEX% - 批量打开文件,:Menu_BOpen
}

BatchOpen_Set:
Gui,BatOpen:New
Gui,BatOpen:+HwndBO_ID ;-MinimizeBox +Owner
Gui,BatOpen:Font,,Microsoft Yahei
Gui,BatOpen:Add,Tab2,x10 y10 Buttons AltSubmit gbo_Tab vbo_Tab,1-编辑内容|2-格式说明
Gui,BatOpen:Tab,1
Gui,BatOpen:Add,Edit,x10 y45 w550 h400 -Wrap +HScroll HwndBO_BoxID vBO_List,
Gui,BatOpen:Tab,2
Gui,BatOpen:Add,Edit,x10 y45 w550 h400 ReadOnly,
(
类似 ini 文件格式，分组名包含在中括号中。
可选本组文件是否指定打开方式：[组名@指定的程序] 即可。
注：需保证组内文件类型一致。
参考格式如下：
==============
[分组名1]`n文件 1`n文件 2`n文件 3`n……
[分组名2@执行程序]`n文件 1`n文件 2`n文件 3`n……
==============
`n文件列表支持使用通配符 *（仅支持 * 号）。
)
Gui,BatOpen:Tab
Gui,BatOpen:Font,Bold
Gui,BatOpen:Add,Link,x400 y15 gbo_Add vbo_Add,<a>+ 添加文件</a>
Gui,BatOpen:Add,Button,x480 y8 w80 gbo_Save vbo_Save,保存(&S)
Gui,BatOpen:Show,,批量打开文件管理
tempStr=
Loop,% arr_BOpen.Length()
{
	tempStr.=((A_Index=1)?"":"`n") . "[" arr_BOpen[A_Index][1] . ((arr_BOpen[A_Index][2]="")?"":("@" . arr_BOpen[A_Index][2])) . "]"
	Loop,Parse,% arr_BOpen[A_Index][3],|
		tempStr .= "`n" . A_LoopField
}
GuiControl,BatOpen:,BO_List,%tempStr%
tempStr=
Return

BatOpenGuiDropFiles:
tempStr:=A_GuiEvent
Control,EditPaste,% strReplace(tempStr,"`n","`r`n"),,Ahk_Id %BO_BoxID%
WinActivate,ahk_id %BO_ID%
tempStr:=StrLen(tempStr)
GuiControl,BatOpen:Focus,BO_List
SendInput +{Left %tempStr%}
tempStr=
Return

bo_Tab:
GuiControlGet,tempStr,BatOpen:,bo_Tab
GuiControl,% (tempStr=2)?"BatOpen:Hide":"BatOpen:Show",bo_Add
GuiControl,% (tempStr=2)?"BatOpen:Disable":"BatOpen:Enable",bo_Save
tempStr=
Return

bo_Add:
GuiControl,BatOpen:Disable,BO_List
Gui,BatOpen:+OwnDialogs
FileSelectFile,tempStr,32,,选择文件
GuiControl,BatOpen:Enable,BO_List
GuiControl,BatOpen:Focus,BO_List
If ErrorLevel Or (tempStr="")
	Return
Control,EditPaste,%tempStr%,,Ahk_Id %BO_BoxID%
tempStr:=StrLen(tempStr)
SendInput +{Left %tempStr%}
tempStr=
Return

bo_Save:
GuiControlGet,tempStr,BatOpen:,BO_List
If (arr_BOpen.Length()>0){
	Loop,% arr_BOpen.Length()
	{
		IniDelete,%_INI_PATH%,BatchOpen,% arr_BOpen[A_Index][1] . ((arr_BOpen[A_Index][2]="")?"":("@" . arr_BOpen[A_Index][2]))
		Menu,Menu_BOpen,Delete,% arr_BOpen[A_Index][1]
	}
}
tempStr:=Trim(tempStr),arr_BOpen:=[]
If (tempStr<>""){
	nCount:=0
	Loop,Parse,tempStr,`n
	{
		getStr1:=Trim(A_LoopField)
		If (getStr1="")
			Continue
		If (SubStr(getStr1,1,1)="["){
			nCount+=1,s1:=s2:="",RegexMatch(getStr1,"^\[([^@]+)@?(.*)]$",s),s1:=Trim(s1),s2:=Trim(s2),arr_BOpen[nCount]:=[s1,s2,""]
			Menu,Menu_BOpen,Add,%s1%,cmd_BOpen
		}Else
			arr_BOpen[nCount][3].=getStr1 . "|"
	}
	Loop,% arr_BOpen.Length()
		IniWrite,% SubStr(arr_BOpen[A_Index][3],1,-1),%_INI_PATH%,BatchOpen,% arr_BOpen[A_Index][1] . ((arr_BOpen[A_Index][2]="")?"":("@" . arr_BOpen[A_Index][2]))
	nCount:=getStr1:=s:=s1:=s2:=""
}
func_ShowInfoTip("已更新",,150),tempStr:=""
Return

cmd_BOpen:
tPath:=arr_BOpen[A_ThisMenuItemPos][2]
If (tPath="") Or !FileExist(tPath)
	tPath=
Loop,Parse,% arr_BOpen[A_ThisMenuItemPos][3],|
{
	tempStr:=Trim(A_LoopField)
	If (tempStr="")
		Continue
	SplitPath,tempStr,getStr1,getStr3,getStr2,getStr4
	If InStr(getStr1,"*")
	{
		Loop,%getStr3%\%getStr4%.%getStr2%
			BO_OpenFile(tPath,A_LoopFileLongPath)
	}Else
		BO_OpenFile(tPath,tempStr)
}
tempStr:=tPath:=getStr1:=getStr2:=getStr3:=getStr4:=""
Return

BO_OpenFile(s,t){
	Try
		Run,% s .  ((s="")?t:(A_Space . t))
	Catch
		func_ShowInfoTip("“" tempStr "”打开失败！",3500,,,0)
}

#if WinActive("ahk_id" . BO_ID)
^s::Gosub bo_Save
#if

BatOpenGuiEscape:
BatOpenGuiClose:
Gui,BatOpen:Destroy
Return