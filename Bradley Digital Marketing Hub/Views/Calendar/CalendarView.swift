import SwiftUI

struct ContentCalendarGridView: View {
    @Binding var selectedDate: Date
    let calendarItems: [ContentCalendarItem]
    let onItemTap: (ContentCalendarItem) -> Void
    
    @State private var currentMonth: Date = Date()
    @Environment(\.colorScheme) private var colorScheme
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Month Header
            monthHeader
            
            // Calendar Grid
            calendarGrid
        }
    }
    
    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
            }
            
            Spacer()
            
            Text(currentMonth, format: .dateTime.month(.wide).year())
                .font(.system(size: 20, weight: .semibold))
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .padding()
    }
    
    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar Days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        items: itemsForDate(date),
                        onTap: {
                            selectedDate = date
                        },
                        onItemTap: onItemTap
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstDay = calendar.dateInterval(of: .month, for: currentMonth)?.start else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        let numberOfDays = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day ?? 0
        
        var days: [Date] = []
        
        // Add padding days from previous month
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth),
           let previousMonthDays = calendar.range(of: .day, in: .month, for: previousMonth) {
            let lastDayOfPreviousMonth = previousMonthDays.upperBound - 1
            for i in (lastDayOfPreviousMonth - firstWeekday + 1)...lastDayOfPreviousMonth {
                if let date = calendar.date(byAdding: .day, value: i - lastDayOfPreviousMonth, to: monthInterval.start) {
                    days.append(date)
                }
            }
        }
        
        // Add current month days
        for i in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: i, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        // Add padding days for next month to complete the grid
        let remainingDays = 42 - days.count // 6 weeks * 7 days
        for i in 1...remainingDays {
            if let date = calendar.date(byAdding: .day, value: numberOfDays + i - 1, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func itemsForDate(_ date: Date) -> [ContentCalendarItem] {
        calendarItems.filter { item in
            calendar.isDate(item.date, inSameDayAs: date)
        }
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let items: [ContentCalendarItem]
    let onTap: () -> Void
    let onItemTap: (ContentCalendarItem) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    private var isCurrentMonth: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(dayNumber)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(isCurrentMonth ? (isToday ? .white : .primary) : .secondary)
                .frame(width: 32, height: 32)
                .background(
                    Group {
                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                        } else if isToday {
                            Circle()
                                .fill(Color.red)
                        } else {
                            Circle()
                                .fill(Color.clear)
                        }
                    }
                )
            
            // Item indicators
            if !items.isEmpty {
                HStack(spacing: 2) {
                    ForEach(items.prefix(3)) { item in
                        Circle()
                            .fill(colorForPlatform(item.platform))
                            .frame(width: 4, height: 4)
                    }
                    if items.count > 3 {
                        Text("+\(items.count - 3)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    private func colorForPlatform(_ platform: String) -> Color {
        switch platform.lowercased() {
        case "instagram": return Color.purple
        case "facebook": return Color.blue
        case "twitter", "x": return Color.black
        case "linkedin": return Color.blue.opacity(0.8)
        case "tiktok": return Color.black
        case "youtube": return Color.red
        case "pinterest": return Color.red
        default: return Color.gray
        }
    }
}


