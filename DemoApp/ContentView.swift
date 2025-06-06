import SwiftUI
import AVKit
import AVFoundation
import Firebase
import FirebaseCore
import FirebaseAuth
import CoreMotion
import PhotosUI


struct ContentView: View {
    @State private var isVideoFinished = false
    @State private var blurAmount: CGFloat = 0
    @State private var videoOpacity: Double = 1
    @State private var loadingProgress: CGFloat = 0.0
    @State private var hasStartedLoading = false
    @State private var videoDuration: Double = 0.0
    @State private var isProgressBarHidden = false
    @State private var isLoggedIn = false

    private let player = AVPlayer(url: Bundle.main.url(forResource: "OrangeLoadingScreen", withExtension: "mp4")!)

    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)

            if !isVideoFinished {
                VStack(spacing: 20) {
                    VideoPlayer(player: player)
                        .frame(width: 280, height: 280)
                        .cornerRadius(20)
                        .allowsHitTesting(false)
                        .offset(y: -100)
                        .onAppear {
                            player.isMuted = true
                            player.play()

                            // Run progress bar once the video starts
                            if !hasStartedLoading {
                                hasStartedLoading = true
                                Task {
                                    if let currentItem = player.currentItem {
                                        let asset = currentItem.asset
                                        do {
                                            let duration = try await asset.load(.duration)
                                            if duration.isNumeric {
                                                videoDuration = CMTimeGetSeconds(duration)
                                                print("Video duration: \(videoDuration) seconds")

                                                // Sync progress bar directly with video playback
                                                player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
                                                    let progress = CMTimeGetSeconds(time) / videoDuration
                                                    
                                                    // Update progress smoothly
                                                    withAnimation(.linear(duration: 0.1)) {
                                                        loadingProgress = CGFloat(progress)
                                                    }

                                                    // Apply blur 2 seconds before the video ends
                                                    if progress >= 1.0 {
                                                        return // Don't apply blur if video is finished
                                                    }

                                                    if progress >= 1.0 - 2.0 / videoDuration {
                                                        withAnimation(.easeInOut(duration: 0.4)) {
                                                            blurAmount = 10
                                                        }
                                                    }
                                                }
                                            }
                                        } catch {
                                            print("Failed to load duration: \(error)")
                                        }
                                    }
                                }
                            }

                            // When video ends, hide the progress bar immediately
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: player.currentItem,
                                queue: .main
                            ) { _ in
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    videoOpacity = 0
                                    blurAmount = 10 // Apply blur immediately at end of video
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Wait a bit before hiding the progress bar
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        isProgressBarHidden = true
                                    }
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    isVideoFinished = true
                                }
                            }
                        }

                    // Glow Progress Bar, conditionally hidden when video ends
                    if !isProgressBarHidden {
                        GlowProgressBar(progress: loadingProgress, blurAmount: blurAmount)
                            .offset(y: -20)
                    }
                }
            } else {
                if isLoggedIn {
                    StoryDashboardPage()
                } else {
                    LandingPageView(isLoggedIn: $isLoggedIn)
                }
            }
        }
    }
}

struct GlowProgressBar: View {
    var progress: CGFloat
    var blurAmount: CGFloat
    let barWidth: CGFloat = 250

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color(.systemGray5))
                .frame(width: barWidth, height: 18)
                .blur(radius: blurAmount)

            // Gradient fill for the progress bar
            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red, Color.orange, Color.yellow]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: barWidth * progress, height: 18)
                .shadow(color: Color.orange.opacity(0.6), radius: 10)
                .blur(radius: blurAmount)
        }
    }
}
enum AuthDestination {
    case login
    case signup
    case storyDashboard  // Add this line to define the case
}
struct LandingPageView: View {
    let examples: [(ai: String, user: String)] = [
        ("You awaken in a forest where the trees whisper your name...", "Who am I?"),
        ("The spaceship AI offers you two buttons: escape or explore.", "Let’s explore."),
        ("A mysterious book glows on the library shelf.", "I open the book."),
        ("The AI asks: 'Would you like to rewrite history?'", "Yes, take me back."),
    ]

    @State private var currentIndex = 0
    @State private var aiText = ""
    @State private var userText = ""
    @State private var path: [AuthDestination] = []
    @Binding var isLoggedIn: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Title
                    VStack(spacing: 8) {
                        Text("StoryBoard")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)

