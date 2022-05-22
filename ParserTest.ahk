/*
---------------------------
CMD:	2987992	 2972.817400
InStr:	2984950	23751.959300
SubStr:	2984950	22019.072200
---------------------------
*/


; determine log folder
EnvGet, journalPath, USERPROFILE
journalPath .= "\Saved Games\Frontier Developments\Elite Dangerous\"

timeCMD    := time("testCMD")
cntCMD := cnt
timeInStr  := time("testInStr")
cntInStr := cnt
timeSubStr := time("testSubStr")
cntSubStr := cnt

MsgBox, CMD:`t%cntCMD%`t%timeCMD%`nInStr:`t%cntInStr%`t%timeInStr%`nSubStr:`t%cntSubStr%`t%timeSubStr%

Return



time(fn)
{
    DllCall("QueryPerformanceFrequency", "Int64*", freq)
    DllCall("QueryPerformanceCounter", "Int64*", CounterBefore)
    %fn%()
    DllCall("QueryPerformanceCounter", "Int64*", CounterAfter)
    Return (CounterAfter - CounterBefore) / freq * 1000
}

countLines(ByRef input)
{
    global cnt := 0
    Loop, Parse, input, `n
    {
        cnt++
    }
}

testCMD()
{
    global journalPath
    result := runCMD("findstr ""\""event\"":\""Carrier"" """ . journalPath . "Journal*.log""")
    Loop, Parse, result, `n
    {
        filtered .= SubStr(A_LoopField, InStr(A_LoopField, "{"))
    }
    Sort, filtered
    ; countLines(filtered)
    global cnt := StrLen(filtered)
}

testInStr()
{
    global journalPath
    Loop, %journalPath%Journal*.log
    {
        Loop, Read, %journalPath%%A_LoopFileName%
        {
        if (InStr(A_LoopReadLine, """event"":""Carrier"))
            result .= A_LoopReadLine
        }
    }
    Sort, result
    ; countLines(result)
    global cnt := StrLen(result)
}

testSubStr()
{
    global journalPath
    Loop, %journalPath%Journal*.log
    {
        Loop, Read, %journalPath%%A_LoopFileName%
        {
        if (SubStr(A_LoopReadLine, 39, 16) == """event"":""Carrier")
            result .= A_LoopReadLine
        }
    }
    Sort, result
    ; countLines(result)
    global cnt := StrLen(result)
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
