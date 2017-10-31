# Get-AcceptedDomainDNSRecords.ps1

## Purpose  
The primary purpose of this script is take an export of your accepted domains from Exchange on-premises or Exchange Online, and pull DNS records related to MX, SPF, DKIM, DMARC, and Autodiscover.  
  
## Example  
First get and export your Accepted domains to a CSV  
Get-AcceptedDomain | Export-CSV domains.csv -notypeinformation  
  
  Now run the script using the exported CSV as import  
.\Get-AcceptedDomainDNSRecords.ps1 -AcceptedDomainCSVPath domains.csv  
  
## Plans  
* Add variable input  
* Create HTML report highlighting discrepencies  
