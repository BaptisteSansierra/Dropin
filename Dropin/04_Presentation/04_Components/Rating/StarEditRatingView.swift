//
//  StarEditRatingView.swift
//  Dropin
//
//  Created by baptiste sansierra on 5/3/26.
//

import SwiftUI

struct StarEditRatingView: View {

    @Binding var rating: Float
    let maxRating: Int = 5
    let spacing: CGFloat = 7

    init(rating: Binding<Float>) {
        self._rating = rating
    }
    
    var body: some View {
        ZStack(alignment: .leading) {

            // Background (empty stars)
            HStack(spacing: spacing) {
                ForEach(0..<maxRating, id: \.self) { idx in
                    Image(systemName: "star.fill")
                        .foregroundStyle(.gray.opacity(0.3))
                        .onTapGesture {
                            rating = Float(idx + 1)
                        }
                }
            }
            
            // Foreground (filled stars)
            HStack(spacing: spacing) {
                ForEach(0..<Int(rating), id: \.self) { idx in
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .onTapGesture {
                            rating = Float(idx + 1)
                        }
                }
            }
        }
        .font(.body)
    }
}

#Preview {
    @Previewable @State var rating: Float = 1
    
    VStack {
        StarEditRatingView(rating: $rating)
            .padding(.bottom, 50)
        StarRatingView(rating: rating)
    }
}
