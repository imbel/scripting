<#
Windows Forms script to check for breached passwords in the haveibeenpwned breached password database.  This script makes an API call with a piece of the hash of the provided password.
NO COMPLETE PASSWORDS ARE SENT TO THE API, THEY REMAIN LOCAL.
More details on the implementation here https://www.troyhunt.com/ive-just-launched-pwned-passwords-version-2/
To run, simply pass the script with no parameters.  Ensure unsigned scripts are allowed to run on your system.
#>
function getPwned {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$True)]
        [Security.SecureString]$password
    )
    $sha1 = new-object -TypeName System.Security.Cryptography.SHA1CryptoServiceProvider
    $utf8 = new-object -TypeName System.Text.UTF8Encoding
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $pwClear = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $passHash = [System.BitConverter]::ToString($sha1.ComputeHash($utf8.GetBytes($pwClear))) -replace '[-]',''
    $pwClear = $null
    $search = $passHash.substring(0,5)
    $allProtocols = [System.Net.SecurityProtocolType]'Tls11,Tls12'
    [System.Net.ServicePointManager]::SecurityProtocol = $allProtocols
    $subString = $passHash.substring(10)
    $password = $null
    $passHash=$null

    $response = invoke-webrequest -uri https://api.pwnedpasswords.com/range/$search -UseBasicParsing
    $array = $response.Content -split('\r\n')

    foreach ($line in $array) {
        if ($line.contains($subString)) {
            $pwned = $true
            $pwnedTime = $line.split(":")[1]
            Write-Output "This password has been pwned $pwnedTime times!"
        }
        else {
            continue
        }
    }
    if (!$pwned) {
        Write-Output "This password is not in the pwned DB, you should be good!"
    }
    $subString = $null
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

$form = New-Object System.Windows.Forms.Form
$Font = New-Object System.Drawing.Font("Lucida Console",10)
$Form.Font = $Font
$form.Text = "have i been pwned?"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.MinimumSize = New-Object System.Drawing.Size(600,400)
$form.StartPosition = "CenterScreen"

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Size(20,160)
$outputBox.Size = New-Object System.Drawing.Size(520,40)
$outputBox.Dock = "None"
$outputBox.Anchor = "None"
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$Form.Controls.Add($outputBox)

$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Location = New-Object System.Drawing.Point(18,140)
$outputLabel.Size = New-Object System.Drawing.Size(280,20)
$outputLabel.Dock = "None"
$outputLabel.Anchor = "None"
$outputLabel.Text = "Results:"
$form.Controls.Add($outputLabel) 

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(300,240)
$CancelButton.Size = New-Object System.Drawing.Size(150,46)
$CancelButton.Dock = "None"
$CancelButton.Anchor = "None"
$CancelButton.Text = "Cancel"
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(18,60)
$label.Size = New-Object System.Drawing.Size(320,20)
$label.Dock = "None"
$label.Anchor = "None"
$label.Text = "Please enter the password to check:"
$form.Controls.Add($label)

$password = New-Object System.Windows.Forms.MaskedTextBox
$password.PasswordChar = '*'
$password.Location = New-Object System.Drawing.Point(20,80) 
$password.Size = New-Object System.Drawing.Size(520,40)
$password.Dock = "None"
$password.Anchor = "None"
$form.Controls.Add($password)
$form.Topmost = $True

$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Point(150,240)
$Button.Size = New-Object System.Drawing.Size(150,46)
$Button.Dock = "None"
$Button.Anchor = "None"
$Button.Text = "Check it!"
$form.AcceptButton = $Button
$Form.Controls.Add($Button)
$Button.Add_Click({
    $secstr = $password.Text | ConvertTo-SecureString -AsPlainText -Force
    $pwnedResults = getPwned($secstr)
    $outputBox.Text = $pwnedResults
    if ($pwnedResults -like "This password has been pwned*") {
        $outputBox.BackColor = "Red"
    }
    if ($pwnedResults -like "This password is not in the pwned DB*") {
        $outputBox.BackColor = "Limegreen"
    }
})
$dialog = [System.Windows.MessageBox]::Show("This utility returns the number of times the provided password has been compromised in known security breaches.`n`nDatasource is Troy Hunts haveibeenpwned password database`n`nNO PASSWORDS ARE SENT OVER THE NETWORK, THEY STAY LOCAL","Disclaimer","OkCancel")
switch ($dialog) {
    "OK" {
            $form.Add_Shown({$password.Select()})
            [VOID]$Form.Showdialog()
    }
    "Cancel" {
        exit 0
    }
    
}

