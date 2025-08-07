//
//  CreatePlaceView.swift
//  Dropin
//
//  Created by baptiste sansierra on 31/7/25.
//

import SwiftUI
import CoreLocation
import SwiftData

// TODO: check that https://developer.apple.com/documentation/mapkit/interacting-with-nearby-points-of-interest


struct CreatePlaceView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(PlaceFactory.self) private var placeFactory

    @State private var showingMarkerList = false
    @State private var showingTagsSelector = false
    @State private var showingGroupSelector = false
    @State private var selectedGroup: SDGroup?
    @State private var markerListModelView = MarkerListModelView()
    @State private var showPhoneField = false
    @State private var showUrlField = false
    @State private var showNotesField = false
    @State private var scrollPosition = ScrollPosition(edge: .top)

    private var phone: Binding<String> {
        Binding<String>(
            get: {
                return placeFactory.place.phone ?? ""
            }, set: { value in
                placeFactory.place.phone = value
            })
    }
    private var url: Binding<String> {
        Binding<String>(
            get: {
                return placeFactory.place.url ?? ""
            }, set: { value in
                placeFactory.place.url = value
            })
    }
    private var notes: Binding<String> {
        Binding<String>(
            get: {
                return placeFactory.place.notes ?? ""
            }, set: { value in
                placeFactory.place.notes = value
            })
    }

    @Query var groups: [SDGroup]
    @Query var tags: [SDTag]

    var body: some View {
        @Bindable var wipPlace = placeFactory.place
        
        VStack {
            NewPlaceFixedMap(place: wipPlace)
            
            // - Content
            ScrollView {
                HStack(alignment: .center) {
                    ZStack(alignment: .topLeading) {
                        PlaceAnnotationView(sysImage: wipPlace.systemImage,
                                            color: wipPlace.groupColor)
                        .padding()
                        IcoButton(systemImage: "ellipsis", icoSize: 14)
                            .padding(0)
                            .onTapGesture {
                                showingMarkerList.toggle()
                            }
                    }
                    VStack(alignment: .leading) {
                        TextField("Give place a name", text: $wipPlace.name)
                            .font(.title)
                            .autocorrectionDisabled()
                        Text(wipPlace.address.isEmpty ? "" : wipPlace.address)
                            .font(.callout)
                            .foregroundStyle(.gray)
                    }
                }
                .padding(EdgeInsets(top: 15,
                                    leading: 15,
                                    bottom: !showPhoneField || !showUrlField || !showNotesField ? 0 : 15,
                                    trailing: 15))
                
                HStack {
                    if !showPhoneField {
                        IcoButton(systemImage: "phone", icoSize: 14)
                            .padding(.horizontal, 15)
                            .padding(.top, 5)
                            .padding(.bottom, 10)
                            .onTapGesture {
                                withAnimation {
                                    showPhoneField.toggle()
                                }
                            }
                    }
                    if !showUrlField {
                        IcoButton(systemImage: "link", icoSize: 14)
                            .padding(.horizontal, 15)
                            .padding(.top, 5)
                            .padding(.bottom, 10)
                            .onTapGesture {
                                withAnimation {
                                    showUrlField.toggle()
                                }
                            }
                    }
                    if !showNotesField {
                        IcoButton(systemImage: "note.text", icoSize: 14)
                            .padding(.horizontal, 15)
                            .padding(.top, 5)
                            .padding(.bottom, 10)
                            .onTapGesture {
                                withAnimation {
                                    showNotesField.toggle()
                                    scrollPosition.scrollTo(edge: .bottom)
                                }
                            }
                    }
                }
                .padding(0)
                
                Divider()
                    .padding(.horizontal)
                
                // Phone
                VStack {
                    HStack {
                        Text("Phone")
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                        TextField("", text: phone)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                            .keyboardType(.phonePad)
                    }
                    Divider()
                        .padding(.horizontal)
                }
                .padding(0)
                .frame(height: showPhoneField ? 40 : 0 )
                .opacity(showPhoneField ? 1 : 0)
                .tag("phone")
                .border(.green, width: 2)

                // Url
                VStack {
                    HStack {
                        Text("Url")
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                        TextField("url", text: url)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                            .keyboardType(.URL)
                    }
                    Divider()
                        .padding(.horizontal)
                }
                .padding(0)
                .frame(height: showUrlField ? 40 : 0 )
                .opacity(showUrlField ? 1 : 0)
                .tag("url")
                .border(.red, width: 2)

                // Tags chooser
                VStack {
                    HStack {
                        Text("Tags")
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                        Spacer()
                        IcoButton(systemImage: "ellipsis", icoSize: 14)
                            .padding(.trailing, 15)
                            .onTapGesture {
                                showingTagsSelector.toggle()
                            }
                    }
                    if wipPlace.tags.count > 0 {
                        FlowLayout(alignment: .leading) {
                            ForEach(wipPlace.tags) { tag in
                                TagView(name: tag.name, color: Color(rgba: tag.colorHex))
                            }
                        }
                        .padding([.leading, .trailing, .bottom])
                    }
                }
                
                Divider()
                    .padding(.horizontal)

                // Group chooser
                VStack {
                    HStack {
                        Text("Group")
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                        Spacer()
                        
                        if let group = placeFactory.place.group {
                            GroupView(name: group.name,
                                      color: Color(rgba: group.colorHex),
                                      hasDestructiveBt: true,
                                      destructiveAction: {
                                placeFactory.place.group = nil
                            })
                            .padding(.trailing)
                        } else {
                            IcoButton(systemImage: "ellipsis", icoSize: 14)
                                .padding(.trailing, 15)
                                .onTapGesture {
                                    showingGroupSelector.toggle()
                                }
                        }
                    }
                }
                .frame(height: 60)
                Divider()
                    .padding(.horizontal)
                
                // Notes
                VStack {
                    HStack(alignment: .top) {
                        Text("Notes")
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                        Spacer()
                    }
                    TextField("Add more information here", text: notes, axis: .vertical)
                        .lineLimit(2...6)
                        .padding(.horizontal)
                        .onChange(of: wipPlace.notes) { oldVal, newVal in
                            // Scroll to bottom so edited line do not disapear under scroll
                            withAnimation {
                                scrollPosition.scrollTo(edge: .bottom)
                            }
                        }
                }
                .opacity(showNotesField ? 1 : 0)
                .tag("notes")
            }
            .scrollPosition($scrollPosition)
            Spacer()
            Divider()
            Button("Save this place") {
                placeFactory.save(modelContext: modelContext)
                dismiss()
            }
            .padding()

        }
        .onFirstAppear {
            // Fetch address from coords
            wipPlace.address = "Fetching address..."
            LocationManager.lookUpAddress(coords: wipPlace.coordinates) { address in
                guard let address = address else {
                    wipPlace.address = "N/A"
                    return
                }
                wipPlace.address = address
            }
        }
        .sheet(isPresented: $showingTagsSelector, onDismiss: {
            //wipPlace.tags = tagSelectorOutput.selected
        }) {
            TagSelectorView()
                .padding(.top, 40)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingGroupSelector, onDismiss: {

        }) {
            GroupSelectorView()
                .presentationDetents([.medium, .large])

        }
        
        .fullScreenCover(isPresented: $showingMarkerList, onDismiss: {
            wipPlace.systemImage = markerListModelView.selected
        }) {
            MarkerListView()
                .environment(markerListModelView)
        }
    }
}

