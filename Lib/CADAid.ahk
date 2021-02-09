; @title:	CAD 办公辅助
; ---------------------

_init_CADAid()
{
	Global in_En,in_Zh,_str_IMECode,arr_CADAid:=[]
	Gosub CADAid_Get
	If (in_En="") Or (in_Zh="") Or !InStr(_str_IMECode,in_En . "|") Or !InStr(_str_IMECode,in_Zh . "|")
		Gosub CADAid_Set
	Else
		SetTimer,Switch2En,1000
	;其他选项
	IniRead,tempStr,%_INI_PATH%,CADAid,Option,0000
	If !RegexMatch(tempStr,"^[01]{4}$")
		tempStr:="0000"
	arr_CADAid:=StrSplit(tempStr),tempStr:=""
	If arr_CADAid[1] Or arr_CADAid[2] Or arr_CADAid[3]
		SetTimer,cad_AutoFunc,100
	_LIB_COUNT+=1	;组件计数
	Menu,_Menu_LIBSET,Add,%_LIB_COUNT% - CAD 办公辅助,CADAid_Set	;组件菜单
}

CADAid_Get:
in_En:=in_Zh:=_str_IMECode:=""
Loop
{
	RegRead,tempStr,HKCU\Keyboard Layout\Preload,%A_Index%
	If ErrorLevel And (tempStr="")
		Break
	_str_IMECode .= tempStr . "|"
}
IniRead,in_En,%_INI_PATH%,CADAid,In_En,%A_Space%
IniRead,in_Zh,%_INI_PATH%,CADAid,In_Zh,%A_Space%
Return

CADAid_Set:
Gosub CADAid_Get
ime_List:="",arr_ImeName:=[]
Loop,Parse,_str_IMECode,|
{
	If (A_LoopField="")
		Continue
	RegRead,tempStr,HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\%A_LoopField%,Layout Text
	ime_List .= tempStr . "|",arr_ImeName[tempStr]:=A_LoopField		;arr_ImeName["us"]:="00000409"
}
Gui,ime_GetIme:New
Gui,ime_GetIme:-MinimizeBox +AlwaysOnTop +Owner
Gui,ime_GetIme:Font,,Tahoma
Gui,ime_GetIme:Font,,微软雅黑
Gui,ime_GetIme:Add,GroupBox,x10 y8 w300 h145,自动切换回英文输入法 · 设定
Gui,ime_GetIme:Add,Text,x25 y35,英文输入法(&E):
Gui,ime_GetIme:Add,DropDownList,x25 y55 w270 vimeGet_En,%ime_List%
Gui,ime_GetIme:Add,Text,x25 y90,中文输入法(&Z):
Gui,ime_GetIme:Add,DropDownList,x25 y110 w270 vimeGet_Zh,%ime_List%
Gui,ime_GetIme:Add,Link,x245 y8 gimeGet_info,<a># 提示 #</a>
Gui,ime_GetIme:Add,GroupBox,x10 y160 w300 h140,其他
tempStr:=arr_CADAid.haskey(1)?arr_CADAid[1]:0
Gui,ime_GetIme:Add,CheckBox,x25 y190 Checked%tempStr% vcadfunc_1,自动替换未找到字体为“hztxt.shx”(&F)
tempStr:=arr_CADAid.haskey(2)?arr_CADAid[2]:0
Gui,ime_GetIme:Add,CheckBox,x25 y215 Checked%tempStr% vcadfunc_2,自动跳过“教育版检测标记”提示(&T)
tempStr:=arr_CADAid.haskey(3)?arr_CADAid[3]:0
Gui,ime_GetIme:Add,CheckBox,x25 y240 Checked%tempStr% vcadfunc_3,自动跳过 HGCAD 插件对话框(&P)
tempStr:=arr_CADAid.haskey(4)?arr_CADAid[4]:0
Gui,ime_GetIme:Add,CheckBox,x25 y265 Checked%tempStr% vcadfunc_4,Ctrl+Alt+BackSpace 显示 CAD 文件关联(&A)
Gui,ime_GetIme:Add,Button,x125 y310 w100 Default gimeGet_Save,确定
Gui,ime_GetIme:Add,Button,x230 y310 w80 gimeGet_Cancel,取消
If (in_En<>"")
	GuiControl,ime_GetIme:ChooseString,imeGet_En,% _get_IMEName(in_En)
If (in_Zh<>"")
	GuiControl,ime_GetIme:ChooseString,imeGet_Zh,% _get_IMEName(in_Zh)
Gui,ime_GetIme:Show,,CAD 辅助功能设置
ime_List:=tempStr:=""
Return

imeGet_info:
Gui,ime_GetIme:+OwnDialogs
Msgbox,262208,说明,请在此处设定要切换的英文、中文输入法。`n下拉列表框中为已安装并启用的输入法列表。`n注：为保证本功能的正常使用，请至少设置一个英文输入法和一个中文输入法（控制面板——时钟、语言和区域——键盘和语言——更改键盘对话框）。`n`n本功能默认开启。
Return

imeGet_Save:
GuiControlGet,getStr1,ime_GetIme:,imeGet_En
GuiControlGet,getStr2,ime_GetIme:,imeGet_Zh
If (getStr1="") Or (getStr2="")
	Return
