#SingleInstance Force
#NoTrayIcon
#NoEnv

Menu,Tray,Icon,shell32.dll,-133
arr_Sample:=["8 + 8 =","88 + 8 =","88 + 88 =","8 + 8 + 8 =","88 + 8 + 8 =","8 + 8 + 8 + 8 =","88 + 8 + 8 + 8 ="],n_Check:=4,dL:=100
,str_Types:="1. 一位数加减一位数|2. 二位数加减一位数|3. 二位数加减二位数|4. 一位数连续计算（3数字）||5. 一位数与两位数连续计算（3数字）|6. 一位数连续计算（4数字）|7. 一位数与两位数连续计算（4数字）"
Gui,+HwndMain_ID +MinSize +Resize
Gui,Font,,微软雅黑
Gui,Font,s12
Gui,Add,Text,x15 y15,计算类型
Gui,Add,DropDownList,x90 y10 w300 AltSubmit gs_Op vs_Op,%str_Types%
Gui,Add,Button,y5 w120 Default gt_BtnSet vt_BtnSet,♦ 开始%A_Space%%A_Space%(F5)
Gui,Font,Bold
Gui,Add,Button,y5 w140 Disabled gt_BtnValid vt_BtnValid,√ 检查%A_Space%%A_Space%(Enter)
Gui,Font,Norm
Gui,Add,Button,y5 w120 Disabled gt_BtnRepeat vt_BtnRepeat,の 重做%A_Space%%A_Space%(F9)
Gui,Add,GroupBox,x10 y45 vs_Box,
Gui,Font,s20
Gui,Add,Text,Hidden r1 vt_Sample,8
Loop,20
{
	Gui,Add,Text,Hidden cblue Right vt_Val_Formula%A_Index%,
	Gui,Add,Edit,Hidden Number Center r1 w60 vt_Re%A_Index%,
	Gui,Add,Text,Hidden w60 Center vt_Valid%A_Index%,
}
Gui,Font,Bold s12,
Gui,Add,Text,vt_Info,按下回车键、F5 键或点击“开始”按钮答题
Gui,Font,s16
Gui,Add,Edit,y5 w80 c800000 ReadOnly Center vt_Tmr,00:00
Gui,Font,Norm s10
Gui,Add,Link,x560 y370 vt_ShowLog gt_ShowLog,<a>→ 历史记录</a>
Gui,Font,Norm s12
Gui,Add,ListBox,x10 h80 0x100 vt_Log Disabled,Ready
Gui,Show,% "w" A_ScreenWidth/1.35 "h" A_ScreenHeight/1.15,算术练习
b_Op:=3,nFlag:=1,_Is_On:=_Is_Log_On:=__Count:=0,_f_Log:=A_ScriptDir . "\Data\calcLog.log"
,d_Lw:=_GetLen("t_Sample")[1],dH:=d_Lh:=_GetLen("t_Sample")[2],dW:=d_Lw*StrLen(arr_Sample[n_Check]),Is_FirstRun:=1
Return

GuiSize:
GuiControl,movedraw,t_BtnRepeat,% "x" A_GuiWidth-130
GuiControl,movedraw,t_BtnValid,% "x" A_GuiWidth-275
GuiControl,movedraw,t_BtnSet,% "x" A_GuiWidth-400
GuiControl,movedraw,t_Tmr,% "x" A_GuiWidth/2-40
GuiControl,movedraw,s_Box,% "w" A_GuiWidth-20 "h" A_GuiHeight-145
GuiControl,movedraw,t_Log,% "y" A_GuiHeight-90 "w" A_GuiWidth-20
GuiControl,movedraw,t_ShowLog,% "x" A_GuiWidth-90 "y" A_GuiHeight-130
GuiControl,movedraw,t_Info,% "x" A_GuiWidth/2-_GetLen("t_Info")[1]/2 "y" A_GuiHeight/2-_GetLen("t_Info")[2]/2-60
w_W:=A_GuiWidth,h_W:=A_GuiHeight,ds:=(h_W-125-dH*10)/13,dy:=2*ds+45
Loop,20
{
	mx:=Floor(A_Index/2),my:=Mod(A_Index,2),dx:=(my=1)?(w_W-280-2*dW-dL)/2:((w_W+dL)/2-10)
	GuiControl,movedraw,t_Val_Formula%A_Index%,x%dx% y%dy%
	dx+=(dW+5)
	GuiControl,movedraw,t_Re%A_Index%,x%dx% y%dy%
	dx+=65
	GuiControl,movedraw,t_Valid%A_Index%,x%dx% y%dy%
	If (my=0)
		dy+=(dH+ds)
}
Return

