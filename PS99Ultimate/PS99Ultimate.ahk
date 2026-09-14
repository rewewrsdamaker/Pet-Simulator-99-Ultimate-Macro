#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode("Mouse", "Client")
CoordMode("Pixel", "Client")

#Include Paths\ToEgg6.ahk
#Include Paths\ToEgg7.ahk
#Include Paths\ToEgg8.ahk
#Include Paths\FromEgg6.ahk
#Include Paths\FromEgg7.ahk
#Include Paths\FromEgg8.ahk
#Include Paths\CollectCoins.ahk
#Include Paths\LobbyToGreenPortal.ahk
#Include Paths\BoostMachine.ahk
#Include Paths\CraftHuge.ahk

global mainGui := ""
global statusGui := ""
global ddlEgg := ""
global chkAutoRejoin := ""
global chkCoins := ""
global chkBoost := ""
global chkCraft := ""
global txtHatchSec := ""
global txtCoinMin := ""
global txtBoostHrs := ""
global txtBoostMins := ""
global txtRecDelay := ""
global txtStatus := ""
global txtStatusOverlay := ""
global isRunning := false
global isHatchingState := false
global initialized := false
global isPathRunning := false

global liveLogBuffer := ""

CreateGUI()

CreateGUI() {
    global mainGui, statusGui, ddlEgg, chkAutoRejoin, chkCoins, chkBoost, chkCraft
    global txtHatchSec, txtCoinMin, txtBoostHrs, txtBoostMins, txtRecDelay, txtStatus, txtStatusOverlay
    
    mainGui := Gui("+AlwaysOnTop", "PS99 Ultimate Macro")
    mainGui.SetFont("s9", "Segoe UI")
    
    tabs := mainGui.Add("Tab3", "w460 h300", ["General", "Tasks", "Settings"])
    
    tabs.UseTab(1)
    mainGui.Add("Text", "x20 y45", "Select Target Egg:")
    ddlEgg := mainGui.Add("DropDownList", "x135 y42 w120", ["Egg6", "Egg7", "Egg8"])
    ddlEgg.Value := 1
    
    chkAutoRejoin := mainGui.Add("Checkbox", "x20 y85 Checked", "Enable Auto Rejoin / Disconnect Recovery")
    
    mainGui.Add("GroupBox", "x20 y120 w260 h140", "Quick Info & Keybinds")
    mainGui.Add("Text", "x35 y145", "• Egg Hatching: Configurable Seconds")
    mainGui.Add("Text", "x35 y170", "• Path Execution: Modular Engine v2.0")
    mainGui.Add("Text", "x35 y195", "• Start / Pause / Stop: GUI Buttons Below")
    mainGui.Add("Text", "x35 y220", "• Hotkeys: F1 (Start), F2 (Pause), F3 (Stop)")
    
    tabs.UseTab(2)
    chkCoins := mainGui.Add("Checkbox", "x20 y45 Checked", "Enable Auto Coin Collection")
    chkBoost := mainGui.Add("Checkbox", "x20 y75 Checked", "Enable Auto Boost Machine")
    chkCraft := mainGui.Add("Checkbox", "x20 y105 Disabled", "Enable Craft Huge (Coming Soon)")
    
    tabs.UseTab(3)
    mainGui.Add("Text", "x20 y45", "Hatch Click Interval (sec):")
    txtHatchSec := mainGui.Add("Edit", "x200 y42 w80", "10")
    
    mainGui.Add("Text", "x20 y85", "Coin Collection (min):")
    txtCoinMin := mainGui.Add("Edit", "x200 y82 w80", "8")
    
    mainGui.Add("Text", "x20 y125", "Boost Machine Interval:")
    txtBoostHrs := mainGui.Add("Edit", "x180 y122 w35", "4")
    mainGui.Add("Text", "x220 y125", "h")
    txtBoostMins := mainGui.Add("Edit", "x245 y122 w35", "0")
    mainGui.Add("Text", "x285 y125", "m")
    
    mainGui.Add("Text", "x20 y165", "Reconnect Delay (sec):")
    txtRecDelay := mainGui.Add("Edit", "x200 y162 w80", "30")
    
    tabs.UseTab(0)
    
    mainGui.Add("Text", "x300 y15 w160", "Live Status:")
    txtStatus := mainGui.Add("Edit", "x300 y35 w160 h100 ReadOnly vtxtStatusBox", "Ready...")
    btnCopyLog := mainGui.Add("Button", "x300 y140 w160 h25", "Copy Live Status")
    btnCopyLog.OnEvent("Click", CopyLiveStatus)
    
    btnStart := mainGui.Add("Button", "x20 y325 w100 h35", "Start")
    btnPause := mainGui.Add("Button", "x130 y325 w100 h35", "Pause")
    btnStop  := mainGui.Add("Button", "x240 y325 w100 h35", "Stop")
    
    btnStart.OnEvent("Click", StartMacro)
    btnPause.OnEvent("Click", PauseMacro)
    btnStop.OnEvent("Click", StopMacro)
    
    Hotkey("F1", StartMacro)
    Hotkey("F2", PauseMacro)
    Hotkey("F3", StopMacro, "P21000")
    
    mainGui.OnEvent("Close", (*) => ExitApp())
    
    statusGui := Gui("+AlwaysOnTop -SysMenu +ToolWindow", "PS99 Active Status")
    statusGui.SetFont("s9", "Segoe UI")
    statusGui.Add("Text", "x15 y12 w250", "PS99 Macro Running - Live Status:")
    txtStatusOverlay := statusGui.Add("Edit", "x15 y35 w270 h180 ReadOnly", "Macro active...")
    
    mainGui.Show()
}

