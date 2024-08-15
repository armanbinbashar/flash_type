/*
	Hotstring Support: Define custom abbreviations that automatically expand into full text, saving time and reducing typing effort.
	Instant Command Execution: Execute AHK commands right after a hotstring is expanded, enabling complex automation workflows.
	User-Friendly Interface: Easily manage and configure hotstrings through an intuitive graphical user interface (GUI).
	Customizable: Tailor the script to your specific needs with extensive customization options.
	Lightweight and Efficient: Optimized for performance to ensure minimal impact on system ress.
	Getting Started
	Clone the Repository:
	git clone https://github.com/armanbinbashar/flash_typing.git

	Install AutoHotkey: Download and install AutoHotkey from AutoHotkey’s official website.
	Run the Script: Execute the FastTypingAHK.ahk script using AutoHotkey.
	Usage
	Define Hotstrings: Open the script and add your hotstring definitions in the specified section.
	Execute Commands: Customize the script to execute specific AHK commands immediately after a hotstring is expanded.
	Contributing
	Contributions are welcome! Please fork the repository and submit a pull request with your improvements.
*/

#NoEnv
#SingleInstance Force
CoordMode, Mouse, Screen
SetWorkingDir %A_ScriptDir%
SetBatchLines, -1

;_________________________________________________

Menu, Tray, Icon, res/appicon.ico
Menu, Tray, NoStandard
Menu, Tray, Add, Show menu, menu__
Menu, Tray, Add, Quit, Quit__
hostStringFile := "res/hString.json"
if FileExist(hostStringFile){
    FileRead, FileContent, %hostStringFile%
    global hStringItems := Jxon_Load(FileContent)
}Else{
    MsgBox, 4096,res not found!,% "hString.json not found :(", 5
}

Gui, Font, S8, Segoe UI
Gui, Add, Text, xm, Hotstring Items: 
MenuItemList =
For Each, Item in hStringItems
{
	hotstring(":*:" . Item.hString, Func("donow").Bind(Item.eText,Item.Command,Item.window,Item.hString),"On")
	MenuItemList .= Item.hString "|"
}
Gui, Add, ListBox, xm r15 vMenuItemListBox gonIndexUpdate AltSubmit, %MenuItemList%
Gui, Add, Text, x+10 ym w200 section, hString : 
Gui, Add, Edit, xs wp vhString
Gui, Add, Text, xs w200 section, window : 
Gui, Add, Edit, xs wp vwindow
Gui, Add, Text, xs wp, Expand Text :
Gui, Add, Edit, xs wp veText
Gui, Add, Text, xs wp, Command :
Gui, Add, Edit, xs wp h60 vCommand -Wrap
Gui, Add, Button, xs wp h30 gSave, Save
Gui, Add, Button, xm yp w50 hp gAdd, Add
Gui, Add, Button, x+10 yp w60 hp gRemove, Remove

GuiControl, Choose, MenuItemListBox, 1
Gosub onIndexUpdate
Gui, Show,, ' 	flash_type
Return


;______________________labels__________________________________________

:*:#menu::
:*:#menü::
menu__:
Gui, Show,, ' 	flash_type
Return

GuiClose:
MainGuiClose:
guimainclose:
Gui, Hide
Return

Quit__:
ExitApp
Return


Remove:
GuiControlGet, Index,, MenuItemListBox
If Index
{
	If (hStringItems[Index].eText != ""){
		hotstring(":*:" . hStringItems[Index].hString, hStringItems[Index].eText,"Off")
	}Else{
		hotstring(":*:" . hStringItems[Index].hString, A_Space,"Off")
	}
	hStringItems.RemoveAt(Index)
	Gosub HSitemListBox
		GuiControl, Choose, MenuItemListBox, % Index = 1 ? 1 : Index-1
	Gosub onIndexUpdate
}
Return


Add:
NewWord := "New "
NewIndex := 1
For Each, Item in SortByKey(hStringItems, "hString")
{
	If SubStr(Item.hString, 1, StrLen(NewWord)) != NewWord
		Continue
	Index := SubStr(Item.hString, NewWord+1)
	If (Index = NewIndex)
		NewIndex := Index+1
}
hStringItems.Push({hString: NewWord . NewIndex, Command: "", eText: "", window: ""})
Gosub HSitemListBox
GuiControl, Choose, MenuItemListBox, % hStringItems.MaxIndex()
Gosub onIndexUpdate
Return

Save:
Gui, Submit, NoHide
If (hString = "")
{
	Msgbox, 0x30, %MenuTitle%, hString cannot be blank!
	Return
}
GuiControlGet, Index,, MenuItemListBox
hStringItems[Index].hString := hString
hStringItems[Index].window := window
hStringItems[Index].eText := eText
hStringItems[Index].Command := Command
hotstring(":*:" . hStringItems[Index].hString, Func("donow").Bind(hStringItems[Index].eText,hStringItems[Index].Command,hStringItems[Index].window,hStringItems[Index].hString),"On")
hStringItems := SortByKey(hStringItems, "hString")
Gosub HSitemListBox
For Each, Item in hStringItems
	If Item.hString = hString
		Index := Each, Break
