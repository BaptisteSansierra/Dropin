//
//  TestView.swift
//  Dropin
//
//  Created by baptiste sansierra on 8/3/26.
//

import SwiftUI

struct TestView: View {
    
    var indices: [Int] = [1,  2,  3,  4,  5,
                          6,  7,  8,  9,  10,
                          11, 12, 13, 14, 15,
                          16, 17, 18, 19, 20]
    
    var body: some View {
        NavigationStack {
            
            ZStack {
                
                VStack {
                    ScrollView {
                        ForEach(indices, id: \.self) { idx in
                            
                            ZStack {
                                Rectangle()
                                    .fill(.red.opacity(0.3))
                                    .frame(height: 50)
                                Text("Cell \(idx)")
                            }
                        }
                    }
                }
                
                
                Rectangle()
                    .fill(.green)
                    .offset(x: 0, y: 2)
                    .ignoresSafeArea()
                    .opacity(0.25)
                
            }
            .navigationTitle("MyTitle")
        }
    }
}

#Preview {
    TestView()
}
