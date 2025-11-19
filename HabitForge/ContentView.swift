//
//  ContentView.swift
//  HabitForge
//
//  Created by yunus emre yıldırım on 12.09.2025.
//

import SwiftUI
import UserNotifications


struct ColorData: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Double(r)
        green = Double(g)
        blue = Double(b)
        alpha = Double(a)
    }

    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

enum WeekDay: String, Codable, CaseIterable, Identifiable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .monday: "Pazartesi"
        case .tuesday: "Salı"
        case .wednesday: "Çarşamba"
        case .thursday: "Perşembe"
        case .friday: "Cuma"
        case .saturday: "Cumartesi"
        case .sunday: "Pazar"
        }
    }
}

struct Habit : Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool = false
    var habitDescription: String
    var dailyTarget: Int
    var remaininToday: Int
    var habitColor: ColorData
    var activeDays: [WeekDay]
    var startTime: Date?
    var repeatIntervalHours: Int?
}

class HabitForgeViewModel: ObservableObject {
    @Published var habits: [Habit] = [
//        Habit(title: "Mark 0 tamamla", habitDescription: "Hep daha ileriye", dailyTarget: 2, remaininToday: 2, habitColor: ColorData(color: .blue)),
//        Habit(title: "Mark I tamamla", habitDescription: "Hep daha ileriye", dailyTarget: 3, remaininToday: 3, habitColor: ColorData(color: .blue)),
//        Habit(title: "Mark II tamamla", habitDescription: "Hep daha ileriye", dailyTarget: 4, remaininToday: 4, habitColor: ColorData(color: .blue))
    ] {
        didSet {
            saveHabits()
        }
    }
        private let habitsKey = "habits_key"

            init() {
                loadHabits()
            }

            func saveHabits() {
                let encoder = JSONEncoder()
                if let data = try? encoder.encode(habits) {
                    UserDefaults.standard.set(data, forKey: habitsKey)
                }
            }

            func loadHabits() {
                if let data = UserDefaults.standard.data(forKey: habitsKey) {
                    let decoder = JSONDecoder()
                    if let decoded = try? decoder.decode([Habit].self, from: data) {
                        self.habits = decoded
                    }
                }
            }
    
    @Published var completedHabits: [Habit] = []

