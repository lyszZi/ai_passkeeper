## ADDED Requirements

### Requirement: Settings entry point exists
The system SHALL provide a Settings entry point in the main UI.

#### Scenario: Settings accessible from main view
- **WHEN** user is on the main screen
- **THEN** user SHALL be able to navigate to Settings view

### Requirement: Language switching
The system SHALL allow users to switch between supported languages.

#### Scenario: User changes language in settings
- **WHEN** user navigates to Settings and taps language option
- **THEN** system SHALL display available language options (简体中文, English)
- **AND** user can select one option
- **AND** after selection, all UI text SHALL update immediately

#### Scenario: Language preference persists across app restarts
- **WHEN** user selects a language and restarts the app
- **THEN** app SHALL remember the selected language
- **AND** display UI in that language

### Requirement: Password reset entry
The system SHALL provide a way to reset login password from settings.

#### Scenario: User initiates password reset
- **WHEN** user navigates to Settings and taps "Reset Password" option
- **THEN** system SHALL verify user's current password before allowing reset