; @title: 文件关联管理
; -------------------

#SingleInstance Ignore
#NoTrayIcon
Menu,Tray,Icon,shell32.dll,-274

Gui,+HwndMainWin
Gui,Font,,Tahoma
Gui,Font,,Microsoft Yahei
Gui,Add,GroupBox,x10 y0 w400 h455 h60
Gui,Add,Text,x25 y25,扩展名(&E)
Gui,Add,ComboBox,x85 y22 w175 Sort gft_Do vft_Suffix,
Gui,Add,Button,x265 y22 w65 h25 Default gft_Do vft_Query,查询(&G)
Gui,Add,Button,x335 y22 w65 h25 Disabled gft_Do vft_Menu,操作(&M)
Gui,Add,GroupBox,x10 y50 w400 h415
Gui,Add,Text,x25 y77,类型名(&T)
Gui,Add,ComboBox,x85 y73 w175 Sort Disabled gft_Do vft_TypeName,
Gui,Add,Button,x265 y73 w35 h25 Disabled gft_Do vft_SetType,✔
Gui,Add,Button,x300 y73 w35 h25 Disabled gft_Do vft_DelType,✖
Gui,Add,Text,x25 y112,图标(&C)
Gui,Add,Edit,x85 y108 w212 Disabled gft_Do vft_IconPath,
Gui,Add,Button,x300 y108 w35 h25 Disabled gft_Do vft_BrowseIcon,...
Gui,Add,GroupBox,x345 y65 w55 h68
Gui,Add,Picture,x356 y87 w32 h-1 Icon1 gft_Do vft_Icon,shell32.dll
Gui,Add,ListView,x20 y145 w380 h305 Grid -Multi Sort Disabled gft_Do vft_List,默认|操作|命令
Gui,Font,Bold
;Gui,Add,Text,x25 y455 w300 cRed vft_Test,Ready
LV_ModifyCol(1,40),LV_ModifyCol(2,60),LV_ModifyCol(3,255)
GuiControl,Focus,ft_Suffix
Gui,Show,,FilesType Manager

Menu,m_Man,Add,备份,cmd_Man
Menu,m_Man,Add,还原,cmd_Man
Menu,m_Man,Add,
Menu,m_Man,Add,删除,cmd_Man

Menu,m_ConText,Add,编辑操作命令,m_CT_Cmd
Menu,m_ConText,Add,设为默认打开方式,m_CT_Cmd
Menu,m_ConText,Add,
Menu,m_ConText,Add,删除操作命令,m_CT_Cmd
Menu,m_ConText,Add,添加操作命令,m_CT_Cmd
Menu,m_ConText,Default,编辑操作命令

Global curr_suffix,curr_Type,arr_Get:=[],arr_Icon:=[],all_suffix:=func_GetKeyFrReg(0),all_Type:=func_GetKeyFrReg(1)
_Is_GetOK:=_Is_BackAct:=IcoID:=0
;_Is_GetOK：0——默认/未找到扩展名；1——找到扩展名和类型名；2——找到扩展名没找到类型名；
;_Is_BackAct：0——删除；1——返回原类型；2——取消创建新扩展名
GuiControl,,ft_Suffix,%all_suffix%
GuiControl,,ft_TypeName,%all_Type%
;SetTimer,ddd,500
Return

;ddd:
;GuiControl,,ft_Test,_Is_GetOK: [%_Is_GetOK%] - _Is_BackAct: [%_Is_BackAct%]
;Return

GuiContextMenu:
If (A_GuiControl<>"ft_List") Or (curr_Type="")
	Return
Menu,m_ConText,% (Lv_GetNext()=0)?"Disable":"Enable",1&
Menu,m_ConText,% (Lv_GetNext()=0)?"Disable":"Enable",2&
Menu,m_ConText,% (Lv_GetNext()=0)?"Disable":"Enable",4&
Menu,m_ConText,Show
Return

