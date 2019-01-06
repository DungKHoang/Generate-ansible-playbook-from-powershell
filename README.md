# Generate ansible playbook from OneView

Generate-ansible.PS1 is a PowerShell script that generates ansible playbooks to configure new OneView instances. The script queries an existing OV instance (called 'Master') and based on resources and attributes configured in this instance, it will create ansible playbooks. Those playbooks can then be transferred to a linux machine running oneview ansible to be executed and re-create the environment. 

There are two categories of playbooks
* OV resources - the playbooks are used to create OV resources including
        * Ethernet networks
        * Network set
        * FC / FCOE networks
        * Logical InterConnect Groups
        * Uplink Sets
        * Enclosure Groups
        * Enclosures
        * Server Profile Templates with local storage connections and network connections
        * Server Profiles with local storage connections and network connections

* OV settings - the playbooks are used to configure OV settings including  
        * Time and locale and NTP servers



## Prerequisites
Both scripts require the OneView PowerShell library at least v4.1 : https://github.com/HewlettPackard/POSH-HPOneView/releases


## Syntax

### To generate ansible playbooks

```
    .\Generate-ansible.ps1     --> You will be prompted for credential and IP address of the master OV appliance
    .\Generate-ansible.ps1 -OVApplianceIP <OV-IP-Address-of-the-master-OV> -OVAdminName <Admin-name> -OVAdminPassword <password> -OVAuthDomain <local or AD-domain>

```
Playbooks will be created under the folder ansible-scripts. a oneview_config.json will also be created to provide information to access to teh destination OV instance

### To run ansible playbooks
Copy the folder ansible-scripts to a Linux machine configured to run oneview playbooks
