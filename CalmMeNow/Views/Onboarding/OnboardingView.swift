import SwiftUI
import UserNotifications

// MARK: - UserPrimaryGoal

enum UserPrimaryGoal: String, CaseIterable {
    case panicAttacks = "panic_attacks"
    case generalAnxiety = "general_anxiety"
    case dailyStress = "daily_stress"
    case sleep = "sleep"

    var displayText: String {
        switch self {
        case .panicAttacks: return "I get panic attacks — and they terrify me"
        case .generalAnxiety: return "I live with anxiety every day"
        case .dailyStress: return "I want to manage stress before it builds"
        case .sleep: return "Anxiety is ruining my sleep"
        }
    }

    var emoji: String {
        switch self {
        case .panicAttacks: return "🚨"
        case .generalAnxiety: return "😰"
        case .dailyStress: return "😮‍💨"
        case .sleep: return "😴"
        }
    }

    var personalizedSubtitle: String {
        switch self {
        case .panicAttacks: return "Your emergency calm is always ready."
        case .generalAnxiety: return "Steady yourself, one breath at a time."
        case .dailyStress: return "Even small moments of calm add up."
        case .sleep: return "Rest is within reach."
        }
    }

    var processingLabel: String {
        switch self {
        case .panicAttacks: return "Goal noted — panic attack relief"
        case .generalAnxiety: return "Goal noted — anxiety management"
        case .dailyStress: return "Goal noted — stress relief"
        case .sleep: return "Goal noted — sleep support"
        }
    }
}

// MARK: - UserPainPoint

enum UserPainPoint: String, CaseIterable {
    case noPlan = "no_plan"
    case ashamed = "ashamed"
    case anticipation = "anticipation"
    case sleep = "sleep_pain"
    case avoidance = "avoidance"
    case nothingSticks = "nothing_sticks"

    var displayText: String {
        switch self {
        case .noPlan: return "When it hits, I have no idea what to do with my body"
        case .ashamed: return "I feel embarrassed or ashamed after an episode"
        case .anticipation: return "I worry about when the next one will happen"
        case .sleep: return "I can't sleep — my mind won't switch off"
        case .avoidance: return "I avoid places or situations just in case"
        case .nothingSticks: return "I've tried things before. Nothing sticks."
        }
    }

    var emoji: String {
        switch self {
        case .noPlan: return "💥"
        case .ashamed: return "😶"
        case .anticipation: return "🔄"
        case .sleep: return "💤"
        case .avoidance: return "🏃"
        case .nothingSticks: return "😤"
        }
    }
}

// MARK: - UserTrigger (kept for backwards compatibility)

enum UserTrigger: String, CaseIterable {
    case workSchool = "work_school"
    case socialSituations = "social_situations"
    case healthWorries = "health_worries"
    case sleepDifficulties = "sleep_difficulties"
    case generalOverwhelm = "general_overwhelm"
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var done = false
    @AppStorage("prefSounds") var prefSounds = true
    @AppStorage("prefHaptics") var prefHaptics = true
    @AppStorage("prefVoice") var prefVoice = false
    @AppStorage("userPrimaryGoal") var userPrimaryGoal: String = ""
    @AppStorage("userPainPoints") var userPainPoints: String = ""

    @State private var step = 0
    @State private var selectedGoal: UserPrimaryGoal?
    @State private var selectedPainPoints: Set<UserPainPoint> = []
    @State private var notifGranted = false
    @State private var notifRequested = false
    @State private var showPaywall = false

    @StateObject private var healthKit = HealthKitManager.shared

    private let totalSteps = 14

