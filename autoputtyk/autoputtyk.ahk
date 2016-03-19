;-------------------------------------------------------------------------------------
; AutoPuttyk
; Shows a menu when a hotkey is pressed, with all the sessions saved in putty.
; Written by Thomas Steen Rasmussen / Tykling, april 2010
;-------------------------------------------------------------------------------------
; Revision information below:
; $Rev:: 18                                               $:  Revision of last commit
; $Author:: tykling                                       $:  Author of last commit
; $Date:: 2012-04-19 13:20:25 +0200 (to, 19 apr 2012)     $:  Date of last commit
;-------------------------------------------------------------------------------------

if %0% = 0
{
PuttyPath = c:\Programmer\PuTTY\putty.exe
} 
else 
{
PuttyPath = %1%
}

; ------ configuration start
Menu_Hotkey = #a 		;Define the hotkey used to open the menu with putty sessions
; ------ configuration end

; ------ script start
;persistent, keep running from systray
#Persistent

;only allow one instance of this script
#SingleInstance force

;Get SVN revision and use for version string
SvnRev = $Rev: 18 $
StringReplace, SvnRev, SvnRev, `$,, All
StringReplace, SvnRev, SvnRev, Rev: ,
StringReplace, SvnRev, SvnRev, %A_SPACE%,

;string to contain the version of this script
AutoPuttyk_Version = 1.0r%SvnRev% ;Define the script version

;string to contain the title and version of this script
FullTitle = AutoPuttyk %AutoPuttyk_Version% ; Assemble the full title incl. version

;bind the hotkeys as configured
Hotkey, %Menu_Hotkey%, ShowMenu ;Bind the hotkey

;start with an empty var
AllSessions =

;loop through the registry key
Loop, HKEY_CURRENT_USER, Software\SimonTatham\PuTTY\Sessions, 1, 1
{
	if a_LoopRegType = key
	{
		StringReplace, SessionName, a_LoopRegName, `%20, %A_SPACE%, All
		AllSessions = %AllSessions%`n%SessionName%
		SessionCounter++
	}
}

;The session list from registry is not sorted, add the whole thing to a variable,
;convert to a sorted array, loop through the array and build the menu
Sort, AllSessions
StringSplit, SessionArray, AllSessions, `n
Loop, %SessionArray0%
{
    this_session := SessionArray%a_index%
	if (this_session != "") 
	{
		Menu AutoPuttyk, add, %this_session%, RunPutty
	}
}

StringReplace, Printable_Hotkey, Menu_Hotkey, #, Win-

;some output 
TrayTip, %FullTitle%, AutoPuttyk v. %AutoPuttyk_Version% loaded - %SessionCounter% Putty sessions in the menu.`r`n`r`nPress %Printable_Hotkey% to open the menu with putty sessions ; Make systray baloon tip

;Do nothing else for now
return

;Sub for the "show menu" hotkey
ShowMenu:
	Menu AutoPuttyk, Show
return

;Sub to run putty
Runputty:
	Run, %PuttyPath% -load `"%A_ThisMenuItem%`",,Max
return