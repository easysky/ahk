; @title: ��ݼ��༭��
; ------------------
#SingleInstance Ignore
#NoTrayIcon
Menu,Tray,Icon,shell32.dll,-283
CoordMode,Mouse,Screen
SplitPath,A_ScriptDir,,s
__fKey_SetPath:=s . "\Lib\Hotkeys.ahk",b_HKF_Exist:=FileExist(__fKey_SetPath)?1:0
,arr_KeysTip:={"ahk_BrowseSelUrl":"���ѡ����ַ"
,"ahk_ClearClip":"��ռ�����"
,"ahk_CloseLCD":"�ر���ʾ��"
,"ahk_CloseLCDAndLockPC":"�ر���ʾ������������"
,"ahk_HiddenWinMan":"�������ش��ڹ���˵�"
,"ahk_HideThisWin":"���ص�ǰ����"
,"ahk_LockInput":"��ֹ�����������"
,"ahk_LockPC":"��������"
,"ahk_ReloadScript":"��������"
,"ahk_SearchSelText":"����ѡ������"
,"ahk_ShowAppList":"�������ٳ���˵�"
,"ahk_ShowExtendMenu":"������չ���������ò˵�"
,"ahk_ShowMainMenu":"����ϵͳ���˵�"
,"ahk_ShowSysContrl":"����ϵͳ���ƹ���˵�"
,"ahk_ToggleTrayIcon":"��ʾ/���س�������ͼ��"
,"ahk_TopOnThisWin":"������ö�"
,"ahk_TransparentThisWin":"�����͸���л�"
,"ahk_VolumeDown":"��С����"
,"ahk_VolumeUp":"�Ӵ�����"}
,arr_KeysMap:=arr_KeysList:=[],_Is_KeyMod:=0,s1:=s2:=""
If b_HKF_Exist
{
	Loop,Read,%__fKey_SetPath%
	{
		If RegexMatch(A_LoopReadLine,"i)^\s*([^:]+)::\s*GoSub\s+(ahk_[^\s]+)",s)
			arr_KeysMap[s2]:=s1,arr_KeysList[s1]:=s2
			;s1���ȼ���s2������
			;arr_KeysMap[����]:=�ȼ����Ѷ����ȼ�ӳ��
			;arr_KeysList[�ȼ�]:=������ȼ��Ѷ���
	}
}
Gui,+HwndKS_MainID
Gui,Font,,΢���ź�
Gui,Add,ListView,x0 y0 w700 h550 Grid -WantF2 -Multi HwndctrList ReadOnly gKA_KeyList vKA_KeyList,��ݼ�|����|��������
LV_ModifyCol(1,200),LV_ModifyCol(2,200),LV_ModifyCol(3,270)
Gui,Show,w700 h550,��ݼ�������
GuiControl,-Redraw,KA_KeyList
Lv_Add("","* Shift+Pause","[�����ȼ�]","����/�ָ��ű�"),Lv_Add("","* Ctrl+Alt+Shift+Insert","[�����ȼ�]","����/�ָ��ű�")
For s1,s2 In arr_KeysTip
	Lv_Add("",_Key_Switch(arr_KeysMap[s1]),s1,s2)
GuiControl,+Redraw,KA_KeyList
Menu,Pop_KAMenu,Add,�༭(&E),cmd_KAMenu
Menu,Pop_KAMenu,Add
Menu,Pop_KAMenu,Add,ɾ��(&D),cmd_KAMenu
Menu,Pop_KAMenu,Add
Menu,Pop_KAMenu,Add,����(&S),cmd_KAMenu
Menu,Pop_KAMenu,Add
Menu,Pop_KAMenu,Add,����(&R),cmd_KAMenu
s:=s1:=s2:=""
Return

GuiContextMenu:
strKS_Row:=A_EventInfo
If _Check_InnerKey()
	Menu,Pop_KAMenu,Show
Return

KA_KeyList:	;;;˫�����б༭
If (A_GuiEvent="DoubleClick"){
	strKS_Row:=A_EventInfo
	If _Check_InnerKey()
		GoSub KA_KeySetWin
}
Return

cmd_KAMenu:
If (A_ThisMenuItemPos=1)
	GoSub KA_KeySetWin
Else If (A_ThisMenuItemPos=3)
	Gosub sub_RemoveKey
Else If (A_ThisMenuItemPos=5)
	Gosub sub_SaveKeySet
Else If (A_ThisMenuItemPos=7)
	Reload
Return

sub_RemoveKey:
Gui,+OwnDialogs
Msgbox,262180,ɾ����ݼ�,ȷ��ɾ��ѡ�еĿ�ݼ���
IfMsgBox No
	Return
Gui,Default
Lv_Modify(strKS_Row,"Col1","")
,arr_KeysMap.Delete(arr_KeysList.Delete(_Key_Switch(strKS_Key,1)))
,_Is_KeyMod:=1
Return

#If WinActive("ahk_id " . KS_MainID)
Enter::
NumPadEnter::
Del::
Gui,Default
strKS_Row:=Lv_GetNext()
If (strKS_Row=0)
	Return