    // Schedules notifications for a given habit
    func scheduleNotifications(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        guard let startTime = habit.startTime else { return }
        let calendar = Calendar.current
        for day in habit.activeDays {
            for repetition in 0..<habit.dailyTarget {
                var dateComponents = calendar.dateComponents([.hour, .minute], from: startTime)
                // Calculate hour and minute for each repetition
                if let repeatInterval = habit.repeatIntervalHours, repetition > 0 {
                    let hour = (dateComponents.hour ?? 0) + repetition * repeatInterval
                    dateComponents.hour = hour % 24
                    // Optionally, you could add day offset if hour >= 24, but for simplicity we wrap to next day
                }
                // Set weekday (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
                switch day {
                case .sunday: dateComponents.weekday = 1
                case .monday: dateComponents.weekday = 2
                case .tuesday: dateComponents.weekday = 3
                case .wednesday: dateComponents.weekday = 4
                case .thursday: dateComponents.weekday = 5
                case .friday: dateComponents.weekday = 6
                case .saturday: dateComponents.weekday = 7
                }
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let content = UNMutableNotificationContent()
                content.title = "Habit Reminder"
                content.body = habit.title
                let request = UNNotificationRequest(
                    identifier: "\(habit.id.uuidString)_\(day.rawValue)_\(repetition)",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }
        }
    }
}

struct HabitView: View {
    @ObservedObject var habitModel: HabitForgeViewModel
    @State var openSheet: Bool = false
    var index : Int
    var body: some View {
        HStack {
            Button{
                if habitModel.habits[index].remaininToday > 0 {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        habitModel.habits[index].remaininToday -= 1
                    }
                    if habitModel.habits[index].remaininToday == 0 {
                        withAnimation(.easeInOut) {
                            habitModel.habits[index].isCompleted = true
                        }
                        let habit = habitModel.habits[index]
                        habitModel.completedHabits.append(habit)
                    }
                }else {
                    withAnimation(.easeInOut) {
                        habitModel.habits[index].isCompleted.toggle()
                    }
                    let habit = habitModel.habits[index]
                    if habitModel.completedHabits.contains(where: { $0.id == habit.id }) {
                        habitModel.completedHabits.removeAll(where: { $0.id == habit.id })
                        habitModel.habits[index].remaininToday = habit.dailyTarget
                    } else {
                        habitModel.completedHabits.append(habit)
                    }
                }
            }label: {
//                Circle()
//                    .stroke(lineWidth: 1)
//                    .frame(width: 37)
//                    .foregroundColor(habitModel.habits[index].isCompleted ? Color.green : Color.blue)
//                    .overlay(
//                        ZStack {
//                            Text(habitModel.habits[index].remaininToday.description)
//                                .foregroundColor(habitModel.habits[index].isCompleted ? .clear : .lightDark)
//                            Image(systemName: "checkmark")
//                                .foregroundColor(habitModel.habits[index].isCompleted ? .green : .clear)
//                        }
//                    )
                
                CircularProgressBar(habitModel: habitModel, index: index,
                    progress: 1.0 - Double(habitModel.habits[index].remaininToday)
                                     / Double(habitModel.habits[index].dailyTarget)
                )
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            
            
            Text(habitModel.habits[index].title)
                .font(.title2)
            
            Spacer()
            
            Button{
                withAnimation(.bouncy) {
                    openSheet.toggle()
                }
            } label: {
                
                Circle()
                    .frame(width: 25)
                    .foregroundColor(Color.gray.opacity(0))
                    .overlay(
                        Image(systemName: "ellipsis")
                            .foregroundColor(Color.lightDark)
                    )
            }
            .buttonStyle(.bordered)
            .contentShape(Circle())
            .sheet(isPresented: $openSheet) {
                HabitDetailView(
                    habitModel: habitModel,
                    habitTitle: habitModel.habits[index].title,
                    habitDescirption: habitModel.habits[index].habitDescription,
                    habitTarget: habitModel.habits[index].dailyTarget,
                    habitColor: habitModel.habits[index].habitColor,
                    index: index
                )
            }
            Circle()
                .frame(width: 7)
                .foregroundColor(habitModel.habits[index].habitColor.swiftUIColor)
        }
    }
}

struct HabitDetailView: View {
    @ObservedObject var habitModel: HabitForgeViewModel
    @Environment(\.dismiss) var dismiss
    @State var editPage: Bool = false
    @State var habitTitle: String
    @State var habitDescirption: String
    @State var habitTarget: Int
    @State var habitColorUI: Color
    var index: Int
    
    init(habitModel: HabitForgeViewModel,
         habitTitle: String,
         habitDescirption: String,
         habitTarget: Int,
         habitColor: ColorData,
         index: Int) {
        self._habitTitle = State(initialValue: habitTitle)
        self._habitDescirption = State(initialValue: habitDescirption)
        self._habitTarget = State(initialValue: habitTarget)
        self._habitColorUI = State(initialValue: habitColor.swiftUIColor)
        self.habitModel = habitModel
        self.index = index
    }
    