GuiControl, Choose, MenuItemListBox, %Index%
File := FileOpen(hostStringFile, "w")
File.Write(Jxon_Dump(hStringItems, "  "))
File.Close()
Return


HSitemListBox:
MenuItemList =
For Each, Item in hStringItems
{
	MenuItemList .= Item.hString . "|"
}
GuiControl,, MenuItemListBox, |%MenuItemList%
GuiControl, Choose, MenuItemListBox, %Index%
Return

onIndexUpdate:
GuiControlGet, Index,, MenuItemListBox
GuiControl,, hString, % hStringItems[Index].hString
GuiControl,, window, % hStringItems[Index].window
GuiControl,, eText, % hStringItems[Index].eText
GuiControl,, Command, % hStringItems[Index].Command
Return

;______________________functions defination____________________________
donow(endText,ahkCommand,winstring,hString){
	SetTitleMatchMode, 2
	If (winstring != "")
	{
		If (WinActive(winstring))
			Send % endText
		Else{
			savedClip := Clipboard
			Clipboard := ""
			Clipboard := hString
			Sleep, 100
			Send, ^v
			Sleep, 200
			Clipboard := savedClip
		}
	}
	Else if (endText != "")
	{
		Send % endText
	}
	If (ahkCommand != ""){
		ExecScript(ahkCommand)
	}
	SoundPlay, res/triggered.wav
	return
}

ExecScript(script) {
	exePath := A_AhkPath
	shell := ComObjCreate("WScript.Shell")
	exec := shell.Exec(exePath . " *")
	exec.StdIn.Write(script)
	exec.StdIn.Close()
	return exec.ProcessID
}

