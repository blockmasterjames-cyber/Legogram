# CLAUDE.md — Legogram iOS App

This file provides context and conventions for AI assistants working on the Legogram codebase.

---

## Project Overview

**Legogram** is a native iOS social media app for LEGO enthusiasts built with SwiftUI. Users can photograph and share their LEGO builds, follow other builders, explore LEGO sets by number, track affiliate earnings from buy links, and compete on leaderboards.

**Bundle ID:** `com.legogram.app`
**Minimum iOS:** 17.0
**Swift Tools Version:** 5.9
**Current Sprint:** 2 (functional UI + local state) → Sprint 3 (Firebase integration)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI |
| State Management | Singleton `@ObservableObject` stores |
| Backend | Firebase (Auth, Firestore, Storage, Analytics) |
| Package Manager | Swift Package Manager (Package.swift) |
| Minimum OS | iOS 17.0 |

### Firebase Modules in Use
- `FirebaseAuth` — user sign-up, sign-in, sign-out, password reset
- `FirebaseFirestore` — cloud database for users, posts, LEGO sets
- `FirebaseStorage` — image upload and URL retrieval
- `FirebaseAnalytics` — app analytics

---

## Repository Structure

```
Legogram/
├── CLAUDE.md                          # This file
├── README.md                          # Minimal project description
├── Package.swift                      # Swift Package Manager (Firebase deps)
├── LegoGram.xcodeproj/                # Xcode project
│   └── project.pbxproj                # Build config, file references
└── LegoGram/                          # All Swift source code
    ├── App/
    │   ├── LegoGramApp.swift           # @main entry point, Firebase.configure()
    │   └── ContentView.swift           # Root view → MainTabView
    ├── Core/
    │   ├── Components/
    │   │   ├── LegoGramLogo.swift      # Brand logo component
    │   │   └── LoadingView.swift       # Spinner/loading overlay
    │   ├── Navigation/
    │   │   └── MainTabView.swift       # 5-tab bottom nav (custom center button)
    │   ├── Store/
    │   │   ├── AppState.swift          # App-wide state (selected tab)
    │   │   └── PostStore.swift         # In-memory posts + images store
    │   └── Theme/
    │       ├── Colors.swift            # Brand colors (legoRed, legoYellow, etc.)
    │       └── Typography.swift        # Custom font definitions
    ├── Features/
    │   ├── Home/
    │   │   └── HomeView.swift          # Scrollable feed of PostCards
    │   ├── Search/
    │   │   └── SearchView.swift        # Search by LEGO set number
    │   ├── Post/
    │   │   ├── NewPostView.swift       # Post creation (photo + set # + description)
    │   │   └── ImagePicker.swift       # Camera & photo library access
    │   ├── Profile/
    │   │   ├── ProfileView.swift       # User portfolio (3-col grid)
    │   │   └── EditProfileView.swift   # Edit display name, bio, avatar
    │   ├── Leaderboard/
    │   │   └── LeaderboardView.swift   # Top Likes / Followers / Builders tabs
    │   └── Settings/
    │       └── SettingsView.swift      # Account preferences & sign-out
    ├── Models/
    │   ├── User.swift                  # User profile data model
    │   ├── LegoPost.swift              # Social media post model
    │   └── LegoSet.swift               # LEGO set metadata model
    ├── Services/
    │   ├── AuthService.swift           # Firebase Auth wrapper (@MainActor)
    │   └── FirebaseService.swift       # Firestore & Storage operations
    └── Resources/
        ├── Assets.xcassets/            # App icons, colors, images
        └── GoogleService-Info.plist    # Firebase config (not committed in prod)
```

---

## Architecture

### Pattern: MVVM-Lite with Singletons

Views observe singleton `ObservableObject` stores. There are no dedicated ViewModels — stores serve that purpose.

```
View → @ObservedObject → Singleton Store → Firebase / Local State
```

### Key Singletons

