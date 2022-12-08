import SwiftUI
import PexipInfinityClient

struct SplashView: View {
    let splashScreen: SplashScreen
    private var text: String? {
        splashScreen.elements.first(where: { $0.isTextType })?.text
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundImage
            if let text {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(text).font(.title2)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }

    private var backgroundImage: some View {
        AsyncImage(url: splashScreen.background.url) { image in
            image.resizable()
        } placeholder: {
            Color.black
        }
        .scaledToFit()
        .clipped()
    }
}

// MARK: - Previews

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(
            splashScreen: SplashScreen(
                layoutType: "direct_media",
                background: .init(path: "test.jpg"),
                elements: [
                    .init(
                        type: "text",
                        color: 4294967295,
                        text: "Waiting for the host..."
                    )
                ]
            )
        )
    }
}
