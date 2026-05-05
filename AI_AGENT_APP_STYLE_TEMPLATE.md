# AI Agent App Style Template

Use this template when asking an AI agent to build a new Flutter app that follows the visual style, UX structure, and implementation patterns of this app.

Copy this file into the new project prompt and replace every `[placeholder]`.

---

## 1. Agent Mission

Build a polished Flutter app for `[new app category]` using the same design language as this reference app:

- Warm, premium, image-led UI
- Soft off-white canvas with white cards
- Terracotta/gold primary accent
- Large rounded image surfaces with gradient overlays
- Glassmorphism navigation surfaces
- Montserrat headings and Inter body text
- Material 3, simple state, service-driven app architecture
- Smooth but restrained `flutter_animate` transitions

The result should feel calm, aspirational, touch-friendly, and visually rich. Do not copy the furniture or AI-generation business model unless the new app specifically needs it. Treat the pages below as common page patterns that can be renamed or omitted based on the new business.

---

## 2. Core Design Tokens

Use these exact tokens unless the new app has a strong brand reason to adjust them.

```dart
class AppTheme {
  static const Color background = Color(0xFFF5F5F0);      // warm off-white canvas
  static const Color surface = Color(0xFFFFFFFF);         // cards, sheets, nav surfaces
  static const Color primary = Color(0xFFD4A373);         // warm terracotta/gold CTA
  static const Color secondary = Color(0xFFFAD0C4);       // soft blush support color
  static const Color textMain = Color(0xFF4A4A4A);        // charcoal text
  static const Color textSecondary = Color(0xFF8E8E8E);   // muted gray metadata
}
```

### Color Usage

- App background: `AppTheme.background`
- Default card/sheet/input fill: `Colors.white`
- Primary CTAs, selected states, progress, links: `AppTheme.primary`
- Main text: `AppTheme.textMain`
- Captions, helper text, disabled text: `AppTheme.textSecondary`
- Image overlays: black vertical gradients at `0.5` to `0.8` opacity
- Premium/paywall panels may use dark editorial gradients, for example:

```dart
LinearGradient(
  colors: [Color(0xFF1A1A2E), Color(0xFF4B3832), Color(0xFF2C3E50)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

Avoid bright saturated palettes, flat gray enterprise styling, sharp corners, heavy outlines, and generic blue primary buttons.

---

## 3. Typography

Use Google Fonts.

```dart
textTheme: GoogleFonts.interTextTheme().copyWith(
  displayLarge: GoogleFonts.montserrat(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppTheme.textMain,
    letterSpacing: -0.5,
  ),
  headlineMedium: GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppTheme.textMain,
  ),
  titleLarge: GoogleFonts.montserrat(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTheme.textMain,
  ),
  bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppTheme.textMain),
  bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMain),
  labelMedium: GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppTheme.textSecondary,
  ),
)
```

### Text Hierarchy

- Screen title: Montserrat 24, semibold
- Hero title: Montserrat 28-36 on mobile, 36-52 on tablet
- Section title: Montserrat 18, bold
- Card title: Inter 14-16, bold or semibold
- Caption/metadata: Inter 10-13, medium
- Button text: Inter 14-18, bold
- Uppercase badges: Inter 9-10, bold, letter spacing `1.0`

---

## 4. Shape, Spacing, and Elevation

### Radius Scale

- Small badges: `8-12`
- Inputs, chips, list tiles: `20`
- Standard cards/buttons: `20-24`
- Feature cards, bottom sheets, result panels: `32`
- Large image hero/result cards: `40`
- Circular icon containers: `shape: BoxShape.circle`

### Spacing Scale

- Screen horizontal padding: `24`
- Dense tile padding: horizontal `16`, vertical `4-12`
- Card padding: `16-24`
- Bottom sheet padding: `24-32`
- Major section gap: `32-48`
- Persistent bottom CTA padding: `24` horizontal and safe-area-aware bottom padding

### Shadows

Keep shadows soft and sparse.

```dart
BoxShadow(
  color: Colors.black.withOpacity(0.03),
  blurRadius: 20,
)