s_Op:
GuiControlGet,n_Check,,s_Op
If !Is_FirstRun
	Gosub t_BtnSet
Return

s_Pop:
Menu,popMenu,Show
Return

F5::
t_BtnSet:
GuiControl,-Default,t_BtnSet
GuiControl,,t_BtnSet,♦ 出题%A_Space%%A_Space%(F5)
Gosub t_BtnRepeat
ds:=(h_W-125-dH*10)/13,dy:=2*ds+45,dW:=d_Lw*StrLen(arr_Sample[n_Check]),nCount:=1
Loop
{
	If (nCount>20)
		Break
	mx:=Floor(nCount/2),my:=Mod(nCount,2),dx:=(my=1)?(w_W-280-2*dW-dL)/2:((w_W+dL)/2-10),str_Re:=s_Re%nCount%:=""
	If n_Check In 2,3,5,7
		s_Val_1:=_MakeValue(2)
	Else
		s_Val_1:=_MakeValue(1)
	If (n_Check=3)
		s_Val_2:=_MakeValue(2)
	Else
		s_Val_2:=_MakeValue(1)
	Random,b_opt_1,0,1
	str_Re:=s_Val_1 . ((b_opt_1=0)?" + ":" - ") . s_Val_2
	If (b_opt_1=0)
		s_Re%nCount%:=s_Val_1+s_Val_2
	Else
		s_Re%nCount%:=s_Val_1-s_Val_2
	If n_Check In 4,5,6,7
	{
		s_Val_3:=_MakeValue(1)
		Random,b_opt_2,0,1
		str_Re .= ((b_opt_2=0)?" + ":" - ") . s_Val_3
		If (b_opt_2=0)
			s_Re%nCount%+=s_Val_3
		Else
			s_Re%nCount%-=s_Val_3
		If n_Check In 6,7
		{
			s_Val_4:=_MakeValue(1)
			Random,b_opt_3,0,1
			str_Re .= ((b_opt_3=0)?" + ":" - ") . s_Val_4
			If (b_opt_3=0)
				s_Re%nCount%+=s_Val_4
			Else
				s_Re%nCount%-=s_Val_4
		}
	}
	If (s_Re%nCount%<0)
		Continue
	GuiControl,,t_Val_Formula%nCount%,%str_Re%%A_Space%=
	GuiControl,movedraw,t_Val_Formula%nCount%,x%dx% w%dW% y%dy%
	dx+=(dW+5)
	GuiControl,movedraw,t_Re%nCount%,x%dx% y%dy%
	dx+=65
	GuiControl,movedraw,t_Valid%nCount%,x%dx% y%dy%
	nCount+=1
	If (my=0)
		dy+=(dH+ds)
}
GuiControl,Enable,t_BtnValid
GuiControl,Enable,t_BtnRepeat
_Is_On:=1
Return

