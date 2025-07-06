#Requires AutoHotkey v2.0
#SingleInstance

XButton1::{
    ScrollWithAcceleration("up")
}

XButton2::{
    ScrollWithAcceleration("down")
}

ScrollWithAcceleration(direction)
{
    delay := 60   ; Initial delay in ms
    step := 5     ; How much to reduce delay each loop
    minDelay := 20 ; Fastest speed

    btn := direction = "up" ? "XButton1" : "XButton2"
    wheel := direction = "up" ? "{WheelUp}" : "{WheelDown}"

    while GetKeyState(btn, "P")
    {
        Send wheel
        Sleep delay
        if (delay > minDelay)
            delay -= step
    }
}
