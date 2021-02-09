; @title: 文本/文件编码
; -------------------

#NoTrayIcon
#SingleInstance Ignore
Menu,Tray,Icon,shell32.dll,-45

Global str_HexBin:="0_0000|1_0001|2_0010|3_0011|4_0100|5_0101|6_0110|7_0111|8_1000|9_1001|A_1010|B_1011|C_1100|D_1101|E_1110|F_1111"
,str_Base64:="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",iTick,_crypto_exe:=A_ScriptDir . "\Data\crypto.exe"

Gui,Font,,Tahoma
Gui,Font,,Microsoft Yahei
Gui,Add,Tab2,x0 y0 w0 h0 vcoder_Tab,Tab
Gui,Add,Edit,x10 y30 w300 h280 vcoder_Box,
Gui,Add,Edit,x340 y30 w300 h280 vcoder_Re,
Gui,Font,Bold
Gui,Add,Radio,x10 y8 Checked gcoder_Do vcoder_Type1,处理文本(&C)
Gui,Add,Radio,x10 y325 gcoder_Do vcoder_Type2,或文件(&F)
Gui,Font,Norm
Gui,Add,Text,x345 y8 vcoder_Txt,处理结果(&R)
Gui,Add,Button,x313 y100 w25 h30 Disabled gcoder_Do vcoder_Switch1,←
Gui,Add,Button,x313 y135 w25 h30 Disabled gcoder_Do vcoder_Switch2,☈
Gui,Add,Edit,x90 y320 w465 Disabled vcoder_FilePath,
Gui,Add,Button,x560 y320 w40 h25 Disabled gcoder_Do vcoder_Find,...
Gui,Font,Bold
Gui,Add,Button,x600 y320 w40 h25 Disabled gcoder_Do vcoder_Enc,￡
Gui,Font,Norm
Gui,Add,GroupBox,x10 y350 w630 h90 ,
Gui,Add,Radio,x30 y375 gcoder_Do vcoder_C1,URL编码(&U)
Gui,Add,Radio,x145 y375 gcoder_Do vcoder_C2,URL解码(&T)
Gui,Add,Radio,x255 y375 gcoder_Do vcoder_C3,Base64编码(&B)
Gui,Add,Radio,x370 y375 gcoder_Do vcoder_C4,Base64解码(&A)
Gui,Add,Radio,x490 y375 Checked gcoder_Do vcoder_C5,计算MD5[32位](&M)
If FileExist(_crypto_exe)
{
	Gui,Add,Radio,x30 y410 Disabled gcoder_Do vcoder_C6,文件加密(&D)
	Gui,Add,Radio,x145 y410 Disabled gcoder_Do vcoder_C7,文件解密(&E)
	Gui,Add,Text,x255 y410 Hidden vcoder_Info,密码(&P):
	Gui,Add,Edit,x305 y405 w150 Hidden Password vcoder_Pass,
}
Gui,Font,Bold
Gui,Add,CheckBox,x530 y410 Hidden gcoder_Do vcoder_Batch,批量模式(&Z)
Gui,Font,Normal
Gui,Add,CheckBox,x20 y465 Disabled vcoder_ByLine,按行编解码(&L)
Gui,Add,Button,x445 y460 w100 gcoder_Run,执行(&R)
Gui,Add,Button,x550 y460 w90 gcoder_Cancel,退出(&X)
Gui,Tab
Gui,Add,ListView,x10 y10 w630 h300 Grid ReadOnly Hidden vcoder_FileList,文件列表|保存到|状态
Lv_ModifyCol(1,300),Lv_ModifyCol(2,250),Lv_ModifyCol(3,"50 center")
Gui,Tab
Gui,Show,,文本/文件编解码
Menu,menu_Encode,Add,ANSI (默认),cmd_Encode
Menu,menu_Encode,Add,UTF-8,cmd_Encode
Menu,menu_Encode,Add,UTF-8-RAW,cmd_Encode
Menu,menu_Encode,Add,UTF-16,cmd_Encode
Menu,menu_Encode,Add,UTF-16-RAW,cmd_Encode
Menu,menu_Encode,Check,ANSI (默认)

