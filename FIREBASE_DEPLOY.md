# Firebase Firestore Rules — Manual Deployment Guide

The `firestore.rules` file in this repo defines the security rules for BrickFeed.
**These rules do nothing until you manually deploy them in the Firebase Console.**

---

## Step-by-Step: Deploy Firestore Rules via Console

### 1. Open the Firebase Console
Go to: **https://console.firebase.google.com**

### 2. Select Your Project
Click on the **BrickFeed** project (or whichever project your `GoogleService-Info.plist` points to).

### 3. Navigate to Firestore Database
In the left sidebar, click **"Firestore Database"** (under the Build section).

### 4. Open the Rules Tab
At the top of the Firestore page, click the **"Rules"** tab.

### 5. Replace the Existing Rules
Delete all existing text in the rules editor and paste in the contents of `firestore.rules` from this repo:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      match /{subcollection}/{docId} {
        allow read, write: if request.auth != null;
      }
    }
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
      match /{subcollection}/{docId} {
        allow read, write: if request.auth != null;
      }
    }
    match /comments/{commentId} {
      allow read, write: if request.auth != null;
    }
    match /reports/{reportId} {
      allow create: if request.auth != null;
    }
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null;
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null;
    }
    match /moderation_logs/{logId} {
      allow create: if request.auth != null;
    }
    match /lego_sets/{setId} {
      allow read: if request.auth != null;
    }
  }
}
```

### 6. Click "Publish"
Click the blue **"Publish"** button. The rules take effect within ~1 minute.

---

## Why This Is Required

Firebase security rules live in the Firebase cloud — they are NOT read from this repo automatically. The file here is the source of truth for version control, but the actual deployed rules must be updated manually via the Console (or via the Firebase CLI).

**Rules that are blocking the app without deployment:**
- `/conversations` — needed for Direct Messages (DM list and threads)
- `/users/{userId}/{subcollection}` — needed for followers/following/notifications
- `/posts/{postId}/{subcollection}` — needed for likes
- Without these rules, queries fail silently and features show error states

---

## Verifying the Deploy Worked

After publishing, you can test rules in the **"Rules Playground"** tab:
1. Set Auth to **"Authenticated"**
2. Set Path to `/databases/(default)/documents/users`
3. Set Method to **"get"**
4. Click **"Run"** — should show **"Allow"**

---

## Firebase CLI (Alternative Method)

If you have the Firebase CLI installed:
```bash
firebase deploy --only firestore:rules
```

This requires `firebase login` and the project to be selected with `firebase use <project-id>`.