ft_Do:
If (A_GuiControl="ft_Suffix"){
	GuiControlGet,tempStr,,ft_Suffix
	If (tempStr<>curr_suffix)
		func_SetEmpty(),func_GuiSwitch(-1)
	_Is_BackAct:=_Is_GetOK:=0,tempStr:=""
}Else If (A_GuiControl="ft_Query")
	Gosub ft_DoQuery
Else If (A_GuiControl="ft_TypeName"){
	func_SetEmpty(1)
	GuiControlGet,tempStr,,ft_TypeName
	tempStr=%tempStr%
	If (_Is_GetOK=1){	;正常切换
		GuiControl,% ((tempStr<>"") And (tempStr<>curr_Type))?"Enable":"Disable",ft_SetType
		GuiControl,Text,ft_DelType,% (tempStr<>curr_Type)?"●":"✖"
		GuiControl,% (tempStr<>curr_Type)?"+Readonly":"-Readonly",ft_IconPath
		GuiControl,% (tempStr<>curr_Type)?"Disable":"Enable",ft_BrowseIcon
		GuiControl,% (tempStr<>curr_Type)?"Disable":"Enable",ft_List
		_Is_BackAct:=(tempStr<>curr_Type)?1:0	;1——返回原类型；0——删除
	}Else If (_Is_GetOK=0){	;添加扩展名
		If (tempStr=""){
			GuiControl,Text,ft_TypeName,%curr_Type%
			SendInput ^a
			GuiControl,Disable,ft_IconPath
		}Else{
			GuiControl,% (tempStr<>curr_Type)?"Enable":"Disable",ft_IconPath
			GuiControl,% (tempStr<>curr_Type)?"+Readonly":"-Readonly",ft_IconPath
		}
	}Else If (_Is_GetOK=2){	;添加类型名
		GuiControl,% (tempStr<>"")?"Enable":"Disable",ft_SetType
		GuiControl,% (tempStr<>"")?"Enable":"Disable",ft_IconPath
		GuiControl,% (tempStr<>"")?"+Readonly":"-Readonly",ft_IconPath
	}
	func_FillToGui(tempStr),tempStr:=""
}Else If (A_GuiControl="ft_Menu"){
	If func_SuffixCheck()
		Menu,m_Man,Show
	Else{
		curr_Type:=curr_suffix . "file"
		GuiControl,Text,ft_TypeName,%curr_Type%
		func_GuiSwitch(3),_Is_BackAct:=2
		GuiControl,Focus,ft_TypeName
	}
}Else If (A_GuiControl="ft_BrowseIcon")
		Gosub SetIcons
