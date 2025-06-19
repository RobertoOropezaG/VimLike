#Requires AutoHotkey v2.0
#SingleInstance

SetCapsLockState("AlwaysOff")
SendMode("Input")

global AUTOSWITCH := 800    ; Turn off visual mode automatically
global SHORT := 50      ; Wait so two events don't collapse, eg. send home and end
global WAIT := 500    ; Wait for user input, eg. press vw
global SCROLL := 15     ; Scroll lines size
global SCROLL_CONTEXT := 15      ; Leave this quantity of extra lines down

global currentCommand := ""
global lastCommand := ""
global currentMode := ""

; ====== Double shift key to toggle caps lock ========
/* Turns out I tend to double press shift...

global lastShiftTime := 0

~LShift::{ 
    CheckDoubleShift() 
}
~RShift::{ 
    CheckDoubleShift() 
}

CheckDoubleShift() {
    global lastShiftTime
    now := A_TickCount

    if (now - lastShiftTime) < WAIT {
        ; Detected double press: toggle CapsLock

        capsState := GetKeyState("CapsLock", "T")  ; "T" = toggle state (for toggle keys like CapsLock)
        if capsState { 
            SetCapsLockState("Off")
        }else{
            SetCapsLockState("On")
        }
        lastShiftTime := 0  ; reset
    } else {
        lastShiftTime := now
    }
}
*/

; ==== Double Caps Lock maps to escape! =======
global lastCapsTime := 0

CapsLock:: {
    CheckDoubleCaps()
}
CheckDoubleCaps() {
    global lastCapsTime
    now := A_TickCount

    if (now - lastCapsTime) < WAIT {
        ; Detected double press: do escape
        Send("{Escape}")
    } else {
        lastCapsTime := now
    }
}

; === Navigation =====

CapsLock & 0::HandleKey("0")
CapsLock & 4::HandleKey("4")
CapsLock & 6::HandleKey("6")

CapsLock & e::HandleKey("e")

CapsLock & g::HandleKey("g")

; Maps t to start of document
CapsLock & t::HandleKey("t")

; === Movement ===
CapsLock & h:: HandleKey("h")
CapsLock & j:: HandleKey("j")
CapsLock & k:: HandleKey("k")
CapsLock & l:: HandleKey("l")
CapsLock & w:: HandleKey("w")
CapsLock & b:: HandleKey("b")


