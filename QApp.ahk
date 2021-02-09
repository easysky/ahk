; @title:	快速程序菜单
; ----------------------

_init_QApp()
{
	Global arr_Group:=[["默认分组",1]],arr_Apps:=[],b_HMI,Key_Trigger
	_LIB_COUNT+=1	;本组件启用标志
	IniRead,Key_Trigger,%_INI_PATH%,QApp,KeyRunTrigger,00
	If !RegexMatch(Key_Trigger,"[01]{2}")
		Key_Trigger:="00"
	IniRead,tempStr,%_INI_PATH%,QApp,Group,%A_Space%
	tempStr:=Trim(tempStr),n:=1
	If (tempStr<>""){
		Loop,Parse,tempStr,|
		{
			tempStr:=strReplace(A_LoopField,A_Space)
			If (tempStr="")
				Continue
			RegexMatch(tempStr,"(^[^\[]+)\[(\d+)]$",s),s1:=Trim(s1)
			If (s1="")
				Continue
			If s2 Not In 0,1
				s2:=1
			arr_Group.Push([s1,s2]),n+=1
			If (s2<>0)
				func_CreatAppMenu(n)	;创建菜单
		}
		Gosub sub_CreatMainMenu
	}
	Menu,m_QApp,Add,程序菜单管理,ahk_QuickAppsMan
	Menu,m_QApp,Add,键盘启动设置,ahk_KeyRunSet_Win
	Menu,_Menu_LIBSET,Add,%_LIB_COUNT% - 快速程序菜单,:m_QApp
}

sub_CreatMainMenu:
nCount:=func_CreatAppMenu(1)
If (nCount>0)
	Menu,G1,Add,
nCount:=0
Loop,% arr_Group.Length()
{
	If (A_Index=1) Or (arr_Group[A_Index][2]=0)
		Continue
	nCount+=1
	Menu,G1,Add,% arr_Group[A_Index][1],:G%A_Index%
	If !b_HMI
		Menu,G1,Icon,% arr_Group[A_Index][1],SHELL32.dll,-4
}
If (nCount>0)
	Menu,G1,Add,
nCount=
Return

;;------------程序管理模块之分组管理--------

ahk_QuickAppsMan:
Gui,Apps_Group:New
Gui,Apps_Group:+HwndMainW
Gui,Apps_Group:Font,,Tahoma
Gui,Apps_Group:Font,,Microsoft Yahei
Gui,Apps_Group:Add,Listbox,x5 y5 w200 h350 0x100 AltSubmit gqa_GrDo vqa_GList,
Gui,Apps_Group:Add,Button,x210 y5 w80 h28 gqa_GrDo vqa_GEdit,编辑(&E)...
Gui,Apps_Group:Add,Button,x210 y40 w80 h28 Disabled gqa_GrDo vqa_GRename,重命名(&R)
Gui,Apps_Group:Add,Button,x210 y75 w80 h28 gqa_GrDo vqa_GAdd,添加(&N)
Gui,Apps_Group:Add,Button,x210 y110 w80 h28 Disabled gqa_GrDo vqa_GDel,删除(&D)
Gui,Apps_Group:Add,Button,x210 y145 w80 h28 Disabled gqa_GrDo vqa_GHide,隐藏(&H)
Gui,Apps_Group:Add,Button,x210 y180 w38 h22 Disabled gqa_GrDo vqa_GUp,▲	;↑
Gui,Apps_Group:Add,Button,x250 y180 w38 h22 Disabled gqa_GrDo vqa_GDown,▼	;↓
Gui,Apps_Group:Show,w295,程序菜单分组
_str_Groups:="|",_curr_GIndex:=1	;_curr_GIndex:当前组列表中的位置
Loop,% arr_Group.length()
	_str_Groups .= ((arr_Group[A_Index][2]=0)?(arr_Group[A_Index][1] . A_Space . "[隐藏]"):arr_Group[A_Index][1]) . "|"
GuiControl,Apps_Group:,qa_GList,%_str_Groups%
GuiControl,Apps_Group:Choose,qa_GList,1
Return

