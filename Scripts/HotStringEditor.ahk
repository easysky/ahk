; @title: 热字串编辑器
; ------------------

#NoEnv
#NoTrayIcon
#SingleInstance Ignore
Menu,Tray,Icon,shell32.dll,-274

Global arr_HSOption:={"*":1,"?":2,"B":3,"C":4,"O":5,"R":6,"T":7,"X":8,"Z":9}
Gui,+HwndHSEM_Win
Gui,Font,,微软雅黑
Gui,Add,GroupBox,x10 y0 w450 h125,
Gui,Add,Radio,x20 y18 Checked ghs_Do vhs_EndChar_1,使用终止符(&E)
Gui,Add,Radio,x20 y100 ghs_Do vhs_EndChar_0,不使用终止符(&D)
Gui,Add,Link,x400 y15 ghs_Do vhs_SelCtrl,<a>清空选择</a>
Gui,Add,Tab2,x0 y0 w0 h0 vhs_Tab,Tab
Gui,Add,CheckBox,x35 y45 vhs_Char1,-
Gui,Add,CheckBox,x70 y45 vhs_Char2,(
Gui,Add,CheckBox,x105 y45 vhs_Char3,)
Gui,Add,CheckBox,x140 y45 vhs_Char4,[
Gui,Add,CheckBox,x175 y45 vhs_Char5,]
Gui,Add,CheckBox,x210 y45 vhs_Char6,{
Gui,Add,CheckBox,x245 y45 vhs_Char7,}
Gui,Add,CheckBox,x280 y45 vhs_Char8,:
Gui,Add,CheckBox,x315 y45 vhs_Char9,`;
Gui,Add,CheckBox,x350 y45 vhs_Char10,'
Gui,Add,CheckBox,x385 y45 vhs_Char11,"
Gui,Add,CheckBox,x420 y45 vhs_Char12,/
Gui,Add,CheckBox,x35 y70 vhs_Char13,\
Gui,Add,CheckBox,x70 y70 vhs_Char14,`,
Gui,Add,CheckBox,x105 y70 vhs_Char15,.
Gui,Add,CheckBox,x140 y70 vhs_Char16,?
Gui,Add,CheckBox,x175 y70 vhs_Char17,!
Gui,Add,CheckBox,x210 y70 vhs_Char18,[回车]
Gui,Add,CheckBox,x280 y70 vhs_Char19,[空格]
Gui,Add,CheckBox,x350 y70 vhs_Char20,[制表符]
Gui,Tab
Gui,Add,ListView,x10 y135 w450 h355 -LV0x10 Grid -Multi ghs_Do vhs_List,热字串|替换文本|选项
LV_ModifyCol(1,100),LV_ModifyCol(2,200),LV_ModifyCol(3,120)
Gui,Add,Button,x10 y500 w100 ghs_Do vhs_BtnOption,全局选项(&O)
Gui,Add,Edit,x115 y501 w130 ReadOnly h25 vhs_Option,
Gui,Add,Button,x275 y500 w100 Default ghs_Do vhs_Save,保存(&S)
Gui,Add,Button,x380 y500 w80 ghs_Do vhs_Exit,退出(&X)
Gui,Show,,热字串（自动文本替换）编辑器

Menu,popMenu,Add,编辑,cmd_Pop
Menu,popMenu,Add,删除,cmd_Pop
Menu,popMenu,Add,
Menu,popMenu,Add,添加,cmd_Pop

SplitPath,A_ScriptDir,,s
__f_HSPath:=s . "\Lib\AutoText.ahk",b_HSF_Exist:=FileExist(__f_hsPath)?1:0,arr_HStr:=[],arr_RWin:=[],_str_EndChar:=_str_OptG:=s:=""
If !b_HSF_Exist
	Return