BoxShadow(
  color: AppTheme.primary.withOpacity(0.3),
  blurRadius: 20,
  offset: Offset(0, 10),
)
```

Use heavier shadows only for large image/result surfaces:

```dart
BoxShadow(
  color: Colors.black.withOpacity(0.15),
  blurRadius: 30,
  offset: Offset(0, 20),
)
```

---

## 5. App Theme Setup

```dart
ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppTheme.background,
    colorScheme: const ColorScheme.light(
      primary: AppTheme.primary,
      secondary: AppTheme.secondary,
      surface: AppTheme.surface,
      onPrimary: Colors.white,
      onSurface: AppTheme.textMain,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppTheme.textMain),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppTheme.surface,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: AppTheme.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
    ),
  );
}
```

---

## 6. Navigation Pattern

Use a tabbed app shell with `IndexedStack`.

Recommended common tabs:

```text
Tab 0: Overview / Home        // discovery, dashboard, or landing content
Tab 1: Primary Action         // main business workflow
Tab 2: Collection / Activity  // saved items, orders, history, records, or inbox
Tab 3: Account / Settings     // profile, preferences, help, legal
```

Use `UniqueKey` refresh for tabs that need a clean state when revisited.

```dart
Key _primaryFlowKey = UniqueKey();

void _openPrimaryFlow() {
  setState(() {
    _currentIndex = 1;
    _primaryFlowKey = UniqueKey();
  });
}
```

Bottom nav icon style:

- Use Material icons.
- Pair outlined inactive icons with filled active icons.
- Keep labels short and business-specific: `Home`, `Create`, `Orders`, `Saved`, `Inbox`, `Profile`, `Settings`.

---

## 7. Overview Page Pattern

Use this for a home, dashboard, explore, marketplace, catalog, or landing tab. The page should be image-led and editorial when the business benefits from visual browsing; for operational apps, keep the same visual tokens but make the content denser and more task-focused.

Required sections:

1. Glass AppBar with title
2. Hero, summary, or featured `PageView` carousel
3. Horizontal category/action/status strip
4. Main content grid, list, or dashboard modules

### Glass AppBar

```dart
PreferredSize(
  preferredSize: const Size.fromHeight(70),
  child: ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AppBar(
        backgroundColor: Colors.white.withOpacity(0.5),
        title: Text(
          '[App Title]',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
      ),
    ),
  ),
)
```

### Featured / Summary Card

- `PageController(viewportFraction: 0.85)`
- Card radius `40`
- Full-bleed image with bottom black gradient
- White badge at top of text block
- White secondary CTA inside image
- Scale entrance animation
- If the app is not image-first, use a white surface card with the same radius/spacing and primary-accent status badges.

```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 10),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(40),
    image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.12),
        blurRadius: 30,
        offset: Offset(0, 15),
      ),
    ],
  ),
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(40),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
      ),
    ),
    padding: const EdgeInsets.all(32),
  ),
)
```

---

## 8. Primary Workflow Page Pattern

Use this for the app's main business flow: create, book, scan, order, submit, configure, analyze, schedule, upload, or checkout. A multi-step wizard is recommended when the workflow has several decisions; otherwise use a single focused form with the same CTA and selection patterns.

Example wizard steps:

```text
Step 1: Select or add source/input
Step 2: Choose category/type
Step 3: Configure details/options
Step 4: Review and submit/continue
```

### Progress Indicator

- Top horizontal labels: Inter 10
- Active/completed labels: primary
- Inactive labels: textSecondary
- Progress bar height: `4`
- Use animated progress.

### Source / Input Placeholder

- White card
- Radius `24`
- Subtle primary border opacity `0.05`
- Primary-tinted circular icon well
- Height responsive: about `32%` screen height on phone, `45%` on tablet

### Selection Cards

Selected state:

```dart
BoxDecoration(
  color: AppTheme.primary,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
  boxShadow: [
    BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 10),
  ],
)
```

Unselected state:

```dart
BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
)
```

### Visual Option Cards

- Horizontal list
- Image background
- Radius `28`
- Bottom black gradient overlay
- Selected border: primary, width `4`
- Special/highlighted option can use a distinct gradient, but keep it as an exception.

### Prompt Chips

- Height around `44`
- Radius `20`
- White background with subtle primary border
- Primary fill for featured/magic chip

---

## 9. Loading / Processing Overlay Pattern

Use a full-screen processing overlay for long-running tasks such as upload, booking, payment, analysis, export, sync, or AI generation.

Visual rules:

- `BackdropFilter` blur `10`
- Black overlay at `0.8`
- Centered animated magic/edit icon
- Primary glowing circle
- Thin circular progress ring
- Status text changes over time
- Progress bar with percentage and uppercase process label

```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  child: Container(
    color: Colors.black.withOpacity(0.8),
    width: double.infinity,
    height: double.infinity,
  ),
)
```

Animation timing:

- Main title fade/slide: `600ms`
- Status text fade/slide: `400ms`
- Icon shimmer: `2s`, repeated
- Ring rotation: `10s`, repeated
- Glow scale pulse: `2s`, repeated

---

## 10. Detail / Outcome Page Pattern

Use this for a result, receipt, detail, confirmation, report, product, saved item, or completed action page.

Required elements:

- Transparent AppBar over content
- Circular white icon buttons for close/download
- Large primary media/content card with radius `40`, if visual content exists
- Optional flip, before/after, gallery, summary, or detail interaction
- Metadata line in primary color
- Summary white panel with primary icon
- Glass bottom action bar
- Primary CTA plus small secondary icon actions

Bottom action bar:

```dart
ClipRRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
    ),
  ),
)
```

---

## 11. Collection / List Page Pattern

Use this for saved items, projects, orders, activity, history, inbox, documents, favorites, transactions, or any repeatable business object.

- AppBar title using `headlineMedium`
- Empty state centered with large pale icon
- Grid padding: `24`
- Phone grid: 2 columns
- Tablet grid: 3 columns
- Image card radius: `24`
- For visual objects, put metadata below the image, not inside a heavy card
- For non-visual objects, use white list rows/cards with radius `20-24`
- Long press or overflow icon for delete/actions
- Use `Hero` transitions into detail screen

Card metadata hierarchy:

```text
Category/status: labelMedium, primary
Main title/type: bodyLarge, semibold
Date/metadata: Inter 11, gray
```

---

## 12. Account / Utility Page Pattern

Use grouped white setting panels on the warm background.

Possible blocks:

- Optional upgrade/premium card if monetized
- Account/status/usage card
- Preferences section
- Business-specific utility section
- Help, legal, privacy, terms, feedback, share

Section label:

```dart
Text(
  title.toUpperCase(),
  style: GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: AppTheme.textSecondary,
  ),
)
```

Setting tile:

- `ListTile`
- Leading icon in a lightly tinted rounded square, radius `10`
- Title Inter 14 medium
- Chevron right trailing
- Section container radius `24`
- Section border black opacity `0.04`

---

## 13. Bottom Sheets and Dialogs

Bottom sheets should feel soft and premium.

- `showModalBottomSheet`
- `backgroundColor: Colors.transparent` for custom blurred sheets
- Sheet radius top `24-40`
- Add small drag handle: `40 x 4`, radius `2`
- Padding: `24` horizontal, `20-36` vertical
- Use full-width primary CTA when there is a main action

Upsell sheet pattern:

- Blur background
- White sheet opacity `0.95`
- Radius top `40`
- Primary-tinted circular icon well
- Montserrat 24 title
- Inter 14 centered body, height `1.5`
- Primary gradient CTA
- TextButton secondary action

---

## 14. Buttons and Inputs

Primary CTA:

```dart
ElevatedButton.styleFrom(
  backgroundColor: AppTheme.primary,
  foregroundColor: Colors.white,
  elevation: 0,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
)
```

Persistent step CTA:

- Height `60`
- Full width
- Disabled background `Colors.grey[300]`
- Disabled foreground `Colors.grey[500]`

Inputs:

```dart
InputDecoration(
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide.none,
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
)
```

Focused edit input:

```dart
focusedBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(20),
  borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
)
```

---

## 15. Responsive Rules

- Treat `MediaQuery.of(context).size.shortestSide > 600` as tablet.
- Constrain main content width on tablet: `maxWidth: 600`.
- Home featured carousel height:
  - phone: about `0.5 * screenHeight`, clamp `260-520`
  - tablet: about `0.6 * screenHeight`, clamp `260-700`
- Horizontal style/category cards:
  - phone width: about `0.35 * screenWidth`, clamp `110-160`
  - tablet width: about `0.25 * screenWidth`, clamp `180-240`
- Grids:
  - phone: 2 columns
  - tablet: 3 columns
- Avoid text overflow with `Expanded`, `maxLines`, and `TextOverflow.ellipsis`.

---

## 16. Motion Rules

Use `flutter_animate`.

Common patterns:

```dart
widget.animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0)
widget.animate().fadeIn(delay: 200.ms)
widget.animate().scale(begin: Offset(0.95, 0.95), duration: 600.ms)
widget.animate().slideY(begin: 1, duration: 600.ms)
```

Guidelines:

- Animate meaningful entrance, state change, and loading feedback.
- Stagger repeated items by `80-100ms`.
- Keep transitions smooth: `Curves.easeOutQuart`, `Curves.easeInOutCubic`, or default ease.
- Avoid excessive bouncing or playful effects outside loading/magic states.

---

## 17. Assets Direction

This style depends on strong visual assets.

Asset requirements for a new app:

- At least 1 onboarding image per slide if onboarding exists
- 2-4 overview hero/featured images if the app is image-led
- 4-8 category/action/status thumbnails if visual browsing exists
- 4-8 item thumbnails or placeholders if the app has a collection/list page
- 1 monetization hero image if the app has subscription/paywall
- App icon

Image treatment:

- Use real or AI-generated bitmap images when visuals are part of the product.
- Prefer bright, inspectable subject images.
- Use full-bleed image surfaces with gradient overlays.
- Avoid generic abstract SVG illustrations.

Folder convention:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/models/ # only if needed
```

