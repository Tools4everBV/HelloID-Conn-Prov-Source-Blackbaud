#Configuration
$config = ConvertFrom-Json $configuration;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

#Retrieve refresh token
$refreshToken = Get-Content -Path $config.tokenLoc

#Build access token request
$tokenRequestUri = "https://oauth2.sky.blackbaud.com/token";
    
$headers = @{
	'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $config.clientId,$config.secret)))
	'Accept' = 'application/JSON'
	'Content-Type' = 'application/x-www-form-urlencoded'
};	

$body = "grant_type=refresh_token&refresh_token=$refreshToken";

#Request access token
$authResponse = Invoke-RestMethod -Method POST -Uri $tokenRequestUri -Headers $headers -Body $body -Verbose:$false;
$accessToken = $authResponse.access_token;

#Save refresh token
$authResponse.refresh_token | Set-Content -Path $config.tokenLoc

#Add the authorization header to the request
$authorization = @{
    Authorization = "Bearer $accesstoken";
    'Content-Type' = "application/json";
    Accept = "application/json";
    'Bb-Api-Subscription-Key' = $config.subscriptionKey;
};

#Use the call below if you need to find user base_role_ids
#$rolesResponse = Invoke-RestMethod -Method GET -Uri "https://api.sky.blackbaud.com/school/v1/roles" -Headers $authorization

#14 base_role_ids student
#15 base_role_ids teacher
$marker = "";
$users = $null;
$usersExtendListUri = "https://api.sky.blackbaud.com/school/v1/users/extended?base_role_ids=14";
do
{ 
    $usersResponse = Invoke-RestMethod -Method GET -Uri $usersExtendListUri -Headers $authorization

    if ($users -eq $null)
    {
        $users = $usersResponse.value;
    }
    else
    {
        $users = $users + $usersResponse.value;
    }

    $usersExtendListUri = $usersResponse.next_link;
}
while ($usersExtendListUri -ne $null -and $usersExtendListUri -ne "")


foreach ($user in $users)
{
    $person = $user;

    $person | Add-Member -Name "ExternalId" -Value $user.Id -MemberType NoteProperty;
    $person | Add-Member -Name "DisplayName" -Value "$($user.first_name) $($person.last_name)" -MemberType NoteProperty;
    $person | Add-Member -Name "Contracts" -Value @(@{ 'ExternalId' = $user.Id; 'enroll_date' = $user.enroll_date; 'depart_date' = "$($user.depart_date)".replace("0001-01-01T00:00:00-05:00", ""); }) -MemberType NoteProperty;

    Write-Output ($person | ConvertTo-Json -Depth 20);
}