Else If (A_GuiControl="ft_List"){
	Gui,%MainWin%:Default
	If A_GuiEvent In DoubleClick
	{
		curr_Row:=Lv_GetNext()
		If (curr_Row=0)
			Is_AddCmd:=1
		Else
			LV_GetText(curr_Opt,curr_Row,2),Is_AddCmd:=0
		Gosub cmd_Edit_Win
	}
}Else If (A_GuiControl="ft_SetType"){	;确定添加/指定类型名
	GuiControlGet,tempStr,,ft_TypeName
	tempStr=%tempStr%
	If (tempStr=""){
		GuiControl,Focus,ft_TypeName
		Return
	}
	Gui,+OwnDialogs
	MsgBox,262196,更改/指定类型名,% "确定要更改/指定类型名为「" . tempStr . "」？"
	IfMsgBox,No
		Return
	RegWrite,REG_SZ,% ((_Is_GetOK=0)?"HKCU\SOFTWARE\Classes":"HKCR") . "\." . curr_suffix,,%tempStr%
	errflag:=ErrorLevel
	If !errflag
	{
		func_GuiSwitch(1),curr_Type:=tempStr,_Is_GetOK:=1,_Is_BackAct:=0
		GuiControl,Text,ft_DelType,✖
	}
	func_ShowTip(errflag?(((_Is_GetOK=0)?"创建":"指定") "文件类型「" curr_Type "」错误！"):("已" ((_Is_GetOK=0)?"创建":"指定") . "类型为「" tempStr "」"))
	tempStr=
}Else If (A_GuiControl="ft_DelType"){
	If (_Is_BackAct=0)	;删除文件类型
	{
		Gui,+OwnDialogs
		MsgBox,262196,删除文件类型,% "确定删除文件类型「" curr_Type "」？"
		IfMsgBox,No
			Return
		RegDelete,% "HKCR\" . curr_Type
		errflag:=ErrorLevel,func_ShowTip(errflag?("删除文件类型“" curr_Type "”失败！"):("已成功删除文件类型“" curr_Type "”"))
		If !errflag
		{
			GuiControl,,ft_TypeName,%all_Type%
			func_SetEmpty(),func_GuiSwitch(5)
			,all_Type:=SubStr(strReplace(all_Type . "|","|" . curr_Type . "|","|"),1,-1)
			,curr_Type:=arr_Get["ico"]:="",arr_Get[]:=[]
		}
		errflag=
	}Else If (_Is_BackAct=1){	;返回指定类型状态
		GuiControl,ChooseString,ft_TypeName,%curr_Type%
		func_GuiSwitch(1),func_FillToGui(curr_Type),_Is_BackAct:=0
		GuiControl,Text,ft_DelType,✖
	}Else If (_Is_BackAct=2){	;取消创建新扩展名
		GuiControl,Text,ft_TypeName,
		func_GuiSwitch(4),func_SetEmpty(),_Is_BackAct:=0
	}
}Else If (A_GuiControl="ft_Icon"){
	tempStr=
(
FilesType Manager
v0.0.4（2020年10月25日）
`n# 注意！本工具直接修改系统设置，请慎重操作！
# 查询、修改关联为操作注册表 HKCR 分支
# 增加文件关联为操作 HKCU 分支
# 不支持动态数据交换（DDE）等高级操作
`n© Easysky by Cui, 2013-%A_yyyy%
)
Gui,+OwnDialogs
MsgBox,262208,关于,%tempStr%
tempStr=
}
Return

ft_DoQuery:
func_SetEmpty(),_Is_BackAct:=_Is_GetOK:=0
GuiControlGet,curr_suffix,,ft_Suffix
curr_suffix:=RegexReplace(Trim(curr_suffix),"^\.")
Gui,Show,,% "FilesType Manager" ((curr_suffix="")?"":(" -「" curr_suffix "」"))
GuiControl,Text,ft_Suffix,%curr_suffix%
GuiControl,Focus,ft_Suffix
SendInput {End}
errflag:=0
If (curr_suffix="")	;查询为空
	errflag:=1
Else If curr_suffix In exe,bat,cmd,com,cpl,scr,pif,ttf,ttc,fon,ico	;无图标扩展名
	func_ShowTip("文件类型“" curr_suffix "”无图标或本身为图标文件！",2500),errflag:=1
If errflag
{
	func_GuiSwitch(-1)
	Guicontrol,Focus,ft_Suffix
	SendInput ^a
	Return
}
If !func_SuffixCheck()	;未找到扩展名
{
	func_GuiSwitch(0)
	Return
}
curr_Type=
RegRead,tempStr,% "HKCR\." . curr_suffix,
If !ErrorLevel
	curr_Type:=tempStr,tempStr:=""
If (curr_Type<>"")
{
	Guicontrol,ChooseString,ft_TypeName,%curr_Type%
	func_GuiSwitch(1),func_FillToGui(curr_Type),_Is_GetOK:=1
}Else		;找到扩展名但未找到类型名
	func_GuiSwitch(2),curr_Type:="",_Is_GetOK:=2
Return

