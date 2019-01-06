
# ------------------ Parameters
Param ( [string]$OVApplianceIP                  = "", 
        [string]$OVAdminName                    = "", 
        [string]$OVAdminPassword                = "",
        [string]$OVAuthDomain                   = "local",
        [string]$OneViewModule                  = "HPOneView.410"
)

$DoubleQuote    = '"'
$CRLF           = "`r`n"
$Delimiter      = "\"   # Delimiter for CSV profile file
$SepHash        = ";"   # USe for multiple values fields
$Sep            = ";"
$hash           = '@'
$SepChar        = '|'
$CRLF           = "`r`n"
$OpenDelim      = "{"
$CloseDelim     = "}" 
$CR             = "`n"
$Comma          = ','
$Equal          = '='
$Dot            = '.'
$Underscore     = '_'

$Syn12K                   = 'SY12000' # Synergy enclosure type



    ######################################
    # REMOVE PRIOR TO MERGE INTO CMDLET
    ######################################
    [Hashtable]$SnmpAuthLevelEnum = @{
        None        = "noauthnopriv";
        AuthOnly    = "authnopriv";
        AuthAndPriv = "authpriv"
    }
    [Hashtable]$Snmpv3UserAuthLevelEnum = @{
        None        = "None";
        AuthOnly    = "Authentication";
        AuthAndPriv = "Authentication and privacy"
    }
    [Hashtable]$SnmpAuthProtocolEnum = @{

        'none'   = 'none';
        'md5'    = 'MD5';
        'SHA'    = 'SHA';
        'sha1'   = 'SHA1';
        'sha2'   = 'SHA2';
        'sha256' = 'SHA256';
        'sha384' = 'SHA384';
        'sha512' = 'SHA512'

    }
    [Hashtable]$SnmpPrivProtocolEnum = @{
        'none'    = 'none';	
        'aes'     = "AES128";
        'aes-128' = "AES128";
        'aes-192' = "AES192";
        'aes-256' = "AES256";
        'aes128'  = "AES128";
        'aes192'  = "AES192";
        'aes256'  = "AES256";
        'des56'   = "DES56";
        '3des'    = "3DES";
        'tdea'    = 'TDEA'
    }
    [Hashtable]$ApplianceSnmpV3PrivProtocolEnum = @{
        'none'   = 'none';
        "des56"  = 'DES';
        '3des'   = '3DES';
        'aes128' = 'AES-128';
        'aes192' = 'AES-192';
        'aes256' = 'AES-256'
    }
    [Hashtable]$ServerProfileSanManageOSType = @{
        CitrixXen  = "Citrix Xen Server 5.x/6.x";
        CitrisXen7 = "Citrix Xen Server 7.x";
        AIX        = "AIX";
        IBMVIO     = "IBM VIO Server";
        RHEL4      = "RHE Linux (Pre RHEL 5)";
        RHEL3      = "RHE Linux (Pre RHEL 5)";
        RHEL       = "RHE Linux (5.x, 6.x, 7.x)";
        RHEV       = "RHE Virtualization (5.x, 6.x)";
        RHEV7      = "RHE Virtualization 7.x";
        VMware     = "VMware (ESXi)";
        Win2k3     = "Windows 2003";
        Win2k8     = "Windows 2008/2008 R2";
        Win2k12    = "Windows 2012 / WS2012 R2";
        Win2k16    = "Windows Server 2016";
        OpenVMS    = "OpenVMS";
        Egenera    = "Egenera";
        Exanet     = "Exanet";
        Solaris9   = "Solaris 9/10";
        Solaris10  = "Solaris 9/10";
        Solaris11  = "Solaris 11";
        ONTAP      = "NetApp/ONTAP";
        OEL        = "OE Linux UEK (5.x, 6.x)";
        OEL7       = "OE Linux UEK 7.x";
        HPUX11iv1  = "HP-UX (11i v1, 11i v2)"
        HPUX11iv2  = "HP-UX (11i v1, 11i v2)";
        HPUX11iv3  = "HP-UX (11i v3)";
        SUSE       = "SuSE (10.x, 11.x, 12.x)";
        SUSE9      = "SuSE Linux (Pre SLES 10)";
        Inform     = "InForm"
    }
    [Hashtable]$SmtpConnectionSecurityEnum = @{

        None     = 'PLAINTEXT';
        Tls      = 'TLS';
        StartTls = 'STARTTLS'

    }



function Insert-Header 
{
    [void]$scriptCode.Add($headerText)
} 

function Insert-BlankLine
{

    "" | Out-Host

}

Function Get-NamefromUri([string]$uri)
{
    $name = $null

    if (-not [string]::IsNullOrEmpty($Uri)) 
    { 
        
        
            $resource = Send-HPOVRequest -Uri $Uri -ApplianceConnection $ApplianceConnection
        

    
    }

    switch ($resource.category)
    {

        'id-range-IPV4-subnet'
        {

            $name = $resource.networkId

        }

        default
        {

            $name = $resource.name

        }

    }

    return $name

}

Function rebuild-fwISO ($BaselineObj)
{

    # ----------------------- Rescontruct FW ISO filename
    # When uploading the FW ISO file into OV, all the '.' chars are replaced with "_"
    # so if the ISO filename is:        SPP_2018.06.20180709_for_HPE_Synergy_Z7550-96524.iso
    # OV will show $fw.ISOfilename ---> SPP_2018_06_20180709_for_HPE_Synergy_Z7550-96524.iso
    # 
    # This helper function will try to re-build the original ISO filename

    $newstr = $null

    switch ($BaselineObj.GetType().Fullname)
    {

        'HPOneView.Appliance.Baseline'
        {

            $arrList = New-Object System.Collections.ArrayList

            $StrArray = $BaselineObj.ResourceId.Split($Underscore)

            ForEach ($string in $StrArray)
            {

                [void]$arrList.Add($string.Replace($dot, $Underscore))

            }
            
            $newstr = "{0}.iso" -f [String]::Join($Underscore, $arrList.ToArray())                

        }

        'HPOneView.Appliance.BaselineHotfix'
        {

            $newStr     = $BaselineObj.FwComponents.Filename

        }

        default
        {

            $newstr = $null

        }

    }

    return $newStr
    
}
    

# ----------------------- Output code to file
Function Out-ToScriptFile ([string]$Outfile)
{
    if ($ScriptCode)
    {
        Prepare-OutFile -outfile $OutFile
        
        Add-Content -Path $OutFile -Value $ScriptCode
        

    } else 
    {
        Write-Host -ForegroundColor Yellow " No $ovObject found. Skip generating script..."
    }
}


# ------------------------- Beginning of PS script
Function Prepare-OutFile ([string]$Outfile)
{
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

    $config_dir = "~/ansible-scripts"
    $filename   = $outFile.Split($Delimiter)[-1]
    $ovObject   = $filename.Split($Dot)[0] 
    Write-Host -ForegroundColor Cyan "Create Ansible Playbook  -->     $filename  "
    New-Item $OutFile -ItemType file -Force -ErrorAction Stop | Out-Null
    

    $HeaderText = @"
###
# Copyright (2016-2017) Hewlett Packard Enterprise Development LP
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###
---
- hosts: localhost
  vars:
    config: "$config_dir/oneview_config.json"
  tasks:
"@
    

    Set-content -path $outFile -Value $HeaderText
}



Function Generate-TimeLocale-Ansible ($List, $OutFile)
{

    

    foreach ($timeLocale in $List)
    {
        $locale          = $TimeLocale.Locale
        $ntpServers      = $TimeLocale.NtpServers
        $pollingInterval = $timeLocale.pollingInterval
        $syncWithHost    = $timeLocale.SyncWithHost
        $timeZone        = $timelocale.timeZone

        $localeParm        = $ntpParam         = $ntpCode = $null
        $syncWithHostParam = $syncWithHostCode = $null
        $pollingParam      = $pollingCode      = $null

        [void]$scriptCode.Add('     - name: Configure time locale in {0}' -f $locale)
        [void]$scriptCode.Add('       oneview_appliance_time_and_locale_configuration:')
        [void]$scriptCode.Add('         config: "{{ config }}"')
        [void]$scriptCode.Add('         state: present')
        [void]$scriptCode.Add('         data:')
        [void]$scriptCode.Add('             locale: {0}' -f $locale)
        [void]$scriptCode.Add('             timezone: {0}' -f $timeZone)

        # will need to return NTP configuration
        if (-not $syncWithHost)
        {

            if ($ntpServers)
            {
                [void]$scriptCode.Add('             ntpServers:')
                foreach ($ntp in $ntpServers)
                {
                    [void]$scriptCode.Add('                 - {0}' -f $ntp)
                }

            }
        }

        [void]$scriptCode.Add('       delegate_to: localhost')
        [void]$scriptCode.Add(' ')

    } # end foreach

    $scriptCode = $scriptCode.ToArray() 
    Out-ToScriptFile -Outfile $outFile 

}