                        Text("An AI Powered Interactive Story Game")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)

                    Spacer()

                    // AI Preview (Fixed width and moved up)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Preview")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)

                        Text(aiText)
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .multilineTextAlignment(.leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                            .frame(maxWidth: 500) // Set maxWidth to avoid overflow
                            .fixedSize(horizontal: false, vertical: true)

                        if !userText.isEmpty {
                            Text("> \(userText)")
                                .font(.system(size: 16, weight: .regular, design: .monospaced))
                                .foregroundColor(.orange)
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, 30)
                    .frame(maxHeight: 250)
                    .offset(y: -60) // Adjust AI preview position

                    Spacer()

                    // Buttons (Horizontal and adjusted position)
                    HStack(spacing: 20) { // Adjusted spacing between buttons
                        PressableButton(label: "Login", color: .orange) {
                            path.append(.login)
                        }

                        PressableButton(label: "Sign Up", color: .red) {
                            path.append(.signup)
                        }
                    }
                    .frame(maxWidth: 50) // Narrowed width for the buttons container
                    .padding(.top, 0)  // Moved buttons up
                    .padding(.bottom, 40)  // Adjusted spacing to prevent overlap
                    .offset(y: -60) // Moved buttons up closer to the middle
                }
            }
            .onAppear {
                startTypingLoop()
            }
            .navigationDestination(for: AuthDestination.self) { destination in
                switch destination {
                case .login:
                    LoginPage(isLoggedIn: $isLoggedIn) // Pass the binding for isLoggedIn
                case .signup:
                    SignupPage(isLoggedIn: $isLoggedIn) // Pass the binding for isLoggedIn
                        .toolbarBackground(Color.white, for: .navigationBar)
                        .toolbarColorScheme(.light)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    path.removeLast()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.red)
                                        Text("Back")
                                            .foregroundColor(.red)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                        }
                case .storyDashboard:
                    StoryDashboardPage() // Assuming you have a StoryDashboardPage
                }
            }
            .onChange(of: isLoggedIn) { oldValue, newValue in
                if newValue {
                    path.append(.storyDashboard)
                }
            }
        }
    }

    // MARK: Typing
    func startTypingLoop() {
        let example = examples[currentIndex]
        aiText = ""
        userText = ""

        typeText(example.ai, into: \.aiText) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                typeText(example.user, into: \.userText) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        currentIndex = (currentIndex + 1) % examples.count
                        startTypingLoop()
                    }
                }
            }
        }
    }

    func typeText(_ fullText: String, into keyPath: ReferenceWritableKeyPath<LandingPageView, String>, completion: @escaping () -> Void) {
        var currentIndex = 0
        let characters = Array(fullText)
        self[keyPath: keyPath] = ""

        Timer.scheduledTimer(withTimeInterval: 0.035, repeats: true) { timer in
            if currentIndex == 0 {
                self[keyPath: keyPath].append(characters[currentIndex])
            }
            if currentIndex < characters.count - 1 {
                DispatchQueue.main.async {
                    self[keyPath: keyPath].append(characters[currentIndex])
                }
                currentIndex += 1
            } else {
                if currentIndex == 0 {
                    self[keyPath: keyPath].append(characters[currentIndex])
                } else {
                    timer.invalidate()
                    completion()
                }
            }
        }
    }
}
struct PressableButton: View {
    var label: String
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .frame(width: 100) // Fixed narrower width for the buttons
                .padding()
                .background(color)
                .cornerRadius(12)
                .foregroundColor(.white)
                .shadow(color: color.opacity(0.6), radius: 3, x: 0, y: 2)
        }
        .padding(.horizontal, 15)
    }
}

