/*
	HelpText:  A tool that helps you keep track of all of your hotkeys.
	
	Available hotkeys show up when you hold down the associated modifier keys.
	
	To use, #Include HelpTextFunctions.ahk at the bottom of your autohotkey script and
	Gosub the HelpText label at the first, or somewhere in the main thread
	
	You can also run it solo and list the autohotkey files below, or include autohotkey
	scripts in the *Help.ini file that gets created when first ran.
	The globally defined variable or object 'HelpScript' will define which hotkey 
	script(s) will be parsed into the helptext tool.  If 'HelpScript' is not defined,
	the tool will parse the primary ahk script.
	
	To define a help label, inject ;;Your Help Text;; next to or underneath the
	hotkey(up to 5 lines down)
	
	This tool does not recognize custom modifiers and may not work perfectly for
	everything.
	
	Dependencies:  The GUIText Class, which is now included in the functions below, 
	so you need no additional files.
	
	THIS TOOL MAY BE FREELY USED AND CHANGED TO SUIT YOUR NEEDS.  USE AT YOUR OWN RISK.
	CHOOSING TO USE THIS TOOL DOES NOT MAKE ME LIABLE FOR ANYTHING.  THIS TOOL WAS
	DEVELOPED BY A BEGINNER AUTOHOTKEY PROGRAMMER(ME), SO IF YOU HAVE ANY SUGGESTIONS
	FOR IT TO MAKE IT RUN BETTER I WILL GRATEFULLY RECEIVE THEM.
		
	THANKS,
	
	Luddd
	
	
*/

HelpText:
Global help,activekey,activekeytext, GUIall, default_values, AA_ScriptFullPath ; Some Housekeeping
Gosub, DefaultsGuiTextVars
RegExMatch(A_ScriptFullPath,"(?<Path>.*)\.+",AA_ScriptFull) ; Establish A_ScriptFullPath without file extension

If (SubStr(A_ScriptName,1,-3) = "HelpTextFunctions.") {
	IF ! A_IsAdmin
	{
		MsgBox Restarting as admin...
		Run *RunAs "%A_ScriptFullPath%"
		ExitApp
	}

	;  If HelpTextFunctions.ahk is not included into another script, assign the scripts to HelpScript here.
	;  HelpScript may be a variable or an object assigned to (an)other script name(s) / full path(s)
	;  Example:
	;
	;  HelpScript := "Test1.ahk"
	;  
	;  or
	;
	;  HelpScript := {}
	;  HelpScript.Test1 := "Test1.ahk"
	;  HelpScript.Test2 := "C:\Users\User\Desktop\Test2.ahk"
	;  HelpScript.Test3 := "Test3.ahk"
	;
	;  Another easier way to add autohotkey files is add them to the HelpTextFunctionsHelp.ini
	;  file (or *Help.ini where * is your script that includes HelpTextFunctions.ahk) under the
	;  [AutoHotkeyFileList] section.
	
}

IfNotExist,% AA_ScriptFullPath "Help.ini"
{
	IniWrite,% "Add AutoHotkey files here to include their Hotkeys in the HelpText Script",% AA_ScriptFullPath "Help.ini",AutoHotkeyFileList  ; Build help settings file
	IniWrite,% "",% AA_ScriptFullPath "Help.ini",HelpSettings
	HTSb_RunIntro()
}


; assign variables
help := {}
help := HTFn_IniObject(AA_ScriptFullPath "Help.ini","HelpSettings") ; pull settings if they exist from the _Help.ini file
If ! help.color { ; Default variables
	help.x := 100
	help.y := 100
	help.size := 20
	help.color := "Red"
	help.trans := 255
	help.style := "MV Boli"
	help.state := 1
	help.Delay_ms := 750	
}

help.trans := help.trans < 20 ? 20 : help.trans ; prevents complete invisibility

; These may be defined in the settings .ini file if you so desire.
help.hotkeys := help.hotkeys ? help.hotkeys : ["^/","^!/"]
help.reload := help.reload ? help.reload : ["^!'"]
help.hotkeysexplain := help.hotkeysexplain ? help.hotkeysexplain : "Turns on/off the help text"
help.reloadexplain := help.reloadexplain ? help.reloadexplain : "Reload HelpText"
help.options .= help.options ? help.options : " +savemovable{" AA_ScriptFullPath "Help.ini<HelpSettings>} +dragallchange +dragcustomchange +draglimits +savevalues{color,size,style,trans,x,y,Delay_ms,<help.state>state}" ;  +fadein +fadeout +fadeswitch you can add options as they are truncated

Global helptext := new GUIText(help.x,help.y,help.size,help.color,(help.state ? "Help" : ""),255,help.style,help.options) ;  +fadeswitch10 +fadeswitchstep40")
SetTimer, InitialSetTrans,-1000

helptext.Message(" ",200)
helptext.Message("Help")

; Parsing the script
hkobject := {}
activekeytext2 := {"~*$RCtrl":">^","~*$RShift":">+","~*$RAlt":">!","~*$Shift":"+","~*$Alt":"!","~*$Ctrl":"^","~*$LWin":"#"}
hkmodifier := [">!",">^",">+","!","^","+","#"]
hkmodifiertext := ["RAlt","RCtrl","RShift","Alt","Ctrl","Shift","Win"]
hkmodifiertextalph := ["Alt","Ctrl","RAlt","RCtrl","RShift","Shift","Win"]
If IsObject(HelpScript) {
	for k, v in HelpScript {
		FileRead, hkscriptcontents, % v
		temphkobject := HTFn_PullHotkeys(hkscriptcontents,AA_ScriptFullPath "Help.ini",SubStr(v,1,-4) "Hotkeys")
		HTFn_Append(hkobject,temphkobject)
	} 
} else {
	v := HelpScript ? HelpScript : A_ScriptFullPath
	FileRead, hkscriptcontents, % v
	temphkobject := HTFn_PullHotkeys(hkscriptcontents,AA_ScriptFullPath "Help.ini",SubStr(v,1,-4) "Hotkeys")
	HTFn_Append(hkobject,temphkobject)
}