Function Generate-AddressPoolSubnet-Ansible ($List, $OutFile)
{

    foreach ($subnet in $list)
    {

        $networkID      = $subnet.NetworkID
        $subnetmask     = $subnet.subnetmask
        $gateway        = $subnet.gateway
        $domain         = $subnet.domain
        $dns            = $subnet.dnsservers
        $rangeUris      = $subnet.rangeUris

        [void]$scriptCode.Add('     - name: Create subnet {0}'          -f $name)
        [void]$scriptCode.Add('       oneview_id_pools_ipv4_subnet:')
        [void]$scriptCode.Add('         config: "{{ config }}"')
        [void]$scriptCode.Add('         state: present')
        [void]$scriptCode.Add('         data:')
        [void]$scriptCode.Add('             name: subnet name {0}'      -f $networkID)
        [void]$scriptCode.Add('             type: Subnet')
        [void]$scriptCode.Add('             networkId: {0}'             -f $networkID)
        [void]$scriptCode.Add('             subnetmask: {0}'            -f $subnetmask)
        [void]$scriptCode.Add('             gateway: {0}'               -f $gateway)

        if ($domain)
        {
            [void]$scriptCode.Add('             domain: {0}'                -f $domain)
        }

        if ($dns)
        {
            [void]$scriptCode.Add('             dnsServers:')
            foreach ($dnsserver in $dns)
            {
                [void]$scriptCode.Add('                 - {0}'                  -f $dnsserver)
            }
        }

        [void]$scriptCode.Add('       delegate_to: localhost')
        [void]$scriptCode.Add(' ')

        ### Define range
        [void]$scriptCode.Add('     - set_fact: subnet_uri="{{ id_pools_ipv4_subnet["uri"] }}" ')
        
        foreach ($rangeUri in $rangeUris)
        {

            $range          = send-HPOVRequest -uri $rangeUri
            $name           = $range.Name 
            $startAddress   = $range.startAddress 
            $endAddress     = $range.endAddress 

           [void]$scriptCode.Add('     - name: Create IPV4 range {0}'          -f $name)
           [void]$scriptCode.Add('       oneview_id_pools_ipv4_range:')
           [void]$scriptCode.Add('         config: "{{ config }}"')
           [void]$scriptCode.Add('         state: present')
           [void]$scriptCode.Add('         data:')
           [void]$scriptCode.Add('             name: {0}'      -f $name)
           [void]$scriptCode.Add('             subnetUri: "{{ subnet_uri }}" ')
           [void]$scriptCode.Add('             type: Range' )
           [void]$scriptCode.Add('             rangeCategory: Custom')
           [void]$scriptCode.Add('             startAddress: {0}'      -f $startAddress)
           [void]$scriptCode.Add('             endAddress: {0}'      -f $endAddress)
           [void]$scriptCode.Add('       delegate_to: localhost')
           [void]$scriptCode.Add(' ')

        }
    } # end foreach

    $scriptCode= $scriptCode.ToArray() 
    Out-ToScriptFile -Outfile $outFile 

}

Function Generate-fwBaseline-Ansible ($List, $outFile) # Review RPM file generated
{

    foreach ($fwBase in $List)
    {

        # - OV strips the dot from the ISOfilename, so we have to re-construct it
        $filename   = rebuild-fwISO -BaselineObj $fwBase

        [void]$scriptCode.Add('     - name: Ensure that firmwate bundle {0} is present')
        [void]$scriptCode.Add('       oneview_firmware_bundle:')
        [void]$scriptCode.Add('         config: "{{ config }}"')
        [void]$scriptCode.Add('         state: present')
        [void]$scriptCode.Add('         file_path: "{0}"' -f $filename)
        [void]$scriptCode.Add('       delegate_to: localhost')
        [void]$scriptCode.Add(' ')
    } # end foreach

    $scriptCode= $scriptCode.ToArray() 
    Out-ToScriptFile -Outfile $outFile  

}

Function Generate-EthernetNetwork-Ansible ($List, $outFile)
{

    
    foreach ($net in $List)
    {
        # ----------------------- Construct Network information
        $name        = $net.name
        $type        = $net.type.Split("-")[0]   # Value is like ethernet-v30network

        $vLANType    = $net.ethernetNetworkType
        $vLANID      = $net.vLanId

        $pBandwidth  = [string]$net.DefaultTypicalBandwidth
        $mBandwidth  = [string]$net.DefaultMaximumBandwidth
        $smartlink   = if ($net.SmartLink) { 'true' } else { 'false' }
        $Private     = if ($net.PrivateNetwork) { 'true' } else { 'false' }
        $purpose     = $net.purpose

        [void]$scriptCode.Add('     - name: Create an Ethernet Network {0}' -f $name)
        [void]$scriptCode.Add('       oneview_ethernet_network:')
        [void]$scriptCode.Add('         config: "{{ config }}"')
        [void]$scriptCode.Add('         state: present')
        [void]$scriptCode.Add('         data:')
        [void]$scriptCode.Add('             name: "{0}"' -f $name)
        [void]$scriptCode.Add('             ethernetNetworkType: {0}' -f $vLANType)
        [void]$scriptCode.Add('             purpose: {0}' -f $purpose)
        [void]$scriptCode.Add('             smartLink: {0}' -f $smartlink)
        [void]$scriptCode.Add('             privateNetwork: {0}' -f $Private)

        if ($vLANType -eq 'Tagged')
        { 
            if (($vLANID) -and ($vLANID -gt 0)) 
            {
            [void]$scriptCode.Add('             vlanId: {0}' -f $vLANID)
            }

        } 

        if ($pBandwidth -or $mBandwidth)
        {
            [void]$scriptCode.Add('             bandwidth:')
            if ($pBandwidth)
            {
                [void]$scriptCode.Add('                typicalBandwidth: {0}' -f $pBandwidth)
            }

            if ($mBandwidth)
            {
                [void]$scriptCode.Add('                maximumBandwidth: {0}' -f $mBandwidth)
            }
        }

        [void]$scriptCode.Add('       delegate_to: localhost')
        [void]$scriptCode.Add(' ')

    } # end foreach

    $scriptCode= $scriptCode.ToArray() 
    Out-ToScriptFile -Outfile $outFile 

}

Function Generate-NetworkSet-Ansible ($list, $outFile)
{



    foreach ($ns in $list)
    {
        $nsname             = $ns.name
        $nsdescription      = $ns.description
        $Pbandwidth         = $ns.TypicalBandwidth 
        $Mbandwidth         = $ns.MaximumBandwidth 
        $nativenetURI       = $ns.nativeNetworkUri
        $networkURIs        = $ns.networkUris

        [void]$scriptCode.Add('     - name: Create networkSet {0}'                             -f $name                 )
        [void]$scriptCode.Add('       oneview_network_set:'                                                             )
        [void]$scriptCode.Add('         config: "{{ config }}"'                                                         )
        [void]$scriptCode.Add('         state: present'                                                                 )
        [void]$scriptCode.Add('         data:'                                                                          )
        [void]$scriptCode.Add('             name: "{0}"'                                      -f $nsname                )
        
        if ($networkUris)
        {
            [void]$scriptCode.Add('             networkUris:'                                                           )
            foreach ($netUri in $networkUris)
            {
                $netname    = Get-NamefromUri -uri $netUri
                [void]$scriptCode.Add('                 - {0}'                                -f $netname               )
            }
        }
        if ($nativenetUri)
        {
            $nativeName     = Get-NamefromUri -uri $nativenetUri
            [void]$scriptCode.Add(('             nativeNetworkUri: "{0}"  #name is "{1}"'    -f $nativenetUri,$nativeName ))
        }
#        if ($PBandwidth)
#        {
#            [void]$scriptCode.Add('             typicalBandwidth: {0}'                       -f $Pbandwidth                )
#        }

#        if ($Mbandwidth)
#        {
#            [void]$scriptCode.Add('             maximumBandwidth: {0}'                      -f $Mbandwidth                )
#       }

        [void]$scriptCode.Add('       delegate_to: localhost')
        [void]$scriptCode.Add(' ')
            
    } # end foreach

    $scriptCode = $scriptCode.ToArray() 
    Out-ToScriptFile -Outfile $outFile 

}