Menu,Menu_Bat,Add,添加文件,cmd_Bat
Menu,Menu_Bat,Add,添加目录,cmd_Bat
Menu,Menu_Bat,Add,
Menu,Menu_Bat,Add,删除文件,cmd_Bat
Menu,Menu_Bat,Add,清空列表,cmd_Bat
Menu,Menu_Bat,Add,
Menu,Menu_Bat,Add,指定保存路径,cmd_Bat
b_CodeType:=b_BatMode:=b_CodeOK:=Is_BatRunning:=0,b_MD5:=1,str_MenuEnc:="ANSI (默认)",strEnc_Code:=str_lastBox:="",last_Ctrl:=0
Return

GuiContextMenu:
If (A_GuiControl<>"coder_FileList") Or Is_BatRunning
	Return
Menu,Menu_Bat,Show
Return

GuiDropFiles:
If (b_CodeType<>1)
	Return
If !b_BatMode
{
	Loop,Parse,A_GuiEvent,`n
	{
		GuiControl,,coder_FilePath,%A_LoopField%
		Break
	}
}Else{
	GuiControl,Focus,coder_FileList
	Lv_Modify(0,"-select")
	Loop,Parse,A_GuiEvent,`n
		Lv_Add("select focus vis",A_LoopField,,"-")
}
Return

coder_Do:
If A_GuiControl In coder_Type1,coder_Type2
{
	b_CodeType:=SubStr(A_GuiControl,0)-1
	If !b_CodeType
	{
		GuiControlGet,tempStr,,coder_C6
		GuiControlGet,tempText,,coder_C7
		If tempStr Or tempText
			GuiControl,,coder_C5,1
	}
	tempStr:=!b_CodeType
	GuiControl,Hide%tempStr%,coder_Batch
	GuiControl,Disable%b_CodeType%,coder_Box
	GuiControl,Disable%b_CodeType%,coder_Re
	GuiControl,Disable%b_CodeType%,coder_Switch1
	GuiControl,Disable%b_CodeType%,coder_Switch2
	GuiControl,Enable%b_CodeType%,coder_FilePath
	GuiControl,Enable%b_CodeType%,coder_Find
	GuiControl,Enable%b_CodeType%,coder_C6
	GuiControl,Enable%b_CodeType%,coder_C7
	tempText:=0
	If b_CodeType
	{
		loop,4
		{
			GuiControlGet,tempStr,,coder_C%A_Index%
			If tempStr
			{
				tempText:=1
				Break
			}
		}
		If tempText
			GuiControl,Enable,coder_Enc
	}Else
		GuiControl,Disable,coder_Enc
	tempStr:=tempText:=""
}Else If (A_GuiControl="coder_Switch1"){
	GuiControlGet,str_lastBox,,coder_Box
	GuiControlGet,tempStr,,coder_Re
	GuiControl,,coder_Box,%tempStr%
	tempStr=
}Else If (A_GuiControl="coder_Switch2"){
	GuiControl,,coder_Box,%str_lastBox%
	str_lastBox=
}Else If A_GuiControl In coder_C1,coder_C2,coder_C3,coder_C4,coder_C5,coder_C6,coder_C7
{
	If (A_GuiControl<>last_Ctrl)
		GuiControl,,Coder_Pass,
	b_MD5:=(A_GuiControl="coder_C5")?1:0,tempStr:=0,tempText:=SubStr(A_GuiControl,0)
	If tempText In 3,4
		tempStr:=1
	GuiControl,Enable%tempStr%,coder_ByLine
	tempStr:=0
	If tempText In 6,7
		tempStr:=1
	GuiControl,Show%tempStr%,Coder_Info
	GuiControl,Show%tempStr%,Coder_Pass
	If b_CodeType
	{
		tempStr:=0
		 If tempText In 5,6,7
			tempStr:=1
		GuiControl,Disable%tempStr%,coder_Enc
	}
	If b_BatMode
	{
		Lv_ModifyCol(2,,b_MD5?"MD5值":"保存到"),Lv_Modify(0,"col3","-")
		Menu,Menu_Bat,ReName,7&,% b_MD5?"复制MD5列表":"指定保存路径"
		If b_MD5 Or ((last_Ctrl="coder_C5") And (A_GuiControl<>last_Ctrl))
			Lv_Modify(0,"col2","")
	}
	last_Ctrl:=A_GuiControl,tempStr:=tempText:=""
}Else If (A_GuiControl="coder_Find"){
	Gui,+OwnDialogs
	FileSelectFile,tempStr,,,选择要编/解码的文本文件,
	If ErrorLevel Or (tempStr="")
		Return
	GuiControl,,coder_FilePath,%tempStr%
	str_CodePath:=tempStr,tempStr:=""
}Else If  (A_GuiControl="coder_Batch"){
	GuiControlGet,b_BatMode,,coder_Batch
	GuiControl,% b_BatMode?"Disable":"Enable",coder_FilePath
	GuiControl,% b_BatMode?"Disable":"Enable",coder_Find
	GuiControl,% b_BatMode?"Hide":"Show",coder_Type1
	GuiControl,% b_BatMode?"Hide":"Show",coder_Txt
	GuiControl,% b_BatMode?"Hide":"Show",coder_Switch1
	GuiControl,% b_BatMode?"Hide":"Show",coder_Switch2
	GuiControl,% b_BatMode?"Hide":"Show",coder_Box
	GuiControl,% b_BatMode?"Hide":"Show",coder_Re
	tempStr:=!b_BatMode
	GuiControl,Hide%tempStr%,coder_FileList
	If b_BatMode
	{
		Lv_ModifyCol(2,,b_MD5?"MD5":"保存到")
		Menu,Menu_Bat,ReName,7&,% b_MD5?"复制MD5列表":"指定保存路径"
	}
	tempStr=
}Else If  (A_GuiControl="coder_Enc")
	Menu,menu_Encode,Show
