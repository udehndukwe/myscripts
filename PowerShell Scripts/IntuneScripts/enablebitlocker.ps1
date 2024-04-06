$value = (Get-BitLockerVolume).VolumeStatus

if ($value -eq "FullyEncrypted") {
    exit
}
elseif ($value -eq "FullyDecrypted") {


    Get-BitLockerVolume |Enable-BitLocker -TpmProtector -EncryptionMethod Aes128 

}