    // MARK: - Body

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                if step < totalSteps - 1 {
                    progressBar
                        .padding(.horizontal, 24)
                        .padding(.top, 56)
                        .padding(.bottom, 4)
                }
                screenContent
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
        .fullScreenCover(isPresented: $showPaywall, onDismiss: { done = true }) {
            PaywallView()
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        if step == 8 {
            Color(hex: "#0E2D6C").ignoresSafeArea()
        } else {
            LinearGradient(
                colors: [Color(hex: "#C9B8E8"), Color(hex: "#E8D5F5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.35))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#FF6B9D"))
                    .frame(width: geo.size.width * CGFloat(step) / CGFloat(totalSteps - 2), height: 4)
                    .animation(.easeInOut(duration: 0.4), value: step)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Screen Router

    @ViewBuilder
    private var screenContent: some View {
        Group {
            switch step {
            case 0:  welcomeScreen
            case 1:  goalScreen
            case 2:  painPointsScreen
            case 3:  socialProofScreen
            case 4:  OnboardingTinderView(onComplete: advance)
            case 5:  solutionScreen
            case 6:  preferencesScreen
            case 7:  OnboardingProcessingView(goal: selectedGoal, onComplete: advance)
            case 8:  OnboardingDemoView(onComplete: advance)
            case 9:  valueDeliveryScreen
            case 10: notificationsScreen
            case 11: siriScreen
            case 12: healthScreen
            case 13: paywallScreen
            default: EmptyView()
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .id(step)
    }

    // MARK: - Advance

    func advance() {
        withAnimation(.easeInOut(duration: 0.35)) {
            step += 1
        }
    }

    // MARK: - Screen 1: Welcome

    private var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(hex: "#0E2D6C"))
                    .frame(height: 260)
                CatMascot()
                    .frame(width: 180, height: 180)
            }
            .padding(.horizontal, 32)

            Spacer().frame(height: 36)

            VStack(spacing: 10) {
                Text("Calm in under 60 seconds")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)

                Text("— even mid-panic")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black.opacity(0.65))
                    .multilineTextAlignment(.center)

                Text("Your body already knows how to reset.\nCalm SOS shows it the way.")
                    .font(.body)
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 28)

            Spacer()

            onboardingButton(label: "Get Started", action: advance)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }

    // MARK: - Screen 2: Goal

    private var goalScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                screenHeader(
                    title: "What brings you here?",
                    subtitle: "We'll build your plan around this."
                )

