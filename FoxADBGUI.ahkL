#SingleInstance, off
verDate := "2014-5-4"

bDebug := 1  ; // 是否自用版本

if bDebug
{
	developADB := "D:\bin\Java\Android\sdk\platform-tools\adb.exe"
	LocList := "C:\etc\|S:\|E:\|B:\etc\|D:\tmp\"
} else {
	developADB := "adb.exe"
	FileInstall, D:\bin\Java\Android\adb_cn\adb.exe, %A_scriptdir%\adb.exe, 0
	LocList := "D:\|E:\"
}

	; 设置PATH环境变量，免得后面折腾
	EnvGet, Paths, PATH
	EnvSet, PATH, D:\bin\Java\Android\adb_cn`;D:\bin\Java\Android\sdk\platform-tools`;C:\bin\bin32`;D:\bin\bin32`;%A_scriptdir%\bin32`;%A_scriptdir%`;%Paths%

bOutUTF8 := false
;bOutUTF8 := true

	Gui,Add,Groupbox,x14 y10 w730 h390 cBlue vTip, 远端本地目录及远端列表:
	Gui,Add,checkbox,x640 y8 w730 h20 cBlue vbClickDown checked, 双击下载(&C)
	Gui,Add,Button,x654 y30 w80 h20 gNewShell vNewShell, Shell

	Gui,Add,Button,x454 y30 w80 h20 vShowDir gShowDir, 显示(&S)
	Gui,Add,ComboBox,x24 y30 w430 choose1 vDevDir, /sdcard/|/mnt/shell/emulated/0/|/Removable/MicroSD/

	Gui,Add,ComboBox,x544 y30 w100 vLocDir Choose1, %LocList%

	Gui, Font, S12
	Gui,Add,ListView,x24 y60 w710 h330 -ReadOnly AltSubmit gLVClick vFoxLV, Name|Size|Time
	Gui, Font
	LV_ModifyCol(1, 460) , LV_ModifyCol(2, 80) , LV_ModifyCol(3, 145)
		LV_Add("", "..", "D", "")

	Gui,Show,w751 h410 , ADB push pull by 爱尔兰之狐 http://linpinger.github.io  Ver: %verDate%

	process, Exist, adb.exe
	if ( ErrorLevel = 0 ) {
		guicontrol, Disable, ShowDir
		runwait, %developADB% shell ls /, , Min
		guicontrol, Enable, ShowDir
	}
	gosub, menuinit
	Guicontrol, focus, ShowDir
	gosub, ShowDir
return

menuinit: ; 初始化菜单
	Menu, LVMenu, Add, 下载到本地(&F), FoxMenuAct
	Menu, LVMenu, Add
	Menu, LVMenu, Add, 移动(&M), FoxMenuAct
	Menu, LVMenu, Add, 新建文件夹(&N), FoxMenuAct
	Menu, LVMenu, Add
	Menu, LVMenu, Add, 删除(&D), FoxMenuAct
return

FoxMenuAct: ; 相应菜单
	guicontrolget, DevDir
	LV_GetText(nowName, MenuRowNum, 1)
	If ( A_ThisMenuItem = "移动(&M)" ) {
		oldPath := DevDir . nowName
		inputbox, newPath, 移动／重命名,输入要移动的目标路径,,300, 150, , , , , %oldPath%
		if ( (oldPath = newPath) or newPath = "")
				return
		runwait, adb shell mv "%oldPath%" "%newPath%"
	}
	If ( A_ThisMenuItem = "新建文件夹(&N)" ) {
		inputbox, newDirName, 新建文件夹,输入要新建的文件夹名称,,300, 150
		if ( newDirName = "" )
			return
		runwait, adb shell mkdir %DevDir%%newDirName%
	}
	If ( A_ThisMenuItem = "下载到本地(&F)" ) {
		guicontrolget, DevDir
		guicontrolget, LocDir
		NowRow := 1
		DownNameList := ""
		loop {
			NowRow := LV_GetNext(NowRow)
			if ! NowRow
					break
			LV_GetText(nowName, NowRow, 1)
			LV_GetText(nowSize, NowRow, 2)
			if ( nowSize = "D" )
				continue
			DownNameList .= nowName . "`n"
		} ; 获取名字列表
		loop, parse, DownNameList, `n, `r
		{
				if ( A_LoopField = "" )
						continue
				nowName := A_LoopField
				if ( bOutUTF8 )
					runwait, adb pull "%DevDir%%nowName%" %nowName%, %LocDir%
				else
					runwait, adb pull "%DevDir%%nowName%" ., %LocDir%
		}
	}
	If ( A_ThisMenuItem = "删除(&D)" ) {
		if ( MenuRowNum < 2 )
			return
		LV_GetText(nowSize, MenuRowNum, 2)
		if ( nowSize = "D" ) {
			msgbox, 257, 确认, 确认删除目录
			ifmsgbox, OK
				runwait, adb shell rm -r "%DevDir%%nowName%"
			else
				return
		}
		runwait, adb shell rm "%DevDir%%nowName%"
	}
	lsDir(DevDir, bOutUTF8)
return


NewShell:
	run, adb shell
return

