import SwiftUI

struct MagicInputBar: View {
    @Binding var text: String
    let isRecording: Bool
    let onSubmit: () -> Void
    let onMicrophone: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(PulseTheme.work)
            TextField("Например: созвон завтра в 15:00 на 45 минут", text: $text)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .onSubmit(onSubmit)

            Button(action: onMicrophone) {
                Image(systemName: isRecording ? "waveform.circle.fill" : "mic.circle")
                    .font(.title2)
                    .foregroundStyle(isRecording ? .red : .secondary)
                    .symbolEffect(.pulse, isActive: isRecording)
            }
            .accessibilityLabel(isRecording ? "Остановить диктовку" : "Начать диктовку")

            Button(action: onSubmit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: .rect(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