Function Generate-FCNetwork-Ansible ($List, $outFile)
{

    foreach ($net in $List)
    {
        $name                    = $net.name
        $description             = $net.description
        $type                    = $net.type.Split("-")[0]   # Value is 'fcoe-networksV300
        $fabrictype              = $net.fabrictype
        $pBandwidth              = $net.defaultTypicalBandwidth
        $mBandwidth              = $net.defaultMaximumBandwidth
        $sanURI                  = $net.ManagedSANuri
        $linkStabilityTime       = if ($net.linkStabilityTime) { $net.linkStabilityTime} else {30}
        $autologinredistribution = if ($net.autologinredistribution) { 'true' } else { 'false' }
        $VLANID                  = $net.VLANID
        $fabricUri               = $net.fabricUri 



        if ($type -match 'fcoe') #FCOE network
        {     
            [void]$scriptCode.Add('     - name: Create fcoe Network {0}' -f $name)
            [void]$scriptCode.Add('       oneview_fcoe_network:')
            [void]$scriptCode.Add('         config: "{{ config }}"')
            [void]$scriptCode.Add('         state: present')
            [void]$scriptCode.Add('         data:')
            [void]$scriptCode.Add('             name: "{0}"' -f $name)

            if (($vLANID) -and ($vLANID -gt 0)) 
            {
                [void]$scriptCode.Add('             vlanId: {0}' -f $vLANID)
            }
        
        }

        else  # FC network
        {
            [void]$scriptCode.Add('     - name: Create fc Network {0}' -f $name)
            [void]$scriptCode.Add('       oneview_fc_network:')
            [void]$scriptCode.Add('         config: "{{ config }}"')
            [void]$scriptCode.Add('         state: present')
            [void]$scriptCode.Add('         data:')
            [void]$scriptCode.Add('             name: "{0}"' -f $name)
            [void]$scriptCode.Add('             fabricType: {0}' -f $fabricType)

            if ($fabrictype -eq 'FabricAttach')
            {

                if ($autologinredistribution)
                {
                    [void]$scriptCode.Add('             autoLoginRedistribution: {0}' -f $autologinredistribution)

                }

                if ($linkStabilityTime) 
                {
                    [void]$scriptCode.Add('             linkStabilityTime : {0}' -f $LinkStabilityTime)

                }
        
            }

        }
        
        


        [void]$scriptCode.Add('       delegate_to: localhost')
        [void]$scriptCode.Add(' ')

    } # end foreach

    $scriptCode = $scriptCode.ToArray() 
    Out-ToScriptFile -Outfile $outFile 
}

####
Function Generate-LogicalInterConnectGroup-Ansible($List,$OutFile) 
{
    foreach ($lig in $list)
    {
        $name                   = $lig.Name
        $enclosureType          = $lig.enclosureType
        $category               = $lig.category
        $enclosureIndexes       = $lig.enclosureIndexes
        $interconnectBaySet     = $lig.interconnectBaySet
        $redundancyType         = $lig.redundancyType

        $internalNetworkUris    = $lig.InternalNetworkUris

        $ethernetSettings       = $lig.ethernetSettings
        $igmpSnooping           = if ($ethernetSettings.enableIGMPSnooping) {'true'} else {'false'}
         $igmpIdleTimeout        = $ethernetSettings.igmpIdleTimeoutInterval

        $networkLoopProtection  = if ($ethernetSettings.enablenetworkLoopProtection) {'true'} else {'false'}
        $PauseFloodProtection   = if ($ethernetSettings.enablePauseFloodProtection) {'true'} else {'false'}

        $enableRichTLV          = if ($ethernetSettings.enableRichTLV) {'true'} else {'false'}

        $LDPTagging             = if ($ethernetSettings.enableTaggedLldp) {'true'} else {'false'}

        $stormControl           = if ($ethernetSettings.enableStormControl) {'true'} else {'false'}
         $stormControlThreshold = $ethernetSettings.stormControlThreshold
         $stormControlPolling   = $ethernetSettings.stormControlPollingInterval

        $fastMacCacheFailover   = if ($ethernetSettings.enableFastMacCacheFailover) {'true'} else {'false'}
         $macRefreshInterval    = $ethernetSettings.macRefreshInterval

        $Telemetry              = $lig.telemetryConfiguration
         $sampleCount           = $Telemetry.sampleCount
         $sampleInterval        = $Telemetry.sampleInterval



        [void]$scriptCode.Add('     - name: Create logical Interconnect Group {0}' -f $name)
        if ($category -ne 'sas-logical-interconnect-groups')
        {
            [void]$scriptCode.Add('       oneview_logical_interconnect_group:')
        }
        else  # SAS
        {
            [void]$scriptCode.Add('       oneview_sas_logical_interconnect_group:')   
        }
        
        [void]$scriptCode.Add('         config: "{{ config }}"')
        [void]$scriptCode.Add('         state: present')
        [void]$scriptCode.Add('         data:')
        [void]$scriptCode.Add('             name: "{0}"' -f $name)
        [void]$scriptCode.Add('             enclosureType: "{0}"' -f $enclosureType)
        [void]$scriptCode.Add('             redundancyType: "{0}"' -f $redundancyType)
        [void]$scriptCode.Add('             interconnectBaySet: {0}' -f $interconnectBaySet)


        [void]$scriptCode.Add('             enclosureIndexes:')
        foreach ($index in $lig.enclosureIndexes)
        {
            [void]$scriptCode.Add('                 - {0}' -f $index)
        }

        ### Interconnect Map Template
        $LigInterConnects       = $lig.interconnectmaptemplate.interconnectmapentrytemplates
        [void]$scriptCode.Add('             interconnectMapTemplate:')
        [void]$scriptCode.Add('                 interconnectMapEntryTemplates:')
        foreach ($ligIC in $LigInterConnects)
        {
            $ICpermittedInterconnectTypeUri = $ligIC.permittedInterconnectTypeUri
            $ICTypeName                     =  Get-NamefromUri -uri  $ligIC.permittedInterconnectTypeUri
            $enclosureIndex                 = $ligIC.enclosureIndex
            if ($category -ne 'sas-logical-interconnect-groups')
            {
                [void]$scriptCode.Add('                     - permittedInterconnectTypeName: "{0}"' -f $ICTypeName )
            }
            else # SAS
            {
                [void]$scriptCode.Add('                     - permittedInterconnectTypeUri: "{0}"' -f $ICpermittedInterconnectTypeUri )  
            }
            [void]$scriptCode.Add('                       enclosureIndex: "{0}"' -f $enclosureIndex )
            [void]$scriptCode.Add('                       logicalLocation: ')
            [void]$scriptCode.Add('                         locationEntries: ')

            $locationEntries        = $ligIC.logicalLocation.LocationEntries
            foreach ($entry in $locationEntries)
            {
                $relativeValue      = $entry.relativeValue
                $type               = $entry.type
                [void]$scriptCode.Add('                             - relativeValue: {0}' -f $relativeValue )
                [void]$scriptCode.Add('                               type: "{0}" ' -f $type )
            } #end foreach locationEntries
        

        } #end foreach $ligIC
        

        if ($category -ne 'sas-logical-interconnect-groups')
        {
            [void]$scriptCode.Add('             #enableIgmpSnooping: {0}' -f $igmpSnooping)
            if ($igmpIdletimeOut)
            {
                [void]$scriptCode.Add('             #igmpIdleTimeoutInterval: {0}' -f $igmpIdleTimeout)
            }
            [void]$scriptCode.Add('             #enableNetworkLoopProtection: {0}' -f $networkLoopProtection)
            [void]$scriptCode.Add('             #enablePauseFloodProtection: {0}' -f $pauseFloodProtection)
            [void]$scriptCode.Add('             #enableRichTLV: {0}' -f $enableRichTLV)
            [void]$scriptCode.Add('             #enableTaggedLldp: {0}' -f $LDPTagging)
            [void]$scriptCode.Add('             #enableStormControl: {0}' -f $stormControl)
            [void]$scriptCode.Add('             #stormControlThreshold: {0}' -f $stormControlThreshold)
            [void]$scriptCode.Add('             #fastMacCacheFailover: {0}' -f $fastMacCacheFailover)
            [void]$scriptCode.Add('             #macRefreshInterval: {0}' -f $macRefreshInterval)




            # Internal Networks in LIG
            if ($internalNetworkUris)
            {
                [void]$scriptCode.Add('             internalNetworkUris:')
                foreach ($neturi in $internalNetworkUris)
                {
                    $netname    = Get-NamefromUri -uri $neturi
                    [void]$scriptCode.Add(('                - "{0}"    # network name is : {1} ' -f $netUri, $netname))
                }

            }


            ## -- UplinkSets
            $uplinkSets             = $lig.uplinksets | sort-object Name
            if ($uplinkSets)
            {
                [void]$scriptCode.Add('             uplinkSets:')
                foreach ($upl in $uplinkSets)
                {
                    $uplName                = $Upl.name
                    $networkType            = $Upl.networkType
                    $ethMode                = $Upl.mode
                    $nativenetURIs          = $Upl.nativeNetworkUri
                    $netTagtype             = $Upl.ethernetNetworkType
                    $lacpTimer              = $Upl.lacpTimer
                    $networkURIs            = $upl.networkUris
                    $uplLogicalPorts        = $Upl.logicalportconfigInfos

                    [void]$scriptCode.Add('                 - name: "{0}"' -f $uplName)
                    [void]$scriptCode.Add('                   networkType: "{0}"' -f $networkType)
                    [void]$scriptCode.Add('                   mode: "{0}"' -f $ethMode)
                    #[void]$scriptCode.Add('                   ethernetnetworkType: "{0}"' -f $netTagtype)

                    # Networks in uplinkSets
                    if ($networkUris)
                    {
                        [void]$scriptCode.Add('                   networkUris:')
                        foreach ($neturi in $networkUris)
                        {
                            $netname    = Get-NamefromUri -uri $neturi
                            [void]$scriptCode.Add(('                     - "{0}"    # network name is : {1} ' -f $netUri, $netname))
                        }

                    }
                    else # No networks
                    {
                        [void]$scriptCode.Add('                   networkUris: []')                  
                    }

                    if ($uplLogicalPorts)
                    {
                        [void]$scriptCode.Add('                   logicalPortConfigInfos:')  
                        foreach ($port in $uplLogicalPorts)
                        {
                            $desiredSpeed           = $port.desiredSpeed
                            [void]$scriptCode.Add('                     - desiredSpeed: "{0}"' -f $desiredSpeed)

                            [void]$scriptCode.Add('                       logicalLocation:')
                            [void]$scriptCode.Add('                         locationEntries:')
                            $locationEntries        = $port.logicalLocation.LocationEntries
                            foreach ($entry in $locationEntries)
                            {
                                $relativeValue      = $entry.relativeValue
                                $type               = $entry.type
        
                                [void]$scriptCode.Add('                             - relativeValue: {0}' -f $relativeValue )
                                [void]$scriptCode.Add('                               type: "{0}" ' -f $type )
                            } #end foreach locationEntries
                        }
                    }
                    else # Logical Ports not defined
                    {
                        [void]$scriptCode.Add('                   logicalPortConfigInfos: []')  
                    }


                } # end foreach uplinkset
            } # end if uplinksets    
        

        } # end not SAS

        [void]$scriptCode.Add('       delegate_to: localhost')
        [void]$scriptCode.Add(' ')


    } # end foreach

    $scriptCode = $scriptCode.ToArray() 
    Out-ToScriptFile -Outfile $outFile 


} 
####

