; @title: 创建符号链接
; -------------------

#NoTrayIcon
#SingleInstance Ignore
Menu,Tray,Icon,shell32.dll,-257

Gui,+hwndid_mklWin +AlwaysOnTop
Gui,Font,,Tahoma
Gui,Font,,微软雅黑
Gui,Add,Tab2,x0 y0 w0 h0 vmkl_Tab,Tab
Gui,Add,Text,x15 y20 vmkl_Txt,目录联接名(&N)
Gui,Font,Bold
Gui,Add,Edit,x100 y17 w300 c800000 r1 gmkl_Do vmkl_Name,
Gui,Font,Norm
Gui,Add,Button,x10 y50 w80 gmkl_Do vmkl_BtnDes,联接目录(&P)
Gui,Add,Edit,x100 y50 w270 r1 vmkl_Des,
Gui,Add,Button,x375 y50 w25 h25 gmkl_Do vmkl_GetDesDir,╃
Gui,Add,Button,x10 y85 w80 gmkl_Do vmkl_BtnSrc,源目录(&S)
Gui,Add,Edit,x100 y85 w270 r1 gmkl_Do vmkl_Src,
Gui,Add,Button,x375 y85 w25 h25 gmkl_Do vmkl_GetSrcDir,╃
Gui,Font,Bold
Gui,Add,CheckBox,x12 y133 gmkl_Do vmkl_Switch,文件符号链接
Gui,Font,Norm
Gui,Add,Button,x195 y125 w100 Default gmkl_Do vmkl_Run,执行(&R)
Gui,Add,Button,x300 y125 w100 gmkl_Do vmkl_Exit,退出(&X)
Gui,Tab
Gui,Add,Edit,x10 y160 w390 h120 cblue ReadOnly 0x100 -Wrap HScroll hwndid_mklOut vmkl_Out,% _Get_Time() " 就绪"
Gui,Show,,创建目录联接「mklink /j」
_Is_MKLFile:=0
Return

