Connect-AzureAD
Connect-MsolService

$ExportPath = Read-Host "Please enter the export csv path (eg. C:\Scripts\test.csv): "
$Date = Read-Host "Please enter the date to search for (in format yyyy-mm-dd): "

$authType = Read-Host "Please enter the authtype you want to search (OneWaySMS, PhoneAppOTP, PhoneAppNotification, TwoWayVoiceMobile): "

$searchbyphone = Read-Host "Do You want to search by phone number? (Y/N): "
if($searchbyphone -eq "Y"){
    $Phone = Read-Host "Enter phone number like (+44 07777777777 or as it appears in azure)"

    Write-Host "If no values appear, but you know they are appearing go into the code and change 'PhoneNumber' to 'Mobile' on like 28. Press Enter to Continue"
    Read-Host
    #OneWaySMS
    #PhoneAppOTP
    #PhoneAppNotification
    #TwoWayVoiceMobile



    $Users = Get-MsolUser -All
    Write-Host "Searching for users with the Auth against the phone number $Phone"
    $result=@()
    ForEach ($User in $Users)
    {
    
        If (($User.StrongAuthenticationMethods | ? { $_.IsDefault -eq "True" }).MethodType -eq $authType)
        {
           If($User.StrongAuthenticationUserDetails.PhoneNumber -eq $Phone) #change PhoneNumber to MobilePhone to check other field - it depends how they are set up Phonenumber must be as it appears in Azure - if unsure run without it first and then find your number in the csv and replace. 
           {
                $upn = $User.UserPrincipalName.ToLower()

                $Logs = Get-AzureADAuditSignInLogs -Filter "CreatedDateTime gt $Date and userPrincipalName eq '$upn' and status/errorCode ne 0"

                foreach ($log in $Logs){
                    $result+= New-Object PsObject -Property @{
                                              DateTime = $log.CreatedDateTime
                                              Name=$log.userPrincipalname
                                              errorCode=$log.status.errorcode
                                              additionalDetails=$log.status.additionalDetails
                                              failureReason=$log.status.FailureReason
                                              app=$log.AppDisplayName
                                              Phone=$User.StrongAuthenticationUserDetails.PhoneNumber
                                              Mobile = $User.StrongAuthenticationUserDetails.MobilePhone
                                              DeviceName= $log.DeviceDetail.DisplayName
                                              DeviceManaged = $log.DeviceDetail.IsManaged
                                              }
               }
       
           }

        } 
        $result | Select-Object "DateTime", "Name", "errorCode", "additionalDetails", "failureReason", "app", "Mobile","Phone","DeviceName","DeviceManaged" | export-csv -path $ExportPath
    
    }
}
else
{

    $Users = Get-MsolUser -All
    Write-Host "Searching without filter"
    $result=@()
    ForEach ($User in $Users)
    {
    
        If (($User.StrongAuthenticationMethods | ? { $_.IsDefault -eq "True" }).MethodType -eq $authType)
        {
           $upn = $User.UserPrincipalName.ToLower()

           $Logs = Get-AzureADAuditSignInLogs -Filter "CreatedDateTime gt $Date and userPrincipalName eq '$upn' and status/errorCode ne 0"

        foreach ($log in $Logs){
              $result+= New-Object PsObject -Property @{
                                              DateTime = $log.CreatedDateTime
                                              Name=$log.userPrincipalname
                                              errorCode=$log.status.errorcode
                                              additionalDetails=$log.status.additionalDetails
                                              failureReason=$log.status.FailureReason
                                              app=$log.AppDisplayName
                                              Phone=$User.StrongAuthenticationUserDetails.PhoneNumber
                                              Mobile = $User.StrongAuthenticationUserDetails.MobilePhone
                                              DeviceName= $log.DeviceDetail.DisplayName
                                              DeviceManaged = $log.DeviceDetail.IsManaged
                                              }
            }

        } 
         $result | Select-Object "DateTime", "Name", "errorCode", "additionalDetails", "failureReason", "app", "Mobile","Phone","DeviceName","DeviceManaged" | export-csv -path $ExportPath
    
    }

}