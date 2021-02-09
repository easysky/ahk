; @title: 快速表达式计算器
; -------------------

#SingleInstance Force

Menu,Tray,Icon,shell32.dll,-242
Menu,Tray,NoStandard
Menu,Tray,Add,设置,cmd_Main
Menu,Tray,Add,
Menu,Tray,Add,重启,cmd_Main
Menu,Tray,Add,退出,cmd_Main
Menu,Tray,Default,1&
Menu,Tray,Click,1

Global _INI_PATH:=A_ScriptDir . "\Data\exScriptSet.ini"
arr_QCalOpt:=[],str_QcalVar:="i)(abs|round|ceil|floor|exp|sqrt|ln|log|sin|cos|tan|cot|sec|csc|asin|acos|atan|hex|bin|dech|decb)(.*)"
,last_Opt:=""
IniRead,tempStr,%_INI_PATH%,QCalc,Option,000000001014
If (tempStr="") Or (StrLen(tempStr)<12) Or (StrLen(tempStr)>13) Or RegexMatch(tempStr,"[^\d]")
	tempStr:="000000001014"
Loop,11
	arr_QCalOpt[A_Index]:=SubStr(tempStr,A_Index,1)
arr_QCalOpt[12]:=SubStr(tempStr,12)
If (arr_QCalOpt[12]<0) Or (arr_QCalOpt[12]>15)
	arr_QCalOpt[12]:=4
last_Opt:=tempStr,tempStr:=""		;获取计算函数
Gosub qcal_GetConst		;获取自定义常量
Gosub qcal_GetFormula	;获取自定义公式
Return

; --------------- 即时计算核心模块 -----

Do_Calc:
calc_Input:=getExp()
If (calc_Input="")
	Return
If (SubStr(calc_Input,1,6)=":qcalc") Or (SubStr(calc_Input,1,3)=":qc")
{
	SendInput {Home}+{End}{BackSpace}
	Is_Qcal_DT:=1
	Gosub QCalc_Set
	Return
}
tempStr:=InStr(calc_Input,"=")
If (tempStr>0){
	If arr_QCalOpt[1]
	{
		getStr0:=StrLen(SubStr(calc_Input,tempStr))
		SendInput {BackSpace %getStr0%}
	}
	calc_Input:=SubStr(calc_Input,1,tempStr-1),getStr0:=""
}
calc_Input:=RegExReplace(calc_Input,"\s"),Is_Error:=0

If arr_QCalOpt[8] And RegExMatch(calc_Input,"(\bsin|\bcos|\btan|cot|sec|csc)") And !RegExMatch(calc_Input,"(\bsin|\bcos|\btan|cot|sec|csc)\(")
	calc_Output:="[Err4]",Is_Error:=1
If !Is_Error
{
	If RegExMatch(calc_Input,"\w+\(")
		calc_Input:=ExplainFormula(calc_Input)
	SetFormat,FloatFast,0.15
	calc_Output:=Eval(calc_Input),Re_Format(calc_Output)	;对计算结果进行格式化
	SetFormat,FloatFast,%last_FF%
}

If arr_QCalOpt[1]
{
	SendInput {Raw}=
	if arr_QCalOpt[2]
		SendInput `n
}
SendInput %calc_Output%
If arr_QCalOpt[5] And !Is_Error
	Clipboard:=calc_Output
if arr_QCalOpt[1] and !arr_QCalOpt[2]
{
	if arr_QCalOpt[3]
	{
		SendInput `n
		if arr_QCalOpt[4] And !Is_Error
			SendInput %calc_Output%
	}
}
calc_Input:=calc_Output:=tempStr:=Is_Error:=""
Return

#if arr_QCalOpt[10]
Ctrl::
If (A_ThisHotkey=A_PriorHotkey) and (A_TimeSincePriorHotkey<300)
	GoSub Do_Calc
Return
#if

#if arr_QCalOpt[11]
~NumpadAdd::
KeyWait,NumpadEnter,D T1
if !ErrorLevel
{
	SendInput {BS}{BS}
	GoSub Do_Calc
}
Return
#if

