﻿#Requires AutoHotkey v2.0
#SingleInstance

SetCapsLockState("AlwaysOff")
SendMode("Input")

global SHORT := 30      ; Wait so two events don't collapse, eg. send home and end
global WAIT := 600    ; Wait for user next character input, eg. press d WAIT 3 WAIT w
global DOUBLE := 300    ; Wait for double press of caps lock
global MOUSE_STEP := 20       ; mouse movement per capslock + enter + hjkl keys

global currentCommand := ""
global lastCommand := ""
global currentMode := ""
global currentNumber := ""

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

; === Number management for repetition

CapsLock & 2:: HandleNumber("2")
CapsLock & 3:: HandleNumber("3")
CapsLock & 4:: HandleNumber("4")
CapsLock & 5:: HandleNumber("5")
CapsLock & 6:: HandleNumber("6")
CapsLock & 7:: HandleNumber("7")
CapsLock & 8:: HandleNumber("8")

HandleNumber(number) {
    global currentNumber
    currentNumber := number
    SetTimer(ClearNumber, -WAIT)
    SetTimer(ClearCommand, -WAIT)
    ResetVisualModeTimer()
}

ClearNumber(*) {
    global currentNumber
    currentNumber := ""
}
; === Navigation =====

CapsLock & 0::HandleKey("0")
CapsLock & 9::HandleKey("9")

CapsLock & e::HandleKey("e")
CapsLock & g::HandleKey("g")
CapsLock & t::HandleKey("t")
CapsLock & m::HandleMouseKey("m")
CapsLock & ,::HandleMouseKey(",")

; === Movement ===
CapsLock & h:: HandleMouseKey("h")
CapsLock & j:: HandleMouseKey("j")
CapsLock & k:: HandleMouseKey("k")
CapsLock & l:: HandleMouseKey("l")

CapsLock & Left:: HandleMouseKey("left")
CapsLock & Down:: HandleMouseKey("down")
CapsLock & Up:: HandleMouseKey("up")
CapsLock & Right:: HandleMouseKey("right")

CapsLock & Space:: HandleMouseKey(" ")
#HotIf GetKeyState("CapsLock", "P") && GetKeyState("Enter", "P")
Alt::HandleMouseKey("Alt")
#HotIf

#HotIf GetKeyState("CapsLock", "P")
Alt::HandleMouseKey("Alt")
#HotIf

CapsLock & Enter:: {
    ; This ignores the enter key when pressed together with caps lock
}
CapsLock & w:: HandleMouseKey("w")
CapsLock & b:: HandleMouseKey("b")

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
    SetTimer(EndVisualMode, -WAIT) ; restart timer for 500ms
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

; === i commands after d or y ===
CapsLock & i:: {
    global currentCommand
    if currentCommand = "d" {
        currentCommand := "di"
        SetTimer(ClearCommand, -WAIT)
    } else if currentCommand = "y" {
        currentCommand := "yi"
        SetTimer(ClearCommand, -WAIT)
    }
}

; === Word motion with operators ===
HandleWord(dir) {
    global currentCommand, lastCommand, currentMode
    if currentCommand = "d" {
        dir = "{Right}" ? DoCommand("dw") : DoCommand("db")
    } else if currentCommand = "y" {
        dir = "{Right}" ? DoCommand("yw") : DoCommand("yb")
    } else if currentCommand = "di" && dir = "{Right}" { ; Simulate 'diw' = delete inner word
        DoCommand("diw")
    } else if currentCommand = "yi" && dir = "{Right}" {
        DoCommand("yiw")
    } else if currentMode = "visual" {
        Send("+^" dir)
        ResetVisualModeTimer()
    } else {
        Send("^" dir)
    }
}

; === Movement with posible command or visual state ===
DoMovement(key, skipDelete := false) {
    global currentCommand, currentMode
    if currentCommand = "v" || currentMode = "visual" {
        Send("+" key)
    } else if currentCommand = "d" && !skipDelete {
        if key = "{Left}" {
            Send("{Backspace}")
            lastCommand := "x"
        } else if key = "{Right}" {
            DoCommand("x")
        } else if key = "{End}" || key = "{Home}" || key = "^{End}" || key = "^{Home}"
                || key = "{Down}" || key = "{Up}"{
            Send("+" key )
            Sleep(SHORT)
            Send("{Delete}")
            lastCommand := ""
        }
    } else if currentCommand = "d" && skipDelete {
        if key = "{End}" || key = "{Home}" || key = "^{End}" || key = "^{Home}"
                         || key = "{Down}" || key = "{Up}"
                         || key = "{PgUp}" || key = "{PgDn}" {
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
    global currentNumber, currentCommand
    SetTimer(ClearCommand, 0)
    repeatCount := currentNumber ? Number(currentNumber) : 1
    loop repeatCount {
        switch key {
            case "0": ; Map 0 to beginning of line
                DoMovement("{Home}", true)
                DoMovement("{Home}")
            case "9": ; Map 9 to End (end of line) // it's $ in vim
                DoMovement("{End}")
            case "e": ; Map e to end of word
                HandleWord("{Right}")
                DoMovement("{Left}")
            case "g": ; Map g to finish of document
                DoMovement("^{End}")
            case "t": ; Map t to start of document
                DoMovement("^{Home}")
            case "m": ; Map m to Page Down
                DoMovement("{PgDn}")
            case ",": ; Map , to Page Up
                DoMovement("{PgUp}")
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
    currentCommand := ""
    currentNumber := ""
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
            Send("{Backspace}")
        case "x":
            Send("{Del}")
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
        case "yiw":
            Send("^{Left}")
            Sleep(SHORT)
            Send("^+{Right}")
            Sleep(SHORT)
            Send("^c")
        case "p":
            Send("^v")
        case "u":
            Send("^z")
    }
    lastCommand := command
}

HandleMouseKey(key) {
    global MOUSE_STEP

    if GetKeyState("Enter", "P") {
        switch key {
            case "l":
                DoMouseMove("right")
            case "w":
                DoMouseMove("right", true)
            case "h":
                DoMouseMove("left")
            case "b":
                DoMouseMove("left", true)
            case "j":
                DoMouseMove("down")
            case "m":
                DoMouseMove("down", true)
            case "k":
                DoMouseMove("up")
            case ",":
                DoMouseMove("up", true)
            case " ":
                Click()
            case "Alt":
                Click("Right")
        }
    } else if key = "up" || key = "down" || key = "left" || key = "right" {
        DoMouseMove(key, GetKeyState("LShift", "P"))
    } else if key = "Alt" || key = " " {
        switch key {
            case " ":
                Click()
            case "Alt":
                Click("Right")
        }
    } else {
        HandleKey(key)
    }
}

DoMouseMove(direction, fast := false) {
    global MOUSE_STEP
    MouseGetPos(&x, &y)
    fast_factor := (fast ? 5 : 1)
    switch direction {
        case "right":
            MouseMove(x + fast_factor * MOUSE_STEP, y)
        case "left":
            MouseMove(x - fast_factor * MOUSE_STEP, y)
        case "up":
            MouseMove(x, y - fast_factor * MOUSE_STEP)
        case "down":
            MouseMove(x, y + fast_factor * MOUSE_STEP)
    }
}

; Block all CapsLock combinations not otherwise handled
CapsLock & *::return
  