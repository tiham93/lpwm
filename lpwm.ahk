;v0.5
#Requires AutoHotkey v1.1.36+
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
#NoTrayIcon
#Singleinstance Force

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetTitleMatchMode 2

;windows manager persist
gui, WMhl:New, +ToolWindow +alwaysontop -sysmenu -caption, WMhl
gui, WMhl:color, c2EB352
wmArray := []
;windows manager persist end
return


;WINDOWS MANAGER
ToolTipCenter(tttext)
{
	wingetpos, outx, outy, outw, outh, A
	outw := outw / 2 - 70
	outh := outh / 2 - 20
	ToolTip, `n      %tttext%      `n   `n, %outw%, %outh%
}

;Hotkey function label
wmHotkey:
DetectHiddenWindows, on
global wmArray
if not wmArray[A_ThisHotkey]
	return
target_id := wmArray[A_ThisHotKey]
ifwinexist, ahk_id %target_id%
	ifwinnotactive, ahk_id %target_id%
		ActivateWithTT(target_id, true)
	else
		winminimize, ahk_id %target_id%
DetectHiddenWindows, off
return

^#Enter::
{
	;Show ToolTip and wait for key to be assigned (inputhook)
	ih := InputHook("T2")
	ih.KeyOpt("{All}", "SE")
	ih.KeyOpt("{Enter}", "-E")
	ih.KeyOpt("{LWin}", "-E")
	ih.KeyOpt("{LShift}", "-E")
	ih.KeyOpt("{LControl}", "-E")
	ih.KeyOpt("/", "-E")
	ToolTipCenter("Assign WM Key")
	ih.start()
	ErrorLevel := ih.wait()
	ToolTip

	if (ErrorLevel != "EndKey")
	{
		; msgbox % errorlevel
		ToolTip
		return
	}

	;Show ToolTip confirming key assignment
	key := ih.Endkey
	if (key == "Escape")
		return
	global wmArray
	storedKey = #%key%
	if islabel(storedKey) ; check if key is used by ahk
	{
		ToolTipCenter("Key Occupied by AHK")
		settimer, removetooltip, -1000
		return
	}
	if wmArray[storedKey] ; check if key already exists
	{
		msgbox, 1, Duplicate WM Keys, WM Key %key% already exists. Overwrite?
		ifmsgbox cancel
			return
	}
	tttext = Assigned window to Win+%key%
	ToolTipCenter(tttext)
	settimer, removetooltip, -1000

	;Dynamically create hotkey based on input
	winget, active_id, id, A
	wmArray[(storedKey)] := active_id
	Hotkey, %storedKey%, wmHotkey
	return
}

#'::
AppsKey::
{
	ih := InputHook("T4")
	ih.KeyOpt("{All}", "SE")
	ih.KeyOpt("{Enter}", "-E")
	ih.KeyOpt("{LShift}", "-E")
	ih.KeyOpt("{LControl}", "-E")
	ToolTipCenter("Waiting for WM Key")
	ih.start()
	ErrorLevel := ih.wait()
	ToolTip

	if (ErrorLevel != "EndKey")
	{
		ToolTip
		return
	}

	key := ih.endkey
	if ( key == "Escape" ) or ( key == "LWin" )
		return
	
	key = #%key%
	global wmArray
	if not wmArray[key]
		return
	target_id := wmArray[key]
	DetectHiddenWindows, on
	ifwinexist, ahk_id %target_id%
		ActivateWithTT(target_id, true)
	DetectHiddenWindows, off
	return
}

ActivateWithTT(target_id, tt)
{
	DetectHiddenWindows, on
	winactivate, ahk_id %target_id%
	DetectHiddenWindows, off

	;highlight activated
	global firstDraw
	firstDraw := true
	settimer, drawWMhl, 20
	settimer, hideWMhl, 20
	;mouse follows focus
	WinGetPos, outX, outY, outW, outH, A
	outW := outW / 2 - 70
	outH := outH / 2 - 20
	mousemove, %outw%, %outh%
	;tooltip notification
	if tt
	{
		ToolTip, `n      ACTIVE WINDOW      `n `n, %outW%, %outH%
		SetTimer, RemoveToolTip, -1000
	}

	return
}

RemoveToolTip:
Tooltip
return