CopyLiveStatus(*) {
    global liveLogBuffer
    A_Clipboard := liveLogBuffer
    UpdateStatus("Copied full live status log history to clipboard!")
}

UpdateStatus(message) {
    global txtStatus, txtStatusOverlay, liveLogBuffer
    timestamp := A_Hour ":" A_Min ":" A_Sec
    logEntry := "[" timestamp "] " message "`n"
    
    liveLogBuffer := logEntry liveLogBuffer
    txtStatus.Value := liveLogBuffer
    if (txtStatusOverlay) {
        txtStatusOverlay.Value := liveLogBuffer
    }
}

StartMacro(*) {
    global isRunning, chkAutoRejoin, mainGui, statusGui, isHatchingState, initialized, ddlEgg, isPathRunning
    if (isRunning)
        return
    
    isRunning := true
    UpdateStatus("Macro Started.")
    
    mainGui.Minimize()
    
    statusX := A_ScreenWidth - 310
    statusGui.Show("w300 h230 x" statusX " y40")
    
    isPathRunning := true
    
    UpdateStatus("Initializing Route: Lobby to Portal...")
    portalPath := GetLobbyToGreenPortalPath()
    RunPath(portalPath, 7)
    
    selectedEgg := ddlEgg.Text
    UpdateStatus("Routing to Target Egg: " selectedEgg)
    RunPath(GetToEggPath(selectedEgg))
    isPathRunning := false
    
    isHatchingState := true
    initialized := true
    UpdateStatus("Arrived at egg. Starting loops.")
    
    if (chkAutoRejoin.Value) {
        SetTimer(CheckDisconnect, 60000)
    }
    
    SetTimer(MainMacroLoop, 100)
}

PauseMacro(*) {
    global isRunning, mainGui, statusGui, chkAutoRejoin
    if (isRunning) {
        isRunning := false
        SetTimer(CheckDisconnect, 0)
        SetTimer(MainMacroLoop, 0)
        UpdateStatus("Macro Paused.")
        
        statusGui.Hide()
        mainGui.Restore()
    } else {
        isRunning := true
        UpdateStatus("Macro Resumed.")
        
        mainGui.Minimize()
        statusX := A_ScreenWidth - 310
        statusGui.Show("w300 h230 x" statusX " y40")
        
        SetTimer(MainMacroLoop, 100)
        if (chkAutoRejoin.Value) {
            SetTimer(CheckDisconnect, 60000)
        }
    }
}