Jxon_Dump(obj, indent:="", lvl:=1)
{
	static q := Chr(34) ; q = ""
	if IsObject(obj)
	{
		static Type := Func("Type")
		if Type ? (Type.Call(obj) != "Object") : (ObjGetCapacity(obj) == "")
			throw Exception("Object type not supported.", -1, Format("<Object at 0x{:p}>", &obj))

		is_array := 0
		for k in obj
			is_array := k == A_Index
		until !is_array

		static integer := "integer"
		if indent is %integer%
		{
			if (indent < 0)
				throw Exception("Indent parameter must be a postive integer.", -1, indent)
			spaces := indent, indent := ""
			Loop % spaces
				indent .= " "
		}
		indt := ""
		Loop, % indent ? lvl : 0
			indt .= indent

		lvl += 1, out := "" ; Make #Warn happy
		for k, v in obj
		{
			if IsObject(k) || (k == "")
				throw Exception("Invalid object key.", -1, k ? Format("<Object at 0x{:p}>", &obj) : "<blank>")
			
			if !is_array
				out .= ( ObjGetCapacity([k], 1) ? Jxon_Dump(k) : q . k . q ) ;// key
				    .  ( indent ? ": " : ":" ) ; token + padding
			out .= Jxon_Dump(v, indent, lvl) ; value
			    .  ( indent ? ",`n" . indt : "," ) ; token + indent
		}

		if (out != "")
		{
			out := Trim(out, ",`n" . indent)
			if (indent != "")
				out := "`n" . indt . out . "`n" . SubStr(indt, StrLen(indent)+1)
		}
		
		return is_array ? "[" . out . "]" : "{" . out . "}"
	}

	; Number
	else if (ObjGetCapacity([obj], 1) == "")
		return obj

	; String (null -> not supported by AHK)
	if (obj != "")
	{
		obj := StrReplace(obj,  "\",    "\\")
		, obj := StrReplace(obj,  "/",    "\/")
		, obj := StrReplace(obj,    q, "\" . q)
		, obj := StrReplace(obj, "`b",    "\b")
		, obj := StrReplace(obj, "`f",    "\f")
		, obj := StrReplace(obj, "`n",    "\n")
		, obj := StrReplace(obj, "`r",    "\r")
		, obj := StrReplace(obj, "`t",    "\t")

		static needle := (A_AhkVersion<"2" ? "O)" : "") . "[^\x20-\x7e]"
		while RegExMatch(obj, needle, m)
			obj := StrReplace(obj, m[0], Format("\u{:04X}", Ord(m[0])))
	}
	
	return q . obj . q
}

SortByKey(arr, key, reverse := false) {
	static ch := Chr(1) ; Chr(1) return a spacial char
	newArr := [], obj := arr.Clone()
	for k, v in obj
		keys .= (A_Index = 1 ? "" : ch) . v[key]
	Sort, keys, % (numeric ? "N" : "") . (reverse ? " R" : "") . " D" . ch
	Loop, parse, keys, %ch%
	{
		for k, v in obj {
			if (A_LoopField = v[key]) {
				newArr.Push(v), obj.Delete(k)
				break
			}
		}
	}
	Return newArr
}

OnMenuHover(wParam, lParam, Msg, hwnd) {
	Static LastHWnd
    If (A_Gui = "Menu")
	{
		If (LastHwnd)
			CtlColors.Change(LastHwnd, "FFFFFF")
		CtlColors.Change(hwnd, "CCCCCC")
		LastHWnd := hwnd
	}
}

SetGuiClassStyle(hGUI, Style) {
	Return DllCall("SetClassLong" . (A_PtrSize = 8 ? "Ptr" : ""), "Ptr", hGUI, "Int", -26, "Ptr", Style, "UInt")
}

GetGuiClassStyle() {
   Gui, GetGuiClassStyleGUI:Add, Text
   Module := DllCall("GetModuleHandle", "Ptr", 0, "UPtr")
   VarSetCapacity(WNDCLASS, A_PtrSize * 10, 0)
   ClassStyle := DllCall("GetClassInfo", "Ptr", Module, "Str", "AutoHotkeyGUI", "Ptr", &WNDCLASS, "UInt")
      ? NumGet(WNDCLASS, "Int")
      : ""
   Gui, GetGuiClassStyleGUI:Destroy
   Return ClassStyle
}

Jxon_Load(ByRef src, args*)
{
	static q := Chr(34)
	key := "", is_key := false
	stack := [ tree := [] ]
	is_arr := { (tree): 1 }
	next := q . "{[01234567890-tfn"
	pos := 0
	while ( (ch := SubStr(src, ++pos, 1)) != "" )
	{
		if InStr(" `t`n`r", ch)
			continue
		if !InStr(next, ch, true)
		{
			ln := ObjLength(StrSplit(SubStr(src, 1, pos), "`n"))
			col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))
			msg := Format("{}: line {} col {} (char {})"
			,   (next == "")      ? ["Extra data", ch := SubStr(src, pos)][1]
			: (next == "'")     ? "Unterminated string starting at"
			: (next == "\")     ? "Invalid \escape"
			: (next == ":")     ? "Expecting ':' delimiter"
			: (next == q)       ? "Expecting object key enclosed in double quotes"
			: (next == q . "}") ? "Expecting object key enclosed in double quotes or object closing '}'"
			: (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
			: (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
			: [ "Expecting JSON value(string, number, [true, false, null], object or array)"
			, ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1) ][1]
			, ln, col, pos)
			throw Exception(msg, -1, ch)
		}
		is_array := is_arr[obj := stack[1]]
		if i := InStr("{[", ch)
		{
			val := (proto := args[i]) ? new proto : {}
			is_array? ObjPush(obj, val) : obj[key] := val
			ObjInsertAt(stack, 1, val)
			
			is_arr[val] := !(is_key := ch == "{")
			next := q . (is_key ? "}" : "{[]0123456789-tfn")
		}
		else if InStr("}]", ch)
		{
			ObjRemoveAt(stack, 1)
			next := stack[1]==tree ? "" : is_arr[stack[1]] ? ",]" : ",}"
		}
		else if InStr(",:", ch)
		{
			is_key := (!is_array && ch == ",")
			next := is_key ? q : q . "{[0123456789-tfn"
		}
		else ; string | number | true | false | null
		{
			if (ch == q) ; string
			{
				i := pos
				while i := InStr(src, q,, i+1)
				{
					val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
					static end := A_AhkVersion<"2" ? 0 : -1
					if (SubStr(val, end) != "\")
						break
				}
				if !i ? (pos--, next := "'") : 0
					continue
				pos := i
				val := StrReplace(val,    "\/",  "/")
				, val := StrReplace(val, "\" . q,    q)
				, val := StrReplace(val,    "\b", "`b")
				, val := StrReplace(val,    "\f", "`f")
				, val := StrReplace(val,    "\n", "`n")
				, val := StrReplace(val,    "\r", "`r")
				, val := StrReplace(val,    "\t", "`t")
				i := 0
				while i := InStr(val, "\",, i+1)
				{
					if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
						continue 2
					; \uXXXX - JSON unicode escape sequence
					xxxx := Abs("0x" . SubStr(val, i+2, 4))
					if (A_IsUnicode || xxxx < 0x100)
						val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
				}
				if is_key
				{
					key := val, next := ":"
					continue
				}
			}
			else ; number | true | false | null
			{
				val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
			; For numerical values, numerify integers and keep floats as is.
			; I'm not yet sure if I should numerify floats in v2.0-a ...
				static number := "number", integer := "integer"
				if val is %number%
				{
					if val is %integer%
						val += 0
				}
			; in v1.1, true,false,A_PtrSize,A_IsUnicode,A_Index,A_EventInfo,
			; SOMETIMES return strings due to certain optimizations. Since it
			; is just 'SOMETIMES', numerify to be consistent w/ v2.0-a
				else if (val == "true" || val == "false")
					val := %value% + 0
			; AHK_H has built-in null, can't do 'val := %value%' where value == "null"
			; as it would raise an exception in AHK_H(overriding built-in var)
				else if (val == "null")
					val := ""
			; any other values are invalid, continue to trigger error
				else if (pos--, next := "#")
					continue
				
				pos += i-1
			}
			is_array? ObjPush(obj, val) : obj[key] := val
			next := obj==tree ? "" : is_array ? ",]" : ",}"
		}
	}
	return tree[1]
}