; Pull AutoHotkeyFiles out of the *Help.ini
IniRead,AHFileList,% AA_ScriptFullPath "Help.ini",AutoHotkeyFileList
Loop, Parse, AHFileList, `n
{
	If (A_LoopField = "Add AutoHotkey files here to include their Hotkeys in the HelpText Script")
		Continue
	FileRead, hkscriptcontents, % A_Loopfield
	temphkobject := HTFn_PullHotkeys(hkscriptcontents,AA_ScriptFullPath "Help.ini",SubStr(A_Loopfield,1,-4) "Hotkeys")
	HTFn_Append(hkobject,temphkobject)
}

for hkkey, hkval in help.hotkeys {
	hkval := StrReplace(hkval,"/","?") ; makes the / display as ?
	hkobject[(hkval)] := help.hotkeysexplain
}
for rdkey, rdval in help.reload {
	hkobject[(rdval)] := help.reloadexplain
}


HTFn_SortObj("k",hkmodifier,hkmodifiertext,hkobject,"~","`n`t")

HTFn_Hotkey("ON","HelpOnOff",help.hotkeys) ; Turn on the help text on/off
HTFn_Hotkey("ON","ReloadHelpText",help.reload)

Return





/*
-------------------------------------------------
Functions and Classes used for the HelpText Tool and GUIText

Includes the GUIText class for on screen messaging
-------------------------------------------------
*/






; fn_Option(object,value(string),haystack,default when + used and no value, default when - used)
HTFn_Option(para_oobject,para_ovalue, para_ostring, para_odefaultp := 1,para_odefaultn := 0) {
	If InStr(para_ostring,"+" para_ovalue "{") {
		RegExMatch(para_ostring,"\+" para_ovalue "{(?<txt>.*?)}",omatch)
		para_oobject[(para_ovalue)] := omatchtxt ? omatchtxt : para_odefaultp
		Return
	}
	If InStr(para_ostring,"+" para_ovalue) {
		RegExMatch(para_ostring,"\+" para_ovalue "(?<txt>[\d\w\Q!^#+<>-\E]*)",omatch) ; \Q...\E Literal text, no escapes
		para_oobject[(para_ovalue)] := omatchtxt ? omatchtxt : para_odefaultp
		Return
	}
	If InStr(para_ostring,"-" para_ovalue) {
		para_oobject[(para_ovalue)] := para_odefaultn
		Return
	}
	;~ MsgBox % para_ovalue ":" para_oobject[(para_ovalue)]
}

HTFn_SetTimer(para_label,para_cmd) {
	SetTimer, %para_label%,% para_cmd
}

HTFn_Bigger(para_bvalue*) { ; untested fully
	breturnval := .1
	for key, val in para_bvalue {
		if (val is number) && (breturnval is number)
			breturnval := val > breturnval ? val : breturnval
		else
			breturnval := StrLen(val) > StrLen(breturnval) ? val : breturnval
	}
	Return breturnval
}

Class GUIEdit extends GUIunit { ; Later

}

HTFn_FindKey(para_array,para_value) { ; arrays only....
	For key, val in para_array {
		If (para_array[(key)] = para_value) {
			Return key
		}
	}
	Return 0
}

HTFn_Before(para_array,para_value) { ; These only really work with arrays...
	Return HTFn_FindKey(para_array,para_value) 
		? HTFn_FindKey(para_array,para_value) > 1 
		? para_array[(HTFn_FindKey(para_array,para_value)-1)] 
		: para_array[(para_array.Length())] 
		: ""
}

HTFn_After(para_array,para_value) { ; These only really work with arrays...
	Return HTFn_FindKey(para_array,para_value) 
		? HTFn_FindKey(para_array,para_value) = para_array.Length() 
		? para_array[1] 
		: para_array[(HTFn_FindKey(para_array,para_value)+1)] 
		: ""
}

HTFn_BeforeAfterInt(para_obj,para_val,para_var) {  ; tested with + : 1516 ms over 1000 itinerations
	;~ MsgBox % fn_ShowObject(para_obj) "`n`n" para_var "," para_val
	If (para_val = "+")
		Return HTFn_After(para_obj,para_var)
	else if (para_val = "-")
		Return HTFn_Before(para_obj,para_var)
	else if para_val is integer
		Return para_obj[(para_val)]
	else
		Return para_val
}

HTFn_TextWidest(para_string) {
	TextLines := StrSplit(para_string,"`n")
	For key, val in TextLines {
		widestline := StrLen(val) > widestline ? StrLen(val) : widestline
	}
	TextLines := ""
	Return widestline
}

HTFn_TextLines(para_string) {
	TextLines := StrSplit(para_string,"`n")
	For key, val in TextLines
		numberoflines ++
	TextLines := ""
	Return numberoflines
}

HTFn_Hotkey(para_hcmd,para_hlabel,para_hhotkey*) { ; YOU MIGHT HAVE TO ADD A TRY...
	For key, val in para_hhotkey
		If IsObject(val) {
			For key2, val2 in val
				Hotkey, % val2, % para_hlabel, % "UseErrorLevel" para_hcmd
		} else {
			If val {
				;~ Try {
				Hotkey, % val,% para_hlabel, % "UseErrorLevel " para_hcmd
				;~ }
			}
		}
	Return
}

HTFn_Tooltip(para_tooltip,para_timer := 2000, para_window := "",para_divX := 0,para_divY := 0) {
	If para_window
		WinGetPos,WinX,WinY,WinW,WinH,%para_window%
	If para_divX {
		TooltipX := WinX + (WinW / para_divX)
		TooltipY := WinY + (WinH / para_divY)
		Tooltip, %para_tooltip%,TooltipX,TooltipY
	} Else {
		Tooltip, %para_tooltip%
	}
	SetTimer, HTFn_RemoveToolTip, %para_timer%
}
HTFn_RemoveToolTip:
{
	SetTimer, HTFn_RemoveToolTip, Off
	ToolTip
	Return
}

HTFn_Cloneobj(para_csource,ByRef para_cdest) {
	para_cdest := {}
	For key, val in para_csource {
		If key
			para_cdest[(key)] := val
	}
	Return "Source:" . HTFn_ShowObject(para_csource,"source") . "`nDest: " . HTFn_ShowObject(para_cdest,"dest")
}

HTFn_ShowObject(para_sobj,para_svarname := "array") {  ; FIX TO EXPAND SUBOBJECTS!
;	nameobj := GetOriginalVariableNameForSingleArgumentOfCurrentCall(A_ThisFunc)
	Listtxt := para_svarname . " = {"
;	MsgBox % Listtxt
	For key, val in para_sobj {
		If key {
			Listtxt .= key . ":" . val
			x++
		}
		If (A_Index != para_sobj.GetCapacity())
			If key
				Listtxt .= ","
	}
;	Listtxt := SubStr(Listtxt, 1, -StrLen(",")) ; Another way to take off that last comma
	Listtxt .= "}"
	Return Listtxt . "`n" . x . " Key:Value pairs"
}

HTFn_IniObject(para_file,para_section,para_writeobject := "",para_savesettings := "",para_deleteexcess := 0) {
	/*
		Where:
		para_file is the name of the ini file
		para_section is the name of the ini section
		if an object is given as the third parameter, the function updates the ini file.
			No updating is necessary, the function returns a 0
		para_savesettings is a comma separated string that declares which keys to save/copy to object.
		If no string is given, all keys are saved/copied to object.
			If the key is enclosed in a <>, it is saved as a separate variable.
				If there is a key after the <key>, the <key> value is saved under the key name
					For Example:   <var1>var2 means the value of var1 is saved as var2=val_of_var1 in the .ini
						
		
		IniRead,AHFileList,% AA_ScriptFullPath "Help.ini",AutoHotkeyFileList
		Loop, Parse, AHFileList, "`n"
	*/
	para_include := 0
	para_object := {}
	para_testobject := {}
	IniRead, sectiontext,% para_file,% para_section
	Loop, Parse, sectiontext, "`n" ; Loop, Read, % para_file
	{
	para_val := RegExMatch(A_LoopField,"(?<key>.+?)\s*=\s*(?<val>.*)",_) ? _val : para_val "`n" A_LoopField
	para_key := _key ? _key : para_key
	_val := _val ? _val : Continue
	para_object[para_key] := para_val
	}
	If ! IsObject(para_writeobject)
		Return para_object
	else {
		Update := 0
		NotEmpty := 0
		If para_savesettings {
			Loop, Parse, para_savesettings, "`," 
			{
				RegexMatch(A_LoopField,"\<(?<valkey>.+)\>(?<inikey>.*)",_)
				IniRead,checkvar,% para_file,% para_section,% (_inikey ? _inikey : _valkey ? _valkey : A_LoopField)
				If (checkvar != (_valkey ? HTFn_GetValue(_valkey) : para_writeobject[A_Loopfield])) {
					IniWrite,% (_valkey ? HTFn_GetValue(_valkey) : para_writeobject[A_Loopfield]),% para_file,% para_section,% (_inikey ? _inikey : _valkey ? _valkey : A_Loopfield)
					Update := 1
				}
			}
		} else {
			for key, val in para_writeobject {
				If (para_object[key] != para_writeobject[key]) { 
					; MsgBox % "file's:" para_object[key] """    object's:" para_writeobject[key] """"
					para_object[key] := para_writeobject[key]
					IniWrite,% val,% para_file,% para_section,% key
					Update := 1
				} else
					NotEmpty := 1
				if NotEmpty && para_deleteexcess
					for key, val in para_object
						If ! para_writeobject.HasKey(key) {
							IniDelete,% para_file,% para_section,% key
							Update := 1
						}
			}
		}
		If Update
			Return para_object
		Else
			Return ""
	}
}

HTFn_GetValue(para_var) {
	For vkey, vval in StrSplit(para_var,".") {
		temp_obj2 := IsObject(temp_obj) ? temp_obj[vval] : %vval%
		If IsObject(temp_obj2)
			temp_obj := temp_obj2
		else
			Return temp_obj2
	}
	Return temp_obj
}

HTFn_objectcompare(para_object1,para_object2){
	same := 1
	for okey, oval in para_object1
		if ! (oval = para_object2[okey])
			Return 0
	for okey, oval in para_object2
		if ! (oval = para_object1[okey])
			Return 0
	Return 1
}