qa_GrDo:
If (A_GuiControl="qa_GList"){
	GuiControlGet,_curr_GIndex,Apps_Group:,qa_GList
	GuiControl,% (_curr_GIndex=1)?"Apps_Group:Disable":"Apps_Group:Enable",qa_GRename
	GuiControl,% (_curr_GIndex=1)?"Apps_Group:Disable":"Apps_Group:Enable",qa_GDel
	GuiControl,% (_curr_GIndex=1)?"Apps_Group:Disable":"Apps_Group:Enable",qa_GHide
	GuiControl,% (_curr_GIndex<3)?"Apps_Group:Disable":"Apps_Group:Enable",qa_GUp
	GuiControl,% ((_curr_GIndex=1) Or (_curr_GIndex=arr_Group.length()))?"Apps_Group:Disable":"Apps_Group:Enable",qa_GDown
	GuiControl,Apps_Group:,qa_GHide,% ((_curr_GIndex>1) And (arr_Group[_curr_GIndex][2]=0))?"显示(&S)":"隐藏(&H)"
	If A_GuiEvent In DoubleClick
		Gosub ahk_AppsEdit
}Else If (A_GuiControl="qa_GEdit")
	Gosub ahk_AppsEdit
Else If (A_GuiControl="qa_GRename"){
	Gui,Apps_Group:+OwnDialogs
	InputBox,tempStr,重命名分组,,,250,100,,,,,% arr_Group[_curr_GIndex][1]
	If ErrorLevel or (tempStr="") or (tempStr=arr_Group[_curr_GIndex][1])
		Return
	If IsGroupExist(tempStr)
		Return
	_str_Groups:=StrReplace(_str_Groups,"|" . arr_Group[_curr_GIndex][1] . "|","|" . tempStr . "|")
	GuiControl,Apps_Group:,qa_GList,%_str_Groups%
	GuiControl,Apps_Group:Choose,qa_GList,%_curr_GIndex%
	GuiControl,Apps_Group:Focus,qa_GList
	arr_Group[_curr_GIndex][1]:=tempStr,func_DelMenuApp(1),tempStr:=""
	Gosub sub_CreatMainMenu
	Gosub sub_CreatBasicMenu
	Gosub sub_Group2Ini
}Else If (A_GuiControl="qa_GAdd"){
	Gui,Apps_Group:+OwnDialogs
	InputBox,tempStr,请输入新组的名称,,,200,105,,,,,新建分组
	If ErrorLevel Or (tempStr="")
		Return
	If IsGroupExist(tempStr)
		Return
	_curr_GIndex:=arr_Group.Length()+1,arr_Group.Push([tempStr,1]),_str_Groups .= tempStr . "|",tempStr:=""
	GuiControl,Apps_Group:,qa_GList,%_str_Groups%
	GuiControl,Apps_Group:Choose,qa_GList,%_curr_GIndex%
	GuiControl,Apps_Group:Focus,qa_GList
	Gosub sub_Group2Ini
	IniWrite,%A_Space%,%_INI_PATH%,QApp,G%_curr_GIndex%
	Menu,G%_curr_GIndex%,Add,空,cmd_RunApp
	Menu,G%_curr_GIndex%,Disable,空
	func_DelMenuApp(1)
	Gosub sub_CreatMainMenu
	Gosub sub_CreatBasicMenu
}Else If (A_GuiControl="qa_GDel"){
	Gui,Apps_Group:+OwnDialogs
	MsgBox,262196,确认操作,% "确定要删除分组“" . arr_Group[_curr_GIndex][1] . "”？`n注：该操作将同时删除组内的所有文件，且无法撤销！"
	IfMsgBox,No
		Return
	_str_Groups:=StrReplace(_str_Groups,"|" . arr_Group[_curr_GIndex][1] . "|","|")
	GuiControl,Apps_Group:,qa_GList,%_str_Groups%
	GuiControl,Apps_Group:Choose,qa_GList,1
	GuiControl,Apps_Group:Focus,qa_GList
	Loop,% arr_Group.Length()-1
	{
		If (A_Index<_curr_GIndex)
			Continue
		tempStr:=A_Index+1
		IniRead,tempStr,%_INI_PATH%,QApp,G%tempStr%,%A_Space%
		IniWrite,%tempStr%,%_INI_PATH%,QApp,G%A_Index%
	}
	IniDelete,%_INI_PATH%,QApp,% "G" arr_Group.Length()
	arr_Group.RemoveAt(_curr_GIndex),func_DelMenuApp(_curr_GIndex),func_DelMenuApp(1),_curr_GIndex:=1,tempStr:=""
	Gosub sub_CreatMainMenu
	Gosub sub_CreatBasicMenu
	Gosub sub_Group2Ini
}Else If (A_GuiControl="qa_GHide"){
	;bFlag=1： 隐藏 －> 显示；0:显示 －> 隐藏
	bFlag:=(arr_Group[_curr_GIndex][2]=0)?1:0,tempStr:=bFlag?"显示":"隐藏"
	Gui,Apps_Group:+OwnDialogs
	MsgBox,262196,确认操作,% "确定要" . tempStr . "分组“" . arr_Group[_curr_GIndex][1] . "”？"
	IfMsgBox,No
		Return
	If bFlag	;隐藏 －> 显示
		_str_Groups:=StrReplace(_str_Groups,"|" . arr_Group[_curr_GIndex][1] . A_Space . "[隐藏]|","|" . arr_Group[_curr_GIndex][1] . "|"),arr_Group[_curr_GIndex][2]:=1,func_CreatAppMenu(_curr_GIndex)
	Else{	;显示 －> 隐藏
		_str_Groups:=StrReplace(_str_Groups,"|" . arr_Group[_curr_GIndex][1] . "|","|" . arr_Group[_curr_GIndex][1] . A_Space . "[隐藏]|"),arr_Group[_curr_GIndex][2]:=0,func_DelMenuApp(_curr_GIndex)
	}
	GuiControl,Apps_Group:,qa_GHide,% bFlag?"隐藏(&H)":"显示(&S)"
	GuiControl,Apps_Group:,qa_GList,%_str_Groups%
	GuiControl,Apps_Group:Choose,qa_GList,%_curr_GIndex%
	GuiControl,Apps_Group:Focus,qa_GList
	func_DelMenuApp(1),tempStr:=bFlag:=""
	Gosub sub_Group2Ini
	Gosub sub_CreatMainMenu
	Gosub sub_CreatBasicMenu
}Else If A_GuiControl In qa_GUp,qa_GDown
{
	tempStr:=_curr_GIndex,_curr_GIndex:=(A_GuiControl="qa_GUp")?_curr_GIndex-1:_curr_GIndex+1,arr_Group.InsertAt(_curr_GIndex,arr_Group.RemoveAt(tempStr))
	_str_Groups:="|"
	Loop,% arr_Group.length()
		_str_Groups .= arr_Group[A_Index][1] . ((arr_Group[A_Index][2]=0)?" [隐藏]":"") . "|"
	GuiControl,Apps_Group:,qa_GList,%_str_Groups%
	GuiControl,Apps_Group:Focus,qa_GList
	GuiControl,Apps_Group:Choose,qa_GList,%_curr_GIndex%
	If (_curr_GIndex<=2)
		GuiControl,Apps_Group:Disable,qa_GUp
	If (_curr_GIndex=arr_Group.Length())
		GuiControl,Apps_Group:Disable,qa_GDown
	IniRead,getStr1,%_INI_PATH%,QApp,G%tempStr%,%A_Space%
	IniRead,getStr2,%_INI_PATH%,QApp,G%_curr_GIndex%,%A_Space%
	IniWrite,%getStr1%,%_INI_PATH%,QApp,G%_curr_GIndex%
	IniWrite,%getStr2%,%_INI_PATH%,QApp,G%tempStr%
	func_DelMenuApp(tempStr),func_DelMenuApp(_curr_GIndex),func_CreatAppMenu(tempStr),func_CreatAppMenu(_curr_GIndex),func_DelMenuApp(1),tempStr:=getStr1:=getStr2:=""
	Menu,G1,Delete
	Gosub sub_CreatMainMenu
	Gosub sub_CreatBasicMenu
	Gosub sub_Group2Ini
}
Return

