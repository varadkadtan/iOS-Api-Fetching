import SwiftUI
import SwiftUICharts

struct ContentView: View {
    enum LinkType {
        case recent
        case top
    }
    
    @State private var greeting = ""
    @State private var chartData: [Double] = []
    @State private var recentLinks: [Link] = []
    @State private var topLinks: [Link] = []
    @State private var todaysClicks = ""
    @State private var topSource = ""
    @State private var topLocation = ""
    @State private var totalLinks = ""
    @State private var selectedLinkType: LinkType = .recent
    
    var body: some View {
        
            NavigationView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Dashboard")
                        .font(.largeTitle)
                        .foregroundColor(.primary)
                    Text(greeting)
                        .font(.title)
                        .foregroundColor(.primary)
                    Text("Ajay Manya 👋")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    if !chartData.isEmpty {
                        LineView(data: chartData)
                            .frame(height: 200)
                            .padding(.bottom, 16)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Text("Chart data not available at the moment")
                            .foregroundColor(.secondary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            DashboardBox(title: "Today's Clicks", value: todaysClicks)
                            DashboardBox(title: "Top Source", value: topSource)
                            DashboardBox(title: "Top Location", value: topLocation)
                            DashboardBox(title: "Total Links", value: totalLinks)
                        }
                    }
                    .padding(.bottom, 32)
                    
                    Picker(selection: $selectedLinkType, label: Text("Links")) {
                        Text("Recent Links").tag(LinkType.recent)
                        Text("Top Links").tag(LinkType.top)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.bottom, 8)
                    ScrollView(.vertical,showsIndicators: false){
                        VStack(spacing:20){
                            if selectedLinkType == .recent {
                                LinkListView(links: recentLinks)
                            } else {
                                LinkListView(links: topLinks)
                            }
                        }
                    }
                }
                .padding()
                .foregroundColor(.primary)
                .frame(width: .infinity, height: .infinity)
            }
            .frame(width: .infinity, height: .infinity)
            .accentColor(.primary)
            .onAppear {
                fetchData()
                updateGreeting()
            
        
        }
    }
    
    func fetchData() {
        guard let url = URL(string: "https://api.inopenapp.com/api/v1/dashboardNew") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MjU5MjcsImlhdCI6MTY3NDU1MDQ1MH0.dCkW0ox8tbjJA2GgUx2UEwNlbTZ7Rr38PVFJevYcXFI", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
            } else if let data = data {
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let apiResponse = try decoder.decode(APIResponse.self, from: data)
                    
                    DispatchQueue.main.async {
                        
                        self.chartData = extractChartData(from: apiResponse.data.overallUrlChart)
                        self.recentLinks = apiResponse.data.recentLinks
                        self.topLinks = apiResponse.data.topLinks
                        self.todaysClicks = "\(apiResponse.data.todaysClicks ?? 0)"
                        self.topSource = apiResponse.data.topSource ?? "null"
                        self.topLocation = apiResponse.data.topLocation ?? "null"
                        self.totalLinks = "\(apiResponse.data.totalLinks ?? 0)"
                    }
                } catch {
                    print("Failed to parse JSON: \(error)")
                }
            }
        }.resume()
    }
    
    func updateGreeting() {
            let hour = Calendar.current.component(.hour, from: Date())
            
            switch hour {
            case 5..<12:
                greeting = "Good morning!"
            case 12..<18:
                greeting = "Good afternoon!"
            case 18..<22:
                greeting = "Good evening!"
            default:
                greeting = "Good night!"
            }
        }
    

    func extractChartData(from chartData: [String: Int]?) -> [Double] {
        guard let chartData = chartData else { return [] }
        return chartData.values.map { Double($0) }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct APIResponse: Decodable {
    let data: APIData
    let startTime: String
}

struct APIData: Decodable {
    let overallUrlChart: [String: Int]?
    let recentLinks: [Link]
    let topLinks: [Link]
    let todaysClicks: Int?
    let topSource: String?
    let topLocation: String?
    let totalLinks: Int?
}

struct Link: Decodable {
    let title: String
    let webLink: String
    let totalClicks: Int
    let originalImage: String
    let createdAt: String
}

struct DashboardBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.subheadline)
        }
        .frame(width: 150, height: 100)
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct LinkListView: View {
    let links: [Link]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(links, id: \.title) { link in
                    LinkCard(link: link)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct LinkCard: View {
    let link: Link
    
    var body: some View {
        HStack(spacing: 8) {
            URLImage(url: link.originalImage)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(link.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("Total Clicks: \(link.totalClicks)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(link.webLink)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                Text("Created at: \(link.createdAt)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 300,height: 80)
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct URLImage: View {
    let url: String
    
    @State private var image: UIImage? = nil
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .onAppear {
            load()
        }
    }
    
    private func load() {
        guard let url = URL(string: url) else { return }
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                isLoading = false
                return
            }
            DispatchQueue.main.async {
                self.image = UIImage(data: data)
                isLoading = false
            }
        }.resume()
    }
}


