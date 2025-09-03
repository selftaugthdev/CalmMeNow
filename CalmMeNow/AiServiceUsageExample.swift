import Foundation

// MARK: - AiService Usage Examples
/*

 How to use AiService anywhere in your app (e.g. in a button action):

 Task {
     do {
         // Example 1: Generate a personalized panic plan
         let intake: [String: Any] = [
             "triggers": ["crowded places"],
             "symptoms": ["racing heart","dizzy"],
             "preferences": ["breathing","grounding"],
             "duration": 120,
             "phrase": "This will pass; I'm safe."
         ]

         let plan = try await AiService.shared.generatePanicPlan(intake: intake)
         print("Panic plan:", plan)

         // Example 2: Submit a daily check-in
         let checkin: [String: Any] = [
             "mood": 3,
             "tags": ["poor-sleep","work-stress"],
             "note": "Heart feels jumpy before meetings."
         ]

         let coach = try await AiService.shared.dailyCheckIn(checkin: checkin)
         print("Check-in result:", coach)

     } catch {
         print("AI error:", error.localizedDescription)
     }
 }

 // MARK: - Integration with Paywall System

 // Before calling AI functions, check if user has subscription:
 if PaywallManager.shared.hasAIAccess {
     // User has subscription, proceed with AI call
     Task {
         do {
             let plan = try await AiService.shared.generatePanicPlan(intake: intake)
             // Handle the plan response
         } catch {
             // Handle any errors
         }
     }
 } else {
     // Show paywall
     PaywallManager.shared.showPaywall()
 }

 */