If _Check_InnerKey()
{
	If (A_ThisHotkey="Del")
		Gosub sub_RemoveKey
	Else
		GoSub KA_KeySetWin
}
Return
#if

GuiClose:
Gui,Destroy
Menu,Pop_KAMenu,Delete
If _Is_KeyMod
	Gosub sub_SaveKeySet
ExitApp
Return

sub_SaveKeySet:
_str_Out:="; @title:`t�����ȼ�`n; ���ļ���ֱ�ӱ༭��ʹ���Զ���ű���������`n; Shift+Pause��Ctrl+Alt+Shift+Insert������/�ָ��ű��������ȼ���֧���޸�`n; ------------------"
For s1,s2 In arr_KeysTip
	_str_Out.="`n" . (arr_KeysMap.Haskey(s1)?(arr_KeysMap[s1] . "::"):";`t") . "`tGosub " . s1 . "`t`t;" . s2
FileDelete,%__fKey_SetPath%
FileAppend,%_str_Out%,%__fKey_SetPath%,UTF-8
_Is_KeyMod:=0,_str_Out:=A_TickCount
SplashImage,,b1 w350 fs10 cwffffcc FM10,�ȼ������Ѹ��£����ű���zBox.ahk����������Ч,,,Microsoft Yahei
Loop
{
	If (A_TickCount-_str_Out>=3000)
	{
		SplashImage,Off
		Break
	}
}
_str_Out=
Return

_Check_InnerKey(){
	Global KS_MainID,strKS_Row,strKS_Key
	Gui,%KS_MainID%:Default
	Lv_GetText(r,strKS_Row)
	If (SubStr(r,1,1)="*"){
		Gui,+OwnDialogs
		MsgBox,262192,��ʾ,���ÿ�ݼ���֧���޸ģ�
		Return 0
	}
	strKS_Key:=r
	Return 1
}

_Key_Switch(s,b:=0)
{
	If b
		Return StrReplace(StrReplace(StrReplace(StrReplace(s,"Shift+","+"),"Alt+","!"),"Ctrl+","^"),"Win+","#")
	StringUpper,s,s,T
	Return StrReplace(StrReplace(StrReplace(StrReplace(s,"+","Shift+"),"!","Alt+"),"^","Ctrl+"),"#","Win+")
}

;;------------- ���ÿ�ݼ���ʼ ---------------

KA_KeySetWin:
Gui,%KS_MainID%:+Disabled
Gui,HotKeySet:New
Gui,HotKeySet:-MinimizeBox +Owner%KS_MainID%
Gui,HotKeySet:Font,,΢���ź�
Gui,HotKeySet:Add,GroupBox,x10 y0 w345 h90,
Gui,HotKeySet:Add,Edit,x300 y15 w45 Limit1 Center Uppercase vKeyKey,
Gui,HotKeySet:Add,CheckBox,x20 y20 vKey_Ctrl,&Ctrl +
Gui,HotKeySet:Add,CheckBox,x90 y20 vKey_Alt,&Alt +
Gui,HotKeySet:Add,CheckBox,x155 y20 vKey_Shift,&Shift +
Gui,HotKeySet:Add,CheckBox,x230 y20 vKey_Win,&Win +
Gui,HotKeySet:Add,CheckBox,x20 y55 gKA_KeyChk vKA_KeyChk,�����(&Z)
Gui,HotKeySet:Add,DropDownList,x98 y50 w110 vKeySpec,
Gui,HotKeySet:Add,Button,x215 y50 w65 h25 Default gKA_Key_Save,ȷ��(&S)
Gui,HotKeySet:Add,Button,x285 y50 w60 h25 gKA_Key_Cancel vKA_Key_Cancel,ȡ��(&C)
tempStr:="|"
Loop,12
	tempStr .= "F" . A_Index . "|"
tempStr .= "Esc/Escape|Tab|BS/BackSpace|Enter/Return|Space|Ins/Insert|Del/Delete|Home|End|PgUp|PgDn|Left|Right|Up|Down|Pause|PrintScreen|AppsKey|Sleep|Pause|CtrlBreak|Numpad0|Numpad1|Numpad2|Numpad3|Numpad4|Numpad5|Numpad6|Numpad7|Numpad8|Numpad9|NumpadDot|NumpadEnter|NumpadMult|NumpadDiv|NumpadAdd|NumpadSub|LButton|RButton|MButton|WheelUp|WheelDown|WheelLeft|WheelRight|XButton1|XButton2"
GuiControl,HotKeySet:,KeySpec,%tempStr%
tempStr .= "|",b_UseSpecKey:=0
MouseGetPos,dx,dy
dx-=180,dy-=15
If (dx<0)
	dx:=10
If (dx+375>A_ScreenWidth)
	dx:=A_ScreenWidth-380
If (dy<0)
	dy:=10
If (dy+160>A_ScreenHeight)
	dy:=A_ScreenHeight-190