#if arr_QCalOpt[9]
;:?o:=::
;GoSub Do_Calc
;Return
~=::
If (A_ThisHotkey=A_PriorHotkey) and (A_TimeSincePriorHotkey<300)
	GoSub Do_Calc
Return
Return
#if

;------------- 即时计算公用过程与函数 --------------

qcal_GetConst:		;获取自定义常量
arr_Constant:=[],str_QcalConst:=""
IniRead,tempStr,%_INI_PATH%,Qcalc,Constant,%A_Space%
tempStr=%tempStr%
If (tempStr<>""){
	Loop,parse,tempStr,`,
	{
		getStr0:=StrReplace(A_LoopField,"A_Space")
		If (getStr0="")
			Continue
		If RegexMatch(getStr0,"i)^(_?[a-z]+\w*):(-?\d+\.?\d+)$",getStr)
		{
			If (getStr1<>"pi") And (getStr1<>"e") And (getStr1<>"ep")
				arr_Constant[getStr1]:=getStr2,str_QcalConst .= getStr1 . "|"
		}
	}
	Sort,str_QcalConst,D| R
}
tempStr:=getStr0:=getStr1:=getStr2:=""
Return

qcal_GetFormula:		;获取自定义公式
arr_Formula:=[],str_QcalFormula:=""
IniRead,tempStr,%_INI_PATH%,QCalc,Formula,%A_Space%
tempStr=%tempStr%
If (tempStr<>""){
	Loop,Parse,tempStr,|
	{
		If RegexMatch(StrReplace(trim(A_LoopField),A_Space),"i)^(_?[a-z]+\w*)\(([a-z,]+)\):(.+)$",getStr)
			arr_Formula[getStr1]:=[getStr2,getStr3],str_QcalFormula .= getStr1 . "(|"
			;arr_Formula["acd"]:=["a,b,c","pi*a^2/b+c*15"]
	}
}
tempStr:=getStr1:=getStr2:=getStr3:=""
Return

Eval(x)	{
	Global str_QcalConst,arr_Constant,arr_QCalOpt
	x:=RegExReplace(x,"([\d\)])\-","$1#"),tempStr:="((pi|" . Trim(str_QcalConst,"|") . "))\-",x:=RegExReplace(x,tempStr,"$1#"),tempStr:=""
	;将数字或）后的“-”转换为“#”	;将常量后的“-”转换为“#”
	x:=StrReplace(StrReplace(x,"pi","3.1415926535897932"),"ep","2.7182818284590452")
	If (str_QcalConst<>""){
		Loop,Parse,str_QcalConst,|
		{
			If (A_LoopField="")
				Continue
			x:=StrReplace(x,A_LoopField,arr_Constant[A_LoopField])
		}
	}
	If arr_QCalOpt[8]
		x:=RegexReplace(x,"(\bsin|\bcos|\btan|cot|sec|csc)\(([^\)]+)\)","$1(($2)*0.017453292519943)"),x:=RegexReplace(x,"(asin|acos|atan)","57.295779513082323*$1")
	Loop
	{
		If !RegExMatch(x,"(.*)\(([^\(\)]*)\)(.*)",y)	;如果匹配不到括号“()”则停止计算	;由内侧括号往外侧括号计算
			Return Eval_(x)
		x:=y1 . Eval_(y2) . y3	;否则用括号内的计算结果代入原式继续计算
	}
}

Eval_(x){
	Global str_QcalVar
	RegExMatch(x,"(.*)(\+|\#)(.*)",y)		;匹配加、减
	IfEqual,y2,+,Return Eval_(y1)+Eval_(y3)	;加
	IfEqual,y2,#,Return Eval_(y1)-Eval_(y3)	;减

	RegExMatch(x,"(.*)(\*|\/|\%)(.*)",y)		;匹配乘、除、取余数
	IfEqual,y2,*,Return Eval_(y1)*Eval_(y3)	;乘
	IfEqual,y2,/,Return Eval_(y1)/Eval_(y3)	;除
	IfEqual,y2,`%,Return Mod(Eval_(y1),Eval_(y3))	;取余数

	RegExMatch(x,"(.*\d)(e)(.*)",y)	;匹配常用指数
	IfEqual,y2,e,Return Eval_(y1)*10**Eval_(y3)

	StringGetPos,i,x,^,R	;匹配幂函数
	IfGreaterOrEqual,i,0,Return Eval_(SubStr(x,1,i)) ** Eval_(SubStr(x,2+i))

	StringGetPos,i,x,!,R	;匹配阶乘
	if (i>0){
		getStr0:=SubStr(x,1,i),getStr1:=1
		;If InStr(getStr0,".") Or InStr(getStr0,"-") Or (getStr0>20)
		;	Return "[Err7]"
		Loop %getStr0%
			getStr1 *= A_index
		Return getStr1
	}

	;匹配其他函数
	If !RegExMatch(x,str_QcalVar,y)
		Return x
	If (y1="hex")	;10进制转16进制
		Return ToBase(y2,16)
	If (y1="dech"){	;16进制转10进制
		y2=%y2%
		StringLower,y2,y2
		If (SubStr(y2,1,2)="0x")
			y2:=SubStr(y2,3)
		;If RegexMatch(y2,"i)[^\da-f]")
		;	Return "[Err5]"
		Return ToBase("0x" . y2,10)
	}
	If (y1="bin")	;10进制转2进制
		Return ToBase(y2,2)
	if (y1="decb"){	;2进制转10进制
		;If RegExMatch(y2,"[^01]")
		;	Return "[Err6]"
		Return Bin2Dec(y2)
	}
	IfEqual y1,cot,Return 1/tan(Eval_(y2))
	IfEqual y1,sec,Return 1/cos(Eval_(y2))
	IfEqual y1,csc,Return 1/sin(Eval_(y2))
	Return %y1%(Eval_(y2))
}

