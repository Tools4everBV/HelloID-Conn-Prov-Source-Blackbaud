Clear-Host
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

$config = @{
	'clientId' = ''
	'secret' = ''
};

$code = Read-Host "Visit and login to the following URL and enter in the ""code"" query parameter from the redirect, https://oauth2.sky.blackbaud.com/authorization?client_id=$($config.clientId)&response_type=code&redirect_uri=http://localhost"

#Build access token request
$tokenRequestUri = "https://oauth2.sky.blackbaud.com/token";
    
$headers = @{
	'Authorization' = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $config.clientId,$config.secret)))
	'Accept' = 'application/JSON'
	'Content-Type' = 'application/x-www-form-urlencoded'
};	

$body = "grant_type=authorization_code&redirect_uri=http://localhost&code=$code";

#Request access token
$authResponse = Invoke-RestMethod -Method POST -Uri $tokenRequestUri -Headers $headers -Body $body;
Write-Host "New Token: $($authResponse.refresh_token)";