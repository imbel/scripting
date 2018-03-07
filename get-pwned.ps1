param (
    [Parameter(Mandatory=$True)]
    [Security.SecureString]$password
)
#Setting execution policy as this script is not signed
Set-ExecutionPolicy Unrestricted -Scope Process -Force
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

$response = invoke-webrequest -uri https://api.pwnedpasswords.com/range/$search
$array = $response.Content -split('\r\n')

foreach ($line in $array) {
    if ($line.contains($subString)) {
        $pwned = $true
        $pwnedTime = $line.split(":")[1]
        write-host -foregroundcolor red "This password has been pwned $pwnedTime times, you should probly change it"
    }
    else {
        continue
    }
}
if (!$pwned) {
    write-host -foregroundcolor green "This password is not in the pwned DB, you should be good!"
}

$subString = $null
