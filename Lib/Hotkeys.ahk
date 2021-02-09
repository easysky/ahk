; @title:	功能热键
; 本文件可直接编辑或使用自定义脚本进行配置
; Shift+Pause、Ctrl+Alt+Shift+Insert：禁用/恢复脚本，内置热键不支持修改
; ------------------
#w::	Gosub ahk_BrowseSelUrl			;浏览选中网址
#Del::	Gosub ahk_ClearClip				;清空剪贴板
;		Gosub ahk_CloseLCD				;关闭显示器
#k::	Gosub ahk_CloseLCDAndLockPC		;关闭显示器并锁定电脑
#`::	Gosub ahk_HiddenWinMan			;弹出隐藏窗口管理菜单
#h::	Gosub ahk_HideThisWin			;隐藏当前窗口
;		Gosub ahk_LockInput				;禁止键盘鼠标输入
;		Gosub ahk_LockPC				;锁定电脑
;		Gosub ahk_ReloadScript			;重启程序
#q::	Gosub ahk_SearchSelText			;搜索选中内容
#LButton::	Gosub ahk_ShowAppList		;弹出快速程序菜单
;		Gosub ahk_ShowExtendMenu		;弹出扩展功能与设置菜单
;		Gosub ahk_ShowMainMenu			;弹出系统主菜单
;		Gosub ahk_ShowSysContrl			;弹出系统控制管理菜单
^!+F12::	Gosub ahk_ToggleTrayIcon	;显示/隐藏程序托盘图标
#t::	Gosub ahk_TopOnThisWin			;活动窗口置顶
^!t::	Gosub ahk_TransparentThisWin	;活动窗口透明切换
^#Down::	Gosub ahk_VolumeDown		;减小音量
^#Up::	Gosub ahk_VolumeUp				;加大音量