ExplainFormula(s){
	Global str_QcalFormula
	If !RegexMatch(s,"i)" . StrReplace(str_QcalFormula,"(","\(") . "abs\(|round\(|ceil\(|floor\(|exp\(|sqrt\(|ln\(|log\(|sin\(|cos\(|tan\(|cot\(|sec\(|csc\(|asin\(|acos\(|atan\(|hex\(|bin\(|dech\(|decb\(")
		Return "[Err1-1]"
	b:=0
	Loop,Parse,str_QcalFormula,|
	{
		If (A_LoopField="")
			Continue
		If b
			Break
		Loop
		{
			s1:=InStr(s,A_LoopField)	;s1——表达式中是否存在已定义的公式名
			If (s1=0)
				Break
			;S2:公式参数列表，s1:公式名
			s2:=SubStr(s,s1+StrLen(A_LoopField),InStr(s,")",False,s1)-s1-StrLen(A_LoopField))
			,s1:=SubStr(A_LoopField,1,-1),s3:=ParseFormula(s1,s2)
			If InStr(s3,"[Err",1)
			{
				s:=s3,b:=1
				Break
			}Else
				s:=StrReplace(s,s1 . "(" . s2 . ")","(" . s3 . ")")
		}
	}
	Return s
}

ParseFormula(s1,s2){	;s1——公式名 f; s2——当前参数列表
;	arr_Formula["acd"]:=["a,b,c","pi*a^2/b+c*15"]
	Global arr_Formula
	;1——公式是否定义
	If !arr_Formula.haskey(s1) Or (arr_Formula[s1][1]="") Or (arr_Formula[s1][2]="")
		Return "[Err1-0]"
	;2——参数的数量核对
	s2:=StrReplace(s2,A_Space),t1:=StrReplace(s2,",",,n1),t2:=StrReplace(arr_Formula[s1][1],",",,n2)
	If (n1<>n2)
		Return "[Err2]"
	;3——是否有空参数，若无则把参数代入到公式
	s1:=arr_Formula[s1][2],r:=0
	Loop,Parse,s2,`,
	{
		If (A_LoopField=""){
			r:=1
			Break
		}
		t:=SubStr("abcdefghijklmnopqrstuvwxyz",A_Index,1),s1:=StrReplace(s1,t,A_LoopField)
	}
	If r
		Return "[Err3]"
	Return s1
}

Re_Format(ByRef s){
	;处理计算结果	s0——正负号；	s1——整数位；	s2——小数位；	s3——指数
	Global arr_QCalOpt
	s0=
	If (SubStr(s,1,1)="-")
		s0:="-",s:=SubStr(s,2)
	If InStr(s,".")	;小数
	{
		Loop,Parse,s,.
			s%A_index%:=A_LoopField	;s1:整数部分	;s2:小数部分
		s2:=RegexReplace(s2,"0+$"),s3:=0
		If (s2=""){	;小数部分为空，变成了整数
			If arr_QCalOpt[6] And (StrLen(s1)>4)
				s1:=Accuracy(SubStr(s1,1,1) . "." . SubStr(s1,2)) . "e" . (StrLen(s1)-1)
			s:=s0 . s1,s0:=s1:=s2:=""
			Return
		}
		If arr_QCalOpt[6]
		{
			If (StrLen(s1)>4)
				s3:=StrLen(s1)-1,s2:=SubStr(s1,2) . s2,s1:=SubStr(s1,1,1)
			If (s1="0") And (RegExMatch(s2,"P)^(0{3,})[1-9]+",s)>0)	;匹配诸如 0.00004561238
				s1:=SubStr(s2,sLen1+1,1),s2:=SubStr(s2,sLen1+2),s3:=(sLen1+1)*-1
		}
		s:=Accuracy(s1 . "." . s2) . ((arr_QCalOpt[6] And (s3<>0))?("e" . s3):"")
	}Else{	;整数
		If arr_QCalOpt[6] And (StrLen(s)>4)
			s:=Accuracy(SubStr(s,1,1) . "." . SubStr(s,2)) . "e" . (StrLen(s)-1)
	}
	s:=s0 . s,s0:=s1:=s2:=s3:=sLen1:=""
}

Accuracy(s){
	Global arr_QCalOpt
	If arr_QCalOpt[7]
		s:=Round(s,arr_QCalOpt[12])
	If InStr(s,".")
		s:=RegexReplace(s,"\.?0+$")
	Return s
}

getExp(){	;获取表达式
	Global arr_QCalOpt
	if !arr_QCalOpt[5]
		t:=ClipboardAll
	Clipboard=
	if arr_QCalOpt[1]
		SendInput {End}+{Home}^c{End}
	else
		SendInput {End}+{Home}^x
	ClipWait,0.5
	r:=ErrorLevel?"":Clipboard
	if !arr_QCalOpt[5]
		Clipboard:=t,t:=""
	Return r
}

; --------------- 即时计算设置模块 -----

QCalc_Set:
Gui,+HwndQCalc_ID
Gui,Font,,Tahoma
Gui,Font,,微软雅黑
Gui,Add,Tab,x0 y0 w375 h455 ,1 - 选项|2 - 说明
Gui,Add,GroupBox,x10 y40 w350 h185 ,输入/输出格式
getStr1:=arr_QCalOpt[1]
Gui,Add,CheckBox,x40 y70 Checked%getStr1% vqcal_Reserve,保留输入的表达式(&P)
getStr1:=arr_QCalOpt[2]
Gui,Add,CheckBox,x40 y100 Checked%getStr1% gqcal_ReInNewline vqcal_ReInNewline,在新行中显示计算结果(&N)【* 对单行文本框无效】
getStr2:=arr_QCalOpt[3]
Gui,Add,CheckBox,x40 y130 Disabled%getStr1% Checked%getStr2% gqcal_AutoWrap vqcal_AutoWrap,自动开始新行(&I)【* 对单行文本框无效】
getStr1:=(!getStr1 And getStr2)?0:1,getStr2:=arr_QCalOpt[4]
Gui,Add,CheckBox,x60 y160 Checked%getStr2% Disabled%getStr1% vqcal_AutoInsert,在新行中插入上次计算结果(&L)
getStr1:=arr_QCalOpt[5]
Gui,Add,CheckBox,x40 y190 Checked%getStr1% vqcal_AutoCopy,自动复制上次计算结果到剪贴板(&C)

Gui,Add,GroupBox,x10 y230 w350 h125,计算结果
getStr1:=arr_QCalOpt[6]
Gui,Add,CheckBox,x40 y260 Checked%getStr1% vqcal_ENotation,使用科学计数法(&E)
getStr1:=arr_QCalOpt[7],getStr2:=1-getStr1
Gui,Add,CheckBox,x40 y290 Checked%getStr1% gqcal_AccuChk vqcal_AccuChk,保留小数位数(&A)
Gui,Add,Edit,x155 y286 w45 h25 Number Disabled%getStr2% vqcal_AccuBox,
Gui,Add,UpDown,Range0-15 Disabled%getStr2% vqcal_AccuUD,% arr_QCalOpt[12]
getStr1:=arr_QCalOpt[8]
Gui,Add,CheckBox,x40 y320 Checked%getStr1% vqcal_UseDegrees,三角函数使用角度(&D)
getStr1:=getStr2:=""

Gui,Add,GroupBox,x10 y360 w350 h70 ,自定义
Gui,Add,Button,x30 y390 w110 gqcal_CustomConst,常量(&T)
Gui,Add,Button,x145 y390 w110 gqcal_CustomFormula,公式(&F)
Gui,Add,Button,x260 y390 w80 gqcal_Key,计算按键(&K)

Gui,Tab,2
Gui,Add,Edit,x0 y30 w370 h405 ReadOnly,
(
在任意可编辑区域输入任意表达式，按下计算键即可进行计算。
» 自动忽略表达式中的所有空格和制表符
» 表达式必须处于单独一行
`n—————————— 运算符和函数 ——————————
`n» 函数/常量名不区分大小写
» 如计算结果为空，请检查运算符/函数的拼写和参数使用范围。
`n» 基本运算
`n+ - * /%A_Tab%%A_Tab% 加减乘除四则运算
x`%y%A_Tab%%A_Tab% x 除以 y 的余数
xey%A_Tab%%A_Tab% x 乘以 10 的 y 次方
x^y%A_Tab%%A_Tab% x 的 y 次方
x!%A_Tab%%A_Tab% x 的阶乘（x 为自然数且不大于20）
`n» 基本函数
`nAbs(x)%A_Tab%%A_Tab% x 的绝对值
Exp(x)%A_Tab%%A_Tab% e 的 x 次方
Sqrt(x)%A_Tab%%A_Tab% x 的平方根
Log(x)%A_Tab%%A_Tab% x 的对数（底数为 10）
Ln(x)%A_Tab%%A_Tab% x 的自然对数（底数为 e）
Round(x)%A_Tab%%A_Tab% x 四舍五入后取整
Ceil(x)%A_Tab%%A_Tab% x 向上取整
Floor(x)%A_Tab%%A_Tab% x 向下取整
`n» 三角函数
`nSin(x)%A_Tab%%A_Tab% x 的正弦
Cos(x)%A_Tab%%A_Tab% x 的余弦
Tan(x)%A_Tab%%A_Tab% x 的正切
Cot(x)%A_Tab%%A_Tab% x 的余切
Sec(x)%A_Tab%%A_Tab% x 的正割
Csc(x)%A_Tab%%A_Tab% x 的正割
ASin(x)%A_Tab%%A_Tab% x 的反正弦值
ACos(x)%A_Tab%%A_Tab% x 的反余弦值
ATan(x)%A_Tab%%A_Tab% x 的反正切值
`n# Sin,Cos,Tan,Cot,Sec,Csc 当 x 为角度时需包含在括号内！
`n» 进制转换函数
`nHex(x)%A_Tab%%A_Tab%十进制转十六进制
Bin(x)%A_Tab%%A_Tab%十进制转二进制
DecH(x)%A_Tab%%A_Tab%十六进制转十进制
DecB(x)%A_Tab%%A_Tab%二进制转十进制
`n# Hex,Bin 的参数必须为正整数！
`n» 自定义常量:
`n. 常量名只能由数字、字母和下划线组成
. 常量名不能以数字开头
. 圆周率 Pi= 3.1415926535897932
. 自然常数 e= 2.7182818284590452（名称为 eP）
. 常量名不能为字母 e、Pi、eP
`n» 自定义公式:
`n. 公式名只能由数字、字母和下划线组成
. 公式名不能以数字开头
. 每个公式最多包含 26 个由英文字母表示的参数
. 参数应按 a～z的排列顺序依次指定
. 公式内的运算符必须与程序运算符一致
`n`n——————————— 按键定义 ———————————
`n» 内置三组计算按键：[=]+[=]、[Ctrl]+[Ctrl] 以及 [NumpadAdd]+[NumpadEnter]，可随时切换
» 如计算按键在其他程序中已被注册成热键，原有热键被覆盖
`n`n——————————— 其他 ———————————
`n注意: 本程序支持 15 位精度的浮点数计算。
为保证计算结果的准确性，请不要用于过“大”的数值计算！
`n» 输入表达式“:qcalc”或“:qc”（不含双引号）进入设置。
`n» 错误代码“Err[x]”含义:
`n 1 —— 公式或函数未定义
 2 —— 参数数量不匹配
 3 —— 公式或函数有空参数
 4 —— 三角函数以角度计算时参数需带括号
)
Gui,Show,w370 h435,即时计算 设置
Menu,qcal_Menu,Add,[=]+[=],cmd_qcal
Menu,qcal_Menu,Add,[Ctrl]+[Ctrl],cmd_qcal
Menu,qcal_Menu,Add,[NumpadAdd]+[NumpadEnter],cmd_qcal
Menu,qcal_Menu,% arr_QCalOpt[9]?"Check":"UnCheck",[=]+[=]
Menu,qcal_Menu,% arr_QCalOpt[10]?"Check":"UnCheck",[Ctrl]+[Ctrl]
Menu,qcal_Menu,% arr_QCalOpt[11]?"Check":"UnCheck",[NumpadAdd]+[NumpadEnter]
Return

qcal_ReInNewline:
GuiControlGet,tempStr,,qcal_ReInNewline
GuiControl,% tempStr?"Disable":"Enable",qcal_AutoWrap
GuiControlGet,getStr1,,qcal_AutoWrap
GuiControl,% (!tempStr & getStr1)?"Enable":"Disable",qcal_AutoInsert
tempStr:=getStr1:=""
Return

qcal_AutoWrap:
GuiControlGet,tempStr,,qcal_AutoWrap
GuiControl,% tempStr?"Enable":"Disable",qcal_AutoInsert
tempStr=
Return

qcal_AccuChk:
GuiControlGet,tempStr,,qcal_AccuChk
GuiControl,% tempStr?"Enable":"Disable",qcal_AccuBox
GuiControl,% tempStr?"Enable":"Disable",qcal_AccuUD
tempStr=
Return

qcal_Key:
Menu,qcal_Menu,Show
Return

cmd_Main:
If (A_ThisMenuItemPos=1)
	Gosub QCalc_Set
Else If (A_ThisMenuItemPos=3)
	Reload
Else If (A_ThisMenuItemPos=4)
	ExitApp
Return

cmd_qcal:
Menu,qcal_Menu,ToggleCheck,%A_ThisMenuItem%
arr_QCalOpt[A_ThisMenuItemPos+8]:=1-arr_QCalOpt[A_ThisMenuItemPos+8]
Return

qcal_CustomConst:
Is_QCalCustomConst:=1
Gosub Qcal_CustomEdit
Return

qcal_CustomFormula:
Is_QCalCustomConst:=0
Gosub Qcal_CustomEdit
Return

GuiClose:
GuiEscape:
GuiControlGet,tempStr,,qcal_Reserve
arr_QCalOpt[1]:=tempStr
GuiControlGet,tempStr,,qcal_ReInNewline
arr_QCalOpt[2]:=tempStr
GuiControlGet,tempStr,,qcal_AutoWrap
arr_QCalOpt[3]:=tempStr
GuiControlGet,tempStr,,qcal_AutoInsert
arr_QCalOpt[4]:=tempStr
GuiControlGet,tempStr,,qcal_AutoCopy
arr_QCalOpt[5]:=tempStr
GuiControlGet,tempStr,,qcal_ENotation
arr_QCalOpt[6]:=tempStr
GuiControlGet,tempStr,,qcal_AccuChk
arr_QCalOpt[7]:=tempStr
GuiControlGet,tempStr,,qcal_UseDegrees
arr_QCalOpt[8]:=tempStr
GuiControlGet,tempStr,,qcal_AccuBox
If (tempStr="") Or RegexMatch(tempStr,"[^\d]") Or (tempStr<0) Or (tempStr>15)
	tempStr:=4
arr_QCalOpt[12]:=tempStr,tempStr:=""
Loop,12
	tempStr .= arr_QCalOpt[A_Index]
If (tempStr<>last_Opt){
	IniWrite,%tempStr%,%_INI_PATH%,QCalc,Option
	last_Opt:=tempStr
}
tempStr=
Gui,Destroy
Return

;------------- 自定义常量和公式 --------------

Qcal_CustomEdit:
tempStr=
If Is_QCalCustomConst
{
	For getStr1,getStr2 In arr_Constant
		tempStr.= "`n" . getStr1 . "=" . getStr2
}Else{
	For getStr1,getStr2 In arr_Formula
		tempStr.= ((A_Index=1)?"":"`n") . getStr1 . "(" getStr2[1] ")=" . getStr2[2]
}
tempStr:=(Is_QCalCustomConst?"Pi=3.1415926535897932 [内置]`nep=2.7182818284590452 [内置]":"") . tempStr
Gui,QCal_CustomWin:New
Gui,1:+Disabled
Gui,QCal_CustomWin:-MinimizeBox +HwndQCTW_ID +Owner%QCalc_ID%
Gui,QCal_CustomWin:Font,,Tahoma
Gui,QCal_CustomWin:Font,,微软雅黑
Gui,QCal_CustomWin:Add,Button,x5 y410 w80 h25 gqBtn_Do vCustom_Btn_Info,说明(&I)
Gui,QCal_CustomWin:Add,Button,x210 y410 w100 h25 gqBtn_Do vCustom_Btn_Save,保存(&S)
Gui,QCal_CustomWin:Add,Button,x315 y410 w80 h25 gqBtn_Do vCustom_Btn_Close,关闭(&C)
Gui,QCal_CustomWin:Font,s12,Fixedsys
Gui,QCal_CustomWin:Add,Edit,x0 y0 w400 h400 vCustom_Box,%tempStr%
Gui,QCal_CustomWin:Show,w400 h445,% "自定义" . (Is_QCalCustomConst?"常量":"公式")
tempStr:="",Is_BoxInfo:=0
Return

