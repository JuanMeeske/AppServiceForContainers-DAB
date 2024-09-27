$location = "uksouth"
$randomString = -join ((65..90) + (97..122) | Get-Random -Count 4 | % {[char]$_})
$rg = "rg-appservice-dabapi-"+ $location + "-" + $randomString
$appName = "mydabapi-"+ $location + "-" + $randomString + "123"
$storageAccountName = ("sablob" + $randomString + $randomString).ToLower()
$sqladminpassword = "YourStrongPasswordHere!" + $randomString
$publicIP = (Invoke-WebRequest -Uri "http://ifconfig.me/ip" -UseBasicParsing).Content.Trim()

try {
    az group create --name $rg --location $location
    az deployment group create --resource-group $rg --template-file=AppServiceDataApiBuilder.bicep --parameters location=$location appName=$appName adminPassword=$sqladminpassword storageAccountName=$storageAccountName publicIP=$publicIP
} catch {
    echo "Error during resource group or deployment creation: $_"
    exit 1
}


try {
    .\createTable.ps1 -ServerName "sqlserver-$appName" -DatabaseName "db-$appName" -Username "sqladmin" -Password $sqladminpassword
    .\upload-config.ps1 -StorageAccountName $storageAccountName -ContainerName "default" -ResourceGroupName $rg -FileName "dab-config.json"
} catch {
    echo "Error during table creation or config upload: $_"
    exit 1
}

echo "Deployment Information:"
echo "Resource Group: $rg"
echo "App Name: $appName"
echo "Storage Account Name: $storageAccountName"


echo "Attempting to reach the API at http://$($appName).azurewebsites.net/swagger for 5 minutes..."

$startTime = Get-Date
$endTime = $startTime.AddMinutes(5)
$lastReportTime = $startTime

while ((Get-Date) -lt $endTime) {
    try {
        $response = Invoke-WebRequest -Uri "http://$($appName).azurewebsites.net/swagger" -TimeoutSec 10
        echo "Successfully reached the API at $(Get-Date -Format 'HH:mm:ss')"
        break
    } catch {
        $currentTime = Get-Date
        if (($currentTime - $lastReportTime).TotalSeconds -ge 30) {
            echo "Failed to reach the API at $(Get-Date -Format 'HH:mm:ss'). Retrying..."
            $lastReportTime = $currentTime
        }
    }
    Start-Sleep -Seconds 5
}

if ((Get-Date) -ge $endTime) {
    echo "Failed to reach the API after 5 minutes of attempts."
}
