#Requires AutoHotkey v2.0
#SingleInstance Force

global recordingArray := []
global keyStartTime := Map()
global lastActionTick := A_TickCount

F5::ToggleRecording()

ToggleRecording() {
    global recordingArray, lastActionTick, keyStartTime
    static ih := ""
    
    if (!IsObject(ih)) {
        recordingArray := []
        keyStartTime.Clear()
        lastActionTick := A_TickCount
        
        ih := InputHook("V L0")
        ih.KeyOpt("{All}", "N")
        ih.OnKeyDown := OnKeyDown
        ih.OnKeyUp := OnKeyUp
        ih.Start()
        ToolTip("🔴 RECORDING ACTIVE (Press F5 to Stop)")
    } else {
        ih.Stop()
        ih := ""
        ToolTip()
        ExportRecording()
    }
}

OnKeyDown(ih, vk, sc) {
    global keyStartTime
    keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
    if (keyName = "" || keyName = "F5")
        return
    
    keyName := StrLower(keyName)
    if (!keyStartTime.Has(keyName)) {
        keyStartTime[keyName] := A_TickCount
    }
}

OnKeyUp(ih, vk, sc) {
    global recordingArray, lastActionTick, keyStartTime
    keyName := GetKeyName(Format("vk{:x}sc{:x}", vk, sc))
    if (keyName = "" || keyName = "F5")
        return
        
    keyName := StrLower(keyName)
    if (keyStartTime.Has(keyName)) {
        startTime := keyStartTime[keyName]
        currentTick := A_TickCount
        duration := currentTick - startTime
        delay := startTime - lastActionTick
        if (delay < 0)
            delay := 0
            
        recordingArray.Push(Map("action", "key", "key", keyName, "duration", duration, "delay", delay))
        lastActionTick := currentTick
        keyStartTime.Delete(keyName)
    }
}

ExportRecording() {
    global recordingArray
    if (recordingArray.Length == 0) {
        MsgBox("No keys were recorded!")
        return
    }
    
    output := "GetCustomPath() {`n    return [`n"
    for index, step in recordingArray {
        comma := (index < recordingArray.Length) ? "," : ""
        output .= "        {action: `"key`", key: `"" step["key"] "`", duration: " step["duration"] ", delay: " step["delay"] "}" comma "`n"
    }
    output .= "    ]`n}`n"
    
    A_Clipboard := output
    MsgBox("Recording saved! Code copied to clipboard (" recordingArray.Length " steps).")
}