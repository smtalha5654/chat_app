# Chat App

A one-to-one chat app for Android and iOS. Users sign in with email and password, see other registered people, and message them in realtime. Own messages can be edited or deleted. The chat list shows a last-message preview and can be used offline from a local cache.

## Stack

- Flutter 3.38.9
- Firebase Auth (email / password)
- Cloud Firestore
- BLoC + Clean Architecture
- get_it
- Hive (user list and chat previews)
- connectivity_plus

Firebase project: `chat-app-aa999`  
Android / iOS application id: `com.app.chatapp`

## Run

```bash
flutter pub get
flutter run
```

Create two accounts on two devices or simulators to try a real conversation.

## Firebase setup

The app is already wired with FlutterFire (`lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`). In the [Firebase console](https://console.firebase.google.com/project/chat-app-aa999) you still need:

1. **Authentication** → Sign-in method → enable Email/Password.
2. **Firestore** → create the `(default)` database if it is missing.
3. **Rules** → paste `firestore.rules` and Publish.

Rules in short: signed-in users can read the user list, write only their own profile, and read/write only chats they belong to.

The user list query is `participants array-contains <uid>`. Last-message sorting is done on the device, so you should not need a composite index.

## What is in scope

- Register, log in, session restore, log out
- User list with search, pull-to-refresh, last message preview
- Realtime 1:1 chat
- Edit / delete own messages (deleted for everyone)
- Edit display name (email is read-only)
- Offline cache, timeout, empty and no-internet states
- Light and dark theme (follows the system)

## Layout

```
lib/
  main.dart
  injection.dart          # get_it
  core/                   # theme, routing, errors, shared widgets
  features/
    auth/
    users/
    chat/
    profile/
```

Each feature has `data`, `domain`, and `presentation`. Domain talks to repositories through use cases. Failures come back as `Either<Failure, T>`.

Chat documents live at `chats/{uidA_uidB}` with a `messages` subcollection. `uidA_uidB` is the two user ids sorted alphabetically.

Hive boxes:

- `users_cache` — last user list
- `chat_previews` — last message per peer, keyed by the signed-in user

Both are replaced on a successful fetch and cleared on logout.

## Tests

```bash
flutter test
```

Coverage is intentionally small: validators, chat id, message bubble, login validation, and UsersBloc filtering.

## Troubleshooting

- **Empty user list after sign up.** Confirm the `(default)` Firestore database exists and the published rules match `firestore.rules`.
- **Permission denied on the first message.** Publish the rules file, then try again. The first send creates the chat document and the first message in one batch.
- **SHA-1 / Google Play services warnings on Android.** They are unrelated to email/password sign-in.
- **Changes to `injection.dart` or Hive boxes.** Do a full restart, not a hot reload.