t_BtnValid:
SetTimer,_Tmr_Count,Off
Gui,+OwnDialogs
MsgBox,262177,做完了,确定提交答案进行检查？
IfMsgBox,Cancel
{
	SetTimer,_Tmr_Count
	Return
}
nCount:=0
Loop,20
{
	GuiControlGet,tempStr,,t_Re%A_Index%
	tempStr=%tempStr%
	If (tempStr=s_Re%A_Index%)
	{
		Gui,Font,c00aa00 s20
		GuiControl,,t_Valid%A_Index%,✔
		nCount+=1
	}Else{
		Gui,Font,cRed s20
		GuiControl,,t_Valid%A_Index%,✖
	}
	GuiControl,Font,t_Valid%A_Index%
	GuiControl,Show,t_Valid%A_Index%
}
WinGetPos,,dY,,,ahk_id%Main_ID%
dY-=150
SplashImage,,% "b1 w700 fs14 cwf0f0f0 FM32 " . ((nCount=20)?"ct0000ff":"ctff0000") . " y" . ((dY<0)?0:dY),% "做对了 " nCount "/20 道题，" ((nCount=20)?"继续保持哦":"再接再厉，胆大心细"),% (nCount=20)?"你真棒！":"继续努力呀！",__WIN_CALC__,微软雅黑
;WinSet,TransColor,f0f0f0,__WIN_CALC__
SetTimer,NoSplash,-3500
SoundPlay,% A_ScriptDir . "\Data\" . ((nCount=20)?1:0) . ".wav"
FormatTime,tempStr,%A_Now%,yyyy/M/d HH:mm:ss
tempStr:="[" tempStr "]" A_Tab "[" RegexReplace(StrSplit(str_Types,"|")[n_Check],"^\d+\.\s*") "]" A_Space A_Space A_Space "用时 " _toTime(str_Tmr,0) "，做对 " nCount " 题，做错 " (20-nCount) " 题"
If _Is_On
{
	__Count+=1
	GuiControl,,t_log,(%__Count%)%A_Space%%A_Space%%tempStr%
	GuiControl,Choose,t_log,%__Count%
	FileAppend,%tempStr%`n,%_f_Log%,UTF-8-Raw
}
GuiControl,Enable,t_BtnSet
_Is_On:=0,tempStr:=""
Return

t_BtnRepeat:
SplashImage,Off
GuiControl,,t_Tmr,00:00
Loop,20
{
	GuiControl,Show,t_Val_Formula%A_Index%,
	GuiControl,,t_Re%A_Index%,
	GuiControl,Show,t_Re%A_Index%
	GuiControl,Hide,t_Valid%A_Index%
	GuiControl,Hide,t_Info
}
GuiControl,Enable,t_Log
If Is_FirstRun
{
	GuiControl,,t_Log,|
	Is_FirstRun:=0
}
GuiControl,Focus,t_Re1
_Is_On:=1,str_Tmr:=0
SetTimer,_Tmr_Count,1000
Return

_Tmr_Count:
str_Tmr+=1
GuiControl,,t_Tmr,% _toTime(str_Tmr)
Return

t_ShowLog:
Try
	Run,%_f_Log%
Catch{
	Gui,+OwnDialogs
	MsgBox,262192,错误,打开记录文件错误，请重试！
}
Return

NoSplash:
SplashImage,Off
Return

_toTime(s,b:=1){
	s1:=Floor(s/60),s2:=Mod(s,60)
	If !b
		Return s1 " 分 " s2 " 秒"
	Return Format("{:02}",s1) ":" Format("{:02}",s2)
}

_GetLen(s){
	GuiControlGet,d,Pos,%s%
	Return [dw,dh]
}

_MakeValue(s){
	Random,tempStr,1,9
	r:=tempStr,s-=1
	Loop,%s%
	{
		Random,tempStr,0,9
		r .= tempStr
	}
	Return r
}

#if WinActive("ahk_id " . Main_ID) And !_Is_On
Space::Gosub t_BtnSet
Return

#if WinActive("ahk_id " . Main_ID) And _Is_On
Enter::
NumPadEnter::
Gosub t_BtnValid
Return
Space::Return
Tab::Return
Left::
Up::
Right::
Down::
GuiControlGet,tempStr,FocusV
If RegexMatch(tempStr,"^t_Re(\d{1,2})$",s)
{
	If (A_ThisHotkey="Right"){
		If (s1=20)
			GuiControl,Focus,t_Re1
		Else
			SendInput {Tab}
	}Else If (A_ThisHotkey="Down"){
		If (s1=19)
			GuiControl,Focus,t_Re1
		Else If (s1=20)
			GuiControl,Focus,t_Re2
		Else
			SendInput {Tab 2}
	}Else If (A_ThisHotkey="Left"){
		If (s1=1)
			GuiControl,Focus,t_Re20
		Else
			SendInput +{Tab}
	}Else If (A_ThisHotkey="Up"){
		If (s1=1)
			GuiControl,Focus,t_Re19
		Else If (s1=2)
			GuiControl,Focus,t_Re20
		Else
			SendInput +{Tab 2}
	}
}
Return
F9::Gosub t_BtnRepeat
#If

GuiClose:
ExitApp