| Singleton | Role | Thread |
|---|---|---|
| `AppState` | Selected tab tracking | `@MainActor` |
| `PostStore` | Posts array + image cache | `@MainActor` |
| `AuthService` | Firebase Auth state | `@MainActor` |
| `FirebaseService` | Firestore + Storage calls | background (async) |

### Navigation Architecture

```
ContentView
└── MainTabView  (custom TabView with floating center button)
    ├── HomeView          (tab: .home)
    ├── SearchView        (tab: .search)
    ├── NewPostView       (tab: .newPost) ← floating red circle button
    ├── LeaderboardView   (tab: .leaderboard)
    └── ProfileView       (tab: .profile)
        ├── EditProfileView  (sheet modal)
        └── SettingsView     (sheet modal)
```

---

## Data Models

### User
```swift
User(
    id, username, displayName, bio, avatarURL,
    followerCount, followingCount, postCount, totalLikes,
    totalEarnings, isKidAccount, parentEmail, joinDate
)
```

### LegoPost
```swift
LegoPost(
    id, userId, username, imageURL,
    legoSetNumber, legoSetName, description,
    likeCount, commentCount,
    buyLink, affiliateLink, estimatedEarnings,
    postedDate, tags
)
```

### LegoSet
```swift
LegoSet(
    id, setNumber, name, theme,
    pieceCount, retailPrice,
    buyLink, imageURL, releaseYear
)
```

---

## Firestore Schema

```
users/{uid}
  ├── username, display_name, bio, avatar_url
  ├── follower_count, following_count, post_count
  ├── total_likes, total_earnings
  ├── is_kid_account, parent_email, join_date

posts/{postId}
  ├── user_id, username, image_url
  ├── lego_set_number, lego_set_name
  ├── description, like_count, comment_count
  ├── buy_link, affiliate_link, estimated_earnings
  ├── posted_date, tags

lego_sets/{setNumber}
  ├── set_number, name, theme
  ├── piece_count, retail_price
  ├── buy_link, image_url, release_year
```

---

## Design System

### Colors (`Core/Theme/Colors.swift`)
```swift
Color.legoRed      // #E3000B — primary brand red
Color.legoYellow   // #FFD700 — accent yellow
Color.darkBG       // #1A1A1A — app background
Color.cardBG       // #2C2C2C — card surfaces
Color.textPrimary  // white
Color.textSecondary // gray
```

All colors are defined as `static` extensions on `Color`. Use these — do not hardcode hex values.

### Typography (`Core/Theme/Typography.swift`)
```swift
Font.legoScreenTitle   // large, bold
Font.legoTitle         // section headers
Font.legoBody          // body text
Font.legoCaption       // captions/metadata
```

Use `.font(.legoBody)` etc. throughout — do not use system fonts directly.

### UI Conventions
- Dark theme throughout (no light mode support currently)
- Rounded font design (`Font.Design.rounded`)
- Card-based layout with `RoundedRectangle` corners (12–16pt radius)
- LEGO stud decorative patterns in profile header
- Custom tab bar with floating red center button for "New Post"

---

## State Management Patterns

```swift
// Reading from store in a view
@ObservedObject var postStore = PostStore.shared
@ObservedObject var authService = AuthService.shared

// Local ephemeral state
@State private var isLoading = false

// Persisted user preferences (UserDefaults)
@AppStorage("displayName") var displayName = ""

// Passing state down to child views
@Binding var selectedTab: Tab
```

---

## Adding New Features — Checklist

1. **Create file** in the appropriate `Features/<FeatureName>/` directory
2. **Add to Xcode project** — new `.swift` files must be referenced in `project.pbxproj`; add them via Xcode or manually edit the pbxproj
3. **Use existing theme** — colors from `Colors.swift`, fonts from `Typography.swift`
4. **Use singletons** — access `PostStore.shared`, `AuthService.shared`, `FirebaseService.shared`
5. **Add `#Preview`** block so SwiftUI Previews work
6. **Wire navigation** — if adding a new tab, update `MainTabView.swift` and the `Tab` enum in `AppState.swift`

