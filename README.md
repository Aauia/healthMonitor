# HealthMonitor: AI-Powered Personal Wellness Companion

HealthMonitor is a state-of-the-art wellness application designed to bridge the gap between daily health tracking and actionable lifestyle improvements. By combining a beautiful, intuitive SwiftUI interface with a high-performance FastAPI backend, HealthMonitor empowers users to visualize their health data and receive personalized, AI-driven insights to achieve their wellness goals.

## 🎯 Project Goal
The primary objective of HealthMonitor is to provide a holistic, data-centric platform for managing personal health. Unlike traditional trackers that merely record data, HealthMonitor analyzes user patterns across sleep, activity, and nutrition to deliver proactive coaching and meaningful progress visualization.

## 🚀 Core Features
- **AI Health Coach**: A sophisticated insights engine that analyzes the last 7 days of health metrics to generate personalized, context-aware recommendations.
- **Dynamic Health Dashboard**: Real-time calculation of a "Health Score" based on a weighted analysis of sleep quality, step count, and supplement consistency.
- **Intelligent Sleep Tracking**: Detailed logging of sleep sessions, including bedtime consistency, wake-ups, and overall duration.
- **Activity Monitoring**: Integrated step tracking and goal-based progress visualization.
- **Supplement Management**: A robust system for managing vitamins and supplements, featuring timed reminders and intake logging.
- **Secure Onboarding & Profile**: A seamless entry experience with personalized goal setting for activity and recovery.

## 🏗 System Architecture
The project follows a modern, decoupled architecture designed for performance and scalability:

### Frontend (iOS Application)
- **Framework**: SwiftUI
- **Pattern**: MVVM (Model-View-ViewModel) for clean state management.
- **UI/UX**: Wellness-focused design system with vibrant aesthetics, dynamic gradients, and smooth transitions.
- **Networking**: Asynchronous API communication using `async/await` and custom middleware for JWT handling.

### Backend (REST API)
- **Framework**: FastAPI (Python)
- **Database**: PostgreSQL with SQLAlchemy ORM for reliable data persistence.
- **Security**: JWT (JSON Web Token) based authentication with bcrypt password hashing.
- **Logic Layer**: Centralized health services for metric calculation and recommendation generation.

### AI Engine
- **Insight Generation**: A dedicated service that processes historical user data (SleepSession, ActivityLog, SupplementList) to identify patterns and generate actionable wellness advice formatted for mobile consumption.

## 👥 Primary Actors
1. **The User**: Logs daily metrics, manages their profile, and interacts with the dashboard to track their wellness journey.
2. **The AI Coach**: Analyzes stored data to provide proactive, personalized recommendations (e.g., suggesting an earlier bedtime if sleep quality drops).
3. **The Backend Service**: Manages data integrity, processes health scores, and serves as the bridge between the database and the mobile app.

## 🛠 Tech Stack
- **Language**: Swift (SwiftUI), Python
- **Backend API**: FastAPI, Pydantic, Uvicorn
- **Database**: PostgreSQL, SQLAlchemy, Alembic
- **Authentication**: OAuth2 with JWT
- **Design**: SF Symbols, Tailwind-inspired color palette

---
*Developed with a focus on privacy, performance, and user-centric health management.*