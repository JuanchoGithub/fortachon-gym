import SwiftUI

// MARK: - Skeleton Loading View

struct SkeletonLoadingView: View {
    let style: SkeletonStyle
    @State private var isAnimating = false
    
    enum SkeletonStyle {
        case text(width: CGFloat = .infinity, height: CGFloat = 16)
        case circle(size: CGFloat = 40)
        case rectangle(width: CGFloat = .infinity, height: CGFloat = 100, cornerRadius: CGFloat = 12)
        case listRow(height: CGFloat = 60)
        case card
        
        var dimensions: (width: CGFloat, height: CGFloat, cornerRadius: CGFloat) {
            switch self {
            case .text(let w, let h): return (w, h, 4)
            case .circle(let size): return (size, size, size / 2)
            case .rectangle(let w, let h, let r): return (w, h, r)
            case .listRow(let h): return (.infinity, h, 12)
            case .card: return (.infinity, 120, 16)
            }
        }
    }
    
    var body: some View {
        let dims = style.dimensions
        RoundedRectangle(cornerRadius: dims.cornerRadius)
            .fill(
                LinearGradient(
                    colors: [.gray.opacity(0.3), .gray.opacity(0.1), .gray.opacity(0.3)],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(width: dims.width == .infinity ? nil : dims.width,
                   height: dims.height)
            .frame(maxWidth: dims.width == .infinity ? .infinity : nil)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton Container

struct SkeletonContainer<Content: View>: View {
    let isLoading: Bool
    @ViewBuilder let content: () -> Content
    @ViewBuilder let skeleton: () -> Content
    
    var body: some View {
        if isLoading {
            skeleton()
                .redacted(reason: .placeholder)
                .allowsHitTesting(false)
        } else {
            content()
        }
    }
}

// MARK: - Workout List Skeleton

struct WorkoutListSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: 12) {
                    SkeletonLoadingView(style: .circle(size: 50))
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonLoadingView(style: .text(width: 150, height: 18))
                        SkeletonLoadingView(style: .text(width: 100, height: 14))
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Exercise List Skeleton

struct ExerciseListSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<8, id: \.self) { _ in
                HStack(spacing: 12) {
                    SkeletonLoadingView(style: .circle(size: 40))
                    VStack(alignment: .leading, spacing: 6) {
                        SkeletonLoadingView(style: .text(width: 120, height: 16))
                        SkeletonLoadingView(style: .text(width: 80, height: 12))
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Stats Card Skeleton

struct StatsCardSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: 8) {
                    SkeletonLoadingView(style: .circle(size: 30))
                    SkeletonLoadingView(style: .text(width: 40, height: 20))
                    SkeletonLoadingView(style: .text(width: 50, height: 12))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Stats Skeleton")
                .font(.headline)
            StatsCardSkeleton()
            
            Text("Workout List Skeleton")
                .font(.headline)
            WorkoutListSkeleton()
            
            Text("Exercise List Skeleton")
                .font(.headline)
            ExerciseListSkeleton()
        }
    }
}