# 关于 zBox.ahk
---
### 概述

 **zBox**  是用 AHK 开发的自用脚本组合。
> 最开始，大概是2013年，我偶然在网上接触到  _AutoHotkey_，看介绍说开发快捷键和热字串及其方便，且语法简单易学，于是开始网上拷贝一些热字串和快捷键的代码，效率的确提高了不少，用的不亦乐乎。

> 后来，接触到了自带帮助文件（当然是中文版~~），业余时间开始翻一翻，慢慢开始产生了兴趣。

> 记得那些年快速启动小程序很流行，我发现AHK生成菜单也很简单，而且用（系统）菜单来启动程序也没有太多违和之处，于是有了第一个粗糙的脚本：_QuickApps.ahk_，主要功能是读取配置文件自动生成快速启动菜单，并通过鼠标中键点击指定位置或直接使用快捷键来弹出。

> 后来陆续增加各种小功能，如鼠标手势、鼠标音量、办公辅助等。但这些功能都是直接写在_QuickApps.ahk_中，整个脚本臃肿不堪，而且很乱，有了 Bug 什么的我自己都不想改，确实太乱了，有时候自己也看不懂~~。2020年疫情在家重新整合了一下，把各个功能整合了一下，优化了部分代码，改了个名字叫 _zBox.ahk_，把原来主要的功能——快速启动做成了一个组件。

> 我不是程序员出身，做这些脚本也主要是自用，偶尔分享给朋友同事；脚本也是照着帮助文件和网络大牛分享的代码，修改、完善、增加内容，杂糅成现在的模样；而且某些代码是13年刚接触AHK时写的，现在看起来稍显幼稚，但也不想花费时间去重写了，能用就好~~，所以，如果有需要的朋友可以拿去用，看着不顺眼的自己有时间可以完善。没什么版权，但还是希望能常回来看看~~~

## 脚本结构和功能
#### 脚本功能简介
- zBox.ahk：主脚本，包含一些公用的函数和代码段
- zxx_XXX.ini：配置文件，为做区分，xx 为操作系统架构（64或32），XXX 为当前系统用户名，自动生成，无需手动操作
- _zList.inc：脚本包含文件2，各组件的名称列表，自动生成，脚本 GUI 配置中有对应选项，无需手动操作
- _zInit.inc：脚本包含文件1，各组件初始化函数，自动生成，无需手动操作
- Lib 目录：组件目录，包含主脚本 zBox.ahk 以外的附加功能，非完全独立，与主脚本结合较紧密；已启用的脚本随主脚本自动运行。所有组件独立于主脚本存在，且可通过主脚本设置界面启用或禁用。默认包含以下文件：
> - AutoText.ahk：热字串。可直接编辑脚本文件或使用附加脚本中的热字串编辑器生成。
> - BatchOpen.ahk：批量打开文件。启用后可将任意数量、任意类型的文件组合在一起，通过主菜单界面批量打开。
> - CADAid.ahk：CAD办公辅助。启用后可实现CAD绘图界面自动切换回英文输入、自动替换未找到字体、自动跳过“教育版检测标记”提示、自动跳过 HGCAD 插件对话框、查看当前CAD文件关联等
> - Clip2.ahk：剪贴板增强。启用后支持剪贴板历史及多剪贴板粘贴
> - DualMonAid.ahk：双显示器增强。启用后支持使用快捷键在双显示器中操作窗口（针对性较强，可能存在兼容性问题）
> - Gesture.ahk：鼠标手势。可替代单独的鼠标手势程序：可视化指定手势窗口、禁用手势窗口、手势组合、手势超时、轨迹显示、手势提示等。
> - Hotkeys.ahk：快捷键。可直接编辑脚本文件或使用附加脚本中的快捷键编辑器生成。
> - MouseVolume.ahk：鼠标控制音量。可选择鼠标控制位置、通过鼠标滚轮速度实现变速调节音量
> - Mussy.ahk：杂项功能。包含 [Alt+鼠标左键] 移动窗口、[Alt+右键]调整窗口大小、[Ctrl+Alt+Win]显示鼠标下信息、鼠标在屏幕左上角时[Ctrl+Alt]显示系统信息
> - QApp.ahk：快速启动程序。包含快速菜单显示、菜单编辑器等
- Scripts 目录：附加脚本目录，第三方脚本，完全独立。需独立启动或通过入口菜单启动。默认包含以下文件：
> - FileTypesMan.ahk：文件关联管理。操作系统文件关联。
> - HotkeyEditor.ahk：可视化快捷键编辑器，支持所有按键。
> - HotStringEditor.ahk：可视化热键编辑器，支持终止符、全局选项、独立选项、上下文相关等特性指定编辑。
> - Mklink.ahk：创建符号连接，可显示进度及结果，仅支持操作系统为 Win7 及以上。
> - PWDMan.ahk：密码管理器，支持多用户多密码库。需该目录下 “Data”文件夹下的 “crypto.exe”支持。
> - QCalc.ahk：快速表达式计算器，支持在任意可编辑界面计算，支持四则运算、基本函数运算、三角函数运算、进制转换，支持自定义常量、自定义函数
> - ScriptMan.ahk：脚本管理器，显示当前系统运行的所有 AHK 脚本，并支持脚本的运行/重启/停止、编辑等操作，同时支持保存脚本列表
> - TextCoder.ahk：文本/文件编码器，支持文本和文件的 URL/Base64/ 编解码、MD5计算、加解密（需该目录下 “Data”文件夹下的 “crypto.exe”支持）
> - 算术练习.ahk：小学算术练习，包含各种难度的加减法计算，自动出题、自动检查，带计时、保存记录功能（小朋友可能用得着）
> - Data目录：附加脚本所需要的文件及配置。默认包含：
> > - exScriptSet.ini：各附加脚本的配置信息，自动生成
> > - crypto.exe：加解密工具，密码管理器（PWDMan.ahk）、文本/文件编码器（TextCoder.ahk）必需
> > - 1.wav/0.wav：算术练习.ahk 所需音效文件
#### 其他
Lib 和 Scripts 目录内的脚本可自行添加、编辑、删除，注意：
如脚本要显示标题，需在脚本文件第1行添加如下格式的标志，否则将显示文件名：
> ; @title: XXX

> 分号、@、title、冒号为必需，XXX为标题，各符号之间可添加空格或制表符

Lib 组件脚本需按格式要求编写 _init_XXX() 初始化函数才可被主脚本加载：
- 函数名：_init_XXX(){...}，其中XXX为脚本名（无后缀）
- 如组件含配置界面，需在初始化函数中添加以下代码：
> _LIB_COUNT+=1

> Menu,_Menu_LIBSET,Add,%_LIB_COUNT% - [本组件设置菜单名称],[设置界面的标签名]

> 注：以上菜单代码中不含方括号
- 如组件需在主脚本“扩展功能与设置”菜单中增加子菜单，需在初始化函数中添加以下代码：
> _LIB_SETINDEX+=1

>Menu,SubMenu_Extend,Add,%_LIB_SETINDEX% - [菜单名称],[执行命令或子菜单名]

> 注：以上菜单代码中不含方括号
