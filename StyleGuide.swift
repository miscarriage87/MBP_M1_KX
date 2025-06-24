import SwiftUI

struct StyleGuide: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Insets.large) {
                Text("Style Guide")
                    .font(AppFonts.largeTitle)
                    .padding(.bottom, Insets.large)

                // Colors
                VStack(alignment: .leading, spacing: Insets.medium) {
                    Text("Colors")
                        .font(AppFonts.title2)
                    
                    HStack(spacing: Insets.medium) {
                        ColorBlock(color: AppColors.primary, title: "Primary")
                        ColorBlock(color: AppColors.secondary, title: "Secondary")
                        ColorBlock(color: AppColors.success, title: "Success")
                        ColorBlock(color: AppColors.warning, title: "Warning")
                        ColorBlock(color: AppColors.error, title: "Error")
                    }
                }

                // Typography
                VStack(alignment: .leading, spacing: Insets.medium) {
                    Text("Typography")
                        .font(AppFonts.title2)

                    VStack(alignment: .leading, spacing: Insets.small) {
                        Text("Large Title").font(AppFonts.largeTitle)
                        Text("Title").font(AppFonts.title)
                        Text("Headline").font(AppFonts.headline)
                        Text("Body").font(AppFonts.body)
                        Text("Caption").font(AppFonts.caption)
                    }
                }

                // Spacing
                VStack(alignment: .leading, spacing: Insets.medium) {
                    Text("Spacing")
                        .font(AppFonts.title2)

                    HStack(spacing: Insets.medium) {
                        SpacerBlock(width: Insets.small, title: "Small")
                        SpacerBlock(width: Insets.medium, title: "Medium")
                        SpacerBlock(width: Insets.large, title: "Large")
                    }
                }
            }
            .padding(Insets.large)
        }
    }
}

struct ColorBlock: View {
    let color: Color
    let title: String
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(width: 50, height: 50)
                .cornerRadius(CornerRadius.small)
            
            Text(title)
                .font(AppFonts.caption)
        }
    }
}

struct SpacerBlock: View {
    let width: CGFloat
    let title: String

    var body: some View {
        VStack {
            Rectangle()
                .fill(AppColors.secondary.opacity(0.3))
                .frame(width: width, height: 20)
            
            Text(title)
                .font(AppFonts.caption)
        }
    }
}

#Preview {
    StyleGuide()
}
