**Product Requirements Document (PRD)**

**Product Name:** Clubi
**Platform:** iOS
**Version:** MVP (Minimum Viable Product)
**Last Updated:** 2025-07-25

---

## **1. Objective**
Build an iOS app that allows users to review golf courses they've played by answering a series of simple, preset questions. Based on their answers, Clubi will automatically generate a score between 0 and 10 (with one decimal point). This version does not include authentication or performance tracking — the goal is to provide a lightweight, opinion-focused golf course review experience.

---

## **2. Target Users**
- Recreational and avid golfers
- Golfers who want to remember and rank the courses they've played
- Users looking for a clean, Beli-style experience for golf course reviews

---

## **3. Core User Experience**

### 3.1 No Login
- Users can open the app and start immediately
- All data stored locally on the device

### 3.2 Course Search and Selection
- Search bar for course name or location
- If the course does not exist, users can manually add it (Name + Location)

### 3.3 Review Flow (Preset Questions Only)
- Once a course is selected, user is guided through a series of preset multiple-choice questions:

#### Sample Questions and Options (with scoring weights in parentheses):
1. **Did you like this course overall?**
   - No (0)
   - Yes (10)
2. **Would you play it again?**
   - No (0)
   - Maybe (5)
   - Definitely (10)
3. **How was the course layout and design?**
   - Confusing / Bland (0)
   - OK (4)
   - Thoughtful / Fun (7)
   - Excellent (10)
4. **How well maintained was the course?**
   - Poor (0)
   - OK (2.5)
   - Well Maintained (5)
   - Very Well Maintained (7.5)
   - Professional Tour Quality (10)
5. **How scenic was the course?**
   - Not scenic (0)
   - Some nice views (3)
   - Pretty scenic (7)
   - Absolutely stunning (10)
6. **How was the pace of play?**
   - Extremely slow (0)
   - A bit slow (3)
   - Reasonable (7)
   - Fast & smooth (10)
7. **How were the clubhouse amenities?**
   - Bad (0)
   - Decent (3)
   - Good (7)
   - Great (10)
8. **How was the value for money?**
   - Not worth it (0)
   - Fair (3)
   - Good deal (7)
   - Great value (10)
9. **Was the staff friendly and helpful?**
   - Not really (0)
   - Average (3)
   - Friendly (7)
   - Super welcoming (10)
10. **What kind of vibe did the course have?**
   - Too stuffy / snobby (0)
   - Very casual (3)
   - Relaxed but well run (7)
   - Perfect mix of serious & social (10)

### 3.4 Score Calculation
- Each question has a maximum score associated with the best answer
- Total max score: 90
- Final score = (raw total / 90) * 10 → rounded to 1 decimal point

### 3.5 Viewing Course Scores
- User can see a history of courses they’ve rated
- Tap on a course to view the score and their selected answers

### 3.6 Automatic Personal Rankings
- After each review, the course is added to the user's personal Top Courses list
- The list is automatically sorted by score, highest to lowest
- If a course is re-reviewed, its score is updated and the list re-ordered accordingly

---

## **4. Non-Functional Requirements**
- iOS app written in Swift using SwiftUI
- Compatible with iOS 16+
- Local storage only (UserDefaults or Core Data)
- No login, no networking, no backend

---

## **5. Navigation Flow**
1. Open app → Search screen
2. Search for a course
   - If found → tap to start review
   - If not found → option to add it manually
3. Answer preset questions
4. View automatically generated score
5. Course added to “My Top Courses” list in ranked position

---

## **6. Key Screens**
- Course Search
- Add Course (if needed)
- Review Question Flow (multi-screen or scrollable form)
- Score Summary
- My Top Courses (auto-ranked list)

---

## **7. Future Considerations (Not in MVP)**
- Sharing reviews with friends
- Filtering by state/region
- Social feed of where friends have played
- Cloud sync / export
- Map view of played courses

---

## **8. Success Metrics**
- % of users who complete a review within 2 minutes of opening the app
- Average number of courses reviewed per user
- % of users who return within 7 days to review another course
- % of reviewed courses shown in Top Courses list

---

End of Document

