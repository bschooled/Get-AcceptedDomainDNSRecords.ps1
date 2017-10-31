################################################################################# 
#  
# The sample scripts are not supported under any Microsoft standard support  
# program or service. The sample scripts are provided AS IS without warranty  
# of any kind. Microsoft further disclaims all implied warranties including, without  
# limitation, any implied warranties of merchantability or of fitness for a particular  
# purpose. The entire risk arising out of the use or performance of the sample scripts  
# and documentation remains with you. In no event shall Microsoft, its authors, or  
# anyone else involved in the creation, production, or delivery of the scripts be liable  
# for any damages whatsoever (including, without limitation, damages for loss of business  
# profits, business interruption, loss of business information, or other pecuniary loss)  
# arising out of the use of or inability to use the sample scripts or documentation,  
# even if Microsoft has been advised of the possibility of such damages 
# 
################################################################################# 
param(
    $AcceptedDomainCSVPath
    )

if(!$AcceptedDomainCSVPath){
   $AcceptedDomainCSVPath = Read-Host "Please enter path to exported CSV of your Accepted Domains; EX: Get-AcceptedDomain | export-csv acceptedomains.csv "
}
if((Test-Path $AcceptedDomainCSVPath)){
    $AcceptedDomains = Import-Csv $AcceptedDomainCSVPath 
    }
else{
    Write-Host "Couldn't find CSV, try again" -ForegroundColor Yellow
}


function parse-records([array]$inputArray){
    $firstRun = $true
    $global:return = $null
    if($inputArray.Count -gt 1){
        foreach($entry in $inputArray){

            [string]$type = $entry | select -ExpandProperty QueryType
            Write-Host "`tType = $type"
            switch($type){
                CNAME{$filter = "NameHost"}
                A{$filter = "IpAddress" }
                MX{$filter = "NameExchange"}
                TXT{$filter = "Strings"}

            }
            Write-Host "`tFilter = $filter"
            if($firstRun -eq $true){
                Write-Host "`tEntry = $($entry.$filter)"
                [string]$output = $entry.$filter
                }
            else{
                Write-Host "`tEntry = $($entry.$filter)"
                [string]$output = $output + ',' + $entry.$filter
            }
            $firstRun = $false
        }
    }
    elseif($inputArray.Count -eq 1){
        $type = $inputArray | select -ExpandProperty QueryType
        switch($type){
            CNAME{$filter = "NameHost"}
            A{$filter = "IpAddress" }
            MX{$filter = "NameExchange"}
            TXT{$filter = "Strings"}

        }
        Write-Host "`tEntry = $($inputArray.$filter)"
        [string]$output = $inputArray.$filter
    }
    else{
        [string]$output = ''
    }
    $global:return = $output
    Write-Host "`tReturn Output = $($global:return)"

}

$exportCSV = @()
foreach($domain in $AcceptedDomains){
    Write-Host "Checking $($domain.Name)" -ForegroundColor White
    
    #resolve root txt records for DKIM and SPF
    [array]$txtroot = Resolve-DnsName -Name "$($domain.Name)" -Type TXT -ErrorAction SilentlyContinue
    [array]$dkimKeyArray = $txtroot | where{$_.Strings -like "*=="}
    if($dkimKeyArray){
        parse-records -input $dkimKeyArray 
        $dkimKey = $Global:return
        }
    else{
        $dkimKey = ''
        }

    [array]$spfArray = $txtroot | where{$_.Strings -like "V=spf*"}
    if($spfArray){
        parse-records -input $spfArray 
        $spf = $Global:return
        }
    else{
        $spf = ''
        }

    #resolve Dmarc 
    [array]$dmarcArray = Resolve-DnsName -Name "_dmarc.$($domain.Name)" -Type TXT -ErrorAction SilentlyContinue
    if($dmarcArray){
        parse-records -input $dmarcArray 
        $dmarc = $Global:return
        }
    else{
        $dmarc = ''
        }

    #resolve MX 
    [array]$mxArray = Resolve-DnsName -Name $domain.Name -Type MX  -ErrorAction SilentlyContinue
    if($mxArray){
        parse-records -input $mxArray 
        $mx = $Global:return
        }
    else{
        $mx = ''
        }

    #Autodiscover
    [array]$autodArray = Resolve-DnsName -Name "autodiscover.$($domain.Name)" -ErrorAction SilentlyContinue
    if($autodArray){
        parse-records -input $autodArray
        $autoD = $Global:return
        }
    else{
        $autoD = ''
    }

    $obj = New-Object psobject
    $obj | Add-Member -MemberType NoteProperty "Domain" -Value "$($domain.Name)"
    $obj | Add-Member -MemberType NoteProperty "DKIMKey" -Value $dkimKey
    $obj | Add-Member -MemberType NoteProperty "SPF" -Value $spf
    $obj | Add-Member -MemberType NoteProperty "Dmarc" -Value $dmarc
    $obj | Add-Member -MemberType NoteProperty "MX" -Value $mx
    $obj | Add-Member -MemberType NoteProperty "Autodiscover" -Value $autoD
    $exportCSV += $obj
    }


try{
    $exportCSV | Export-Csv AcceptedDomains-DNSRecords.csv -NoTypeInformation
    Write-Host "Exported AcceptedDomains-DNSRecords.csv" 
    }
Catch{
    Write-Host "Failed to export CSV, likely to due it being Null" -ForegroundColor Red
}