sub_Group2Ini:
tempStr=
Loop,% arr_Group.Length()
{
	If (A_Index=1)
		Continue
	tempStr .= arr_Group[A_Index][1] . "[" . arr_Group[A_Index][2] . "]|"
}
IniWrite,% SubStr(tempStr,1,-1),%_INI_PATH%,QApp,Group
tempStr=
Return

IsGroupExist(s){
	Global _str_Groups,arr_Group,arr_Apps
	errFlag:=0
	If RegexMatch(s,"[\|\[\]\*]") Or InStr(_str_Groups,"|" . s . "|")
		errFlag:=1
	If !errFlag
	{
		If s in 默认分组,系统控制管理,扩展功能,程序选项
			errFlag:=1
	}
	If !errFlag
	{
		For s1,s2 In arr_Apps
		{
			If (s2[2]<>1)
				Continue
			If (s=s1){
				errFlag:=1
				Break
			}
		}
	}
	If errFlag
		func_ShowInfoTip("命名分组『" s "』失败！可能的原因：`n1. 组名已存在`n2. 组被命名为“默认分组”`n3. 组名与“默认分组”中的某菜单项相同`n4. 组名包含以下四个非法字符: | [ ] *",5000,,0,0)
	Return errFlag
}

#If WinActive("ahk_id" . MainW)
Enter::
NumPadEnter::
GuiControlGet,tempStr,Apps_Group:FocusV
If (tempStr="qa_GList")
	Gosub ahk_AppsEdit