in_En:=arr_ImeName[getStr1],in_Zh:=arr_ImeName[getStr2],getStr1:=getStr2:=""
Loop,4
{
	GuiControlGet,getStr%A_Index%,ime_GetIme:,cadfunc_%A_Index%
	arr_CADAid[A_Index]:=getStr%A_Index%
}
IniWrite,%in_En%,%_INI_PATH%,CADAid,In_En
IniWrite,%in_Zh%,%_INI_PATH%,CADAid,In_Zh
IniWrite,%getStr1%%getStr2%%getStr3%%getStr4%,%_INI_PATH%,CADAid,Option
getStr1:=getStr2:=getStr3:=getStr4:=""
SetTimer,Switch2En,1000
Gosub ime_GetImeGuiClose
Return

imeGet_Cancel:
ime_GetImeGuiClose:
ime_GetImeGuiEscape:
Gui,ime_GetIme:Destroy
arr_ImeName:=[]
Return

Switch2En:
If _Is_CAD() And (A_Cursor="Unknown")
	DllCall("SendMessage",UInt,WinActive("A"),UInt,80,UInt,1,UInt,DllCall("LoadKeyboardLayout",Str,in_En,UInt,1))
Return

_get_IMEName(s)
{
	Global arr_ImeName
	For r In arr_ImeName
	{
		If (arr_ImeName[r]=s)
			Break
	}
	Return r
}

_Is_CAD(){
	WinGet,r,ProcessName,A
	If (r="acad.exe") Or (r="gcad.exe")
		Return 1
	Return 0
}

;----- CAD 自动替换字体为 hztxt.shx；AutoCAD 2019 自动关闭教育版戳记窗口；自动跳过 HGCAD 插件对话框-----

cad_AutoFunc:
If arr_CADAid[1] And WinExist("指定字体 Ahk_Class #32770")	;自动替换字体
{
	WinActivate
	WinGet,PrN_CAD,ProcessName
	If (PrN_CAD="gcad.exe"){
		Try{
			Control,ChooseString,hztxt.shx,ListBox1,指定字体的样式 ahk_class #32770 ahk_exe gcad.exe
		}Catch
			func_ShowInfoTip("CAD 替换字体中出现问题",,,,0)
	}Else If (PrN_CAD="acad.exe"){
		ControlGetText,PrN_CAD,Static3
		PrN_CAD:=Trim(SubStr(PrN_CAD,InStr(PrN_CAD,":")+1))
		FileAppend,`n%PrN_CAD%`;%str_Font%,%A_Appdata%\Autodesk\AutoCAD 2019\R23.0\chs\support\acad.fmp
		SendInput {Esc}
	}
}
If arr_CADAid[2] And WinActive("教育版 - 检测到打印戳记 ahk_class #32770")	;自动关闭教育版戳记窗口
	ControlClick,Button1
If arr_CADAid[3] And WinActive("设置IE首页 ahk_class #32770")	;自动跳过 HGCAD 插件对话框
	ControlClick,Button6
Return

;----- CAD 文件关联查看及切换-----

#if arr_CADAid[4]
^!BackSpace::
Menu,menu_CADShell,Add,CAD 文件关联查看及切换,cmd_Null
Menu,menu_CADShell,Add,
Menu,menu_CADShell,Default,CAD 文件关联查看及切换
Menu,menu_CADShell,Disable,CAD 文件关联查看及切换
nCount:=0
Loop,Reg,HKCR,K
{
	If RegexMatch(A_LoopRegName,"(AutoCAD\.Drawing\.|Gcad\.Drawing\.dwg\.|YaoCCAD\.Drawing|ZWCAD\.Drawing\.)[\d]*")
	{
		Menu,menu_CADShell,Add,%A_LoopRegName%,cmd_CADShell
		nCount+=1
	}
}
If (nCount>0){
	RegRead,str_CADShell,HKCR\.dwg
	Menu,menu_CADShell,Check,%str_CADShell%
}Else{
	Menu,menu_CADShell,Add,未安装 CAD 程序！,cmd_CADShell
	Menu,menu_CADShell,Disable,未安装 CAD 程序！
}
Menu,menu_CADShell,Show
Menu,menu_CADShell,Delete
nCount=
Return
#if

cmd_Null:
Return

cmd_CADShell:
If (A_ThisMenuItem=str_CADShell)
	Return
Gui,+OwnDialogs
Msgbox,262180,DWG 文件关联切换,关联 dwg 文件到「%A_ThisMenuItem%」？
IfMsgBox,No
	Return
RegWrite,REG_SZ,HKCU,Software\Classes\.dwg,,%A_ThisMenuItem%
If ErrorLevel
	Msgbox,262192,操作失败,设置 dwg 文件关联错误，请检查后重试！
Else{
	Msgbox,262192,操作成功,已成功将 dwg 文件关联到「%A_ThisMenuItem%」。,5
	Menu,menu_CADShell,UnCheck,%str_CADShell%
	Menu,menu_CADShell,Check,%A_ThisMenuItem%
	str_CADShell:=A_ThisMenuItem
}
Return