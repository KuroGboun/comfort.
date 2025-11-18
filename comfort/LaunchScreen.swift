import SwiftUI

struct LaunchScreen: View {
    @State private var animateLogo = false
    @State private var fadeOutLogo = false
    @State private var fadeToWhite = false
    @State private var showHome = false

    var body: some View {
        ZStack {
            (fadeToWhite ? Color.white : Color.comfortBackground)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.2), value: fadeToWhite)

            Text("comfort.")
                .font(.comfort(size: 52))
                .foregroundColor(.white)
                .opacity(fadeOutLogo ? 0 : 1)
                .scaleEffect(animateLogo ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateLogo)
                .animation(.easeInOut(duration: 1.0), value: fadeOutLogo)
        }
        .onAppear {
            animateLogo = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    fadeOutLogo = true
                    fadeToWhite = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
                showHome = true
            }
        }
        .fullScreenCover(isPresented: $showHome) {
            ContentView()
                .transition(.opacity)
        }
    }
}

#Preview {
    LaunchScreen()
}