                VStack(spacing: 12) {
                    ForEach(UserPrimaryGoal.allCases, id: \.self) { goal in
                        SelectionRow(
                            emoji: goal.emoji,
                            label: goal.displayText,
                            isSelected: selectedGoal == goal,
                            multiSelect: false
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedGoal = goal }
                        }
                    }
                }

                onboardingButton(
                    label: selectedGoal == nil ? "Select one to continue" : "Continue"
                ) {
                    if let goal = selectedGoal {
                        userPrimaryGoal = goal.rawValue
                        advance()
                    }
                }
                .disabled(selectedGoal == nil)
                .opacity(selectedGoal == nil ? 0.5 : 1)
                .padding(.top, 4)
                .padding(.bottom, 52)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }

    // MARK: - Screen 3: Pain Points

    private var painPointsScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                screenHeader(
                    title: "Which of these feel familiar?",
                    subtitle: "Pick everything that resonates."
                )

                VStack(spacing: 12) {
                    ForEach(UserPainPoint.allCases, id: \.self) { point in
                        SelectionRow(
                            emoji: point.emoji,
                            label: point.displayText,
                            isSelected: selectedPainPoints.contains(point),
                            multiSelect: true
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedPainPoints.contains(point) {
                                    selectedPainPoints.remove(point)
                                } else {
                                    selectedPainPoints.insert(point)
                                }
                            }
                        }
                    }
                }

                onboardingButton(label: "Continue") {
                    userPainPoints = selectedPainPoints.map { $0.rawValue }.joined(separator: ",")
                    advance()
                }
                .padding(.top, 4)
                .padding(.bottom, 52)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }

    // MARK: - Screen 4: Social Proof

    private var socialProofScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                screenHeader(
                    title: "You're not alone in this",
                    subtitle: "Thousands of people use Calm SOS to get through the moments that used to floor them."
                )

                VStack(spacing: 14) {
                    testimonialCard(
                        quote: "I had my phone out mid-attack and it actually worked. First time anything ever has.",
                        name: "Sarah M.",
                        tag: "Panic attack sufferer"
                    )
                    testimonialCard(
                        quote: "I've had anxiety for 10 years. This is the first app that feels made for the real thing, not just general wellness.",
                        name: "James T.",
                        tag: "Daily anxiety"
                    )
                    testimonialCard(
                        quote: "I use the Night Protocol every night now. Haven't had a 3am spiral in weeks.",
                        name: "Priya K.",
                        tag: "Sleep anxiety"
                    )
                }

                onboardingButton(label: "Continue", action: advance)
                    .padding(.top, 4)
                    .padding(.bottom, 52)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }

    // MARK: - Screen 6: Personalised Solution

    private var solutionScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                screenHeader(
                    title: "Here's exactly how Calm SOS helps",
                    subtitle: "Built for what you just described."
                )

                VStack(spacing: 14) {
                    solutionRow(
                        pain: "Nothing to do when it hits",
                        solution: "Emergency Calm stops a spiral in 60 seconds — one tap, any time",
                        icon: "bolt.heart.fill",
                        color: Color(hex: "#FF6B9D")
                    )
                    solutionRow(
                        pain: "I don't understand why it keeps happening",
                        solution: "Trigger Tracker spots your patterns so you can get ahead of them",
                        icon: "waveform.path.ecg",
                        color: .blue
                    )
                    solutionRow(
                        pain: "I've tried apps before — they don't stick",
                        solution: "A daily plan that adapts to your goal, not a generic programme",
                        icon: "calendar.badge.checkmark",
                        color: .green
                    )
                    solutionRow(
                        pain: "Can't sleep when anxiety spikes at night",
                        solution: "Night Protocol guides you back to calm, even at 3am",
                        icon: "moon.stars.fill",
                        color: .indigo
                    )
                }

                onboardingButton(label: "This sounds right → Continue", action: advance)
                    .padding(.top, 4)
                    .padding(.bottom, 52)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }

    // MARK: - Screen 7: Preferences

    private var preferencesScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            screenHeader(
                title: "Make it yours",
                subtitle: "You can change these any time in settings."
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 20)

            VStack(spacing: 12) {
                preferenceToggle(emoji: "🔊", title: "Soothing soundscapes", subtitle: "Calming audio during exercises", isOn: $prefSounds)
                preferenceToggle(emoji: "📳", title: "Gentle haptic cues", subtitle: "Subtle vibrations to guide your breathing", isOn: $prefHaptics)
                preferenceToggle(emoji: "🎙️", title: "Soft voice coaching", subtitle: "Spoken guidance through each exercise", isOn: $prefVoice)
            }
            .padding(.horizontal, 24)

            Spacer()

            onboardingButton(label: "Continue", action: advance)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }

    // MARK: - Screen 10: Value Delivery

    private var valueDeliveryScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("You just did it.")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text("That's the same technique used in the Emergency Calm button — available any time, in one tap.")
                        .font(.body)
                        .foregroundColor(.black.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 12) {
                    toolkitCard(emoji: "🆘", title: "Emergency Calm", subtitle: "For when panic hits")
                    toolkitCard(emoji: "🌊", title: "Trigger Tracker", subtitle: "Spot what sets you off")
                    toolkitCard(emoji: "🌙", title: "Night Protocol", subtitle: "For 3am spirals")
                }

                Text("These are yours for free. Unlock the full plan below.")
                    .font(.footnote)
                    .foregroundColor(.black.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer()

            onboardingButton(label: "See my full plan →", action: advance)
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }

    // MARK: - Screen 11: Notifications

    private var notificationsScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 52))
                    .foregroundColor(Color(hex: "#FF6B9D"))

                VStack(spacing: 10) {
                    Text("Never face a panic attack unprepared")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text("A gentle daily check-in keeps your calm toolkit sharp — so it's second nature when you actually need it.")
                        .font(.body)
                        .foregroundColor(.black.opacity(0.65))
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    permissionBullet(emoji: "🔔", text: "Daily breathing reminders (you pick the time)")
                    permissionBullet(emoji: "📈", text: "Streak nudges to keep momentum")
                    permissionBullet(emoji: "💬", text: "Check-ins when stress tends to spike")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.85)))
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 14) {
                onboardingButton(
                    label: notifGranted ? "Reminders enabled ✓" : "Enable reminders →"
                ) {
                    if notifGranted {
                        advance()
                    } else {
                        requestNotifications()
                    }
                }

                Button("Not now") { advance() }
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.45))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
        .onAppear {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    notifGranted = settings.authorizationStatus == .authorized
                }
            }
        }
    }

    private func requestNotifications() {
        notifRequested = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                notifGranted = granted
                advance()
            }
        }
    }

    // MARK: - Screen 12: Siri Shortcuts

    private var siriScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Image(systemName: "waveform")
                    .font(.system(size: 52))
                    .foregroundColor(Color(hex: "#5E5CE6"))

                VStack(spacing: 10) {
                    Text("Call for calm — hands free")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text("When panic hits, unlocking your phone can feel impossible. Say any of these to Siri — even from your lock screen.")
                        .font(.body)
                        .foregroundColor(.black.opacity(0.65))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    siriPhrase("\"Hey Siri, open Calm SOS\"")
                    siriPhrase("\"Hey Siri, start Calm SOS\"")
                    siriPhrase("\"Hey Siri, I'm having a panic attack with Calm SOS\"")
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            onboardingButton(label: "Got it →") { advance() }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
        }
    }

    private func siriPhrase(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#5E5CE6"))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color(hex: "#5E5CE6").opacity(0.12)))

            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.black.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.85)))
    }

    // MARK: - Screen 13: Apple Health

    private var healthScreen: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.pink)

                VStack(spacing: 10) {
                    Text("Breathing that adapts to your body")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text("Calm SOS reads your heart rate to recommend the most effective technique for your stress level right now.")
                        .font(.body)
                        .foregroundColor(.black.opacity(0.65))
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    permissionBullet(emoji: "❤️", text: "Real-time heart rate during exercises")
                    permissionBullet(emoji: "📊", text: "HRV data to track your nervous system recovery")
                    permissionBullet(emoji: "🎯", text: "Smarter suggestions, the more you use it")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.85)))
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 14) {
                onboardingButton(
                    label: healthKit.authStatus == .authorized ? "Apple Health connected ✓" : "Connect Apple Health →"
                ) {
                    if healthKit.authStatus == .authorized {
                        advance()
                    } else {
                        Task {
                            await healthKit.requestAuthorization()
                            advance()
                        }
                    }
                }

                Button("Skip for now") { advance() }
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.45))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        }
    }

    // MARK: - Screen 13: Paywall

    private var paywallScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("Your calm plan is ready.")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text("Unlock everything personalised to you.")
                        .font(.title3)
                        .foregroundColor(.black.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)

                testimonialCard(
                    quote: "The Daily Coach changed everything. It's like having a therapist in your pocket — without the waiting list.",
                    name: "Alex R.",
                    tag: "Premium subscriber"
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("What's included:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black.opacity(0.6))

                    premiumFeatureRow(emoji: "🧠", text: "Daily Coach — AI check-ins built around your triggers")
                    premiumFeatureRow(emoji: "📊", text: "Pattern Analytics — understand why it keeps happening")
                    premiumFeatureRow(emoji: "🗓️", text: "Smart Plan — know exactly what to do today")
                    premiumFeatureRow(emoji: "💤", text: "Sleep Routine — a wind-down for anxious nights")
                    premiumFeatureRow(emoji: "📄", text: "Therapist export — share your progress")
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.9)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05), lineWidth: 1))

                VStack(spacing: 6) {
                    Text("7-day free trial, then $49.99/year")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                    Text("That's just $0.96 a week")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.5))
                }

                VStack(spacing: 14) {
                    onboardingButton(label: "Start My 7-Day Free Trial") {
                        showPaywall = true
                    }

                    Button("Maybe later") { done = true }
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.45))
                }

                Text("Cancel anytime. No charge during trial.")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 52)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Reusable Components

    @ViewBuilder
    private func screenHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
            Text(subtitle)
                .font(.body)
                .foregroundColor(.black.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func onboardingButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#FF6B9D")))
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func testimonialCard(quote: String, name: String, tag: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.caption).foregroundColor(.orange)
                }
            }
            Text("\u{201C}\(quote)\u{201D}")
                .font(.body)
                .foregroundColor(.black.opacity(0.85))
                .italic()
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Text(name).font(.caption).fontWeight(.semibold).foregroundColor(.black)
                Text("·").font(.caption).foregroundColor(.black.opacity(0.4))
                Text(tag).font(.caption).foregroundColor(.black.opacity(0.55))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05), lineWidth: 1))
    }

    @ViewBuilder
    private func solutionRow(pain: String, solution: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(pain)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.5))
                Text(solution)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05), lineWidth: 1))
    }

    @ViewBuilder
    private func toolkitCard(emoji: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Text(emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.semibold).foregroundColor(.black)
                Text(subtitle).font(.caption).foregroundColor(.black.opacity(0.6))
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.title3)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05), lineWidth: 1))
    }

    @ViewBuilder
    private func permissionBullet(emoji: String, text: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
            Text(text).font(.subheadline).foregroundColor(.black.opacity(0.8))
        }
    }

    @ViewBuilder
    private func premiumFeatureRow(emoji: String, text: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
            Text(text).font(.subheadline).foregroundColor(.black.opacity(0.85))
        }
    }

    @ViewBuilder
    private func preferenceToggle(emoji: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 10) {
                Text(emoji).font(.title3)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).fontWeight(.semibold).foregroundColor(.black)
                    Text(subtitle).font(.caption).foregroundColor(.black.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#FF6B9D")))
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - SelectionRow (single and multi-select)

struct SelectionRow: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let multiSelect: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji).font(.title2)
                Text(label)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Image(systemName: selectionIcon)
                    .foregroundColor(isSelected ? Color(hex: "#FF6B9D") : .black.opacity(0.25))
                    .font(.title2)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(isSelected ? Color.white : Color.white.opacity(0.65)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color(hex: "#FF6B9D") : Color.clear, lineWidth: 2))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var selectionIcon: String {
        if multiSelect {
            return isSelected ? "checkmark.square.fill" : "square"
        } else {
            return isSelected ? "checkmark.circle.fill" : "circle"
        }
    }
}