Function Generate-EnclosureGroup-Ansible ([string]$outfile, $list)
{
    
    foreach ($EG in $List)
    {
        $name                   = $EG.name
        $description            = $EG.description
        $enclosureCount         = $EG.enclosureCount
        $powerMode              = $EG.powerMode

        $manageOSDeploy         = $EG.osDeploymentSettings.manageOSDeployment
        $deploySettings         = $EG.osDeploymentSettings.deploymentModeSettings
        $deploymentMode         = $deploySettings.deploymentMode

        $ipAddressingMode       = $EG.ipAddressingMode
        $ipRangeUris            = $EG.ipRangeUris
        $ICbayMappings          = $EG.InterConnectBayMappings
        $enclosuretype          = $EG.enclosureTypeUri.Split('/')[-1]

        [void]$scriptCode.Add('     - name: Create Enclosure Group {0}' -f $name)
        [void]$scriptCode.Add('       oneview_enclosure_group:')
        [void]$scriptCode.Add('         config: "{{ config }}"')
        [void]$scriptCode.Add('         state: present')
        [void]$scriptCode.Add('         data:')
        [void]$scriptCode.Add('             name: "{0}"' -f $name)
        [void]$scriptCode.Add('             ipAddressingMode: "{0}"' -f $ipAddressingMode)
        [void]$scriptCode.Add('             enclosureCount: {0}' -f $enclosureCount)
        [void]$scriptCode.Add('             powerMode: {0}' -f $powerMode)

        if ($ICbayMappings)
        {
            [void]$scriptCode.Add('             interconnectBayMappings:') 

            foreach ($ICbay in $ICbayMappings)
            {
                $bayNumber          = $ICbay.interconnectBay
                $enclosureIndex     = $ICbay.enclosureIndex
                $ligUri             = $ICbay.logicalInterconnectGroupUri
                $ligname            = Get-NamefromUri $ligUri

                if ($enclosureIndex)
                {
                    [void]$scriptCode.Add('                 - interconnectBay: {0}' -f $bayNumber) 
                    [void]$scriptCode.Add('                   enclosureIndex: {0}' -f $enclosureIndex) 
                    [void]$scriptCode.Add(('                   logicalInterconnectGroupUri: "{0}" # lig name is: {1}' -f $ligUri, $ligname) )
                }
                else # EnclosureIndex is $NULl --> the lig is populated in each  enclosure/frame
                {
                    for ($i=1; $i -le $enclosureCount; $i++)
                    {
                        $enclosureIndex = $i
                        [void]$scriptCode.Add('                 - interconnectBay: {0}' -f $bayNumber) 
                        [void]$scriptCode.Add('                   enclosureIndex: {0}' -f $enclosureIndex) 
                        [void]$scriptCode.Add(('                   logicalInterconnectGroupUri: "{0}" # lig name is: {1}' -f $ligUri, $ligname) )
                    }
                } # end else
            } # end ICBay
        } # end ICbayMappings
        else 
        {
            [void]$scriptCode.Add('             interconnectBayMappings: []')   
        }


        [void]$scriptCode.Add('       delegate_to: localhost')
        [void]$scriptCode.Add(' ')
    } # endforeach

    $scriptCode = $scriptCode.ToArray() 
    Out-ToScriptFile -Outfile $outFile 

}


Function Generate-LogicalEnclosure-Ansible ([string]$outfile, $list) # TO BE REVIEWED
{
    

    foreach ($LE in $list)
    {
        $name               = $LE.name
        $enclUris           = $LE.enclosureUris
        $EncGroupUri        = $LE.enclosuregroupUri
        $FWbaselineUri      = $LE.firmware.firmwareBaselineUri
        $FWinstall          = if ($LE.firmware.forceInstallFirmware) {'true'} else { 'false' }

        $EGName             = Get-NamefromUri -uri $EncGroupUri

        [void]$scriptCode.Add('     - name: Create logical enclosure {0}' -f $name)
        [void]$scriptCode.Add('       oneview_logical_enclosure:')
        [void]$scriptCode.Add('         config: "{{ config }}"')
        [void]$scriptCode.Add('         state: present')
        [void]$scriptCode.Add('         data:')
        [void]$scriptCode.Add('             name: "{0}"' -f $name)
        [void]$scriptCode.Add(('             enclosureGroupUri: "{0}" # Enclosure Group name is {1}' -f $encGroupUri, $EGName))
        [void]$scriptCode.Add('             enclosureUris:') 
        foreach ($uri in $enclUris)
        {
            $enclName       = Get-NamefromUri -uri $uri
            [void]$scriptCode.Add(('                 - "{0}" # Enclosure name is {1}' -f $uri, $enclName))
        }

        [void]$scriptCode.Add('       delegate_to: localhost')
        [void]$scriptCode.Add(' ')
    } # endforeach

    $scriptCode = $scriptCode.ToArray() 
    Out-ToScriptFile -Outfile $outFile 

}