cmd_Man:
If (A_ThisMenuItemPos=1){	;备份
	If !FileExist(A_ScriptDir "\RegBak")
		FileCreateDir, %A_ScriptDir%\RegBak
	file_Bak:=A_ScriptDir "\RegBak\" curr_suffix ".reg"
	If FileExist(file_Bak)
	{
		Gui,+OwnDialogs
		MsgBox,262196,备份,备份文件“%file_Bak%”已存在，`n是否覆盖？
		IfMsgBox,Yes
			FileDelete,%file_Bak%
		Else
			Return
	}
	FileDelete,%A_Temp%\*.ftb
	arr_Temp:=["HKCR\." curr_suffix,"HKCR\" curr_Type],errflag:=0
	Loop,2
	{
		tempStr:=arr_Temp[A_Index]
		Try
			RunWait,%comspec% /c "reg export "%tempStr%" "%A_Temp%\t%A_Index%.ftb"",,Hide
		Catch
			errflag:=1,func_ShowTip("备份扩展名错误！")
	}
	arr_Temp:=[],tempStr:=""
	If !errflag
	{
		Loop,Read,%A_Temp%\t1.ftb,%A_Temp%\t2.ftb
		{
			If !InStr(A_LoopReadLine,"Windows Registry Editor Version 5.00")
				FileAppend,%A_LoopReadLine%`n
		}
		Try
		{
			FileMove,%A_Temp%\t2.ftb,%file_Bak%
			FileDelete,%A_Temp%\t1.ftb
			func_ShowTip("已备份：" file_Bak,3000)
		}Catch
			func_ShowTip("备份错误！")
	}
	file_Bak:=errflag:=""
}Else If (A_ThisMenuItemPos=2){	;还原
	If !FileExist(A_ScriptDir "\RegBak")
	{
		func_ShowTip("未找到备份目录！")
		Return
	}
	tempStr:=A_ScriptDir "\RegBak\" curr_suffix ".reg"
	If !FileExist(tempStr)
	{
		func_ShowTip("目录“" A_ScriptDir "\RegBak”中未找到备份文件！")
		Return
	}
	Gui,+OwnDialogs
	MsgBox,262196,还原扩展名,确定还原扩展名“%curr_suffix%”的设置？
	IfMsgBox,Yes
	{
		Try
		{
			RunWait, %comspec% /c "regedit /s "%tempStr%"",,Hide
			Gosub ft_DoQuery
			func_ShowTip("已成功还原“" curr_suffix "”",3000)
		}
		Catch
			func_ShowTip("还原扩展名错误！")
	}
	tempStr=
}Else If (A_ThisMenuItemPos=4){	;删除
	Gui,+OwnDialogs
	MsgBox,262196,删除扩展名,确定删除扩展名“%curr_suffix%”？
	IfMsgBox,Yes
	{
		RegDelete,% "HKCR\." curr_suffix
		func_ShowTip(ErrorLevel?("删除扩展名“" curr_suffix "”失败！"):("已成功删除扩展名“" curr_suffix "”"))
		,all_suffix:=SubStr(strReplace(all_suffix . "|","|" . curr_suffix . "|","|"),1,-1),func_GuiSwitch(6)
		If !ErrorLevel
			func_SetEmpty()
	}
}
Return

m_CT_Cmd:
If (A_ThisMenuItemPos=1){
	curr_Row:=Lv_GetNext(),LV_GetText(curr_Opt,curr_Row,2),Is_AddCmd:=0
	Gosub cmd_Edit_Win
}Else If (A_ThisMenuItemPos=2){
}Else If (A_ThisMenuItemPos=4){
	Gui,+OwnDialogs
	MsgBox,262180,提示,确定删除该命令？
	IfMsgBox,Yes
	{
		curr_Row:=Lv_GetNext(),LV_GetText(curr_Opt,curr_Row,2)
		RegDelete,% "HKCR\" curr_Type "\shell\" curr_Opt
		func_ShowTip(ErrorLevel?("删除操作“" curr_Opt "”失败，请重试！"):("已成功删除操作“" curr_Opt "”"))
		If !ErrorLevel
			Lv_Delete(curr_Row),arr_Get["opt"].Delete(curr_Opt)
		currRow:=curr_Opt:=""
	}
}Else If (A_ThisMenuItemPos=5) {
	ft_currName:=ft_currCmd:="",Is_AddCmd:=1
	Gosub cmd_Edit_Win
	GuiControl,cmd_Edit:Focus,ce_Name
	Gui,%MainWin%:+Disabled
}
Return

