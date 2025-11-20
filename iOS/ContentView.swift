//
//  ContentView.swift
//  iOS
//
//  Created by Pallav Agarwal on 11/19/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var activeApp: AppType?
    @State private var currentPage = 0
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let dockApps: [AppType] = [.phone, .safari, .messages, .music]
    let homeApps: [AppType] = [
        .weather, .calendar, .photos, .camera,
        .notes, .calculator, .settings, .mail,
        .clock, .appStore
    ]
    
    var body: some View {
        ZStack {
            // Wallpaper
            Image("wallpaper")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Pages with TabView
                TabView(selection: $currentPage) {
                    // Page 1: Apps
                    VStack(spacing: 0) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(homeApps) { app in
                                AppIconView(app: app) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        activeApp = app
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.top, 30)
                        
                        Spacer()
                    }
                    .tag(0)
                    
                    // Page 2: Empty
                    VStack(spacing: 0) {
                        Spacer()
                    }
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                Spacer()
                
                // Page Indicator
                HStack(spacing: 8) {
                    Circle().fill(Color.white.opacity(currentPage == 0 ? 1.0 : 0.5)).frame(width: 8, height: 8)
                    Circle().fill(Color.white.opacity(currentPage == 1 ? 1.0 : 0.5)).frame(width: 8, height: 8)
                }
                .padding(.bottom, 30)
                
                // Dock
                HStack(spacing: 20) {
                    ForEach(dockApps) { app in
                        AppIconView(app: app, action:  {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                activeApp = app
                            }
                        }, showLabel: false)
                    }
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 18)
                .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 35, style: .continuous))
                .padding(.horizontal, 10)
                .padding(.bottom, -15)
            }
            .padding(.vertical, 45)
            
            // Hidden Volume View to hijack HUD
            HiddenVolumeView()
                .frame(width: 0, height: 0)
        }
        .fullScreenCover(item: $activeApp) { app in
            AppContainerView(app: app)
        }
    }
}

struct AppContainerView: View {
    let app: AppType
    @Environment(\.dismiss) var dismiss
    @StateObject private var volumeObserver = VolumeObserver()
    @State private var initialVolume: Float = 0.0
    
    var body: some View {
        ZStack {
            // App Content
            ZStack {
                switch app {
                    case .weather: WeatherView()
                    case .calculator: CalculatorView()
                    case .notes: NotesView()
                    case .settings: SettingsView()
                    case .mail: MailView()
                    case .appStore: AppStoreView()
                    case .clock: ClockView()
                    case .calendar: CalendarView()
                    case .photos: PhotosView()
                    case .messages: MessagesView()
                    case .phone: PhoneView()
                    case .camera: CameraView()
                    case .safari: SafariView()
                    case .music: MusicView()
                    default:
                        ZStack {
                            Color.white.ignoresSafeArea()
                            VStack {
                                Text("\(app.displayName) coming soon")
                                    .foregroundStyle(.black)
                            }
                        }
                }
            }
            
            // Back Button Overlay
            VStack {
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Text("◀ Home")
                                .font(.system(size: 12))
                                .padding(.horizontal, 6)
                                .padding(.bottom, 10)
                                .padding(.top, -6)
                        }
                        .foregroundStyle(.primary)
                        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .padding(.leading, 12)
                    .padding(.top, -20)
                    .padding(.vertical, 8)
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            initialVolume = volumeObserver.volume
        }
        .onChange(of: volumeObserver.volume) { newVolume in
            // If volume changes significantly (button press), dismiss
            // Note: This is a heuristic. Volume buttons usually change volume by 0.0625 (1/16)
            if abs(newVolume - initialVolume) > 0.001 {
                dismiss()
            }
            initialVolume = newVolume
        }
    }
}

#Preview {
    ContentView()
}
