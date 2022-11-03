<############ Settings ###############>
$url = "http://localhost:83"

$bodyLogin = @{
 "username"="***USERNAME***"
 "password"="***PASSWORD***"
} | ConvertTo-Json

#Die folgenden Plugins werden immer gestartet, selbst man diese den Status "Stopped" haben
$pluginsImmerStarten = @(
    "MailInputRLP"
);


#Umlaute müssen als [char] angegeben werden. (https://www.torsten-horn.de/techdocs/ascii.htm)
#InputÜberwachung
$alarmEinheit = "Input$([char]220)berwachung"

<############ Settings ###############>

$header = @{
 "Accept"="application/json"
 "Content-Type"="application/json"
} 

$responseLogin = Invoke-RestMethod -Uri $url"/rest/login" -Method Post -Body $bodyLogin -Headers $header
$token = "JWT " + $responseLogin.token
$header.Add("Authorization", $token);



$responseInputs = Invoke-RestMethod -Uri $url"/rest/admin/input/active" -Method Get -Headers $header


$alarm = $false;
$Alarmtext = "Es wurde ein Fehler in folgenden Plugins festgestellt:\n--------------------------\n";


foreach($input in $responseInputs){
    if($input.state.state -eq 'ERROR'){
        #Startet das Plugin neu, wenn es im im Status ERROR ist.
        $IDinput = $input.id
        $bodyRestart = @{"state"="RESTART"} | ConvertTo-Json
        $responseRestart = Invoke-RestMethod -Uri $url"/rest/admin/input/"$IDInput"/state" -Method Put -Body $bodyRestart -Headers $header


    } elseif($input.state.state -eq 'STOPPED' -and $pluginsImmerStarten.contains($input.type)){
        #Startet das Plugin, wenn es im Status STOPPED ist.
        $IDinput = $input.id
        $bodyRestart = @{"state"="START"} | ConvertTo-Json
        $responseRestart = Invoke-RestMethod -Uri $url"/rest/admin/input/"$IDInput"/state" -Method Put -Body $bodyRestart -Headers $header
    }
}


# 30 Sekunden warten
Start-Sleep 30
$responseInputs = Invoke-RestMethod -Uri $url"/rest/admin/input/active" -Method Get -Headers $header
foreach($input in $responseInputs){
    if($input.state.state -eq 'ERROR'){
        #send Alarm
        $alarm = $true;
        $Alarmtext += $input.name+"\n("+$input.note+")\n"+$input.state.Message+"\n- - - - - - - - - - - - - - - -";
    }
    if($input.state.state -eq 'STARTING'){
        #send Alarm
        $alarm = $true;
        $Alarmtext += $input.name+"\n("+$input.note+")\n"+"Input-Plugin startet nicht"+"\n- - - - - - - - - - - - - - - -";
        #restart Input
        $IDinput = $input.id
        $bodyRestart = @{"state"="RESTART"} | ConvertTo-Json
        $responseRestart = Invoke-RestMethod -Uri $url"/rest/admin/input/"$IDInput"/state" -Method Put -Body $bodyRestart -Headers $header
    }
    
    if($input.state.state -eq 'STOPPED' -and $pluginsImmerStarten.contains($input.type)){
        #send Alarm
        $alarm = $true;
        $Alarmtext += $input.name+"\n("+$input.note+")\n"+"Input-Plugin startet nicht"+"\n- - - - - - - - - - - - - - - -";
        #restart Input
        $IDinput = $input.id
        $bodyRestart = @{"state"="START"} | ConvertTo-Json
        $responseRestart = Invoke-RestMethod -Uri $url"/rest/admin/input/"$IDInput"/state" -Method Put -Body $bodyRestart -Headers $header
    }
}




$stringAsStream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stringAsStream)
$writer.write($Alarmtext)
$writer.Flush()
$stringAsStream.Position = 0
$hash = (Get-FileHash -InputStream $stringAsStream -Algorithm MD5).hash




$alarmJSON = @{
    "units"=$alarmEinheit
    "data"=@{
        "message"=$Alarmtext
        "alarmtexthash"=$hash
        "withStatistic"=$false
        "generateExternalId"=$false
        "alarmType"="MANUAL"
    }
    "externalId"=""
    "vehicles"=@()
} | ConvertTo-Json

$alarmJSON = $alarmJSON.Replace('\\n','\n')

if($alarm){
    $alarmbody =  ([System.Text.Encoding]::UTF8.GetBytes($alarmJSON))
    Invoke-WebRequest -UseBasicParsing -Uri $url"/rest/alarm" -Method "POST" -ContentType "application/json;charset=UTF-8" -Headers $header -Body $alarmbody 
}