CapsLock & SC01A::HandleKey("´") ; Actually "´" character
CapsLock & {::HandleKey("{")

; === Visual Mode Toggle ===
EndVisualMode(*) {
    global currentMode
    currentMode := ""
    ToolTip("mode: off") 
    SetTimer(() => ToolTip(), -WAIT)   ; clear tooltip
}

CapsLock & v::{
    global currentMode
    DoSetVisualMode(!currentMode)
}

DoSetVisualMode(newMode) {
    global currentMode
    currentMode := newMode ? "visual" : ""
    ToolTip currentMode ? currentMode ": ON" : "mode: OFF"  ; show a tooltip (optional)
    SetTimer(() => ToolTip(), -WAIT)
}

ResetVisualModeTimer() {
    SetTimer(EndVisualMode, -AUTOSWITCH) ; restart timer for 500ms
}


; === Command Starters ===
CapsLock & d::{
    global currentCommand, lastCommand
    if currentCommand = "d" {
        DoCommand("dd")
    } else {
        currentCommand := "d"
        SetTimer(ClearCommand, -WAIT)
    }
}
{}
CapsLock & y::{
    global currentCommand, lastCommand
    if currentCommand = "y" {
        DoCommand("yy")
    } else {
        currentCommand := "y"
        SetTimer(ClearCommand, -WAIT)
    }
}

; ==== Single commands

CapsLock & x::{ ; Backspace or delete
    global currentCommand, lastCommand
    if currentCommand = "d" {
        DoCommand("dx")
    } else {
        DoCommand("x")
    }
}

CapsLock & p:: DoCommand("p")  ; Paste

CapsLock & u:: DoCommand("u")  ; Undo


; === Repeat last command ==========

CapsLock & .:: {
    global lastCommand
    switch lastCommand {
        case "dd":
            DoCommand("dd", true)
        case "dw":
            DoCommand("dw", true)
        case "diw":
            DoCommand("diw", true)
        case "db":
            DoCommand("db", true)
        case "dx":
            DoCommand("dx", true)
        case "x":
            DoCommand("x", true)
        case "yy":
            DoCommand("yy", true)
        case "yw":
            DoCommand("yw", true)
        case "yb":
            DoCommand("yb", true)
        case "p":
            DoCommand("p", true)
        case "u":
            DoCommand("u", true)
    }
}

; === i commands after d ===
CapsLock & i:: {
    global currentCommand
    if currentCommand = "d" {
        currentCommand := "di"
        SetTimer(ClearCommand, -AUTOSWITCH)
    }
}{}

; === Word motion with operators ===
HandleWord(dir) {
    global currentCommand, lastCommand, currentMode
    if currentCommand = "d" {
        dir = "{Right}" ? DoCommand("dw") : DoCommand("db")
    } else if currentCommand = "y" {
        dir = "{Right}" ? DoCommand("yw") : DoCommand("yb")
    } else if currentCommand = "di" && dir = "{Right}" { ; Simulate 'diw' = delete inner word
        DoCommand("diw")
    } else if currentMode = "visual" {
        Send("+^" dir)
        ResetVisualModeTimer()
    } else {
        Send("^" dir)
    }
}

; === Movement with posible visual selection ===
DoMovement(key, skipDelete := false) {
    global currentCommand, currentMode
    if currentCommand = "v" || currentMode = "visual" {
        Send("+" key)
    } else if currentCommand = "d" && !skipDelete {
        if key = "{Left}" {
            Send("{Backspace}")
            lastCommand := "x"
        } else if key = "{Right}" {
            DoCommand("dx")
        } else if key = "{End}" || key = "{Home}" || key = "^{End}" || key = "^{Home}"
                || key = "{Down}" || key = "{Up}"{
            Send("+" key )
            Sleep(SHORT)
            Send("{Delete}")
            lastCommand := ""
        }
    } else if currentCommand = "d" && skipDelete {
        if key = "{End}" || key = "{Home}" || key = "^{End}" || key = "^{Home}"
                         || key = "{Down}" || key = "{Up}"{
            Send("+" key )
            Sleep(SHORT)
            lastCommand := ""
        }
    } else {
        Send(key)
    }
    if currentMode {
        ResetVisualModeTimer()
    }
}

HandleKey(key) {
    switch key {
        case "0": ; Map 0 to beginning of line
            DoMovement("{Home}", true)
            DoMovement("{Home}")
        case "4": ; Map 4 to End (end of line) // it's $ in vim
            DoMovement("{End}")
        case "6": ; Map 6 to move cursor to first non-whitespace char // It's ^ in vim
            DoMovement("{Home}{Home}", true)
            DoMovement("^{Right}")
        case "e": ; Map e to end of word
            HandleWord("{Right}")
            DoMovement("{Left}")
        case "g": ; Map g to finish of document
            DoMovement("^{End}")
        case "t": ; Map t to start of document
            DoMovement("^{Home}")
        case "h": ; Map h to left
            DoMovement("{Left}")
        case "j": ; Map j to down
            DoMovement("{Down}")
        case "k": ; Map k to up
            DoMovement("{Up}")
        case "l": ; Map l to right
            DoMovement("{Right}")
        case "w": ; Map w to next word
            HandleWord("{Right}")
        case "b": ; Map b to previous word
            HandleWord("{Left}")
        case "´": ; Map  to some lines up, I'm using * instead because .ahk have some issues with that character
            {
                global currentMode
                if currentMode = "visual" {
                    Send("+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Down}+{Down}+{Down}+{Down}+{Down}")
                } else {
                    Send("{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Down}{Down}{Down}{Down}{Down}")
                }
                Sleep(50)
                return
            }
        case "{": ; { Moves some lines up
            {
                global currentMode
                if currentMode = "visual" {
                  Send("+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Up}+{Up}+{Up}+{Up}+{Up}")
                }else{
                  Send("{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Up}{Up}{Up}{Up}{Up}")
                }
                Sleep(50)
                return
            }
    }
}

ClearCommand(*) {
    global currentCommand
    currentCommand := ""
}

DoCommand(command, preserveCommand := false) {
    global lastCommand, currentCommand
    switch command {
        case "dd":
            Send("{Home}+{End}")
            Sleep(SHORT)
            Send("{Del}")
        case "dw":
            Send("^+{Right}")
            Sleep(SHORT)
            Send("{Del}")
        case "diw":
            Send("^{Left}^+{Right}")
            Sleep(SHORT)
            Send("{Del}")
        case "db":
            Send("^+{Left}")
            Sleep(SHORT)
            Send("{Del}")
        case "dx":
            Send("{Del}")
        case "x":
            Send("{Backspace}")
        case "yw":
            Send("^+{Right}")
            Sleep(SHORT)
            Send("^c")
        case "yb":
            Send("^+{Left}")
            Sleep(SHORT)
            Send("^c")
        case "yy":
            Send("{Home}+{End}")
            Sleep(SHORT)
            Send("^c")
            Send("{Home}{End}")
        case "p":
            Send("^v")
        case "u":
            Send("^z")
    }
    if !preserveCommand {
        lastCommand := command
        currentCommand := ""
    }
}

; Block all CapsLock combinations not otherwise handled
CapsLock & *::return
