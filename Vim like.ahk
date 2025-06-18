#Requires AutoHotkey v2.0

/********************************************************************************************
CAPSLOCK DOBLE SHIFT
; Presionar dos veces Shift rápidamente → Activa o desactiva CapsLock // Deshabilitado
Presionar dos veces CapsLock rápidamente -> tecla Escape

NAVEGACIÓN BÁSICA
CapsLock + h → Mover cursor a la izquierda (equiv. Vim: h)
CapsLock + j → Mover cursor hacia abajo (equiv. Vim: j)
CapsLock + k → Mover cursor hacia arriba (equiv. Vim: k)
CapsLock + l → Mover cursor a la derecha (equiv. Vim: l)
CapsLock + w → Mover al inicio de la siguiente palabra (equiv. Vim: w)
CapsLock + b → Mover al inicio de la palabra anterior (equiv. Vim: b)
CapsLock + e → Mover al final de la palabra actual (equiv. Vim: e)
CapsLock + 0 → Ir al inicio de línea (equiv. Vim: 0)
CapsLock + 4 → Ir al final de línea (equiv. Vim: $)
CapsLock + 6 → Ir al primer carácter no blanco (equiv. Vim: ^)
CapsLock + g → Ir al final del documento (equiv. Vim: G)
CapsLock + t → Ir al inicio del documento (equiv. Vim: gg)

REPETICIÓN
CapsLock + . → Repetir último comando (equiv. Vim: .) 

ELIMINACIÓN Y COPIADO
CapsLock + d + d → Eliminar línea completa (equiv. Vim: dd)
CapsLock + d + w → Eliminar palabra a la derecha (equiv. Vim: dw)
CapsLock + d + i + w → Eliminar palabra interna sin espacios (equiv. Vim: diw)
CapsLock + x → Retroceso o borrar carácter (equiv. Vim: x o dx)

COPIADO Y PEGADO
CapsLock + y + y → Copiar línea completa (equiv. Vim: yy)
CapsLock + y + w → Copiar palabra (equiv. Vim: yw)
CapsLock + p → Pegar desde el portapapeles (equiv. Vim: p)

MODO VISUAL
CapsLock + v → Activar o desactivar modo visual (equiv. Vim: v)
Luego usar h/j/k/l para expandir la selección

DESHACER
CapsLock + u → Deshacer última acción (equiv. Vim: u)

SCROLLING
CapsLock + ´ → Scroll arriba unas 15 líneas (equiv. Vim: Ctrl + u)
CapsLock + { → Scroll abajo unas 15 líneas (equiv. Vim: Ctrl + d)

*********************************************************************************************/


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
} */

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

; Map 0 to beginning of line
CapsLock & 0::DoMovement("{Home}{Home}")

; Map 4 to End (end of line)   // it's $ in vim
CapsLock & 4::DoMovement("{End}")

; Map 6 to move cursor to first non-whitespace char // It's ^ in vim
CapsLock & 6::{ 
    DoMovement("{Home}{Home}", true)
    DoMovement("^{Right}")
}

; Maps e to move cursor to end of current word
CapsLock & e::{ 
    HandleWord("{Right}")
    DoMovement("{Left}") 
}

; Maps g to go to finish of document
CapsLock & g:: {
    DoMovement("^{End}")
}

; Maps t to start of document
CapsLock & t:: {
    DoMovement("^{Home}")
}

; === Movement ===
CapsLock & h:: DoMovement("{Left}")
CapsLock & j:: DoMovement("{Down}")
CapsLock & k:: DoMovement("{Up}")
CapsLock & l:: DoMovement("{Right}")
CapsLock & w:: HandleWord("{Right}")
CapsLock & b:: HandleWord("{Left}")


