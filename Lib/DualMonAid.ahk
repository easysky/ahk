; @title:	双显示器切换优化
; -------------------------

_init_DualMonAid()
{
	Global arr_Mon
	SysGet,Mon1,MonitorWorkArea,1
	SysGet,Mon2,MonitorWorkArea,2
	arr_Mon:=[[0,0,Mon1right,Mon1bottom],[Mon2left,Mon2top-2,Mon2right-Mon2left,Mon2bottom-Mon2top+4]]
	_LIB_COUNT+=1	;组件计数
	Menu,_Menu_LIBSET,Add,%_LIB_COUNT% - 双显示器切换优化,DualMonAid_Set	;组件设置菜单
}

DualMonAid_Set:
Gui,+OwnDialogs
MsgBox,262208,快捷功能说明,
(
Ctrl+Alt+Right%A_Tab%活动窗口移到2#显示器
Ctrl+Alt+Left%A_Tab%活动窗口移到1#显示器
Ctrl+Alt+Up%A_Tab%活动窗口最大化/还原
Ctrl+Alt+Down%A_Tab%重设活动窗口尺寸和位置
Ctrl+Alt+左键%A_Tab%重设鼠标下窗口尺寸和位置
`n注：仅当窗口超出1#或2#显示器范围时，重设窗口功能有效！
)
Return

#If _check_Mon() And IsObject(sWin:=_check_Win())
^!Lbutton::Gosub _Win_Resize
#if

#If _check_Mon() And IsObject(sWin:=_check_Win(0))
^!Right::
WinWait,% "Ahk_Id " sWin[1]
If !sWin[2]
	Return	;仅当前窗口左边缘在1#显示器时有效
If sWin[6]
	WinRestore
WinGetPos,,,dW,dH
If (dW>=arr_Mon[2][3])
	dW:=arr_Mon[2][3]-200
If (dH>=arr_Mon[2][4])
	dH:=arr_Mon[2][4]-100
WinMove,,,arr_Mon[2][1]+(arr_Mon[2][3]-dW)/2,arr_Mon[2][2]+(arr_Mon[2][4]-dH)/2,dW,dH
If sWin[6]
{
	If sWin[7]
		Gosub _gCad_Resize
	Else
		WinMaximize
}
Return

^!Left::
WinWait,% "Ahk_Id " sWin[1]
If !sWin[2]
{	;当前窗口左边缘在2#显示器
	If sWin[6]
		WinRestore
	WinGetPos,,,dW,dH
	If (dW>=arr_Mon[1][3])
		dW:=arr_Mon[1][3]-200
	If (dH>=arr_Mon[1][4])
		dH:=arr_Mon[1][4]-100
	WinMove,,,(arr_Mon[1][3]-dW)/2,(arr_Mon[1][4]-dH)/2,dW,dH
	If sWin[6]
		Gosub _Win_MaxSize
}
Return

^!Up::
WinWait,% "Ahk_Id " sWin[1]
If sWin[6]
	WinRestore
Else
	Gosub _Win_MaxSize
Return

^!Down::Gosub _Win_Resize
#If

_Win_MaxSize:
If sWin[7] And !sWin[2]
	Gosub _gCad_Resize
Else
	WinMaximize
Return

_Win_Resize:
If sWin[6] Or !sWin[5]
	Return
WinWait,% "Ahk_Id " sWin[1]
WinGetPos,,,dW,dH
If !sWin[2] And ((sWin[3]+dW>arr_Mon[2][3]) Or (sWin[4]+dH>arr_Mon[2][4]))	;当前窗口在2#显示器且超出2#显示器范围
{
	If sWin[7]
		Gosub _gCad_Resize
	Else
		WinMove,,,arr_Mon[2][1]+150,arr_Mon[2][2]+100,arr_Mon[2][3]-300,arr_Mon[2][4]-200
}
;当前窗口在1#显示器且超出1#显示器范围
If sWin[2] And ((sWin[3]+dW>arr_Mon[1][3]+20) Or (sWin[4]+dH>arr_Mon[1][4]+20))
{
	If sWin[5]
		WinMove,,,100,50,arr_Mon[1][3]-200,arr_Mon[1][4]-100
	Else
		WinMove,,,100,50
}
Return

_gCad_Resize:
WinMove,,,arr_Mon[2][1],arr_Mon[2][2],arr_Mon[2][3],arr_Mon[2][4]
Return

_check_Win(b:=1){
;判断窗口信息返回 0 或数组[窗口id,窗口位置,X,Y,W,H,是否可调节大小,是否最大化]
;b：1——检查鼠标下窗口；2——检查活动窗口
	Global arr_Mon
	If b
		MouseGetPos,,,sID
	Else
		WinGet,sID,ID,A
	WinGetClass,sCls,Ahk_Id %sID%
	If sCls In Progman,Button,WorkerW,#32769,#32770,Shell_TrayWnd,bbLeanBar,TXGuiFoundation	;屏蔽特殊窗口
		Return 0
	WinGet,w,Style,Ahk_Id %sID%
	Is_Resize:=(w & 0x40000)?1:0,Is_WinMax:=0
	If Is_Resize
	{
		WinGet,w,MinMax,Ahk_Id %sID%
		Is_WinMax:=(w=1)?1:0
	}
	WinGetPos,dX,dY,,,Ahk_Id %sID%
	Is_OnLeft:=(dX>arr_Mon[2][1]-10)?0:1
	If Is_WinMax
		dY:=0
	WinGet,w,ProcessName,Ahk_Id %sID%
	Return [sID,Is_OnLeft,dX,dY,Is_Resize,Is_WinMax,(w="gcad.exe")?1:0]
}

_check_Mon(){
	;判断是否双显示器
	SysGet,MonCount,80
	If (MonCount=1)
		Return 0
	Return 1
}