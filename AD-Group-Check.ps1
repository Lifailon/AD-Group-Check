$group_name = "RDGW_Admins"
$mailFrom = "Report@$env:userdnsdomain"
$mailTo = "support@mail.ru"
$mailSrv = "mail.mail.ru"

$file_name = "$group_name.txt"
$path = "$env:userprofile\Documents\$file_name"
$path_temp = "$env:userprofile\Documents\temp.txt"

function ad-group {
Get-ADGroupMember -Identity $group_name | select @{Label="Name"; Expression={$_.SamAccountName + " (" + $_.Name + ")"}}
}

function compare-group {
Compare-Object -ReferenceObject $check_command -DifferenceObject $check_file
}

if((Test-Path $path) -eq $false) {
New-Item -Path $path;
ad-group > $path
}

$check_file = Get-Content $path
ad-group > $path_temp
$check_command = Get-Content $path_temp

$count = ($check_command.Count)-($check_file.Count)
if ($count -notmatch "-") {
$count = $count -replace "^","+"
}

if (compare-group) {
if ($count -notmatch "-") {
compare-group | select InputObject > $path_temp
$change = Get-Content $path_temp
$change = $change -replace "InputObject"
$change = $change -replace "\-{1,100}"
$change = $change -replace "\s{2,100}"
}

#Send-MailMessage -From "$mailFrom" -To "$mailTo" -Subject "В группе $group_name есть изменени" -Body "
#Изменения: $count пользователь(я)
#$change
#" –SmtpServer "$mailSrv" -Encoding 'UTF8'

Add-Type -AssemblyName System.Windows.Forms
$NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
$NotifyIcon.Icon = [Drawing.Icon]::ExtractAssociatedIcon((Get-Command netplwiz).Path)
$NotifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
$NotifyIcon.BalloonTipTitle = "В группе $group_name есть изменения"
$NotifyIcon.BalloonTipText = "
Изменения: $count пользователь(я)
$change
"
$NotifyIcon.Visible = $true
$NotifyIcon.ShowBalloonTip(10000)
}
Remove-Item -Recurse $path_temp