struct LoginPage: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isLoggedIn: Bool  // Declare the binding to pass data between views

    @State private var email = ""
    @State private var password = ""
    @State private var isPressed = false
    @State private var showSignup = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 30) {
                VStack(spacing: 6) {
                    Text("Welcome Back")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)

                    Text("Log in to continue your story")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 80)

                Divider().padding(.horizontal, 40)

                VStack(spacing: 20) {
                    SignInWithAppleButtonView()
                    SignInWithGoogleButtonView()

                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)

                Button(action: {
                    withAnimation {
                        isPressed = true
                    }
                    loginUser()
                }) {
                    Text("Log In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 220, height: 50)
                        .background(Color.orange)
                        .cornerRadius(14)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 6)
                }

                // Display error message if there's one
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()

                Button(action: {
                    showSignup = true
                }) {
                    Text("Don’t have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.orange, lineWidth: 1.5)
                        )
                        .padding(.horizontal, 50)
                }
                .fullScreenCover(isPresented: $showSignup) {
                    SignupPage(isLoggedIn: $isLoggedIn)  // Pass the binding to the SignupPage
                }
                .padding(.bottom, 80)
            }
        }
    }

    func loginUser() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty."
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                // Print error details for debugging
                print("Firebase Error Code: \(String(describing: error._code))")
                print("Firebase Error Message: \(error.localizedDescription)")
                
                // Show Firebase error message
                errorMessage = "Login failed: \(error.localizedDescription)"
                return
            }
            
            // Successfully logged in, dismiss the view
            isLoggedIn = true  // Update the login state
            dismiss()
        }
    }
}


