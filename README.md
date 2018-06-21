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