/*
	--------------------------------------------------------------------------
	S O R T   O B J E C T   F U N C T I O N(S)   A N D    H O T K E Y S
	--------------------------------------------------------------------------
	HTFn_SortObj(para_kv,para_order,para_order2,ByRef para_obj,para_separator := "",para_separator2 := "")
*/

HTFn_SortObj(para_kv,para_order,para_order2,ByRef para_obj,para_separator := "",para_separator2 := "") {
	newobj := {}
	For key, val in para_obj {
		newkey =
		newkey2 =
		newkey3 =
		oldkey := key
		For key2, val2 in para_order {
			IfInString, oldkey, %val2%
			{
				StringReplace, oldkey, oldkey, %val2%, ,UseErrorLevel
;				Loop ErrorLevel
				newkey .= val2
				if para_order2 {
					newkey2 .= para_order2[(key2)]
					newkey3 .= newkey3 ? " + " . para_order2[(key2)] : para_order2[(key2)]
				}
			}
		}
		;~ MsgBox % key2 . " - key  val - " . val2
;		para_obj.Delete(key)
		newobj[1,(newkey . oldkey)] := val
		newobj[2,(newkey)] .= newobj[2,(newkey)] ? para_separator . Trim(oldkey,"~$") : oldkey
		newobj[3,(newkey2)] := para_order2 ? newkey : ""
		newobj[4,(newkey3)] .= val ? para_order2 ? newobj[4,(newkey3)] ? para_separator2 . Trim(oldkey,"~$") . " - " . val : Trim(oldkey,"~$") . " - " . val : "" : ""
;		More Objects
	}
;	GUIObject(newobj,"newobj")
	HTFn_Cloneobj(newobj,para_obj)
	newobj := {}
	Return
}

HTFn_ObjectValues(para_object,para_delimiterbefore, para_delimiterafter) {
	For key, val in para_object
		alltext .= val ? para_delimiterbefore . val . para_delimiterafter : ""
	Return RTrim(LTrim(alltext,para_delimiterbefore),para_delimiterafter)
}

HTFn_IsEmpty(para_object){
	For ekey, eval in para_object
		If eval
			Return False
	Return True		
}

; HTFn_PullHotkeys(hkscriptcontents,hkobject,AA_ScriptFullPath "Help.ini",SubStr(v,-3) "Hotkeys")
HTFn_PullHotkeys(para_text,para_settingsfile,para_section) {
	tempobject := {}
	Loop {
		RegExMatch(para_text,"\n(?<hk>[!#^+~\*\w\d\<\>/]*)::.*[\n\s]{0`,5};;(?<explain>.*);;", match)
		If (matchhk = matchhk2)
			Break ; Prevents infinite loops
		matchhk := StrReplace(matchhk,"~")
		tempobject[matchhk] := Trim(matchexplain," `t`n`r")
		para_text := StrReplace(para_text,"`n" . matchhk . "::")
		para_text := StrReplace(para_text,";;" . matchexplain . ";;")
		matchhk2 := matchhk
	}Until ! matchhk
	If HTFn_IsEmpty(tempobject) {
		tempobject := HTFn_IniObject(para_settingsfile,para_section) ; test compiled
		helptext.Message(para_section "`nNot Found" (! HTFn_IsEmpty(tempobject) ? "`nPrevious Hotkeys Loaded..." : ""))
	}
	If HTFn_IniObject(para_settingsfile,para_section,tempobject,"",1)
		helptext.Message(para_section "`nHotkeys updated in`n" para_settingsfile) ; HTFn_ToolTip(para_section " Hotkeys updated in " para_settingsfile)helptext
	Return tempobject
}

HTFn_Append(para_obj1,para_obj2) {
	For akey, aval in para_obj2
		para_obj1[akey] := aval
}

; Modifier Hotkeys
~*$RAlt::
~*$RCtrl::
~*$RShift::
~*$Alt::
~*$Ctrl::
~*$Shift::
~*$LWin::
If ! help.state
	Return
mk := A_ThisHotkey = "~*$RAlt" ? 1 : A_ThisHotkey = "~*$RCtrl" ? 2 : A_ThisHotkey = "~*$RShift" ? 3 : A_ThisHotkey = "~*$Alt" ? 4 : A_ThisHotkey = "~*$Ctrl" ? 5 : A_ThisHotkey = "~*$Shift" ? 6 : 7
activekeytext[(mk)] := LTrim(A_ThisHotkey,"~*$L")
hktext := HTFn_ObjectValues(activekeytext," + ","")
If (remembermodtext = hktext)
	Return
help.text := "Help  " . hktext . "`n`n`t" . hkobject[4,(hktext)]
If helptext.Delay_ms
	SetTimer, ModifierDown, % "-" helptext.Delay_ms
else
	Gosub, ModifierDown
remembermodtext := hktext
mk := 0
return

ModifierDown:
helptext.SetText(help.text)
helptext.RedrawGUI()
Return


~*$RAlt UP::
~*$RCtrl UP::
~*$RShift UP::
~*$Alt UP::
~*$Ctrl UP::
~*$Shift UP::
~*$LWin UP::
SetTimer, ModifierDown, Off
If ! help.state
	Return
If (HTFn_ObjectValues(activekeytext,"","") = "Win" && A_PriorHotkey = "~*$LWin")
	Send ^{Esc}
mk := A_ThisHotkey = "~*$RAlt UP" ? 1 : A_ThisHotkey = "~*$RCtrl UP" ? 2 : A_ThisHotkey = "~*$RShift UP" ? 3 : A_ThisHotkey = "~*$Alt UP" ? 4 : A_ThisHotkey = "~*$Ctrl UP" ? 5 : A_ThisHotkey = "~*$Shift UP" ? 6 : 7
activekeytext[(mk)] := ""
hktext := HTFn_ObjectValues(activekeytext," + ","")
help.text := "Help  " . hktext . "`n`n`t" . hkobject[4,(hktext)]
helptext.SetText(help.text)
mk := 0
return

sb_AllOff() {
	HTFn_Hotkey("OFF","","Up","Down","Left","Right","Enter","~LButton","Esc","X","x","A","a")
}

HelpOnOff:
help.state := help.state ? 0 : 1
If ! help.state
	help.text := ""
else
	help.text := "Help"
helptext.SetText(help.text)
IniWrite,% help.state,% AA_ScriptFullPath "Help.ini", HelpSettings, state
Return

ReloadHelpText:
Critical
Reload
Sleep 3000
HTFn_ToolTip("Didn't Reload...Somethings Wrong")
Return

InitialSetTrans:
helptext.SetTrans(help.trans)   
helptext.Delay_ms := help.Delay_ms
Return

HTSb_RunIntro() {
	Global intro := new GUIText(100,200,30,"Black","",255,"MV Boli","+fadein +fadeswitch +fadeout +savemovable")
	intro.MInterrupt := "Space"
	intro.Message("Hit Space to skip...",5000)
	intro.Message("Hello!",3000,0,"Black",50,"OCR A Extended")
	intro.Message("So this is your first time using HelpText!",3000,0,"Yellow",60, "Times New Roman Italic")
	intro.Message("HelpText uses the GUIText Class to organize`nyour Hotkeys when there`nare so many they are hard to remember....",10000)
	intro.Message("HelpText can be implemented into one script`n with an #Include or/and include many scripts.",7000)
	intro.Message("HelpText can also be deployed solo and have`nscripts added to the HelpTextFunctionsHelp.ini file`nto manage literally hundreds of hotkeys.",7000)
	intro.Message("Hotkeys that are available under the modifiers`nshow up as the modifiers are pressed.`nFor example...",7000)
	intro.Message("Help  Alt + Ctrl + Shift + Win`n`n`tl - Make a Log Entry`n`tc - Copy Files`n`tk - KILL SCRIPT`n`tt - Change Window Transparency",7000)
	intro.Message("Hotkeys are included into the HelpText tool`nBy adding the hotkey message like this:",7000)
	intro.Message("!^#+l::  `;`;Make Log Entry`;`;",7000)
	intro.Message("The HelpText text size,color,position,font,delay,etc may`nbe changed by dragging the text and`nmaking the changes while still holding the mouse`nbutton.`nFollow the tooltip instructions...",7000)
	intro.Message("View README to see more....",7000)
	intro.Message(" ",200)
	intro.Message("THIS TOOL MAY BE FREELY USED, DISTRIBUTED, AND CHANGED TO SUIT YOUR NEEDS.`nUSE AT YOUR OWN RISK.`nCHOOSING TO USE THIS TOOL DOES NOT MAKE ME LIABLE `nFOR ANYTHING.  THIS TOOL WAS DEVELOPED BY A BEGINNER`nAUTOHOTKEY PROGRAMMER(ME), SO IF YOU HAVE ANY SUGGESTIONS`nFOR IT TO MAKE IT RUN BETTER I WILL GRATEFULLY RECEIVE THEM.`n`nTHANKS,`n`nLuddd",20000,1000,"",20,"OCR A Extended")
}



