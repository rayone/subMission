enum ConnectionState: Equatable {
    case connecting
    case connected
    case error(String)
    
    var indicator: String {
        switch self {
        case .connecting: return "🟡"
        case .connected:  return "🟢"
        case .error:      return "🔴"
        }
    }
}
