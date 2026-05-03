# Project Report: HealthMonitor System Analysis

## 1. Project Requirements

### Functional Requirements
- **User Authentication**: Secure sign-up/login with encrypted password storage and JWT session management.
- **Health Data Logging**: Manual and automated entry for sleep sessions, daily step counts, and active minutes.
- **Supplement Management**: CRUD operations for supplement lists with timed notification scheduling.
- **AI Recommendation Engine**: Automated generation of personalized wellness advice based on 7-day historical trends.
- **Unified Dashboard**: Real-time aggregation of all health metrics into a single "Health Score" for immediate progress assessment.

### Non-Functional Requirements
- **Performance**: Backend response times under 200ms for standard data retrieval.
- **Scalability**: Decoupled architecture to support a growing user base via FastAPI's asynchronous capabilities.
- **Reliability**: ACID-compliant data persistence using PostgreSQL.
- **Usability**: High-fidelity SwiftUI interface with support for dark mode and accessibility features.

---

## 2. Relevance, Novelty, and Practical Significance

### Relevance
With the global shift towards preventative healthcare, there is a critical need for tools that simplify complex health data. HealthMonitor addresses this by centralizing disparate metrics (sleep, exercise, and nutrients) into a single, understandable dashboard.

### Novelty
HealthMonitor's novelty lies in its **Hardware-Free AI Coaching**. While most competitors require expensive wearables (Whoop, Oura), HealthMonitor utilizes advanced statistical analysis and pattern matching to provide high-level insights using only the smartphone's native capabilities and user input.

### Practical Significance
The application serves as a bridge for everyday users who seek the benefits of high-end health optimization without the financial barrier of specialized hardware. It provides immediate practical value by automating the "analysis" phase of wellness tracking.

---

## 3. Competitive Analysis

| Characteristics / Comparisons | Apple Health | MyFitnessPal | Whoop | HealthMonitor |
| :--- | :--- | :--- | :--- | :--- |
| **URL** | https://www.apple.com/health/ | https://www.myfitnesspal.com | https://www.whoop.com | iOS App (App Store) |
| **Creator** | Apple Inc. Founded by Steve Jobs, Steve Wozniak & Ronald Wayne. Native iOS platform built into every iPhone. | Mike Lee & Albert Lee founded MyFitnessPal in 2005. Acquired by Under Armour in 2015, then by Francisco Partners in 2020. | Will Ahmed founded Whoop in 2012. Harvard graduate focused on human performance optimization. | Founded by a team of Kazakh IT engineers and healthcare professionals. |
| **App Language** | English, Spanish, French, German, Chinese, Japanese, Arabic, and 30+ more | English, Spanish, French, German, Portuguese, Italian, Korean, Japanese | English, German, French, Spanish, Portuguese | English |
| **App Goal** | Central health data hub for all iOS devices. Aggregates data from 100+ third-party apps. Tracks activity, sleep, heart rate, nutrition, and more passively. | World's largest nutrition and calorie tracking platform. Helps users reach weight and fitness goals through detailed food logging, macro tracking, and exercise records. | Performance optimization through continuous physiological monitoring. Tracks HRV, respiratory rate, strain, and recovery for athletes and high-performers. | Holistic AI-powered wellness companion. Unifies sleep, activity, and supplement management into a single Health Score with personalized AI coaching. Built for everyday users seeking proactive health guidance. |
| **Key Features** | Step & activity tracking<br>Heart rate monitoring<br>Sleep tracking (basic)<br>Nutrition (via 3rd party apps)<br>100+ app integrations<br>Menstrual cycle tracking<br>Medical records storage<br>NO supplement tracking<br>NO AI coaching | Calorie & macro tracking<br>14M+ food database<br>Barcode food scanner<br>Exercise logging<br>Step tracking<br>Water intake logging<br>Weight progress tracking<br>NO sleep tracking<br>NO supplement tracking<br>NO AI health coaching | HRV monitoring<br>Respiratory rate tracking<br>Recovery score (daily)<br>Strain score (daily)<br>Sleep tracking (advanced)<br>Continuous heart rate<br>Skin temperature tracking<br>NO supplement tracking<br>NO nutrition tracking<br>Requires Whoop hardware | AI Health Coach (7-day analysis)<br>Unified Health Score<br>Sleep session logging<br>Step & activity tracking<br>Supplement management<br>Timed supplement reminders<br>Supplement intake logging<br>Apple HealthKit sync<br>Personalized goal setting<br>Real-time dashboard<br>NO hardware required |
| **App Speed** | Ultra Fast (native iOS) | Fast | Fast | Ultra Fast (native SwiftUI) |
| **Design** | Clean, minimal, Apple-native design. Familiar to all iOS users. White-heavy UI with colored metric rings. | Functional and data-dense. Blue and white color scheme. Practical but dated compared to modern apps. | Sleek dark-mode design. Performance-oriented aesthetic. Data-rich dashboards aimed at serious athletes. | Modern wellness-focused design. Dynamic gradients, vibrant colors, smooth animations. Built with SwiftUI for a premium feel. Designed for motivation and daily engagement. |
| **Contacts** | https://www.apple.com/support/ | https://support.myfitnesspal.com | support@whoop.com<br>https://support.whoop.com | support@healthmonitor.app |
| **Disadvantages** | iOS/Apple ecosystem only<br>No AI coaching or recommendations<br>No supplement tracking<br>Passive only — does not prompt action | Premium features require paid subscription<br>Weak sleep tracking<br>No AI health coaching<br>UI feels outdated<br>Food logging is time-consuming | Requires expensive hardware ($30+/month)<br>No supplement tracking<br>Steep learning curve<br>Niche audience — not for general users<br>No nutrition tracking | iOS only — no Android version yet<br>Smaller user base (early stage)<br>No food/calorie tracking module<br>Still expanding feature set |
| **Advantages** | Free, built-in on every iPhone<br>Highly accurate sensor data<br>100+ app integrations<br>Strong privacy credentials<br>No setup required | Largest food database (14M+ items)<br>Cross-platform (iOS + Android)<br>Strong community features<br>Established trusted brand<br>Barcode scanner for food logging | Deep physiological monitoring (HRV, SpO2)<br>Sophisticated recovery scoring<br>AI coaching features<br>Strong athlete community<br>Continuous 24/7 monitoring | Unified: sleep + activity + supplements<br>AI coaching without hardware<br>Modern, motivating UI<br>Health Score — single wellness metric<br>Supplement adherence tracking<br>Apple HealthKit integration |