CapsLock & SC01A:: { 
    ; ´ Moves some lines up
    global currenMode
    if currentMode = "visual" {
        Send("+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Up}+{Down}+{Down}+{Down}+{Down}+{Down}")    
    } else {
        Send("{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Down}{Down}{Down}{Down}{Down}")
    }
    Sleep(50)
    /*Loop SCROLL + SCROLL_CONTEXT
        DoMovement("{Up}")
    Loop SCROLL_CONTEXT
        DoMovement("{Down}")*/
}
CapsLock & {:: {
    ; { Moves some lines up  //}}
    global currentMode
    if currentMode = "visual" {
        Send("+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Down}+{Up}+{Up}+{Up}+{Up}+{Up}")
    }else{
        Send("{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Down}{Up}{Up}{Up}{Up}{Up}")
    }
    Sleep(50)
    return    
    /*Loop SCROLL + SCROLL_CONTEXT
        DoMovement("{Down}")
    Loop SCROLL_CONTEXT
        DoMovement("{Up}")*/
}

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
        Send("{Home}+{End}")
        Sleep(SHORT)
        Send("{Del}")
        lastCommand := "dd"
        currentCommand := ""
    } else {
        currentCommand := "d"
        SetTimer(ClearCommand, -WAIT)
    }
}
{}
CapsLock & y::{
    global currentCommand, lastCommand
    if currentCommand = "y" {
        Send("{Home}+{End}")
        Sleep(SHORT)
        Send("^c")
        lastCommand := "yy"
        currentCommand := ""
    } else {
        currentCommand := "y"
        SetTimer(ClearCommand, -WAIT)
    }
}
{}
; ==== Single commands

CapsLock & x::{ ; Backspace or delete
    global currentCommand, lastCommand
    if currentCommand = "d" {
        Send("{Del}")
        lastCommand := "dx"
        currentCommand := ""
    } else {
        Send("{Backspace}")
        lastCommand := "x"
    }
}

CapsLock & p:: { ; Paste
    global lastCommand
    Send("^v")
    lastCommand := "p"
}

CapsLock & u:: Send("^z")  ; Undo


; === Repeat last command ==========

CapsLock & .:: {
    global lastCommand
    switch lastCommand {
        case "dd":
            Send("{Home}+{End}")
            Sleep(SHORT)
            Send("{Del}")
        case "dw":
            DoCommand("dw")
        case "db":
            DoCommand("db")
        case "yy":
            Send("{Home}+{End}")
            Sleep(SHORT)
            Send("^c")
        case "p":
            Send("^v")
        case "dx":
            Send("{Del}")
        case "x":
            Send("{Backspace}")
        case "diw":
            Send("^{Left}^+{Right}{Del}")
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
        DoCommand(dir = "{Right}" ? "dw" : "db")
        lastCommand := dir = "{Right}" ? "dw" : "db"
        currentCommand := ""
    } else if currentCommand = "y" {
        Send("^+" dir)
        Sleep(SHORT)
        Send("^c")
        lastCommand := "yw"
        currentCommand := ""
    } else if currentCommand = "di" && dir = "{Right}" { ; Simulate 'diw' = delete inner word
        Send("^{Left}^+{Right}{Del}")
        lastCommand := "diw"
        currentCommand := ""
    } else if currentMode = "visual" {
        Send("+^" dir)
        ResetVisualModeTimer()
    } else {
        Send("^" dir)
    }
}

; === Movement with visual selection ===
DoMovement(key, skipDelete := false) {
    global currentCommand, currentMode
    if currentCommand = "v" || currentMode = "visual" {
        Send("+" key)
    } else if currentCommand = "d" && !skipDelete {
        if key = "{Left}" {
            Send("{Backspace}")
            lastCommand := "x"
        } else if key = "{Right}" {
            Send("{Delete}")
            lastCommand := "dx"
        } else if key = "{End}" || key = "{Home}" || key = "^{End}" || key = "^{Home}"
                || key = "{Down}" || key = "{Up}"{
            Send("+" key "{Delete}")
            lastCommand := ""
        }
    } else {
        Send(key)
    }
    if currentMode {
        ResetVisualModeTimer()
    }
}

ClearCommand(*) {
    global currentCommand
    currentCommand := ""
}

DoCommand(command) {
    if command = "dw" {
        Send("^+{Right}")
        Sleep(SHORT)
        Send("{Del}")
    }else if command = "db" {
        Send("^+{Left}")
        Sleep(SHORT)
        Send("{Del}")
    }
}

; Block all CapsLock combinations not otherwise handled
CapsLock & *::return