StopMacro(*) {
    global isRunning, mainGui, statusGui, isHatchingState, initialized, isPathRunning
    Critical("Off")
    
    isRunning := false
    isHatchingState := false
    initialized := false
    isPathRunning := false
    
    SetTimer(CheckDisconnect, 0)
    SetTimer(MainMacroLoop, 0)
    UpdateStatus("Macro Stopped.")
    
    statusGui.Hide()
    mainGui.Restore()
}

WaitForLoadingScreen() {
    global isRunning
    UpdateStatus("Monitoring ReconnectDetector.png...")
    timeout := A_TickCount + 60000
    
    detectTimeout := A_TickCount + 10000
    while (isRunning && A_TickCount < detectTimeout) {
        if ImageSearch(&foundX, &foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "Paths\ReconnectDetector.png") {
            break
        }
        PreciseSleep(300)
    }
    
    while (isRunning && A_TickCount < timeout) {
        if (!ImageSearch(&foundX, &foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "Paths\ReconnectDetector.png")) {
            UpdateStatus("Loading screen cleared!")
            PreciseSleep(1500)
            return true
        }
        PreciseSleep(500)
    }
    UpdateStatus("Loading screen timeout reached, proceeding anyway...")
    return false
}

CheckDisconnect() {
    global ddlEgg, isRunning, chkAutoRejoin, isHatchingState, initialized, txtRecDelay, isPathRunning
    if (!isRunning || !chkAutoRejoin.Value)
        return
        
    if (!WinExist("Roblox") || ImageSearch(&foundX, &foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "Paths\DisconnectDetector.png")) {
        UpdateStatus("Disconnect screen or crash detected! Reconnecting...")
        isHatchingState := false
        initialized := false
        isPathRunning := true
        
        RunWait('taskkill /f /im RobloxPlayerBeta.exe', , 'Hide')
        PreciseSleep(1500)
        
        Run('roblox://experiences/start?placeId=8737899170')
        
        recDelaySec := Number(txtRecDelay.Value)
        if (!recDelaySec || recDelaySec < 5)
            recDelaySec := 30
            
        UpdateStatus("Waiting " recDelaySec "s for game client...")
        if WinWait("Roblox", , recDelaySec) {
            WinActivate("Roblox")
            PreciseSleep(2000)
            
            UpdateStatus("Waiting for initial menu screen...")
            PreciseSleep(1500)
            
            if WinExist("Roblox") {
                WinGetPos(&wx, &wy, &ww, &wh, "Roblox")
                MouseMove(Integer(ww * 0.49), Integer(wh * 0.61), 20)
            } else {
                MouseMove(940, 656, 20)
            }
            PreciseSleep(150)
            Click("down")
            PreciseSleep(100)
            Click("up")
            PreciseSleep(1000)
            
            UpdateStatus("Post-Reconnect Path: Lobby to Portal & Egg")
            portalPath := GetLobbyToGreenPortalPath()
            RunPath(portalPath, 7)
            
            currentEgg := ddlEgg.Text
            RunPath(GetToEggPath(currentEgg))
            isHatchingState := true
            initialized := true
            isPathRunning := false
            return true
        }
        isPathRunning := false
    }
    return false
}