# region ServerProfile
Function Generate-LocalStorage-Ansible
{
    Param ($list, [switch]$isServerProfile )

    $listofControllers       = $list.controllers
    $listofSASJBODs          = $list.sasLogicalJBODs | sort Id

    if ($listofSASJBODs)
    {
        [void]$scriptCode.Add('             localStorage:'                      )
        [void]$scriptCode.Add('                 sasLogicalJBODs:'                      )
        foreach ($jbod in $listofSASJBODs)
        {
            $name            = $jbod.name
            $deviceSlot      = $jbod.deviceSlot
            $id              = $jbod.Id  
            $numPhysDrives   = $jbod.numPhysicalDrives
            $driveMinSizeGB  = $jbod.driveMinSizeGB 
            $driveMaxSizeGB  = $jbod.driveMaxSizeGB 
            $driveTechnology = $jbod.driveTechnology
            $eraseData       = if ($jbod.eraseData) {'true'} else {'false'} 
            
            [void]$scriptCode.Add('                     - id: {0}'          -f $id )
            [void]$scriptCode.Add('                       deviceSlot: "{0}"'          -f $deviceSlot)
            [void]$scriptCode.Add('                       name: "{0}"'                  -f $name)
            [void]$scriptCode.Add('                       numPhysicalDrives: {0}'       -f $numPhysDrives)
            [void]$scriptCode.Add('                       driveMinSizeGB: {0}'          -f $driveMinSizeGB)
            [void]$scriptCode.Add('                       driveMaxSizeGB: {0}'          -f $driveMaxSizeGB)
            [void]$scriptCode.Add('                       driveTechnology: "{0}"'       -f $driveTechnology)
            [void]$scriptCode.Add('                       eraseData: {0}'               -f $eraseData)
        } # end JBOD
    } # end SASJBODs

    if ($listofControllers)
    {
        [void]$scriptCode.Add('                 controllers:'                   )
        foreach ($cont in $listofControllers)
        {
            $deviceSlot          = $cont.deviceSlot
            $mode                = $cont.mode
            $initialize          = if ($cont.initialize) {'true'} else {'false'}
            $importConfig        = $cont.importConfiguration
            $importConfiguration = if ($importConfig) {'true'} else {'false'}
            $logicalDrives       = $cont.logicalDrives
    
            if ($logicalDrives)
            {
                [void]$scriptCode.Add('                     - deviceSlot: "{0}"'    -f $deviceSlot )
                [void]$scriptCode.Add('                       mode: "{0}"'          -f $mode )
                [void]$scriptCode.Add('                       initialize: {0}'      -f $initialize )
        
                if ($importConfig -and $isServerProfile  -and ($deviceSlot -notlike 'Mezz*')  )  # Import Lofgical Disk config for embedded controller only
                {
                    #[void]$scriptCode.Add('                       importConfiguration: "{0}"'          -f $importConfiguration )
                }
                else
                {
                    #[void]$scriptCode.Add('                       importConfiguration: false'  )
                    [void]$scriptCode.Add('                       logicalDrives:' )
        
                    if ($logicalDrives)
                    {             
                        foreach ($ld in $logicalDrives )
                        {
                            $raidLevel        = $ld.raidLevel
                            $bootable         = if ($ld.bootable) {'true'} else {'false'} 
                            $sasLogJBODId     = $ld.sasLogicalJBODId
                            $accelerator      = $ld.accelerator
                            
        
                            $name             = $ld.name
                            $numPhysDrives    = $ld.numPhysicalDrives
                            $driveTechnology  = $ld.driveTechnology  
                    
                            if (-not $name)
                            {
                                $name = 'null'
                            }
        
                            if ($deviceSlot -eq 'Embedded')
                            {
                                $sasLogJBODId = 'null'
                            }
                            else 
                            {
                                $driveTechnology = 'null'
                                $numPhysDrives   = 'null'    
                            }
                        
        
                            [void]$scriptCode.Add('                         - name: {0}'                  -f $name )
                            [void]$scriptCode.Add('                           raidLevel: "{0}"'           -f $raidLevel )
                            [void]$scriptCode.Add('                           bootable: "{0}"'            -f $bootable )
                            [void]$scriptCode.Add('                           numPhysicalDrives: {0}'     -f $numPhysDrives )
                            [void]$scriptCode.Add('                           driveTechnology: {0}'       -f $driveTechnology )
                            [void]$scriptCode.Add('                           sasLogicalJBODId: {0}'      -f $sasLogJBODId )
        
                        } # end if LogicalDrives
                    } 
                } # end ImportConfig
            } # end logicalDrives

        } # end foreach controller
    
    } # end ListControllers


    return $ScriptCode
}

###
Function Generate-NetConnection-Ansible
{
    Param ( $list)

    [void]$scriptCode.Add('             connectionSettings:'                      )
    [void]$scriptCode.Add('                 connections:'                         )
    
    foreach ($Conn in $list)
    {
        $connID             = $Conn.id
        $connName           = $Conn.name
        $connType           = $Conn.functionType
        $netUri             = $Conn.networkUri
            $ThisNetwork    = Get-HPOVNetwork | where uri -eq $netUri
            if (-not $ThisNetwork)                      # could be networkset
            {
                $ThisNetwork    = Get-HPOVNetworkSet | where uri -eq $netUri
            }
            $netName        = $thisNetwork.name 
        $portID             = $Conn.portID
        $requestedVFs       = $Conn.requestedVFs
        $macType            = $Conn.macType
            $mac            = ""
            if ( ($connType -eq 'Ethernet') -and ($macType -eq "UserDefined"))
            {   
                $mac        = $Conn.mac -replace '[0-9a-f][0-9a-f](?!$)', '$&:'
            }

        $wwpnType           = $Conn.wwpnType
            $wwpn           = $wwnn = ""
            if (($connType -eq 'FibreChannel') -and ($wpnType -eq "UserDefined"))
            {   
                $mac        = $Conn.mac  -replace '[0-9a-f][0-9a-f](?!$)', '$&:'   # Format 10:00:11
                $wwpn       = $Conn.wwpn -replace '[0-9a-f][0-9a-f](?!$)', '$&:'
                $wwnn       = $Conn.wwnn -replace '[0-9a-f][0-9a-f](?!$)', '$&:'
            }

        $requestedMbps      = $Conn.requestedMbps 
        $allocatededMbps    = $Conn.allocatedMbps
        $maximumMbps        = $Conn.maximumMbps
        $lagName            = $Conn.lagName
        $ipV4               = $Conn.ipv4

        $boot               = $conn.boot
        $bootPriority       = $boot.priority   
        $bootVolumeSource   = $boot.bootVolumeSource
        $bootvLANId         = $boot.bootVlanId
        $bootTargets        = $boot.targets
        $bootEthernetType   = $boot.ethernetBootType
        $bootiscsi          = $boot.iscsi
        


        [void]$scriptCode.Add('                     - id: {0}'                                                          -f $connID                      )
        [void]$scriptCode.Add('                       portId: "{0}"'                                                    -f $portID                      )
        [void]$scriptCode.Add('                       name: "{0}"'                                                      -f $connName                    )
        [void]$scriptCode.Add('                       functionType: "{0}"'                                              -f $connType                    )
       [void]$scriptCode.Add(('                       networkUri: "{0}" # network or networkset name is: "{1}"'         -f $netUri, $netName)           )
        [void]$scriptCode.Add('                       requestedMbps: {0}'                                               -f $requestedMbps               )

        ## VF function
        if ($connType -eq 'Ethernet')
        {
            [void]$scriptCode.Add('                       requestedVFs: {0}'                                                -f $requestedVFs             )
        }

        ## LAG
        if ($lagname)
        {
            [void]$scriptCode.Add('                       lagName: "{0}"'                                                      -f $lagName              )
        }

        ## ipv4
        if ($ipV4)
        {
            $ipAddressSource        = $ipV4.ipAddressSource

            [void]$scriptCode.Add('                       ipv4:'                                                                                        )
            [void]$scriptCode.Add('                         ipAddressSource: "{0}"'                                         -f $ipAddressSource         )
            if ($ipAddressSource -eq 'UserDefined')
            {
                $gateway                = $ipV4.gateway
                $subnetMask             = $ipV4.subnetMask 
                [void]$scriptCode.Add('                         gateway: {0}'                                                   -f $gateway             )
                [void]$scriptCode.Add('                         subnetMask: {0}'                                                -f $subnetMask          )
            }
        }

        if ($bootPriority -ne 'NotBootable')
        {
            $bootvLANId        = if ($bootvLANId) {$bootvLANId} else {'null'}

            [void]$scriptCode.Add('                       boot: '       )
            [void]$scriptCode.Add('                         priority: "{0}"'                                                    -f $bootpriority        )
            [void]$scriptCode.Add('                         bootVlanId: {0}'                                                    -f $bootvLANId          )

            if ($bootEthernetType)
            {
                [void]$scriptCode.Add('                         ethernetBootType: "{0}"'                                            -f $bootEthernetType )
            }

            if ($bootVolumeSource)
            {
                [void]$scriptCode.Add('                         bootVolumeSource: "{0}"'                                            -f $bootVolumeSource )
            }

            if ($bootTargets)
            {
                $arrayWwpn               = $bootTargets.arrayWwpn 
                $lun                     = $bootTargets.lun
                [void]$scriptCode.Add('                         targets:'                                                                               )
                [void]$scriptCode.Add('                             - arrayWwpn: {0}'                                               -f $arrayWwpn       )
                [void]$scriptCode.Add('                               lun: {0}'                                                     -f $lun             )
            }

            if ($bootiscsi)
            {
                $chapLevel              = $bootiscsi.chapLevel
                $firstIP                = $bootiscsi.firstBootTargetIp
                $initiatorName          = $bootiscsi.initiatorNameSource
                $secondIP               = $bootiscsi.secondBootTargetIp
                $secondTarget           = $bootiscsi.secondBootTargetPort
                [void]$scriptCode.Add('                         iscsi:'                                                                                 )
                [void]$scriptCode.Add('                             chapLevel: "{0}"'                                               -f $chapLevel       )
                [void]$scriptCode.Add('                             firstBootTargetIp: {0}'                                         -f $firstIP         )
                [void]$scriptCode.Add('                             initiatorNameSource: "{0}"'                                     -f $initiatorName   )
                [void]$scriptCode.Add('                             secondBootTargetIp: {0}'                                        -f $secondIP        )
                [void]$scriptCode.Add('                             secondBootTargetPort: {0}'                                      -f $secondTarget    )
            }


        }
    } #end foreach

    return $ScriptCode
}
####
## -------------------------------------------------------------------------------------------------------------
##
##                     Function Generate-ProfileTemplateScript
##
## -------------------------------------------------------------------------------------------------------------

