import SwiftUI
import PhotosUI
import AppFactoryKit

// Old Photo Restoration — pick a faded/old photo, restore it on-device
// (denoise + sharpen + auto-enhance). Press and hold the image to compare with
// the original. Premium unlocks colorize and full-resolution saving.
struct ContentView: View {
    @EnvironmentObject private var factory: AppFactory
    private let service: RestoreService = OnDeviceRestoreService()

    @State private var pickerItem: PhotosPickerItem?
    @State private var inputImage: UIImage?
    @State private var outputImage: UIImage?
    @State private var colorize = false
    @State private var showingOriginal = false
    @State private var isProcessing = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    preview
                    Toggle(isOn: $colorize) {
                        Label("Colorize (Pro)", systemImage: "paintpalette")
                    }
                    .padding(.horizontal, 4)
                    .onChange(of: colorize) { _, on in
                        if on && !factory.subscriptions.isSubscribed {
                            colorize = false
                            factory.presentPaywall(placement: "colorize")
                        }
                    }
                    actions
                    if outputImage != nil {
                        Text("Tip: press and hold the photo to compare with the original")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    if let errorText { Text(errorText).font(.footnote).foregroundStyle(.red) }
                }
                .padding(20)
            }
            .navigationTitle("Restore Photo")
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task { await load(item) }
        }
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18).fill(.quaternary)
            let shown = (showingOriginal ? inputImage : (outputImage ?? inputImage))
            if let shown {
                Image(uiImage: shown).resizable().scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .gesture(LongPressGesture(minimumDuration: 0.01).sequenced(before: DragGesture(minimumDistance: 0))
                        .onChanged { _ in if outputImage != nil { showingOriginal = true } }
                        .onEnded { _ in showingOriginal = false })
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "photo.badge.arrow.down").font(.system(size: 54)).foregroundStyle(.purple)
                    Text("Pick an old photo to restore").foregroundStyle(.secondary)
                }
            }
            if isProcessing { ProgressView().controlSize(.large) }
        }
        .frame(height: 380)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label(inputImage == nil ? "Choose Photo" : "Choose Another", systemImage: "photo")
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered)

            Button { Task { await restore() } } label: {
                Label("Restore", systemImage: "wand.and.rays").frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent).tint(.purple)
            .disabled(inputImage == nil || isProcessing)

            if outputImage != nil {
                Button {
                    factory.requirePremium(feature: "save_restored") { save() }
                } label: {
                    Label("Save to Photos", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func load(_ item: PhotosPickerItem) async {
        errorText = nil
        if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
            inputImage = img; outputImage = nil
        } else { errorText = "Couldn't load that photo." }
    }

    private func restore() async {
        guard let inputImage else { return }
        isProcessing = true; errorText = nil
        defer { isProcessing = false }
        do {
            outputImage = try await service.restore(from: inputImage, colorize: colorize)
        } catch { errorText = "Restore failed. Try another photo." }
    }

    private func save() {
        guard let outputImage else { return }
        UIImageWriteToSavedPhotosAlbum(outputImage, nil, nil, nil)
    }
}
