import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries = [SimpleEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct TwentyFourFramesWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if #available(iOS 16.0, *) {
            switch family {
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20, weight: .bold))
                }
                .widgetURL(URL(string: "twentyfourframes://snap"))
            default:
                defaultSmallWidgetView
            }
        } else {
            defaultSmallWidgetView
        }
    }
    
    private var defaultSmallWidgetView: some View {
        ZStack {
            Color.black
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 54, height: 54)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                }
                Text("Instant Snap")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .widgetURL(URL(string: "twentyfourframes://snap"))
    }
}

@main
struct TwentyFourFramesWidget: Widget {
    let kind: String = "TwentyFourFramesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TwentyFourFramesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("24Frames Snap")
        .description("Instantly open 24Frames and snap an unenhanced photo.")
        .supportedFamilies(supportedFamilies)
    }
    
    private var supportedFamilies: [WidgetFamily] {
        if #available(iOS 16.0, *) {
            return [.systemSmall, .accessoryCircular]
        } else {
            return [.systemSmall]
        }
    }
}
