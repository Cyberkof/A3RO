Option Explicit

Dim oFSO, oShell, sDir, sHTML, sURL, sEdge, aPaths, i

Set oFSO   = CreateObject("Scripting.FileSystemObject")
Set oShell = CreateObject("WScript.Shell")

sDir  = oFSO.GetParentFolderName(WScript.ScriptFullName) & "\"
sHTML = sDir & "apps\claude-dashboard\index.html"
sURL  = "file:///" & Join(Split(sHTML, "\"), "/")

' Parse usage data silently (window hidden, waits for completion)
oShell.Run "cmd /c node """ & sDir & "apps\claude-dashboard\parse-usage.js""", 0, True

' Find Edge (always present on Windows 11)
aPaths = Array( _
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe", _
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe" _
)
sEdge = ""
For i = 0 To UBound(aPaths)
    If oFSO.FileExists(aPaths(i)) Then
        sEdge = aPaths(i)
        Exit For
    End If
Next

If sEdge <> "" Then
    ' --app removes all browser chrome — looks and behaves like a native app
    oShell.Run """" & sEdge & """ --app=""" & sURL & """ --start-maximized --no-first-run", 1, False
Else
    ' Fallback: default browser
    oShell.Run """" & sHTML & """"
End If

Set oFSO   = Nothing
Set oShell = Nothing