qBtn_Do:
If (A_GuiControl="Custom_Btn_Info"){
	Is_BoxInfo:=1-Is_BoxInfo
	If Is_BoxInfo
	{
		GuiControlGet,Custom_Value,QCal_CustomWin:,Custom_Box
		GuiControl,QCal_CustomWin:+ReadOnly,Custom_Box
		GuiControl,QCal_CustomWin:,Custom_Box,% "请参照以下格式自定义" . (Is_QCalCustomConst?"常量":"公式") . "，每行一个。`n注意:`n`n1. " . (Is_QCalCustomConst?"常量":"公式") . "名只能由数字、字母和下划线组成`n2. " . (Is_QCalCustomConst?"常量":"公式") . "名不能以数字开头`n3. " . ((Is_QCalCustomConst)?"圆周率 Pi 的值已内置，无需重复定义`n4. 自然常数 ep 的值已内置，无需重复定义`n5. 字母 e 为运算符，自动忽略 e 的常量定义`n`n示例:`nPP=9876 `nsp=2.71828":"每个公式最多包含 26 个由英文字母表示的参数`n4. 参数应按 a~z 的排列顺序依次指定`n`n示例:`nf(a,b)=a+b`ng(a,b,c,d)=a*(b+c)/d")
		GuiControl,QCal_CustomWin:,Custom_Btn_Info,返回(&I)
		GuiControl,QCal_CustomWin:Disable,Custom_Btn_Save
		GuiControl,QCal_CustomWin:Disable,Custom_Btn_Close
	}Else{
		GuiControl,QCal_CustomWin:-ReadOnly,Custom_Box
		GuiControl,QCal_CustomWin:,Custom_Box,%Custom_Value%
		GuiControl,QCal_CustomWin:,Custom_Btn_Info,说明(&I)
		GuiControl,QCal_CustomWin:Enable,Custom_Btn_Save
		GuiControl,QCal_CustomWin:Enable,Custom_Btn_Close
	}
}Else If (A_GuiControl="Custom_Btn_Save")
	Gosub qCustom_Save