LVClick: ; 双击条目
	nItem := A_EventInfo
	if ( A_GuiEvent == "E" ) { ; F2前
		LV_GetText(nEditBefore, nItem, 1)
	}
	if ( A_GuiEvent == "e" ) { ; F2后
		LV_GetText(nEditAfter, nItem, 1)
		if ( (nEditBefore = nEditAfter) or nEditAfter = "")
				return
		guicontrolget, DevDir
		runwait, adb shell mv "%DevDir%%nEditBefore%" "%DevDir%%nEditAfter%"
	}
	if ( A_GuiEvent = "DoubleClick" ) {
		LV_GetText(nowName, nItem, 1)
		LV_GetText(nowSize, nItem, 2)
		guicontrolget, DevDir
		if ( nowSize = "D" ) { ; 目录
			if ( nowName = ".." ) { ; 上级目录
				xx_1 := ""
				regexmatch(DevDir, "i)^([/]?.*/).+/$", xx_)
				if ( xx_1 != "" ) {
					guicontrol, Text, DevDir, %xx_1%
					lsDir(xx_1, bOutUTF8)
				}
			} else { ; 下级目录
				subDir := DevDir . nowName . "/"
				guicontrol, Text, DevDir, %subDir%
				lsDir(subDir, bOutUTF8)
			}
		} else if ( nowSize = "L" ) { ; 链接
			xx_1 := "" , xx_2 := ""
			; etc -> /system/etc
			regexmatch(nowName, "i)^(.*) -> (.*)", xx_)
			if ( xx_1 != "" ) {
				subDir := DevDir . xx_1 . "/"
				guicontrol, Text, DevDir, %subDir%
				lsDir(subDir, bOutUTF8)
			}
		} else { ; 普通文件
			GuiControlGet, bClickDown
			if ( 1 = bClickDown ) { ; 双击下载
				if ( nItem < 2 )
					return
				if ( nowSize = "D" )
					return
				guicontrolget, LocDir
				if ( bOutUTF8 )
					runwait, adb pull "%DevDir%%nowName%" %nowName%, %LocDir%
				else
					runwait, adb pull "%DevDir%%nowName%" ., %LocDir%
			} else {
				remoteFilePath := DevDir . nowName
				guicontrol, , Tip, 远端本地目录及远端列表: %remoteFilePath%
				clipboard = %remoteFilePath%
			}
		}
	}
return

ShowDir: ; 显示目录内容
	guicontrolget, DevDir
	lsDir(DevDir, bOutUTF8)
return


GuiContextMenu:     ; 菜单:显示右键菜单
	If ( A_guicontrol = "FoxLV") {
		MenuRowNum := A_EventInfo
		Menu, LVMenu, Show, %A_GuiX%, %A_GuiY%
	}
return

GuiDropFiles:  ; 拖动事件
	File_full_path := A_GuiEvent
	if ( A_guicontrol = "FoxLV" ) {
		GuiControlGet, DevDir
		loop, parse, File_full_path, `n, `r
		{
			if ( A_loopfield = "" )
					continue
			FileGetSize, pushSize, %A_LoopField%, K
			sTime := A_TickCount
			runwait, adb push "%A_LoopField%" "%DevDir%"
			eTime := ( A_TickCount - sTime ) / 1000
			TrayTip, Push速度:, % pushSize / eTime . " K/s"
			lsDir(DevDir, bOutUTF8)
		}
	} else {
		TrayTip, 提示:, 要将文件拖动到列表框里
	}
return

GuiEscape:
GuiClose:
	ExitApp
return


^esc::reload
+esc::Edit
!esc::ExitApp


lsDir(DevDir="/sdcard/", bUTF8=false)
{
	tmpFilePath := "C:\DevDir.lst"
	runwait, cmd /c adb shell ls -l "%DevDir%" > %tmpFilePath%, , Min
	if ( bUTF8 ) {
		fileread, nr, *P65001 %tmpFilePath%  ; UTF-8
	} else {
		fileread, nr, %tmpFilePath%
	}
	filedelete, %tmpFilePath%
	LV_Delete()
	LV_Add("", "..", "D")
	loop, parse, nr, `n, `r  ; 目录
	{	 ; drwxrwxr-x root     sdcard_rw          2014-03-25 21:56 aa
		if ( A_LoopField = "" )
			continue
		xx_1 := "", xx_2 := ""
		regexmatch(A_loopfield, "Ui)^d[rwx\-]+[ ]+[a-z\_\-0-9]+[ ]+[a-z\_\-0-9]+[ ]+[0-9]*([0-9]{4}-[0-9]{2}-[0-9]{2} *[0-9]{2}:[0-9]{2}) +(.*)$", xx_)
		if ( xx_2 = "" )
			continue
		LV_Add("", xx_2, "D", xx_1)
	}
	loop, parse, nr, `n, `r  ; 链接
	{	 ; lrwxrwxrwx root     root              1970-01-01 08:00 emmc@android -> /dev/block/mmcblk0p5
		if ( A_LoopField = "" )
			continue
		xx_1 := "", xx_2 := ""
		regexmatch(A_loopfield, "Ui)^l[rwx\-]+[ ]+[a-z\_\-0-9]+[ ]+[a-z\_\-0-9]+[ ]+[0-9]*([0-9]{4}-[0-9]{2}-[0-9]{2} *[0-9]{2}:[0-9]{2}) +(.*)$", xx_)
		if ( xx_2 = "" )
			continue
		LV_Add("", xx_2, "L", xx_1)
	}

	loop, parse, nr, `n, `r  ; 文件
	{	 ; -rw-rw-r-- root     sdcard_rw  2130142 2014-03-27 21:49 novel.zip
		if ( A_LoopField = "" )
			continue
		xx_1 := "", xx_2 := "", xx_3 := ""
		regexmatch(A_loopfield, "Ui)^[^dl].[rwx\-]+[ ]+[a-z\_\-0-9]+[ ]+[a-z\_\-0-9]+[ ]+([0-9]*) +([0-9]{4}-[0-9]{2}-[0-9]{2} *[0-9]{2}:[0-9]{2}) +(.*)$", xx_)
		if ( xx_1 = "" )
			continue
		LV_Add("", xx_3, xx_1, xx_2)
	}
}