; extends BaseClassName - full name of another class - ClassName writes over same BaseClassName methods and ?properties?
; full name of each class: object.__Class
; Classes contain:	var declarations
;					method declarations
;					nested classes definitions
;.__Class = name of class
; Methods:  __Init, __New, 
Class GUIunit {
	__New() {
		GUI, %GUIName%:Destroy
	}
	__Delete() {
		HTFn_SetTimer(this.fadeswitchlabel,"Off")
		If this.fadeout ;  || this.sizeout
			this.DeleteStart()
		Else {
			GUIName := this.guiname
			If GUIName {
				Gui, %GUIName%:Destroy
				GUIall[(this.guinum)] := ""
			}
		}
	}
	DeleteStart() {
		If this.fadeout {
			this.fadeoutstep := this.fadeoutstep ? this.fadeoutstep : default_values.GUITextFadeOutStep
			HTFn_SetTimer(this.fadeoutlabel,this.fadeout)
		}
	}
	FadeOutL() {
		this.transtemp := this.trans
		HTFn_SetTimer(this.fadeinlabel,"Off")
		this.transtemp -= this.fadeoutstep
		If (this.transtemp < 0) {
			GUIName := this.guiname
			If GUIName {
				Gui, %GUIName%:Destroy
				GUIall[(this.guinum)] := ""
			}
			HTFn_SetTimer(this.fadeoutlabel,"Off")
		}
		this.SetTrans(this.transtemp)
	}
	NameIt(para_type) {
		guicount := 0
		For key, val in GUIall
			guicount++
		this.guinum := guicount + 1
		this.guiname := GUIall[(this.guinum)] := para_type "GUI" . this.guinum
		var := this.var := this.guiname "var"
		; MsgBox % this.guinum "," this.guiname
		; GUIObject(GUIall,"GUIall")
	}
	TransferValues(para_takeold := "") {
		For key, val in this.valuelist ? this.valuelist : default_values.GUIMsgVList {
			If para_takeold
				this[(val)] := this[("old" val)]				
			else
				this[("old" val)] := this[(val)]
		}
	}
	LoadWinVars(para_value := "") {
		;~ this.winUID := WinActive("A")
		;~ WinSetTitle := this.guiname
		WinGetPos x,y,w,h,% this.guiname
		this.winX := x, this.winY := y, this.winW := w, this.winH := h
		If para_value
			this.h := this.WinH, this.w := this.WinW, this.x := this.WinX, this.y := this.WinY
	}
}


