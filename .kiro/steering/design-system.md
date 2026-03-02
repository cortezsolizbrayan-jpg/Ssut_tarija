---
inclusion: always
---

# Design System Rules for Flutter Project

## Project Overview
This is a Flutter educational platform application with a focus on university programs, enrollment, and payment management. The app uses Material Design with custom styling and supports Spanish localization.

## Color System

### Primary Colors
- **Primary Blue**: `Color(0xFF005BAC)` - Main brand color used for buttons, links, and primary actions
- **Light Blue**: `Color(0xFF3D8FE0)` - Used for selected states and secondary actions
- **Success Green**: `Color(0xFF4CAF50)` - Used for success states and paid status indicators

### Background Colors
- **Main Background**: `Color(0xFFEEF1F8)` - App scaffold background
- **Card Background**: `Colors.white` - Default card and form backgrounds
- **Input Background**: `Color(0xFFF8F9FB)` - Form input field backgrounds
- **Header Background**: Primary blue with 8% opacity for card headers

### Border Colors
- **Default Border**: `Color(0xFFE0E4ED)` - Standard border color for inputs and cards
- **Focused Border**: `Color(0xFF005BAC)` - Active/focused state borders
- **Light Border**: `Color(0xFFE0E0E0)` - Subtle borders for cards

### Text Colors
- **Primary Text**: `Color(0xFF333333)` - Main text content
- **Secondary Text**: `Color(0xFF666666)` - Secondary information
- **Light Text**: `Colors.grey[600]` - Tertiary information and labels

## Typography

### Font Families
- **Primary Font**: "Intel" (Inter) - Main UI font
- **Secondary Font**: "Poppins" - Used for bold headings
- **Script Font**: "Parisienne" - Used for decorative text/slogans

### Font Weights
- **Regular**: 400 (Inter-Regular.ttf)
- **Semi-Bold**: 600 (Inter-SemiBold.ttf)
- **Bold**: 700 (Poppins-Bold.ttf)

### Text Styles
- **Card Title**: 18px, weight 700, color primary text
- **Card Subtitle**: 13px, weight 500, color secondary text
- **Form Input**: 17px, color black
- **Button Text**: Default with white color
- **Info Labels**: 14px, weight 500, color secondary text
- **Info Values**: 14px, weight 600, color primary text

## Spacing System

### Standard Spacing
- **Extra Small**: 6px
- **Small**: 8px
- **Medium**: 12px
- **Large**: 16px
- **Extra Large**: 20px
- **XXL**: 24px

### Component Spacing
- **Card Padding**: 16-20px all around
- **Form Field Padding**: Responsive based on screen width (4% horizontal, 3.5% vertical)
- **Button Padding**: 12px vertical, 20px horizontal for secondary buttons

## Border Radius

### Standard Radius
- **Small**: 10px - Used for buttons
- **Medium**: 14px - Used for form inputs
- **Large**: 16px - Used for cards
- **Extra Large**: 20px - Used for program cards

## Shadows

### Card Shadows
- **Default Card**: `Colors.black.withOpacity(0.06)`, blur: 12px, offset: (0, 4)
- **Selected Card**: Primary blue with 30% opacity, blur: 16px, offset: (0, 8)
- **Form Input**: Minimal shadow for depth

## Component Patterns

### Cards
- **Background**: White
- **Border Radius**: 16px
- **Border**: 1px solid light border color
- **Shadow**: Default card shadow
- **Padding**: 16px
- **Selected State**: Blue border with enhanced shadow

### Form Inputs
- **Background**: `Color(0xFFF8F9FB)`
- **Border**: 1px solid `Color(0xFFE0E4ED)`
- **Border Radius**: 14px
- **Focused Border**: Primary blue, 1.2px width
- **Content Padding**: Responsive based on screen width

### Buttons
- **Primary Button**: Primary blue background, white text, 10px radius
- **Secondary Button**: White background, primary blue text, border
- **Disabled Button**: Grey background, white text
- **Icon Buttons**: 18px icon size

### Progress Indicators
- **Circular Progress**: 4px stroke width, primary blue color
- **Background Circle**: Light grey or white with opacity
- **Size**: 50x50px for cards

### Status Indicators
- **Success Badge**: Success green background with 10% opacity, green border with 30% opacity
- **Paid Status**: Check circle icon with success green color
- **Progress Percentage**: Bold text in center of circular progress

## Layout Patterns

### Screen Structure
- **Scaffold Background**: Main background color
- **App Bar**: Custom styling with primary blue
- **Content Padding**: 16px horizontal margins
- **Card Spacing**: 12px between cards