#if DEBUG

private struct CLVPreview: View {

    let container: ModelContainer
    @State private var placeFactory = PlaceFactory.preview
    
    init() {
        print("CREATE TSVPreview")
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: SDPlace.self, configurations: config)
        } catch {
            fatalError("couldn't create model container")
        }
        container.mainContext.insert(SDTag.t1)
        container.mainContext.insert(SDTag.t2)
        container.mainContext.insert(SDTag.t3)
        container.mainContext.insert(SDTag.t4)
        container.mainContext.insert(SDTag.t5)
        container.mainContext.insert(SDTag.t6)
        container.mainContext.insert(SDTag.t7)
        container.mainContext.insert(SDTag.t8)
        container.mainContext.insert(SDTag.t9)
        container.mainContext.insert(SDTag.t10)
        container.mainContext.insert(SDTag.t11)
        
        container.mainContext.insert(SDGroup.g1)
        container.mainContext.insert(SDGroup.g2)
        container.mainContext.insert(SDGroup.g3)
        container.mainContext.insert(SDGroup.g4)
        container.mainContext.insert(SDGroup.g5)

        container.mainContext.insert(SDPlace.l1)
        container.mainContext.insert(SDPlace.l2)

        placeFactory.place.name = "My lovely place"
        placeFactory.place.tags = [SDTag.t4, SDTag.t8, SDTag.t11]
        placeFactory.place.group = SDGroup.g2

        do {
            try container.mainContext.save()
        } catch {
            print("COULDN t save DB")
        }
        print(container)
    }
    
    var body: some View {
        CreatePlaceView()
            .modelContainer(container)
//            .environment(TagSelectorOutput())
            .environment(placeFactory)
//            .environment(newLocation)
    }
}

#Preview {
    CLVPreview()
}

#endif