Gui,HotKeySet:Show,x%dx% y%dy%,�༭��ݼ�
if (strKS_Key<>""){
	Loop,Parse,strKS_Key,+
	{
		If A_LoopField in Ctrl,Alt,Shift,Win
			GuiControl,HotKeySet:,Key_%A_LoopField%,1
		tempKeyStr:=A_LoopField
	}
	If tempKeyStr In Esc,Escape
	{
		GuiControl,HotKeySet:ChooseString,KeySpec,Esc/Escape
		b_UseSpecKey:=1
	}Else If tempKeyStr In Bs,BackSpace
	{
		GuiControl,HotKeySet:ChooseString,KeySpec,BS/BackSpace
		b_UseSpecKey:=1
	}Else If tempKeyStr In Enter,Return
	{
		GuiControl,HotKeySet:ChooseString,KeySpec,Enter/Return
		b_UseSpecKey:=1
	}Else If tempKeyStr In Ins,Insert
	{
		GuiControl,HotKeySet:ChooseString,KeySpec,Ins/Insert
		b_UseSpecKey:=1
	}Else If tempKeyStr In Del,Delete
	{
		GuiControl,HotKeySet:ChooseString,KeySpec,Del/Delete
		b_UseSpecKey:=1
	}Else if instr(tempStr,"|" . tempKeyStr . "|")
	{
		GuiControl,HotKeySet:ChooseString,KeySpec,%tempKeyStr%
		b_UseSpecKey:=1
	}Else{
		GuiControl,HotKeySet:,KeyKey,%tempKeyStr%
		;GuiControl,HotKeySet:Choose,KeySpec,1
	}
	If b_UseSpecKey
		GuiControl,HotKeySet:,KA_KeyChk,1
	tempKeyStr=
}
Gosub KA_SwitchSpecKey
dx:=dy:=tempStr:=""
Return

KA_KeyChk:	;;;�л�ʹ�������
b_UseSpecKey:=1-b_UseSpecKey
Gosub KA_SwitchSpecKey
if !b_UseSpecKey
	GuiControl,HotKeySet:Focus,KeyKey
Return

KA_Key_Save:
;;;�����ݼ�
If !b_UseSpecKey
{
	GuiControlGet,_key_Get,HotKeySet:,KeyKey
	_key_Get:=Trim(_key_Get)
	If (_key_Get=""){
		GuiControl,HotKeySet:Focus,KeyKey
		Return
	}
}Else{
	GuiControlGet,_key_Get,HotKeySet:,KeySpec
	If (_key_Get=""){
		GuiControl,HotKeySet:Focus,KeySpec
		Return
	}
	tempStr:=InStr(_key_Get,"/")
	If (tempStr>0)
		_key_Get:=SubStr(_key_Get,1,tempStr-1)
}
_key_Code:=_key_Title:=""
GuiControlGet,tempStr,HotKeySet:,Key_Ctrl
_key_Code .= tempStr?"^":"",_key_Title.=tempStr?"Ctrl+":""
GuiControlGet,tempStr,HotKeySet:,Key_Alt
_key_Code .= tempStr?"!":"",_key_Title.=tempStr?"Alt+":""
GuiControlGet,tempStr,HotKeySet:,Key_Shift
_key_Code .= tempStr?"+":"",_key_Title.=tempStr?"Shift+":""
GuiControlGet,tempStr,HotKeySet:,Key_Win
_key_Code .= tempStr?"#":"",_key_Title.=tempStr?"Win+":""
If !b_UseSpecKey And (_key_Code="")
{
	_key_Code:=_key_Title:=tempStr:=""
	GuiControl,HotKeySet:Focus,KeyKey
	SendInput ^a
	Return
}
_key_Title.=_key_Get
If !b_UseSpecKey
	StringLower,_key_Get,_key_Get
_key_Code.=_key_Get
If arr_KeysList.Haskey(_key_Code)
{
	Gui,HotKeySet:+OwnDialogs
	Msgbox,262192,��ݼ� �ظ�����,% "��ݼ��� " . _key_Title . "���Ѷ��壡`n���޸�Ϊһ��δ����Ŀ�ݼ���"
	GuiControl,HotKeySet:Focus,% b_UseSpecKey?"KeySpec":"KeyKey"
	If !b_UseSpecKey
		SendInput ^a
	_key_Code:=_key_Title:=tempStr:=""
	Return
}
Gosub HotKeySetGuiClose
Gui,%KS_MainID%:Default
Lv_GetText(tempStr,strKS_Row,2),Lv_Modify(strKS_Row,"COL1",_key_Title)
,arr_KeysList[_key_Code]:=tempStr,arr_KeysMap[tempStr]:=_key_Code
,_Is_KeyMod:=1
,_key_Code:=_key_Title:=tempStr:=""
Return

KA_Key_Cancel:
;;;�رձ༭����
HotKeySetGuiClose:
HotKeySetGuiEscape:
Gui,%KS_MainID%:-Disabled
Gui,HotKeySet:Destroy
Return

KA_SwitchSpecKey:
GuiControl,HotKeySet:Enable%b_UseSpecKey%,KeySpec
GuiControl,HotKeySet:Disable%b_UseSpecKey%,KeyKey
Return