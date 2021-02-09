; @title:	剪贴板增强
; -------------------

_init_Clip2()
{
	Global arr_sClip:=[],arr_sClipOption:=[],_Is_sClipEmpty:=0
	IniRead,tempStr,%_INI_PATH%,Clip2,Option,1|20|^``
	tempStr=%tempStr%
	If (tempStr="") Or !RegexMatch(tempStr,"i)^[123]\|\d{1,2}\|.*$")
		tempStr:="1|20|^``"
	arr_sClipOption:=strsplit(tempStr,"|")
	If (arr_sClipOption[2]<2)
		arr_sClipOption[2]:=20
	If __Set_Hotkey()
	{
		If (Clipboard<>"")
		{
			arr_sClip.push(Clipboard)
			Menu,menu_sClip,Add,% __sStr(Clipboard),cmd_sClip
		}Else{
			Menu,menu_sClip,Add,无,cmd_sClip
			Menu,menu_sClip,Disable,1&
			_Is_sClipEmpty:=1
		}
		OnClipboardChange("__ClipChanged")
	}
	_LIB_COUNT+=1	;组件计数
	Menu,_Menu_LIBSET,Add,%_LIB_COUNT% - 剪贴板增强,cmd_sClipOption	;组件菜单
}

sClip_Send:
MouseGetPos,,,sWin_Clip
Menu,menu_sClip,Show
return

cmd_sClip:
WinWaitActive,Ahk_Id %sWin_Clip%
__SendStr(arr_sClip[A_ThisMenuItemPos]),sWin_Clip:=""
Return

__Set_Hotkey(b:=1)
{
	Global arr_sClipOption
	Try{
		Hotkey,% arr_sClipOption[3],% b?"sClip_Send":"Off"
		Return 1
	}Catch{
		func_ShowInfoTip("剪贴板增强：设置快捷键错误！",,,1,0)
		Return 0
	}
}

__ClipChanged(Type) {
	Global arr_sClip,arr_sClipOption,_Is_sClipEmpty
	If (Type!=1)
		Return
	If _Is_sClipEmpty
	{
		Menu,menu_sClip,Delete,无
		_Is_sClipEmpty:=0
	}
	s:=arr_sClip.length(),t:=0
	;重复项前置
	Loop,%s%
	{
		If (arr_sClip[A_Index]=Clipboard)
		{
			t:=A_Index
			Break
		}
	}
	If (t>0){
		arr_sClip.RemoveAt(t)
		Menu,menu_sClip,Delete,%t%&
	}Else{
		;超过数量自动覆盖
		If (s>=arr_sClipOption[2])
		{
			arr_sClip.pop()
			Menu,menu_sClip,Delete,%s%&
		}
	}
	arr_sClip.InsertAt(1,Clipboard)
	Menu,menu_sClip,Insert,1&,% __sStr(Clipboard),cmd_sClip
}

__SendStr(s){
	Global arr_sClip,arr_sClipOption
	;s——内容；arr_sClipOption[1]——1：直接发送字符模式；2：剪贴板模式；3：Unicode模式
	If (arr_sClipOption[1]=1)
		SendInput {Raw}%s%
	Else If (arr_sClipOption[1]=2){
		t:=ClipboardAll
		Clipboard:=s
		ClipWait
		SendInput ^v
		r:=A_TickCount
		Loop
		{
			If (A_TickCount-r>=100)
				Break
		}
		Clipboard:=t
		t=
	 }else{
		Loop,Parse,s
		{
			If (Asc(A_LoopField)<=255)
				SendInput,% "{Asc 0" . Asc(A_LoopField) . "}"
			Else
				SendInput,%A_LoopField%
		}
	}
}

__sStr(s){
	s:=RegexReplace(s,"\s{2,}",A_Space)
	Return (StrLen(s)>40)?(SubStr(s,1,20) . " ... " . SubStr(s,-14)):s
}

;------ Option ------

cmd_sClipOption:
Gui,sClip_Win:New
Gui,sClip_Win:+AlwaysOnTop -MinimizeBox +Owner
Gui,sClip_Win:Font,,Microsoft Yahei
Gui,sClip_Win:Add,Text,x20 y25,触发热键(&K)
Gui,sClip_Win:Add,Edit,x95 y20 w150 vsClip_Key,% arr_sClipOption[3]
Gui,sClip_Win:Add,Text,x20 y60,剪贴数量(&N)
Gui,sClip_Win:Add,Edit,x95 y55 w150 Number vsClip_Num,
Gui,sClip_Win:Add,UpDown,,% arr_sClipOption[2]
Gui,sClip_Win:Add,Text,x20 y95,发送方式(&M)
Gui,sClip_Win:Add,DropDownList,x95 y90 w150 AltSubmit vsClip_Mode,文本发送模式|剪贴板模式|Unicode 字符模式
GuiControl,sClip_Win:Choose,sClip_Mode,% arr_sClipOption[1]
Gui,sClip_Win:Add,Picture,x18 y145 w24 h-1 gsClip_Info Icon-1004, shell32.dll
Gui,sClip_Win:Add,Button,x80 y145 w80 gsClip_Save,保存
Gui,sClip_Win:Add,Button,x166 y145 w80 gsClip_Cancel,取消
Gui,sClip_Win:Show,h185 w260,剪贴板增强设置
Return

sClip_Save:
GuiControlGet,tempStr,sClip_Win:,sClip_Mode
arr_sClipOption[1]:=tempStr
GuiControlGet,tempStr,sClip_Win:,sClip_Num
tempStr=%tempStr%
If (tempStr="") Or !RegexMatch(tempStr,"\d{1,2}")
	arr_sClipOption[2]:=20
Else
	arr_sClipOption[2]:=tempStr
GuiControlGet,tempStr,sClip_Win:,sClip_Key
tempStr=%tempStr%
Gosub sClip_WinGuiClose
IniWrite,% arr_sClipOption[1] "|" arr_sClipOption[2] "|" tempStr,%_INI_PATH%,Clip2,Option
If (tempStr!=arr_sClipOption[3])
{
	If __Set_Hotkey(0)
	{
		If (tempStr!="")
			arr_sClipOption[3]:=tempStr,__Set_Hotkey()
	}
}
tempStr=
Return

sClip_Info:
Gui,sClip_Win:+OwnDialogs
MsgBox,262208,提示,
(
1、热键遵循 AHK 简写方式：^(Ctrl)、!(Alt)、+(Shift)、#(Win)；`n如 ^v 表示快捷键 Ctrl+v；仅支持手动输入热键符号。
2、剪贴内容数量限制为 <100 条
3、关于发送方式：正常使用三种方式效率相差不大；但使用“文本发送模式”时，如果当前输入法为中文状态，会触发输入法而不上屏；其他两种方式不受输入法影响，“Unicode字符模式”是针对“文本发送模式”的不足进行补充；“剪贴板模式”有可能会对当前复制内容产生影响（虽然已实现对当前复制内容进行还原，但偶尔仍可能不稳定）
)
Return

sClip_Cancel:
sClip_WinGuiClose:
sClip_WinGuiEscape:
Gui,sClip_Win:Destroy
return