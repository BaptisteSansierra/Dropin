//
//  LabeledValueEditView.swift
//  Dropin
//
//  Created by baptiste sansierra on 29/1/26.
//

#if false
import SwiftUI
import NoFlyZone

struct LabeledValueEditViewNoFly: View {
    
    // MARK: - States & Bindings
    @State private var kind: EntityLabeledValue.TypeWithLabel.Kind
    // Layout
    @State private var labelMaxWidth: CGFloat = 0
    @State private var isRemovingRow = false
    // Data
    @Binding private var values: [LabeledValueRowUI]
    // NoFlyZone
    @Binding private var noFlyZoneCompletionStatus: NoFlyZoneCompletionStatus
    @Binding private var noFlyZoneEnabled: Bool
    @Binding private var noFlyAuthorizedZones: [NoFlyZoneData]
    
    // MARK: - properties
    private var viewIdentifier: Int
    private let roundedButtonsSize: CGFloat = 20
    private let rowHeight: CGFloat = 45
    private let swipeDeleteButtonW: CGFloat = 65
    private let rowLabelLeadPaddingW: CGFloat = 10
    private let rowDeleteButtonW: CGFloat = 50
    private let rowChevronW: CGFloat = 20
    private let rowSeparatorW: CGFloat = 0.5
    
    // MARK: - init
    init(viewIdentifier: Int,
         kind: EntityLabeledValue.TypeWithLabel.Kind,
         values: Binding<[LabeledValueRowUI]>,
         noFlyZoneEnabled: Binding<Bool>,
         noFlyZoneCompletionStatus: Binding<NoFlyZoneCompletionStatus>,
         noFlyAuthorizedZones: Binding<[NoFlyZoneData]>
    ) {
        self.viewIdentifier = viewIdentifier
        self.kind = kind
        self._values = values
        self._noFlyZoneEnabled = noFlyZoneEnabled
        self._noFlyZoneCompletionStatus = noFlyZoneCompletionStatus
        self._noFlyAuthorizedZones = noFlyAuthorizedZones
    }
    
    // MARK: - body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            Divider()
                .overlay(Color.backgroundTertiary)
            
