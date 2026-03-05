//
//  StarRatingView.swift
//  Dropin
//
//  Created by baptiste sansierra on 26/2/26.
//

import SwiftUI

struct StarRatingView: View {

    private let rating: Float?
    private let maxRating: Int = 5
    //private let starImage: String = "star.circle"
    private let starImage: String = "star.fill"

    init(rating: Float) {
        self.rating = rating
    }

    init() {
        self.rating = nil
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if let rating = rating {
                ratingView(rating)
            } else {
                placeholderView
            }
        }
        .font(.caption2)
    }
    
    @ViewBuilder
    private func ratingView(_ rating: Float) -> some View {
        // Background (empty stars)
        HStack(spacing: 0) {
            ForEach(0..<maxRating, id: \.self) { _ in
                Image(systemName: starImage)
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
        // Foreground (filled stars)
        HStack(spacing: 0) {
            ForEach(0..<maxRating, id: \.self) { _ in
                Image(systemName: starImage)
                    .foregroundStyle(.yellow)
            }
        }
        .mask(
            GeometryReader { geo in
                Rectangle()
                    .frame(width: geo.size.width * (CGFloat(rating) / CGFloat(maxRating)))
                    })
    }
    
    private var placeholderView: some View {
        HStack(spacing: 0) {
            ForEach(0..<maxRating, id: \.self) { _ in
                Image(systemName: "star.slash")
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
    }
}


#Preview {
    @Previewable @State var rating: Float = 1
    
    VStack {
        StarEditRatingView(rating: $rating)
            .padding(.bottom, 50)
        StarRatingView(rating: rating)
            .padding(.bottom, 50)
        StarRatingView()
    }
}
