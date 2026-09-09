//
//  ImportStatusView.swift
//  Dropin
//
//  Created by baptiste sansierra on 8/9/26.
//

import Foundation
import SwiftUI

struct ImportStatusView: View {
    
    // MARK: - State & Bindings
    @Binding private var importStatus: ImportStatus?

    // MARK: - private properties
    private var cancelCb: (() -> Void)
    private var closeCb: (() -> Void)

    // MARK: - init
    init(importStatus: Binding<ImportStatus?>,
         cancelCb: @escaping () -> Void,
         closeCb: @escaping () -> Void) {
        self._importStatus = importStatus
        self.cancelCb = cancelCb
        self.closeCb = closeCb
    }
    
    // MARK: - Body
    var body: some View {
        if let importStatus = importStatus {
            ZStack {
                Color(.overlayAlphaLayer)
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    Group {
                        switch importStatus.status {
                            case .importing:
                                importingView(importStatus)
                            case .complete:
                                resultView(importStatus)
                            case .error(let error):
                                errorView(importStatus, error)
                        }
                    }
                    .padding(.vertical, 20)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(uiColor: UIColor.systemBackground))
                            .ignoresSafeArea(edges: .bottom)
                    }
                }
            }
        } else {
            Color(.clear)
        }
    }
    
    // MARK: - subviews
    private func errorView(_ importStatus: ImportStatus, _ error: ImportError) -> some View {
        VStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(.destructive.opacity(0.1))
                    .frame(width: 45, height: 45)
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.destructive)
            }
            
            switch error {
                case .canceled:
                    Text(verbatim: error.localizedDescription)
                        .textStyle(.bodySemibold)
                default:
                    Text("import.error.title")
                        .textStyle(.bodySemibold)
                    Text(verbatim: error.localizedDescription)
                        .textStyle(.caption, color: .textSecondary)
            }
            
            DropinButton(text: "common.close",
                         background: .clear,
                         foreground: .textPrimary,
                         action: close)
                .padding(.top, 10)
        }
        .padding(.horizontal, 20)
    }

    private var resultDetailsSpacerView: some View {
        Rectangle()
            .fill(.fieldBorder)
            .frame(height: 1)
            .padding(.horizontal, -20)
            .padding(.leading, 10)
    }

    private func resultDetailsView(_ importStatus: ImportStatus) -> some View {
        VStack {
            HStack {
                Text("import.complete.count")
                    .textStyle(.subheadline, color: .textSecondary)
                Spacer()
                Text("\(importStatus.count)")
                    .textStyle(.subheadlineSemibold)
            }
            
            resultDetailsSpacerView
            
            HStack {
                Text("import.complete.duplicatesCount")
                    .textStyle(.subheadline, color: .textSecondary)
                Spacer()
                Text("\(importStatus.duplicateCount)")
                    .textStyle(.subheadline, color: .textSecondary)
            }

            resultDetailsSpacerView

            HStack {
                Text("import.complete.count.group")
                    .textStyle(.subheadline, color: .textSecondary)
                Spacer()
                Text("\(importStatus.groupCount)")
                    .textStyle(.subheadline, color: .textSecondary)
            }

            resultDetailsSpacerView
            
            HStack {
                Text("import.complete.count.tag")
                    .textStyle(.subheadline, color: .textSecondary)
                Spacer()
                Text("\(importStatus.tagCount)")
                    .textStyle(.subheadline, color: .textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.clear)
                .stroke(.fieldBorder)
        }
        .padding(.top, 10)
    }
    
    private func resultView(_ importStatus: ImportStatus) -> some View {
        VStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(.dropinPrimary)
                    .frame(width: 45, height: 45)
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.backgroundPrimary)
            }
            Text("import.complete.title")
                .textStyle(.bodySemibold)
            
            resultDetailsView(importStatus)
            
            MainButton(text: "common.done", action: close)
                .padding(.top, 10)
        }
        .padding(.horizontal, 20)
    }
    
    private func importingView(_ importStatus: ImportStatus) -> some View {
        VStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(.dropinPrimary.opacity(0.1))
                    .frame(width: 45, height: 45)
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.dropinPrimary)
            }
            
            Text("import.title")
                .textStyle(.bodySemibold)
            Text(subtitle())
                .textStyle(.caption, color: .textSecondary)
            
            GeometryReader { geox in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.backgroundSecondary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.dropinPrimary)
                        .frame(width: progression() * geox.size.width, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.top, 5)
            
            HStack {
                Text(progressionLabel(importStatus))
                    .textStyle(.caption, color: .textSecondary)
                Spacer()
                Text("\(progressionPercent())%")
                    .textStyle(.caption, color: .textSecondary)
            }
            
            DropinButton(text: "common.cancel",
                         background: .clear,
                         foreground: .textPrimary,
                         action: cancel)
                .padding(.top, 10)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - private methods
    private func subtitle() -> LocalizedStringKey {
        guard let importStatus = importStatus else { return "" }
        switch importStatus.source {
            case .dropin:
                return "import.title.dropin_\(importStatus.filename)"
            case .mapstr:
                return "import.title.mapstr_\(importStatus.filename)"
            case .google, .unknown:
                assertionFailure("unknown importer")
                return "unknown"
        }
    }

    private func progressionLabel(_ importStatus: ImportStatus) -> LocalizedStringKey {
        if importStatus.progress > 0 {
            return "import.progression_\(importStatus.progress)_\(importStatus.count)"
        } else {
            return "import.preparing"
        }
    }
    
    private func progression() -> CGFloat {
        guard let importStatus = importStatus else { return 0 }
        guard importStatus.count > 0 else { return 0 }
        return CGFloat(importStatus.progress) / CGFloat(importStatus.count)
    }

    private func progressionPercent() -> Int {
        return Int((100.0 * progression()).rounded())
    }
    
    private func cancel() {
        cancelCb()
    }

    private func close() {
        closeCb()
    }
}


#if DEBUG

import Combine

struct MOCKImportStatusView: View {

    @State private var importStatus: ImportStatus?
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()
            VStack(spacing: 40) {
                Button {
                    importStatus = ImportStatus(filename: "my_places.json",
                                                source: .mapstr)
                    importStatus?.setCount(100)
                    //importStatus?.updateProgress(15)
                } label: {
                    Text(verbatim: "Importing")
                }
                Button {
                    importStatus = ImportStatus(filename: "my_places.json",
                                                source: .mapstr)
                    importStatus?.setCount(100)
                    importStatus?.updateProgress(100)
                    importStatus?.complete()
                } label: {
                    Text(verbatim: "Complete")
                }
                Button {
                    importStatus = ImportStatus(filename: "my_places.json",
                                                source: .mapstr)
                    importStatus?.setCount(100)
                    importStatus?.setError(ImportError.unsupported("unsupported format"))
                } label: {
                    Text(verbatim: "Error")
                }
            }
            if let importStatus = importStatus {
                ImportStatusView(importStatus: $importStatus,
                                 cancelCb: cancel,
                                 closeCb: close)
                .onReceive(timer, perform: { _ in
                    guard importStatus.status == .importing else { return }
                    if importStatus.progress < importStatus.count {
                        importStatus.updateProgress(importStatus.progress + 1)
                    } else {
                        importStatus.complete()
                    }
                })
            }
        }
    }
    
    private func cancel() { importStatus = nil }
    private func close() { importStatus = nil }
}

#Preview {
    MOCKImportStatusView()
}

#endif
