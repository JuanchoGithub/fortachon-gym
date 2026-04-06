import SwiftUI
import SwiftData
import FortachonCore

// MARK: - Multi-Step Onboarding Wizard

struct OnboardingWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferencesM]
    
    @State private var currentStep = 0
    @State private var userGoal: UserGoal = .muscle
    @State private var weightUnit: WeightUnit = .kg
    @State private var gender: String = "male"
    @State private var heightCm: String = ""
    @State private var weightKg: String = ""
    @State private var experienceLevel: String = "intermediate"
    @State private var trainingDaysPerWeek: String = "3"
    @State private var notificationsEnabled: Bool = true
    
    let steps = [
        OnboardingStep(title: "Welcome", subtitle: "Let's set up your profile", icon: "hand.wave"),
        OnboardingStep(title: "Your Goal", subtitle: "What do you want to achieve?", icon: "target"),
        OnboardingStep(title: "Your Body", subtitle: "Help us calculate your ratios", icon: "person.fill"),
        OnboardingStep(title: "Training", subtitle: "How often do you train?", icon: "calendar"),
        OnboardingStep(title: "Ready", subtitle: "Let's get started!", icon: "checkmark.circle"),
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Step indicator
                StepProgressView(currentStep: currentStep, totalSteps: steps.count)
                    .padding(.horizontal)
                
                // Step content
                TabView(selection: $currentStep) {
                    WelcomeStep()
                        .tag(0)
                    
                    GoalSelectionStep(selectedGoal: $userGoal)
                        .tag(1)
                    
                    BodyStatsStep(gender: $gender, heightCm: $heightCm, weightKg: $weightKg, unit: $weightUnit)
                        .tag(2)
                    
                    TrainingStep(experienceLevel: $experienceLevel, daysPerWeek: $trainingDaysPerWeek)
                        .tag(3)
                    
                    CompletionStep()
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation { currentStep -= 1 }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == 4 ? "Finish" : "Next") {
                        if currentStep == 4 {
                            savePreferences()
                        } else {
                            withAnimation { currentStep += 1 }
                            HapticsManager.shared.play()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationBarHidden(true)
        }
    }
    
    private func savePreferences() {
        let hasCompletedOnboarding = true
        let prefs = preferences.first
        
        if let existing = prefs {
            existing.mainGoalStr = userGoal.rawValue
            existing.weightUnitStr = weightUnit.rawValue
            existing.gender = gender
            existing.heightCm = Double(heightCm)
            existing.hasCompletedOnboarding = hasCompletedOnboarding
            existing.notificationsEnabled = notificationsEnabled
        } else {
            let newPrefs = UserPreferencesM(
                weightUnit: weightUnit.rawValue,
                goal: userGoal.rawValue,
                hasCompletedOnboarding: hasCompletedOnboarding,
                gender: gender,
                heightCm: Double(heightCm) ?? 175,
                notificationsEnabled: notificationsEnabled
            )
            modelContext.insert(newPrefs)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Onboarding Step Model

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

// MARK: - Step Progress Indicator

struct StepProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentStep)
                
                if step < totalSteps - 1 {
                    Rectangle()
                        .fill(step < currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .animation(.easeInOut, value: currentStep)
                }
            }
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
            
            Text("Welcome to Fortachon")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your personal strength training companion. Let's set up your profile to give you the best experience.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Goal Selection Step

struct GoalSelectionStep: View {
    @Binding var selectedGoal: UserGoal
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            
            Text("What's your main goal?")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(UserGoal.allCases, id: \.self) { goal in
                    GoalButton(goal: goal, isSelected: selectedGoal == goal) {
                        selectedGoal = goal
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct GoalButton: View {
    let goal: UserGoal
    let isSelected: Bool
    let action: () -> Void
    
    var icon: String {
        switch goal {
        case .strength: return "bolt.fill"
        case .muscle: return "brain.head.profile"
        case .endurance: return "figure.run"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(goal.title)
                    .font(.headline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Body Stats Step

struct BodyStatsStep: View {
    @Binding var gender: String
    @Binding var heightCm: String
    @Binding var weightKg: String
    @Binding var unit: WeightUnit
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("Tell us about yourself")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Picker("Gender", selection: $gender) {
                    Text("Male").tag("male")
                    Text("Female").tag("female")
                }
                .pickerStyle(.segmented)
                
                HStack {
                    Image(systemName: "ruler.vertical")
                    TextField("Height (cm)", text: $heightCm)
                        .keyboardType(.numberPad)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                HStack {
                    Image(systemName: "scalemass.fill")
                    TextField("Weight (\(unit.rawValue))", text: $weightKg)
                        .keyboardType(.numberPad)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Picker("Unit", selection: $unit) {
                    Text("kg").tag(WeightUnit.kg)
                    Text("lbs").tag(WeightUnit.lbs)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Training Step

struct TrainingStep: View {
    @Binding var experienceLevel: String
    @Binding var daysPerWeek: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            
            Text("Your training habits")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Text("Experience Level")
                    .font(.headline)
                
                Picker("Level", selection: $experienceLevel) {
                    Text("Beginner").tag("beginner")
                    Text("Intermediate").tag("intermediate")
                    Text("Advanced").tag("advanced")
                }
                .pickerStyle(.segmented)
                
                Divider()
                
                HStack {
                    Image(systemName: "clock.fill")
                    Text("Days per week")
                    Spacer()
                    Text("\(daysPerWeek)")
                        .font(.title3.bold())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Slider(value: Binding(
                    get: { Double(daysPerWeek) ?? 3 },
                    set: { daysPerWeek = String(Int($0)) }
                ), in: 1...7, step: 1)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Completion Step

struct CompletionStep: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            
            Text("You're all set!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Start your strength training journey with personalized workouts and tracking.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Haptics Manager

class HapticsManager {
    static let shared = HapticsManager()
    
    func play() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Preview

#Preview {
    OnboardingWizardView()
}