---

## 4. Methodology: Statistical Analysis

HealthMonitor employs a **Weighted Multi-Factor Analysis** to calculate the daily **Health Score**. The score is derived from three normalized ratios:

### The Health Score Formula:
$$S = (W_{sleep} \times R_{sleep}) + (W_{activity} \times R_{activity}) + (W_{supps} \times R_{supps})$$

- **$R_{sleep}$ (30%)**: Ratio of actual sleep vs. goal (capped at 1.0).
- **$R_{activity}$ (40%)**: Ratio of actual steps vs. goal (capped at 1.0).
- **$R_{supps}$ (30%)**: Percentage of planned supplements taken for the day.

This methodology ensures that the user receives a balanced view of their wellness, where over-performance in one area (e.g., exercise) cannot fully compensate for poor recovery (sleep).

---

## 5. Architecture Diagrams

### Use-Case Diagram
```mermaid
flowchart LR
    User((User))
    AI((AI Health Coach))
    
    User --> Log(Log Health Data)
    User --> Manage(Manage Supplements)
    User --> View(View Dashboard)
    
    Log -.-> Score(Calculate Health Score)
    
    AI --> Analyze(Analyze Trends)
    Analyze -.-> Recs(Generate Recommendations)
    
    User --> Read(Read Recommendations)
```

### Sequence Diagram: Recommendation Generation
```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend (SwiftUI)
    participant B as Backend (FastAPI)
    participant AI as AI Service
    participant DB as Database
    
    U->>F: Tap "Generate Insights"
    F->>B: POST /recommendations/generate
    B->>DB: Fetch last 7 days of Sleep/Activity/Supps
    DB-->>B: Return History
    B->>AI: Analyze History (Pattern Match)
    AI-->>B: Return Actionable Insights
    B->>DB: Save Recommendations
    B-->>F: Return New Insights
    F->>U: Display Insight Cards
```

### Class Diagram: Backend Domain
```mermaid
classDiagram
    class User {
        +String email
        +String fullName
        +Int stepsGoal
        +Double sleepGoalHours
    }
    class SleepSession {
        +Date sleepDate
        +Int durationMin
        +Time bedtime
    }
    class ActivityLog {
        +Date logDate
        +Int steps
        +Int activeMinutes
    }
    class Supplement {
        +String name
        +String dosage
        +Boolean isActive
    }
    class Recommendation {
        +String category
        +String message
        +DateTime createdAt
    }
    
    User "1" *-- "many" SleepSession
    User "1" *-- "many" ActivityLog
    User "1" *-- "many" Supplement
    User "1" *-- "many" Recommendation
```

### ER Diagram: Database Schema
```mermaid
erDiagram
    USERS ||--o{ SLEEP_SESSIONS : tracks
    USERS ||--o{ ACTIVITY_LOGS : logs
    USERS ||--o{ SUPPLEMENTS : manages
    USERS ||--o{ RECOMMENDATIONS : receives
    SUPPLEMENTS ||--o{ SUPPLEMENT_LOGS : records
    
    USERS {
        int id PK
        string email UK
        string full_name
        string password
        int steps_goal
        float sleep_goal_hours
    }
    SLEEP_SESSIONS {
        int id PK
        int user_id FK
        date sleep_date
        time bedtime
        time wake_time
        int duration_min
    }
    ACTIVITY_LOGS {
        int id PK
        int user_id FK
        date log_date
        int steps
        int active_minutes
        int calories_burned
    }
    SUPPLEMENTS {
        int id PK
        int user_id FK
        string name
        string dosage
        string frequency
        boolean is_active
    }
    SUPPLEMENT_LOGS {
        int id PK
        int supplement_id FK
        date log_date
        string planned_time
        boolean taken
    }
    RECOMMENDATIONS {
        int id PK
        int user_id FK
        string category
        text message
        string trigger_metric
        boolean is_read
        datetime created_at
    }
```