---

## Firebase Setup (Required for Runtime)

The app will crash on launch without a valid `GoogleService-Info.plist`. To set up:

1. Create a Firebase project at console.firebase.google.com
2. Register iOS app with bundle ID `com.legogram.app`
3. Download `GoogleService-Info.plist` and replace `LegoGram/Resources/GoogleService-Info.plist`
4. Enable **Authentication** (Email/Password provider)
5. Create **Firestore** database in test mode
6. Enable **Firebase Storage**

The placeholder plist in the repo is intentionally empty — do not commit real credentials.

---

## Building & Running

```bash
# Open in Xcode
open LegoGram.xcodeproj

# Build from CLI (requires Xcode + simulator)
xcodebuild -project LegoGram.xcodeproj -scheme LegoGram -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Dependencies** are fetched automatically by Swift Package Manager when opening the project.

---

## Testing

- **No automated test suite** currently exists
- UI testing is done via **SwiftUI Previews** — every view file has a `#Preview` block
- When making UI changes, verify previews still compile and render
- Business logic lives in services/stores — unit tests would go in a new `LegoGramTests` target

---

## Xcode Project File (pbxproj) Notes

When adding new Swift files, they must be added to the Xcode project target or they won't compile. Two approaches:

1. **Via Xcode** (preferred): Drag file into Navigator, check "Add to targets: LegoGram"
2. **Via pbxproj edit** (when Xcode not available): Add entries to both `/* Begin PBXBuildFile */` and `/* Begin PBXSourcesBuildPhase */` sections — see existing entries as a template

Past issues: `AppState.swift` and `PostStore.swift` were added to the filesystem but missed from the pbxproj (fixed in PR #4).

---

## Git Conventions

- Branch naming: `claude/<description>-<session-id>` for AI branches, descriptive names for features
- Commit style: `<type>: <description>` (e.g., `feat:`, `fix:`, `refactor:`)
- PRs are merged into `master` via GitHub
- The current working branch for AI tasks is `claude/claude-md-mm8jwoxm5xde1e73-ikPcX`

### Commit History (recent)
- `fix: replace PhotoLibraryPicker with native SwiftUI PhotosPicker` (PR #5)
- `fix: add AppState.swift and PostStore.swift to Xcode project target` (PR #4)
- `feat: Sprint 2 — make LegoGram actually work!` (Sprint 2 foundation)
- `Convert to proper iOS app Xcode project` (PR #2)

---

## Common Pitfalls

1. **File not in pbxproj** — New files added outside Xcode won't be compiled. Always verify inclusion.
2. **Missing Firebase plist** — App crashes at startup without real `GoogleService-Info.plist`
3. **Main thread violations** — Firebase callbacks are on background threads; wrap UI updates in `DispatchQueue.main.async` or use `@MainActor`
4. **Image picker** — Use `PhotosPicker` (SwiftUI native, iOS 16+) not `UIImagePickerController`; `PHPickerViewController` is the UIKit fallback
5. **@AppStorage keys** — Must be consistent strings across app; mismatched keys silently return default values
6. **PostStore images** — Images are in-memory only (not persisted to disk); they reset on app restart until Firebase Storage is integrated

---

## Sprint Roadmap

| Sprint | Status | Description |
|---|---|---|
| Sprint 1 | Done | Initial Xcode project structure, basic SwiftUI scaffolding |
| Sprint 2 | Done | Functional UI, local state management, photo picker, post creation |
| Sprint 3 | Planned | Firebase integration (real auth, Firestore sync, Storage upload) |
| Sprint 4 | Future | Real LEGO set API, affiliate links, earnings tracking |
| Sprint 5 | Future | Social features (follow/unfollow, real comments, notifications) |
