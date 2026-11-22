import SwiftUI

struct MagicInputBar: View {
    @Binding var text: String
    let isRecording: Bool
    let onSubmit: () -> Void
    let onMicrophone: () -> Void

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            if isFocused && text.isEmpty {
                HStack(spacing: 6) {
                    example("Созвон завтра в 15:00")
                    example("Купить кофе")
                    Spacer(minLength: 0)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(PulseTheme.work.opacity(0.13)).frame(width: 34, height: 34)
                    Image(systemName: "sparkles").font(.system(size: 14, weight: .bold)).foregroundStyle(PulseTheme.work)
                }
                TextField("Добавить событие или задачу…", text: $text)
                    .focused($isFocused)
                    .font(.subheadline.weight(.medium))
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .onSubmit(onSubmit)

                Button(action: onMicrophone) {
                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isRecording ? PulseTheme.coral : .secondary)
                        .frame(width: 34, height: 34)
                        .background(isRecording ? PulseTheme.coral.opacity(0.12) : Color.primary.opacity(0.055), in: Circle())
                        .symbolEffect(.pulse, isActive: isRecording)
                }
                .buttonStyle(.plain)

                Button(action: onSubmit) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            LinearGradient(colors: [PulseTheme.work, PulseTheme.workDeep], startPoint: .top, endPoint: .bottom),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }
            .padding(9)
            .background(PulseTheme.surface(for: colorScheme), in: .rect(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isFocused ? PulseTheme.work.opacity(0.45) : Color.primary.opacity(0.07), lineWidth: isFocused ? 1.3 : 0.7)
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 20, y: 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .animation(.snappy(duration: 0.25), value: isFocused)
    }

    private func example(_ title: String) -> some View {
        Button(title) {
            text = title
            isFocused = true
        }
        .font(.system(size: 10, weight: .semibold))
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 9).padding(.vertical, 6)
        .background(.primary.opacity(0.05), in: Capsule())
    }
}