Else If (A_GuiControl="Custom_Btn_Close")
	Gosub QCal_CustomWinGuiClose
Return

QCal_CustomWinGuiClose:
QCal_CustomWinEscape:
Gui,1:-Disabled
Gui,QCal_CustomWin:Destroy
Return

qCustom_Save:
GuiControlGet,tempStr,QCal_CustomWin:,Custom_Box
tempStr:=Trim(tempStr)
If Is_QCalCustomConst
	arr_Constant:=[],str_QcalConst:=""
Else
	arr_Formula:=[],str_QcalFormula:=""
Loop,Parse,tempStr,`n
{
	getStr0:=StrReplace(Trim(A_LoopField),A_Space)
	If (getStr0="")
		Continue
	If Is_QCalCustomConst	;常量
	{
		If InStr(getStr0,"Pi=") Or InStr(getStr0,"ep=")
			Continue
		If RegexMatch(getStr0,"i)^(_?[a-z]+\w*)=(-?\d+\.?\d+)$",getStr)
		{
			If getStr1 Not In pi,ep,e
				arr_Constant[getStr1]:=getStr2,str_QcalConst .= getStr1 . "|"
		}
	}Else{	;公式
		If RegexMatch(getStr0,"i)^(_?[a-z]+\w*)\(([a-z,]+)\)=(.+)$",getStr)
			arr_Formula[getStr1]:=[getStr2,getStr3],str_QcalFormula .= getStr1 . "(|"
	}
}
tempStr=
If Is_QCalCustomConst
{
	For s1,s2 In arr_Constant
		tempStr.=((A_Index=1)?"":",") s1 ":" s2
}Else{
	For s1,s2 In arr_Formula
		tempStr.=((A_Index=1)?"":"|") s1 "(" s2[1] "):" s2[2]
}
If (tempStr="")
	IniDelete,%_INI_PATH%,QCalc,% Is_QCalCustomConst?"Constant":"Formula"
Else
	IniWrite,%tempStr%,%_INI_PATH%,QCalc,% Is_QCalCustomConst?"Constant":"Formula"
If Is_QCalCustomConst
	Sort,str_QcalConst,D| R
Gui,QCal_CustomWin:+OwnDialogs
MsgBox,262208,操作成功,% "已成功保存对" .  (Is_QCalCustomConst?"常量":"公式") . "的修改！"
tempStr:=getStr0:=getStr1:=getStr2:=getStr3:=s1:=s2:=""
Gosub QCal_CustomWinGuiClose
Return

#if WinActive("ahk_id " . QCTW_ID)
^s::
If !Is_BoxInfo
	Gosub qCustom_Save
Return
#if

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