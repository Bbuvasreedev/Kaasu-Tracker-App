import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('ta'),
    Locale('te'),
    Locale('ml'),
    Locale('kn'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'KaasuTracker'**
  String get appTitle;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'KaasuTracker'**
  String get splashTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your money, made clear.'**
  String get splashSubtitle;

  /// No description provided for @continueToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueToDashboard;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your finances at a glance.'**
  String get dashboardPlaceholder;

  /// No description provided for @additionalFundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional funds'**
  String get additionalFundsTitle;

  /// No description provided for @borrowedFundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Borrowed funds'**
  String get borrowedFundsTitle;

  /// No description provided for @fundsReceived.
  ///
  /// In en, this message translates to:
  /// **'Total received'**
  String get fundsReceived;

  /// No description provided for @fundsUsed.
  ///
  /// In en, this message translates to:
  /// **'Allocated to expenses'**
  String get fundsUsed;

  /// No description provided for @fundsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get fundsRemaining;

  /// No description provided for @addFund.
  ///
  /// In en, this message translates to:
  /// **'Add funds'**
  String get addFund;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @sourceDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceDescriptionLabel;

  /// No description provided for @purposeLabel.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purposeLabel;

  /// No description provided for @repaymentBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding repayment balance'**
  String get repaymentBalanceLabel;

  /// No description provided for @saveFund.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveFund;

  /// No description provided for @updateFund.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateFund;

  /// No description provided for @deactivateFund.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateFund;

  /// No description provided for @emptyFunds.
  ///
  /// In en, this message translates to:
  /// **'No funds recorded for this month.'**
  String get emptyFunds;

  /// No description provided for @fundSaved.
  ///
  /// In en, this message translates to:
  /// **'Funds saved successfully.'**
  String get fundSaved;

  /// No description provided for @fundDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Fund deactivated.'**
  String get fundDeactivated;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get amountRequired;

  /// No description provided for @sourceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a source description.'**
  String get sourceRequired;

  /// No description provided for @purposeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a purpose.'**
  String get purposeRequired;

  /// No description provided for @fundsFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund details'**
  String get fundsFormTitle;

  /// No description provided for @salarySpent.
  ///
  /// In en, this message translates to:
  /// **'Salary spent'**
  String get salarySpent;

  /// No description provided for @salaryFundedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Salary-funded expenses'**
  String get salaryFundedExpenses;

  /// No description provided for @remainingSalary.
  ///
  /// In en, this message translates to:
  /// **'Remaining current-month salary'**
  String get remainingSalary;

  /// No description provided for @additionalFundsUsed.
  ///
  /// In en, this message translates to:
  /// **'Additional funds used'**
  String get additionalFundsUsed;

  /// No description provided for @additionalFundsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Additional funds available'**
  String get additionalFundsAvailable;

  /// No description provided for @carryForwardUsed.
  ///
  /// In en, this message translates to:
  /// **'Carry-forward used'**
  String get carryForwardUsed;

  /// No description provided for @borrowedFundsUsed.
  ///
  /// In en, this message translates to:
  /// **'Borrowed funds used'**
  String get borrowedFundsUsed;

  /// No description provided for @actualExpenses.
  ///
  /// In en, this message translates to:
  /// **'Actual expenses'**
  String get actualExpenses;

  /// No description provided for @monthlyEmiScheduled.
  ///
  /// In en, this message translates to:
  /// **'Monthly EMI scheduled'**
  String get monthlyEmiScheduled;

  /// No description provided for @nextEmiDue.
  ///
  /// In en, this message translates to:
  /// **'Next EMI due'**
  String get nextEmiDue;

  /// No description provided for @emiSchedule.
  ///
  /// In en, this message translates to:
  /// **'EMI schedule'**
  String get emiSchedule;

  /// No description provided for @emiScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get emiScheduled;

  /// No description provided for @emiDueToday.
  ///
  /// In en, this message translates to:
  /// **'EMI due today'**
  String get emiDueToday;

  /// No description provided for @noScheduledEmis.
  ///
  /// In en, this message translates to:
  /// **'No active EMI schedules'**
  String get noScheduledEmis;

  /// No description provided for @emiPaymentNotTracked.
  ///
  /// In en, this message translates to:
  /// **'Payment status not tracked'**
  String get emiPaymentNotTracked;

  /// No description provided for @unfundedOverspending.
  ///
  /// In en, this message translates to:
  /// **'Unfunded overspending'**
  String get unfundedOverspending;

  /// No description provided for @summaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Monthly summary could not be loaded.'**
  String get summaryUnavailable;

  /// No description provided for @summaryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading monthly summary...'**
  String get summaryLoading;

  /// No description provided for @salarySetupRequired.
  ///
  /// In en, this message translates to:
  /// **'Monthly salary is not configured. Set it from the funds menu.'**
  String get salarySetupRequired;

  /// No description provided for @emptyMonth.
  ///
  /// In en, this message translates to:
  /// **'No financial activity for this month.'**
  String get emptyMonth;

  /// No description provided for @establishCarryForward.
  ///
  /// In en, this message translates to:
  /// **'Establish carry-forward'**
  String get establishCarryForward;

  /// No description provided for @carryForwardEstablished.
  ///
  /// In en, this message translates to:
  /// **'Carry-forward balance established.'**
  String get carryForwardEstablished;

  /// No description provided for @carryForwardAvailable.
  ///
  /// In en, this message translates to:
  /// **'Eligible previous-month balance'**
  String get carryForwardAvailable;

  /// No description provided for @salaryAvailable.
  ///
  /// In en, this message translates to:
  /// **'Current-month salary balance'**
  String get salaryAvailable;

  /// No description provided for @expenseDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense details'**
  String get expenseDetailsTitle;

  /// No description provided for @expenseDetailsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Expense not found.'**
  String get expenseDetailsNotFound;

  /// No description provided for @expenseDetailsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this expense.'**
  String get expenseDetailsLoadError;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete expense'**
  String get deleteExpense;

  /// No description provided for @confirmExpenseDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense?'**
  String get confirmExpenseDeleteMessage;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted.'**
  String get expenseDeleted;

  /// No description provided for @expenseFundingBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Funding allocation'**
  String get expenseFundingBreakdown;

  /// No description provided for @unfundedAmount.
  ///
  /// In en, this message translates to:
  /// **'Unfunded amount'**
  String get unfundedAmount;

  /// No description provided for @manageExpenseFunding.
  ///
  /// In en, this message translates to:
  /// **'Manage funding'**
  String get manageExpenseFunding;

  /// No description provided for @allocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense funding'**
  String get allocationTitle;

  /// No description provided for @expenseAmount.
  ///
  /// In en, this message translates to:
  /// **'Expense amount'**
  String get expenseAmount;

  /// No description provided for @fundingSource.
  ///
  /// In en, this message translates to:
  /// **'Funding source'**
  String get fundingSource;

  /// No description provided for @sourceAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get sourceAvailable;

  /// No description provided for @assignedAmount.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assignedAmount;

  /// No description provided for @unallocatedAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining unallocated'**
  String get unallocatedAmount;

  /// No description provided for @saveAllocation.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveAllocation;

  /// No description provided for @allocationSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense funding updated.'**
  String get allocationSaved;

  /// No description provided for @allocationExceedsBalance.
  ///
  /// In en, this message translates to:
  /// **'An allocation exceeds the available balance.'**
  String get allocationExceedsBalance;

  /// No description provided for @allocationExceedsExpense.
  ///
  /// In en, this message translates to:
  /// **'Allocations must equal the expense amount.'**
  String get allocationExceedsExpense;

  /// No description provided for @duplicateFundingSource.
  ///
  /// In en, this message translates to:
  /// **'A funding source is listed more than once.'**
  String get duplicateFundingSource;

  /// No description provided for @allocationVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'The server did not confirm the requested allocation. Your changes are still on this screen.'**
  String get allocationVerificationFailed;

  /// No description provided for @expenseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Expense is unavailable for funding.'**
  String get expenseUnavailable;

  /// No description provided for @noFundingSources.
  ///
  /// In en, this message translates to:
  /// **'No funding sources are available for this month.'**
  String get noFundingSources;

  /// No description provided for @allFunds.
  ///
  /// In en, this message translates to:
  /// **'All periods'**
  String get allFunds;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @serverSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get serverSessionExpired;

  /// No description provided for @serverForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get serverForbidden;

  /// No description provided for @serverNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested record could not be found.'**
  String get serverNotFound;

  /// No description provided for @serverFailure.
  ///
  /// In en, this message translates to:
  /// **'The service is temporarily unavailable. Please try again.'**
  String get serverFailure;

  /// No description provided for @serverRequestFailure.
  ///
  /// In en, this message translates to:
  /// **'The request could not be completed. Please try again.'**
  String get serverRequestFailure;

  /// No description provided for @fundsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fund sources'**
  String get fundsTitle;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @baseMonthlySalary.
  ///
  /// In en, this message translates to:
  /// **'Monthly base salary'**
  String get baseMonthlySalary;

  /// No description provided for @combinedRemaining.
  ///
  /// In en, this message translates to:
  /// **'Total remaining funds'**
  String get combinedRemaining;

  /// No description provided for @noNextEmi.
  ///
  /// In en, this message translates to:
  /// **'No next EMI scheduled'**
  String get noNextEmi;

  /// No description provided for @setMonthlySalary.
  ///
  /// In en, this message translates to:
  /// **'Set monthly salary'**
  String get setMonthlySalary;

  /// No description provided for @salarySaved.
  ///
  /// In en, this message translates to:
  /// **'Monthly salary saved.'**
  String get salarySaved;

  /// No description provided for @inactiveFundStatus.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveFundStatus;

  /// No description provided for @invalidExpenseId.
  ///
  /// In en, this message translates to:
  /// **'Invalid expense identifier.'**
  String get invalidExpenseId;

  /// No description provided for @carryForwardRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining carry-forward balance'**
  String get carryForwardRemaining;

  /// No description provided for @salaryAllocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated from current-month salary'**
  String get salaryAllocated;

  /// No description provided for @combinedBalanceDetail.
  ///
  /// In en, this message translates to:
  /// **'Across all funding sources'**
  String get combinedBalanceDetail;

  /// No description provided for @percentUsed.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String percentUsed(String percent);

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get navAnalytics;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to manage your finances.'**
  String get signInPrompt;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordMinLength;

  /// No description provided for @duplicateAccountPossible.
  ///
  /// In en, this message translates to:
  /// **'An account with this email may already exist. Try logging in.'**
  String get duplicateAccountPossible;

  /// No description provided for @emailConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Registration submitted. Please check your email to confirm your account.'**
  String get emailConfirmation;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get accountCreated;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully.'**
  String get signedIn;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the authentication service. Check your connection and try again.'**
  String get authNetworkError;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a while before trying again.'**
  String get tooManyAttempts;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get invalidCredentials;

  /// No description provided for @emailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email address before signing in.'**
  String get emailNotConfirmed;

  /// No description provided for @accountAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Please log in.'**
  String get accountAlreadyExists;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password and try again.'**
  String get weakPassword;

  /// No description provided for @accountCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create your account. Please try again.'**
  String get accountCreationFailed;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Please check your connection and try again.'**
  String get signInFailed;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found: {path}'**
  String pageNotFound(String path);

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @recentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Recent Expenses'**
  String get recentExpenses;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @collapseRecentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Collapse recent expenses'**
  String get collapseRecentExpenses;

  /// No description provided for @expandRecentExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expand recent expenses'**
  String get expandRecentExpenses;

  /// No description provided for @collapseEmiSchedule.
  ///
  /// In en, this message translates to:
  /// **'Collapse EMI schedule'**
  String get collapseEmiSchedule;

  /// No description provided for @expandEmiSchedule.
  ///
  /// In en, this message translates to:
  /// **'Expand EMI schedule'**
  String get expandEmiSchedule;

  /// No description provided for @recentExpensesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent expenses'**
  String get recentExpensesLoadError;

  /// No description provided for @noExpensesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded yet'**
  String get noExpensesRecorded;

  /// No description provided for @startExpenseTracking.
  ///
  /// In en, this message translates to:
  /// **'Tap + Add expense to start tracking.'**
  String get startExpenseTracking;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load analytics'**
  String get analyticsLoadError;

  /// No description provided for @monthlyOverview.
  ///
  /// In en, this message translates to:
  /// **'Monthly Overview'**
  String get monthlyOverview;

  /// No description provided for @noExpensesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No expenses this month'**
  String get noExpensesThisMonth;

  /// No description provided for @startTrackingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Start tracking to see your spending habits!'**
  String get startTrackingExpenses;

  /// No description provided for @expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by Category'**
  String get expensesByCategory;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdown;

  /// No description provided for @addExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpenseTitle;

  /// No description provided for @spendQuestion.
  ///
  /// In en, this message translates to:
  /// **'How much did you spend?'**
  String get spendQuestion;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilities;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @expenseDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What was this expense for?'**
  String get expenseDescriptionHint;

  /// No description provided for @shortDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a short description.'**
  String get shortDescriptionRequired;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scanReceipt;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo (Camera)'**
  String get takePhoto;

  /// No description provided for @chooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseGallery;

  /// No description provided for @chooseDocument.
  ///
  /// In en, this message translates to:
  /// **'Choose Document'**
  String get chooseDocument;

  /// No description provided for @receiptPreview.
  ///
  /// In en, this message translates to:
  /// **'Receipt preview'**
  String get receiptPreview;

  /// No description provided for @removeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Remove receipt'**
  String get removeReceipt;

  /// No description provided for @analyzeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Analyze receipt'**
  String get analyzeReceipt;

  /// No description provided for @receiptSuggestionsNotice.
  ///
  /// In en, this message translates to:
  /// **'AI suggestions are unverified. Review and edit the expense fields before saving.'**
  String get receiptSuggestionsNotice;

  /// No description provided for @receiptAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not analyze this receipt. Check your connection and try again.'**
  String get receiptAnalysisFailed;

  /// No description provided for @receiptReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected receipt. Choose another file and try again.'**
  String get receiptReadError;

  /// No description provided for @receiptEmptyFile.
  ///
  /// In en, this message translates to:
  /// **'The selected receipt file is empty.'**
  String get receiptEmptyFile;

  /// No description provided for @receiptFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The receipt file exceeds the 10 MB limit.'**
  String get receiptFileTooLarge;

  /// No description provided for @receiptUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPEG, PNG, or WebP receipt image, or a PDF document.'**
  String get receiptUnsupportedFormat;

  /// No description provided for @receiptInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'The selected receipt file is invalid or damaged.'**
  String get receiptInvalidFile;

  /// No description provided for @receiptPdfUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The current receipt analysis service accepts images only; PDF analysis is not enabled.'**
  String get receiptPdfUnsupported;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get cameraPermissionRequired;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access was denied. Allow camera access to take a receipt photo.'**
  String get cameraPermissionDenied;

  /// No description provided for @cameraPermissionPermanent.
  ///
  /// In en, this message translates to:
  /// **'Camera access is blocked. Enable it in system settings to take a receipt photo.'**
  String get cameraPermissionPermanent;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openAppSettings;

  /// No description provided for @receiptSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get receiptSubtotal;

  /// No description provided for @receiptTax.
  ///
  /// In en, this message translates to:
  /// **'Tax/GST'**
  String get receiptTax;

  /// No description provided for @receiptDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get receiptDiscount;

  /// No description provided for @receiptCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get receiptCurrency;

  /// No description provided for @receiptPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get receiptPaymentMethod;

  /// No description provided for @receiptInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt number'**
  String get receiptInvoiceNumber;

  /// No description provided for @receiptAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Receipt analyzed. Details automatically populated!'**
  String get receiptAnalyzed;

  /// No description provided for @receiptExpenseDefault.
  ///
  /// In en, this message translates to:
  /// **'Receipt expense'**
  String get receiptExpenseDefault;

  /// No description provided for @invalidReceiptAmount.
  ///
  /// In en, this message translates to:
  /// **'The receipt analysis did not provide a valid amount.'**
  String get invalidReceiptAmount;

  /// No description provided for @saveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save Expense'**
  String get saveExpense;

  /// No description provided for @analyzingReceipt.
  ///
  /// In en, this message translates to:
  /// **'Analyzing receipt…'**
  String get analyzingReceipt;

  /// No description provided for @expenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense saved successfully.'**
  String get expenseSaved;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the request. Please try again.'**
  String get operationFailed;

  /// No description provided for @operationFailedWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the request: {details}'**
  String operationFailedWithDetails(String details);

  /// No description provided for @emiTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'EMI Tracker'**
  String get emiTrackerTitle;

  /// No description provided for @addEmi.
  ///
  /// In en, this message translates to:
  /// **'Add EMI'**
  String get addEmi;

  /// No description provided for @emiLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load EMIs'**
  String get emiLoadError;

  /// No description provided for @noActiveEmis.
  ///
  /// In en, this message translates to:
  /// **'No active EMIs'**
  String get noActiveEmis;

  /// No description provided for @addEmiDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap + Add EMI to track your monthly loan installments.'**
  String get addEmiDescription;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @emiAdded.
  ///
  /// In en, this message translates to:
  /// **'EMI added successfully!'**
  String get emiAdded;

  /// No description provided for @addNewEmi.
  ///
  /// In en, this message translates to:
  /// **'Add New EMI'**
  String get addNewEmi;

  /// No description provided for @emiTitle.
  ///
  /// In en, this message translates to:
  /// **'EMI Title'**
  String get emiTitle;

  /// No description provided for @emiTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Motorcycle Loan'**
  String get emiTitleHint;

  /// No description provided for @emiTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title for the EMI.'**
  String get emiTitleRequired;

  /// No description provided for @monthlyAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly Amount (₹)'**
  String get monthlyAmount;

  /// No description provided for @dueDateDay.
  ///
  /// In en, this message translates to:
  /// **'Due Date Day of Month'**
  String get dueDateDay;

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of every month'**
  String dayOfMonth(int day);

  /// No description provided for @saveEmi.
  ///
  /// In en, this message translates to:
  /// **'Save EMI'**
  String get saveEmi;

  /// No description provided for @positiveAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive amount.'**
  String get positiveAmountRequired;

  /// No description provided for @dueOnEveryMonth.
  ///
  /// In en, this message translates to:
  /// **'Due on the {day} of every month'**
  String dueOnEveryMonth(String day);

  /// No description provided for @emiDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get emiDuration;

  /// No description provided for @emiDurationMonths.
  ///
  /// In en, this message translates to:
  /// **'{months} months'**
  String emiDurationMonths(int months);

  /// No description provided for @emiDurationYears.
  ///
  /// In en, this message translates to:
  /// **'{months} months ({years} years)'**
  String emiDurationYears(int months, String years);

  /// No description provided for @emiCustomDuration.
  ///
  /// In en, this message translates to:
  /// **'Custom duration'**
  String get emiCustomDuration;

  /// No description provided for @emiCustomDurationMonths.
  ///
  /// In en, this message translates to:
  /// **'Duration in months'**
  String get emiCustomDurationMonths;

  /// No description provided for @emiDurationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive whole number of months.'**
  String get emiDurationRequired;

  /// No description provided for @emiStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date: {date}'**
  String emiStartDate(String date);

  /// No description provided for @emiEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date: {date}'**
  String emiEndDate(String date);

  /// No description provided for @emiTotalInstallments.
  ///
  /// In en, this message translates to:
  /// **'{total} total installments'**
  String emiTotalInstallments(int total);

  /// No description provided for @emiInstallmentProgress.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total} installments paid · {remaining} remaining'**
  String emiInstallmentProgress(int paid, int total, int remaining);

  /// No description provided for @emiCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get emiCompleted;

  /// No description provided for @deactivateEmiTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate EMI?'**
  String get deactivateEmiTitle;

  /// No description provided for @deactivateEmiConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {title}? It will remain visible and can be reactivated.'**
  String deactivateEmiConfirmation(String title);

  /// No description provided for @deactivateEmi.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateEmi;

  /// No description provided for @emiStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'EMI status updated.'**
  String get emiStatusUpdated;

  /// No description provided for @emiStatusUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update EMI status. Please try again.'**
  String get emiStatusUpdateFailed;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileSettings;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get profileLoadError;

  /// No description provided for @personalFinanceSettings.
  ///
  /// In en, this message translates to:
  /// **'Personal Finance & Settings'**
  String get personalFinanceSettings;

  /// No description provided for @financialPreferences.
  ///
  /// In en, this message translates to:
  /// **'Financial Preferences'**
  String get financialPreferences;

  /// No description provided for @validSalaryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid salary amount.'**
  String get validSalaryRequired;

  /// No description provided for @alertThreshold.
  ///
  /// In en, this message translates to:
  /// **'Alert Threshold'**
  String get alertThreshold;

  /// No description provided for @thresholdDescription.
  ///
  /// In en, this message translates to:
  /// **'Get notified when monthly spending reaches this % of salary.'**
  String get thresholdDescription;

  /// No description provided for @manageEmi.
  ///
  /// In en, this message translates to:
  /// **'Manage monthly loan installments'**
  String get manageEmi;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkThemeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Dark theme enabled'**
  String get darkThemeEnabled;

  /// No description provided for @lightThemeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Light theme enabled'**
  String get lightThemeEnabled;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ் (Tamil)'**
  String get languageTamil;

  /// No description provided for @languageTelugu.
  ///
  /// In en, this message translates to:
  /// **'తెలుగు (Telugu)'**
  String get languageTelugu;

  /// No description provided for @languageMalayalam.
  ///
  /// In en, this message translates to:
  /// **'മലയാളം (Malayalam)'**
  String get languageMalayalam;

  /// No description provided for @languageKannada.
  ///
  /// In en, this message translates to:
  /// **'ಕನ್ನಡ (Kannada)'**
  String get languageKannada;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी (Hindi)'**
  String get languageHindi;

  /// No description provided for @savePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get savePreferences;

  /// No description provided for @preferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved successfully!'**
  String get preferencesSaved;

  /// No description provided for @preferencesSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save preferences: {details}'**
  String preferencesSaveError(String details);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out: {details}'**
  String signOutError(String details);

  /// No description provided for @userEmailFallback.
  ///
  /// In en, this message translates to:
  /// **'User Email'**
  String get userEmailFallback;

  /// No description provided for @salaryLabelRupees.
  ///
  /// In en, this message translates to:
  /// **'Base Monthly Salary (₹)'**
  String get salaryLabelRupees;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'hi',
    'kn',
    'ml',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
