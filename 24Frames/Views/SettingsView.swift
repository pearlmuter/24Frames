import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.presentationMode) private var presentationMode
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                Form {
                    Section(header: Text("Photo Limits & Filter").foregroundColor(.gray)) {
                        Toggle(isOn: $settings.isInfinitePicturesMode) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Infinite pictures mode")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Bypass the 24 photo daily calendar limit")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                        
                        Toggle(isOn: $settings.isBlackAndWhiteMode) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Black & White photos")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Live viewfinder and saved photos in monochrome")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                    }
                    .listRowBackground(Color(white: 0.12))
                    
                    Section(header: Text("Film Roll & Development").foregroundColor(.gray)) {
                        Toggle(isOn: $settings.isDevelopModeEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Develop photographs")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Hold photos in film roll until submitted for development")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                        
                        if settings.isDevelopModeEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Development Speed")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Picker("Development Speed", selection: $settings.developmentSpeed) {
                                    ForEach(DevelopmentSpeed.allCases) { speed in
                                        Text(speed.rawValue).tag(speed)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listRowBackground(Color(white: 0.12))
                }
                .formContentBackground()
            }
            .navigationTitle("24Frames Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

extension View {
    @ViewBuilder
    func formContentBackground() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}
