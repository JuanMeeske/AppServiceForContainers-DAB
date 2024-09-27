param(
    [string]$StorageAccountName,
    [string]$ContainerName,
    [string]$ResourceGroupName,
    [string]$FileName
)

# Get the storage account key
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName)[0].Value

# Create a storage context using the account name and key
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $storageAccountKey

# Upload the file
Set-AzStorageBlobContent -File $FileName -Container $ContainerName -Blob $FileName -Context $ctx -Force
