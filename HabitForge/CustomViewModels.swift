//
//  CustomViewModels.swift
//  HabitForge
//
//  Created by yunus emre yıldırım on 24.09.2025.
//

import SwiftUI

struct CustomProgressBar: View {
    var progress: Double     // 0.0 – 1.0 arasında
    var barColor: Color = .green
    var height: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Arka plan
                RoundedRectangle(cornerRadius: height/2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: height)

                // Dolu kısım
                RoundedRectangle(cornerRadius: height/2)
                    .fill(barColor)
                    .frame(width: geo.size.width * progress, height: height)
            }
        }
        .frame(height: height)
    }
}

struct CircularProgressBar: View {
    @ObservedObject var habitModel: HabitForgeViewModel
    var index: Int
    var progress: Double // 0.0 ile 1.0 arası
    
    var body: some View {
        ZStack {
            if habitModel.habits[index].remaininToday <= 0 {
                // tamamlanmış
                Circle()
                    .stroke(lineWidth: 4)
                    .foregroundColor(.green)
                
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
                    .font(.system(size: 14, weight: .bold))
            } else {
                // normal
                Circle()
                    .stroke(lineWidth: 4)
                    .opacity(0.2)
                    .foregroundColor(.green)
                    .overlay(Text(habitModel.habits[index].remaininToday.description))
                
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .foregroundColor(.green)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
            }
        }
        .frame(width: 37, height: 37)
    }
}