Loop,Read,%__f_HSPath%
{
	_str_Line:=Trim(A_LoopReadLine)
	If (_str_Line="") || (SubStr(_str_Line,1,1)=";")
		Continue
	If InStr(_str_Line,"#Hotstring")	;当前行是定义的终止符或选项代码
	{
		_str_Line:=strReplace(_str_Line,"#Hotstring")
		If InStr(_str_Line,"EndChars")	;当前行定义终止符
			_str_EndChar:=Trim(strReplace(_str_Line,"EndChars"))
		Else
			_str_OptG:=Trim(_str_Line)
	}Else If RegexMatch(_str_Line,"iS)^#IfWin(Active|Exist),?\s*.+")	;该行定义窗口限制开始
		b_RWin:=1,_str_RWin:=_str_Line
	Else If RegexMatch(_str_Line,"iS)^#IfWin(Active|Exist)$")	;该行定义窗口限制结束
		b_RWin:=0,_str_RWin:=""
	Else{		;该行定义替换内容
		If RegexMatch(_str_Line,"iS)^:([\*\?bcortxz01]*):([^:]+)::(.+)$",s)
		{
			arr_HStr[s2]:=[s3,s1]
			;arr_HStr[热字串]:=[替代文本,独立选项]
			If b_RWin
				arr_RWin[s2]:=_str_RWin
			;arr_RWin[热字串1/热字串2]:=[指定窗口 1]
			;arr_RWin[热字串3/热字串4]:=[指定窗口 2]
		}
	}
}
GuiControl,,hs_Option,% strReplace(_str_OptG,A_Space)
GuiControl,-ReDraw,hs_List
For s1,s2 In arr_HStr
	Lv_Add("",s1,s2[1],s2[2] . ((arr_RWin.HasKey(s1))?"#":""))
GuiControl,+ReDraw,hs_List
Lv_ModifyCol(1,"","热字串" . A_Space . "[" . Lv_GetCount() . "]"),s1:=s2:=s3:=_str_RWin:=_str_Line:=""
;;处理终止符
b_NoEndChar:=InStr(_str_OptG,"*")?1:0
If b_NoEndChar
{
	GuiControl,,hs_EndChar_0,1
	GuiControl,Disable,hs_Tab
}Else{
	If (_str_EndChar=""){
		Loop,20
			GuiControl,,hs_Char%A_Index%,1
	}Else{
		If (InStr(_str_EndChar,A_Space)>0)
		{
			GuiControl,,hs_Char19,1
			_str_EndChar:=RegexReplace(_str_EndChar,"\s")
		}
		If ((_str_EndChar!="") And InStr(_str_EndChar,"``n"))
		{
			GuiControl,,hs_Char18,1
			_str_EndChar:=StrReplace(_str_EndChar,"``n")
		}
		If ((_str_EndChar!="") And InStr(_str_EndChar,"``t"))
		{
			GuiControl,,hs_Char20,1
			_str_EndChar:=StrReplace(_str_EndChar,"``t")
		}
		If (_str_EndChar!="")
		{
			Loop,Parse,_str_EndChar
			{
				tempStr:=InStr("-()[]{}:;'""/\`,.?!",A_LoopField)
				If (tempStr>0)
					GuiControl,,hs_Char%tempStr%,1
			}
		}
	}
}
GuiControl,Focus,hs_List
Return

GuiContextMenu:
If (A_GuiControl="hs_List"){
	strHS_Row:=LV_GetNext()
	Menu,popMenu,% (strHS_Row=0)?"Disable":"Enable",1&
	Menu,popMenu,% (strHS_Row=0)?"Disable":"Enable",2&
	Menu,popMenu,Show
}
Return

cmd_Pop:
If (A_ThisMenuItemPos=1){
	_Is_Edit:=1
	Gosub HS_Edit
}Else If (A_ThisMenuItemPos=2){
	Gui,+OwnDialogs
	MsgBox,262180,删除热字串,确定要删除选择的热字串？
	IfMsgBox,No
		Return
	Lv_GetText(strHS_Str,strHS_Row)
	If Lv_Delete(strHS_Row)
		arr_HStr.Delete(strHS_Str),arr_RWin.Delete(strHS_Str)
	strHS_Str:=strHS_Row:=""
}If (A_ThisMenuItemPos=4){
	_Is_Edit:=0
	Gosub HS_Edit
}
Return

