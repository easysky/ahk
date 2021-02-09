; @title: 密码管理器
; -------------------

#SingleInstance Ignore
#NoTrayIcon
CoordMode,ToolTip,Screen
_LAST_ENCODING:=A_FileEncoding

Global _CURR_DB,_CURR_DBMASK,_STR_PASS,arr_Pass,_CURR_ITEM,_str_Dot:="********"
_INI_PATH:=A_ScriptDir . "\Data\exScriptSet.ini",_STR_DBLIST:="|",_COUNT_DB:=0,last_DB:=""
Loop
{
	IniRead,tempStr,%_INI_PATH%,PWDMan,%A_Index%
	If (tempStr="ERROR")
		Break
	tempStr=%tempStr%
	If (tempStr="")
		Continue
	_STR_DBLIST .= tempStr . "|",_COUNT_DB+=1
}

Gui,-MinimizeBox +HwndLogin_ID
Gui,Font,,Tahoma
Gui,Font,,微软雅黑
Gui,Add,Button,x10 y20 w70 h27 gLogin_SelData,密码库(&D)
Gui,Font,Bold
Gui,Add,ComboBox,x85 y20 w230 gLogin_DB vLogin_DB,% Trim(_STR_DBLIST,"|")
Gui,Add,Edit,x85 y60 w230 Password vLogin_Pass,
Gui,Font,Norm
Gui,Add,Text,x13 y65 vLogin_Txt,输入密码(&P)
Gui,Add,Link,x15 y113 gLogin_New,<a Id="1">+ 新建</a>%A_Space%%A_Space%%A_Space%<a Id="2">≡ 管理</a>
Gui,Add,Button,x135 y105 w100 h28 Default gLogin_OK,确定(&O)
Gui,Add,Button,x240 y105 w75 h28 gLogin_Cancel,退出(&X)
Gui,Show,,Easysky 密码管理器

IniRead,tempStr,%_INI_PATH%,PWDMan,Last,%A_Space%
tempStr=%tempStr%
If (tempStr="")
	Return
If InStr(_STR_DBLIST,"|" . tempStr . "|")
{
	GuiControl,Text,Login_DB,%tempStr%
	GuiControl,Focus,Login_Pass
	last_DB:=tempStr
}Else
	IniDelete,%_INI_PATH%,PWDMan,Last
tempStr:="",Is_DBFromNew:=0
Return

GuiDropFiles:
Loop,Parse,A_GuiEvent,`n
{
	tempStr:=A_LoopField
	Break
}
If (SubStr(tempStr,-3)=".edb"){
	GuiControl,Text,Login_DB,%tempStr%
	Gosub Login_DB
}
tempStr=
Return

Login_DB:
GuiControl,,Login_Pass,
GuiControl,Focus,Login_Pass
Return

Login_SelData:
Gui,+OwnDialogs
FileSelectFile,tempStr,3,%A_ScriptDir%,选择密码库文件,密码库 (*.edb)
If ErrorLevel Or (tempStr="") Or (SubStr(tempStr,-3)!=".edb")
{
	GuiControl,Focus,Login_DB
	Return
}
tempStr=%tempStr%
GuiControl,Text,Login_DB,%tempStr%
Gosub Login_DB
tempStr=
Return

Login_New:
Gui,+OwnDialogs
If (ErrorLevel="1"){	;新建密码库
	FileSelectFile,tempStr,S16,%A_ScriptDir%,新建密码库文件,密码库 (*.edb)
	If ErrorLevel Or (tempStr="")
		Return
	tempStr=%tempStr%
	If (SubStr(tempStr,-3)!=".edb")
		tempStr .= ".edb"
	GuiControl,Text,Login_DB,%tempStr%
	Gosub Login_DB
	Gui,Show,,Easysky 密码管理器 - [新建密码库]
	GuiControl,,Login_Txt,设置密码(&P)
	tempStr:="",Is_DBFromNew:=1
}Else{	;管理密码库
	GuiControlGet,curr_PwdData,,Login_DB
	curr_PwdData=%curr_PwdData%
	Gui,+Disabled
	Gosub PWDManager_Win
}
Return

Login_OK:
GuiControlGet,getStr1,,Login_DB
Gui,+OwnDialogs
If (getStr1=""){
	GuiControl,Focus,Login_DB
	Return
}
If !Is_DBFromNew And !FileExist(getStr1)
{
	MsgBox,262192,密码库文件不存在,密码库:`n“%getStr1%”`n不存在或已被删除！
	GuiControl,Focus,Login_DB
	SendInput ^a
	Return
}
GuiControlGet,_STR_PASS,,Login_Pass
If (_STR_PASS=""){
	GuiControl,Focus,Login_Pass
	Return
}
;获取/分析数据库信息
_CURR_DBMASK:=getStr1
If !InStr(_STR_DBLIST,"|" . _CURR_DBMASK . "|")
{
	GuiControl,,Login_DB,%_CURR_DBMASK%
	_COUNT_DB+=1,_STR_DBLIST.=_CURR_DBMASK . "|"
	IniWrite,%_CURR_DBMASK%,%_INI_PATH%,PWDMan,%_COUNT_DB%
}
SplitPath,_CURR_DBMASK,,,,getStr1
_CURR_DB:=A_ScriptDir . "\Data\" . getStr1 . ".ini",getStr1:=""
If Is_DBFromNew
{
	Gui,Show,,Easysky 密码管理器
	GuiControl,,Login_Txt,输入密码(&P)
}
Gui,Cancel
SplashImage,,b1 fs10.5,数据读取中，请稍等……,,,微软雅黑
If !Is_DBFromNew	;打开密码库
{
	If !_crypto(1,_CURR_DBMASK)	;密码库解密
	{	;——失败
		SplashImage,Off
		Gui,Show
		GuiControl,Focus,Login_Pass
		SendInput ^a
		MsgBox,262192,打开密码库,密码错误！
		Return
	}
	;解密成功
	FileGetTime,tmr_DB,%_CURR_DB%
}Else{	;新建密码库
	FileAppend,[PWDMan],%_CURR_DB%,CP936
	fp:=_LockFile(),tmr_DB:=0
}
If (_CURR_DBMASK!=last_DB)
	IniWrite,%_CURR_DBMASK%,%_INI_PATH%,PWDMan,Last
last_DB:=_CURR_DBMASK
GuiControl,,Login_Pass,
Gui,Cancel
Gosub PwdMain_Win
Return

_crypto(bAct,sFile){
	;bAct——1：解密；0：加密；
	s=%A_ScriptDir%\Data\crypto.exe /pass:%_STR_PASS%
	If bAct	;解密
	{
		s .= " d /force"
		If FileExist(_CURR_DB)
			FileDelete,%_CURR_DB%
		FileDelete,%A_ScriptDir%\Data\*.tmp
	}Else{	;加密
		s .= " e /ealgm:SEAL160_LE /lz4"
		If FileExist(sFile . ".crp")
			FileDelete,%sFile%.crp
	}
	RunWait,%s%%A_Space%"%sFile%",,Hide UseErrorLevel
	r:=(ErrorLevel="ERROR")?1:0
	FileDelete,%A_ScriptDir%\Data\*.tmp
	Return r?0:(FileExist(bAct?_CURR_DB:(sFile . ".crp"))?1:0)
}

Login_Cancel:
GuiClose:
GuiEscape:
ExitApp
Return

;;-------------- 密码库管理窗口--------

PWDManager_Win:
Gui,PWD_Man:New
Gui,PWD_Man:-MinimizeBox +Owner%Login_ID%
Gui,PWD_Man:Font,,Tahoma
Gui,PWD_Man:Font,,微软雅黑
Gui,PWD_Man:Add,Tab2,x0 y0 w0 h0 vpwdMan_Tab,Tab
Gui,PWD_Man:Add,ListBox,x5 y5 0x100 Multi w500 h280 Choose1 vpwdMan_List,% Trim(_STR_DBLIST,"|")
tempStr:=(_STR_DBLIST="|")?"Disabled":""
Gui,PWD_Man:Add,CheckBox,x10 y298 %tempStr% gpwdMan_DelFile vpwdMan_DelFile,同时删除文件（慎重！）
Gui,PWD_Man:Add,Button,x260 y290 w170 h30 %tempStr% gpwdMan_Del vpwdMan_Del,从列表中删除(&R)
Gui,PWD_Man:Add,Button,x435 y290 w70 h30 gpwdMan_Cancel,关闭(&X)
Gui,PWD_Man:Show,w510 h325,管理密码库
tempStr=
Return

pwdMan_DelFile:
GuiControlGet,tempStr,PWD_Man:,pwdMan_DelFile
GuiControl,PWD_Man:,pwdMan_Del,% tempStr?"完全删除密码库(&R)":"从列表中删除(&R)"
tempStr=
Return

pwdMan_Del:
GuiControlGet,getStr1,PWD_Man:,pwdMan_DelFile
Gui,PWD_Man:+OwnDialogs
Msgbox,262180,删除密码库,% "确定要删除选择的密码库？" . (getStr1?"`n注意：删除密码库文件将造成不可恢复的后果！":"")
IfMsgBox,No
	Return