// MARK: - GoalOptionButton (kept for any external references)

struct GoalOptionButton: View {
    let goal: UserPrimaryGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionRow(
            emoji: goal.emoji,
            label: goal.displayText,
            isSelected: isSelected,
            multiSelect: false,
            action: action
        )
    }
}

// MARK: - Tinder Cards (Screen 5)

struct OnboardingTinderView: View {
    let onComplete: () -> Void

    private let statements = [
        ("💭", "When panic hits, my brain goes blank. I can't remember what to do."),
        ("🔍", "I've Googled 'how to stop a panic attack' — usually mid-attack."),
        ("🔄", "I know what triggers me. I just don't know how to stop it once it starts."),
        ("😰", "I feel fine for weeks, then it comes back out of nowhere.")
    ]

    @State private var selected: Set<Int> = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Which of these sounds like you?")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text("Tap everything that resonates.")
                        .font(.body)
                        .foregroundColor(.black.opacity(0.65))
                }

                VStack(spacing: 12) {
                    ForEach(statements.indices, id: \.self) { i in
                        let (emoji, text) = statements[i]
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selected.contains(i) { selected.remove(i) } else { selected.insert(i) }
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 14) {
                                Text(emoji).font(.title2)
                                Text("\u{201C}\(text)\u{201D}")
                                    .font(.body)
                                    .fontWeight(selected.contains(i) ? .semibold : .regular)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                                Image(systemName: selected.contains(i) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(selected.contains(i) ? Color(hex: "#FF6B9D") : .black.opacity(0.25))
                                    .font(.title2)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(selected.contains(i) ? Color.white : Color.white.opacity(0.65)))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected.contains(i) ? Color(hex: "#FF6B9D") : Color.clear, lineWidth: 2))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Button(action: onComplete) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#FF6B9D")))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 4)
                .padding(.bottom, 52)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }
}