drawWMhl:
global firstDraw
if firstDraw 
{
	firstDraw := false
	fadeTimer := 500
	winset, transcolor, 000000 100, WMhl
}
wingetactivestats, title, winw, winh, winx, winy
gui, WMhl:show, noactivate w%winw% h%winh% x%winx% y%winy%
return

hideWMhl:
if (fadeTimer > 49)
{
	fadeTimer -= 50 
	op := fadeTimer / 5
	winset, transcolor, 000000 %op%, WMhl
}
else
{
	settimer, drawWMhl, off
	gui, WMhl:hide
	global firstDraw
	firstDraw := true
	settimer, hideWMhl, off
}
return

#+/::
{
	settimer, drawWMhl, 30
	settimer, hideWMhl, 30
	global firstDraw
	firstDraw := true

	msg := "Assigned keys:`n"
	global wmArray
	wmArrayTemp := wmArray.Clone()
	DetectHiddenWindows, on
	for key, id in wmArrayTemp
	{
		ifwinnotexist, ahk_id %id% 
		{
			wmArray.Delete(key)
			continue
		}
		keyFull := Strreplace(key, "#", "Win + ")
		keyFull = %keyFull%:
		winget, name, processName, ahk_id %id%
		line := Format("{1:-12}{2}", keyFull, name)
		msg = %msg%`n%line%
	}
	DetectHiddenWindows, off
	CoordMode, Tooltip, Screen
	Tooltip, %msg%, 900, 500
	settimer, removetooltip, -2000
	return
}

#/::
{
	global prev_id
	CoordMode, Tooltip, Screen
	Tooltip, WM Searching, 900, 500
	winget, prev_id, id, A
	ih := InputHook()
	ih.keyopt("{All}", "S")
	ih.keyopt("{Escape}", "E")
	ih.keyopt("{Enter}", "IE")
	ih.keyopt("{Backspace}", "N")
	ih.keyopt("{Tab}", "NI")
	ih.onChar := func("fuzzyWMFind")
	ih.backspaceisundo := true
	ih.onKeyDown := func("fuzzyWMKey")

	ih.start()
	ErrorLevel := ih.wait()
	if (ErrorLevel != "EndKey")
	{
		msgbox % ErrorLevel
		winactivate, ahk_id %prev_id%
		return
	}

	if ( ih.endkey == "Escape" )
		winactivate, ahk_id %prev_id%
	Tooltip
	return
}

fuzzyWMKey( ih, vk, sc)
{
	if ( vk == 8 )
	{
		fuzzyWMFind( ih, "a" )
		return
	}
	if ( vk == 9 )
	{
		fuzzyWMFind( ih, "+" )
		return
	}
	return
}

fuzzyWMFind( ih, char )
{
	winget, id, List,,, Program Manager
	match_ids := []
	match_length := 999
	query := ih.input
	id_search := ""
	loop, parse, query
	{
		if ( A_Index == 1 )
			id_search = %id_search%%A_LoopField%
		else
			id_search = %id_search%.*%A_LoopField%
	}
	id_search = iUP)%id_search%
	Loop, %id%
	{
		this_id := id%A_Index%
		wingetclass, this_class, ahk_id %this_id%
		if ( this_class == "tooltips_class32" )
			continue
		wingettitle, this_title, ahk_id %this_id%
		winget, this_proc, processName, ahk_id %this_id%
		id_string = %this_proc% - %this_title%
		foundPos := regexmatch(id_string, id_search, this_mlength)
		if ( foundPos == 0 )
			continue
		if ( this_mlength < match_length )
		{
			match_length := this_mlength
			match_ids.insertAt(1, this_id)
			continue
		}
		match_ids.push(this_id)
	}

	CoordMode, Tooltip, Screen
	if ( char = "+" )
		match_id := match_ids.pop()
	else
		match_id := match_ids[1]

	wingettitle, match_title, ahk_id %match_id%
	tooltip_msg = WM Searching "%query%":`n`nMatch ID "%match_id%"`nMatch Title "%match_title%"`nWith match length "%match_length%"
	tooltip_msg = %tooltip_msg%`n`nOTHER RESULTS:
	for index, other_id in match_ids
	{
		if ( other_id != match_id )
		{
			WingetTitle, other_title, ahk_id %other_id%
			tooltip_msg = %tooltip_msg%`n%other_title%
		}
	}
	tooltip, %tooltip_msg%, 900, 500
	ActivateWithTT(match_id, false)

	return
}

;WINDOW MANAGER END
