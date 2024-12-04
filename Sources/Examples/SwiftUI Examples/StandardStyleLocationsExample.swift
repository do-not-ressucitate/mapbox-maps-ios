import MapboxMaps
import SwiftUI

struct StandardStyleLocationsExample: View {
    /// This model is created in root application views for each platform:
    ///
    /// - ``VisionOSMain`` for visionOS
    /// - ``SwiftUIWrapper`` view for iOS
    @EnvironmentObject var model: StandardStyleLocationsModel
    @State private var settingsHeight: CGFloat = 0

#if swift(>=5.9) && os(visionOS)
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
#endif

    var style: MapStyle {
        switch model.style {
        case .standard:
            .standard(
                theme: model.theme,
                lightPreset: model.lightPreset,
                font: model.font,
                showPointOfInterestLabels: model.poi,
                showTransitLabels: model.transitLabels,
                showPlaceLabels: model.placeLabels,
                showRoadLabels: model.roadLabels,
                show3dObjects: model.show3DObjects)
        case .standardSatellite:
            .standardSatellite(
                    lightPreset: model.lightPreset,
                    font: model.font,
                    showPointOfInterestLabels: model.poi,
                    showTransitLabels: model.transitLabels,
                    showPlaceLabels: model.placeLabels,
                    showRoadLabels: model.roadLabels,
                    showRoadsAndTransit: model.showRoadsAndTransit,
                    showPedestrianRoads: model.showPedestrianRoads)
        }
    }

    var body: some View {
        Map(viewport: $model.viewport)
            .mapStyle(style)
            // Center of the map will be translated in order to accommodate settings panel
            .additionalSafeAreaInsets(.bottom, settingsHeight)
            .ignoresSafeArea()
#if swift(>=5.9) && os(visionOS)
            .onAppear {
                openWindow(id: "standard-style-locations-settings")
            }
            .onDisappear {
                dismissWindow(id: "standard-style-locations-settings")
            }
#else
            // On iOS the settings pane will be placed in an overlay view.
            .safeOverlay(alignment: .bottom) {
                StandardStyleLocationsSettings()
                    .floating(RoundedRectangle(cornerRadius: 10))
                    .limitPaneWidth()
                    .background(GeometryReader { proxy in
                        Color.clear.onAppear { settingsHeight = proxy.size.height }
                    })
            }
#endif
            .onChange(of: model.selectedBookmark) { newValue in
                model.viewport = newValue.viewport
            }
    }
}

class StandardStyleLocationsModel: ObservableObject {
    @Published var lightPreset: StandardLightPreset = .day
    @Published var poi = true
    @Published var transitLabels = true
    @Published var placeLabels = true
    @Published var roadLabels = true
    @Published var showRoadsAndTransit = true
    @Published var showPedestrianRoads = true
    @Published var show3DObjects = true
    @Published var selectedBookmark = Location.all.first!
    @Published var viewport: Viewport = Location.all.first!.viewport
    @Published var style: Style = .standard
    @Published var theme: StandardTheme = .default
    @Published var font: StandardFont = .dinPro

    enum Style {
        case standard
        case standardSatellite
    }

    struct Location: Equatable, Identifiable {
        var id: String { title }
        var title: String
        var viewport: Viewport

        static let all = [
            Location(title: "Globe", viewport: .camera(center: .init(latitude: 27.2, longitude: -26.9), zoom: 1.53, bearing: 0, pitch: 0)),
            Location(title: "Europe", viewport: .camera(center: .init(latitude: 47.29, longitude: 0), zoom: 3.28, bearing: 0, pitch: 0)),
            Location(title: "Paris", viewport: .camera(center: .init(latitude: 48.8603, longitude: 2.2932), zoom: 15.58, bearing: 337.89, pitch: 59.67)),
            Location(title: "Japan", viewport: .camera(center: .init(latitude: 36.11, longitude: 138.239), zoom: 6.15, bearing: -85.9, pitch: 61)),
            Location(title: "Washington DC", viewport: .camera(center: .init(latitude: 38.915, longitude: -76.972), zoom: 7.16, bearing: 0, pitch: 0)),
            Location(title: "Amsterdam", viewport: .camera(center: .init(latitude: 52.344, longitude: 4.89), zoom: 10.33, bearing: 0, pitch: 66)),
            Location(title: "Brasília", viewport: .camera(center: .init(latitude: -15.792, longitude: -47.888), zoom: 12.21, bearing: -25.8, pitch: 28)),
            Location(title: "Chicago", viewport: .camera(center: .init(latitude: 41.8812, longitude: -87.62855), zoom: 14.12, bearing: 0, pitch: 0)),
            Location(title: "Brussels", viewport: .camera(center: .init(latitude: 50.8443, longitude: 4.364), zoom: 15.75, bearing: -113.6, pitch: 38)),
            Location(title: "New York", viewport: .camera(center: .init(latitude: 40.7488, longitude: -73.9682), zoom: 16.41, bearing: 96.8, pitch: 38)),
            Location(title: "San Diego", viewport: .camera(center: .init(latitude: 32.7062, longitude: -117.1595), zoom: 18.77, bearing: -53.1, pitch: 72))
        ]
    }
}

