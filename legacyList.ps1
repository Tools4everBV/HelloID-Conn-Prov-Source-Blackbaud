#Configuration
$config = ConvertFrom-Json $configuration;
$listId = ""; #List ID of the list you wish to retrieve
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

$legacyListUri = "https://api.sky.blackbaud.com/school/v1/legacy/lists/$listId";

$legacyListResponse = Invoke-RestMethod -Method GET -Uri $legacyListUri -Headers $authorization