### Responsive Design
- **Form Field Padding**: Calculated as percentage of screen width
- **Adaptive Layouts**: Use MediaQuery for responsive spacing
- **Breakpoints**: Mobile-first approach

## Animation Guidelines

### Transitions
- **Duration**: 300ms for state changes
- **Curve**: `Curves.easeInOut` for smooth transitions
- **Card Selection**: Animated container with color and shadow changes

### Micro-interactions
- **Button Press**: Elevation changes
- **Card Tap**: Scale and shadow animations
- **Form Focus**: Border color transitions

## Accessibility

### Color Contrast
- Ensure sufficient contrast between text and background colors
- Use semantic colors for status indicators

### Touch Targets
- Minimum 44px touch target size for interactive elements
- Adequate spacing between interactive elements

### Text Scaling
- Support for system text scaling
- Maintain readability at different text sizes

## Asset Management

### Icons
- Use Material Icons for consistency
- Custom SVG icons stored in `assets/icons/`
- Icon sizes: 18px for buttons, 24px for navigation

### Images
- Avatar images in `assets/avaters/`
- Background images in `assets/Backgrounds/`
- Program-specific images in `assets/images/`

### Fonts
- Font files stored in `assets/Fonts/`
- Properly declared in pubspec.yaml with weights

## State Management Patterns

### Visual States
- **Default**: Standard appearance
- **Selected**: Enhanced styling with primary blue
- **Disabled**: Reduced opacity and grey colors
- **Loading**: Progress indicators
- **Error**: Red accent colors for validation

### Interactive States
- **Hover**: Subtle elevation increase (web/desktop)
- **Pressed**: Slight scale reduction
- **Focused**: Border color change to primary blue

## Implementation Guidelines

### When Creating New Components
1. Follow the established color system
2. Use consistent spacing values
3. Apply appropriate border radius
4. Include proper shadows for depth
5. Ensure responsive behavior
6. Add smooth animations for state changes
7. Maintain accessibility standards

### Code Organization
- Keep design tokens in constants files
- Create reusable widget components
- Use consistent naming conventions
- Document component usage and variants

## Figma Integration Guidelines

### Design-to-Code Workflow
- **Figma URL Format**: Extract fileKey and nodeId from URLs like `https://figma.com/design/:fileKey/:fileName?node-id=1-2`
- **Code Generation**: Use Figma power to generate Flutter widgets from designs
- **Design Tokens**: Extract design variables from Figma and map to Flutter constants
- **Asset Export**: Use Figma power to export images and icons directly to `assets/` folders

### Code Connect Mapping
- **Component Mapping**: Link Figma components to Flutter widgets using Code Connect
- **File Patterns**: Monitor `lib/features/**/widgets/*.dart` and `lib/features/**/screens/*.dart` for component updates
- **Naming Convention**: Match Figma component names to Flutter widget class names
- **Framework Label**: Use "Flutter" for all Code Connect mappings

### Figma-to-Flutter Translation Rules
1. **Colors**: Convert Figma hex colors to Flutter `Color(0xFFHEXCODE)` format
2. **Typography**: Map Figma text styles to Flutter TextStyle with proper font families
3. **Spacing**: Convert Figma spacing to Flutter EdgeInsets and SizedBox
4. **Border Radius**: Map Figma corner radius to Flutter BorderRadius.circular()
5. **Shadows**: Convert Figma drop shadows to Flutter BoxShadow
6. **Layout**: Translate Figma auto-layout to Flutter Column/Row/Flex widgets

### Component Architecture Integration
- **Widget Structure**: Follow existing Flutter widget patterns in the codebase
- **State Management**: Integrate with existing provider patterns
- **Responsive Design**: Use MediaQuery for responsive layouts from Figma designs
- **Material Design**: Ensure Figma designs align with Material Design principles

### Asset Management from Figma
- **Icons**: Export SVG icons to `assets/icons/` and reference in Flutter
- **Images**: Export images to appropriate `assets/` subfolders
- **Fonts**: Ensure Figma fonts match those declared in pubspec.yaml
- **Optimization**: Compress exported assets for mobile performance

### Quality Assurance
- **Visual Parity**: Validate Flutter implementation matches Figma design exactly
- **Responsive Behavior**: Test across different screen sizes
- **Accessibility**: Ensure semantic labels and proper contrast ratios
- **Performance**: Optimize for Flutter's rendering pipeline

### Automated Workflows
- **Hook Integration**: Use Figma Code Connect hook for automatic component mapping
- **Design Updates**: Monitor Figma changes and update Flutter code accordingly
- **Screenshot Validation**: Use Figma screenshots to validate implementation accuracy

This design system ensures consistency across the educational platform while maintaining the professional, accessible, and user-friendly interface that supports the app's core functionality of program management, enrollment, and payments.