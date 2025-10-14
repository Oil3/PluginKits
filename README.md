<sub>Extension and plugin or plug-in, are used interchangeably and signify **Application and System Extension**. </sub> 

<sup>To refer to a **filename-extension**, file-extension and filename-extension are preferred.</sup>

   <p align="center">
  <img src="https://github.com/user-attachments/assets/63790fc2-300b-4a7c-b039-42d37f4e6c1c" height="128">
  <h1 align="center">PluginKits</h1>
   <p align="center">
Open-source macOS extension management.
</p>
 

   <p align="justify">


 


Edit Sep25: FYI if you need to register or re-register, a system extension, you can always drag/drop its .appex in the sidebar's bottom 'UTI informations' box, which for _.appex_ will manually register it.    
 

 ## Features

### QuickLook Extension Management

- **Conflict Detection**: Automatically identifies UTI conflicts between competing QuickLook extensions  
- **Selective Resolution**: Choose which extension handles specific file types when conflicts arise  
- **Extension Details**: View comprehensive metadata, identifiers, and paths for all extensions  

### System-Wide Plugin Registry
- **Complete Visibility**: Browse all hundreds+ extensions installed on your system  

### Advanced Controls
- **Individual Extension Control**: Manage extensions that System Preferences cannot access  
- **Be careful with what you deregister**: An "undo deregister" is present until app is terminated.  

## Privacy & Security

- **Zero Permissions Required**: No system permissions, network access, or sensitive data handling  
- **Network Disabled**: Internet connectivity explicitly disabled at the entitlement level  

## System Requirements

- macOS 13.0 or later  
- Apple Silicon or Intel Mac  

## Installation

Download from Releases.  
Choose the Ventura version if macOS < 14.0   

## Build from source

Xcode project -> Project -> Signing & Capabilities  
Select your own "development team", check Bundle Identifier, then:  
Clean Project -> Build/Run   

## Common Use Cases

-resolve Quick Look extensions issues.  
-choose which extension Quick Look uses, effective immediatelly.  
-inspect and control system extensions: manually add/remove/start/stop any extension, including system's.  


 100% Swift, no private-APIs, no permissions required.   
Universal binaries, Silicon and Intel supports, from macOS Ventura 13.0 to current, hardened and notarized.  
Privacy: Nothing is collected, and I chose to explicitey disable outgoing network connections at the entitlements level: enforced by GateKeeper, and user-verificable.  

A mac is a mac, and it needs to stay comfortable; but it's stil you mac.[^1]
 
## Support

Please open an 'issue' here in GitHub..

## License

This app is libre/open-source.
---
![Screenshot 2025-09-18 at 12 15 42 AM](https://github.com/user-attachments/assets/73203dcc-04e8-4c09-b699-066402bf6572)  
![Screenshot 2025-09-18 at 12 13 46 AM](https://github.com/user-attachments/assets/f9caa8a7-721f-49d2-b7e8-78fde8c501b8)  
![Screenshot 2025-09-17 at 11 34 34 PM](https://github.com/user-attachments/assets/381bb638-a694-4758-b3d9-1602ee3454d4)  
![Screenshot 2025-09-17 at 11 33 28 PM](https://github.com/user-attachments/assets/0b5bc586-5620-43ef-a84d-f89e5cd11b53)   

---
## QuickLook    
### Fix plugins version conflicts:    
This specific tool should fix issue when an older version supercedes a new one.  
In the "Extension Conflicts" tab: the tool automatically keeps the latest version and puts it in /Applications.[^2]  
You can alternatively manage manually, the important step is deactivating the conflicing versions; the tool goes beyond to ensure it stays like that.   
The process is virtually instantaneous, and Quick Look should work immediately.

### Fix another extension prevents a different  
This helps manage when you want to keep different extensions that handle the same file-extensions, basically it allows swap between the two in one click.  

![Screenshot 2025-09-17 at 11 29 57 PM](https://github.com/user-attachments/assets/34879c8c-3d28-442e-a40f-5d70c947747b)  
![Screenshot 2025-09-17 at 11 06 21 PM](https://github.com/user-attachments/assets/53b8e743-8c77-464f-8395-230bf8c6a5e7)  
   
 </p>  
----    
I made the app initially to debug Quick Look extensions, and I noticed that  we  had a lower level access than standard System Settings gave, allowing, e.g., to disable that 'Warda Synthethizer".     

[^1]: "A Mac is a Mac and it works. In front of a Macbook Retina you feel comfortable[...]" original quote Rocco Gagliardi, Audit in a OSX System https://www.scip.ch/en/?labs.20150108  
[^2]: A strict workflow: it deactivates duplicates, deregisters all plugins of this operation, zips/backups in temporary directory then puts in the trash the duplicates, move the kept extension in /Applications and finaly re-egister at the n itctivates the extension.    
[^3]: <h8>Mac and macOS are trademarks of [Apple Inc.](http://www.apple.com/), registered in the U.S. and other countries and regions.</h8> <sub><sup><sub><sup><sub><sup><sub><sup>[^3]</sub></sup></sub></sup></sub></sup></sub></sup>