struct SignupPage: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isLoggedIn: Bool  // Declare the binding here to receive the login state

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isPressed = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 30) {
                VStack(spacing: 6) {
                    Text("Create Account")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.red)

                    Text("Begin your interactive journey")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 80)

                Divider().padding(.horizontal, 40)

                VStack(spacing: 20) {
                    SignInWithAppleButtonView()
                    SignInWithGoogleButtonView()

                    TextField("Name", text: $name)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)

                Button(action: {
                    withAnimation {
                        isPressed = true
                    }
                    signupUser(email: email, password: password, name: name) { error in
                        if let error = error {
                            print("Signup failed: \(error.localizedDescription)")
                        } else {
                            print("Signup succeeded")
                        }
                    }
                }) {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 220, height: 50)
                        .background(Color.red)
                        .cornerRadius(14)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 6)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()

                Button(action: {
                    // Navigate to LoginPage
                }) {
                    Text("Already have an account? Log In")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red, lineWidth: 1.5)
                        )
                        .padding(.horizontal, 50)
                }
                .padding(.bottom, 80)
            }
        }
    }

    func signupUser(email: String, password: String, name: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(error)
                return
            }

            guard let user = authResult?.user else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User creation failed"]))
                return
            }

            // 1. Update Firebase Auth profile displayName (optional)
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            changeRequest.commitChanges { error in
                if let error = error {
                    print("Error updating displayName: \(error.localizedDescription)")
                }
            }

            // 2. Save user data to Firestore
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "name": name,
                "email": email,
                "createdAt": Timestamp(date: Date())
            ]) { err in
                if let err = err {
                    print("Error saving user data to Firestore: \(err)")
                    completion(err)
                } else {
                    completion(nil)
                }
            }
        }
    }
}
struct SignInWithAppleButtonView: View {
    var body: some View {
        Button(action: {
            // Handle Apple sign in
        }) {
            HStack {
                Image(systemName: "applelogo")
                Text("Sign in with Apple")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}
struct SignInWithGoogleButtonView: View {
    var body: some View {
        Button(action: {
            // Handle Google sign in
        }) {
            HStack {
                Image("google-icon") // Add google icon image asset to project
                    .resizable()
                    .frame(width: 30, height: 30)
                Text("Sign in with Google")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .foregroundColor(.black)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    @Published var x: CGFloat = 0.0
    @Published var y: CGFloat = 0.0

    init() {
        motionManager.deviceMotionUpdateInterval = 1 / 60
        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion else { return }
            // Tilt values
            self.x = CGFloat(motion.attitude.roll)
            self.y = CGFloat(motion.attitude.pitch)
        }
    }
}
struct StoryDashboardPage: View {
    @State private var selectedOption: String?
    @State private var typingText = ""
    @State private var phrases = ["FBLA Sponsored", "AI Generated Stories", "Unique Adventures", "Varun and Aviral"]
    @State private var currentIndex = 0
    @State private var pulse = false
    @State private var particles: [Particle] = []
    @StateObject private var motion = MotionManager()
    @State private var showTestingView = false
    @State private var userName: String = ""
    @State private var showProfilePage = false

    let colors: [Color] = [.red, .orange, .yellow]

    var body: some View {
        Group {
            if showTestingView {
                StoryChoice(showTestingView: $showTestingView)
            } else {
                dashboardBody
            }
        }
    }

    var dashboardBody: some View {
        NavigationStack {
            ZStack {
                Color.white.opacity(0.7).ignoresSafeArea()

                ForEach(particles, id: \.id) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.position.x + motion.x * 30,
                                  y: particle.position.y + motion.y * 30)
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: particle.position)
                }

                VStack {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Welcome, \(userName)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)

                            Text(typingText)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 20)

                        Spacer()

                        Button(action: {
                            showProfilePage = true
                        }) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.black)
                                .padding(.trailing, 20)
                        }
                    }
                    .padding(.top, 40)

                    // Stars animation
                    HStack(spacing: 15) {
                        Image(systemName: "star.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.orange)
                            .rotationEffect(.degrees(-20))
                            .opacity(pulse ? 0.9 : 0.6)
                            .scaleEffect(pulse ? 1.05 : 0.95)
                            .onAppear { pulse = true }
                            .offset(y: 5)

                        Image(systemName: "star.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.orange)
                            .opacity(pulse ? 0.9 : 0.6)
                            .scaleEffect(pulse ? 1.05 : 0.95)
                            .onAppear { pulse = true }

                        Image(systemName: "star.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.orange)
                            .rotationEffect(.degrees(20))
                            .opacity(pulse ? 0.9 : 0.6)
                            .scaleEffect(pulse ? 1.05 : 0.95)
                            .onAppear { pulse = true }
                            .offset(y: 5)
                    }
                    .padding(.top, 40)

                    // Stats
                    HStack(spacing: 55) {
                        StatItem(number: "0", label: "Stories")
                        StatItem(number: "0", label: "Words")
                        StatItem(number: "0", label: "Hours")
                    }
                    .padding()
                    .frame(maxWidth: 300)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.gray.opacity(0.2), radius: 6, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 40)

                    // Buttons
                    VStack(spacing: 30) {
                        HStack(spacing: 20) {
                            OptionButton(title: "Start Story", icon: "plus", action: {
                                showTestingView = true
                            }, width: 140)

                            OptionButton(title: "Resume Story", icon: "arrow.counterclockwise", action: {
                                selectedOption = "Resume Game"
                            }, width: 140)
                        }

                        OptionButton(title: "Settings", icon: "gear", action: {
                            showProfilePage = true
                        }, width: 300)
                    }
                    .padding(.top, 35)

                    Spacer()

                    VStack {
                        Button(action: {
                            // Log out action
                        }) {
                            Text("Log Out")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }
                        .padding(.bottom, 10)

                        Text("Version 1.0")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .onAppear {
                pulse = true
                startTypingAnimation()
                startParticleEffect()
                Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
                    updateParticles()
                }
                fetchUserName()
            }
            .navigationDestination(isPresented: $showProfilePage) {
                ProfilePage(showTestingView: $showProfilePage)
            }
        }
    }

    func fetchUserName() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.userName = "Guest"
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                self.userName = document.get("name") as? String ?? "No Name"
            } else {
                print("Error fetching user name: \(error?.localizedDescription ?? "No document")")
                self.userName = "No Name"
            }
        }
    }

    func startTypingAnimation() {
        typingText = " "
        let fullText = phrases[currentIndex]
        var currentCharIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if currentCharIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: currentCharIndex)
                typingText += String(fullText[index])
                currentCharIndex += 1
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    currentIndex = (currentIndex + 1) % phrases.count
                    startTypingAnimation()
                }
            }
        }
    }

    func startParticleEffect() {
        var newParticles: [Particle] = []

        for _ in 0..<50 {
            let randomColor = colors.randomElement() ?? .white
            let alpha = CGFloat.random(in: 0.2...0.5)
            let particleColor = randomColor.opacity(alpha)

            let position = CGPoint(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
            )

            let velocity = CGVector(
                dx: CGFloat.random(in: -1.5...1.5),
                dy: CGFloat.random(in: -1.5...1.5)
            )

            let particle = Particle(position: position, color: particleColor, size: CGFloat.random(in: 5...10), velocity: velocity)

            newParticles.append(particle)
        }

        self.particles = newParticles
    }

    func updateParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for i in 0..<particles.count {
            var particle = particles[i]

            particle.position.x += particle.velocity.dx
            particle.position.y += particle.velocity.dy

            if particle.position.x <= 0 || particle.position.x >= screenWidth {
                particle.velocity.dx *= -1
            }

            if particle.position.y <= 0 || particle.position.y >= screenHeight {
                particle.velocity.dy *= -1
            }

            particles[i] = particle
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var size: CGFloat
    var velocity: CGVector  // ← New
}

