# BrickFeed — App Store Connect Metadata

Complete copy-paste fields for App Store Connect submission.

---

## App Name
BrickFeed

## Subtitle (30 characters max)
Share Your LEGO Builds

## Bundle ID
com.brickfeed.app

---

## Description (4000 characters max)

BrickFeed is the ultimate social network for LEGO fans of all ages! Share photos of your amazing brick builds, discover incredible creations from builders around the world, and earn points while connecting with a safe, kid-friendly community that loves LEGO just as much as you do.

BUILD. SHARE. EARN POINTS. INSPIRE.

Whether you just finished a massive UCS Millennium Falcon, created an awesome custom MOC (My Own Creation), or are showing off your very first LEGO City set, BrickFeed is the place to share it with the world!

🧱 CORE FEATURES:

• Share Your Builds — Snap a photo of your LEGO creation, tag the official set number or mark it as a custom build, and share it instantly with the BrickFeed community.

• Discover Amazing Builds — Browse a feed full of incredible LEGO creations. Find builds from Star Wars, Harry Potter, Technic, City, Architecture, and every theme you love.

• Follow Your Favorite Builders — Follow builders whose work inspires you and see their latest creations in your personalized feed.

• Like and Comment — Show love for great builds with likes and leave encouraging comments. Every interaction earns points for the creator!

⭐ POINTS SYSTEM:
• Post a build → earn 10 points
• Receive a like → earn 2 points
• Receive a comment → earn 5 points
• Get followed → earn 1 point

Climb the Global Leaderboard and show the BrickFeed community who the top builder really is!

🏆 LEADERBOARD:
• Global Leaderboard ranks ALL builders by total points
• Friends Leaderboard shows how you compare to builders you follow
• Trophy icons for top 3 builders — gold, silver, and bronze!

🔍 LEGO SET SEARCH:
• Look up any official LEGO set by name or number
• See piece count, theme, age rating, and retail price
• Tap to buy from the official LEGO Store

💬 DIRECT MESSAGES:
• Chat privately with builders you follow
• Age verification required to keep younger users safe

🛡️ SAFE AND FUN FOR EVERYONE:
BrickFeed is designed with safety as a top priority:

• Kid Safe Mode automatically enabled for users under 13 (COPPA compliant)
• Built-in bad word filter removes inappropriate language from all posts and comments
• Report any post with one tap — choose from: Inappropriate content, Bullying, Spam, Not LEGO related
• Block any builder to hide their content from your feed
• Direct messaging requires age verification
• Privacy Policy and Terms of Service visible before account creation
• Sign in with Apple supported (required by Apple for apps with social login)

No ads. No data selling. Just LEGO fun!

LEGO is a trademark of the LEGO Group, which does not sponsor, authorize, or endorse this app.

---

## Keywords (100 characters max)
lego,kids,social,builds,bricks,creative,safe,builders,minifigures,sets,moc,brick,fan,share,points

---

## Support Email
support@brickfeed.app

## Support URL
https://blockmasterjames-cyber.github.io/brickfeed-legal/support

## Privacy Policy URL
https://blockmasterjames-cyber.github.io/brickfeed-legal/privacy

## Terms of Service URL
https://blockmasterjames-cyber.github.io/brickfeed-legal/terms

---

## Primary Category
Social Networking

## Secondary Category
Kids

---

## Age Rating
4+ (Made for Kids: Yes)

### Age Rating Questionnaire Answers
- Cartoon or fantasy violence: No
- Realistic violence: No
- Sexual content or nudity: No
- Profanity or crude humor: No (bad word filter always active)
- Mature/suggestive themes: No
- Horror/fear themes: No
- Medical/treatment info: No
- Alcohol, tobacco, or drugs: No
- Gambling: No
- Contests: No
- User-generated content: Yes (moderated with bad word filter, reporting, and blocking)
- Unrestricted web access: No (only links to official LEGO Store and legal pages)

---

## What's New in This Version

v1.0.0 — Initial Release!

🎉 Welcome to BrickFeed — the LEGO community social network!

• Share photos of your LEGO builds with builders worldwide
• Earn points for posting, likes, comments, and follows
• Global and Friends Leaderboard to see who's on top
• Full COPPA compliance — Kid Safe Mode for under-13 users
• Sign in with Apple and email/password login
• Built-in bad word filter for a safe community
• Report and block tools for moderation
• Profile photos and backgrounds saved to the cloud
• Direct messaging with age verification
• Search for LEGO sets and users
• Push notifications for likes, comments, and follows

---

## Permissions Used (for App Review Notes)

| Permission | Purpose |
|---|---|
| Photo Library (`NSPhotoLibraryUsageDescription`) | Uploading LEGO build photos and profile/background pictures |
| Camera (`NSCameraUsageDescription`) | Taking photos of LEGO builds directly in the app |
| Microphone (`NSMicrophoneUsageDescription`) | Video recording support for LEGO build videos |
| Push Notifications | Notifying users when their builds receive likes, comments, or new followers |

---

## App Review Notes

- BrickFeed uses Sign in with Apple and email/password authentication via Firebase Auth.
- New Apple Sign In users are directed to a username and birthday setup screen before reaching the feed.
- Kid Safe Mode is automatically enabled for all users under 13 (birthday captured at signup for COPPA compliance).
- The bad word filter is always active — cannot be disabled by users.
- All affiliate/buy links go to the official LEGO Store website (lego.com).
- Direct messaging requires the user to confirm they are 13+ before accessing.
- Privacy Policy and Terms of Service links are visible on both the login and signup screens before account creation.
- Account deletion is available in Settings and permanently removes the Firebase Auth account, Firestore user document, all posts, and all Storage files.
- Firebase credentials in GoogleService-Info.plist must be replaced with production values before final submission.
- The app handles offline gracefully — shows a "No Internet Connection" banner instead of crashing.

---

## App Store Screenshots Needed (for each iPhone size)

1. Home feed showing LEGO build posts with like/comment buttons
2. Comment sheet opened from feed
3. Profile page showing points, follower count, and build grid
4. Global Leaderboard with trophy icons and current user highlighted
5. New Post screen with LEGO set search
6. Onboarding screen showing the points system
7. Settings with Kid Safe Mode toggle and account deletion option
8. Sign up screen showing birthday picker and Privacy Policy link