hs_Do:
If (A_GuiControl="hs_List"){
	If A_GuiEvent In DoubleClick
	{
		strHS_Row:=Lv_GetNext()
		If (strHS_Row=0)
			Return
		_Is_Edit:=1
		Gosub HS_Edit
	}
}Else If A_GuiControl In hs_EndChar_1,hs_EndChar_0
{
	GuiControl,% (A_GuiControl="hs_EndChar_1")?"Enable":"Disable",hs_Tab
	GuiControl,% (A_GuiControl="hs_EndChar_1")?"Show":"Hide",hs_SelCtrl
	If (A_GuiControl="hs_EndChar_0"){
		If !InStr(_str_OptG,"*")
		{
			_str_OptG.=" *"
			GuiControl,,hs_Option,% strReplace(_str_OptG,A_Space)
		}
		b_NoEndChar:=1
	}Else{
		If InStr(_str_OptG,"*")
		{
			_str_OptG:=RegexReplace(_str_OptG,"\s*\*\s*")
			GuiControl,,hs_Option,% strReplace(_str_OptG,A_Space)
		}
		b_NoEndChar:=0
	}
}Else If (A_GuiControl="hs_SelCtrl"){
	Loop,20
		GuiControl,,hs_Char%A_Index%,0
}Else If (A_GuiControl="hs_Save"){
	If (Lv_GetCount()=0){
		Gui,+OwnDialogs
		MsgBox,262192,未定义热字串,当前热字串为空！
		Return
	}
	_str_Out:="; @title:" . A_Tab . "热字串-自动文本替换`n; -------------------------`n`n"
	If !b_NoEndChar	;已设置终止符
	{
		_str_EndChar:="",c:=0
		Loop,20
		{
			GuiControlGet,tempStr,,hs_Char%A_Index%
			If tempStr
			{
				c+=1
				If (A_Index=18)
					tempStr:="``n"
				Else If (A_Index=19)
					tempStr:=A_Space
				Else If (A_Index=20)
					tempStr:="``t"
				Else
					GuiControlGet,tempStr,,hs_Char%A_Index%,Text
				_str_EndChar.=tempStr
			}
		}
		If (c=0){
			_str_OptG.=" *"
			GuiControl,,hs_EndChar_0,1
			GuiControl,Disable,hs_Tab
			GuiControl,,hs_Option,% strReplace(_str_OptG,A_Space)
		}Else If (c!=20)
			_str_Out.="#Hotstring EndChars " . _str_EndChar . "`n"
		c=
	}
	If (_str_OptG!="")
		_str_Out.="#Hotstring " . _str_OptG . "`n"
	arr_Temp:=[]
	For s1,s2 In arr_HStr
	{
		If arr_RWin.HasKey(s1)
		{
			If !arr_Temp.haskey(arr_RWin[s1])
				arr_Temp[arr_RWin[s1]]:=[]
			arr_Temp[arr_RWin[s1]].push(s1)
			Continue
		}
		_str_Out.="`n:" . s2[2] . ":" . s1 . "::" . s2[1]
	}
	For s1,s2 In arr_Temp
	{
		_str_Out.="`n" . s1
		Loop,% s2.Length()
			_str_Out.="`n:" . arr_HStr[s2[A_Index]][2] . ":" . s2[A_Index] . "::" . arr_HStr[s2[A_Index]][1]
		_str_Out.="`n" . SubStr(s1,1,RegexMatch(s1,"[,\s]")-1)
	}
	If FileExist(__f_HSPath)
		FileDelete,%__f_HSPath%
	FileAppend,%_str_Out%,%__f_HSPath%,UTF-8
	arr_Temp:=[],s1:=s2:=_str_Out:=tempStr:=""
	Gui,+OwnDialogs
	MsgBox,262208,保存成功,热字串已更新！`n重启主脚本“zBox.ahk”生效。
}Else If (A_GuiControl="hs_BtnOption"){
	b_OptG:=1
	Gosub HS_OptionWin
}Else If (A_GuiControl="hs_Exit")
	Gosub GuiClose
Return

GuiClose:
GuiEscape:
ExitApp
Return

;----------- 编辑框 ------

HS_Edit:
Gui,%HSEM_Win%:Default
If _Is_Edit
	Lv_GetText(strHS_Str,strHS_Row),_str_OptI:=arr_HStr[strHS_Str][2]
Else
	strHS_Str:=_str_OptI:=""
Gui,%HSEM_Win%:+Disabled
Gui,HSE_Win:-MinimizeBox +Owner%HSEM_Win%
Gui,HSE_Win:Font,,微软雅黑
Gui,HSE_Win:Add,Text,x12 y13,热字串(&S)
Gui,HSE_Win:Add,Edit,x85 y10 w330 vhse_Str,%strHS_Str%
Gui,HSE_Win:Add,Text,x12 y43,替换文本(&T)
Gui,HSE_Win:Add,Edit,x85 y40 r8 w330 vhse_Text,% _Is_Edit?arr_HStr[strHS_Str][1]:""
Gui,HSE_Win:Add,CheckBox,x12 y195 ghse_rWin vhse_rWin,窗口(&W)
Gui,HSE_Win:Add,Tab2,x0 y0 w0 h0 Disabled vhse_Tab,Tab
Gui,HSE_Win:Add,Edit,x85 y190 r1 w160 vhse_WinCls,
Gui,HSE_Win:Add,Radio,x260 y193 Checked vhse_AE1,激活时(&A)
Gui,HSE_Win:Add,Radio,x340 y193 vhse_AE2,存在时(&E)
Gui,HSE_Win:Tab
Gui,HSE_Win:Add,Button,x10 y230 w65 h25 ghse_Set,选项(&O)
Gui,HSE_Win:Add,Edit,x85 y230 w160 h25 ReadOnly vhse_Option,%_str_OptI%
Gui,HSE_Win:Add,Button,x270 y230 w80 h25 ghse_Save,确定(&S)
Gui,HSE_Win:Add,Button,x355 y230 w60 h25 ghse_Cancel,取消(&X)
Gui,HSE_Win:Show,,热字串编辑
If _Is_Edit And arr_RWin.HasKey(strHS_Str)
{
	GuiControl,HSE_Win:,hse_rWin,1
	GuiControl,HSE_Win:Enable,hse_Tab
	If RegexMatch(arr_RWin[strHS_Str],"i)#ifWin(Active|Exist),?\s*(.+)",s)
	{
		GuiControl,HSE_Win:,hse_WinCls,%s2%
		If (s1="Active")
			GuiControl,HSE_Win:,hse_AE1,1
		Else
			GuiControl,HSE_Win:,hse_AE2,1
	}
}
s1:=s2:=""
Return

hse_rWin:
GuiControlGet,tempStr,HSE_Win:,%A_ThisLabel%
GuiControl,% tempStr?"HSE_Win:Enable":"HSE_Win:Disable",hse_Tab
tempStr=
Return

hse_Set:
b_OptG:=0
Gosub HS_OptionWin
Return

hse_Save:
GuiControlGet,s1,HSE_Win:,hse_Str
GuiControlGet,s2,HSE_Win:,hse_Text
s1:=Trim(s1),s2:=Trim(s2)
If (s1="") Or (s2="")
{
	GuiControl,HSE_Win:Focus,% (s1="")?"hse_Str":"hse_Text"
	s1:=s2:=""
	Return
}
If (!_Is_Edit || (_Is_Edit && (s1<>strHS_Str))) && !_check_NewStr(s1)
	Return
If _Is_Edit && (s1<>strHS_Str)
	arr_HStr.Delete(strHS_Str)
arr_HStr[s1]:=[s2,_str_OptI],s3:=""

;获取指定窗口
GuiControlGet,tempStr,HSE_Win:,hse_rWin
If tempStr
{
	GuiControlGet,s3,HSE_Win:,hse_WinCls
	s3=%s3%
	If (s3!=""){
		GuiControlGet,s4,HSE_Win:,hse_AE1
		s3:=(s4?"#IfWinActive":"#IfWinExist") . A_Space . s3
	}
}
If (s3!="")
	arr_RWin[s1]:=s3
Gosub HSE_WinGuiClose
Gui,%HSEM_Win%:Default
If _Is_Edit
	Lv_Modify(strHS_Row,"",s1,s2,_str_OptI . ((s3="")?"":"#"))
Else
	Lv_Modify(0,"-select"),Lv_Add("select",s1,s2,_str_OptI . ((s3="")?"":"#")),Lv_Modify(Lv_GetCount(),"vis"),Lv_ModifyCol(1,"","热字串" . A_Space . "[" . Lv_GetCount() . "]")
tempStr:=s1:=s2:=s3:=s4:=""
Return

_check_NewStr(s)
{
	Global arr_HStr
	If arr_HStr.HasKey(s)
	{
		Gui,HSE_Win:+OwnDialogs
		MsgBox,262192,重复定义,热字串“%s%”已定义！
		Return 0
	}
	Return 1
}

hse_Cancel:
HSE_WinGuiClose:
HSE_WinGuiEscape:
Gui,%HSEM_Win%:-Disabled
Gui,HSE_Win:Destroy
Return

;----------- 热字串选项代码 ------

HS_OptionWin:
Gui,HS_OptWin:New
Gui,HS_OptWin:-MinimizeBox
If b_OptG
{
	Gui,%HSEM_Win%:+Disabled
	Gui,HS_OptWin:+Owner%HSEM_Win%
}Else{
	Gui,HSE_Win:+Disabled
	Gui,HS_OptWin:+OwnerHSE_Win
}
Gui,HS_OptWin:Font,,微软雅黑
Gui,HS_OptWin:Add,GroupBox,x10 y0 w300 h300
Gui,HS_OptWin:Add,CheckBox,x25 y25 Disabled%b_OptG% vhso_1 ghso_Do,* - 无需终止符触发
Gui,HS_OptWin:Add,Radio,x190 y25 Checked Disabled vhso_En1,启用
Gui,HS_OptWin:Add,Radio,x250 y25 Disabled vhso_Dis1,禁用
Gui,HS_OptWin:Add,CheckBox,x25 y55 vhso_2 ghso_Do,? - 在单词中也会触发
Gui,HS_OptWin:Add,Radio,x190 y55 Checked Disabled vhso_En2,启用
Gui,HS_OptWin:Add,Radio,x250 y55 Disabled vhso_Dis2,禁用
Gui,HS_OptWin:Add,CheckBox,x25 y85 vhso_3 ghso_Do,B - 自动退格
Gui,HS_OptWin:Add,Radio,x190 y85 Checked Disabled vhso_En3,启用
Gui,HS_OptWin:Add,Radio,x250 y85 Disabled vhso_Dis3,禁用
Gui,HS_OptWin:Add,CheckBox,x25 y115 vhso_4 ghso_Do,C - 区分大小写
Gui,HS_OptWin:Add,Radio,x190 y115 Checked Disabled vhso_En4,启用
Gui,HS_OptWin:Add,Radio,x250 y115 Disabled vhso_Dis4,禁用
Gui,HS_OptWin:Add,CheckBox,x25 y145 vhso_5 ghso_Do,O - 不显示终止符
Gui,HS_OptWin:Add,Radio,x190 y145 Checked Disabled vhso_En5,启用
Gui,HS_OptWin:Add,Radio,x250 y145 Disabled vhso_Dis5,禁用
Gui,HS_OptWin:Add,CheckBox,x25 y175 vhso_6 ghso_Do,R - 发送原始文本
Gui,HS_OptWin:Add,Radio,x190 y175 Checked Disabled vhso_En6,启用
Gui,HS_OptWin:Add,Radio,x250 y175 Disabled vhso_Dis6,禁用
Gui,HS_OptWin:Add,CheckBox,x25 y205 vhso_7 ghso_Do,T - 发送原始文本2
Gui,HS_OptWin:Add,Radio,x190 y205 Checked Disabled vhso_En7,启用
Gui,HS_OptWin:Add,Radio,x250 y205 Disabled vhso_Dis7,禁用
Gui,HS_OptWin:Add,CheckBox,x25 y235 vhso_8 ghso_Do,X - 执行命令
Gui,HS_OptWin:Add,Radio,x190 y235 Checked Disabled vhso_En8,启用
Gui,HS_OptWin:Add,Radio,x250 y235 Disabled vhso_Dis8,禁用
Gui,HS_OptWin:Add,CheckBox,x25 y265 vhso_9 ghso_Do,Z - 重置热字串识别器
Gui,HS_OptWin:Add,Radio,x190 y265 Checked Disabled vhso_En9,启用
Gui,HS_OptWin:Add,Radio,x250 y265 Disabled vhso_Dis9,禁用
Gui,HS_OptWin:Add,Link,x15 y315,<a href="https://wyagd001.github.io/zh-cn/docs/Hotstrings.htm">了解更多...</a>
Gui,HS_OptWin:Add,Button,x125 y310 w100 h25 ghso_Save,确定(&S)
Gui,HS_OptWin:Add,Button,x230 y310 w80 h25 ghso_Cancel,取消(&X)
Gui,HS_OptWin:Show,,热字串选项
If (b_OptG && (_str_OptG="")) || (!b_OptG && (_str_OptI=""))
	Return
__Get_HSCode(b_OptG?_str_OptG:_str_OptI,1-b_OptG)
;b_OptG:0——全局选型带空格；1——独立选型无空格
;e.g: arr_HS_On["*"]:=0
;e.g: arr_HS_On["O"]:=1
For s1,s2 In arr_HS_On
{
	tempStr:=arr_HSOption[s1]
	GuiControl,HS_OptWin:,hso_%tempStr%,1
	GuiControl,HS_OptWin:Enable,hso_En%tempStr%
	GuiControl,HS_OptWin:Enable,hso_Dis%tempStr%
	If s2
		GuiControl,HS_OptWin:,hso_En%tempStr%,1
	Else
		GuiControl,HS_OptWin:,hso_Dis%tempStr%,1
}
tempStr=
Return

hso_Do:
s1:=SubStr(A_GuiControl,0,1)
GuiControlGet,s2,HS_OptWin:,hso_%s1%
GuiControl,% s2?"HS_OptWin:Enable":"HS_OptWin:Disable",hso_En%s1%
GuiControl,% s2?"HS_OptWin:Enable":"HS_OptWin:Disable",hso_Dis%s1%
s1:=s2:=""
Return

hso_Save:
r=
Loop,9
{
	GuiControlGet,s1,HS_OptWin:,hso_%A_Index%
	If s1
	{
		GuiControlGet,s2,HS_OptWin:,hso_%A_Index%,Text
		GuiControlGet,s3,HS_OptWin:,hso_En%A_Index%
		r.=SubStr(s2,1,1) . (s3?"":"0") . (b_OptG?A_Space:"")
	}
}
Gosub HS_OptWinGuiClose
r:=Trim(r)
If b_OptG
{
	GuiControl,%HSEM_Win%:,hs_Option,% strReplace(r,A_Space)
	_str_OptG:=r
}Else{
	GuiControl,HSE_Win:,hse_Option,%r%
	_str_OptI:=r
}
r:=s1:=s2:=s3:=""
Return

__Get_HSCode(s,b:=1){
	Global arr_HS_On:=[]
	i:=1
	If !b
		s:=StrReplace(s,A_Space)
	Loop
	{
		If (i>=StrLen(s)+1)
			Break
		i:=RegexMatch(s,"iS)(\*|\?|B|C|O|R|T|X|Z)0?",m,i)
		If i
		{
			If (StrLen(m)=1)
				arr_HS_On[m]:=1
			Else
				arr_HS_On[SubStr(m,1,1)]:=SubStr(m,0)
			i+=1
		}Else
			Break
	}
}

hso_Cancel:
HS_OptWinGuiEscape:
HS_OptWinGuiClose:
If b_OptG
	Gui,%HSEM_Win%:-Disabled
Else
	Gui,HSE_Win:-Disabled
Gui,HS_OptWin:Destroy
Return