import random
from typing import List, Dict, Any

class AIService:
    def __init__(self):
        # No API key needed for imitation mode
        pass

    def generate_health_insights(self, user_data: Dict[str, Any]) -> List[Dict[str, str]]:
        """
        Imitates an AI Health Coach by generating personalized insights using heuristics.
        This provides a realistic experience without requiring an external API key.
        """
        insights = []
        user_name = user_data.get("user_name", "User")
        goals = user_data.get("goals", {})
        steps_goal = goals.get("steps_goal", 10000)
        sleep_goal = goals.get("sleep_goal_hours", 8)

        # 1. Analyze Sleep
        sleep_history = user_data.get("sleep_history", [])
        if sleep_history:
            avg_sleep_min = sum(s.duration_min for s in sleep_history if s.duration_min) / len(sleep_history)
            avg_sleep_h = avg_sleep_min / 60
            
            if avg_sleep_h < sleep_goal:
                diff = sleep_goal - avg_sleep_h
                insights.append({
                    "category": "sleep",
                    "message": f"Your average sleep is {avg_sleep_h:.1f}h, which is {diff:.1f}h below your goal. Try to go to bed 30 mins earlier tonight."
                })
            else:
                insights.append({
                    "category": "sleep",
                    "message": f"Excellent sleep consistency, {user_name}! You're hitting your {sleep_goal}h goal. This is great for your recovery."
                })
        else:
            insights.append({
                "category": "sleep",
                "message": "I noticed you haven't logged much sleep lately. Consistent tracking helps me provide better recovery insights."
            })

        # 2. Analyze Activity
        activity_history = user_data.get("activity_history", [])
        if activity_history:
            avg_steps = sum(a.steps for a in activity_history) / len(activity_history)
            
            if avg_steps < steps_goal * 0.7:
                insights.append({
                    "category": "activity",
                    "message": f"Your activity level is a bit low this week (avg {int(avg_steps)} steps). A short 15-minute walk today would bridge the gap!"
                })
            elif avg_steps >= steps_goal:
                insights.append({
                    "category": "activity",
                    "message": f"You're crushing your activity goals! Averaging over {int(avg_steps)} steps is fantastic for your cardiovascular health."
                })
            else:
                insights.append({
                    "category": "activity",
                    "message": f"You're almost at your step goal! Just {int(steps_goal - avg_steps)} more steps on average will get you there."
                })
        else:
            insights.append({
                "category": "activity",
                "message": "Starting a new activity habit? Try to aim for 5,000 steps today to build momentum."
            })

        # 3. Analyze Supplements
        supplements = user_data.get("supplements", [])
        if supplements:
            insights.append({
                "category": "supplement",
                "message": f"You're currently taking {len(supplements)} supplements. Remember to stay hydrated as it helps with nutrient absorption."
            })
        
        # 4. General Wellness (Randomized)
        wellness_tips = [
            "Remember to take deep breaths during work breaks to manage stress levels.",
            "Drinking a glass of water right after waking up can jumpstart your metabolism.",
            "Try to limit screen time 1 hour before bed for deeper, more restful sleep.",
            "Consistency is key! Small daily wins lead to big health transformations."
        ]
        insights.append({
            "category": "wellness",
            "message": random.choice(wellness_tips)
        })

        # Return a subset of insights to keep it fresh
        return random.sample(insights, min(len(insights), 3))

ai_service = AIService()