/*
	savemovable array
	postmessage moving
	sizing for winw and h adjust - still need to adjust
	later - color chooser/namer...something like that
	WinSet, Region, % "0-0 w" PW/2 " h" PH/2 " r6-6"  -  size in and out derivative
	Do the size in-out-switch later, you probably won't use it.
	flashfade
	Bugs:
	fading timer stops with a msgbox.(Maybe it happens when you call a different class method/variable
	too many fonts - FIGURE THIS ONE OUT
	after -dragallchange and -dragcustomchange options, lose GUI!!
*/
Class GUIText extends GUIunit {
	__New(x := 1,y := 1,size := 28,color := "",text := "",trans := 255,style := "",options := "") {
		global
		this.glabel := this.Gmove.Bind(this)
		this.mouseuplabel := this.DragWindowMouseUp.Bind(this)
		this.changelabel := this.ChangeL.Bind(this)
		this.dragtt := this.DragToolTip.Bind(this)
		this.fadeinlabel := this.FadeInL.Bind(this)
		this.fadeoutlabel := this.FadeOutL.Bind(this)
		this.fadeswitchlabel := this.FadeSwitchL.Bind(this)
		this.sizeinlabel := this.SizeInL.Bind(this)
		this.sizeoutlabel := this.SizeOutL.Bind(this)
		this.flashlabel := this.FlashL.Bind(this)
		this.quetolabel := this.QueTo.Bind(this)
		this.quelabel := this.Que.Bind(this)
		if (color = "")
			color := default_values.color
		if (style = "")
			style := default_values.font
		this.NameIt("Text")
		this.x := x
		this.y := y
		this.text := text
		this.size := size
		this.color := color
		this.trans := trans
		this.style := style
		if options 
			this.Options(options)
		this.Load()
	}
	Options(options) { ; fn_Option(object,value(string),haystack,default when +(1), " -(0))
		/*
		; A better way to parse options...  Needs finished...
			while options {
				MsgBox % options
				RegExMatch(options " ","(?<p>\+)?(?<n>-)?(?<var>.+?)(\{(?<add>.+)\})?\s",option)
				MsgBox % "optionvar=" optionvar ",optionp=" optionp ",optionn=" optionn ",optionadd=" optionadd "`n`n" options
				options := StrReplace(options,optionp optionn optionvar (optionadd ? "{" optionadd "}" : ""))
				options := Trim(options)
				MsgBox % "'"optionp optionn optionvar (optionadd ? "{" optionadd "}" : "")"'"
			}
		*/
		If this.dragallchange
			dragallchange := 1
		;~ fn_Option(this,"message",options)
		HTFn_Option(this,"ftext",options,"","")
		HTFn_Option(this,"flash",options,default_values.GUITextFlash)
		HTFn_Option(this,"movable",options)
		HTFn_Option(this,"savemovable",options)
		If InStr(this.savemovable,"<") {
			this.savemovablesection := RegExMatch(this.savemovable,"(?<file>.+)\<(?<set>.+)\>",_)
				? _set : default_values.GUITextSaveSection
			this.savemovable := _file
		} else
			this.savemovablesection := this.savemovablesection ? this.savemovablesection 
				: default_values.GUITextSaveSection
		HTFn_Option(this,"savevalues",options)
		this.savevalues := this.savevalues ? this.savevalues : default_values.GUITextSaveValues
		HTFn_Option(this,"cww",options)
		HTFn_Option(this,"cwh",options)
		HTFn_Option(this,"fadein",options,default_values.GUITextFadeIn)
		HTFn_Option(this,"fadeinstep",options,default_values.GUITextFadeInStep,1)
		HTFn_Option(this,"fadeout",options,default_values.GUITextFadeOut)
		HTFn_Option(this,"fadeoutstep",options,default_values.GUITextFadeOutStep,1)
		HTFn_Option(this,"fadeswitch",options,default_values.GUITextFadeSwitch)
		HTFn_Option(this,"fadeswitchstep",options,default_values.GUITextFadeSwitchStep,1)
		; GUISize?
		; Sizing in/out/switch is too slow and ugly.  Need to figure out how through a postmessage or DLLCall...
		;~ fn_Option(this,"sizein",options,default_values.GUITextSizeIn)
		;~ fn_Option(this,"sizeinstep",options,default_values.GUITextSizeInStep,1)
		;~ fn_Option(this,"sizeout",options,default_values.GUITextSizeOut)
		;~ fn_Option(this,"sizeoutstep",options,default_values.GUITextSizeOutStep,1)
		;~ fn_Option(this,"sizeswitch",options,default_values.GUITextSizeSwitch)
		;~ fn_Option(this,"sizeswitchstep",options,default_values.GUITextSizeSwitchStep,1)
		HTFn_Option(this,"draglimits",options,"changetopositive","changetonegative")
		If (this.draglimits = "changetopositive") {
			this.dragsizeulimit := this.dragsizeulimit ? this.dragsizeulimit : default_values.GUITextSizeChangeHotkeyULimit
			this.dragsizellimit := this.dragsizellimit ? this.dragsizellimit : default_values.GUITextSizeChangeHotkeyLLimit
			this.dragtransulimit := this.dragtransulimit ? this.dragtransulimit : default_values.GUITextTransChangeHotkeyULimit
			this.dragtransllimit := this.dragtransllimit ? this.dragtransllimit : default_values.GUITextTransChangeHotkeyLLimit
			this.dragcustomulimit := this.dragcustomulimit ? this.dragcustomulimit : default_values.GUITextCustomChangeHotkeyULimit
			this.dragcustomllimit := this.dragcustomllimit ? this.dragcustomllimit : default_values.GUITextCustomChangeHotkeyLLimit
			this.draglimits := ""
		}
		if (this.draglimits = "changetonegative") {
			this.dragsizeulimit := ""
			this.dragsizellimit := ""
			this.dragtransulimit := ""
			this.dragtransllimit := ""
			this.dragcustomulimit := ""
			this.dragcustomllimit := ""
			this.draglimits := ""
		}
		HTFn_Option(this,"dragfontchange",options,default_values.GUITextFontChangeHotkey) ; make sure you build an instru GUI
		HTFn_Option(this,"dragsizechange",options,default_values.GUITextSizeChangeHotkey)
		HTFn_Option(this,"dragsizeulimit",options,default_values.GUITextSizeChangeHotkeyULimit)
		HTFn_Option(this,"dragsizellimit",options,default_values.GUITextSizeChangeHotkeyLLimit)
		HTFn_Option(this,"dragcolorchange",options,default_values.GUITextColorChangeHotkey)
		HTFn_Option(this,"dragtranschange",options,default_values.GUITextTransChangeHotkey)
		HTFn_Option(this,"dragtransulimit",options,default_values.GUITextTransChangeHotkeyULimit)
		HTFn_Option(this,"dragtransllimit",options,default_values.GUITextTransChangeHotkeyLLimit)
		HTFn_Option(this,"dragcustomchange",options,default_values.GUITextCustomChangeHotkey)
		HTFn_Option(this,"dragcustomchangename",options,default_values.GUITextCustomChangeHotkeyName)
		HTFn_Option(this,"dragcustomchangestep",options,default_values.GUITextCustomChangeHotkeyStep)
		HTFn_Option(this,"dragcustomchangevalue",options,default_values.GUITextCustomChangeHotkeyValue)
		HTFn_Option(this,"dragcustomulimit",options,default_values.GUITextCustomChangeHotkeyULimit)
		HTFn_Option(this,"dragcustomllimit",options,default_values.GUITextCustomChangeHotkeyLLimit)
		HTFn_Option(this,"dragallchange",options)
		this.dragcustomchangename := this.dragcustomchangename
			? this.dragcustomchangename
			: default_values.GUITextCustomChangeHotkeyName
		this.dragcustomchangestep := this.dragcustomchangestep
			? this.dragcustomchangestep
			: default_values.GUITextCustomChangeHotkeyStep
		this[(this.dragcustomchangename)] := this[(this.dragcustomchangename)] ? this[(this.dragcustomchangename)]
			: this.dragcustomchangevalue
			? this.dragcustomchangevalue
			: default_values.GUITextCustomChangeHotkeyValue
		If this.dragallchange {
			this.dragfontchange := this.dragfontchange ? this.dragfontchange : default_values.GUITextFontChangeHotkey
			this.dragsizechange := this.dragsizechange ? this.dragsizechange : default_values.GUITextSizeChangeHotkey
			this.dragcolorchange := this.dragcolorchange ? this.dragcolorchange : default_values.GUITextColorChangeHotkey
			this.dragtranschange := this.dragtranschange ? this.dragtranschange : default_values.GUITextTransChangeHotkey
		} else
			If dragallchange {
				this.dragfontchange := ""
				this.dragsizechange := ""
				this.dragcolorchange := ""
				this.dragtranschange := ""
			}
		dragallchange=
		If this.ftext
			this.ChooseBiggerText()
		If this.flash
			HTFn_SetTimer(this.flashlabel,this.flash)
		;~ fn_GUIObject(this,"this")
	}
	Message(para_text := "",para_time := "",para_timeto := 0,para_color := "", para_size := "",para_font := "",para_trans := "",para_x := "",para_y := "", para_MInterrupt := "") {
		if (para_text != "!cyclecycle!") {
			para_text := para_text ? para_text : this.cycle ? this.oldtext : this.text
			para_time := para_time ? para_time : default_values.GUITextQueTime
			para_color := para_color ? para_color : this.cycle ? this.oldcolor : this.color
			para_size := para_size ? para_size : this.cycle ? this.oldsize : this.size
			para_font := para_font ? para_font : this.cycle ? this.oldstyle : this.style
			para_trans := para_trans ? para_trans : this.cycle ? this.oldtrans : this.trans
			para_x := para_x ? para_x : this.cycle ? this.oldx : this.x
			para_y := para_y ? para_y : this.cycle ? this.oldy : this.y
			If ! IsObject(this.q)
				this.q := {}
			this.q.InsertAt(1,[para_text,para_time,para_timeto,para_color,para_size,para_font,para_trans,para_x,para_y,para_MInterrupt ? para_MInterrupt : this.MInterrupt ? this.MInterrupt : ""])
		}
		if ! this.cycle {
			this.TransferValues(0)
			this.cycle := 1
			qend := this.q.Length()
			if this["q",qend,3] {
				HTFn_SetTimer(this.quetolabel,-this["q",qend,3])	
				If this["q",qend,10]
					HTFn_Hotkey("ON",this.quetolabel,this["q",qend,10])
			} else
				this.QueTo()
		}
	}
	
	QueTo() {
		qend := this.q.Length()
		HTFn_SetTimer(this.quetolabel,"OFF")
		this.Move(this["q",qend,8],this["q",qend,9])
		this.Set(this["q",qend,4],this["q",qend,6],this["q",qend,5],this["q",qend,1],this["q",qend,7])
		HTFn_SetTimer(this.quelabel,-this["q",qend,2])
		If this["q",qend,10] {
			HTFn_Hotkey("ON",this.quelabel,this["q",qend,10])
		}
	}
	Que() {
		qend := this.q.Length()
		HTFn_SetTimer(this.quelabel,"Off")
		HTFn_Hotkey("OFF","",this["q",qend,10])
		this.TransferValues(1)
		this.cycle := ""
		this.q.Pop()
		qend := this.q.Length()  
		if this["q",qend,1] 
			this.Message("!cyclecycle!")
		else {
			this.TransferValues(1)
			this.cycle := 0
			this.Move(this.x,this.y)
			this.Set(this.color,this.font,this.size,this.text,this.trans)
		}
	}
	;~ __Call() {
		;~ MsgBox Called!
	;~ }
	Load() {
		global
		this.transtemp := this.fadein ? 0 : this.trans
		; If this.fadein ; || this.sizein
		; 	this.LoadStart()
		GUI, % this.guiname ":Destroy"
		Gui, % this.guiname ":+LastFound"
		WinSet, Transcolor, % "808080 " this.transtemp
		;~ WinSet, Transparent, 75
		Gui, % this.guiname ":Color", 808080
		Gui, % this.guiname ":Margin", 0, 0
		Gui, % this.guiname ":Font", % "s" this.size " c" this.color , % this.style
		Gui, % this.guiname ":Add", Text,% "v" this.var " " ; hwndhwnd " 
			,% (this.ftext ? HTFn_bigger(this.text,this.ftext) : this.text) ;  gsb_GuiMove ;
		this.hwnd := hwnd
		;~ GuiControl,% this.guiname ":+g",% this.var,% this.glabel
		gggg := this.Gmove.Bind(this)
		GuiControl, % this.guiname ":+g", % this.var, % gggg
		; GuiControl,% this.guiname ":+g",% this.var, %Gmover%
		; MsgBox % "GuiControl, " this.guiname ":+g, " this.var ",% " this.glabel()
;		GuiControlGet, P, Pos
		Gui, % this.guiname ":-Caption +AlwaysOnTop +ToolWindow +E0x08000000"
		Gui, % this.guiname ":Show", % "x" this.x " y" this.y " NoActivate", % this.guiname
		GuiControl, % this.guiname ":Text",% this.var, % this.text
		If this.fadein || this.flash ; || this.sizein
			this.LoadEnd()
		this.LoadWinVars()
		this.ChooseBiggerText()
		this.Resize()
		this.RedrawGUI()
	}  ; (this.cww ? " w" this.cww : "") (this.cwh ? " h" this.cwh : "")
	/*
		LoadStart() {
			If this.fadein {
				this.transtemp := 0
			}
			/*
			If this.sizein {
				this.sizeend := this.size
				this.size := 1
			}
			
		}
	*/
	LoadEnd() {
		If this.fadein {
			this.fadeinstep := this.fadeinstep ? this.fadeinstep : default_values.GUITextFadeInStep
			HTFn_SetTimer(this.fadeinlabel,this.fadein)
		}
		/*
			If this.sizein {
				this.sizeinstep := this.sizeinstep ? this.sizeinstep : default_values.GUITextSizeInStep
				SizeIn := this.sizeinlabel
				SetTimer, %SizeIn%, % this.sizein
			}
		*/
		If this.flash
			HTFn_SetTimer(this.flashlabel,abs(this.flash))
	}
	FlashL() {
		;~ If this.ftext {
		if (this.flash > 0) {
			GuiControl, % this.guiname ":Text",% this.var,% this.text
			this.flash := -this.flash
		} else {
			GuiControl, % this.guiname ":Text",% this.var,% this.ftext
			this.flash := abs(this.flash)
		}
		;~ } else {
			;~ if (this.flash > 0) {
				;~ WinSet, Transcolor,% "808080 " this.trans,% this.guiname
				;~ this.flash := -this.flash
			;~ } else {
				;~ WinSet, Transcolor,% "808080 " 0,% this.guiname
				;~ this.flash := abs(this.flash)
			;~ }
		;~ }
		If ! this.flash {
			HTFn_SetTimer(this.flashlabel,"Off")
			this.SetTrans(this.trans)
		}
	}
	FadeInL() {
		FadeSwitch := this.fadeswitchlabel
		SetTimer, %FadeSwitch%, Off
		this.transtemp += this.fadeinstep
		If (this.transtemp > this.trans) {
			this.transtemp := this.trans
			HTFn_SetTimer(this.fadeinlabel,"Off")
		}
		WinSet, Transcolor,% "808080 " this.transtemp,% this.guiname ; this.SetTrans(this.transtemp)
	}
	/*
		SizeInL() { ; too slow and ugly.  Need to figure out how through a postmessage or DLLCall...
			this.size += this.sizeinstep
			If (this.size > this.sizeend) {
				this.size := this.sizeend
				SizeIn := this.sizeinlabel
				SetTimer, %SizeIn%, Off
			}
			this.SetSize(this.size)
		}
		SizeOutL() {
		}
	*/
	Redraw() {
		If this.fadeswitch ;  || this.sizeswitch
			this.RedrawSwitch()
		Else
			this.RedrawGUI()  
	}
	RedrawGUI() {
		global
		this.w := this.w ? this.w : this.winW
		this.h := this.h ? this.h : this.winH
		;~ MsgBox % this.w "`," this.h
		Gui, % this.guiname ":Font",% " s" this.size " c" this.color,% this.style
		If Errorlevel
			this.Load()
		GuiControl, % this.guiname ":Font",% this.var
		GuiControl, % this.guiname ":Text",% this.var,% this.text
		GuiControl, % this.guiname ":Move",% this.var, % "w" this.w " h" this.h ; (this.cww ? " w" this.cww : this.w) (this.cwh ? " h" this.cwh : this.h) ;  
		Gui, % this.guiname ":Show", % "x" this.x " y" this.y " w" this.w " h" this.h " NoActivate", % this.guiname ;  AutoSize
	}
	RedrawSwitch() {
		;~ If this.fadeswitch {
		this.fadeswitchstep := this.fadeswitchstep ? this.fadeswitchstep : default_values.GUITextFadeSwitchStep
		this.transtemp := this.trans
		HTFn_SetTimer(this.fadeswitchlabel,this.fadeswitch)
		;~ }
	}
	FadeSwitchL() {
		this.transtemp -= this.fadeswitchstep
		If (this.transtemp <= 0) {
			this.transtemp := 0
			this.fadeswitchstep := -(Abs(this.fadeswitchstep))
			; WinSet, Transcolor,% "808080 " this.transtemp,% this.guiname ; this.SetTrans(this.transtemp)
			this.RedrawGUI()
			; Return
		}
		If (this.fadeswitchstep < 0) && (this.transtemp >= this.trans) {
			this.transtemp := this.trans
			this.fadeswitchstep := Abs(this.fadeswitchstep)
			; this.SetTrans(this.transtemp)
			HTFn_SetTimer(this.fadeswitchlabel,"Off")
			; Return
		}
		WinSet, Transcolor,% "808080 " this.transtemp,% this.guiname
	}
	Move(para_mx,para_my,para_mrelative := 0) {
		this.x := para_mrelative ? this.x + x : para_mx
		this.y := para_mrelative ? this.y + y : para_my
		;~ WinMove,% this.guiname, , this.x, this.y ; this is a really slow command!!
		this.Redraw() ; this is way faster
	}
	Set(color := "", font := "", size := 0, text := "", trans := "") { ; UNTESTED
		this.color := color
			? HTFn_BeforeAfterInt(this.ColorList 
			? this.ColorList 
			: default_values.colorarray,color,this.color)
			: this.color
		this.style := font
			? HTFn_BeforeAfterInt(this.FontList 
			? this.FontList 
			: default_values.fontarray,font,this.style)
			: this.style
		this.size := size ? size : this.size
		this.text := text ? text : this.text
		this.ChooseBiggerText()
		If trans
			this.SetTrans(trans)
		If size || text || font
			this.Resize()
		this.ReDraw()
	}
	Resize() {  ;YOU STILL NEED TO ADJUST THIS ONCE HELPTEXT AND FONTCHANGE IS IN ORDER
		this.w := (this.size) * 1.5 * this.widertext ; was 1.5
		this.h := (this.size) * 2.5 * this.tallertext ; was 2.5
		;~ MsgBox % this.w "`," this.h
	}
	ChooseBiggerText() {
		If this.ftext {
			this.widertext := HTFn_TextWidest(this.text) > HTFn_TextWidest(this.ftext)
				? HTFn_TextWidest(this.text) : HTFn_TextWidest(this.ftext)
			this.tallertext := HTFn_TextLines(this.text) > HTFn_TextLines(this.ftext)
				? HTFn_TextLines(this.text) : HTFn_TextLines(this.ftext)
		} Else {
			this.widertext := HTFn_TextWidest(this.text)
			this.tallertext := HTFn_TextLines(this.text)
		}
	}
	SetColor(color) { ; Tested
		this.color := HTFn_BeforeAfterInt(this.ColorList 
			? this.ColorList 
			: default_values.colorarray,color,this.color)
		this.Redraw()
	}
	SetFont(font) {
		this.style := HTFn_BeforeAfterInt(this.FontList 
			? this.FontList 
			: default_values.fontarray,font,this.style)
		this.Resize()
		this.Redraw()
	}
	SetSize(size) {
		this.size := size
		this.Resize()
		this.Redraw()
	}
	SetText(text) {
		this.text := text
		this.ChooseBiggerText()
		this.Resize()
		this.Redraw()
	}
	SetTrans(trans) {
		this.trans := trans
		WinSet, Transcolor,% "808080 " trans,% this.guiname ; OK as far as speed (125 ms w 100 itinerations)
	}
	Fonts {
		get {
			Return HTFn_ShowObject(this.FontList,this.guiname)
		}
		set {
			this.FontList := value
		}
	}
	Colors {
		get {
			Return HTFn_ShowObject(this.ColorList,this.guiname)
		}
		set {
			this.ColorList := value
		}
	}
	GMove() {
		WinSet, Transcolor,% "808080 " this.trans,% this.guiname
		if this.movable
			PostMessage, 0xA1,2,,,% this.guiname ; This has to be last
		if this.nonmovable
			HTFn_Tooltip("No!! You Can't Move it!")
		if this.savemovable {
			HTFn_SetTimer(this.flashlabel, "Off")
			HTFn_Hotkey("ON",this.mouseuplabel,"~LButton UP")
			If this.CheckDrags() { ; Maybe if you want, break the !^#+ into AltCtrlWinShift if you end up using....
				this.TransferValues()
				this.GetDragMessage()
				this.DragHotKeys("ON")
				HTFn_SetTimer(this.dragtt,100)
			}
			PostMessage, 0xA1,2,,,% this.guiname ; This has to be last
			this.ChooseBiggerText()
			this.Resize()
			this.RedrawGUI()
			If StrLen(this.savemovable) > 1 {
				HTFn_IniObject(this.savemovable,this.savemovablesection,this,this.savevalues)
			}
		}
		
		;~ this.trans := this.transend
		;~ PostMessage, 0xA1,2,,,% this.guiname
		;~ Hotkey, ~LButton UP, this.DragWindowMouseUp(), ON
	}
	DragHotkeys(para_cmd) {
		HTFn_Hotkey(para_cmd,this.changelabel,this.dragfontchange,this.dragsizechange,this.dragcolorchange,this.dragtranschange,this.dragcustomchange)
	}
	GetDragMessage() {
		this.dragmessage := "To configure:`n"
		this.dragmessage .= this.dragfontchange ? "   Font`, press " this.dragfontchange "  (" this.style ")`n" : ""
		this.dragmessage .= this.dragsizechange ? "   Size`, press " this.dragsizechange "  (" this.size ")`n" : ""
		this.dragmessage .= this.dragcolorchange ? "   Color`, press " this.dragcolorchange "  (" this.color ")`n" : ""
		this.dragmessage .= this.dragtranschange ? "   Transparency`, press " this.dragtranschange "  (" this.trans ")`n" : ""
		this.dragmessage .= this.dragcustomchange 
			? "   " this.dragcustomchangename "`, press " this.dragcustomchange "  (" this[(this.dragcustomchangename)] ")" : ""
	}
	DragToolTip() {
		HTFn_ToolTip(this.dragmessage)
	}
	CheckDrags() {
		If (this.dragfontchange || this.dragsizechange || this.dragcolorchange || this.dragtranschange || this.dragcustomchange) {
			Return True
		}
		Return False
	}
	DragWindowMouseUp() {
		HTFn_SetTimer(this.dragtt,"off")
		HTFn_Tooltip("")
		this.LoadWinVars(1)
		; setvar, probably save to disk after closedown...
		HTFn_Hotkey("OFF",this.mouseuplabel,"~LButton UP")
		If this.text = "TEXT*~*~TEXT*~*~TEXT"
			this.text := ""
		If this.CheckDrags() {
			this.DragHotKeys("OFF")
			HTFn_Hotkey("OFF",this.changelabel,"Up","Down","Enter","Esc")
		}
		If this.flash {
			this.flash := abs(this.flash)
			HTFn_SetTimer(this.flashlabel,this.flash)
		}
		this.Load()
		;~ if % this.savemovable
			;~ MsgBox Variable exists!
	}
	WhichDragHotkey(para_wdhotkey,para_wdhstring,para_wdhkey) {
		If (A_ThisHotkey = para_wdhotkey) {
			this.beingchanged := para_wdhstring
			this.dragmessage := "Press Up/Down to Configure " this.beingchanged ": " this[(para_wdhkey)] "`nPress Enter to Accept`nPress Esc to Cancel"
			;~ this.DragHotkeys("OFF")
			HTFn_Hotkey("ON",this.changelabel,"Up","Down","Enter","Esc")
		}
	}
	WhichDragHotkeyUpDown(para_wdhkey,para_wdhstring,para_wdhmath,para_wdhlimit := 0) {
		If (this.beingchanged = para_wdhstring) {
			this[(para_wdhkey)] := ! para_wdhlimit ? para_wdhmath > 0 ? para_wdhmath : 0
				: A_ThisHotkey = "Up" ? para_wdhmath < para_wdhlimit ? para_wdhmath : para_wdhlimit
				: para_wdhmath > para_wdhlimit ? para_wdhmath : para_wdhlimit
			this.dragmessage := "Press Up/Down to Configure " this.beingchanged ": " this[(para_wdhkey)] "`nPress Enter to Accept`nPress Esc to Cancel"
		}
	}
	ChangeL() {
		this.WhichDragHotkey(this.dragfontchange,"Font","style")
		this.WhichDragHotkey(this.dragsizechange,"Size","size")
		this.WhichDragHotkey(this.dragcolorchange,"Color","color")
		this.WhichDragHotkey(this.dragtranschange,"Transparency","trans")
		this.WhichDragHotkey(this.dragcustomchange,this.dragcustomchangename,this.dragcustomchangename)
		If (A_ThisHotkey = "Up") {
			this.WhichDragHotkeyUpDown("style","Font",HTFn_After(this.FontList ? this.FontList : default_values.fontarray,this.style))
			this.WhichDragHotkeyUpDown("color","Color",HTFn_After(this.ColorList ? this.ColorList : default_values.colorarray,this.color))
			this.WhichDragHotkeyUpDown("size","Size",this.size + default_values.GUITextSizeChangeHotkeyStep,this.dragsizeulimit)
			this.WhichDragHotkeyUpDown("trans","Transparency",this.trans + default_values.GUITextTransChangeHotkeyStep,this.dragtransulimit)
			this.WhichDragHotkeyUpDown(this.dragcustomchangename,this.dragcustomchangename
				,this[(this.dragcustomchangename)] + this.dragcustomchangestep,this.dragcustomulimit)
		}
		If (A_ThisHotkey = "Down") {
			this.WhichDragHotkeyUpDown("style","Font",HTFn_Before(this.FontList ? this.FontList : default_values.fontarray,this.style))
			this.WhichDragHotkeyUpDown("color","Color",HTFn_Before(this.ColorList ? this.ColorList : default_values.colorarray,this.color))
			this.WhichDragHotkeyUpDown("size","Size",this.size - default_values.GUITextSizeChangeHotkeyStep,this.dragsizellimit)
			this.WhichDragHotkeyUpDown("trans","Transparency",this.trans - default_values.GUITextTransChangeHotkeyStep,this.dragtransllimit)
			this.WhichDragHotkeyUpDown(this.dragcustomchangename,this.dragcustomchangename
				,this[(this.dragcustomchangename)] - this.dragcustomchangestep,this.dragcustomllimit)
		}
		If (A_ThisHotkey = "Enter" || A_ThisHotkey = "Esc") {
			HTFn_Hotkey("OFF",this.changelabel,"Up","Down","Enter","Esc")
			;~ this.DragHotkeys("ON")
			If (A_ThisHotkey = "Esc") {
				this.TransferValues(1)
				this.RedrawGUI()
				this.SetTrans(this.trans)
				this.DragWindowMouseUp()
			}
			this.GetDragMessage()
		}
		this.LoadWinVars(1)
		if (this.text = "")
			this.text := "TEXT*~*~TEXT*~*~TEXT"
		If (this.beingchanged = "Font" || this.beingchanged = "Size") {
			this.ChooseBiggerText()
			this.Resize()
		}
		this.RedrawGUI()
		this.SetTrans(this.trans)
		;~ WinMove,,,,this.w,this.h
	}
	Property {
		get { ; := this.text
			MsgBox I've been got!
			;~ return ...
		}
		set { ; this.text :=
			MsgBox I've been set!  %value%
			;~ return ... := value
		}
	}
	Variables {
		get {
			For key, val in this
				txt .= key " = " val "`n"
			Return "values:`n`n" txt "`n"
		}	
		set {
		}
	}
}



DefaultsGuiTextVars:
activekey := {}
activekeytext := {}
notification.q := {}
GUIall := {}

default_values := {}
default_values.GUITextSaveValues := "color,size,style,trans,x,y,state"
default_values.GUITextSaveFile := "GUIText.ini"
default_values.GUITextSaveSection := "GUIText_Settings"
default_values.GUITextFlash := 500
default_values.GUITextFadeIn := 5
default_values.GUITextFadeInStep := 20
default_values.GUITextFadeOut := 5
default_values.GUITextFadeOutStep := 20
default_values.GUITextFadeSwitch := 5
default_values.GUITextFadeSwitchStep := 20
default_values.GUITextSizeIn := 100
default_values.GUITextSizeInStep := 3
default_values.GUITextSizeOut := 100
default_values.GUITextSizeOutStep := 3
default_values.GUITextSizeSwitch := 100
default_values.GUITextSizeSwitchStep := 3
default_values.GUITextFontChangeHotkey := "f"
default_values.GUITextSizeChangeHotkey := "s"
default_values.GUITextSizeChangeHotkeyStep := 1
default_values.GUITextSizeChangeHotkeyULimit := 100
default_values.GUITextSizeChangeHotkeyLLimit := 1
default_values.GUITextColorChangeHotkey := "c"
default_values.GUITextTransChangeHotkey := "t"
default_values.GUITextTransChangeHotkeyStep := 5
default_values.GUITextTransChangeHotkeyULimit := 255
default_values.GUITextTransChangeHotkeyLLimit := 0
default_values.GUITextCustomChangeHotkey := "d"
default_values.GUITextCustomChangeHotkeyName := "Delay_ms"
default_values.GUITextCustomChangeHotkeyStep := 250
default_values.GUITextCustomChangeHotkeyValue := 0
default_values.GUITextCustomChangeHotkeyULimit := 10000
default_values.GUITextCustomChangeHotkeyLLimit := 0

default_values.GUITextQueTime := 2000
default_values.GUIMsgVList := []
default_values.GUIMsgVList := ["color","style","size","text","trans","x","y"]

default_values.color := "Lime"
default_values.font := "OCR A Extended"
default_values.colorarray := ["Black","Silver","White","Maroon","Red","Purple","Fuchsia","Green","Lime","Olive","Yellow","Navy","Blue","Teal","Aqua"]
default_values.fontarray := ["Arial","Arial Black","Arial Bold","Arial Bold Italic","Arial Italic","Book Antiqua","Calisto MT","Century Gothic","Century Gothic Bold","Century Gothic Bold Italic","Century Gothic Italic","Comic Sans MS","Comic Sans MS Bold","Copperplate Gothic Bold","Copperplate Gothic Light","Courier","Courier New","Courier New Bold","Courier New Bold Italic","Courier New Italic","Franklin Gothic Medium","Franklin Gothic Medium Italic","Georgia","Georgia Bold","Georgia Bold Italic","Georgia Italic","Impact","Lucida Console","Lucida Handwriting Italic","Lucida Sans Italic","Lucida Sans Unicode","Modern","MS Sans Serif","MS Serif","Mv Boli","OCR A Extended","Palatino Linotype","Palatino Linotype Bold","Palatino Linotype Bold Italic","Palatino Linotype Italic","Roman","Script","Small Fonts","Tahoma","Tahoma Bold","Tempus Sans ITC","Times New Roman","Times New Roman Bold","Times New Roman Bold Italic","Times New Roman Italic","Trebuchet MS","Trebuchet MS Bold","Trebuchet MS Bold Italic","Trebuchet MS Italic","Verdana","Verdana Bold","Verdana Bold Italic","Verdana Italic"]
Return


/*
	Without Symbols:
	["Abadi MT Condensed Light","Arial","Arial Alternative Regular","Arial Alternative Symbol","Arial Black","Arial Bold","Arial Bold Italic","Arial Italic","Book Antiqua","Calisto MT","Century Gothic","Century Gothic Bold","Century Gothic Bold Italic","Century Gothic Italic","Comic Sans MS","Comic Sans MS Bold","Copperplate Gothic Bold","Copperplate Gothic Light","Courier","Courier New","Courier New Bold","Courier New Bold Italic","Courier New Italic","Estrangelo Edessa","Franklin Gothic Medium","Franklin Gothic Medium Italic","Gautami","Georgia","Georgia Bold","Georgia Bold Italic","Georgia Italic","Georgia Italic Impact","Impact","Latha","Lucida Console","Lucida Handwriting Italic","Lucida Sans Italic","Lucida Sans Unicode","Matisse ITC","Modern","Modern MS Sans Serif","MS Sans Serif","MS Serif","Mv Boli","News Gothic MT","News Gothic MT Bold","News Gothic MT Italic","OCR A Extended","Palatino Linotype","Palatino Linotype Bold","Palatino Linotype Bold Italic","Palatino Linotype Italic","Roman","Script","Small Fonts","Smallfonts","Tahoma","Tahoma Bold","Tempus Sans ITC","Times New Roman","Times New Roman Bold","Times New Roman Bold Italic","Times New Roman Italic","Trebuchet","Trebuchet Bold","Trebuchet Bold Italic","Trebuchet Italic","Trebuchet MS","Trebuchet MS Bold","Trebuchet MS Bold Italic","Trebuchet MS Italic","Tunga","Verdana","Verdana Bold","Verdana Bold Italic","Verdana Italic","Westminster","WST_Czech","WST_Engl","WST_Fren","WST_Germ","WST_Ital","WST_Span","WST_Swed"]
*/

/*
	Without nonworking/unusable fonts and symbols:
	["Arial","Arial Black","Arial Bold","Arial Bold Italic","Arial Italic","Book Antiqua","Calisto MT","Century Gothic","Century Gothic Bold","Century Gothic Bold Italic","Century Gothic Italic","Comic Sans MS","Comic Sans MS Bold","Copperplate Gothic Bold","Copperplate Gothic Light","Courier","Courier New","Courier New Bold","Courier New Bold Italic","Courier New Italic","Franklin Gothic Medium","Franklin Gothic Medium Italic","Georgia","Georgia Bold","Georgia Bold Italic","Georgia Italic","Impact","Lucida Console","Lucida Handwriting Italic","Lucida Sans Italic","Lucida Sans Unicode","Modern","MS Sans Serif","MS Serif","Mv Boli","OCR A Extended","Palatino Linotype","Palatino Linotype Bold","Palatino Linotype Bold Italic","Palatino Linotype Italic","Roman","Script","Small Fonts","Tahoma","Tahoma Bold","Tempus Sans ITC","Times New Roman","Times New Roman Bold","Times New Roman Bold Italic","Times New Roman Italic","Trebuchet MS","Trebuchet MS Bold","Trebuchet MS Bold Italic","Trebuchet MS Italic","Verdana","Verdana Bold","Verdana Bold Italic","Verdana Italic"]
*/

/*
	Everything:
	["Abadi MT Condensed Light","Arial","Arial Alternative Regular","Arial Alternative Symbol","Arial Black","Arial Bold","Arial Bold Italic","Arial Italic","Book Antiqua","Calisto MT","Century Gothic","Century Gothic Bold","Century Gothic Bold Italic","Century Gothic Italic","Comic Sans MS","Comic Sans MS Bold","Copperplate Gothic Bold","Copperplate Gothic Light","Courier","Courier New","Courier New Bold","Courier New Bold Italic","Courier New Italic","Estrangelo Edessa","Franklin Gothic Medium","Franklin Gothic Medium Italic","Gautami","Georgia","Georgia Bold","Georgia Bold Italic","Georgia Italic","Georgia Italic Impact","Impact","Latha","Lucida Console","Lucida Handwriting Italic","Lucida Sans Italic","Lucida Sans Unicode","Marlett","Matisse ITC","Modern","Modern MS Sans Serif","MS Sans Serif","MS Serif","Mv Boli","News Gothic MT","News Gothic MT Bold","News Gothic MT Italic","OCR A Extended","Palatino Linotype","Palatino Linotype Bold","Palatino Linotype Bold Italic","Palatino Linotype Italic","Roman","Script","Small Fonts","Smallfonts","Symbol","Tahoma","Tahoma Bold","Tempus Sans ITC","Times New Roman","Times New Roman Bold","Times New Roman Bold Italic","Times New Roman Italic","Trebuchet","Trebuchet Bold","Trebuchet Bold Italic","Trebuchet Italic","Trebuchet MS","Trebuchet MS Bold","Trebuchet MS Bold Italic","Trebuchet MS Italic","Tunga","Verdana","Verdana Bold","Verdana Bold Italic","Verdana Italic","Webdings","Westminster","Wingdings","WST_Czech","WST_Engl","WST_Fren","WST_Germ","WST_Ital", "WST_Span","WST_Swed"]
	
*/
