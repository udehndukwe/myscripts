#Gets and removes office printers
$printers = Get-Printer | Where PortName -like "*172.*"
$printers | Remove-Printer

#Gets and removes all printer drivers for RICOH or LANIER, there will be one of them, or both present on corp machines
$printdrivers = @()

$printdrivers += get-printerdriver "*RICOH*" 
$printdrivers += get-printerdriver "*LANIER*" 

$printdrivers | Remove-PrinterDriver

#Start and stop print spooler. One of the ports lingered until I restarted the service
$spool = Get-Service Spooler

Stop-Service $spool
Start-Service $spool

#remove all TCP/IP Printer Ports

$printerports = Get-PrinterPort | Where Description -Like "*Standard TCP/IP Port*"
$printerports | Remove-PrinterPort 