            ForEach(values.indices, id: \.self) { idx in
                entityLabeledValueRow(idx)
                    .frame(height: values[idx].height)
                    .opacity(values[idx].opacity)
                    .padding(0)
                    .if(values[idx].clip) { view in
                        view.clipped()
                    }
                Divider()
                    .overlay(Color.backgroundTertiary)
                    .padding(.leading, 45)
                    .opacity(values[idx].separatorOpacity)
            }
            addView
                .frame(height: rowHeight)
            Divider()
                .overlay(Color.backgroundTertiary)
        }
        .background(.backgroundPrimary)
        .onChange(of: values.map { $0.toBeDeleted }, { oldValue, newValue in
        //.onChange(of: values, { oldValue, newValue in
            // Skip if we're in removal
            guard !isRemovingRow else { return }
            // If any item is marked as 'toBeDeleted', delete it
            guard let toBeRemovedIdx = values.firstIndex(where: { $0.toBeDeleted == true }) else { return }
            print("To be removed marked at \(toBeRemovedIdx) => reset it and animate")
            //values[toBeRemovedIdx].deleting = false
            //values[toBeRemovedIdx].toBeDeleted = false // reset the flag, ensure we do not delete twice
            removeRow(toBeRemovedIdx)
        })
        .onChange(of: noFlyZoneEnabled) { oldValue, newValue in
            guard newValue == false else { return }
            guard oldValue != newValue else { return }
            // Reset the zones once NoFlyZone is hidden
            noFlyAuthorizedZones = []
        }
        
        .onChange(of: noFlyZoneCompletionStatus) { oldValue, newValue in
            guard oldValue != newValue else { return }
            switch newValue {
                case .blocked:
                    // Reset row offsets if NoFlyZone was tapped on blocking zone
                    resetOffsets()
                default:
                    ()
            }
        }
    }
    
    // MARK: - subviews
    private var addView: some View {
        HStack {
            addButtonView
                .padding(.leading)
            Text(String(localized: getAddViewContent()).capitalized)
                .textStyle(.caption)
        }
    }
    
    private func removeButtonView(_ idx: Int) -> some View {
        Button {
            showRemoveButton(idx)
        } label: {
            ZStack {
                Circle()
                    .frame(width: roundedButtonsSize, height: roundedButtonsSize)
                    .foregroundStyle(.destructive)
                Image(systemName: "minus")
                    .foregroundStyle(.white)
                    .font(.caption)
            }
        }
    }
    
    private var addButtonView: some View {
        Button {
            addItem()
        } label: {
            ZStack {
                Circle()
                    .frame(width: roundedButtonsSize, height: roundedButtonsSize)
                    .foregroundStyle(.success)
                Image(systemName: "plus")
                    .foregroundStyle(.white)
                    .font(.caption)
            }
        }
    }
    
    private func entityLabeledValueRow(_ idx: Int) -> some View {
        ZStack(alignment: .trailing) {
            
            // Delete button hidden below row
            GeometryReader { geo in
                HStack {
                    Spacer()
                    Button {
                        // No action here, the remove action will be triggered if the according zone is tapped over the NoFlyZone
                    } label: {
                        ZStack {
                            Rectangle()
                                .frame(width: swipeDeleteButtonW, height: rowHeight)
                                .foregroundStyle(.destructive)
                            Image(systemName: "trash")
                                .foregroundStyle(.white)
                        }
                    }
                    .onChange(of: geo.frame(in: .global)) { oldFrame, newFrame in
                        updateDeleteButtonFrame(geo: geo, idx: idx)
                    }
                    .task(id: values.count, {
                        updateDeleteButtonFrame(geo: geo, idx: idx)
                    })
                    .opacity(values[idx].removeButtonOpacity)
                }
            }
            
            // Row: delete button - label - value
            GeometryReader { geo in
                HStack(spacing: 0) {
                    removeButtonView(idx)
                        .padding(.leading, 15)
                    
                    labelContentView(idx, rowWidth: geo.size.width)
                    
                    TextField("common.phone", text: getItemBindingValue(idx))
                        .lineLimit(1)
                        .frame(alignment: .leading)
                        .padding(.leading, 10)
                        .foregroundStyle(Color.accentColor)
                        .textStyle(.body)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.backgroundPrimary)
                }
                .offset(x: values[idx].offset, y: 0)
            }
        }
    }
    
    private func labelContentView(_ idx: Int, rowWidth: CGFloat) -> some View {
        ZStack {
            // Hidden stack : computes max label width
            ZStack(alignment: .trailing) {
                ForEach(values.indices, id: \.self) { idx2 in
                    Text(getLabelContent(idx2))
                        .lineLimit(1)
                        .foregroundStyle(Color.accentColor)
                        .textStyle(.caption)
                        .padding(.leading, 10)
                        .background(.clear)
                }
            }
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            labelMaxWidth = geo.size.width
                        }
                }
            }
            .hidden()
            
            HStack(alignment: .center, spacing: 0) {
                Text(getLabelContent(idx))
                    .lineLimit(1)
                    .foregroundStyle(Color.accentColor)
                    .textStyle(.caption)
                    .padding(.leading, rowLabelLeadPaddingW)
                    .background(.clear)
                    .frame(alignment: .trailing)
                    .frame(width: getLabelContentWidths(rowWidth: rowWidth).label,
                           alignment: .trailing)
                ZStack {
                    Rectangle()
                        .fill(.clear)
                        .frame(width: rowChevronW)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.textTertiary)
                        .font(.caption)
                        .background(.clear)
                }
                Rectangle()
                    .frame(width: rowSeparatorW)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.shade2, .backgroundTertiary]), startPoint: .top, endPoint: .bottom))
                    .background(.clear)
            }
            .frame(width: getLabelContentWidths(rowWidth: rowWidth).content)
        }
    }
    
    // MARK: - private methods
    func getLabelContentWidths(rowWidth: CGFloat) -> (content: CGFloat, label: CGFloat) {
        // A row is made of :
        // <delete button> - <label content> - <value>
        // Compute the <label content> width :
        //   use the maximum label width + other <label content>'s elements width
        //   ensure <value> has enough space remaining > max = 50% * ( <row width> - <delete button.width> )
        
        let labelContentMaxWidth = (rowWidth - rowDeleteButtonW) * 0.5
        let labelContentProposedWidth = rowLabelLeadPaddingW + labelMaxWidth + rowChevronW + rowSeparatorW
        guard labelContentProposedWidth < labelContentMaxWidth else {
            return (labelContentMaxWidth,
                    labelMaxWidth - labelContentProposedWidth + labelContentMaxWidth)
        }
        return (labelContentProposedWidth, labelMaxWidth)
    }
    
    private func addItem() {
        values.append(LabeledValueRowUI(kind: kind,
                                        height: 0,
                                        opacity: 0,
                                        clip: true,
                                        separatorOpacity: 0,
                                        removeButtonOpacity: 0))
        
        withAnimation(.easeOut(duration: 0.5)) {
            values[values.count - 1].height = LabeledValueRowUI.rowHeight
            values[values.count - 1].opacity = 1
        } completion: {
            values[values.count - 1].clip = false
            values[values.count - 1].removeButtonOpacity = 1
        }
        withAnimation(.easeInOut(duration: 0.2).delay(0.4)) {
            values[values.count - 1].separatorOpacity = 1
        }
    }
    
    private func getItemBindingValue(_ idx: Int) -> Binding<String> {
        return $values[idx].entityLabeledValue.value
        
        // ICI TODO FIXME : this is not a correct binding ??
    }
    
    private func getLabelContent(_ idx: Int) -> LocalizedStringKey {
        LocalizedStringKey(values[idx].entityLabeledValue.labelKey)
    }
    
    private func getAddViewContent() -> String.LocalizationValue {
        switch kind {
            case .phone:
                "common.add_phone"
            case .url:
                "common.add_url"
            case .email:
                "common.add_email"
        }
    }
    
    private func removeRow(_ idx: Int) {
        isRemovingRow = true
        values[idx].clip = true
        values[values.count - 1].removeButtonOpacity = 0
        withAnimation(.easeInOut(duration: 0.2)) {
            values[idx].separatorOpacity = 0
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            values[idx].offset = -500
            values[idx].height = 0
            values[idx].opacity = 0
        } completion: {
            removeItem(idx)
            isRemovingRow = false
        }
    }
    
    private func removeItem(_ idx: Int) {
        print("  - remove value at \(idx)")
        values.remove(at: idx)
    }
    
    private func showRemoveButton(_ idx: Int) {
        values[idx].removeButtonOpacity = 1
        withAnimation {
            values[idx].offset = -1 * swipeDeleteButtonW
        }
        // Enable NoFlyZone with current row delete button frame
        noFlyZoneCompletionStatus = .undefined
        noFlyAuthorizedZones = [NoFlyZoneData(viewId: viewIdentifier,
                                              itemId: idx,
                                              zone: values[idx].deleteFrame)]
        noFlyZoneEnabled = true
    }
    
    private func resetOffsets() {
        guard values.contains(where: {$0.offset != 0}) else {
            print("WARNING: no zero offsets found ?? weird thing")
            for idx in 0..<values.count {
                print(" reset anyway \(idx) : \(values[idx].entityLabeledValue.labelKey) \(values[idx].entityLabeledValue.value)")
                // Do not reset offset for a row to be deleted
                if values[idx].toBeDeleted /*|| values[idx].deleting*/ {
                    print("  SKIP Reset offset at line \(idx) ")
                    continue
                }
                print("  Reset offset at line \(idx) ")
                values[idx].offset = 0
            }
            return
        }
        withAnimation {
            for idx in 0..<values.count {
                // Do not reset offset for a row to be deleted
                if values[idx].toBeDeleted /*|| values[idx].deleting*/ {
                    continue
                }
                values[idx].offset = 0
            }
        }
    }
    
    private func updateDeleteButtonFrame(geo: GeometryProxy, idx: Int) {
        // Store delete buttons frame, update each time the array size change
        let rowFrame = geo.frame(in: .global)
        let posX = rowFrame.origin.x + rowFrame.size.width - swipeDeleteButtonW
        let buttonFrame = CGRect(x: posX,
                                 y: rowFrame.origin.y,
                                 width: rowFrame.size.width - posX,
                                 height: rowHeight)
        values[idx].deleteFrame = buttonFrame
    }
}

 
#if DEBUG