mkl_Do:
If (A_GuiControl="mkl_BtnSrc"){
	Gui,+OwnDialogs
	If _Is_MKLFile
		FileSelectFile,tempStr,32,,选择真实存在的源文件
	Else
		FileSelectFolder,tempStr,,,选择真实存在的源目录
	If ErrorLevel Or (tempStr="")
		Return
	GuiControl,,mkl_Src,%tempStr%
	tempStr=
}Else If (A_GuiControl="mkl_BtnDes"){
	Gui,+OwnDialogs
	FileSelectFolder,tempStr,,,选择将符号链接的上级目录
	If ErrorLevel Or (tempStr="")
		Return
	GuiControl,,mkl_Des,%tempStr%
	tempStr=
}Else If A_GuiControl In mkl_GetSrcDir,mkl_GetDesDir
{
	errFlag:=(A_GuiControl="mkl_GetSrcDir")?1:0,tempStr:=""
	SplashImage,,b1 w450 fs10 cwffffcc FM10,激活 TotalCommander 窗口以获取路径；再次返回本程序时自动填充,,,Microsoft Yahei
	If WinExist("ahk_class TTOTAL_CMD")
	{
		;Gui,Minimize
		WinActivate,ahk_class TTOTAL_CMD
		WinWaitNotActive,ahk_class TTOTAL_CMD
		tempStr:=_get_TcFolder()
	}
	WinWaitActive,Ahk_Id %id_mklWin%
	SplashImage,Off
	tempStr:=RegExReplace(tempStr,"\\$")
	If errFlag
	{
		GuiControl,,mkl_Src,%tempStr%
		GuiControl,Focus,mkl_Src
	}Else{
		GuiControl,,mkl_Des,%tempStr%
		GuiControl,Focus,mkl_Des
	}
	SendInput ^a
	tempStr:=errFlag:=""
}Else If (A_GuiControl="mkl_Src"){
	GuiControlGet,tempStr,,mkl_Src
	SplitPath,tempStr,tempStr
	GuiControl,,mkl_Name,%tempStr%
	tempStr=
}Else If (A_GuiControl="mkl_Switch"){
	GuiControlGet,_Is_MKLFile,,mkl_Switch
	GuiControl,,mkl_Txt,% (_Is_MKLFile?"符号链接":"目录联接") . "名(&N)"
	GuiControl,,mkl_BtnDes,% (_Is_MKLFile?"链":"联") . "接目录(&P)"
	GuiControl,,mkl_BtnSrc,% "源" . (_Is_MKLFile?"文件":"目录") . "(&S)"
	GuiControl,,mkl_Src,
	GuiControl,Focus,mkl_Src
	Gui,Color,% _Is_MKLFile?"E2E7F6":"DEFAULT"
	Gui,Show,,% "创建" (_Is_MKLFile?"符号链接「mklink」":"目录联接「mklink /j」")	
}Else If (A_GuiControl="mkl_Run"){	;;执行
	GuiControlGet,tempStr,,mkl_Src
	errFlag:=0
	If (tempStr="") Or !FileExist(tempStr)
		errFlag:=1,tempStr:="未指定源目录或源目录不存在！"
	If !errFlag
	{
		If (!_Is_MKLFile And !InStr(FileExist(tempStr),"D"))
			errFlag:=1,tempStr:="指定源不是目录！"
		If (_Is_MKLFile And InStr(FileExist(tempStr),"D"))
			errFlag:=1,tempStr:="指定源不是文件！"
	}
	If errFlag
	{
		_echo_Out(tempStr)
		GuiControl,Focus,mkl_Src
		SendInput ^a
		Return
	}
	str_MklSrc:=tempStr
	GuiControlGet,tempStr,,mkl_Des
	If (tempStr="") Or !FileExist(tempStr)
	{
		_echo_Out("未指定链接目录，或指定路径不存在！")
		GuiControl,Focus,mkl_Des
		SendInput ^a
		str_MklSrc=
		Return
	}
	str_MklDes:=tempStr
	SplitPath,tempStr,,,,,tempStr
	DriveGet,errFlag,FS,%tempStr%
	If (errFlag<>"NTFS"){
		_echo_Out("磁盘“" . tempStr . "”不是 NTFS 文件系统格式！")
		GuiControl,Focus,mkl_Des
		SendInput ^a
		str_MklSrc:=str_MklDes:=""
		Return
	}
	errFlag:=0
	GuiControlGet,tempStr,,mkl_Name
	If (tempStr="")
		_echo_Out("未设置目录联接名称！"),errFlag:=1
	If (errFlag=0){
		If (RegexMatch(tempStr,"[\\/:\*\?""<>\|]")>0)
			_echo_Out("联接名称不得包含字符:`n%A_Space%\ / : * \ ? "" < > |"),errFlag:=1
	}
	If (errFlag=0){
		str_MklDes:=RegExReplace(str_MklDes,"\\$") . "\" . tempStr
		If (str_MklDes=str_MklSrc)
			_echo_Out("新建目录联接不可与源目录同名！"),errFlag:=1
	}
	If errFlag
	{
		GuiControl,Focus,mkl_Name
		SendInput ^a
		str_MklSrc:=str_MklDes:=""
		Return
	}
	GuiControl,Disable,mkl_Tab
	_echo_Out(cmdClipReturn("mklink" A_Space (_Is_MKLFile?"":"/j ") """" str_MklDes """" A_Space """" str_MklSrc """"))
	SendInput ^{End}
	_echo_Out("操作完成")
	GuiControl,Enable,mkl_Tab
	errFlag:=str_MklSrc:=str_MklDes:=tempStr:=""
}Else If (A_GuiControl="mkl_Exit")
	Gosub GuiClose
Return

GuiClose:
ExitApp
Return

_echo_Out(s){
	Global id_mklOut
	GuiControl,Focus,mkl_Out
	SendInput ^{End}
	Control,EditPaste,% "`r`n" _Get_Time() A_Space s,,Ahk_Id %id_mklOut%	
}

_Get_Time(){
	FormatTime,r,%A_Now%,HH:mm:ss
	Return "[" r "]"
}

_get_TcFolder()
{
	s:=ClipboardAll 
	clipboard=
	SendMessage 1075,2029,0,,ahk_class TTOTAL_CMD
	ClipWait,2 
	r=%clipboard%
	Clipboard:=s 
	s=
	Return r
}

cmdClipReturn(s){
	r=
	t:=ClipboardAll
	try{
		Clipboard:=""
		Run,% ComSpec " /C " s " | CLIP",, Hide
		ClipWait,2
		r:=Clipboard
	}catch{
		r:="ERROR"
	}
	Clipboard:=t
	return Trim(r,"`r `n`t")
}

RemoveSplashImg:
SplashImage,Off
Return