Loop,% _COUNT_DB
	IniDelete,%_INI_PATH%,PWDMan,%A_Index%
_COUNT_DB:=0
GuiControlGet,tempStr,PWD_Man:,pwdMan_List
tempStr:=Trim(tempStr,"| `t")
If (tempStr="")
	GuiControl,PWD_Man:Disable,pwdMan_Tab
Loop,Parse,tempStr,|
{
	_STR_DBLIST:=StrReplace(_STR_DBLIST,"|" . A_LoopField . "|","|")
	If getStr1
		FileDelete,%A_LoopField%
}
GuiControl,PWD_Man:,pwdMan_List,|
GuiControl,PWD_Man:,pwdMan_List,% Trim(_STR_DBLIST)
Loop,Parse,_STR_DBLIST,|
{
	If (A_LoopField="")
		Continue
	_COUNT_DB+=1
	IniWrite,%A_LoopField%,%_INI_PATH%,PWDMan,%_COUNT_DB%
}
GuiControl,%Login_ID%:,Login_DB,|
GuiControl,%Login_ID%:,Login_DB,% Trim(_STR_DBLIST)
If (curr_PwdData="") Or !InStr(_STR_DBLIST,"|" . curr_PwdData . "|")
{
	GuiControl,%Login_ID%:Text,Login_DB,
	IniDelete,%_INI_PATH%,PWDMan,Last
}Else
	GuiControl,%Login_ID%:Text,Login_DB,%curr_PwdData%
tempStr:=getStr1:=curr_PwdData:=""
Return

pwdMan_Cancel:
PWD_ManGuiClose:
PWD_ManGuiEscape:
Gui,%Login_ID%:-Disabled
Gui,PWD_Man:Destroy
Return

;;-------------- 管理窗口--------

PwdMain_Win:
_STR_SEND:=_CURR_KEYTEXT:="",arr_Option:=[],Is_Sending:=_IS_OnFIND:=0,_CURR_CLSINDEX:=1,str_clsAll:="全部"
IniRead,_STR_OPTION,%_INI_PATH%,PWDMan,Option,11001
If !RegexMatch(_STR_OPTION,"^[01]{5}$")
	_STR_OPTION:="11001"
arr_Option:=StrSplit(_STR_OPTION)
Gui,Main_Win:+Resize +MinSize +HwndMainWin_ID
Gui,Main_Win:Font,,Tahoma
Gui,Main_Win:Font,,微软雅黑
Gui,Main_Win:Add,Picture,x10 y12 w16 h-1 Icon-42 vpwd_P1,shell32.dll
Gui,Main_Win:Add,Text,x33 y13 vpwd_T1,分类(&C):
Gui,Main_Win:Add,DropDownList,x85 y10 w150 Choose1 AltSubmit gpwd_Do vpwd_Class,%str_clsAll%
Gui,Main_Win:Add,Button,x240 y10 w80 h25 gpwd_Do vpwd_ClsMan,分类管理(&T)
Gui,Main_Win:Add,Button,x330 y10 w65 h25 gpwd_Do vpwd_Options,菜单(&M)
Gui,Main_Win:Add,Text,x440 y13 vpwd_T3,查找(&F)
Gui,Main_Win:Add,Edit,x485 y10 w200 vpwd_FindBox,
Gui,Main_Win:Add,Button,x690 y10 w30 h25 gpwd_Do vpwd_BtnFind,→
Gui,Main_Win:Add,Button,x723 y10 w30 h25 gpwd_Do vpwd_BtnFindCancel,╳
Gui,Main_Win:Add,CheckBox,x765 y15 Disabled vpwd_Limit,仅搜索当前分类(&L)

Gui,Main_Win:Add,ListView,x5 y45 Grid gpwd_Do vpwd_List,标题|用户名|密码|分组|备注
Gui,Main_Win:Add,Button,x5 y10 w70 Hidden gpwd_UnLockBtn vpwd_UnLockBtn,解锁(&U)
Gui,Main_Win:Font,s12,
Gui,Main_Win:Add,Edit,x5 y10 w230 Hidden Password vpwd_UnLockEdit,
Gui,Main_Win:Show,w950 h650,%_CURR_DBMASK% - Easysky 密码管理器

Menu,Menu_Cls,Add,重命名(&R),cmd_Cls
Menu,Menu_Cls,Add,删除(&D),cmd_Cls
Menu,Menu_Cls,Add,添加(&A),cmd_Cls
b_SwitchMenu(0)

Menu,Menu_Pop,Add,编辑选择项目(&E)`tF2`, Enter,cmd_Pop
Menu,Menu_Pop,Add,
Menu,Menu_Pop,Add,发送 用户名(&U)`tF5,cmd_Pop
Menu,Menu_Pop,Add,发送 密码(&S)`tF6,cmd_Pop
Menu,Menu_Pop,Add,发送 备注(&I)`tF7,cmd_Pop
Menu,Menu_Pop,Add,发送 用户名+密码(&F)`tF10,cmd_Pop
Menu,Menu_Pop,Add,
Menu,Menu_Pop,Add,打开网址或路径(&P)`tF12,cmd_Pop
Menu,Menu_Pop,Add,
Menu,Menu_Pop,Add,全选(&A)`tCtrl+A,cmd_Pop
Menu,Menu_Pop,Add,删除选择项目(&D)`tDel,cmd_Pop
Menu,Menu_Pop,Add,清空列表(&B)`tShift+Del,cmd_Pop
Menu,Menu_Pop,Add,
Menu,Menu_Pop,Add,添加新项目(&G)`tInsert`, Ctrl+N,cmd_Pop
Menu,Menu_Pop,Default,1&

Menu,Menu_Options,Add,修改密码(&P)...,cmd_Options
Menu,Menu_Options,Add,锁定程序(&L)%A_Tab%Ctrl+Alt+Shift+L,cmd_Options
Menu,Menu_Options,Add,
Menu,Menu_Options,Add,[F4]%A_Space%键显示密码明文(&F),cmd_Options
Menu,Menu_Options,Add,中键点击显示密码明文(&M),cmd_Options
Menu,Menu_Options,Add,显示全部密码明文(&A),cmd_Options
Menu,Menu_Options,Add,
Menu,Menu_Options,Add,[查找]%A_Space%区分大小写(&S),cmd_Options
Menu,Menu_Options,Add,[查找]%A_Space%内容包含密码(&C),cmd_Options
Menu,Menu_Options,Add,
Menu,Menu_Options,Add,窗口最小化时锁定(&K),cmd_Options
Menu,Menu_Options,Add,
Menu,Menu_Options,Add,数据导出(&X)%A_Space%...`tCtrl+E,cmd_Options
Menu,Menu_Options,Add,数据导入(&I)%A_Space%...`tCtrl+I,cmd_Options
Menu,Menu_Options,Add,
Menu,Menu_Options,Add,程序信息(&I),cmd_Options
Menu,Menu_Options,Add,退出(&X),cmd_Options

Menu,Menu_Options,% arr_Option[1]?"Check":"UnCheck",4&
Menu,Menu_Options,% arr_Option[2]?"Check":"UnCheck",5&
Menu,Menu_Options,% arr_Option[3]?"Check":"UnCheck",8&
Menu,Menu_Options,% arr_Option[4]?"Check":"UnCheck",9&
Menu,Menu_Options,% arr_Option[5]?"Check":"UnCheck",11&

