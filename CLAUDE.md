Dropin is an iOS app and a personal project: Create your own places library on a map (as Mapstr)
A place may have one group and multiple tags
I use clean architecture with coordinators + MVVM

There's 4 layers :
* Domain : contains Models (structs) / Repositories protocols / UsesCases 
* Data : Data models / Repositories implementations : Local (SwiftData) + WIP Remote (Supabase)
* Presentations: UI Models (classes) / Views / ViewModels 
* Core: App / Services (LocationManager / AddresslookupService / ReachabilityService) / Resources / Logger / DependencyInjection / Coordinators
I'm in pre-MVP state

MVP goals :
* Handle places / groups / tags / pictures (Implemented)
* Import / Export dropin format (Implemented)
* Import mapstr format (Implemented)
* Offline access (Implemented)
* Remote storage (WIP with a supabase solution)
* Authentication (Missing)

