# ChatCycle

ChatCycle brings intelligent conversations to your fingertips! Whether you’re curious, creative, or just want to explore ideas, jump into any discussion and let AI amplify your thoughts. Discover, share, and connect — all in one place.

## Key Features

- **Real-time AI streaming** powered by OpenRouter with smooth, incremental responses.
- **Home page quick prompt** that seamlessly hands off your first question to the chat view.
- **Persistent chat history** stored locally on-device with instant load times (no external DB required).
- **Sidebar history** with date groupings, filters, “New Chat” action, and per-chat delete buttons.
- **In-chat delete**—remove the active conversation directly from the chat app bar.
- **File attachment entry point** ready for future uploads.

## Prerequisites

- Flutter 3.24+ (or the version specified in `pubspec.yaml`)
- An OpenRouter API key (create one at [https://openrouter.ai](https://openrouter.ai))

## Running the App

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Provide your OpenRouter API key at runtime. This keeps the key out of source control:
   ```bash
   flutter run -d emulator-5554 --dart-define=OPENROUTER_API_KEY=sk-or-xxxxxxxx
   ```

   > Replace `emulator-5554` with any connected device ID. The key is never stored in the repo; add it only when running or debugging locally.

3. (Optional) For release builds use the same `--dart-define` flag with `flutter build ...`.

## Managing Chats

- **Start from Home**: Type a message on the home screen to create a brand-new chat and jump straight into the conversation.
- **Sidebar history**: Tap the menu icon to open the drawer, filter by date, start fresh via “New Chat,” or delete any old thread using the trash icon.
- **Chat app bar**: The delete icon removes the currently open chat and immediately creates a fresh session.

## Security Notes

- The OpenRouter key is pulled at runtime via `String.fromEnvironment('OPENROUTER_API_KEY')`. If the key is missing, the app shows an error instead of making unsecured calls.
- Never check API keys into Git; rely on the `--dart-define` mechanism or your IDE’s run configuration.

## Folder Structure

- `ai_app/lib/screens`: UI for home, chat, drawer, etc.
- `ai_app/lib/services`: `openrouter_stream_service.dart` and `chat_storage.dart` for API + local persistence.
- `ai_app/lib/models`: `ChatSession` data model with JSON helpers.

Happy chatting! Let me know if you’d like help wiring additional providers (Firebase, Supabase, etc.) in the future.
