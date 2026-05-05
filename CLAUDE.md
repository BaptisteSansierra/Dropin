Dropin is an iOS app and a personal project: Create your own places library on a map (as Mapstr)
A place may have one group and multiple tags
I use clean architecture with coordinators + MVVM

There's 4 layers :
* Domain : contains Models (structs) / Repositories protocols / UsesCases 
* Data : Repositories implementations / data models (SwiftData objects)
* Presentations: UI Models (classes) / Views / ViewModels 
* Core: App / Services (LocationManager / AddresslookupService / ReachabilityService) / Resources / Logger / DependencyInjection / Coordinators
I'm in pre-MVP state
Persistency will be handled by SwiftData+icloud (not implemented yet) or by creating a server backend

MVP goal :
* Authentication
* Handle places / groups / tags
* Offline access
* Import / Export dropin format
* Import mapstr format 