func_ShowTip(s,t:=2000){
	SplashImage,,b1 fs10 cw6666661 FM10 ctffffff,%s%,,,微软雅黑
	SetTimer,RemoveTooltip,-%t%
}

func_GetKeyFrReg(b){
; b：0——获取扩展名；1——获取类型名；
	r=
	If !b
	{
		Loop,Reg,HKCR,K
		{
			If (SubStr(A_LoopRegName,1,1)=".")
				r .= "|" . SubStr(A_LoopRegName,2)
		}
	}Else{
		Loop,Reg,HKCR,K
		{
			If !RegexMatch(A_LoopRegName,"^[\*\.]")
				r .= "|" . A_LoopRegName
		}
	}
	Return r
}

func_FillToGui(s){
	If (s="")
		Return
	Global str_DEFOpen
	arr_Get:=arr_Temp:=[],arr_Temp:=func_GetValueFrReg(s)
	,arr_Get["ico"]:=arr_Temp[1],arr_Get["opt"]:=arr_Temp[2]
	,arr_Temp:=[]
	;获取并显示图标
	If (arr_Get["ico"]<>""){
		GuiControl,,ft_IconPath,% arr_Get["ico"]
		arr_Icon:=[],arr_Icon:=StrSplit(arr_Get["ico"],",")
		Try
			Guicontrol,,ft_Icon,% "*icon" . ((SubStr(arr_Icon[2],1,1)="-")?arr_Icon[2]:(arr_Icon[2]+1)) " " arr_Icon[1]
		Catch{
			func_ShowTip("无法获取图标或不包含图标文件！")
			Guicontrol,,ft_Icon,*icon1 shell32.dll
		}
	}
	;操作命令
	Lv_Delete()
	GuiControl,-Redraw,ft_List
	For s1,s2 In arr_Get["opt"]
		Lv_Add("",(s1=str_DEFOpen)?"是":"否",s1,s2)
	GuiControl,+Redraw,ft_List
}

