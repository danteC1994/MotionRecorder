import SwiftUI

struct DataInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        DataInfoRow(label: "First Recording", value: "Jan 7, 2026 at 3:45 PM")
        DataInfoRow(label: "Last Recording", value: "Jan 7, 2026 at 3:48 PM")
        DataInfoRow(label: "Last Export", value: "Never")
    }
    .padding()
}