Function Generate-ProfileTemplate-Ansible ( $List ,$outFile)
{

    foreach ($SPT in $List)
    {
        # ------- Network Connections
        $ListofConnections   = $SPT.connectionSettings.connections


        # ---------- SAN storage Connection
        $SANStorageList     = $SPT.SanStorage
        $ManagedStorage     = $SPT.SanStorage.manageSanStorage

        # ---------- Local storage Connection
        $ListoflocalStorage = $SPT.localStorage

        # ----------- SPT attribute
        $name               = $SPT.Name   
        $description        = $SPT.Description 
        $spDescription      = $SPT.serverprofileDescription
        $shtUri             = $SPT.serverHardwareTypeUri
        $egUri              = $SPT.enclosureGroupUri
        $affinity           = $SPT.affinity 
        $hideFlexNics       = if ($SPT.hideUnusedFlexNics) {'true'} else {'false'}
        $macType            = $SPT.macType
        $wwnType            = $SPT.wwnType
        $snType             = $SPT.serialNumberType       
        $iscsiType          = $SPT.iscsiInitiatorNameType 
        $osdeploysetting    = $SPT.osDeploymentSettings

        $fw                 = $SPT.firmware
        $isFwManaged        = $fw.manageFirmware
        if ($isFwManaged)
        {
            $fwInstallType  = $fw.firmwareInstallType
            $fwForceInstall = if ($fw.forceInstallFirmware ) {'true'} else {'false'}
            $fwActivation   = $fw.firmwareActivationType

            $fwBaseUri      = $fw.firmwareBaselineUri
            $sppName        = Get-NamefromUri  -uri $fwBaseUri
        }
    

        $bm                 = $SPT.bootMode
        $isbootModeManaged  = $bm.manageMode
        if ($isbootModeManaged)
        {
            $manageMode     = 'true'
            $bootMode       = $bm.mode
            $bootPXE        = $bm.pxeBootPolicy
            $bootSecure     = $bm.secureBoot
        }

        $bo                 = $SPT.boot
        $isBootManaged      = $bo.manageBoot
        if ($isBootManaged)
        {
            $orderArray     = $bo.order
        }

        $bios               = $SPT.bios
        $isBiosManaged      = $bios.manageBios

    

        $sht                = send-HPOVRequest  -uri $shtUri
        $shtName            = $sht.name
        
        $eg                 = send-hpovRequest -uri $egUri
        $egName             = $eg.name



        [void]$scriptCode.Add('     - name: Create server profile template {0}' -f $name                    )
        [void]$scriptCode.Add('       oneview_server_profile_template:'                                     )
        [void]$scriptCode.Add('         config: "{{ config }}"'                                             )
        [void]$scriptCode.Add('         state: present'                                                     )
        [void]$scriptCode.Add('         data:'                                                              )
        [void]$scriptCode.Add('             name:                       "{0}"' -f $name                     )
        [void]$scriptCode.Add('             description:                "{0}"' -f $description              )
        [void]$scriptCode.Add('             serverProfileDescription:   "{0}"' -f $spdescription            )
        [void]$scriptCode.Add('             enclosureGroupName:         "{0}"' -f $egName                   ) 
        [void]$scriptCode.Add('             serverHardwareTypeName:     "{0}"' -f $shtName                  ) 
        [void]$scriptCode.Add('             affinity:                   "{0}"' -f $affinity                 )
        [void]$scriptCode.Add('             macType:                    "{0}"' -f $macType                  )
        [void]$scriptCode.Add('             wwnType:                    "{0}"' -f $wwnType                  )
        [void]$scriptCode.Add('             serialNumberType:           "{0}"' -f $snType                   ) 
        [void]$scriptCode.Add('             hideUnusedFlexNics:         {0}  ' -f $hideFlexNics             )
        [void]$scriptCode.Add('             iscsiInitiatorNameType:     "{0}"' -f $iscsiType                )

        # Firmware
        if ($isFwManaged)
        {
            [void]$scriptCode.Add('             firmware:'                                                  )    
            [void]$scriptCode.Add('                 manageFirmware:            {0}'    -f 'true'            )
            [void]$scriptCode.Add('                 forceInstallFirmware:      {0}'    -f $fwForceInstall   )
            [void]$scriptCode.Add('                 firmwareInstallType:       "{0}"'  -f $fwInstallType    )
            [void]$scriptCode.Add('                 firmwareActivationType:    "{0}"'  -f $fwActivation     )
            [void]$scriptCode.Add('                 firmwareBaselineName:      "{0}"'  -f $sppName          )
        
        }
           

        #Manage Boot
        if ($isbootModeManaged)
        {
            [void]$scriptCode.Add('             bootMode:'                                                  )
            [void]$scriptCode.Add('                 manageMode:    {0}' -f $manageMode                      )
            [void]$scriptCode.Add('                 mode:          "{0}"' -f $bootMode                      )
            [void]$scriptCode.Add('                 pxeBootPolicy: "{0}"' -f $bootPXE                       )
            [void]$scriptCode.Add('                 secureBoot:    "{0}"' -f $bootSecure                    )
        }

        # Boot Order
        if ($isBootManaged)
        {
            [void]$scriptCode.Add('             boot:'                                                      )
            [void]$scriptCode.Add('                 manageBoot: {0}' -f 'true'                              )
            [void]$scriptCode.Add('                 order:'                                                 )
            $orderArray     = $bo.order
            foreach ($order in $orderArray)
            {
                [void]$scriptCode.Add('                     - "{0}" ' -f $order                             )
            }

        } # end BootOrder

        # BIOS
        if ($isBiosManaged)
        {
            [void]$scriptCode.Add('             bios:'                                                      )
            [void]$scriptCode.Add('                 manageBios:     {0}' -f 'true'                          )
            [void]$scriptCode.Add('                 overriddenSettings:'                                    )

            foreach ($setting in $bios.overriddenSettings)
            {
                $id         = $setting.id
                $value      = $setting.value

                [void]$scriptCode.Add('                     - id:    "{0}" ' -f $id                         )
                [void]$scriptCode.Add('                       value: "{0}" ' -f $value                      )
            }


        }# BIOS

        # ------- Local Storage Connections

        if ($ListoflocalStorage )
        {
            $LOCALStorageCode     = Generate-LocalStorage-Ansible -list  $listoflocalStorage 
        }

        # ------- network  Connections
        if ($listofConnections)
        {
           $netConnectionCode    = Generate-NetConnection-Ansible -list $ListofConnections 
        }
        
        [void]$scriptCode.Add('       delegate_to: localhost')
        [void]$scriptCode.Add(' ')

    } # endforeach
    
    $scriptCode = $scriptCode.ToArray() 
    Out-ToScriptFile -Outfile $outFile 
}

## -------------------------------------------------------------------------------------------------------------
##
##                     Function Generate-ProfileScript
##
## -------------------------------------------------------------------------------------------------------------

