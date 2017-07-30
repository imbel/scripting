$machines = $env:COMPUTERNAME
foreach ($machine in $machines) {
    get-wmiobject -COMPUTERNAME $machine win32_bios
}