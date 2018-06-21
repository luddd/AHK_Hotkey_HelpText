# AHK_Hotkey_HelpText
An Autohotkey tool that helps you keep track of your hotkeys.

PREFACE

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
  
  
 
  IMPLEMENTATION:
  To include the Hotkeys in an AutoHotkey script, add an explanation between double semicolons:
  
  !#^+e::  ;;This is an example;;
  
  ... then include the AutoHotkey script using the options below:
  
  Option 1:
  	Run HelpTextFunctions.ahk (or .exe if compiled)
	Edit the HelpTextFunctionsHelp.ini file that is created
	List the AutoHotkey files under the [AutoHotkeyFileList] section like so:
	
		[AutoHotkeyFileList]
		Add AutoHotkey files here to include their Hotkeys in the HelpText Script
		C:\Users\User\Desktop\Test1.ahk
		Test2.ahk
		[HelpSettings]

Option 2:
	Assign the scripts to the HelpScript variable or object like so:
	
		HelpScript := {}
		HelpScript.Test1 := "Test1.ahk"
		HelpScript.Test2 := "C:\Users\User\Desktop\Test2.ahk"
		HelpScript.Test3 := "Test3.ahk"
	or
		HelpScript := "Test1.ahk"
	
Option 3:
	Add an 
		#Include HelpTextFunctions.ahk 
	AT THE BOTTOM of another script and add
		Gosub, HelpText
	Somewhere in the main thread.
	
If the variable/object HelpScript is not defined, HelpText will pull any explained hotkeys out of the
Host script.


CONFIGURATION
The HelpText messager may be configured by simply dragging and dropping.  When The left mouse button is held down
on the text, a tooltip gives simple instructions for configuring the following:

Font (press f)
Size (press s)
Color (press c)
Transparency (press t)
Delay_ms (press d)  (This is a delay before the help text pops up after activating modifiers

Keep the mouse button down until text is configured and positioned how you want it.  When you drop the text,
The settings are saved in the Help.ini file.


HOTKEYS
When an AutoHotkey Script's hotkeys and explanations are pulled, they are also saved to the script in the Help.ini file.  The intent
is to use those hotkeys if the script pulled from is compiled.  If some of the hotkeys or explanations are deleted or changed in a
script, they are updated in the Help.ini file; however, if none are pulled in the initial read, the hotkeys/expanations in the
Help.ini are left untouched.



EXTRA ITEMS (READ IF YOU ARE BORED)

HELPTEXT MESSAGER
There are other options that are also changable if you so desire that are usually not configured.  These can be configured by
adding/editing the following values in the script(the values I am listing are the default values already):

help.hotkeys := ["^/","^!/"]  			; an array of hotkeys for turning HelpText on/off.  ? substitutes / in the script.
help.reload := ["^!'"] 				; An Array of hotkeys (only one here) for re-loading HelpText
help.hotkeysexplain := "Turns on/off the help text" ; The explanation for the HelpText on/off hotkey
help.reloadexplain := "Reload HelpText" 	; ditto for HelpText re-load

And finally this monster:
help.options .= " +savemovable{" AA_ScriptFullPath "Help.ini<HelpSettings>} +dragallchange +dragcustomchange +draglimits +savevalues{color,size,style,trans,x,y,Delay_ms,<help.state>state}"
	
	help.options is concatenated so that you may initially (or afterwards) set or concatenate more options if you wish.
	The above options are needed to allow HelpText to work as it should.  However, there are additional options that you
	may want to use.  Some you could try to get the feel for the possibilities are " +fadein +fadeout +fadeswitch "
	Try them and see what they do!
	
	These options are part of the GUIText class being used for the HelpText Messager. I haven't provided a full documentation
	for the GUIText class yet.  The options are somewhat self-explanatory if you look in the class Options() method.
	options are implemented with a + and de-implemented with a -.  Fading, Flashing, the drag-save configuration method,
	and their corresponding steps, speed, etc. are some of the options available.  The class is crudely constructed as it
	was done in my AutoHotkey infancy, so I may revisit it some to streamline it.