Return

cmd_Encode:
Menu,menu_Encode,UnCheck,%str_MenuEnc%
Menu,menu_Encode,Check,%A_ThisMenuItem%
str_MenuEnc:=A_ThisMenuItem
If (A_ThisMenuItemPos=1)
	strEnc_Code:=""
Else
	strEnc_Code:=A_ThisMenuItem
Return

cmd_Bat:
If A_ThisMenuItemPos In 1,2,4,7
	Lv_Modify(0,"col3","-")
Gui,+OwnDialogs
If A_ThisMenuItemPos In 1,2
{
	If (A_ThisMenuItemPos=1)
		FileSelectFile,tempStr,M,,选择预编码的文件
	Else
		FileSelectFolder,tempStr,,,选择包含预编码文件的目录，默认包含子目录
	If ErrorLevel Or (tempStr="")
		Return
	GuiControl,-ReDraw,coder_FileList
	If (A_ThisMenuItemPos=1){
		Loop,parse,tempStr,`n
		{
			If (A_Index=1)
				tPath:=RegExReplace(A_LoopField,"\\$") . "\"
			Else
				Lv_Add("select Focus",tPath . A_LoopField,,"-")
		}
		tPath=
	}Else{
		Loop,Files,%tempStr%\*.*,FR
			Lv_Add("select Focus",A_LoopFileFullPath,,"-")
	}
	GuiControl,+ReDraw,coder_FileList
	Lv_Modify(Lv_GetCount(),"vis"),tempStr:=""
	LV_ModifyCol(1,,"文件列表 [" Lv_GetCount() "]")
}Else If A_ThisMenuItemPos In 4,5
{
	MsgBox,262196,确认操作,% "确定要" ((A_ThisMenuItemPos=4)?"删除选择文件":"清空列表") "？`n该操作无法恢复！"
	IfMsgBox,No
		Return
	If (A_ThisMenuItemPos=5){
		Lv_Delete()
		Return
	}
	tempStr:=0
	Loop
	{
		tempStr:=LV_GetNext(tempStr-1)
		if not tempStr
			break
		LV_Delete(tempStr)
	}
	tempStr=
}Else If (A_ThisMenuItemPos=7){
	If b_MD5
	{
		
	}Else{
		FileSelectFolder,tPath,,,选择保存编码后文件所要保存的位置
		If ErrorLevel Or (tPath="")
			Return
		tempStr:=0
		Loop
		{
			tempStr:=LV_GetNext(tempStr)
			if not tempStr
				break
			Lv_Modify(tempStr,"col2",tPath)
		}
		tempStr:=tPath:=""
	}
}
Return

coder_Run:
;获取参数并判断
If (b_CodeType=0){		;文本编解码
	GuiControlGet,str_CodeGetText,,coder_Box
	If (str_CodeGetText=""){
		GuiControl,Focus,coder_Box
		Return
	}
	GuiControl,Enable,coder_Switch1
	GuiControl,Enable,coder_Switch2
}Else{		;文件编解码
	If b_BatMode
	{
		If (Lv_GetCount()=0)
			Return
		Gui,+OwnDialogs
		MsgBox,262180,执行操作,开始执行批量处理？
		IfMsgBox,No
			Return
	}Else{
		GuiControlGet,str_CodeGetFPath,,coder_FilePath
		If (str_CodeGetFPath="") Or !FileExist(str_CodeGetFPath)
		{
			GuiControl,Focus,coder_FilePath
			Return
		}
	}
}

Loop,% (b_CodeType=0)?5:(FileExist(_crypto_exe)?7:5)
{
	GuiControlGet,tempStr,,coder_C%A_Index%
	If tempStr
	{
		b_CodeGetAct:=A_Index
		Break
	}
}
If b_CodeGetAct In 3,4
	GuiControlGet,b_CodeByLine,,coder_ByLine
If b_CodeGetAct In 6,7	;加解密
{
	GuiControlGet,str_CodePass,,Coder_Pass
	If (str_CodePass=""){
		GuiControl,Focus,Coder_Pass
		Return
	}
}
;开始编码操作
_code_Begin()
If (b_CodeType=0){	;文本编码
	str_CodeOut:=""
	If (b_CodeGetAct=1)
		str_CodeOut:=str2UTF8(str_CodeGetText)
	Else If (b_CodeGetAct=2)
		str_CodeOut:=UTF82Str(str_CodeGetText)
	Else If b_CodeGetAct In 3,4
	{
		If b_CodeByLine
		{
			Loop,Parse,str_CodeGetText,`n
				str_CodeOut .= ((b_CodeGetAct=3)?Str2Base64(A_LoopField,0):Str2Base64(A_LoopField,0))  . "`n"
			str_CodeOut:=SubStr(str_CodeOut,1,-1)
		}Else
			str_CodeOut:=(b_CodeGetAct=3)?Str2Base64(str_CodeGetText,0):Base642Str(str_CodeGetText,0)
	}Else If (b_CodeGetAct=5)
		str_CodeOut:=Str_MD5(str_CodeGetText)
	GuiControl,,coder_Re,%str_CodeOut%
	_code_End()
}Else{	;文件编码
	last_Encoding:=A_FileEncoding
	FileEncoding,%strEnc_Code%
	If !b_BatMode
	{
		Gui,+OwnDialogs
		If (b_CodeGetAct=5){
			Clipboard:=func_FileCoder(str_CodeGetFPath),_code_End()
			MsgBox,262208,编码,[文件] %str_CodeGetFPath%`n[MD5] %Clipboard%`n`n已复制到剪贴板。
		}Else{
			tempStr:=func_FileCoder(str_CodeGetFPath),_code_End()
			If (tempStr<>0)
				MsgBox,262208,文件编码,文件编码完成！编码后的文件保存为:`n%tempStr%
			Else
				MsgBox,262192,文件编码,文件编码中发生错误，请重试！
			tempStr=
		}
	}Else{	;批量模式
		GuiControl,Focus,coder_FileList
		Lv_Modify(0,"-select col3","-"),Is_BatRunning:=1
		Loop,% Lv_GetCount()
		{
			Lv_GetText(tempStr,A_Index)
			If (b_CodeGetAct=5)
				Lv_Modify(A_Index,"vis select Focus col2",func_FileCoder(tempStr)),Lv_Modify(A_Index,"col3","✔")
			Else
				Lv_GetText(tempText,A_Index,2),Lv_Modify(A_Index,"select Focus col3",(func_FileCoder(tempStr,tempText)=0)?"✖":"✔")
		}
		Is_BatRunning:=0,tempStr:=tempText:="",_code_End()
	}
	FileEncoding,%last_Encoding%
	last_Encoding=
}
Return

func_FileCoder(src,des:=""){
	Global b_CodeGetAct,b_CodeByLine,str_CodePass
	If (b_CodeGetAct=5)	;计算MD5
		Return File_MD5(src)
	SplitPath,src,,s1,s2,s3		;获取保存路径
	GuiControlGet,s,,coder_C%b_CodeGetAct%,Text
	s:=SubStr(s,1,-4),s:=s3 . "_" . s . ((InStr("34",b_CodeGetAct) And b_CodeByLine)?"_1":"") . "." . s2	;s——新文件名
	If (des=""){	;未指定保存路径时默认保存到同目录
		If b_CodeGetAct In 6,7
			des:=s1	;加解密时目录不带反斜杠
		Else{
			des:=s1 . "\" . s
			If FileExist(des)
				FileDelete,%des%
		}
	}Else
		des:=RegexReplace(des,"\\$")

	If InStr("12",b_CodeGetAct) Or (InStr("34",b_CodeGetAct) And b_CodeByLine)
	{
		Loop,Read,%src%,%des%
		{
			If (b_CodeGetAct=1)
				FileAppend,% ((A_Index=1)?"":"`n") . str2UTF8(A_LoopReadLine)
			Else If (b_CodeGetAct=2)
				FileAppend,% ((A_Index=1)?"":"`n") . UTF82Str(A_LoopReadLine)
			Else If (b_CodeGetAct=3)
				FileAppend,% ((A_Index=1)?"":"`n") . Str2Base64(A_LoopReadLine,0)
			Else If (b_CodeGetAct=4)
				FileAppend,% ((A_Index=1)?"":"`n") . Base642Str(A_LoopReadLine,0)
		}
		Return des
	}
	If InStr("34",b_CodeGetAct) And !b_CodeByLine
	{
		Try
		{
			FileRead,t,%src%
			FileAppend,% (b_CodeGetAct=3)?Str2Base64(t,0):Base642Str(t,0),%des%
			Return des
		}Catch
			Return 0
	}
	If (b_CodeGetAct=6){
		t:=des "\" s3 "." s2 ".crp"
		If FileExist(t)
			FileDelete,%t%
		RunWait,"%_crypto_exe%" e /ealgm:SEAL160_LE /lz4 /pass:%str_CodePass% /to:"%des%" "%src%",%A_ScriptDir%,Hide UseErrorLevel
		If (ErrorLevel<>"ERROR")
			Return FileExist(t)?t:0
		Return 0
	}Else If (b_CodeGetAct=7){
		t:=des "\" A_Now,e:=1
		FileDelete,%t%\*.tmp
		RunWait,"%_crypto_exe%" d /pass:%str_CodePass% /to:"%t%" "%src%",%A_ScriptDir%,Hide UseErrorLevel
		If (ErrorLevel<>"ERROR") And !FileExist(t . "\*.tmp") And ((r:=_get_FileFrDir(t))<>0)
		{
			e:=0
			FileMove,%r%,%des%,1
			SplitPath,r,r
		}
		FileRemoveDir,%t%,1
		Return e?0:(des "\" r)
	}
}

#if Is_BatRunning
Lbutton::Return
#If

_get_FileFrDir(s){
	n:=0
	Loop,Files,%s%\*.*,F
	{
		r:=A_LoopFileFullPath
		n+=1
	}
	Return (n=1)?r:0
}

_code_Begin(){
	iTick:=A_TickCount
	GuiControl,Disable,coder_Tab
	SplashImage,,b1 fs10 cwfffffc FM10,编码中，请稍侯……,,,Microsoft Yahei
}

_code_end(){
	Global b_CodeType
	If !b_CodeType
	{
		Loop
		{
			If (A_TickCount-iTick>=500)
				Break
		}
	}
	SplashImage,Off
	GuiControl,Enable,coder_Tab
}

coder_Cancel:
GuiClose:
ExitApp
Return
;;---------------- 字符编码区 -----

Str2Base64(s,b:=1){
	If (s="")
		Return
	t:=r:=""
	Loop,Parse,s
	{
		s1:=Asc(A_LoopField)
		If (s1<=127)
			t .= make0(ToBase(s1,2),1)
		Else{	;汉字
			s2:=ToBase(s1,16),s3:=""
			Loop,Parse,s2
				s3 .= SubStr(str_HexBin,InStr(str_HexBin,A_LoopField . "_")+2,4)
			If s1 Between 128 And 2047
				s3:=make0(11-StrLen(s3)) . s3,t .= "110" . SubStr(s3,1,5) . "10" . SubStr(s3,-5)
			If s1 Between 2048 And 65536
				s3:=make0(16-StrLen(s3)) . s3,t .= "1110" . SubStr(s3,1,4) . "10" . SubStr(s3,5,6) . "10" . SubStr(s3,-5)
		}
	}
	s1:=StrLen(t),s2:=Mod(s1,6)
	If (s2=4)
		t .= "00",s1:=(s1+2)/6
	Else If (s2=2)
		t .= "0000",s1:=(s1+4)/6
	Else If (s2=0)
		s1 /= 6
	Loop,%s1%
		r .= SubStr(str_Base64,Bin2Dec("00" . SubStr(t,(A_Index-1)*6+1,6))+1,1)
	t:=(b=1)?"+":"="
	If (s2=4)
		r .= t
	If (s2=2)
		r .= t . t
	s1:=s2:=s3:=t:=""
	Return r
}

Base642Str(s,b:=1){
	If (s="")
		Return
	r:=(b=1)?"+":"=",s:=StrReplace(s,r,,n),n*=2,r:=""
	Loop,Parse,s
		r .= SubStr(make0(ToBase(InStr(str_Base64,A_LoopField,1)-1,2),1),3)
	If (n>0)
		r:=SubStr(r,1,-1*n)
	s1:=StrLen(r),s2:=1,out:=n:=""
	Loop
	{
		s3:=SubStr(r,s2,8)
		If (SubStr(s3,1,4)="1110")
			s3 .= SubStr(r,s2+8,16),out .= Chr(Bin2Dec(SubStr(s3,5,4) . SubStr(s3,11,6) . SubStr(s3,19,6))),s2+=24
		Else If (SubStr(s1,1,3)="110")
			s3 .= SubStr(r,s2+8,8),out .= Chr(Bin2Dec(SubStr(s3,4,5) . SubStr(s3,11,6))),s2+=16
		Else
			out .= Chr(Bin2Dec(s3)),s2+=8
		If (s2>=s1)
			Break
	}
	s1:=s2:=s3:=r:=""
	Return out
}

;Str_MD5(s){	;备用，测试仅英文有效
;	If (s="")
;		Return
;	r:="",VarSetCapacity(MD5_CTX,104,0)
;	,DllCall("advapi32\MD5Init",UInt,&MD5_CTX)
;	,DllCall("advapi32\MD5Update",UInt,&MD5_CTX,A_IsUnicode?"AStr":"Str",s,UInt,StrLen(s))
;	,DllCall("advapi32\MD5Final",UInt,&MD5_CTX)
;	Loop % StrLen(Hex:="123456789abcdef0")
;		t:=NumGet(MD5_CTX,87+A_Index,"Char"),r .= SubStr(Hex,t>>4,1) . SubStr(Hex,t&15,1)
;	Hex:=t:="",VarSetCapacity(MD5_CTX,0)
;	Return r
;}

Str_MD5(s,encoding="UTF-8")
{
	return CalcStringHash(s,0x8003,encoding)
}
 
CalcStringHash(s,algid,encoding="UTF-8",byref hash=0,byref hashlength=0)
{
	chrlength:=(encoding="CP1200" || encoding="UTF-16")?2:1
	length:=(StrPut(s,encoding) - 1) * chrlength
	VarSetCapacity(data,length,0)
	StrPut(s,&data,floor(length / chrlength),encoding)
	return CalcAddrHash(&data,length,algid,hash,hashlength)
}
 
CalcAddrHash(addr,length,algid,byref hash=0,byref hashlength=0)
{
	static h:=[0,1,2,3,4,5,6,7,8,9,"a","b","c","d","e","f"]
	static b:=h.minIndex()
	hProv:=hHash:=o:=""
	if (DllCall("advapi32\CryptAcquireContext","Ptr*",hProv,"Ptr",0,"Ptr",0,"UInt",24,"UInt",0xf0000000))
	{
		if (DllCall("advapi32\CryptCreateHash","Ptr",hProv,"UInt",algid,"UInt",0,"UInt",0,"Ptr*",hHash))
		{
			if (DllCall("advapi32\CryptHashData","Ptr",hHash,"Ptr",addr,"UInt",length,"UInt",0))
			{
				if (DllCall("advapi32\CryptGetHashParam","Ptr",hHash,"UInt",2,"Ptr",0,"UInt*",hashlength,"UInt",0))
				{
					VarSetCapacity(hash,hashlength,0)
					if (DllCall("advapi32\CryptGetHashParam","Ptr",hHash,"UInt",2,"Ptr",&hash,"UInt*",hashlength,"UInt",0))
					{
						loop % hashlength
						{
							v:=NumGet(hash,A_Index - 1,"UChar")
							o .= h[(v >> 4) + b] h[(v & 0xf) + b]
						}
					}
				}
			}
			DllCall("advapi32\CryptDestroyHash","Ptr",hHash)
		}
		DllCall("advapi32\CryptReleaseContext","Ptr",hProv,"UInt",0)
	}
	return o
}

File_MD5(fp){
	If (fp="")
		Return
	PROV_RSA_AES:=24,CRYPT_VERIFYCONTEXT:=0xF0000000,BUFF_SIZE:=1024 * 1024,HP_HASHVAL:=0x0002,HP_HASHSIZE:=0x0004,CALG_MD5:=32771,HASH_ALG:=32771,f:=FileOpen(fp,"r","CP0")
	if !IsObject(f)
		return 0
	if !hModule:=DllCall( "GetModuleHandleW","str","Advapi32.dll","Ptr")
		hModule:=DllCall( "LoadLibraryW","str","Advapi32.dll","Ptr")
	if !dllCall("Advapi32\CryptAcquireContextW","Ptr*",hCryptProv,"Uint",0,"Uint",0,"Uint",PROV_RSA_AES,"UInt",CRYPT_VERIFYCONTEXT)
		Goto,FreeHandles
	if !dllCall("Advapi32\CryptCreateHash","Ptr",hCryptProv,"Uint",HASH_ALG,"Uint",0,"Uint",0,"Ptr*",hHash)
		Goto,FreeHandles
	VarSetCapacity(read_buf,BUFF_SIZE,0),hCryptHashData:=DllCall("GetProcAddress","Ptr",hModule,"AStr","CryptHashData","Ptr")
	While (cbCount:=f.RawRead(read_buf,BUFF_SIZE)){
		if (cbCount = 0)
			break
		if !dllCall(hCryptHashData,"Ptr",hHash,"Ptr",&read_buf,"Uint",cbCount,"Uint",0)
			Goto,FreeHandles
	}
	if !dllCall("Advapi32\CryptGetHashParam","Ptr",hHash,"Uint",HP_HASHSIZE,"Uint*",HashLen,"Uint*",HashLenSize:=4,"UInt",0)
		Goto,FreeHandles
	VarSetCapacity(pbHash,HashLen,0)
	if !dllCall("Advapi32\CryptGetHashParam","Ptr",hHash,"Uint",HP_HASHVAL,"Ptr",&pbHash,"Uint*",HashLen,"UInt",0 )
		Goto,FreeHandles
	SetFormat,integer,Hex
	loop,%HashLen%
	{
		num:=numget(pbHash,A_index-1,"UChar")
		hashval .= substr((num >> 4),0) . substr((num & 0xf),0)
	}
	SetFormat,integer,D

	FreeHandles:
	f.Close()
	DllCall("FreeLibrary","Ptr",hModule),dllCall("Advapi32\CryptDestroyHash","Ptr",hHash),dllCall("Advapi32\CryptReleaseContext","Ptr",hCryptProv,"UInt",0)
	StringLower,hashval,hashval
	return hashval
}

str2UTF8(s){
	;s1: ASCII; s2:十六进制； s3:二进制; s4:新十六进制
	If (s="")
		Return
	r=
	Loop,Parse,s
	{
		s1:=Asc(A_LoopField)
		If (s1>127){
			s2:=ToBase(s1,16),s3:=""
			Loop,Parse,s2
				s3 .= SubStr(str_HexBin,InStr(str_HexBin,A_LoopField . "_",0)+2,4)
			If s1 Between 128 And 2047
				s3:=make0(11-StrLen(s3)) . s3,s4:=Bin2Hex("110" . SubStr(s3,1,5),1) . Bin2Hex("10" . SubStr(s3,-5),1)
			If s1 Between 2048 And 65536
				s3:=make0(16-StrLen(s3)) . s3,s4:=Bin2Hex("1110" . SubStr(s3,1,4),1) . Bin2Hex("10" . SubStr(s3,5,6),1) . Bin2Hex("10" . SubStr(s3,-5),1)
			r .= s4
		} Else
			r .= A_LoopField
		s1:=s2:=s3:=s4:=""
	}
	Return r
}

UTF82Str(s){
	If (s="")
		Return
	b:=n:=0,i:=1,t:=r:=""
	Loop,Parse,s
	{
		If b
		{
			t .= A_LoopField,i+=1
			If (i=2){
				If A_LoopField In C,D
					n:=6
				Else If A_LoopField In E,F
					n:=9
				Else
					n:=3
			}
			If (i=n)
				r .= UTF8_Decode(t),b:=0,n:=0,i:=1,t:=""
		}Else{
			If (A_LoopField="%")
				b:=1
			Else
				r .= A_LoopField
		}
	}
	b:=n:=i:=t:=""
	Return r
}

UTF8_Decode(s){
	t:="",s:=StrReplace(s,"%")
	Loop,Parse,s
		t .= SubStr(str_HexBin,InStr(str_HexBin,A_LoopField . "_",0)+2,4)
	If (StrLen(s)=6)
		t:=SubStr(t,5,4) . SubStr(t,11,6) . SubStr(t,19,6)
	Else If (StrLen(s)=4)
		t:=SubStr(t,4,5) . SubStr(t,11,6)
	Else
		t:=SubStr(t,2,7)
	Return Chr(Bin2Dec(t))
}

make0(s,b=0){
	r=
	If b
		n:=8-StrLen(s)
	Else
		n:=s
	Loop,%n%
		r .= "0"
	If b
		r .= s
	s:=n:=b:=""
	Return r
}

;;----------------进制转换-----------

ToBase(n,b){
	Return (n<b?"":ToBase(n//b,b)) . ((d:=Mod(n,b))<10?d:Chr(d+55))
}

Bin2Dec(s){	;2进制转10进制
	n:=StrLen(s)-1,r:=""
	Loop,Parse,s
	{
		r += (A_LoopField << n)
		n-=1
	}
	Return r
}

Bin2Hex(s,b=0){	;2进制转16进制
	t:=b?"%":""
	Return t . SubStr(str_HexBin,InStr(str_HexBin,"_" . SubStr(s,1,4),0)-1,1) . SubStr(str_HexBin,InStr(str_HexBin,"_" . SubStr(s,-3),0)-1,1)
}