MainMacroLoop() {
    global isRunning, isHatchingState, ddlEgg, isPathRunning
    global txtHatchSec, txtCoinMin, txtBoostHrs, txtBoostMins
    global chkCoins, chkBoost, txtRecDelay
    
    static lastHatchTick := 0
    static lastCoinTick := 0
    static lastBoostTick := 0
    static lastRejoinTick := 0
    static initializedTicks := false
    
    if (!isRunning || isPathRunning)
        return
        
    currentTime := A_TickCount
    
    if (!initializedTicks) {
        lastHatchTick := currentTime
        lastCoinTick := currentTime
        lastBoostTick := currentTime - ((14400000) - 30000)
        lastRejoinTick := currentTime
        initializedTicks := true
        return
    }
    
    fiveHoursMs := 5 * 3600000
    if (currentTime - lastRejoinTick >= fiveHoursMs) {
        lastRejoinTick := currentTime
        isPathRunning := true
        UpdateStatus("5-Hour scheduled limit reached. Performing routine game restart...")
        
        isHatchingState := false
        initialized := false
        
        RunWait('taskkill /f /im RobloxPlayerBeta.exe', , 'Hide')
        PreciseSleep(1500)
        
        Run('roblox://experiences/start?placeId=8737899170')
        
        recDelaySec := Number(txtRecDelay.Value)
        if (!recDelaySec || recDelaySec < 5)
            recDelaySec := 30
            
        UpdateStatus("Waiting " recDelaySec "s for game client...")
        if WinWait("Roblox", , recDelaySec) {
            WinActivate("Roblox")
            PreciseSleep(2000)
            
            UpdateStatus("Waiting for initial menu screen...")
            PreciseSleep(1500)
            
            if WinExist("Roblox") {
                WinGetPos(&wx, &wy, &ww, &wh, "Roblox")
                MouseMove(Integer(ww * 0.49), Integer(wh * 0.61), 20)
            } else {
                MouseMove(940, 656, 20)
            }
            PreciseSleep(150)
            Click("down")
            PreciseSleep(100)
            Click("up")
            PreciseSleep(1000)
            
            UpdateStatus("Routine Restart Path: Lobby to Portal & Egg")
            portalPath := GetLobbyToGreenPortalPath()
            RunPath(portalPath, 7)
            
            currentEgg := ddlEgg.Text
            RunPath(GetToEggPath(currentEgg))
            isHatchingState := true
            initialized := true
            isPathRunning := false
            return
        }
        isPathRunning := false
    }
    
    hatchSec := Number(txtHatchSec.Value)
    if (!hatchSec || hatchSec < 0.5)
        hatchSec := 10
    hatchIntervalMs := hatchSec * 1000
    
    if (isHatchingState && (currentTime - lastHatchTick >= hatchIntervalMs)) {
        lastHatchTick := currentTime
        UpdateStatus("Hatching egg click.")
        
        if WinExist("Roblox") {
            WinGetPos(&wx, &wy, &ww, &wh, "Roblox")
            MouseMove(Integer(ww * 0.5), Integer(wh * 0.66), 20)
        } else {
            MouseMove(960, 713, 20)
        }
        PreciseSleep(100)
        Click("down")
        PreciseSleep(100)
        Click("up")
    }
    
    if (chkCoins.Value && !isPathRunning) {
        coinMin := Number(txtCoinMin.Value)
        if (!coinMin || coinMin < 0.1)
            coinMin := 8
        coinIntervalMs := coinMin * 60000
        
        if (currentTime - lastCoinTick >= coinIntervalMs) {
            lastCoinTick := currentTime
            isPathRunning := true
            UpdateStatus("Executing Auto Coin Collection...")
            currentEgg := ddlEgg.Text
            
            RunPath(GetFromEggPath(currentEgg))
            RunPath(GetCollectCoinsPath())
            RunPath(GetToEggPath(currentEgg))
            
            isPathRunning := false
            return
        }
    }
    
    if (chkBoost.Value && !isPathRunning) {
        boostHrs := Number(txtBoostHrs.Value)
        boostMins := Number(txtBoostMins.Value)
        if (boostHrs < 0)
            boostHrs := 0
        if (boostMins < 0)
            boostMins := 0
            
        boostIntervalMs := (boostHrs * 3600000) + (boostMins * 60000)
        if (boostIntervalMs <= 0)
            boostIntervalMs := 14400000 
            
        if (currentTime - lastBoostTick >= boostIntervalMs) {
            lastBoostTick := currentTime
            isPathRunning := true
            UpdateStatus("Executing Auto Boost Machine...")
            currentEgg := ddlEgg.Text
            
            RunPath(GetFromEggPath(currentEgg))
            RunPath(GetBoostMachinePath())
            RunPath(GetToEggPath(currentEgg))
            
            isPathRunning := false
            return
        }
    }
}

