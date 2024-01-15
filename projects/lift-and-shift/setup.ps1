Start-Transcript -path C:\vm-setup.log

Write-Output '* Install .net'
Invoke-RestMethod "https://dot.net/v1/dotnet-install.ps1" -OutFile "dotnet-install.ps1"
& .\dotnet-install.ps1

Write-Output '** build project'
Invoke-RestMethod "https://jungfile.blob.core.windows.net/file/src.zip" -OutFile "src.zip"
Expand-Archive -LiteralPath "src.zip" -DestinationPath "C:\src"
dotnet publish "C:\src\ToDoList.csproj" -c Release -o "C:\src\publish"

Write-Output '*** Installing Windows features'
Install-WindowsFeature Web-Server,NET-Framework-45-ASPNET,Web-Asp-Net45

Write-Output '**** IIS Setting'
New-WebAppPool -Name "TodoList"
Set-ItemProperty IIS:\AppPools\ToDoList -Name "managedRuntimeVersion" -Value ""
New-WebSite -Name "TodoList" -Port 80 -PhysicalPath "C:\src\publish"

Write-Output '***** Firewall setting'
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow

Write-Output '****** Install .net hosting'
Invoke-RestMethod "https://download.visualstudio.microsoft.com/download/pr/2a7ae819-fbc4-4611-a1ba-f3b072d4ea25/32f3b931550f7b315d9827d564202eeb/dotnet-hosting-8.0.0-win.exe" -OutFile "dotnet-hosting-8.0.0-win.exe"
Start-Process -FilePath "dotnet-hosting-8.0.0-win.exe" -Args "/install /quiet /norestart" -Wait

iisreset

Stop-WebSite -Name "Default Web Site"
Start-Website -Name "TodoList"