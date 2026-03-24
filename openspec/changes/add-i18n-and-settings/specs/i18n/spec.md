## ADDED Requirements

### Requirement: Application supports multiple languages
The system SHALL support Simplified Chinese (简体中文) and English languages for all user-facing text.

#### Scenario: System detects device language on first launch
- **WHEN** user launches the app for the first time
- **THEN** system SHALL detect the device's current language
- **IF** device language is Chinese (zh-Hans, zh-Hant), set app language to 简体中文
- **ELSE** set app language to English

#### Scenario: User manually selects language
- **WHEN** user navigates to Settings and selects a language
- **THEN** system SHALL immediately update all UI text to the selected language
- **AND** save the preference to local storage

#### Scenario: App respects stored language preference
- **WHEN** user launches the app (not first time)
- **THEN** system SHALL load the stored language preference
- **AND** display all UI text in that language

### Requirement: Localized string management
The system SHALL provide a centralized mechanism to manage all localized strings.

#### Scenario: All UI text comes from localization files
- **WHEN** any UI component displays text
- **THEN** system SHALL fetch the text from the appropriate localization file based on current language setting

#### Scenario: Language files are properly organized
- **WHEN** developer needs to add new text
- **THEN** developer SHALL add the text to both zh-Hans.lproj/Localizable.strings and en.lproj/Localizable.strings with the same key