Else
	SendInput {Enter}
Return
#If

Apps_GroupGuiClose:
Apps_GroupGuiEscape:
Gui,Apps_Group:Destroy
_str_Groups:=_curr_GIndex:=""
Return

;;------------文件管理--------

ahk_AppsEdit:
Gui,Apps_File:New
Gui,Apps_File:+Resize +MinSize600x480 +Owner%MainW% +HwndSubW -MinimizeBox
Gui,Apps_File:Font,,Fixedsys
Gui,Apps_File:Add,Edit,x5 y5 Multi -Wrap HScroll hwndQABOX gqa_FpDo vqa_Box,
Gui,Apps_File:Add,Text,y280 w90 Center vqa_FTotal,
Gui,Apps_File:Font,,Tahoma
Gui,Apps_File:Font,,微软雅黑
Gui,Apps_File:Add,Button,y5 w90 h40 gqa_FpDo vqa_FPath,路径(&P)...
Gui,Apps_File:Add,Button,y50 w90 h40 gqa_FpDo vqa_FSave,保存(&S)
Gui,Apps_File:Add,Button,y95 w90 h40 gqa_FpDo vqa_FCancel,关闭(&X)
Gui,Apps_File:Add,Button,y160 w90 h40 gqa_FpDo vqa_FInfo,说明(&X)
Gui,Apps_File:Show,w805 h610,% "文件菜单管理 - [" . arr_Group[_curr_GIndex][1] . "]"
Gui,Apps_Group:+Disabled
IniRead,tempStr,%_INI_PATH%,QApp,G%_curr_GIndex%,%A_Space%
tempStr:=Trim(tempStr,"`t `n")
If (tempStr<>""){
	tempStr:=StrReplace(tempStr,"|","`n")
	GuiControl,Apps_File:,qa_Box,%tempStr%
}
ControlGet,tempStr,LineCount,,,Ahk_Id %QABOX%
GuiControl,Apps_File:,qa_FTotal,「1/%tempStr%」
tempStr=
Return

Apps_FileGuiSize:
GuiControl,Apps_File:Move,qa_Box,% "w" A_GuiWidth-105 "h" A_GuiHeight-10
GuiControl,Apps_File:MoveDraw,qa_FPath,% "x" A_GuiWidth-95
GuiControl,Apps_File:MoveDraw,qa_FSave,% "x" A_GuiWidth-95
GuiControl,Apps_File:MoveDraw,qa_FCancel,% "x" A_GuiWidth-95
GuiControl,Apps_File:MoveDraw,qa_FInfo,% "x" A_GuiWidth-95
GuiControl,Apps_File:MoveDraw,qa_FTotal,% "x" A_GuiWidth-95
Return

Apps_FileGuiDropFiles:
If (A_EventInfo>1)
	tempStr:=StrReplace(A_GuiEvent,"`n","`r`n")
Else
	tempStr:=A_GuiEvent