---

## 18. Localization Pattern

Use Flutter generated localization.

Required:

- `flutter_localizations`
- `intl`
- `l10n.yaml`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_vi.arb` if Vietnamese is supported

All user-facing strings must come from `AppLocalizations`.

String groups:

- Common: continue, cancel, save, delete, error, loading
- Navigation labels
- Onboarding
- Overview/home/dashboard
- Primary workflow
- Detail/outcome
- Collection/list/activity
- Account/settings/utility
- Monetization/paywall only if needed
- Ads/IAP/errors if monetized

---

## 19. Architecture Pattern

Keep architecture simple unless the new app needs more.

- No Provider/Riverpod/Bloc by default
- Use `StatefulWidget`, `setState`, and `ValueNotifier`
- Services use singleton/factory pattern
- Storage service owns local persistence
- Backend service owns HTTP/API calls
- Credits/purchase/ad services own monetization state
- Analytics service owns event tracking
- Screens stay UI-focused but may coordinate simple flows

Singleton service template:

```dart
class MyService {
  static final MyService _instance = MyService._internal();
  factory MyService() => _instance;
  static MyService get instance => _instance;
  MyService._internal();

  final ValueNotifier<bool> isReady = ValueNotifier(false);
}
```

---

## 20. Suggested File Structure

```text
lib/
  main.dart
  theme/
    app_theme.dart
  l10n/
    app_en.arb
    app_vi.arb
  screens/
    onboarding_screen.dart          # optional
    monetization_screen.dart        # optional: offer/paywall/upgrade
    main_navigation.dart
    overview_screen.dart            # home/dashboard/explore
    primary_flow_screen.dart        # create/book/order/submit/etc.
    outcome_screen.dart             # result/receipt/confirmation/detail
    collection_screen.dart          # saved/orders/history/activity
    item_detail_screen.dart
    account_screen.dart             # profile/settings/help/legal
  services/
    backend_service.dart
    storage_service.dart
    credits_service.dart
    purchase_service.dart
    ad_service.dart
    analytics_service.dart
  widgets/
    compare_slider.dart
    [shared_components].dart