struct StatItem: View {
    var number: String
    var label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct OptionButton: View {
    var title: String
    var icon: String
    var action: () -> Void
    var width: CGFloat
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.black)
                    .padding(.bottom, 10)

                Text(title)
                    .font(.system(size:16))
                    .fontWeight(.medium)
                    .foregroundColor(.black)
            }
            .padding()
            .frame(width: width, height: 100)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.gray.opacity(0.2), radius: 6, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct StoryChoice: View {
    @Binding var showTestingView: Bool
    @State private var showPremadeOptions = false
    @State private var showAITextField = false
    @State private var selectedStory = ""
    @State private var aiTheme = ""
    @State private var selectedButton: String? = nil
    @State private var showAIPage = false
    @State private var exampleThemes = ["Space Adventure", "Medieval Quest", "Cyberpunk Heist", "Jungle Mystery"]
    @State private var currentExampleIndex = 0

    var body: some View {
        NavigationStack {
            VStack {
                Button(action: {
                    showTestingView = false
                }) {
                    HStack {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black)
                            .clipShape(Circle())
                    }
                    .font(.system(size: 18, weight: .medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .padding(.top, 60)
                
                Text("Choose Your Story:")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 30)
                
                Button(action: {
                    showPremadeOptions = true
                    showAITextField = false
                }) {
                    Text("Premade Story")
                        .font(.system(size: 20))
                        .foregroundColor(showPremadeOptions ? Color.orange : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(showPremadeOptions ? Color.white : Color.orange)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange, lineWidth: 2)
                                .foregroundColor(showPremadeOptions ? Color.orange : .clear)
                        )
                }
                .padding(.horizontal)
                
                Button(action: {
                    showAITextField = true
                    showPremadeOptions = false
                }) {
                    Text("AI Story")
                        .font(.system(size: 20))
                        .foregroundColor(showAITextField ? Color.red : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(showAITextField ? Color.white : Color.red)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: 2)
                                .foregroundColor(showAITextField ? Color.red : .clear)
                        )
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                if showPremadeOptions {
                    HStack {
                        WhiteOutlinedButton(title: "FBLA", isSelected: Binding(
                            get: { selectedButton == "Button 1" },
                            set: { isSelected in
                                if isSelected {
                                    selectedButton = "Button 1"
                                } else if selectedButton == "Button 1" {
                                    selectedButton = nil
                                }
                            }
                        ))
                        Spacer()
                        WhiteOutlinedButton(title: "Finance", isSelected: Binding(
                            get: { selectedButton == "Button 2" },
                            set: { isSelected in
                                if isSelected {
                                    selectedButton = "Button 2"
                                } else if selectedButton == "Button 2" {
                                    selectedButton = nil
                                }
                            }
                        ))
                        Spacer()
                    }
                    .padding(.vertical)
                    .padding(.top, 40)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Summary:")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text(summaryText(for: selectedButton))
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: .gray.opacity(0.25), radius: 6, x: 0, y: 3)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                if showAITextField {
                    VStack(alignment: .center, spacing: 16) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.red)
                            Text("AI Story Mode")
                                .foregroundColor(.red)
                        }
                        .font(.title3.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(22)
                        .padding(.top, 30)
                        
                        VStack(spacing: 12) {
                            Text("Enter a Theme")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                            
                            TextField("e.g. FBLA Adventures...", text: $aiTheme)
                                .font(.system(size: 18))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.7), lineWidth: 1.5)
                                )
                                .foregroundColor(.black)
                                .tint(.red)
                            
                            Text("Example: \(exampleThemes[currentExampleIndex])")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .italic()
                                .transition(.opacity)
                                .id(currentExampleIndex)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .gray.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                    }
                    .padding()
                    .animation(.easeInOut, value: currentExampleIndex)
                }
                
                Spacer()
                
                VStack {
                    Spacer()
                    Button(action: {
                        if showPremadeOptions {
                            print("Starting \(selectedStory) story")
                        } else if showAITextField {
                            showAIPage = true
                            print("hello")
                        }
                    }) {
                        Text("Start Story")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .background(Color.white)
            .ignoresSafeArea()
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                    currentExampleIndex = (currentExampleIndex + 1) % exampleThemes.count
                }
            }
            .navigationDestination(isPresented: $showAIPage) {
                AIModeView(theme: aiTheme)
            }
        }
    }

    func summaryText(for selected: String?) -> String {
        switch selected {
        case "Button 1":
            return "A story about a kid who navigates the world of FBLA leadership and competitions.."
        case "Button 2":
            return "A story about a student who takes on financial responsibilities, learning money management and investing."
        default:
            return "Select a story type above to see the summary here."
        }
    }
}