struct MockLabeledValueEditView: View {
    
    @State private var phones: [LabeledValueRowUI]
    @State private var emails: [LabeledValueRowUI]
    @State private var urls: [LabeledValueRowUI]
    
    @State private var noFlyZoneEnabled: Bool = false
    @State private var noFlyAuthorizedZones: [NoFlyZoneData] = []
    @State private var noFlyZoneCompletionStatus: NoFlyZoneCompletionStatus = .undefined
    
    var body: some View {
        ZStack {
            Color(.backgroundSecondary)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                
                LabeledValueEditViewNoFly(viewIdentifier: 1,
                                          kind: .phone,
                                          values: $phones,
                                          noFlyZoneEnabled: $noFlyZoneEnabled,
                                          noFlyZoneCompletionStatus: $noFlyZoneCompletionStatus,
                                          noFlyAuthorizedZones: $noFlyAuthorizedZones)
                .padding(.bottom, 20)
                .padding(.top, 40)
                LabeledValueEditViewNoFly(viewIdentifier: 2,
                                          kind: .email,
                                          values: $emails,
                                          noFlyZoneEnabled: $noFlyZoneEnabled,
                                          noFlyZoneCompletionStatus: $noFlyZoneCompletionStatus,
                                          noFlyAuthorizedZones: $noFlyAuthorizedZones)
                .padding(.bottom, 20)
                LabeledValueEditViewNoFly(viewIdentifier: 3,
                                          kind: .url,
                                          values: $urls,
                                          noFlyZoneEnabled: $noFlyZoneEnabled,
                                          noFlyZoneCompletionStatus: $noFlyZoneCompletionStatus,
                                          noFlyAuthorizedZones: $noFlyAuthorizedZones)
                .padding(.bottom, 20)
                Spacer()
            }
        }
        .noFlyZone(enabled: noFlyZoneEnabled,
                   authorizedZones: noFlyAuthorizedZones,
                   onAllowed: noFlyZoneOnAllowed,
                   onBlocked: noFlyZoneOnBlocked,
                   coloredDebugOverlay: true)
    }
    
    init() {
        self.phones = [EntityLabeledValue(phone: "+12125557483", label: .home),
                       EntityLabeledValue(phone: "+16465552917", label: .mobile),
                       EntityLabeledValue(phone: "+13125556042", label: .custom("work")),
                       EntityLabeledValue(phone: "+14155558831", label: .custom("club"))]
            .map { LabeledValueRowUI(entityLabeledValue: $0) }
        self.emails = [EntityLabeledValue(email: "john.doe@home.com", label: .email)]
            .map { LabeledValueRowUI(entityLabeledValue: $0) }
        self.urls = [EntityLabeledValue(url: "john.doe.home.com", label: .url)]
            .map { LabeledValueRowUI(entityLabeledValue: $0) }
    }
    
    private func noFlyZoneOnBlocked() {
        noFlyZoneEnabled = false
        noFlyZoneCompletionStatus = .blocked
    }
    
    private func noFlyZoneOnAllowed(tappedZones: [NoFlyZoneData]) {
        noFlyZoneEnabled = false
        noFlyZoneCompletionStatus = .allowed
        
        for z in tappedZones {
            if z.viewId == 1 {
                phones[z.itemId].toBeDeleted = true
            }
            else if z.viewId == 2 {
                emails[z.itemId].toBeDeleted = true
            }
            else if z.viewId == 3 {
                urls[z.itemId].toBeDeleted = true
            }
        }
    }
}

#Preview {
    MockLabeledValueEditView()
}

#endif

#endif

