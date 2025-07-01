#Requires AutoHotkey v2.0

; Botón lateral izquierdo = Ctrl
XButton1::Send("{Ctrl down}")
XButton1 up::Send("{Ctrl up}")

; Botón lateral derecho = Shift
XButton2::Send("{Shift down}")
XButton2 up::Send("{Shift up}")