```

---

## 21. Dependency Baseline

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2
  google_fonts: ^6.2.1
  flutter_animate: ^4.5.1
  shared_preferences: ^2.2.2
  http: ^1.1.0
  image_picker: ^1.0.7
  url_launcher: ^6.3.0
  share_plus: ^10.1.4
  in_app_review: ^2.0.9
```

Optional by feature:

```yaml
  gal: ^1.1.0
  before_after: ^3.0.0
  percent_indicator: ^4.2.3
  shimmer: ^3.0.0
  firebase_core: ^3.13.0
  firebase_analytics: ^11.3.0
  google_mobile_ads: ^5.1.0
  app_tracking_transparency: ^2.0.6+1
  in_app_purchase: ^3.2.0
  model_viewer_plus: ^1.7.0
```

---

## 22. AI Agent Build Checklist

Before considering the app complete, verify:

- App uses `AppTheme.lightTheme` and Material 3.
- All screens use warm background, white surfaces, and primary accent consistently.
- Main tab shell uses `IndexedStack`.
- Page names and flows match the new app's business, not the reference app's furniture business.
- Overview page uses the reference visual system, whether as a dashboard, catalog, marketplace, or home page.
- Primary workflow has a clear CTA, input/selection states, and progress/review only when the flow needs it.
- Detail/outcome page uses a strong primary content area and clear bottom actions.
- Collection/list page handles empty, loading, populated, and action states.
- Account/utility page uses grouped white sections.
- Bottom sheets use rounded top corners and drag handle.
- All images have stable dimensions and responsive constraints.
- All buttons have clear enabled, disabled, and loading states.
- Text does not overflow on phone or tablet.
- All user-facing text uses localization.
- Animations are present but not noisy.
- `flutter analyze` passes.

---

## 23. Prompt To Give Another AI Agent

```text
You are building a new Flutter app named [App Name].

Follow the style guide in AI_AGENT_APP_STYLE_TEMPLATE.md exactly. Use the same visual language as the reference app: warm off-white background, white cards, terracotta primary accent, Montserrat/Inter typography, large rounded image cards, glass AppBars/bottom bars, Material 3, and smooth flutter_animate transitions.

Product concept:
[Describe the new app in 3-5 sentences.]

Required screens:
[List only the screens the new business actually needs. Use common page patterns: overview, primary workflow, detail/outcome, collection/list, account/utility, onboarding, monetization.]

Business model:
[Free / freemium credits / subscription / ads / none.]

Assets:
[List available assets or ask the agent to create placeholders in assets/images/.]

Implementation requirements:
- Use Flutter and Dart.
- Use AppTheme tokens from this template.
- Use generated localization for all user-facing strings.
- Keep architecture simple: StatefulWidget, setState, ValueNotifier, singleton services.
- Match the reference UI patterns through common page types. Do not force furniture-specific or AI-generation-specific screens into an unrelated business.
- Run flutter analyze and fix issues before finishing.
```