RunPath(pathArray, pauseAfterStep := 0) {
    global isRunning
    
    if (!IsObject(pathArray)) {
        UpdateStatus("Error: Path array is invalid or missing!")
        return
    }
    
    targetWin := WinExist("ahk_exe RobloxPlayerBeta.exe") ? "ahk_exe RobloxPlayerBeta.exe" : "Roblox"
    
    if WinExist(targetWin) {
        WinActivate(targetWin)
        PreciseSleep(500)
        
        WinGetPos(&wx, &wy, &ww, &wh, targetWin)
        Click(ww // 2, 35)
        PreciseSleep(500)
    }
    
    for index, step in pathArray {
        if (!isRunning)
            break
            
        if (IsObject(step)) {
            duration := HasProp(step, "duration") ? Max(step.duration, 100) : 100
            
            postStepDelay := 1000
            if (HasProp(step, "delay") && step.delay > 1000) {
                postStepDelay := step.delay
            }
            
            actionType := HasProp(step, "action") ? step.action : "key"
            
            if (actionType == "key") {
                if (pauseAfterStep == 7 && index == 6) {
                    keyToPress := "Enter"
                } else if (pauseAfterStep == 7 && index == 7) {
                    keyToPress := "\"
                } else {
                    keyToPress := HasProp(step, "key") ? step.key : ""
                }
                
                if (keyToPress != "") {
                    UpdateStatus("Step [" index "] KEY: " keyToPress " | Hold: " duration "ms | Pause After: " postStepDelay "ms")
                    SendRobloxInput(keyToPress, duration)
                    PreciseSleep(postStepDelay)
                }
            } else if (actionType == "click") {
                UpdateStatus("Step [" index "] MOUSE CLICK | Hold: " duration "ms | Pause After: " postStepDelay "ms")
                posX := HasProp(step, "x") ? step.x : (HasProp(step, "xpos") ? step.xpos : "")
                posY := HasProp(step, "y") ? step.y : (HasProp(step, "ypos") ? step.ypos : "")
                
                if (posX !== "" && posY !== "") {
                    MouseMove(posX, posY, 10)
                    PreciseSleep(50)
                    Click("down")
                    PreciseSleep(duration)
                    Click("up")
                } else {
                    Click("down")
                    PreciseSleep(duration)
                    Click("up")
                }
                PreciseSleep(postStepDelay)
            }
        }
        
        if (index == pauseAfterStep) {
            UpdateStatus("Step " index " completed. Waiting for loading screen...")
            WaitForLoadingScreen()
        }
    }
}

SendRobloxInput(keyName, duration) {
    k := Trim(keyName)
    kLower := StrLower(k)
    
    if (kLower == "right")
        targetKey := "{Right}"
    else if (kLower == "left")
        targetKey := "{Left}"
    else if (kLower == "up")
        targetKey := "{Up}"
    else if (kLower == "down")
        targetKey := "{Down}"
    else if (kLower == "enter")
        targetKey := "{Enter}"
    else
        targetKey := "{" k "}"

    SendEvent(SubStr(targetKey, 1, StrLen(targetKey)-1) " down}")
    PreciseSleep(duration)
    SendEvent(SubStr(targetKey, 1, StrLen(targetKey)-1) " up}")
}

PreciseSleep(durationMs) {
    global isRunning
    targetTime := A_TickCount + durationMs
    while (A_TickCount < targetTime) {
        if (!isRunning)
            break
        Sleep(10)
    }
}

GetToEggPath(eggName) {
    switch Trim(eggName) {
        case "Egg6": return GetToEgg6Path()
        case "Egg7": return GetToEgg7Path()
        case "Egg8": return GetToEgg8Path()
        default:     return GetToEgg6Path()
    }
}

GetFromEggPath(eggName) {
    switch Trim(eggName) {
        case "Egg6": return GetFromEgg6Path()
        case "Egg7": return GetFromEgg7Path()
        case "Egg8": return GetFromEgg8Path()
        default:     return GetFromEgg6Path()
    }
}
