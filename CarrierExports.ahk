#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

Gui, Add, StatusBar
Gui, Add, Tab3, vCarrierTabs R20 W400
Gui, Tab
Gui, Show,, Active Carrier Exports

; determine log folder
EnvGet, journalPath, USERPROFILE
journalPath .= "\Saved Games\Frontier Developments\Elite Dangerous\"

; get list of logs
SB_SetText("Gathering log files")
fileListOld = ; clear content
fileListNew = ; clear content
Loop, Files, %journalPath%*.log
{
    ; skip pre 2020 logs as FCs weren't a thing then
    if InStr(A_LoopFileName, "Journal.1")
        Continue
    ; skip any logs not from live (such as JournalAlpha, JournalBeta, etc.)
    if not InStr(A_LoopFileName, "Journal.")
        Continue
    ; move new naming convention log files into separate list
    if InStr(A_LoopFileName, "-")
        FileListNew = %FileListNew%%A_LoopFileName%`n
    Else
        FileListOld = %FileListOld%%A_LoopFileName%`n
    total++
}

; sort lists alphabetically
Sort, FileListOld
Sort, FileListNew
FileList := fileListOld . fileListNew

carrierList := {}
events := { CarrierStats : {} , CarrierNameChange : {} , CarrierTradeOrder : {} }