Function Generate-Profile-Ansible ( $List ,$outFile)
{

    foreach ($SPT in $List)
    {
        # ------- Network Connections
        $ListofConnections   = $SPT.connectionSettings.connections

        # ---------- SAN storage Connection
        $SANStorageList     = $SPT.SanStorage
        $ManagedStorage     = $SPT.SanStorage.manageSanStorage

        # ---------- Local storage Connection
        $ListoflocalStorage = $SPT.localStorage

        # ---------- SP attributes
        $name               = $SPT.Name   
        $description        = $SPT.Description 
        $serverUri          = $SPT.serverHardwareUri
        $sptUri             = $SPT.serverProfileTemplateUri 
        $egUri              = $SPT.enclosureGroupUri
        $enclosureBay       = $SPT.EnclosureBay
        $enclUri            = $SPT.enclosureUri
        $shtUri             = $SPT.ServerHardwareTypeUri
        $affinity           = $SPT.affinity
        $hideFlexNics       = if ($SPT.hideUnusedFlexNics) {'true'} else {'false'}
        


        $fw                 = $SPT.firmware
        $isFwManaged        = $fw.manageFirmware
        if ($isFwManaged)
        {
            $fwInstallType  = $fw.firmwareInstallType
            $fwForceInstall = if ($fw.forceInstallFirmware ) {'true'} else {'false'}
            $fwActivation   = $fw.firmwareActivationType
            $dtFw           = ''
            if ($fwActivation -eq 'Scheduled')
            {
                $dtFw       = $fw.firmwareScheduleDateTime
            }

            $fwBaseUri      = $fw.firmwareBaselineUri
            $sppName        = Get-NamefromUri  -uri $fwBaseUri
        }

        $bm                 = $SPT.bootMode
        $isbootModeManaged  = $bm.manageMode
        if ($isbootModeManaged)
        {
            $manageMode     = 'true'
            $bootMode       = $bm.mode
            $bootPXE        = $bm.pxeBootPolicy
            $bootSecure     = $bm.secureBoot
        }

        $bo                 = $SPT.boot
        $isBootManaged      = $bo.manageBoot
        if ($isBootManaged)
        {
            $orderArray     = $bo.order
        }

        $bios               = $SPT.bios
        $isBiosManaged      = $bios.manageBios

        $snType             = $SPT.serialNumberType
        if ($snType -eq 'UserDefined')
        {
            $sn             = $SPT.serialNumber
            $uuid           = $SPT.uuid
        }


        # get names
        $shtName            = Get-NamefromUri -uri $shtUri
        $egName             = Get-NamefromUri -uri $egUri
        $enclName           = Get-NamefromUri -uri $enclUri
        $serverName         = Get-NamefromUri -uri $serverUri
        $sptName            = Get-NamefromUri -uri $sptUri  



        [void]$scriptCode.Add('     - name: Create server profile {0}'                          -f $name                )
        [void]$scriptCode.Add('       oneview_server_profile:'                                                          )
        [void]$scriptCode.Add('         config: "{{ config }}"'                                                         )
        [void]$scriptCode.Add('         state: present'                                                                 )

        if (-not $serverName) # to set server to unassigned
        {
            [void]$scriptCode.Add('         auto_assign_server_hardware: false'                                         )
        }

        [void]$scriptCode.Add('         data:'                                                                          )
        [void]$scriptCode.Add('             name:                       "{0}"'                  -f $name                )
        [void]$scriptCode.Add('             description:                "{0}"'                  -f $description         )
        [void]$scriptCode.Add('             serverHardwareName:         "{0}"  '                -f $serverName          )

        if ($sptUri)    # Create from Template?
        {
            [void]$scriptCode.Add('             serverProfileTemplateName:  "{0}"  '                -f $sptName             )
        }
        else  # create from scratch 
        {
            [void]$scriptCode.Add('             affinity:                   "{0}"  '                -f $affinity            )          
            [void]$scriptCode.Add('             enclosureGroupName:         "{0}"  '                -f $egName              )
            [void]$scriptCode.Add('             serverHardwareTypeName:     "{0}"  '                -f $shtName             )

            # FlexNICs
            [void]$scriptCode.Add('             hideUnusedFlexNics:         {0}  '                  -f $hideFlexNics        )

            ## SN
            if ($snType -eq 'UserDefined')
            {
                [void]$scriptCode.Add('             serialNumberType:           "{0}"  '                -f $snType          ) 
                [void]$scriptCode.Add('             serialNumber:               "{0}"  '                -f $sn              )   
                [void]$scriptCode.Add('             uuid:                       "{0}"  '                -f $uuid            )     
            }

            # Firmware
            if ($isFwManaged)
            {
                [void]$scriptCode.Add('             firmware:'                                                              )
                [void]$scriptCode.Add('                 manageFirmware:            {0}'    -f 'true'                        )
                [void]$scriptCode.Add('                 forceInstallFirmware:      {0}'    -f $fwForceInstall               )
                [void]$scriptCode.Add('                 firmwareInstallType:       "{0}"'  -f $fwInstallType                )
                [void]$scriptCode.Add('                 firmwareActivationType:    "{0}"'  -f $fwActivation                 )
                [void]$scriptCode.Add('                 firmwareBaselineName:      "{0}"'  -f $sppName                      )
                
                if ($fwActivation -eq 'Scheduled')
                {
                    [void]$scriptCode.Add('                 firmwareScheduleDateTime:  "{0}"'  -f $dtFW                     )
                }

            }

            #Manage Boot
            if ($isbootModeManaged)
            {
                [void]$scriptCode.Add('             bootMode:'                                                             )
                [void]$scriptCode.Add('                 manageMode:    {0}' -f $manageMode                                 )
                [void]$scriptCode.Add('                 mode:          "{0}"' -f $bootMode                                 )
                [void]$scriptCode.Add('                 pxeBootPolicy: "{0}"' -f $bootPXE                                  )
                [void]$scriptCode.Add('                 secureBoot:    "{0}"' -f $bootSecure                               )
            }

            # Boot Order
            if ($isBootManaged)
            {
                [void]$scriptCode.Add('             boot:'                                                                 )
                [void]$scriptCode.Add('                 manageBoot: {0}' -f 'true'                                         )
                [void]$scriptCode.Add('                 order:'                                                            )
                $orderArray     = $bo.order
                foreach ($order in $orderArray)
                {
                    [void]$scriptCode.Add('                     - "{0}" ' -f $order                                        )
                }

            } # end BootOrder

            # BIOS
            if ($isBiosManaged)
            {
                [void]$scriptCode.Add('             bios:'                                                                 )
                [void]$scriptCode.Add('                 manageBios:     {0}' -f 'true'                                     )
                [void]$scriptCode.Add('                 overriddenSettings:'                                               )

                foreach ($setting in $bios.overriddenSettings)
                {
                    $id         = $setting.id
                    $value      = $setting.value

                    [void]$scriptCode.Add('                     - id:    "{0}" ' -f $id                                    )
                    [void]$scriptCode.Add('                       value: "{0}" ' -f $value                                 )
                }


            }# BIOS

            # ---------- Local storage Connection
            if ($ListoflocalStorage )
            {
                $LOCALStorageCode     = Generate-LocalStorage-Ansible -list  $listoflocalStorage -isServerProfile
            }

            # ------- network  Connections
            if ($listofConnections)
            {
            $netConnectionCode    = Generate-NetConnection-Ansible -list $ListofConnections 
            }

        #[void]$scriptCode.Add('             enclosureBay:               {0}    '                -f $enclosureBay        ) # not working
        #[void]$scriptCode.Add('             enclosureName:              "{0}"  '                -f $enclName            ) # not working
        }


        [void]$scriptCode.Add('       delegate_to: localhost')
        [void]$scriptCode.Add(' ')

    } # endforeach
    
    $scriptCode = $scriptCode.ToArray() 
    Out-ToScriptFile -Outfile $outFile 

}

# endregion


# -------------------------------------------------------------------------------------------------------------
#
#       Main Entry
#
# -------------------------------------------------------------------------------------------------------------

# ---------------- Unload any earlier versions of the HPOneView POSH modules
#
Remove-Module -ErrorAction SilentlyContinue HPOneView.120
Remove-Module -ErrorAction SilentlyContinue HPOneView.200
Remove-Module -ErrorAction SilentlyContinue HPOneView.300
Remove-Module -ErrorAction SilentlyContinue HPOneView.310
Remove-Module -ErrorAction SilentlyContinue HPOneView.400

$testedVersion  = [int32] ($OneviewModule.Split($Dot)[1])

if ( ($testedVersion -ge 400) -or  (-not (get-module $OneViewModule)) )
{
    Import-Module -Name $OneViewModule
}
else 
{
    write-host -ForegroundColor YELLOW "Oneview module not found or version is lower than v4.0. The script is not developed for downlevel version of Oneview. Exiting now. "
    exit
}

# ---------------- Connect to Synergy Composer
#
cls
if (-not $ConnectedSessions)
{
    if ((-not $OVApplianceIP) -or (-not $OVAdminName) -or (-not $OVAdminPassword))
    {
        $sourceText = @"
## -----------------------------------------------------------------------
##
##          Configure access to master OV instance
##
##      Note: You will provide information to connect to the 
##             SOURCE OneView instance
##
## -----------------------------------------------------------------------
      
"@


        $sourceText | out-Host
        $OVApplianceIP      = Read-Host 'Synergy Composer IP Address'
        $OVAdminName        = Read-Host 'Administrator Username'
        $OVAdminPassword    = Read-Host 'Administrator Password' 	
        $OVAuthDomain       = Read-Host 'Authentication domain (local or AD domain)'
    } 
	
    $ApplianceConnection = Connect-HPOVMgmt -appliance $OVApplianceIP -user $OVAdminName -password $OVAdminPassword  -AuthLoginDomain $OVAuthDomain -errorAction stop

}