struct WhiteOutlinedButton: View {
    var title: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
            print("\(title) Button Pressed - selected: \(isSelected)")
        }) {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black, lineWidth: 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.orange : Color.clear)
                    )
                    .frame(width: 26, height: 26)
                
                Text(title)
                    .font(.system(size: 20))
                    .foregroundColor(.black)
                    .padding(.leading, 10)
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.25), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}


struct ProfilePage: View {
    @Binding var showTestingView: Bool  // <-- Bind from parent

    @State private var isEditing = false
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var dob = DateComponents(calendar: Calendar.current, year: 1990, month: 1, day: 1).date ?? Date()
    @State private var gender = ""
    @State private var showDatePicker = false

    @State private var showingImagePicker = false
    @State private var profileUIImage: UIImage?

    let profileImageKey = "profileImageData"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Spacer().frame(height: 10)

                    // Profile picture with edit icon overlay
                    ZStack(alignment: .bottomTrailing) {
                        Group {
                            if let uiImage = profileUIImage {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .shadow(radius: 4)

                        Circle()
                            .fill(Color.orange)
                            .frame(width: 34, height: 34)
                            .overlay(
                                Image(systemName: "pencil")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18))
                            )
                            .offset(x: 6, y: 6)
                            .onTapGesture {
                                showingImagePicker = true
                            }
                    }

                    VStack(spacing: 10) {
                        labeledTextField(label: "Name", text: $name, isEditing: isEditing)
                        labeledTextField(label: "Username", text: $username, isEditing: isEditing)
                        labeledTextField(label: "Email", text: $email, isEditing: false, keyboardType: .emailAddress)
                        labeledTextField(label: "Phone Number", text: $phone, isEditing: isEditing, keyboardType: .phonePad)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date of Birth")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.gray)

                            if isEditing {
                                Button(action: {
                                    showDatePicker.toggle()
                                }) {
                                    HStack {
                                        Text(dobFormatted)
                                            .foregroundColor(.black)
                                        Spacer()
                                        Image(systemName: "calendar")
                                            .foregroundColor(.orange)
                                    }
                                    .padding(12)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(10)
                                }
                                .sheet(isPresented: $showDatePicker) {
                                    DatePicker(
                                        "Select Date of Birth",
                                        selection: $dob,
                                        in: ...Date(),
                                        displayedComponents: [.date]
                                    )
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .presentationDetents([.medium])
                                }
                            } else {
                                HStack {
                                    Text(dobFormatted)
                                        .foregroundColor(.black)
                                        .padding(12)
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(10)
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .foregroundColor(.orange)
                                        .padding(12)
                                }
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(10)
                            }
                        }

                        labeledTextField(label: "Gender", text: $gender, isEditing: isEditing)
                    }
                    .padding(.horizontal, 24)


                    Button(action: {
                        if isEditing {
                            saveProfile()
                            saveProfileImageLocally()
                        }
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .background(Color.white.edgesIgnoringSafeArea(.all))
                .onAppear(perform: loadUserProfile)
                .sheet(isPresented: $showingImagePicker) {
                    PhotoPicker(selectedImage: $profileUIImage)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showTestingView = false
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black)
                                .clipShape(Circle())
                        }
                        .font(.system(size: 18, weight: .medium))
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    var dobFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: dob)
    }

    @ViewBuilder
    func labeledTextField(label: String, text: Binding<String>, isEditing: Bool, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color.gray)
            TextField("", text: text)
                .disabled(!isEditing)
                .padding(12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .keyboardType(keyboardType)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }

    func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                self.name = data["name"] as? String ?? "No Name"
                self.username = data["username"] as? String ?? ""
                self.email = Auth.auth().currentUser?.email ?? ""
                self.phone = data["phone"] as? String ?? ""
                if let dobTimestamp = data["dob"] as? Timestamp {
                    self.dob = dobTimestamp.dateValue()
                }
                self.gender = data["gender"] as? String ?? ""

                loadProfileImageLocally()
            } else {
                print("No user profile found, using defaults.")
                self.email = Auth.auth().currentUser?.email ?? ""
                loadProfileImageLocally()
            }
        }
    }

    func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        let userData: [String: Any] = [
            "name": name,
            "username": username,
            "phone": phone,
            "gender": gender,
            "dob": Timestamp(date: dob)
        ]

        db.collection("users").document(uid).setData(userData, merge: true) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            } else {
                print("User data saved successfully.")
            }
        }
    }

    func saveProfileImageLocally() {
        guard let image = profileUIImage else { return }
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: profileImageKey)
        }
    }

    func loadProfileImageLocally() {
        if let imageData = UserDefaults.standard.data(forKey: profileImageKey),
           let image = UIImage(data: imageData) {
            profileUIImage = image
        } else {
            profileUIImage = nil
        }
    }
}
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}