Is_PassShowed:=Is_Locked:=0
If !Is_DBFromNew
{
	Gosub _Get_Data
	fp:=_LockFile()
}Else
	Is_DBFromNew:=0
SplashImage,Off
Return

Main_WinGuiSize:
If (A_EventInfo=1){
	If arr_Option[5] And !Is_Locked And !Is_Sending
		pwd_Lock(1)
}Else{
	GuiControl,Main_Win:Move,pwd_List,% "w" A_GuiWidth-10 "h" A_GuiHeight-55
	Lv_ModifyCol(1,180),Lv_ModifyCol(2,180),Lv_ModifyCol(3,140),Lv_ModifyCol(4,100),Lv_ModifyCol(5,A_GuiWidth-640)
	If Is_Locked
	{
		GuiControl,Main_Win:MoveDraw,pwd_UnlockEdit,% "x" (A_GuiWidth-300)/2 "y" (A_GuiHeight-80)/2-20
		GuiControl,Main_Win:MoveDraw,pwd_UnlockBtn,% "x" (A_GuiWidth-300)/2+235 "y" (A_GuiHeight-80)/2-20
		GuiControl,Main_Win:Focus,pwd_UnlockEdit
	}
}
Return

Main_WinGuiContextMenu:
If (A_GuiControl="pwd_List"){
	_CURR_ROW:=A_EventInfo
	If (_CURR_ROW>0)
		Lv_GetText(_CURR_ITEM,_CURR_ROW)
	Menu,Menu_Pop,% (Lv_GetCount("S")=0)?"Disable":"Enable",1&
	Menu,Menu_Pop,% (Lv_GetCount("S")=0)?"Disable":"Enable",3&
	Menu,Menu_Pop,% (Lv_GetCount("S")=0)?"Disable":"Enable",4&
	Menu,Menu_Pop,% (Lv_GetCount("S")=0)?"Disable":"Enable",5&
	Menu,Menu_Pop,% (Lv_GetCount("S")=0)?"Disable":"Enable",6&
	Menu,Menu_Pop,% ((Lv_GetCount("S")>0) And (RegexMatch(arr_Pass[_CURR_ITEM][4],"i)(http|[a-z]:\\)([^↘→]+)[↘→]?")))?"Enable":"Disable",8&
	Menu,Menu_Pop,% (Lv_GetCount()=0)?"Disable":"Enable",10&
	Menu,Menu_Pop,% (Lv_GetCount("S")=0)?"Disable":"Enable",11&
	Menu,Menu_Pop,% (Lv_GetCount()=0)?"Disable":"Enable",12&
	Menu,Menu_Pop,Show
}
Return

pwd_Do:
If (A_GuiControl="pwd_Class"){
	GuiControlGet,tempStr,Main_Win:,pwd_Class
	GuiControl,% (tempStr=1)?"Main_Win:Disable":"Main_Win:Enable",pwd_Limit
	If (tempStr!=_CURR_CLSINDEX){
		b_SwitchMenu(!(tempStr=1)),_func_PutData(tempStr-1),Lv_ModifyCol(1,"","标题" . A_Space . "[" . _COUNT_PASS . "]")
		,_CURR_CLSINDEX:=tempStr
	}
	tempStr=
}Else If (A_GuiControl="pwd_ClsMan")
	Menu,Menu_Cls,Show
Else If (A_GuiControl="pwd_List"){
	If A_GuiEvent In DoubleClick
	{
		_CURR_ROW:=A_EventInfo
		If (_CURR_ROW>0){
			Is_Edit:=1,Lv_GetText(_CURR_ITEM,_CURR_ROW)
			Gosub PwdEdit_Win
		}
	}
}Else If (A_GuiControl="pwd_BtnFind")
	Gosub sub_GoFind
Else If (A_GuiControl="pwd_Options")
	Menu,Menu_Options,Show
Else If (A_GuiControl="pwd_BtnFindCancel")
	Gosub sub_ExitFind
Return

cmd_Cls:
If (A_ThisMenuItemPos=1){
	Gui,Main_Win:+OwnDialogs
	InputBox,tempStr,分类重命名,,,250,100, , ,,,% arr_Class[_CURR_CLSINDEX-1]
	tempStr=%tempStr%
	If ErrorLevel Or (tempStr="") Or (tempStr=arr_Class[_CURR_CLSINDEX-1])
		Return
	If (tempStr="")
		MsgBox,262192,分类重命名错误,分类名不可为空，当前操作取消！,8
	Else If (tempStr=str_clsAll) Or InStr("|" _STR_CLASSES "|","|" tempStr "|")
		MsgBox,262192,分类重命名错误,新分类名已存在！,8
	Else{
		_STR_CLASSES:=Trim(StrReplace("|" _STR_CLASSES "|","|" arr_Class[_CURR_CLSINDEX-1] "|","|" tempStr "|"),"|")
		,arr_Class[_CURR_CLSINDEX-1]:=tempStr
		GuiControl,Main_Win:,pwd_Class,% "|" str_clsAll "|" _STR_CLASSES
		GuiControl,Main_Win:ChooseString,pwd_Class,%tempStr%
	}
	tempStr=
}Else If (A_ThisMenuItemPos=2){
	Gui,Main_Win:+OwnDialogs
	MsgBox,262196,删除分类,% "确定要删除分类“" arr_Class[_CURR_CLSINDEX-1] "”？`n注意：该分类下的项目将一并删除且不可恢复！"
	IfMsgBox,No
		Return
	_CURR_CLSINDEX-=1,_STR_CLASSES:=Trim(StrReplace("|" _STR_CLASSES "|","|" arr_Class[_CURR_CLSINDEX] "|","|"),"|"),arr_Class.RemoveAt(_CURR_CLSINDEX)
	GuiControl,Main_Win:,pwd_Class,% "|" str_clsAll . "|" _STR_CLASSES
	GuiControl,Main_Win:Choose,pwd_Class,1
	b_SwitchMenu(0),_CURR_CLSINDEX:=1
	GuiControl,Main_Win:Focus,pwd_List
}Else{
	Gui,Main_Win:+OwnDialogs
	InputBox,tempStr,添加分类,,,250,100,,,,,新建分类
	tempStr=%tempStr%
	If (ErrorLevel) Or (tempStr="")
		Return
	If InStr("|" _STR_CLASSES "|","|" tempStr "|")
		MsgBox,262192,添加分类,分类名已存在！,8
	Else{
		Gui,Main_Win:Default
		_STR_CLASSES .= "|" . tempStr,arr_Class.push(tempStr),_CURR_CLSINDEX:=arr_Class.length()+1,Lv_Delete(),Lv_ModifyCol(1,"","标题" . A_Space . "[0]")
		GuiControl,Main_Win:,pwd_Class,% "|" str_clsAll "|" _STR_CLASSES
		GuiControl,Main_Win:ChooseString,pwd_Class,%tempStr%
		b_SwitchMenu(1)
	}
	tempStr=
}
fp.Close()
IniWrite,%_STR_CLASSES%,%_CURR_DB%,PWDMan,PWD_GROUPs
If (A_ThisMenuItemPos=2){
	For s1,s2 In arr_Pass
	{
		If (s2[3]=_CURR_CLSINDEX){
			arr_Pass.Delete(s1),_COUNT_PASS-=1
			IniDelete,%_CURR_DB%,PWDMan,%s1%
		}
	}
	_func_PutData(),Lv_ModifyCol(1,"","标题" . A_Space . "[" . _COUNT_PASS . "]")
}
fp:=_LockFile()
Return

cmd_Pop:
If (A_ThisMenuItemPos=1){
	Lv_GetText(_CURR_ITEM,_CURR_ROW)
	Is_Edit:=1
	Gosub PwdEdit_Win
}Else If A_ThisMenuItemPos In 3,4,5,6
	_CopyInfo(A_ThisMenuItemPos-2)
Else If (A_ThisMenuItemPos=8)	;打开位置
	Gosub Pass_GoWeb
Else If (A_ThisMenuItemPos=10)	;全选
	SendInput {Home}+{End}