; { "timestamp":"2020-06-18T16:00:22Z", "event":"CarrierStats", "CarrierID":3702178048, "Callsign":"Q6B-8KF", "Name":"HER MAJESTY'S EMBRACE", ...
insertIntoEvents("CarrierStats", "needle", ", ""event"":""CarrierStats", """")
insertIntoEvents("CarrierStats", "id", "CarrierID"":")
insertIntoEvents("CarrierStats", "callsign", "Callsign"":""", """")
insertIntoEvents("CarrierStats", "name", "Name"":""", """")

; { "timestamp":"2020-06-18T16:00:13Z", "event":"CarrierNameChange", "CarrierID":3702178048, "Name":"HER MAJESTY'S EMBRACE", "Callsign":"Q6B-8KF" }
insertIntoEvents("CarrierNameChange", "needle", ", ""event"":""CarrierNameChange", """")
insertIntoEvents("CarrierNameChange", "id", "CarrierID"":")
insertIntoEvents("CarrierNameChange", "name", "Name"":""", """")

; { "timestamp":"2020-06-18T17:59:19Z", "event":"CarrierTradeOrder", "CarrierID":3702178048, "BlackMarket":false, "Commodity":"opal", "Commodity_Localised":"Void Opal", "PurchaseOrder":200, "Price":1000586 }
; { "timestamp":"2020-06-18T18:01:12Z", "event":"CarrierTradeOrder", "CarrierID":3702178048, "BlackMarket":false, "Commodity":"tritium", "PurchaseOrder":500, "Price":416840 }
; { "timestamp":"2020-11-12T16:14:24Z", "event":"CarrierTradeOrder", "CarrierID":3702178048, "BlackMarket":false, "Commodity":"buildingfabricators", "Commodity_Localised":"Building Fabricators", "CancelTrade":true}
; { "timestamp":"2020-11-12T15:19:17Z", "event":"CarrierTradeOrder", "CarrierID":3702178048, "BlackMarket":false, "Commodity":"structuralregulators", "Commodity_Localised":"Structural Regulators", "PurchaseOrder":5000, "Price":1951}
; { "timestamp":"2020-06-22T01:04:43Z", "event":"CarrierTradeOrder", "CarrierID":3702178048, "BlackMarket":false, "Commodity":"performanceenhancers", "Commodity_Localised":"Performance Enhancers", "SaleOrder":1, "Price":6745 }
insertIntoEvents("CarrierTradeOrder", "needle", "event"":""CarrierTradeOrder", """")
insertIntoEvents("CarrierTradeOrder", "carrierID", """CarrierID"":")
insertIntoEvents("CarrierTradeOrder", "BlackMarket", """BlackMarket"":")
insertIntoEvents("CarrierTradeOrder", "Commodity", """Commodity"":""", """")
insertIntoEvents("CarrierTradeOrder", "Commodity_Localised", """Commodity_Localised"":""", """")
insertIntoEvents("CarrierTradeOrder", "buy", """PurchaseOrder"":")
insertIntoEvents("CarrierTradeOrder", "sell", """SaleOrder"":")
insertIntoEvents("CarrierTradeOrder", "cancel", """CancelTrade"":")

result := runCMD("findstr ""\""event\"":\""Carrier"" """ . journalPath . "Journal*.log""")
Loop, Parse, result, `n
{
    logLines .= SubStr(A_LoopField, InStr(A_LoopField, "{")) . "`n"
}
Sort, logLines
result := "" ; free memory

; Loop, parse, FileList, `n
; {
;     if A_LoopField =  ; Ignore the blank item at the end of the list.
;         continue
;     count++
    SB_SetText("Processing") ; (" . count . "/" . total . "): " . A_LoopField)
    ; Loop, Read, %journalPath%%A_LoopField%
    Loop, Parse, logLines, `n
    {
        ; the game doesn't write a "CarrierBuy" event and "CarrierNameChange" doesn't trigger on buying either
        ; "CarrierStats" however gets written when accessing the FC management panel which is a prerequisite for pretty much anything
        ; so we're using this as a workaround for getting a carriers id, callsign, and initial name
        if InStr(A_LoopField, events.CarrierStats.needle.val)
        {
            ; id := SubStr(A_LoopReadLine, InStr(A_LoopReadLine, events.CarrierStats.id.val) + events.CarrierStats.id.len, 10)
            id := extract(A_LoopField, "CarrierStats", "id")
            ; skip if FC is known already
            if carrierList.HasKey(id)
                Continue
            
            callsign := extract(A_LoopField, "CarrierStats", "callsign")
            name := extract(A_LoopField, "CarrierStats", "name")

            carrierList[id] := {"callsign" : callsign, "name" : name, "tradeOrders" : {}}
            Continue
        }

        ; tracking any subsequent name changes is similar to handling "CarrierStats"
        ; { "timestamp":"2020-06-18T16:00:13Z", "event":"CarrierNameChange", "CarrierID":3702178048, "Name":"HER MAJESTY'S EMBRACE", "Callsign":"Q6B-8KF" }
        if InStr(A_LoopField, events.CarrierNameChange.needle.val)
        {
            id := SubStr(A_LoopField, InStr(A_LoopField, events.CarrierNameChange.id.val) + events.CarrierNameChange.id.len, 10)

            carrierList[id].Name := extract(A_LoopField, "CarrierNameChange", "name")
        }

        ; { "timestamp":"2020-06-18T17:59:19Z", "event":"CarrierTradeOrder", "CarrierID":3702178048, "BlackMarket":false, "Commodity":"opal", "Commodity_Localised":"Void Opal", "PurchaseOrder":200, "Price":1000586 }
        ; { "timestamp":"2020-06-18T18:01:12Z", "event":"CarrierTradeOrder", "CarrierID":3702178048, "BlackMarket":false, "Commodity":"tritium", "PurchaseOrder":500, "Price":416840 }
        ; { "timestamp":"2020-11-12T16:14:24Z", "event":"CarrierTradeOrder", "CarrierID":3702178048, "BlackMarket":false, "Commodity":"buildingfabricators", "Commodity_Localised":"Building Fabricators", "CancelTrade":true}
        if InStr(A_LoopField, events.CarrierTradeOrder.needle.val)
        {
            ; determine which FC we're working with
            id := SubStr(A_LoopField, InStr(A_LoopField, events.CarrierTradeOrder.carrierID.val) + events.CarrierTradeOrder.carrierID.len, 10)

            ; get the game's internal commodity name
            commodity := extract(A_LoopField, "CarrierTradeOrder", "Commodity")
            ; show(commodity)

            ; a canceled order is least effort, remove and move on
            if InStr(A_LoopField, events.CarrierTradeOrder.cancel.val)
            {
                carrierList[id].tradeOrders.Delete(commodity)
                Continue
            }

            ; events.CarrierTradeOrder.Commodity_Localised
            name := extract(A_LoopField, "CarrierTradeOrder", "Commodity_Localised")
            if (name == "")
                StringUpper, name, commodity, T
            carrierList[id].tradeOrders[commodity].Name := name

            ; events.CarrierTradeOrder.BlackMarket
            StringUpper, bm, % extract(A_LoopField, "CarrierTradeOrder", "BlackMarket"), T

            type := "?"
            ; events.CarrierTradeOrder.buy
            if (extract(A_LoopField, "CarrierTradeOrder", "buy"))
                type := "Buy"
            
            ; events.CarrierTradeOrder.sell
            if (extract(A_LoopField, "CarrierTradeOrder", "sell"))
                type := "Sell"
            
            carrierList[id].tradeOrders[commodity] := {"Name" : name, "BlackMarket" : bm, "orderType" : type}
        }
    }
; }

SB_SetText("Done")

For id in carrierList
{
    name := carrierList[id].callsign . " " . carrierList[id].name
    GuiControl, , CarrierTabs, %name%||
    Gui, Tab, %name%
    Gui, Add, ListView, Count20 R19 W370 Sort, Commodity Name|Black Market?|Buy/Sell?
    For commodity in carrierList[id].tradeOrders
    {
        name := carrierList[id].tradeOrders[commodity].name
        bm := carrierList[id].tradeOrders[commodity].BlackMarket
        type := carrierList[id].tradeOrders[commodity].orderType
        if (type == "Sell")
            LV_Add("", name, bm, type)
    }
    LV_ModifyCol(1, "AutoHdr")
    LV_ModifyCol(3, "AutoHdr")
    SB_SetText(LV_GetCount() . " total")
}

Gui, Show, AutoSize

; needs FC visibility set to "Everybody" on Inara
; UrlDownloadToFile, https://inara.cz/cmdr-fleetcarrier/342706/200249, keyLen.txt
/* extract substring from
<div id="fleetcarriercargo"
to the immediately following
</table>
*/
; substring contains localized commodity names according to website setting
Return

GuiClose:
ExitApp

GuiSize:
if (ErrorLevel = 1)  ; The window has been minimized. No action needed.
    return
; Otherwise, the window has been resized or maximized. Resize the Edit control to match.
NewWidth := A_GuiWidth - 20
NewHeight := A_GuiHeight - 35
GuiControl, Move, CarrierTabs, W%NewWidth% H%NewHeight%
return

insertIntoEvents(event, key, value, delimiter := ",")
{
    global events
    events[event][key] := {}
    events[event][key].val := value
    events[event][key].len := StrLen(value)
    events[event][key].del := delimiter
}

extract(source, event, key)
{
    global events
    offset := InStr(source, events[event][key].val)
    if (offset == 0)
    {
        ErrorLevel = 1
        Return ""
    }
    offset += events[event][key].len
    length := InStr(source, events[event][key].del, false, offset) - offset
    Return SubStr(source, offset, length)
}

runCMD(command := "") {
    static shell

    if (shell == "")
    {
        DetectHiddenWindows On
        Run %ComSpec%,, Hide, pid
        WinWait ahk_pid %pid%
        DllCall("AttachConsole", "UInt", pid)
        shell := ComObjCreate("WScript.Shell")
        OnExit(A_ThisFunc)
    }

    if (command == "")
    {
        objRelease(shell)
        DllCall( "FreeConsole" )
        Return
    }

    return shell.Exec(ComSpec " /C " command).StdOut.ReadAll()
}
