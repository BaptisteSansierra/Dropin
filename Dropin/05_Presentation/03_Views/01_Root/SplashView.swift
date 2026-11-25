//
//  SplashView.swift
//  Dropin
//

// Shown at app launch while `restoreSession()` is in flight. Brand-forward
// Screen matches LaunchScreen.xib

import SwiftUI

struct SplashView: View {

    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                
                Image("Dropin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.top, 100)
                    .padding(.bottom, 50)
                
                ProgressView()
                    .controlSize(.regular)
                    .tint(.dropinPrimary)
                    .opacity(pulse ? 1.0 : 0)
                    .animation(.easeInOut, value: pulse)
                

//                DropinLogo(variant: .logo)
//                    .frame(width: 100, height: 100)
//                    .scaleEffect(pulse ? 1.0 : 0.95)
//                    .opacity(pulse ? 1.0 : 0.85)
//                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
//                               value: pulse)
//                    .padding(.top, 100)

//                Text(verbatim: DropinApp.strings.app)
//                    .textStyle(.formSectionTitle)
//                    .foregroundStyle(.dropinPrimary)
                Spacer()
            }
        }
        .onAppear { pulse = true }
    }
}

#if DEBUG
#Preview {
    SplashView()
}
#endif
