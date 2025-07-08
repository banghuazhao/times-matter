# TimesMatter ⏰

A beautiful and intuitive iOS countdown app built with SwiftUI that helps you track important events and milestones in your life.

## 📱 About

TimesMatter is a modern iOS application designed to help users create and manage countdown timers for important events. Whether it's a birthday, vacation, project deadline, or any significant milestone, TimesMatter provides a clean and elegant way to keep track of time.

## ✨ Features

- **Countdown Management**: Create and manage multiple countdown timers
- **Categories**: Organize countdowns with custom categories
- **Customization**: Personalize countdowns with custom icons, colors, and titles
- **Favorites**: Mark important countdowns as favorites for quick access
- **Archive**: Archive completed or old countdowns
- **Modern UI**: Built with SwiftUI for a native iOS experience
- **Data Persistence**: Uses SharingGRDB for reliable data storage

## 🛠 Tech Stack

- **Framework**: SwiftUI
- **Language**: Swift
- **Database**: SharingGRDB
- **Minimum iOS Version**: iOS 17.0+
- **Target iOS Version**: iOS 18.0+ (with backward compatibility)

## 📋 Requirements

- Xcode 16.2+
- iOS 17.0+
- macOS 14.0+ (for development)

## 🚀 Getting Started

### Prerequisites

1. Make sure you have Xcode 16.2 or later installed
2. Ensure you have a valid Apple Developer account (for device testing)

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/times-matter.git
   cd times-matter
   ```

2. Open the project in Xcode
   ```bash
   open TimesMatter.xcodeproj
   ```

3. Select your target device or simulator

4. Build and run the project (⌘ + R)

## 📁 Project Structure

```
TimesMatter/
├── App/
│   └── TimesMatterApp.swift          # Main app entry point
├── Components/
│   ├── Countdown/
│   │   └── CountdownList.swift       # Countdown list view
│   └── Me/
│       └── Me.swift                  # User profile view
├── Model/
│   ├── Countdown.swift               # Countdown data model
│   └── Category.swift                # Category data model
├── Service/
│   ├── CountdownStore.swift          # Countdown data management
│   └── CategoryStore.swift           # Category data management
├── Utilies/
│   ├── Extension/
│   │   └── Color+Extensions.swift    # Color utilities
│   ├── HashableObject.swift          # Hashable object utilities
│   └── Schema.swift                  # Database schema
└── Assets.xcassets/                  # App assets and icons
```

## 🎨 Features in Detail

### Countdown Management
- Create new countdown timers with custom titles
- Set custom icons and colors for visual distinction
- Mark countdowns as favorites for quick access
- Archive completed countdowns

### Categories
- Organize countdowns into custom categories
- Easy filtering and organization

### User Interface
- Modern SwiftUI interface
- Tab-based navigation
- Responsive design for different iOS versions
- Native iOS design patterns

## 🔧 Development

### Architecture
The app follows a clean architecture pattern with:
- **Models**: Data structures for Countdown and Category
- **Views**: SwiftUI views for the user interface
- **Services**: Data management and business logic
- **Utilities**: Helper functions and extensions

### Database
The app uses SharingGRDB for data persistence, providing:
- Reliable data storage
- Type-safe database operations
- Efficient querying capabilities

## 🤝 Contributing

We welcome contributions! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Contributing Guidelines

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style
- Follow Swift style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Ensure code is properly formatted

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with SwiftUI and SharingGRDB
- Icons and assets designed for iOS
- Thanks to the SwiftUI and iOS development community

## 📞 Support

If you have any questions or need support, please:
1. Check the existing issues
2. Create a new issue with a detailed description
3. Contact the development team

---

Made with ❤️ for iOS users who value their time. 