// MARK: - Processing Moment (Screen 8)

struct OnboardingProcessingView: View {
    let goal: UserPrimaryGoal?
    let onComplete: () -> Void

    @State private var visibleCount = 0

    private var steps: [String] {
        [
            goal?.processingLabel ?? "Goal noted",
            "Triggers identified",
            "Preferences saved",
            "Personalising your toolkit...",
            "Your plan is ready"
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Building your calm plan...")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text("Just a moment")
                        .font(.body)
                        .foregroundColor(.black.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        if i < visibleCount {
                            HStack(spacing: 14) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "#FF6B9D"))
                                    .font(.title3)
                                Text(steps[i])
                                    .font(.body)
                                    .foregroundColor(.black.opacity(0.85))
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.45), value: visibleCount)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.85)))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        for i in 0..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.5) {
                withAnimation { visibleCount = i + 1 }
            }
        }
        let total = Double(steps.count) * 1.5 + 0.8
        DispatchQueue.main.asyncAfter(deadline: .now() + total) {
            onComplete()
        }
    }
}

// MARK: - Breathing Demo (Screen 9)

struct OnboardingDemoView: View {
    let onComplete: () -> Void

    @StateObject private var speechService = SpeechService()
    @State private var timeRemaining = 30
    @State private var started = false
    @State private var finished = false
    @State private var countdown: Timer?
    @State private var lastSpokenPhase: String = ""

