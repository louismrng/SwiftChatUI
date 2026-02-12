# SwiftChatUI

An iOS demo app showcasing two reusable SwiftUI UI components for chat applications.

## Requirements

- iOS 17+
- Xcode 16+

## Overview

The app contains two independent, protocol-driven UI components that can be integrated with any messaging backend:

- **ChatList** - Chat list/inbox UI with search, filtering, swipe actions, and unread badges
- **Conversation** - Message conversation UI with bubbles, image messages, reactions, typing indicators, and delivery status

Both components use a protocol adapter pattern with type-erased wrappers (`AnyThread`, `AnyMessage`) for SwiftUI compatibility, and injectable style providers for customizing appearance.

## Project Structure

```
MessageViewKitDemo/
├── MessageViewKitDemoApp.swift      (@main entry point)
├── MainTabView.swift                (Root TabView with tabs)
├── MockDataProvider.swift           (Simulates real-time messaging)
├── ChatListTab.swift                (Messages tab with search)
├── ConversationView.swift           (Thread conversation screen)
├── ChatList/
│   ├── Protocols/                   (Thread, ChatListStyleProvider)
│   └── SwiftUI/                     (ChatListView, ViewModels, Environment)
├── Conversation/
│   ├── Protocols/                   (Message, ConversationStyleProvider)
│   └── SwiftUI/                     (ConversationContentView, ViewModels, Environment)
└── ...
```

## Architecture

### Protocol Adapter Pattern

Integrate with any backend by implementing two protocols:

- `Thread` - Adapt your thread/roster model
- `Message` - Adapt your message model

Mock implementations (`MockThread`, `MockMessage`) are included as reference.

### Style System

Customize appearance via injectable style protocols:

- `ChatListStyleProvider` / `ConversationStyleProvider` define colors, fonts, and layout
- Apply via SwiftUI environment modifiers: `.chatListStyle()` / `.conversationStyle()`

### Demo Features

`MockDataProvider` simulates realistic messaging behavior:

- Incoming messages at 8-15 second intervals
- Typing indicators before messages arrive
- Delivery status progression: sending → delivered → read
- Reactions with emoji picker

## Build

```bash
xcodebuild -project MessageViewKitDemo.xcodeproj \
  -scheme MessageViewKitDemo \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```