Else If (A_ThisMenuItemPos=11)	;删除
	Gosub Pass_Del
Else If (A_ThisMenuItemPos=12)	;清空
	Gosub Pass_Clear
Else If (A_ThisMenuItemPos=14){	;添加
	Is_Edit:=0,_CURR_ITEM:=""
	Gosub PwdEdit_Win
}
Return

cmd_Options:
If (A_ThisMenuItemPos=1)
	Gosub LoginPassEdit_Win
Else If (A_ThisMenuItemPos=2){
	pwd_Lock(1)
	GuiControl,Main_Win:Focus,pwd_UnlockEdit
}Else If (A_ThisMenuItemPos=4)
	arr_Option[1]:=1-arr_Option[1],tempStr:=arr_Option[1]
Else If (A_ThisMenuItemPos=5)
	arr_Option[2]:=1-arr_Option[2],tempStr:=arr_Option[2]
Else If (A_ThisMenuItemPos=6){
	Is_PassShowed:=1-Is_PassShowed
	Gui,Main_Win:Default
	Loop,% Lv_GetCount()
	{
		If Is_PassShowed
			Lv_GetText(tempStr,A_Index),Lv_Modify(A_Index,"COL3",arr_Pass[tempStr][2])
		Else
			Lv_GetText(tempStr,A_Index,3),Lv_Modify(A_Index,"COL3",_str_Dot)
	}
	GuiControl,Main_Win:Focus,pwd_List
	tempStr:=Is_PassShowed
}Else If (A_ThisMenuItemPos=8)
	arr_Option[3]:=1-arr_Option[3],tempStr:=arr_Option[3]
Else If (A_ThisMenuItemPos=9)
	arr_Option[4]:=1-arr_Option[4],tempStr:=arr_Option[4]
Else If (A_ThisMenuItemPos=11)
	arr_Option[5]:=1-arr_Option[5],tempStr:=arr_Option[5]
Else If (A_ThisMenuItemPos=13)	;导出
	Gosub pwd_Export
Else If (A_ThisMenuItemPos=14)	;导入
	Gosub pwd_Import
