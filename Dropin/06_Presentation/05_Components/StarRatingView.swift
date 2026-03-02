//
//  StarRatingView.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/2/26.
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

struct StarRatingView: View {
    let rating: Float   // e.g. 4.5
    let maxRating: Int = 5
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            // Background (empty stars)
            HStack(spacing: 0) {
                ForEach(0..<maxRating, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundStyle(.gray.opacity(0.3))
                }
            }
            
            // Foreground (filled stars)
            HStack(spacing: 0) {
                ForEach(0..<maxRating, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }
            .mask(
                GeometryReader { geo in
                    Rectangle()
                        .frame(
                            width: geo.size.width * (CGFloat(rating) / CGFloat(maxRating))
                        )
                }
            )
        }
        .font(.caption2)
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
