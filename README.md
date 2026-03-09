VAAYU – Agentic AI Health Advisory System

Vaayu is a cross-platform (Flutter mobile + web) AI-powered health advisory application that helps users take preventive actions against air-pollution-related health problems.
Vaayu uses real-time air quality information, location, and a user’s basic health profile to generate simple, actionable AI-based recommendations.

For now it provides plain-language, personalized advice through an AI agent.

----------------------------------------------------------------------
1. PROJECT OVERVIEW
----------------------------------------------------------------------

Vaayu helps users prevent pollution-related issues such as breathing difficulty, asthma irritation, allergies, and fatigue.
It works by combining:

- Real-time AQI data
- User location (GPS or manual search)
- Personal health profile:
  - Age
  - Gender
  - Asthma (Yes/No)
  - Chronic diseases
  - Smoking habits

These inputs are sent to a Node.js LLM advisory engine, which returns personalized guidance such as:
- “Avoid outdoor activity this evening.”
- “Wear a mask when going outside.”
- “Use an air purifier indoors if possible.”

----------------------------------------------------------------------
2. KEY FEATURES
----------------------------------------------------------------------

2.1 Real-Time AQI Monitoring
- Fetches live AQI using an external AQI API
- Displays pollutant values (AQI, PM2.5, PM10 if available)
- Color-coded AQI representation

2.2 Location Detection
- Automatic GPS-based location detection
- Manual city search option

2.3 Health Profile Input
Users can enter:
- Age
- Gender
- Asthma condition
- Chronic illness
- Smoking habits

2.4 AI-Based Personalized Recommendations
Based on:
- Current AQI
- User’s health profile

2.5 Notifications
- Alerts for sudden AQI spikes
- Daily guidance
- Advisory updates based on AQI changes

2.6 Flutter UI
- Clean Material 3 interface
- Works on mobile and web
- Simple dashboard showing AQI and recommendations

----------------------------------------------------------------------
3. SYSTEM ARCHITECTURE
----------------------------------------------------------------------

Frontend:
Flutter application (mobile + web)

Backend:
Flutter/Dart backend

AI Layer:
Node.js LLM advisory engine

Data Flow:
1. User enters health details
2. Location detected or selected
3. AQI fetched from external API
4. Data sent to AI engine
5. AI generates personalized advice
6. Advice shown in UI

----------------------------------------------------------------------
4. TECHNOLOGY STACK
----------------------------------------------------------------------

Frontend:
- Flutter
- Dart

Backend:
- Flutter/Dart server
- AQI API

AI Advisory Engine:
- Node.js
- LLM text generation

----------------------------------------------------------------------
5. FUNCTIONAL REQUIREMENTS
----------------------------------------------------------------------

1. Detect location
2. Fetch AQI
3. Accept health profile input
4. Send AQI + health data to AI engine
5. Display AI-generated advice
6. Notifications
7. Responsive UI for mobile/web

----------------------------------------------------------------------
6. FUTURE ENHANCEMENTS
----------------------------------------------------------------------

- AI-based AQI forecasting
- Voice-based assistant
- City-to-city AQI comparison
- Government pollution alert integration
- Smart notifications
- Air purifier usage tips
- AQI trend charts
- Offline mode using last-known AQI
- Educational pollution safety content
- Favorite locations for AQI monitoring

----------------------------------------------------------------------
7. TEAM MEMBERS
----------------------------------------------------------------------

- Udayaditya Parbat
- Shubhankar Chandel
- Saanidhya Sharma
- Riya Priyadarshini