    var body: some View {
        NavigationStack{
            Form{
                if !editPage {
                    Section(header: Text("Habit Name")){
                        Text(habitTitle)
                            .font(.title.bold())
                    }
                    Section(header: Text("Description")){
                        Text(habitModel.habits[index].habitDescription)
                    }
                    
                    Section {
                        HStack {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.blue)
                            Text("Color")
                            Spacer()
                            RoundedRectangle(cornerRadius: 15)
                                .foregroundColor(habitColorUI)
                                .frame(width: 50, height: 25)
                        }
                    }

                    Section {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            
                            HStack {
                                Text("Daily Target")
                                    .foregroundColor(.lightDark)
                                Spacer()
                                Text("\(habitTarget) times")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } else {
                    Section(header: Text("Habit Name")){
                        TextField(habitTitle, text: $habitTitle)
                    }
                    
                    Section(header: Text("Description")){
                        TextField(habitDescirption, text: $habitDescirption)
                    }
                    
                    Section {
                        HStack {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.blue)
                            Text("Color  ")
                                
                            RoundedRectangle(cornerRadius: 15)
                                .foregroundColor(habitColorUI)
                                .frame(width: 50, height: 25)
                            ColorPicker("", selection: $habitColorUI)
                        }
                    }
                    
                    Section{
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            
                            HStack {
                                Text("Daily Target")
                                    .foregroundColor(.lightDark)
                                Spacer()
                                Text("\(habitTarget) times")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Picker("Sayı Seç", selection: $habitTarget) {
                            ForEach(1...30, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                        .transition(.move(edge: .bottom).combined(with: .slide))
                    }
                }
            }
            
            .toolbar {
                if !editPage {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Edit") {
                            editPage = true
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading){
                        Button("Close") {
                            dismiss()
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            habitModel.habits[index].title = habitTitle
                            habitModel.habits[index].habitDescription = habitDescirption
                            habitModel.habits[index].dailyTarget = habitTarget
                            habitModel.habits[index].remaininToday = habitTarget
                            habitModel.habits[index].habitColor = ColorData(color: habitColorUI)
                            editPage = false
                        }label: {
                            Image(systemName: "checkmark")
                                .bold()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    ToolbarItem(placement: .title){
                        Text("Edit")
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading){
                        Button {
                            editPage = false
                        }label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.automatic)
                        
                    }
                }
            }
        }
    }
}

struct NewHabitView: View {
    @ObservedObject var habitModel: HabitForgeViewModel
    @Environment(\.dismiss) var dismiss
    @State var newHabit: String = ""
    @State var newDescirption: String = ""
    @State var newTarget: Int = 1
    @State var newColor: Color = Color.red
    @State var showTargetPicker: Bool = false
    @State var buttonAlert: Bool = false
    @State var newActiveDays: [WeekDay] = []
    @State var newStartTime: Date = Date()
    @State var newInterval: Int = 1
    
    var body: some View {
        NavigationStack{
            Form{
                // ALERT SECTION
                if buttonAlert {
                    Section(header: HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Alert")
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("You need to give your habit a name!")
                        }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                            removal: .opacity))
                }
                
                Section(header: HStack {
                    Image(systemName: "circle.grid.2x2")
                    Text("Habit")
                }){
                    TextField("Name", text: $newHabit)
                    TextField("Description", text: $newDescirption)
                }
                
                Section{
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Button{
                            withAnimation(.easeInOut) {
                                showTargetPicker.toggle()
                            }
                        }label: {
                            HStack {
                                Text("Daily Target")
                                    .foregroundColor(.lightDark)
                                Spacer()
                                Text("\(newTarget) times")
                                    .foregroundColor(.green)
                            }
                            
                        }
                    }
                        
                    if showTargetPicker {
                        Picker("", selection: $newTarget) {
                            ForEach(1...30, id: \.self) { number in
                                Text("\(number)").tag(number)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                        .transition(.move(edge: .bottom).combined(with: .slide))

                    }
                    
                }
                
                // Gün seçme
                Section(header: Text("Days")) {
                    ForEach(WeekDay.allCases) { day in
                        Toggle(day.displayName, isOn: Binding(
                            get: { newActiveDays.contains(day) },
                            set: { isOn in
                                if isOn {
                                    newActiveDays.append(day)
                                } else {
                                    newActiveDays.removeAll { $0 == day }
                                }
                            }
                        ))
                    }
                }

                // İlk bildirim saati
                Section(header: Text("Start Time")) {
                    DatePicker("First Notification", selection: $newStartTime, displayedComponents: .hourAndMinute)
                }

                // Eğer hedef > 1 ise tekrar aralığı
                if newTarget > 1 {
                    Section(header: Text("Repeat Interval")) {
                        Picker("Interval (hours)", selection: $newInterval) {
                            ForEach(1...3, id: \.self) { hour in
                                Text("\(hour) saat").tag(hour)
                            }
                        }
                    }
                }
                
                Section {
                    HStack {
                        Image(systemName: "paintbrush")
                            .foregroundColor(.blue)
                        Text("Color :")
                            
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundColor(newColor)
                            .frame(width: 50, height: 25)
                        ColorPicker("", selection: $newColor)
                    }
                }
                
                
                
            }
            .navigationTitle("Create New Habit")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        withAnimation(.easeInOut) {
                            buttonAlert = false
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        if !newHabit.isEmpty {
                            withAnimation(.easeInOut) {
                                buttonAlert = false
                                habitModel.habits.append(
                                    Habit(
                                        title: newHabit,
                                        isCompleted: false,
                                        habitDescription: newDescirption,
                                        dailyTarget: newTarget,
                                        remaininToday: newTarget,
                                        habitColor: ColorData(color: newColor),
                                        activeDays: newActiveDays,
                                        startTime: newStartTime,
                                        repeatIntervalHours: newTarget > 1 ? newInterval : nil
                                    )
                                )
                                // Schedule notifications for the newly added habit
                                if let lastHabit = habitModel.habits.last {
                                    habitModel.scheduleNotifications(for: lastHabit)
                                }
                            }
                            dismiss()
                        } else {
                            withAnimation(.easeInOut) {
                                buttonAlert = true
                            }
                        }
                    }
                    .bold()
                    .buttonStyle(.borderedProminent)
                }
            }
            .animation(.easeInOut, value: buttonAlert)
            .animation(.easeInOut, value: showTargetPicker)
        }
    }
}


struct StatisticPageView: View {
    @ObservedObject var habitModel: HabitForgeViewModel
    var body: some View {
        let total = habitModel.habits.count
                let completed = habitModel.habits.filter { $0.isCompleted }.count
                
                VStack(spacing: 20) {
                    Text("Your Progress")
                        .font(.title.bold())
                    
                    CustomProgressBar(progress: Double(completed) / Double(max(total, 1)))
                        .padding()
                    
                    Text("Completed: \(completed)/\(total)")
                        .font(.headline)
                    
                    Spacer()
                }
                .padding()
                .padding(.top, 50)
    }
}

struct HabitPageView: View {
    @ObservedObject var habitModel: HabitForgeViewModel
    @State var openSheet: Bool = false
    var body: some View {
        let total = habitModel.habits.count
        let completed = habitModel.habits.filter { $0.isCompleted }.count
        NavigationStack{
            HStack {
                Form{
                    Section(header: Text("Progress")){
                        VStack {
                            CustomProgressBar(progress: Double(completed) / Double(max(total, 1)))
                                .padding(.top, 10)
                            Text("Completed: \(completed)/\(total)")
                                .font(.headline)
                        }
                        /*.listRowBackground(completed == total && total > 0 ? Color.green.opacity(0.1) : Color.lightDarkBack)*/  //--> Tüm habitler bittiğinde arkayı yeşil yapar
                    }
                    
                    //1. habits
                    Section(header: Text("Habits")) {
                        ForEach(habitModel.habits.filter { !$0.isCompleted }) { habit in
                            if let index = habitModel.habits.firstIndex(where: { $0.id == habit.id }) {
                                HabitView(habitModel: habitModel, index: index)
                                    .listRowBackground(habit.habitColor.swiftUIColor.opacity(0.2))
                            }
                        }
                    }
                    
                    //2. Completed habits
                    Section(header: Text("Completed")) {
                        ForEach(habitModel.habits.filter { $0.isCompleted }) { habit in
                            if let index = habitModel.habits.firstIndex(where: { $0.id == habit.id }) {
                                HabitView(habitModel: habitModel, index: index)
                                    .listRowBackground(Color.green.opacity(0.2))
                            }
                        }
                    }
                    
                    
                    
                }
                .navigationTitle(Text("Habit Forge"))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button{
                            openSheet.toggle()
                        }label:{
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.extraLarge)
                    }
                }
                .sheet(isPresented: $openSheet) {
                    NewHabitView(habitModel: habitModel)
                }
            }
        }
        .ignoresSafeArea(edges: .all)
    }
}

