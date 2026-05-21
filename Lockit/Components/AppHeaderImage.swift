import SwiftUI

struct AppHeaderImage: View {
    var body: some View {
        Image("appheader")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .offset(y: 0)
            .allowsHitTesting(false)
    }
}