Else If (A_ThisMenuItemPos=16){
	Gui,Main_Win:+OwnDialogs
	MsgBox,262208,程序信息,
(
PWDMan - Easysky 密码管理器
版本: v0.0.7 (2020.11.27)
`n一款简洁实用的密码管理器软件。
» 支持多密码库，密码库采用强加密。
» 支持数据分组及组别编辑
» 支持搜索
» F4 键及鼠标中键可临时查看密码
» 可一键打开项目网址或文件路径
» 20秒内 [Ctrl] 键填充数据
» 支持导出（.JSON 或.CSV 文件）与导入（仅 .CSV 文件）
`nEasysky Studio,2013-%A_yyyy%
[Email]%A_Tab%easysky@foxmail.com
[QQ]%A_Tab%3121356095#easysky
[主页]%A_Tab%https://easysky.top
`n我的追求 —— 新颖、便携、简洁、高效、人性化体验！
)
}Else If (A_ThisMenuItemPos=17)
	ExitApp
If A_ThisMenuItemPos In 4,5,6,8,9,11
{
	Menu,Menu_Options,ToggleCheck,%A_ThisMenuItem%
	tempStr=
}
Return

pwd_Export:
Gui,Main_Win:Default
If (_COUNT_PASS=0){
	Gui,Main_Win:+OwnDialogs
	MsgBox,262192,导出失败！,当前无数据！
	Return
}
Gosub pwdExport_Win
Return

pwd_Import:
Gui,Main_Win:+OwnDialogs
Is_OverWrite:=0
If (_COUNT_PASS>0){
	MsgBox,262179,从 CSV 文件中导入数据,当前列表中已有数据，如发现重复项数据是否覆盖？`n点击“是”覆盖，点击“否”自动重命名，点击“取消”结束操作。
	IfMsgBox,Yes
		Is_OverWrite:=1
	IfMsgBox,Cancel
		Return
}
FileSelectFile,tPath,3,,选择要导入的 CSV 文件,CSV 文件 (*.csv)
If ErrorLevel Or (tPath="") Or !FileExist(tPath) Or (SubStr(tPath,-3)!=".csv")
	Return
;当前列表状态恢复至全部显示
Gosub sub_ExitFind
b_SwitchMenu(0),_CURR_CLSINDEX:=1,_func_PutData(),tempStr:=_COUNT_PASS+1,fp.Close()
;开始导入数据
Gui,Main_Win:Default
FileEncoding,UTF-8-RAW
GuiControl,Main_Win:-ReDraw,pwd_List
Loop,Read,%tPath%
{
	getStr1:=getStr2:=getStr3:=getStr4:=getStr5:=""
	Loop,Parse,A_LoopReadLine,CSV
		getStr%A_Index%:=A_LoopField
	If arr_Pass.haskey(getStr1)
	{
		If !Is_OverWrite
			getStr1.="_" . A_Now
	}
	arr_Pass[getStr1]:=[getStr2,getStr3,getStr4,getStr5],_COUNT_PASS+=1
	,Lv_Add("Select",getStr1,getStr2,((getStr3="")?"":(Is_PassShowed?getStr3:_str_Dot)),arr_Class[getStr4],getStr5)
	If !arr_Class.haskey(getStr4)
		arr_Class.push(getStr4),_STR_CLASSES .= "|" . getStr4
	IniWrite,% _COMMA(getStr2) "`," _COMMA(getStr3) "`," getStr4 "," _COMMA(getStr5),%_CURR_DB%,PWDMan,%getStr1%
}
FileEncoding,%_LAST_ENCODING%
Lv_ModifyCol(1,"","标题" . A_Space . "[" . _COUNT_PASS . "]"),Lv_Modify(tempStr,"Vis"),fp:=_LockFile()
GuiControl,Main_Win:+ReDraw,pwd_List
GuiControl,Main_Win:,pwd_Class,% "|" str_clsAll . "|" _STR_CLASSES
GuiControl,Main_Win:Choose,pwd_Class,1
IniWrite,%_STR_CLASSES%,%_CURR_DB%,PWDMan,PWD_GROUPs
tempStr:=getStr1:=getStr2:=getStr3:=getStr4:=getStr5:=tPath:=""
Return

_Get_Data:
Gui,Main_Win:Default
arr_Pass:=arr_Class:=[],_COUNT_PASS:=0
IniRead,_STR_CLASSES,%_CURR_DB%,PWDMan,PWD_GROUPs,%A_Space%
_STR_CLASSES:=Trim(_STR_CLASSES,"`t |")
If (_STR_CLASSES!=""){
	GuiControl,Main_Win:,pwd_Class,% Trim(_STR_CLASSES)
	arr_Class:=StrSplit(_STR_CLASSES,"|")
}
FileEncoding,CP936
Loop,Read,%_CURR_DB%
{
	If A_LoopReadLine Contains [PWDMan],PWD_GROUPs=
		Continue
	tempStr:=StrReplace(A_LoopReadLine,"=","`,",,1),getStr1:=getStr2:=getStr3:=getStr4:=getStr5:=""
	Loop,Parse,tempStr,CSV
		getStr%A_Index%:=Trim(A_LoopField,"`t """)
	arr_Pass[getStr1]:=[getStr2,getStr3,getStr4,getStr5],_COUNT_PASS+=1
	;arr_Pass["博客园"]=["easysky","123456789",0,"网址：http://easysky.cnblogs.com"]
}
FileEncoding,%_LAST_ENCODING%
_func_PutData()
Lv_ModifyCol(1,"","标题" . A_Space . "[" . _COUNT_PASS . "]")
GuiControl,Main_Win:Focus,pwd_List
getStr1:=getStr2:=getStr3:=getStr0:=tempStr:=""
Return

_func_PutData(b:=0){
	Global Is_PassShowed,arr_Class
	Gui,Main_Win:Default
	Lv_Delete()
	GuiControl,Main_Win:-ReDraw +Sort,pwd_List
	For s1,s2 In arr_Pass
	{
		If (b!=0) And (s2[3]!=b)
			Continue
		;Lv_Add("",s1,s2[1],(s2[2]="")?"":(Is_PassShowed?s2[2]:_str_Dot),arr_Class[s2[3]],s2[4])
		Lv_Add("",s1,s2[1],(s2[2]="")?"":(Is_PassShowed?s2[2]:_str_Dot),arr_Class[s2[3]],StrReplace(StrReplace(s2[4],"``t",A_Space),"``n",A_Space))
	}
	GuiControl,Main_Win:+ReDraw -Sort,pwd_List
}

Pass_Del:
Gui,Main_Win:Default
If (Lv_GetCount("S")=0)
	Return
Gui,Main_Win:+OwnDialogs
MsgBox,262196,删除数据,确定要删除选择的数据项？注意：该操作无法恢复！
IfMsgBox,No
	Return
fp.Close(),tempStr:=0
Loop
{
	tempStr:=LV_GetNext(tempStr-1)
	If Not tempStr
		Break
	Lv_GetText(getStr1,tempStr,1),Lv_Delete(tempStr),arr_Pass.Delete(getStr1),_STR_MARK:=StrReplace(_STR_MARK,getStr1 . "ª")
	IniDelete,%_CURR_DB%,%_CURR_CLSINDEX%,%getStr1%
}
Lv_ModifyCol(1,"","标题" . A_Space . "[" . Lv_GetCount() . "]"),fp:=_LockFile(),tempStr:=getStr1:=""
Return

Pass_Clear:
Gui,Main_Win:Default
If (Lv_GetCount()=0)
	Return
Gui,Main_Win:+OwnDialogs
MsgBox,262196,清空数据,确定要清空列表中的所有数据？注意：该操作无法恢复！
IfMsgBox,No
	Return
Lv_Delete(),arr_Pass:=[],_STR_MARK:="",Lv_ModifyCol(1,"","标题" . A_Space . "[0]")
fp.Close()
IniDelete,%_CURR_DB%,%_CURR_CLSINDEX%
FileAppend,`n[%_CURR_CLSINDEX%],%_CURR_DB%
fp:=_LockFile()
Return

Pass_GoWeb:
If RegexMatch(arr_Pass[_CURR_ITEM][4],"i)(http|[a-z]:\\)([^``\s]+)[``\s]*.*",getStr)
{
	tempStr:=getStr1 . getStr2
	If (tempStr!=""){
		try
			Run,%tempStr%,,UseErrorLevel
		Catch{
			Gui,Main_Win:+OwnDialogs
			MsgBox,262192,运行失败,运行“%tempStr%”失败！请检查文件是否不存在或已被删除。
		}
	}
}
tempStr:=getStr1:=getStr2:=getStr:=""
Return

pwd_UnLockBtn:
GuiControlGet,tempStr,Main_Win:,pwd_UnlockEdit
If (tempStr=""){
	GuiControl,Main_Win:Focus,pwd_UnlockEdit
	Return
}
If (tempStr==_STR_PASS){
	pwd_Lock(0)
	GuiControl,Main_Win:,pwd_UnlockEdit,
}Else{
	Gui,Main_Win:+OwnDialogs
	MsgBox,262192,密码错误,错误的登入密码，请重试！
	GuiControl,Main_Win:Focus,pwd_UnlockEdit
	SendInput ^a
}
tempStr:=getStr1:=""
Return

pwd_SaveData:
tempStr:=arr_Option[1] . arr_Option[2] . arr_Option[3] . arr_Option[4] . arr_Option[5]
If (tempStr!=_STR_OPTION)
	IniWrite,%tempStr%,%_INI_PATH%,PWDMan,Option
_STR_OPTION:=tempStr
fp.Close()
FileGetTime,tempStr,%_CURR_DB%
If (tempStr!=tmr_DB){	;需要更新密码库
	If _crypto(0,_CURR_DB)
		FileMove,%_CURR_DB%.crp,%_CURR_DBMASK%,1
	tmr_DB:=tempStr
}
FileDelete,%_CURR_DB%
tempStr=
Return

sub_GoFind:
_CURR_KEYTEXT=
GuiControlGet,_CURR_KEYTEXT,Main_Win:,pwd_FindBox
If (_CURR_KEYTEXT=""){
	Gosub sub_ExitFind
	Return
}
GuiControl,Main_Win:Disable,pwd_Class
GuiControl,Main_Win:Disable,pwd_ClsMan
Gui,Main_Win:Default
Lv_Delete(),nCount:=mCount:=nFlag:=0,_IS_OnFIND:=1
GuiControl,Main_Win:-ReDraw +Sort,pwd_List
For s1,s2 In arr_Pass
{
	If (_CURR_CLSINDEX>1){
		GuiControlGet,nFlag,Main_Win:,pwd_Limit
		If nFlag And (s2[3]!=_CURR_CLSINDEX-1)
			Continue
	}
	mCount+=1,tempStr:=s1 "|" s2[1] (arr_Option[4]?("|" s2[2]):"") "|" s2[4]
	If InStr(tempStr,_CURR_KEYTEXT,arr_Option[3])
		Lv_Add("",s1,s2[1],(s2[2]="")?"":(Is_PassShowed?s2[2]:_str_Dot),arr_Class[s2[3]],s2[4]),nCount+=1
}
Lv_ModifyCol(1,"","标题" . A_Space . "[" . nCount . "]")
GuiControl,Main_Win:+ReDraw -Sort,pwd_List
If (nCount=0)
{
	Gui,Main_Win:+OwnDialogs
	MsgBox,262192,查找,% (nFlag?("在分类「" arr_Class[_CURR_CLSINDEX-1] "」中"):"") . "未找到与关键词“" _CURR_KEYTEXT "”相匹配的项！"
}
nCount:=mCount:=nFlag:=tempStr:=""
Return

sub_ExitFind:
GuiControl,Main_Win:Enable,pwd_Class
GuiControl,Main_Win:Enable,pwd_ClsMan
Gui,Main_Win:Default
_func_PutData(_CURR_CLSINDEX-1),Lv_ModifyCol(1,"","标题" . A_Space . "[" . _COUNT_PASS . "]"),_IS_OnFIND:=0
Return

pwd_Count:
_COUNT_SEC-=1
If (_COUNT_SEC=0) Or (_STR_SEND="")
{
	ToolTip,,,,14
	SetTimer,pwd_Count,Off
	_COUNT_SEC:=20,Is_Sending:=0,_STR_SEND:=""
}Else
	ToolTip,「Ctrl」填充%A_Tab%「Esc」取消%A_Tab%-%_COUNT_SEC% s,A_ScreenWidth/2-150,0,14
Return

_GetInfo(s){
	If (s=0)
		Return 0
	Gui,Main_Win:Default
	Lv_GetText(_CURR_ITEM,s,1)
	Return 1
}

_CopyInfo(i){
	;i=1：用户名； 2：密码； 3：备注； 4：组合
	Global _COUNT_SEC,Is_Sending,_STR_SEND
	_COUNT_SEC:=20,Is_Sending:=1
	If i In 1,2
		_STR_SEND:=arr_Pass[_CURR_ITEM][i]
	Else If (i=3)
		_STR_SEND:=StrReplace(StrReplace(arr_Pass[_CURR_ITEM][4],"``t","`t") ,"``n","`n") 
	Else
		_STR_SEND:=arr_Pass[_CURR_ITEM][1] A_Tab arr_Pass[_CURR_ITEM][2]
	ToolTip,「Ctrl」填充%A_Tab%「Esc」取消%A_Tab%-%_COUNT_SEC% s,A_ScreenWidth/2-150,0,14
	Gui,Main_Win:Show,Minimize
	SetTimer,pwd_Count,1000
}

b_SwitchMenu(b){
	Menu,Menu_Cls,% b?"Enable":"Disable",1&
	Menu,Menu_Cls,% b?"Enable":"Disable",2&
}

pwd_Lock(i){
	Global Is_Locked,fp
	Is_Locked:=i
	GuiControl,Main_Win:Hide%i%,pwd_P1
	GuiControl,Main_Win:Hide%i%,pwd_T1
	GuiControl,Main_Win:Hide%i%,pwd_Class
	GuiControl,Main_Win:Hide%i%,pwd_ClsMan
	GuiControl,Main_Win:Hide%i%,pwd_T2
	GuiControl,Main_Win:Hide%i%,pwd_Options
	GuiControl,Main_Win:Hide%i%,pwd_T3
	GuiControl,Main_Win:Hide%i%,pwd_FindBox
	GuiControl,Main_Win:Hide%i%,pwd_BtnFind
	GuiControl,Main_Win:Hide%i%,pwd_BtnFindCancel
	GuiControl,Main_Win:Hide%i%,pwd_Limit
	GuiControl,Main_Win:Hide%i%,pwd_List
	GuiControl,Main_Win:Show%i%,pwd_UnlockText
	GuiControl,Main_Win:Show%i%,pwd_UnlockEdit
	GuiControl,% i?"Main_Win:+Default":"Main_Win:-Default",pwd_UnLockBtn
	GuiControl,Main_Win:Show%i%,pwd_UnlockBtn
	If i
	{	;锁定
		GuiControlGet,tempStr,Main_Win:Pos,pwd_List
		tempStrX:=tempStrX+(tempStrW-300)/2,tempStrY:=(tempStrH-80)/2+tempStrY-20
		GuiControl,Main_Win:Move,pwd_UnlockEdit,% "x" tempStrX "y" tempStrY
		GuiControl,Main_Win:Move,pwd_UnlockBtn,% "x" tempStrX+235 "y" tempStrY
		GuiControl,Main_Win:Focus,pwd_UnlockEdit
		tempStr:=tempStrX:=tempStrY:=tempStrW:=tempStrH:=""
		Gosub pwd_SaveData
	}Else{	;解锁
		If _crypto(1,_CURR_DBMASK)
		{
			fp:=_LockFile()
			GuiControl,Main_Win:Focus,pwd_List
		}
	}
}

Is_KeyFocused(){
	GuiControlGet,tempStr,Main_Win:FocusV
	Return (tempStr="pwd_List")?1:((tempStr="pwd_FindBox")?2:0)
}

#if (WinActive("ahk_id " . MainWin_ID))
^a::SendInput {Home}+{End}
#w::Gosub Pass_GoWeb
Del::Gosub Pass_Del
+Del::Gosub Pass_Clear
^e::Gosub pwd_Export
^!+F5::Reload
^!+l::pwd_Lock(1)
^i::Gosub pwd_Import
F5::
F6::
F7::
F8::
Gui,Main_Win:Default
If _GetInfo(LV_GetNext(0,"F"))
	_CopyInfo(SubStr(A_ThisLabel,0)-4)
Return
F10::
Gui,Main_Win:Default
tempStr:=LV_GetNext(0)
If (tempStr=0)
	Return
If _GetInfo(tempStr)
	_CopyInfo(4)
tempStr=
Return
F11::
WinGet,tempStr,MinMax,Ahk_Id %MainWin_ID%
If (tempStr=0)
	Gui,Main_Win:Maximize
If (tempStr=1)
	Gui,Main_Win:Restore
tempStr=
Return
F12::
Gui,Main_Win:Default
tempStr:=LV_GetNext(0)
If (tempStr=0)
	Return
If _GetInfo(tempStr)
	Gosub Pass_GoWeb
tempStr=
Return

Insert::
^n::
Is_Edit:=0
Gosub PwdEdit_Win
Return

F3::
^f::
GuiControl,Main_Win:Focus,pwd_FindBox
SendInput ^a
Return

Mbutton::
MouseGetPos,mX,mY
ControlGetPos,dX,dY,,,SysListView321,ahk_id %MainWin_ID%
If (mY<dY){
	mY:=dY:=dX:=mX:=getStr1:=getStr2:=getStr3:=getStr4:=""
	Return
}
SendInput {Click}
Gui,Main_Win:Default
tempStr:=Lv_GetNext(0)
If (tempStr=0){
	tempStr=
	Return
}
Loop % LV_GetCount("Column")
{
	SendMessage,4125,A_Index-1,0,SysListView321,ahk_id %MainWin_ID%
	getStr%A_Index%:=ErrorLevel
}
If (mX>dX) And (mX<dX+getStr1)	;第1列 标题
	Lv_GetText(tempStr,tempStr,1)
If (mX>dX+getStr1) And (mX<dX+getStr1+getStr2)	;第2列 用户名
	Lv_GetText(tempStr,tempStr,2),tempStr:=((tempStr="")?"<空>":tempStr)
If (mX>dX+getStr1+getStr2) And (mX<dX+getStr1+getStr2+getStr3)	;第3列 密码
{
	Lv_GetText(getStr1,tempStr,3)
	If (getStr1="")
		tempStr:="<空>"
	Else{
		If Is_PassShowed Or arr_Option[2]
			Lv_GetText(getStr1,tempStr,1),tempStr:=arr_Pass[getStr1][2]
		Else
			tempStr:="<已隐藏>"
	}
}
If (mX>dX+getStr1+getStr2+getStr3) And (mX<dX+getStr1+getStr2+getStr3+getStr4)	;第4列 信息
	Lv_GetText(tempStr,tempStr,4)
If (mX>dX+getStr1+getStr2+getStr3+getStr4) And (mX<dX+getStr1+getStr2+getStr3+getStr4+getStr5)	;第5列 信息
{
	Lv_GetText(tempStr,tempStr,5)
	If (tempStr!="")
		tempStr:=StrReplace(StrReplace(tempStr,"``t","`t"),"``n","`n")
	Else
		tempStr:="<空>"
}
ToolTip,%tempStr%,,,13
KeyWait,Mbutton
ToolTip,,,,13
getStr1:=getStr2:=getStr3:=getStr4:=tempStr:=mX:=dX:=mY:=dY:=""
Return
#if

#if WinActive("ahk_id " . MainWin_ID) And _IS_OnFIND
Esc::Gosub sub_ExitFind
#if

#if WinActive("ahk_id " . MainWin_ID) And arr_Option[1]
F4::
Gui,Main_Win:Default
tempStr:=LV_GetNext(tempStr,"F")
If (tempStr=0)
	Return
Lv_GetText(getStr1,tempStr),Lv_Modify(tempStr,"COL3",arr_Pass[getStr1][2])
KeyWait,F4
Lv_Modify(tempStr,"COL3",_str_Dot)
getStr1:=tempStr:=""
Return
#If

#if (Is_KeyFocused()=1)
F2::
Enter::
NumPadEnter::
Gui,Main_Win:Default
tempStr:= LV_GetNext(0,"F")
If (tempStr=0)
	Return
_CURR_ROW:=tempStr,tempStr:=""
If _GetInfo(_CURR_ROW)
{
	Is_Edit:=1
	Gosub PwdEdit_Win
}
Return
#if

#if (Is_KeyFocused()=2)
Enter::
NumPadEnter::
Gosub sub_GoFind
Return
#if

#if (_STR_SEND!="")
Ctrl::
SendInput %_STR_SEND%
ToolTip,,,,14
SetTimer,pwd_Count,Off
_COUNT_SEC:=20,Is_Sending:=0,_STR_SEND:=""
Return
Esc::
Is_Sending:=0,_STR_SEND:=""
Return
#if

Main_WinGuiClose:
Gosub pwd_SaveData
Gui,Main_Win:Destroy
Menu,Menu_Pop,Delete
Menu,Menu_Options,Delete
arr_Option:=[]
Gui,%Login_ID%:Show
Return

;;;-------------------- 密码修改 ----------------

LoginPassEdit_Win:
Gui,pwd_PassEdit:New
Gui,pwd_PassEdit:-MinimizeBox +Owner%MainWin_ID%
Gui,pwd_PassEdit:Font,,Tahoma
Gui,pwd_PassEdit:Font,,微软雅黑
Gui,pwd_PassEdit:Add,Text,x10 y18,原密码(&O)
Gui,pwd_PassEdit:Add,Edit,x85 y15 w180 Password vpwdPassEdit_Pass1,
Gui,pwd_PassEdit:Add,Text,x10 y50,新密码(&N)
Gui,pwd_PassEdit:Add,Edit,x85 y45 w180 Password vpwdPassEdit_Pass2,
Gui,pwd_PassEdit:Add,Text,x10 y80,重复密码(&R)
Gui,pwd_PassEdit:Add,Edit,x85 y75 w180 Password vpwdPassEdit_Pass3,
Gui,pwd_PassEdit:Add,Button,x100 y115 w80 h25 Default gpwdPassEdit_OK,确定(&S)
Gui,pwd_PassEdit:Add,Button,x185 y115 w80 h25 gpwdPassEdit_Cancel,取消(&X)
Gui,pwd_PassEdit:Show,,修改密码
Gui,Main_Win:+Disabled
Return

pwdPassEdit_OK:
errFlag:=0
GuiControlGet,getStr1,pwd_PassEdit:,pwdPassEdit_Pass1
If (getStr1="")
	errFlag:=1
If (errFlag=0){
	If !(getStr1==_STR_PASS)
		errFlag:=2
}
If (errFlag=0){
	GuiControlGet,getStr2,pwd_PassEdit:,pwdPassEdit_Pass2
	If (getStr2="")
		errFlag:=3
}
If (errFlag=0){
	GuiControlGet,getStr3,pwd_PassEdit:,pwdPassEdit_Pass3
	If (getStr3="")
		errFlag:=4
}
If (errFlag=0){
	If !(getStr3==getStr2)
		errFlag:=5
}
Gui,pwd_PassEdit:+OwnDialogs
If !errFlag
{
	_STR_PASS:=getStr3,tmr_DB:=0
	MsgBox,262208,操作完成,已成功修改登入/管理密码。
	Gosub pwd_PassEditGuiClose
}Else{
	If (errFlag=1)
		errFlag:="请输入原密码！",tempStr:="pwdPassEdit_Pass1"
	Else If (errFlag=2)
		errFlag:="原密码输入错误，请重试！",tempStr:="pwdPassEdit_Pass1"
	Else If (errFlag=3)
		errFlag:="请设置新密码！",tempStr:="pwdPassEdit_Pass2"
	Else If (errFlag=4)
		errFlag:="请输入重复密码！",tempStr:="pwdPassEdit_Pass3"
	Else If (errFlag=5)
		errFlag:="新密码两次输入不一致，请检查后重试！",tempStr:="pwdPassEdit_Pass3"
	MsgBox,262192,错误,%errFlag%
	GuiControl,pwd_PassEdit:Focus,%tempStr%
	SendInput ^a
	tempStr=
}
getStr1:=getStr2:=getStr3:=errFlag:=""
Return

pwdPassEdit_Cancel:
pwd_PassEditGuiClose:
pwd_PassEditGuiEscape:
Gui,Main_Win:-Disabled
Gui,pwd_PassEdit:Destroy
Return

;;;-------------------- 编辑 ----------------

PwdEdit_Win:
Gui,pwd_Edit:New
Gui,pwd_Edit:-MinimizeBox +OwnerMain_Win +HwndPassEdit_ID
Gui,pwd_Edit:Font,,Tahoma
Gui,pwd_Edit:Font,,微软雅黑
Gui,pwd_Edit:Add,Text,x15 y13,标题(&T)
Gui,pwd_Edit:Add,Edit,x85 y10 w305 vpwdEdit_ID,%_CURR_ITEM%
Gui,pwd_Edit:Add,Text,x15 y43,用户名(&U)
Gui,pwd_Edit:Add,Edit,x85 y40 w350 vpwdEdit_User,% arr_Pass[_CURR_ITEM][1]
Gui,pwd_Edit:Add,Text,x15 y73,密码(&P)
Gui,pwd_Edit:Add,Edit,x85 y70 w330 r1 Password vpwdEdit_Pass,% arr_Pass[_CURR_ITEM][2]
Gui,pwd_Edit:Add,Text,x15 y103,分组(&G)
tempStr=
Loop,% arr_Class.length()
	tempStr.=((A_Index=1)?"":"|") arr_Class[A_Index]
Gui,pwd_Edit:Add,DropDownList,x85 y100 w350 AltSubmit vpwdEdit_Group,%tempStr%
Gui,pwd_Edit:Add,Text,x15 y133,备注(&I)
Gui,pwd_Edit:Add,Edit,x85 y130 w350 h250 WantTab hwndEBox vpwdEdit_Info,% StrReplace(StrReplace(arr_Pass[_CURR_ITEM][4],"``t","`t"),"``n","`n")
Gui,pwd_Edit:Add,Link,x30 y330 gpwdEdit_AddPath,<a Id="1">+ 网址</a>`n`n<a Id="2">+ 路径</a>
Gui,pwd_Edit:Add,CheckBox,x420 y73 w20 h20 gpwdEdit_ViewPass vpwdEdit_ViewPass,
Gui,pwd_Edit:Add,Button,x250 y390 w100 h25 gpwdEdit_Save,保存(&S)
Gui,pwd_Edit:Add,Button,x355 y390 w80 h25 gpwdEdit_Cancel,取消(&X)
Gui,pwd_Edit:Font,s12,Webdings
tempStr:=Is_Edit?"":"Disabled"
Gui,pwd_Edit:Add,Button,x395 y10 w20 h25 %tempStr% gpwdEdit_Prev,3
Gui,pwd_Edit:Add,Button,x415 y10 w20 h25 %tempStr% gpwdEdit_Next,4
Gui,pwd_Edit:Show,,% (Is_Edit?"编辑":"添加") . "项目"
If Is_Edit
	GuiControl,pwd_Edit:ChooseString,pwdEdit_Group,% arr_Class[arr_Pass[_CURR_ITEM][3]]
Gui,Main_Win:+Disabled
Is_ViewPass:=0,tempStr:=""
Return

pwdEdit_ViewPass:
Is_ViewPass:=1-Is_ViewPass
GuiControl,% (Is_ViewPass?"pwd_Edit:-Password":"pwd_Edit:+Password") . " +ReDraw",pwdEdit_Pass
Return

pwdEdit_AddPath:
If (ErrorLevel=1)
	tempStr:="http://"
Else If (ErrorLevel=2){
	Gui,pwd_Edit:+OwnDialogs
	FileSelectFile,tempStr,3,,选择文件/程序
	If ErrorLevel Or (tempStr="")
		Return
}
Control,EditPaste,%tempStr%,,Ahk_Id %EBox%
GuiControl,pwd_Edit:Focus,pwdEdit_Info
tempStr:=StrLen(tempStr)
SendInput +{Left %tempStr%}
tempStr=
Return

pwdEdit_Prev:
pwdEdit_Next:
Gui,Main_Win:Default
Gui,pwd_Edit:+OwnDialogs
If (A_ThisLabel="pwdEdit_Prev") And (_CURR_ROW=1)
{
	MsgBox,262192,% (Is_Edit?"编辑":"添加") . "项目",已到达第一个项目！
	Return
}
If (A_ThisLabel="pwdEdit_Next") And (_CURR_ROW=Lv_GetCount())
{
	MsgBox,262192,% (Is_Edit?"编辑":"添加") . "项目",已到达最后一个项目！
	Return
}
_CURR_ROW:=(A_ThisLabel="pwdEdit_Prev")?(_CURR_ROW-1):(_CURR_ROW+1)
Lv_Modify(0,"-Select"),Lv_Modify(_CURR_ROW,"Select")
If _GetInfo(_CURR_ROW)
{
	GuiControl,pwd_Edit:,pwdEdit_ID,%_CURR_ITEM%
	GuiControl,pwd_Edit:,pwdEdit_User,% arr_Pass[_CURR_ITEM][1]
	GuiControl,pwd_Edit:,pwdEdit_Pass,% arr_Pass[_CURR_ITEM][2]
	GuiControl,pwd_Edit:ChooseString,pwdEdit_Group,% arr_Class[arr_Pass[_CURR_ITEM][3]]
	GuiControl,pwd_Edit:,pwdEdit_Info,% StrReplace(StrReplace(arr_Pass[_CURR_ITEM][4],"``n","`n"),"``t","`t")
}
Return

pwdEdit_Save:
GuiControlGet,sID,pwd_Edit:,pwdEdit_ID
sID:=Trim(sID),errFlag:=0
If (sID="")
	errFlag:=1,tempStr:="标题不可为空，请修改后重试！"
Else{
	sID:=RegexReplace(sID,"[=\s]","_")	;新标题，=、空格、Tab转为下划线
	If (!Is_Edit Or (Is_Edit And (sID!=_CURR_ITEM))) And arr_Pass.haskey(sID)
		errFlag:=1,tempStr:="项目「" . sID . "」已存在，请修改为其他不重复的标题名！"
}
If errFlag
{
	Gui,Pwd_Edit:+OwnDialogs
	MsgBox,262192,% (Is_Edit?"编辑":"添加") . "项目",%tempStr%
	GuiControl,pwd_Edit:Focus,pwdEdit_ID
	SendInput ^a
	errFlag:=tempStr:=""
	Return
}
errFlag=
GuiControlGet,sUser,pwd_Edit:,pwdEdit_User
GuiControlGet,sPass,pwd_Edit:,pwdEdit_Pass
GuiControlGet,sGroup,pwd_Edit:,pwdEdit_Group
GuiControlGet,sInfo,pwd_Edit:,pwdEdit_Info
Gosub pwd_EditGuiClose
sUser:=Trim(sUser),sPass:=Trim(sPass),sInfo:=StrReplace(StrReplace(Trim(sInfo),"`n","``n"),"`t","``t")
Gui,Main_Win:Default
Lv_Modify(0,"-Select"),fp.Close()
If Is_Edit	;编辑
{
	;编辑模式且所有内容都不变
	If (sID==_CURR_ITEM) And (sUser==arr_Pass[_CURR_ITEM][2]) And (sPass==arr_Pass[_CURR_ITEM][3]) And (sInfo=arr_Pass[_CURR_ITEM][4])
	{
		sID:=sUser:=sPass:=sGroup:=sInfo:=""
		Return
	}
	If !(sID==_CURR_ITEM)	;修改了标题
	{
		arr_Pass.Delete(_CURR_ITEM)
		IniDelete,%_CURR_DB%,PWDMan,%_CURR_ITEM%
		_CURR_ITEM:=sID
	}
	Lv_Modify(_CURR_ROW,"Select Focus",sID,sUser,(sPass="")?"":(Is_PassShowed?sPass:_str_Dot),arr_Class[sGroup],sInfo)
}Else	;新增
	_CURR_ROW:=Lv_Add("Select Focus",sID,sUser,(sPass="")?"":(Is_PassShowed?sPass:_str_Dot),arr_Class[sGroup],sInfo)
	,Lv_Modify(_CURR_ROW,"Vis"),_CURR_ITEM:=sID,_COUNT_PASS+=1,Lv_ModifyCol(1,"","标题" . A_Space . "[" . _COUNT_PASS . "]")
IniWrite,% _COMMA(sUser) "," _COMMA(sPass) "," sGroup "," _COMMA(sInfo),%_CURR_DB%,PWDMan,%sID%
arr_Pass[sID]:=[sUser,sPass,sGroup,sInfo],fp:=_LockFile(),sID:=sUser:=sPass:=sGroup:=sInfo:=""
Return

pwdEdit_Cancel:
pwd_EditGuiClose:
pwd_EditGuiEscape:
Gui,Main_Win:-Disabled
Gui,pwd_Edit:Destroy
Is_ViewPass=
Return

#if WinActive("ahk_id " . PassEdit_ID)
^s:: Gosub pwdEdit_Save
PgUp:: Gosub pwdEdit_Prev
PgDn:: Gosub pwdEdit_Next
#if

;;;-----------数据导出------------

pwdExport_Win:
Gui,Export_Win:New
Gui,Export_Win:-MinimizeBox +OwnerMain_Win
Gui,Export_Win:Font,,Tahoma
Gui,Export_Win:Font,,微软雅黑
Gui,Export_Win:Add,GroupBox,x10 y0 w310 h100,
Gui,Export_Win:Add,Text,x25 y20 w280,支持两种导出类型，根据需求选择：`n● CSV文件 (.csv)，支持导入，可用于数据备份`n● JSON文件 (.json)，不支持导入，可用于数据转移`n注意：导出文件未经加密，请注意保管！
Gui,Export_Win:Add,GroupBox,x10 y105 w310 h65,导出类型
Gui,Export_Win:Add,Radio,x25 y135 Checked vpwdEx_Type1,CSV 文件(&C)
Gui,Export_Win:Add,Radio,x155 y135 vpwdEx_Type2,JSON 文件(&T)
Gui,Export_Win:Add,GroupBox,x10 y175 w310 h65,导出范围
Gui,Export_Win:Add,Radio,x25 y210 Checked vpwdEx_Range1,当前分类(&Q)
Gui,Export_Win:Add,Radio,x155 y210 vpwdEx_Range2,所有分类(&Q)
Gui,Export_Win:Add,Button,x135 y245 w100 Default gpwdEx_OK,导出(&E)
Gui,Export_Win:Add,Button,x240 y245 w80 gpwdEx_Cancel,取消(&X)
Gui,Export_Win:Show,,数据导出 ...
Gui,Main_Win:+Disabled
Return

pwdEx_OK:
Gui,Export_Win:+OwnDialogs
FileSelectFolder,tPath,,,选择导出文件要保存的位置
If ErrorLevel Or (tPath="")
	Return
tPath:=RegExReplace(tPath,"\\$")
;导出格式
GuiControlGet,tType,Export_Win:,pwdEx_Type1
tType:=tType?1:0	;1——csv；0——json
If !tType
	SplitPath,_CURR_DB,,,,db_Name
;导出范围
GuiControlGet,tRange,Export_Win:,pwdEx_Range1
tRange:=tRange?1:0	;1——当前分类；0——全部分类
If (_CURR_CLSINDEX=1)	;若当前分类为全部（_CURR_CLSINDEX=1），则为全部分类
	tRange:=0
tPath.="\密码库导出_" . (tRange?arr_Class[_CURR_CLSINDEX-1]:"All") . "_" . A_Now . "." . (tType?"csv":"json")
Gosub Export_WinGuiClose
If tRange
	outStr:=(tType?"":"{""passLib"": [") . _Ex_Data(_CURR_CLSINDEX-1) . (tType?"":("],""libName"": """ db_Name """}"))
Else{
	outStr:=tType?"":"{""passLib"": ["
	Loop,% arr_Class.length()
		outStr.=((A_Index=1)?"":(tType?"`n":",")) . _Ex_Data(A_Index)
	If !tType
		outStr.="],""libName"": """ db_Name """}"
}
Gui,Main_Win:+OwnDialogs
FileAppend,%outStr%,%tPath%,UTF-8-RAW
MsgBox,% ErrorLevel?262192:262208,数据导出！,% ErrorLevel?"导出数据时出现错误，请重试！":("已成功导出数据: `n" tPath)
tPath:=outStr:=tType:=tRange:=db_Name:=""
Return

pwdEx_Cancel:
Export_WinGuiClose:
Gui,Main_Win:-Disabled
Gui,Export_Win:Destroy
Return

_Ex_Data(i){
	Global arr_Class,tType
	;i——分组类别；1,2,3,4；
	;tType——1：csv；0：json
	r:=tType?"":("{""accountList"": ["),n:=0
	For s1,s2 In arr_Pass
	{
		If (s2[3]=i){
			n+=1
			If tType
				r .= ((n>1)?"`n":"") . _COMMA(s1) . "," . _COMMA(s2[1]) . "," . _COMMA(s2[2]) . "," . arr_Class[i] . "," . _COMMA(s2[4])
			else
				r .= ((n>1)?",":"") . "{""标题"": """ s1 """,""用户名"": """ s2[1] """,""密码"": """ s2[2] """,""备注"": """ s2[4] """}"
		}
	}
	r .= tType?"":("],""groupName"": """ . arr_Class[i] . """}")
	Return r
}

;;;---------- 编码/函数 -------------

_COMMA(s){	;处理逗号
	Return InStr(s,",")?("""" . s . """"):s
}

_LockFile(){	;锁定文件
	Return FileOpen(_CURR_DB,"r -rwd")
}

;UrlDownloadToVar(URL,Timeout=-1)
;{
;	ComObjError(0)
;	WebRequest:=ComObjCreate("WinHttp.WinHttpRequest.5.1")
;	WebRequest.Open("GET",URL,true)
;	WebRequest.Send()
;	WebRequest.WaitForResponse(Timeout)
;	Return WebRequest.ResponseText()
;		,ComObjError(0)
;}