func_GetValueFrReg(s){
	Global str_DEFOpen
	; s：类型名；str_DEFOpen：默认打开方式
	RegRead,sIcon,% "HKCR\" . s . "\DefaultIcon"
	sIcon:=ErrorLevel?"":strReplace(Trim(sIcon),"""")	;图标参数
	;获取命令类别
	arr_OPT:=[]
	RegRead,str_DEFOpen,% "HKCR\" . s . "\shell",
	If (str_DEFOpen="")
		str_DEFOpen:="open"
	Loop,Reg,% "HKCR\" . s . "\shell",K
	{
		RegRead,tempStr,% "HKCR\" . s . "\shell\" . A_LoopRegName . "\command"
		If !ErrorLevel
			arr_OPT[A_LoopRegName]:=tempStr
	}
	Return [sIcon,arr_OPT]

}

func_GuiSwitch(b){
; b=-1——启动（默认）时；扩展名为空；扩展名无图标
; b=0——未找到扩展名
; b=1——1)找到扩展名并查询到类型名；2)确定修改类型名
; b=2——找到扩展名但未查询到类型名
; b=3——点击创建扩展名后
; b=4——取消创建扩展名后
; b=5——删除类型
; b=6——删除扩展名
; b=7——已找到类型名，切换类型
; b=8——新建扩展名时，切换类型
; b=9——有扩展名但无类型时，切换类型
; b=10——类型名切换为空

	GuiControl,% ((b=3) Or (b=8))?"Disable":"Enable",ft_Suffix
	If (b=6)
		GuiControl,,ft_Suffix,
	GuiControl,% ((b=3) Or (b=8))?"Disable":"Enable",ft_Query
	GuiControl,% ((b=3) Or (b=6) Or (b=-1) Or (b=8))?"Disable":"Enable",ft_Menu
	GuiControl,,ft_Menu,% (((b=0) Or (b=4))?"创建":"操作") . "(&M)"
	GuiControl,% ((b=0) Or (b=4) Or (b=6) Or (b=-1))?"Disable":"Enable",ft_TypeName
	If (b=5)
		GuiControl,,ft_TypeName,
	GuiControl,% ((b=3) Or (b=5))?"Enable":"Disable",ft_SetType
	GuiControl,% ((b=1) Or (b=3) Or (b=7) Or (b=8))?"Enable":"Disable",ft_DelType
	GuiControl,% (b=1)?"Enable":"Disable",ft_IconPath
	If (b=1)
		GuiControl,-Readonly,ft_IconPath
	GuiControl,% (b=1)?"Enable":"Disable",ft_BrowseIcon
	GuiControl,% (b=1)?"Enable":"Disable",ft_List
	Menu,m_Man,% (b=2)?"Disable":"Enable",1&
	Menu,m_Man,% (b=2)?"Disable":"Enable",2&
}

func_SuffixCheck(){
	Return InStr(all_suffix . "|","|" . curr_suffix . "|")?1:0
}

func_SetEmpty(b:=0){
	;b=0——全部清空；b=1——除类型名外全部清空
	If !b
	{
		GuiControl,Text,ft_TypeName,
		_Is_GetOK:=0
	}
	Guicontrol,Text,ft_DelType,✖
	GuiControl,Text,ft_IconPath,
	Guicontrol,,ft_Icon,*icon1 shell32.dll
	Lv_Delete(),arr_Get:=[]
}

RemoveTooltip:
SplashImage,off
Return

;;;;-----------操作命令设置-----------------

cmd_Edit_Win:
Gui,%MainWin%:+Disabled
Gui,cmd_Edit:New
Gui,cmd_Edit:+Owner%MainWin%
Gui,cmd_Edit:Font,,Tahoma
Gui,cmd_Edit:Font,,Microsoft Yahei
Gui,cmd_Edit:Add,Text,x10 y12,操作(&P)
Gui,cmd_Edit:Add,ComboBox,x65 y10 w140 gcmd_Do vce_Name,Open|Edit|Print|Printto
;Gui,cmd_Edit:Add,CheckBox,x220 y15 vce_Def,默认打开方式
Gui,cmd_Edit:Add,Text,x10 y42,命令(&D)
;Gui,cmd_Edit:Add,Button,x360 y10 w80 h23 gcmd_Do vce_getApp,+ 添加命令
Gui,cmd_Edit:Add,Edit,x65 y40 w375 h100 -WantReturn vce_Cmd,
Gui,cmd_Edit:Add,Link,x375 y13 h23 gcmd_Do vce_getApp,<a>+ 添加命令</a>
Gui,cmd_Edit:Add,Text,x10 y155 c0066cc,注：此对话框不验证程序路径！
Gui,cmd_Edit:Add,Button,x290 y150 w75 h25 gcmd_Do vce_OK,确定(&S)
Gui,cmd_Edit:Add,Button,x370 y150 w70 h25 gcmd_Do vce_Cancel,关闭(&X)
If !Is_AddCmd	;编辑
{
	GuiControl,cmd_Edit:Text,ce_Name,%curr_Opt%
	GuiControl,cmd_Edit:Text,ce_Cmd,% arr_Get["opt"][curr_Opt]
	;GuiControl,cmd_Edit:Enabled,ce_getApp
	;GuiControl,cmd_Edit:,ce_def,% (curr_Opt=str_DEFOpen)?1:0
	GuiControl,cmd_Edit:Disabled,ce_Name
}
Gui,cmd_Edit:Show,,% ((Is_AddCmd)?"添加":"修改") . "操作命令"
Menu,cmd_AddMenu,Add,执行程序 ...,cmd_AppAdd
Menu,cmd_AddMenu,Add
Menu,cmd_AddMenu,Add,[系统:注册表 .reg 文件] 执行,cmd_AppAdd
Menu,cmd_AddMenu,Add,[系统:批处理 .bat 文件] 执行,cmd_AppAdd
Menu,cmd_AddMenu,Add,[系统:屏保文件 .scr],cmd_AppAdd
Menu,cmd_AddMenu,Default,1&
Return

cmd_Do:
If (A_GuiControl="ce_Name"){
	GuiControlGet,tempStr,cmd_Edit:,ce_Name
	tempStr=%tempStr%
	GuiControl,% (tempStr<>"")?"cmd_Edit:Enabled":"cmd_Edit:Disabled",ce_getApp
	tempStr=
}Else If (A_GuiControl="ce_getApp")
	Menu,cmd_AddMenu,Show
Else If (A_GuiControl="ce_OK"){
	GuiControlGet,new_Opt,cmd_Edit:,ce_Name
	new_Opt=%new_Opt%
	GuiControlGet,new_Cmd,cmd_Edit:,ce_Cmd
	new_Cmd=%new_Cmd%
	If (new_Opt="") Or (new_Cmd="")
		Return
	Gosub cmd_EditGuiClose
	Gui,%MainWin%:Default
	If !Is_AddCmd	;编辑状态
		Lv_Modify(curr_Row,"Col3",new_Cmd)
	Else
		Lv_Add("Select Focus Vis","否",new_Opt,new_Cmd)
	arr_Get["opt"][new_Opt]:=new_Cmd
	RegWrite,REG_SZ,% "HKCR\" curr_Type "\shell\" new_Opt "\command",,%new_Cmd%
	func_ShowTip(ErrorLevel?"命令更新失败！":"命令已更新！"),curr_Row:=new_Opt:=new_Cmd:=""
}Else If (A_GuiControl="ce_Cancel")
	Gosub cmd_EditGuiClose
Return

cmd_AppAdd:
If (A_ThisMenuItemPos=1){
	Gui +OwnDialogs
	FileSelectFile,tempStr,35,,选择该类型文件的关联程序,可执行程序文件(*.exe; *.dll)
	If ErrorLevel
		Return
	If (InStr(tempStr," ")>0)
		tempStr="%tempStr%"
	tempStr=%tempStr%%A_Space%"`%1"
}Else If (A_ThisMenuItemPos=3)
	tempStr=regedit.exe `%1
Else If (A_ThisMenuItemPos=4)
	tempStr="`%1" `%*
Else If (A_ThisMenuItemPos=5)
	tempStr="`%1" /S
GuiControl,cmd_Edit:,ce_Cmd,%tempStr%
GuiControl,cmd_Edit:Focus,ce_Cmd
SendInput ^{End}
tempStr=
Return

cmd_EditGuiClose:
cmd_EditGuiEscape:
Gui,%MainWin%:-Disabled
Gui,cmd_Edit:Destroy
Menu,cmd_AddMenu,Delete
Return

;;;;-----------设置图标-----------------

SetIcons:
Default_Icons:="shell32.dll|imageres.dll|inetcpl.cpl|rasdlg.dll|rasgcw.dll|comres.dll|DDORes.dll|dmdskres.dll|wpdshext.dll"
Gui,%MainWin%:+Disabled
Gui,IconSet:New
Gui,IconSet:+Owner%MainWin%
Gui,IconSet:Font,,Tahoma
Gui,IconSet:Font,,Microsoft Yahei
Gui,IconSet:Add,ComboBox,w305 vIcon_App_Path,%Default_Icons%
Gui,IconSet:Add,Button,ym w40 h23 Default gListIcons,→
Gui,IconSet:Add,Button,ym w30 h23 gIcon_App_Find vIcon_App_Find,...
Gui,IconSet:Add,ListView,xm w398 h220 +Icon -Multi AltSubmit gIconList vIconList,
Gui,IconSet:Add,Button,xm+228 w80 h25 gIcon_OK,确定(&S)
Gui,IconSet:Add,Button,xp+90 w80 h25 gIcon_Cancel,关闭(&X)
GuiControl,IconSet:Text,Icon_App_Path,% arr_Icon[1]
Gui,IconSet:Show,,更改/设置图标
func_IconsToList(arr_Icon[1])
Return

IconList:
If A_GuiEvent in DoubleClick
	Gosub Icon_OK
Return

ListIcons:
GuiControlGet,tempStr,IconSet:,Icon_App_Path
func_IconsToList(tempStr,0),tempStr:=""
Return

Icon_App_Find:
Gui,IconSet:+OwnDialogs
FileSelectFile,tempStr,3,,选择图标或包含图标的文件,含图标文件 (*.exe; *.dll; *.ico)
If !ErrorLevel And (tempStr<>"") {
	GuiControl,IconSet:Text,Icon_App_Path,%tempStr%
	Gosub ListIcons
}
tempStr=
Return

Icon_OK:
If (LV_GetNext()<1)
	Return
GuiControlGet,curr_Path,IconSet:,Icon_App_Path
tempStr:=curr_Path:=Trim(curr_Path),errflag:=0
If (curr_Path="")
	errflag:=1
If !errflag And !FileExist(curr_Path)
{
	tempStr:=getFullPath(tempStr)
	If !FileExist(tempStr)
		errflag:=1
}
If errflag
{
	GuiControl,IconSet:Focus,Icon_App_Path
	tempStr:=curr_Path:=""
	Return
}
arr_Icon[1]:=curr_Path,arr_Icon[2]:=LV_GetNext(0)-1,curr_Path.="," arr_Icon[2]
Guicontrol,%MainWin%:,ft_Icon,% "*icon" . (arr_Icon[2]+1) " " tempStr
Guicontrol,%MainWin%:,ft_IconPath,%curr_Path%
RegWrite,REG_SZ,% "HKCR\" curr_Type "\DefaultIcon",,%curr_Path%
If !ErrorLevel
	arr_Get["ico"]:=curr_Path
Gosub IconSetGuiClose
func_ShowTip(ErrorLevel?"更改关联图标错误！":("文件类型“" curr_Type "”关联图标已更新"))
tempStr:=curr_Path:=""
Return

IconSetGuiClose:
IconSetGuiEscape:
Icon_Cancel:
Gui %MainWin%:-Disabled
Gui,IconSet:Destroy
Return

func_IconsToList(p,b:=1){
	Global Default_Icons
	LV_Delete(),IL_Destroy(IcoID),t:=FileExist(p)?p:getFullPath(p)
	If !FileExist(t)
		Return
	Gui,IconSet:Show,,正在加载图标，请稍候 ...
	IcoID:=IL_Create(1,5,1),LV_SetImageList(IcoID)
	GuiControl,IconSet:-Redraw,IconList
	tempStr:=0
	loop
	{
		n:=IL_Add(IcoID,t,A_index)
		if (n=0)
			break
		tempStr += 1
	}
	if (tempStr>0){
		Loop,%tempStr%
			LV_Add("Icon" . A_Index,A_Index-1)
		GuiControl,IconSet:+Redraw,IconList
		GuiControl,IconSet:Focus,IconList
		tempStr:=((arr_Icon[2]<0) or (arr_Icon[2]>tempStr))?0:arr_Icon[2],LV_Modify(b?(tempStr+1):tempStr,"Select Vis")
	}
	tempStr=
	Gui,IconSet:Show,,更改/设置图标
	If !InStr("|" . Default_Icons . "|","|" . p . "|")
	{
		Default_Icons .= "|" . p
		GuiControl,IconSet:,Icon_App_Path,%p%
	}
}

getFullPath(s) {	;返回完整文件路径，文件不存在时返回空值
	if (s="")
		Return ""
	If (substr(s,2,2)<>":\")
		Transform,s,Deref,%s%
	r:=s
	If !FileExist(s)
	{
		r=
		RegRead,t,Hklm\SYSTEM\ControlSet001\Control\Session Manager\Environment,Path
		Loop,parse,t,`;
		{
			Transform,tempStr,Deref,%A_LoopField%
			if (substr(tempStr,0)<>"\")
				tempStr .= "\"
			tempStr .= s
			If FileExist(tempStr)
			{
				r:=tempStr
				Break
			}
			tempStr=
		}
		t=
	}
	Return r
}

GuiClose:
ExitApp

;^1::Reload