Control,EditPaste,%tempStr%,,Ahk_Id %QABOX%
GuiControl,Apps_File:Focus,qa_Box
tempStr:=(A_EventInfo>1)?(StrLen(tempStr)-2):StrLen(tempStr)
SendInput {Shift Down}{Left %tempStr%}{Shift Up}
tempStr=
Return

qa_FpDo:
If (A_GuiControl="qa_Box")
	_Get_Line()
Else If (A_GuiControl="qa_FPath"){
	GuiControl,Apps_File:Disable,qa_Box
	Gui,Apps_File:+OwnDialogs
	FileSelectFile,tempStr,32,选择文件
	GuiControl,Apps_File:Enable,qa_Box
	GuiControl,Apps_File:Focus,qa_Box
	If ErrorLevel Or (tempStr="")
		Return
	Control,EditPaste,%tempStr%,,Ahk_Id %QABOX%
	tempStr:=StrLen(tempStr)
	SendInput +{Left %tempStr%}
	tempStr=
}Else If (A_GuiControl="qa_FSave")
	Gosub sub_SaveMenu
Else If (A_GuiControl="qa_FCancel")
	Gosub Apps_FileGuiClose
Else If (A_GuiControl="qa_FInfo"){
	Gui,Apps_File:+OwnDialogs
	MsgBox,262208,说明,
(
此处文件列表组成 %_App_NAME% 快速菜单，每行为一个菜单项。
`n1. 以符号“－”表示菜单分隔符；
2. 添加文件路径：
   . 点击“路径...”按钮
   . 直接将文件拖放到窗口（支持多个文件拖放）
3. 列表中的文件名即作为默认菜单名（不含后缀）
    也可通过在路径前添加“<xxx>”（不含双引号）自定义将菜单名
    注：自定义菜单名不得包含以下 3 个字符：<、>、|
5. 列表行前加上星号 * 可禁止该行文件出现在菜单中
6. 窗口操作快捷键：
   . Ctrl+Up	上移一行
   . Ctrl+Down	下移一行
   . Ctrl+S		保存
   . Esc		退出编辑
)
}
Return

sub_SaveMenu:
GuiControlGet,tempStr,Apps_File:,qa_Box
tempStr:=RegexReplace(StrReplace(Trim(tempStr,"`t `n"),"`n","|"),"\|+","|")
IniWrite,%tempStr%,%_INI_PATH%,QApp,G%_curr_GIndex%
func_DelMenuApp(_curr_GIndex)
If (_curr_GIndex=1){
	Gosub sub_CreatMainMenu
	Gosub sub_CreatBasicMenu
}Else
	func_CreatAppMenu(_curr_GIndex)
func_ShowInfoTip("文件菜单已成功保存！")
Return

Apps_FileGuiClose:
Apps_FileGuiEscape:
Gui,Apps_Group:-Disabled
Gui,Apps_File:Destroy
GuiControl,Apps_Group:Focus,qa_GList
Return

#If WinActive("ahk_id" . SubW)
~Up up::
~Down up::
~Lbutton up::
_Get_Line()
Return

^Up::
^Down::
tempStr:=ClipboardAll
SendInput {Home}+{End}^x
If (A_ThisLabel="^Up")
	SendInput {BackSpace}{Home}{Enter}{up}
Else
	SendInput {Del}{End}{Enter}
SendInput ^v
Clipboard:=tempStr,tempStr:=""
Return
^s::
Gosub sub_SaveMenu
Return
#if

_Get_Line()
{
	Global QABOX
	ControlGet,s1,LineCount,,,Ahk_Id %QABOX%
	ControlGet,s2,CurrentLine,,,Ahk_Id %QABOX%
	GuiControl,Apps_File:,qa_FTotal,「%s2%/%s1%」
	s1:=s2:=""
}

func_CreatAppMenu(i){
;根据分组编号创建菜单，同时创建菜单数组，i为分组编号；返回值为创建的菜单数量
	Global arr_Apps,b_HMI
	n:=0
	IniRead,tempStr,%_INI_PATH%,QApp,G%i%,%A_Space%
	If (tempStr="") Or (RegexReplace(tempStr,"[\s\|]")="")
	{	;该组未定义程序或为空
		If (i=0)	;默认分组则不显示
			Return 0
		Menu,G%i%,Add,空,cmd_RunApp	;其他分组显示一个灰色禁用空菜单
		If !b_HMI
			Menu,G%i%,Icon,空,shell32.dll,-30
		Menu,G%i%,Disable,空
		Return 1
	}
	Loop,Parse,tempStr,|
	{
		If (SubStr(A_LoopField,1,1)="*")	;不显示标记为隐藏的程序菜单
			Continue
		If (A_LoopField="-"){	;转换分隔线
			Menu,G%i%,Add
			n+=1
		}Else{
			If !RegexMatch(A_LoopField,"^<(.+)>(.*)",s)	;自定义名称的菜单项，s1——菜单名；s2——文件路径
			{	;非自定义名称的菜单项;s2——文件路径；s1——不带后缀名的文件名
				s2:=Trim(A_LoopField,"<>")
				SplitPath,s2,,,,s1
			}
			SplitPath,s2,,,s3
			;If IsObject(arr_Apps[s1])	;菜单项重复则重命名
			If arr_Apps.HasKey(s1)
				s1 .= "_" . A_Now
			arr_Apps[s1]:=[s2,i],n+=1	;arr_Apps[菜单名]=[路径,分组编号]
			Menu,G%i%,Add,%s1%,cmd_RunApp
			If !b_HMI
			{
				If (s3="exe")
				{
					Try
						Menu,G%i%,Icon,%s1%,%s2%,1
					Catch
						Menu,G%i%,Icon,%s1%,shell32.dll,-3
				}Else
					Menu,G%i%,Icon,%s1%,shell32.dll,-2
			}
		}
	}
	Return n
}

func_DelMenuApp(i){
;删除分组编号为i的文件数组
	Global arr_Apps
	tempStr=
	For s1,s2 In arr_Apps
	{
		If (s2[2]=i){
			tempStr .= s1 . "|"
			Menu,G%i%,NoIcon,%s1%
		}
	}
	tempStr:=SubStr(tempStr,1,-1)
	Loop,Parse,tempStr,|
		arr_Apps.Delete(A_LoopField)
	Menu,G%i%,DeleteAll
}

cmd_RunApp:
func_RunApp(arr_Apps[A_ThisMenuItem][1])
Return

; --------------- 键盘启动设置模块 -----

ahk_KeyRunSet_Win:
Gui,KeyRun:New
Gui,KeyRun:-MinimizeBox +Owner%A_ScriptHwnd% +AlwaysOnTop
Gui,KeyRun:Font,,Tahoma
Gui,KeyRun:Font,Bold,微软雅黑
Gui,KeyRun:Add,GroupBox,x10 y0 w200 h75,
Gui,KeyRun:Add,CheckBox,x25 y20 vKeyRun_1,1 - 按「~」键启动
Gui,KeyRun:Add,CheckBox,x25 y45 vKeyRun_2,2 - 双击「Ctrl」键启动
Gui,KeyRun:Font,Normal
Gui,KeyRun:Add,GroupBox,x10 y80 w200 h70,* 注意
Gui,KeyRun:Add,Text,x25 y105,关键字以「``」或「·」开头时执行`n多引擎网络搜索。
Gui,KeyRun:Add,Button,x25 y160 w100 h25 Default gKeyRun_Save,确定(&O)
Gui,KeyRun:Add,Button,x130 y160 w70 h25 gKeyRun_Cancel,取消(&C)
Loop,Parse,Key_Trigger
	GuiControl,KeyRun:,KeyRun_%A_Index%,%A_LoopField%
Gui,KeyRun:Show,,键盘启动触发键设置
Return

KeyRun_Save:
Key_Trigger=
Loop,2
{
	GuiControlGet,tempStr,KeyRun:,KeyRun_%A_index%
	Key_Trigger .= tempStr
}
IniWrite,%Key_Trigger%,%_INI_PATH%,QApp,KeyRunTrigger
tempStr=
Gosub KeyRunGuiClose
Return

KeyRun_Cancel:
KeyRunGuiClose:
KeyRunGuiEscape:
Gui,KeyRun:Destroy
Return

; --------------- 键盘启动 -----

ahk_AppsQuickRun:
If is_AQRShown
	Return
Gui,app_Run:New
Gui,app_Run:+Owner +AlwaysOnTop +Resize -MinimizeBox -MaximizeBox +hwndAQR_ID
Gui,app_Run:Font,,Tahoma
Gui,app_Run:Font,s11 bold,微软雅黑
Gui,app_Run:Add,Edit,x5 y5 gapp_Sel vapp_Sel,
Gui,app_Run:Font,s9 Normal
Gui,app_Run:Add,ListBox,h150 0x100 Hidden gapp_List vapp_List,
Gui,app_Run:Show,w400 h40,键盘启动
is_AQRShown:=b_NoList:=1,last_Search:=-1
Return

app_RunGuiSize:
If (A_EventInfo<>1){
	GuiControl,app_Run:MoveDraw,app_Sel,% "w" A_GuiWidth-10
	If !b_NoList
	{
		GuiControl,app_Run:MoveDraw,app_List,% "w" A_GuiWidth-10
		GuiControl,app_Run:MoveDraw,app_List,% "h" A_GuiHeight-45
	}Else
		GuiControl,app_Run:MoveDraw,app_Sel,% "h" A_GuiHeight-10
}
Return

app_Sel:
GuiControlGet,tempStr,app_Run:,app_Sel
tempStr:=Trim(tempStr),b_Search:=((SubStr(tempStr,1,1)="``") Or (SubStr(tempStr,1,1)="·"))?1:0
If (b_Search<>last_Search){
	Gui,app_Run:Show,,% b_Search?"按下 [Enter] 键进行搜索":"键盘启动"
	last_Search:=b_Search
}
If b_Search
	Return
GuiControl,app_Run:,app_List,|
If (tempStr<>""){
	GuiControl,-Redraw,app_List
	nCount:=0
	For getStr1,getStr2 In arr_Apps
	{
		If InStr(getStr1,tempStr)
		{
			GuiControl,app_Run:,app_List,%getStr1%
			nCount+=1
			Continue
		}
		tempText:=getStr2[1]
		SplitPath,tempText,,,,tempText
		If InStr(tempText,tempStr)
		{
			GuiControl,app_Run:,app_List,% getStr1 . A_Tab . "<" . tempText . ">"
			nCount+=1
		}
	}
	If (nCount>0)
		GuiControl,app_Run:Choose,app_List,1
	GuiControl,+Redraw,app_List
}
b_NoList:=(tempStr="") Or (nCount=0)
GuiControl,% b_NoList?"app_Run:Hide":"app_Run:Show",app_List
Gui,app_Run:Show,% b_NoList?"h40":"h190"
getStr1:=getStr2:=tempText:=nCount:=tempStr:=""
Return

app_List:
If A_GuiEvent In DoubleClick
	Gosub app_RunIt
Return

app_RunGuiClose:
app_RunGuiEscape:
Gui,app_Run:Destroy
is_AQRShown:=0
Return

app_RunIt:
If b_Search{
	GuiControlGet,tempStr,app_Run:,app_Sel
	Gosub app_RunGuiClose
	_MultiSearch(Trim(tempStr,"`n`t ``·"))
}Else{
	GuiControlGet,tempStr,app_Run:,app_List
	If b_NoList
		Return
	Gosub app_RunGuiClose
	s1:=InStr(tempStr,A_Tab . "<")
	If (s1>0)
		tempStr:=SubStr(tempStr,1,s1-1)
	func_RunApp(arr_Apps[tempStr][1]),s1:=""
}
tempStr=
Return

#if WinActive("ahk_id" . AQR_ID)
Enter::
NumPadEnter::
Gosub app_RunIt
Return

Up::
Down::
GuiControl,app_Run:Focus,app_List
SendInput {%A_ThisLabel%}
GuiControl,app_Run:Focus,app_Sel
Return
#if

#if (SubStr(Key_Trigger,1,1)="1")
`::Gosub ahk_AppsQuickRun
#If

#if (SubStr(Key_Trigger,0)="1")
Ctrl::
If (A_ThisHotkey=A_PriorHotkey) and (A_TimeSincePriorHotkey<300)
	Gosub ahk_AppsQuickRun
Return
#If