struct AIModeView: View {
    var theme: String
    @State private var messages: [Message] = []
    @State private var userInput: String = ""
    @State private var isTyping = false
    @State private var startTime = Date()
    @State private var timerString = "00:00"
    @State private var photoURL: URL? = nil
    @Environment(\.dismiss) private var dismiss
    private let groqAPIKey = "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"
    private let unsplashAccessKey = "AMR1UKnlXDInt3B7SPkEYWbVp5JdqaC9huOrJj1c63w"
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("AI Mode")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.red)
                Text(timerString)
                    .font(.subheadline)
                    .foregroundColor(.red.opacity(0.8))
            }
            .padding(.top, 20)

            ZStack(alignment: .top) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 4) {
                            if messages.isEmpty {
                                MessageView(message: Message(id: UUID(), sender: .ai, content: "No messages yet. Start the conversation!"))
                                    .opacity(0.5)
                            } else {
                                ForEach(messages) { message in
                                    MessageView(message: message)
                                }
                            }
                            if isTyping {
                                TypingIndicator()
                            }
                        }
                        .padding(.top, 60)
                        .padding([.leading, .trailing], 16)
                    }
                    .frame(height: 350)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 4)
                    .padding(.horizontal)
                    .onChange(of: messages) { _, newMessages in
                        if let last = newMessages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                ZStack {
                    Color.white
                        .cornerRadius(16)
                        .shadow(radius: 4)
                        .frame(width: 150, height: 150)

                    if let photoURL = photoURL {
                        AsyncImage(url: photoURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipped()
                                    .cornerRadius(16)
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray.opacity(0.6))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .offset(y: -120)
            }
            .padding(.top, 140)

            HStack {
                TextField("Type your message...", text: $userInput)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .tint(.red)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.red)
                        .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)

            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Pause Story")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .cornerRadius(10)
                }

                Button(action: {dismiss()}) {
                    Text("End Story")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationBarBackButtonHidden(true)
        .tint(.red)
        .onReceive(timer) { _ in
            let elapsed = Int(Date().timeIntervalSince(startTime))
            let minutes = elapsed / 60
            let seconds = elapsed % 60
            timerString = String(format: "%02d:%02d", minutes, seconds)
        }
        .onAppear {
            if messages.isEmpty {
                startStory()
            }
        }
    }

    func startStory() {
        isTyping = true

        let prompt = "Start an interactive story beginning based on the following theme. Make the background information really short and simple as it's for kids, and end the beginning with both some possible things to do next using the format 'A:' and letters like that and ultimately leave with an open ended question. Remember to keep it short, sweet, and simple (Less than 20 words). Leave the story open ended. Theme:\n\(theme)\n\nAI:"

        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            isTyping = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(groqAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "llama3-8b-8192",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            isTyping = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async { isTyping = false }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let choices = json["choices"] as? [[String: Any]],
                let messageDict = choices.first?["message"] as? [String: Any],
                let content = messageDict["content"] as? String
            else {
                return
            }

            DispatchQueue.main.async {
                let aiMessage = Message(id: UUID(), sender: .ai, content: content.trimmingCharacters(in: .whitespacesAndNewlines))
                messages.append(aiMessage)

                getImageKeywordsFromAI(fromUser: "Intro", fromAI: aiMessage.content)
            }

        }.resume()
    }



    func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let userMessage = Message(id: UUID(), sender: .user, content: userInput)
        messages.append(userMessage)
        userInput = ""
        isTyping = true

        let prompt = messages
            .map { msg in (msg.sender == .user ? "User: " : "AI: ") + msg.content }
            .joined(separator: "\n") + "\nAI:"

        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            isTyping = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(groqAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "llama3-8b-8192",
            "messages": [
                ["role": "user", "content": "Continue the interactive story. Remember to keep it really short and simple as it's for kids, and end the beginning with both some possible things to do next using the format 'A:' and letters like that and ultimately leave with an open ended question. " + prompt]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            isTyping = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async { isTyping = false }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let choices = json["choices"] as? [[String: Any]],
                let messageDict = choices.first?["message"] as? [String: Any],
                let content = messageDict["content"] as? String
            else {
                return
            }

            DispatchQueue.main.async {
                let aiMessage = Message(id: UUID(), sender: .ai, content: content.trimmingCharacters(in: .whitespacesAndNewlines))
                messages.append(aiMessage)

                getImageKeywordsFromAI(fromUser: userMessage.content, fromAI: aiMessage.content)

            }

        }.resume()
    }

    func getImageKeywordsFromAI(fromUser userInput: String, fromAI aiOutput: String) {
        let prompt = """
        Based on this children's story exchange, extract 3 short and relevant keywords for an image that would best illustrate it.

        User: \(userInput)
        AI: \(aiOutput)

        Only respond with the 3 keywords, space-separated. Example: "dragon cave treasure"
        """

        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            print("Failed to create Groq URL.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(groqAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "llama3-8b-8192",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Error serializing second AI request: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Second AI API request failed: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data returned from second AI.")
                return
            }

            if let rawString = String(data: data, encoding: .utf8) {
                print("🔍 Second AI raw response: \(rawString)")
            }

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let choices = json["choices"] as? [[String: Any]],
                let messageDict = choices.first?["message"] as? [String: Any],
                let keywordOutput = messageDict["content"] as? String
            else {
                print("Failed to parse second AI response.")
                return
            }

            let keywords = keywordOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            print("✅ Extracted keywords for Unsplash: '\(keywords)'")
            fetchPhoto(for: keywords)

        }.resume()
    }


    
    func sendPromptToGroq(_ prompt: String) {
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(groqAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "llama3-8b-8192",
            "messages": [["role": "user", "content": prompt]]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to serialize JSON body: \(error)")
            isTyping = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async { self.isTyping = false }

            if let error = error {
                print("Groq API error: \(error)")
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let messageDict = choices.first?["message"] as? [String: Any],
                  let content = messageDict["content"] as? String else {
                print("Groq API response parsing error.")
                return
            }

            DispatchQueue.main.async {
                let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = cleaned.components(separatedBy: "[keywords:")
                let storyPart = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? cleaned
                let keywordLine = parts.count > 1 ? parts[1].replacingOccurrences(of: "]", with: "").trimmingCharacters(in: .whitespacesAndNewlines) : ""
                let keywords = keywordLine.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

                messages.append(Message(id: UUID(), sender: .ai, content: storyPart))

                let keywordQuery = keywords.joined(separator: " ")
                fetchPhoto(for: keywordQuery.isEmpty ? storyPart : keywordQuery)
            }

        }.resume()
    }

    func fetchPhoto(for query: String) {
        let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "kids"
        let urlString = "https://api.unsplash.com/search/photos?query=\(queryEncoded)&orientation=landscape&content_filter=high&client_id=\(unsplashAccessKey)&per_page=1"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let firstResult = results.first,
               let urls = firstResult["urls"] as? [String: Any],
               let photoString = urls["regular"] as? String,
               let photoUrl = URL(string: photoString) {
                DispatchQueue.main.async {
                    self.photoURL = photoUrl
                }
            } else {
                print("Photo fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
}


struct Message: Identifiable, Equatable {
    let id: UUID
    let sender: Sender
    let content: String
}

enum Sender {
    case user, ai
}

struct MessageView: View {
    let message: Message

    var body: some View {
        HStack(alignment: .bottom) {
            if message.sender == .ai {
                Image(systemName: "sparkles")
                    .foregroundColor(.black)
                Text(message.content)
                    .padding(10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                Spacer()
            } else {
                Spacer()
                Text(message.content)
                    .padding(10)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(10)
                Image(systemName: "person.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
    }
}

struct TypingIndicator: View {
    @State private var dotCount = 1

    var body: some View {
        Text(String(repeating: ".", count: dotCount))
            .font(.title2)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    dotCount = (dotCount % 3) + 1
                }
            }
    }
}


struct StoryChoice_Previews: PreviewProvider {
    static var previews: some View {
        StoryDashboardPage()
    }
}