struct StandardStyleLocationsSettings: View {
    @EnvironmentObject var model: StandardStyleLocationsModel
    var body: some View {
        VStack(alignment: .leading) {
            SelectorView(data: StandardStyleLocationsModel.Location.all,
                         selection: $model.selectedBookmark) { b in
                Text(b.title)
            }
            Picker("Style", selection: $model.style) {
                Text("Standard").tag(StandardStyleLocationsModel.Style.standard)
                Text("Standard Satellite").tag(StandardStyleLocationsModel.Style.standardSatellite)
            }.pickerStyle(.segmented)
            HStack {
                Text("Light")
                Picker("Light", selection: $model.lightPreset) {
                    Text("Dawn").tag(StandardLightPreset.dawn)
                    Text("Day").tag(StandardLightPreset.day)
                    Text("Dusk").tag(StandardLightPreset.dusk)
                    Text("Night").tag(StandardLightPreset.night)
                }.pickerStyle(.segmented)
            }

            if model.style == .standard {
                HStack {
                    Text("Theme")
                    Picker("Theme", selection: $model.theme) {
                        Text("Default").tag(StandardTheme.default)
                        Text("Faded").tag(StandardTheme.faded)
                        Text("Monochrome").tag(StandardTheme.monochrome)
                    }.pickerStyle(.segmented)
                }
            }

            HStack {
                Text("Font")
                Spacer()
                Picker("Font", selection: $model.font) {
                    Text("Alegreya").tag(StandardFont.alegreya)
                    Text("Alegreya SC").tag(StandardFont.alegreyaSc)
                    Text("Asap").tag(StandardFont.asap)
                    Text("Barlow").tag(StandardFont.barlow)
                    Text("DIN Pro").tag(StandardFont.dinPro)
                    Text("EB Garamond").tag(StandardFont.ebGaramond)
                    Text("Faustina").tag(StandardFont.faustina)
                    Text("Frank Ruhl Libre").tag(StandardFont.frankRuhlLibre)
                    Text("Heebo").tag(StandardFont.heebo)
                    Text("Inter").tag(StandardFont.inter)
                    Text("Lato").tag(StandardFont.lato)
                    Text("League Mono").tag(StandardFont.leagueMono)
                    Text("Montserrat").tag(StandardFont.montserrat)
                    Text("Manrope").tag(StandardFont.manrope)
                    Text("Noto Sans CJK JP").tag(StandardFont.notoSansCjkJp)
                    Text("Open Sans").tag(StandardFont.openSans)
                    Text("Poppins").tag(StandardFont.poppins)
                    Text("Raleway").tag(StandardFont.raleway)
                    Text("Roboto").tag(StandardFont.roboto)
                    Text("Roboto Mono").tag(StandardFont.robotoMono)
                    Text("Rubik").tag(StandardFont.rubik)
                    Text("Source Code Pro").tag(StandardFont.sourceCodePro)
                    Text("Source Sans Pro").tag(StandardFont.sourceSansPro)
                    Text("Spectral").tag(StandardFont.spectral)
                    Text("Ubuntu").tag(StandardFont.ubuntu)
                }.pickerStyle(.menu)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Text("Labels")
                    Group {
                        Toggle("Poi", isOn: $model.poi)
                        Toggle("Transit", isOn: $model.transitLabels)
                        Toggle("Places", isOn: $model.placeLabels)
                        Toggle("Roads", isOn: $model.roadLabels)
                        switch model.style {
                        case .standard:
                            Toggle("3D Objects", isOn: $model.show3DObjects)
                        case .standardSatellite:
                            Toggle("Roads&Transit", isOn: $model.showRoadsAndTransit)
                            Toggle("Pedestrian roads", isOn: $model.showPedestrianRoads)
                        }
                    }
                    .fixedSize()
                    .font(.footnote)
                }.toggleStyleButton()
            }
        }
        .padding(10)
    }

}

private struct SelectorView<T, Content>: View where T: RandomAccessCollection, T.Element: Identifiable, Content: View {
    var data: T
    @Binding
    var selection: T.Element
    var content: (T.Element) -> Content

    func select(_ offset: Int) {
        guard let currentIdx = data.firstIndex(where: { $0.id == selection.id }) else { return }
        var idx = data.index(currentIdx, offsetBy: offset)
        if idx == data.endIndex {
            idx = data.startIndex
        } else if idx == data.index(before: data.startIndex) {
            idx = data.index(before: data.endIndex)
        }
        selection = data[idx]
    }

    var body: some View {
        HStack {
            Button { select(-1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            content(selection)
            Spacer()
            Button { select(1) } label: {
                Image(systemName: "chevron.right")
            }
        }
    }
}

private struct Pair<First, Second> {
    var first: First
    var second: Second
    init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }
}
extension Pair: Equatable where First: Equatable, Second: Equatable {}

struct StandardStyleLocationsExample_Previews: PreviewProvider {
    static var previews: some View {
            StandardStyleLocationsExample()
    }
}
