import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Oneiro'**
  String get appTitle;

  /// The description of the application
  ///
  /// In en, this message translates to:
  /// **'Dream analysis and tracking app'**
  String get appDescription;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signUpHere.
  ///
  /// In en, this message translates to:
  /// **'Sign up here'**
  String get signUpHere;

  /// No description provided for @loginHere.
  ///
  /// In en, this message translates to:
  /// **'Login here'**
  String get loginHere;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @dreamAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Dream Analysis'**
  String get dreamAnalysis;

  /// No description provided for @analyzeDream.
  ///
  /// In en, this message translates to:
  /// **'Analyze Dream'**
  String get analyzeDream;

  /// No description provided for @dreamDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe your dream...'**
  String get dreamDescription;

  /// No description provided for @analyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyze;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @interpretation.
  ///
  /// In en, this message translates to:
  /// **'Interpretation'**
  String get interpretation;

  /// No description provided for @saveDream.
  ///
  /// In en, this message translates to:
  /// **'Save Dream'**
  String get saveDream;

  /// No description provided for @dreamSaved.
  ///
  /// In en, this message translates to:
  /// **'Dream saved successfully'**
  String get dreamSaved;

  /// No description provided for @dreamDeleted.
  ///
  /// In en, this message translates to:
  /// **'Dream deleted successfully'**
  String get dreamDeleted;

  /// No description provided for @noDreamsYet.
  ///
  /// In en, this message translates to:
  /// **'No dreams yet'**
  String get noDreamsYet;

  /// No description provided for @startAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Start analyzing your dreams to see them here'**
  String get startAnalyzing;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get noHistory;

  /// No description provided for @yourDreamHistory.
  ///
  /// In en, this message translates to:
  /// **'Your dream history will appear here'**
  String get yourDreamHistory;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @aboutOneiro.
  ///
  /// In en, this message translates to:
  /// **'About Oneiro'**
  String get aboutOneiro;

  /// No description provided for @oneiroDescription.
  ///
  /// In en, this message translates to:
  /// **'Oneiro is an AI-powered dream analysis application that helps you understand the meaning behind your dreams.'**
  String get oneiroDescription;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error occurred'**
  String get networkError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @dreamTitle.
  ///
  /// In en, this message translates to:
  /// **'Dream Title'**
  String get dreamTitle;

  /// No description provided for @dreamDate.
  ///
  /// In en, this message translates to:
  /// **'Dream Date'**
  String get dreamDate;

  /// No description provided for @dreamTags.
  ///
  /// In en, this message translates to:
  /// **'Dream Tags'**
  String get dreamTags;

  /// No description provided for @addTags.
  ///
  /// In en, this message translates to:
  /// **'Add tags...'**
  String get addTags;

  /// No description provided for @searchDreams.
  ///
  /// In en, this message translates to:
  /// **'Search dreams...'**
  String get searchDreams;

  /// No description provided for @emotionalState.
  ///
  /// In en, this message translates to:
  /// **'Emotional State'**
  String get emotionalState;

  /// No description provided for @dreamType.
  ///
  /// In en, this message translates to:
  /// **'Dream Type'**
  String get dreamType;

  /// No description provided for @lucidDream.
  ///
  /// In en, this message translates to:
  /// **'Lucid Dream'**
  String get lucidDream;

  /// No description provided for @recurringDream.
  ///
  /// In en, this message translates to:
  /// **'Recurring Dream'**
  String get recurringDream;

  /// No description provided for @nightmare.
  ///
  /// In en, this message translates to:
  /// **'Nightmare'**
  String get nightmare;

  /// No description provided for @normalDream.
  ///
  /// In en, this message translates to:
  /// **'Normal Dream'**
  String get normalDream;

  /// No description provided for @veryHappy.
  ///
  /// In en, this message translates to:
  /// **'Very Happy'**
  String get veryHappy;

  /// No description provided for @happy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get happy;

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// No description provided for @sad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get sad;

  /// No description provided for @verySad.
  ///
  /// In en, this message translates to:
  /// **'Very Sad'**
  String get verySad;

  /// No description provided for @anxious.
  ///
  /// In en, this message translates to:
  /// **'Anxious'**
  String get anxious;

  /// No description provided for @excited.
  ///
  /// In en, this message translates to:
  /// **'Excited'**
  String get excited;

  /// No description provided for @confused.
  ///
  /// In en, this message translates to:
  /// **'Confused'**
  String get confused;

  /// No description provided for @dreamInsights.
  ///
  /// In en, this message translates to:
  /// **'Dream Insights'**
  String get dreamInsights;

  /// No description provided for @psychologicalAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Psychological Analysis'**
  String get psychologicalAnalysis;

  /// No description provided for @symbolicMeaning.
  ///
  /// In en, this message translates to:
  /// **'Symbolic Meaning'**
  String get symbolicMeaning;

  /// No description provided for @emotionalImpact.
  ///
  /// In en, this message translates to:
  /// **'Emotional Impact'**
  String get emotionalImpact;

  /// No description provided for @recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup Data'**
  String get backupData;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'Restore Data'**
  String get restoreData;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get deleteAccountWarning;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Oneiro'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Discover the hidden meanings in your dreams with AI-powered analysis'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Track Your Dreams'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Keep a detailed record of your dreams and their interpretations'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Understand Yourself'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'Gain insights into your subconscious mind and emotional state'**
  String get onboardingSubtitle3;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @notificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermission;

  /// No description provided for @notificationPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'We need notification permission to send you dream reminders and updates'**
  String get notificationPermissionDescription;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @dreamInspiration.
  ///
  /// In en, this message translates to:
  /// **'Dream Inspiration'**
  String get dreamInspiration;

  /// No description provided for @dreamAnalysisCompleted.
  ///
  /// In en, this message translates to:
  /// **'Dream analysis completed'**
  String get dreamAnalysisCompleted;

  /// No description provided for @dreamQuote1.
  ///
  /// In en, this message translates to:
  /// **'Dreams are the secret mirror that whispers what the soul cannot say while awake.'**
  String get dreamQuote1;

  /// No description provided for @dreamQuote2.
  ///
  /// In en, this message translates to:
  /// **'Dreams are the poetry that the subconscious writes in darkness.'**
  String get dreamQuote2;

  /// No description provided for @dreamQuote3.
  ///
  /// In en, this message translates to:
  /// **'Dreams are the free journey of the mind liberated from the chains of time and space.'**
  String get dreamQuote3;

  /// No description provided for @dreamQuote4.
  ///
  /// In en, this message translates to:
  /// **'Dreams are the silent stage of truths hidden behind the curtain of the mind.'**
  String get dreamQuote4;

  /// No description provided for @dreamQuote5.
  ///
  /// In en, this message translates to:
  /// **'Dreams are an invisible language coming from the depths of the heart.'**
  String get dreamQuote5;

  /// No description provided for @dreamQuote6.
  ///
  /// In en, this message translates to:
  /// **'Dreams are a mysterious painting drawn by the mind at night.'**
  String get dreamQuote6;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