    private var breathingPhase: String {
        let elapsed = 30 - timeRemaining
        let pos = elapsed % 12
        if pos < 4 { return "Breathe in..." }
        else if pos < 6 { return "Hold..." }
        else { return "Breathe out..." }
    }

    private var currentPhaseCue: String {
        let elapsed = 30 - timeRemaining
        let pos = elapsed % 12
        if pos < 4 { return "Inhale" }
        else if pos < 6 { return "Hold" }
        else { return "Exhale" }
    }

    private var ringProgress: CGFloat {
        CGFloat(30 - timeRemaining) / 30.0
    }

    var body: some View {
        ZStack {
            Color(hex: "#0E2D6C").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if !finished {
                    activeContent
                } else {
                    completionContent
                }

                Spacer()

                bottomAction
            }
        }
        .onDisappear {
            countdown?.invalidate()
            speechService.stopAll()
        }
    }

    private var activeContent: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Let's try it right now")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("30 seconds. Just breathe with the bear.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 7)
                    .frame(width: 220, height: 220)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        Color(hex: "#FF6B9D"),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: ringProgress)

                CatMascot()
                    .frame(width: 160, height: 160)
            }

            VStack(spacing: 8) {
                Text(started ? breathingPhase : "Tap below to begin")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.13)))
                    .animation(.easeInOut(duration: 0.4), value: breathingPhase)

                if started {
                    Text("\(timeRemaining)s")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
    }

    private var completionContent: some View {
        VStack(spacing: 24) {
            CatMascot()
                .frame(width: 160, height: 160)

            VStack(spacing: 8) {
                Text("Feel that?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("That's what calm feels like.")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    @ViewBuilder
    private var bottomAction: some View {
        if !finished {
            Button(action: { if !started { start() } }) {
                Text(started ? " " : "Start breathing")
                    .font(.headline)
                    .foregroundColor(started ? .clear : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(started ? Color.clear : Color.white.opacity(0.18))
                    )
            }
            .disabled(started)
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
        } else {
            Button(action: onComplete) {
                Text("That felt good → Continue")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#0E2D6C"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 52)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func start() {
        started = true
        lastSpokenPhase = "Inhale"
        speechService.speak("Inhale", rate: 0.4, pitch: 0.9)
        countdown = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if timeRemaining > 0 {
                timeRemaining -= 1
                let cue = currentPhaseCue
                if cue != lastSpokenPhase {
                    lastSpokenPhase = cue
                    speechService.speak(cue, rate: 0.4, pitch: 0.9)
                }
            } else {
                t.invalidate()
                withAnimation(.easeInOut(duration: 0.6)) { finished = true }
            }
        }
    }
}

#Preview {
    OnboardingView()
}