if (-not $global:ConnectedSessions) 
{
    Write-Host "Login to Synergy Composer or OV appliance failed.  Exiting."
    Exit
} 
else 
{
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    $scriptPath                             = "$PSscriptRoot\ansible-scripts"
    $ovConfigFile                           = "$scriptPath\oneview_config.json"
    if (-not (Test-path $scriptPath))
        {   $scriptFolder = md $scriptPath}

    if (-not (test-path $ovConfigFile))
    {
        $destinationText = @"
## -----------------------------------------------------------------------
##
##          Configure access to the destination OV instance
##
##      Note:   You will provide information to connect to the 
##              DESTINATION OneView instance. 
##              Information will be stored in oneview_config.json
##
## -----------------------------------------------------------------------

  
"@
        $destinationText | out-host
        $targetOVip             = Read-Host 'Target -> Synergy Composer IP Address'
        $targetAdminName        = Read-Host 'Target ->Administrator Username'
        $targetAdminPassword    = Read-Host 'Target --> Administrator Password' 	
        $config = @"
{
    "ip": "$targetOVip",
    "credentials": {
        "userName": "$targetAdminName",
        "password": "$targetAdminPassword"
    },
    "api_version": 600
}
"@
        $ovConfig               = new-item -path $ovconfigFile -ItemType file -force
        set-content -path $ovConfigFile -value $config 
    }


    $OVEthernetNetworksYML                  = "$scriptPath\ov-ethernetnetwork.yml"
    $OVNetworkSetYML                        = "$scriptPath\ov-networkset.yml"
    $OVFCNetworksYML                        = "$scriptPath\ov-fcnetwork.yml"

    $OVLogicalInterConnectGroupYML          = "$scriptPath\ov-logicalinterconnectgroup.yml"
    $OVUplinkSetYML                         = "$scriptPath\UpLinkSet.yml"

    $OVEnclosureGroupYML                    = "$scriptPath\ov-enclosuregroup.yml"
    $OVEnclosureYML                         = "$scriptPath\Enclosure.yml"
    $OVLogicalEnclosureYML                  = "$scriptPath\ov-logicalenclosure.yml"
    $OVDLServerYML                          = "$scriptPath\DLServers.yml"

    $OVProfileYML                           = "$scriptPath\ov-serverprofile.yml"
    $OVProfileTemplateYML                   = "$scriptPath\ov-serverprofiletemplate.yml"
    $OVProfileConnectionYML                 = "ProfileConnection.yml"
    $OVProfileLOCALStorageYML               = "ProfileLOCALStorage.yml"
    $OVProfileSANStorageYML                 = "ProfileSANStorage.yml"

    $OVProfileTemplateConnectionYML         = "ProfileTemplateConnection.yml"
    $OVProfileTemplateLOCALStorageYML       = "ProfileTemplateLOCALStorage.yml"
    $OVProfileTemplateSANStorageYML         = "ProfileTemplateSANStorage.yml"

    $OVSanManagerYML                        = "$scriptPath\SANManager.yml"
    $OVStorageSystemYML                     = "$scriptPath\StorageSystem.yml"
    $OVStoragePoolYML                       = "$scriptPath\StoragePool.yml"
    $OVStorageVolumeTemplateYML             = "$scriptPath\StorageVolumeTemplate.yml"
    $OVStorageVolumeYML                     = "$scriptPath\StorageVolume.yml"

    $OVAddressPoolYML                       = "$scriptPath\AddressPool.yml"
    $OVAddressPoolSubnetYML                 = "$scriptPath\ov-addresspoolsubnet.yml"


    $OVTimeLocaleYML                        = "$scriptPath\ov-timelocale.yml"
    $OVSmtpYML                              = "$scriptPath\SMTP.yml"
    $OVsnmpYML                              = "$scriptPath\snmp.yml"
    $OValertsYML                            = "$scriptPath\Alerts.yml"
    $OVScopesYML                            = "$scriptPath\Scopes.yml"
    $OVProxyYML                             = "$scriptPath\Proxy.yml"
    $OVfwBaselineYML                        = "$scriptPath\ov-fwbaseline.yml"

    #$OVOSDeploymentYML                      = "$scriptPath\OSDeployment.yml"
    #$OVUsersYML                             = "$scriptPath\Users.yml"
    #$OVBackupConfig                         = "$scriptPath\BackupConfiguration.yml"
    #$OVRSConfig                             = "$scriptPath\OVRSConfiguration.yml"
    #OVLdapYML                               = "$scriptPath\LDAP.yml"
    #$OVLdapGroupsYML                        = "$scriptPath\LDAPGroups.yml"
    
    
   
    $sanManagerList                             = Get-HPOVSanManager 
    if ($sanManagerList)
    {
#        Generate-sanManager-Script              -OutFile $OVsanManagerYML                   -List  $sanManagerList 
    } 

    $storageSystemList                          = get-HPOVStorageSystem
    if ($storageSystemList)
    {
#        Generate-StorageSystem-Script           -OutFile $OVstorageSystemYML                -List $storageSystemList
    }

    $storagePoolList                        = Get-HPOVStoragePool | where state -eq 'Managed'
    if ($storagePoolList)
    {
#        Generate-StoragePool-Script         -OutFile $OVstoragePoolYML                      -List $storagePoolList
    }

    $storageVolumeTemplateList                  = get-HPOVStorageVolumeTemplate
    if ($storageVolumeTemplateList)
    {
#        Generate-StorageVolumeTemplate-Script   -OutFile $OVStorageVolumeTemplateYML        -List $storageVolumeTemplateList
    }

    $storageVolumeList                          = get-HPOVStorageVolume
    if ($storageVolumeList)
    {
#        Generate-StorageVolume-Script           -OutFile $OVStorageVolumeYML                -List $storageVolumeList
    }

    $ethernetNetworkList                        = Get-HPOVNetwork -Type Ethernet
    if ($ethernetNetworkList)
    {
        $scriptCode                             =  New-Object System.Collections.ArrayList
        Generate-EthernetNetwork-Ansible         -OutFile $OVEthernetNetworksYML             -List $ethernetNetworkList 
    } 

    $fcNetworkList                              = Get-HPOVNetwork | Where-Object Type -like "Fc*"
    if ($FCnetworkList)
    {
        $scriptCode                             =  New-Object System.Collections.ArrayList
        Generate-FCNetwork-Ansible               -OutFile $OVFCNetworksYML                   -List $fcNetworkList 
    }

    $networksetList                             = Get-HPOVnetworkset
    if ($networksetList)
    {
        $scriptCode                             =  New-Object System.Collections.ArrayList
        Generate-NetworkSet-Ansible              -Outfile $OVNetworkSetYML                   -List $networksetList
    }

    $ligList                                    = Get-HPOVLogicalInterConnectGroup | sort-object Name
    if ($ligList)
    {
        $scriptCode                             =  New-Object System.Collections.ArrayList
        Generate-LogicalInterConnectGroup-Ansible -OutFile $OVLogicalInterConnectGroupYML    -List $ligList
#        Generate-UplinkSet-Script                -OutFile $OVUplinkSetYML                   -List $ligList
    }

    $egList                                     = Get-HPOVEnclosureGroup | sort-object Name
    if ($egList)
    {
        $scriptCode                             =  New-Object System.Collections.ArrayList
        Generate-EnclosureGroup-Ansible          -Outfile $OVEnclosureGroupYML               -List $egList
    }
    
    $leList                                     = Get-HPOVlogicalEnclosure | sort-object Name
    if ($leList) 
    {
        $scriptCode                             =  New-Object System.Collections.ArrayList
        Generate-LogicalEnclosure-Ansible        -Outfile $OVLogicalEnclosureYML             -List $leList 
    }

    $serverprofileTemplateList                  = get-HPOVserverProfileTemplate
    if ($serverprofileTemplateList)
    {
        $scriptCode                             =  New-Object System.Collections.ArrayList
        Generate-ProfileTemplate-Ansible         -OutFile $OVprofileTemplateYML              -List $serverProfileTemplateList 
    }


    $serverProfileList                          = Get-HPOVServerProfile
    if ($serverProfileList)
    { 
        $scriptCode                             =  New-Object System.Collections.ArrayList
        Generate-Profile-Ansible                -OutFile $OVprofileYML                      -List $serverProfileList 
    }


    $smtpConfigList                             = Get-HPOVSMTPConfig
    if ($smtpConfigList.SenderEmailAddress )
    {
#        Generate-smtp-Script                    -Outfile $OVsmtpYML                         -List $smtpConfigList
#        Generate-Alerts-Script                  -Outfile $OValertsYML                       -List $smtpConfigList
    }

    $snmpList                                   = Get-HPOVSnmpReadCommunity
    if ($snmpList )
    {
#        Generate-Snmp-Script                    -Outfile $OVsnmpYML                         -List $snmpList
    }
    
    $addressPoolSubnetList                      = Get-HPOVAddressPoolSubnet
    if ($addressPoolSubnetList)
    {
        $scriptCode                             =  New-Object System.Collections.ArrayList
        Generate-AddressPoolSubnet-Ansible      -Outfile $OVAddressPoolSubnetYML            -List $addressPoolSubnetList
    }

    $addressPoolList                            = Get-HPOVAddressPoolRange
    if ($addressPoolList)
    {
#        Generate-AddressPool-Script             -Outfile $OVAddressPoolYML                  -List $addressPoolList
    }

    $timelocaleList                             = Get-HPOVApplianceDateTime 
    if ($timelocaleList)
    {
        $scriptCode                             =  New-Object System.Collections.ArrayList
        Generate-TimeLocale-Ansible              -OutFile $OVTimeLocaleYML                  -List $timelocaleList 
    }   

    $scopeList                                  = Get-HPOVScope
    if ($scopeList)
    {
#        Generate-Scope-Script                   -Outfile $OVScopesYML                       -List $scopeList
    }

    $proxyList                                  = Get-HPOVApplianceProxy
    if ($proxyList )
    {
#        Generate-proxy-Script                   -OutFile $OVproxyYML                        -List $proxyList 
    }

    $fwList                                     = Get-HPOVbaseLine
    if ($fwList)
    {
#        $scriptCode                             =  New-Object System.Collections.ArrayList
#        Generate-fwBaseline-Ansible             -OutFile $OVfwBaselineYML                   -List $fwList
    }


    disconnect-hpovmgmt



}