struct WeeksPageView: View {
    @ObservedObject var habitModel: HabitForgeViewModel
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        VStack {
            DatePicker(
                "Select Day",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .frame(maxHeight: 350)
            .padding()
            
            Divider()
            

            List {
                ForEach(habitModel.habits.filter { $0.activeDays.contains(selectedDate.weekDay) }) { habit in
                    HStack {
                        Circle()
                            .fill(habit.habitColor.swiftUIColor)
                            .frame(width: 12, height: 12)
                        Text(habit.title)
                        Spacer()
                        if let time = habit.startTime {
                            Text(time.formatted(date: .omitted, time: .shortened))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }
}

extension Date {
    var weekDay: WeekDay {
        let weekdayIndex = Calendar.current.component(.weekday, from: self)
        switch weekdayIndex {
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .sunday
        }
    }
}

struct ContentView: View {
    @StateObject var habitModel = HabitForgeViewModel()
    var body: some View {
        TabView {
            HabitPageView(habitModel: habitModel)
                .tabItem {
                    Label("Habits", systemImage: "list.bullet")
                }
            
            WeeksPageView(habitModel: habitModel)
                .tabItem {
                    Label("Weeks", systemImage: "calendar")
                }
            
            StatisticPageView(habitModel: habitModel)
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar")
                }
        }
    }
}

#Preview {
    ContentView()
}




