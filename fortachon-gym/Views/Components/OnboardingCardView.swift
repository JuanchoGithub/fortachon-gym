import SwiftUI

struct OnboardingCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.white)
            Text("Welcome to Fortachon")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Set up your profile to get personalized workout recommendations.")
                .foregroundStyle(.white.opacity(0.85))
            Button {
                // Navigate to onboarding/settings
            } label: {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.blue)
                    .fontWeight(.semibold)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.blue, .indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .shadow(radius: 2)
    }
}