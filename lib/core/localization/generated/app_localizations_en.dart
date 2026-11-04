// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KaasuTracker';

  @override
  String get splashTitle => 'KaasuTracker';

  @override
  String get splashSubtitle => 'Your money, made clear.';

  @override
  String get continueToDashboard => 'Continue';

  @override
  String get dashboardTitle => 'Your dashboard';

  @override
  String get dashboardPlaceholder => 'Your finances at a glance.';

  @override
  String get additionalFundsTitle => 'Additional funds';

  @override
  String get borrowedFundsTitle => 'Borrowed funds';

  @override
  String get fundsReceived => 'Total received';

  @override
  String get fundsUsed => 'Allocated to expenses';

  @override
  String get fundsRemaining => 'Available balance';

  @override
  String get addFund => 'Add funds';

  @override
  String get amountLabel => 'Amount';

  @override
  String get dateLabel => 'Date';

  @override
  String get sourceDescriptionLabel => 'Source';

  @override
  String get purposeLabel => 'Purpose';

  @override
  String get repaymentBalanceLabel => 'Outstanding repayment balance';

  @override
  String get saveFund => 'Save';

  @override
  String get updateFund => 'Update';

  @override
  String get deactivateFund => 'Deactivate';

  @override
  String get emptyFunds => 'No funds recorded for this month.';

  @override
  String get fundSaved => 'Funds saved successfully.';

  @override
  String get fundDeactivated => 'Fund deactivated.';

  @override
  String get amountRequired => 'Enter an amount greater than zero.';

  @override
  String get sourceRequired => 'Enter a source description.';

  @override
  String get purposeRequired => 'Enter a purpose.';

  @override
  String get fundsFormTitle => 'Fund details';

  @override
  String get salarySpent => 'Salary spent';

  @override
  String get salaryFundedExpenses => 'Salary-funded expenses';

  @override
  String get remainingSalary => 'Remaining current-month salary';

  @override
  String get additionalFundsUsed => 'Additional funds used';

  @override
  String get additionalFundsAvailable => 'Additional funds available';

  @override
  String get carryForwardUsed => 'Carry-forward used';

  @override
  String get borrowedFundsUsed => 'Borrowed funds used';

  @override
  String get actualExpenses => 'Actual expenses';

  @override
  String get monthlyEmiScheduled => 'Monthly EMI scheduled';

  @override
  String get nextEmiDue => 'Next EMI due';

  @override
  String get emiSchedule => 'EMI schedule';

  @override
  String get emiScheduled => 'Scheduled';

  @override
  String get emiDueToday => 'EMI due today';

  @override
  String get noScheduledEmis => 'No active EMI schedules';

  @override
  String get emiPaymentNotTracked => 'Payment status not tracked';

  @override
  String get unfundedOverspending => 'Unfunded overspending';

  @override
  String get summaryUnavailable => 'Monthly summary could not be loaded.';

  @override
  String get summaryLoading => 'Loading monthly summary...';

  @override
  String get salarySetupRequired =>
      'Monthly salary is not configured. Set it from the funds menu.';

  @override
  String get emptyMonth => 'No financial activity for this month.';

  @override
  String get establishCarryForward => 'Establish carry-forward';

  @override
  String get carryForwardEstablished => 'Carry-forward balance established.';

  @override
  String get carryForwardAvailable => 'Eligible previous-month balance';

  @override
  String get salaryAvailable => 'Current-month salary balance';

  @override
  String get expenseDetailsTitle => 'Expense details';

  @override
  String get expenseDetailsNotFound => 'Expense not found.';

  @override
  String get expenseDetailsLoadError => 'Could not load this expense.';

  @override
  String get deleteExpense => 'Delete expense';

  @override
  String get confirmExpenseDeleteMessage =>
      'Are you sure you want to delete this expense?';

  @override
  String get expenseDeleted => 'Expense deleted.';

  @override
  String get expenseFundingBreakdown => 'Funding allocation';

  @override
  String get unfundedAmount => 'Unfunded amount';

  @override
  String get manageExpenseFunding => 'Manage funding';

  @override
  String get allocationTitle => 'Expense funding';

  @override
  String get expenseAmount => 'Expense amount';

  @override
  String get fundingSource => 'Funding source';

  @override
  String get sourceAvailable => 'Available';

  @override
  String get assignedAmount => 'Assigned';

  @override
  String get unallocatedAmount => 'Remaining unallocated';

  @override
  String get saveAllocation => 'Save changes';

  @override
  String get allocationSaved => 'Expense funding updated.';

  @override
  String get allocationExceedsBalance =>
      'An allocation exceeds the available balance.';

  @override
  String get allocationExceedsExpense =>
      'Allocations must equal the expense amount.';

  @override
  String get duplicateFundingSource =>
      'A funding source is listed more than once.';

  @override
  String get allocationVerificationFailed =>
      'The server did not confirm the requested allocation. Your changes are still on this screen.';

  @override
  String get expenseUnavailable => 'Expense is unavailable for funding.';

  @override
  String get noFundingSources =>
      'No funding sources are available for this month.';

  @override
  String get allFunds => 'All periods';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get serverSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get serverForbidden =>
      'You do not have permission to perform this action.';

  @override
  String get serverNotFound => 'The requested record could not be found.';

  @override
  String get serverFailure =>
      'The service is temporarily unavailable. Please try again.';

  @override
  String get serverRequestFailure =>
      'The request could not be completed. Please try again.';

  @override
  String get fundsTitle => 'Fund sources';

  @override
  String get today => 'Today';

  @override
  String get baseMonthlySalary => 'Monthly base salary';

  @override
  String get combinedRemaining => 'Total remaining funds';

  @override
  String get noNextEmi => 'No next EMI scheduled';

  @override
  String get setMonthlySalary => 'Set monthly salary';

  @override
  String get salarySaved => 'Monthly salary saved.';

  @override
  String get inactiveFundStatus => 'Inactive';

  @override
  String get invalidExpenseId => 'Invalid expense identifier.';

  @override
  String get carryForwardRemaining => 'Remaining carry-forward balance';

  @override
  String get salaryAllocated => 'Allocated from current-month salary';

  @override
  String get combinedBalanceDetail => 'Across all funding sources';

  @override
  String percentUsed(String percent) {
    return '$percent% used';
  }

  @override
  String get saving => 'Saving…';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navProfile => 'Profile';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInPrompt =>
      'Sign in or create an account to manage your finances.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get logIn => 'Log In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get emailRequired => 'Please enter your email.';

  @override
  String get emailInvalid => 'Please enter a valid email address.';

  @override
  String get passwordRequired => 'Please enter your password.';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters.';

  @override
  String get duplicateAccountPossible =>
      'An account with this email may already exist. Try logging in.';

  @override
  String get emailConfirmation =>
      'Registration submitted. Please check your email to confirm your account.';

  @override
  String get accountCreated => 'Account created successfully!';

  @override
  String get signedIn => 'Signed in successfully.';

  @override
  String get authNetworkError =>
      'Could not reach the authentication service. Check your connection and try again.';

  @override
  String get tooManyAttempts =>
      'Too many attempts. Please wait a while before trying again.';

  @override
  String get invalidCredentials => 'The email or password is incorrect.';

  @override
  String get emailNotConfirmed =>
      'Please confirm your email address before signing in.';

  @override
  String get accountAlreadyExists =>
      'An account with this email already exists. Please log in.';

  @override
  String get weakPassword => 'Choose a stronger password and try again.';

  @override
  String get accountCreationFailed =>
      'Could not create your account. Please try again.';

  @override
  String get signInFailed =>
      'Could not sign in. Please check your connection and try again.';

  @override
  String pageNotFound(String path) {
    return 'Page not found: $path';
  }

  @override
  String get addExpense => 'Add expense';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get recentExpenses => 'Recent Expenses';

  @override
  String get add => 'Add';

  @override
  String get collapseRecentExpenses => 'Collapse recent expenses';

  @override
  String get expandRecentExpenses => 'Expand recent expenses';

  @override
  String get collapseEmiSchedule => 'Collapse EMI schedule';

  @override
  String get expandEmiSchedule => 'Expand EMI schedule';

  @override
  String get recentExpensesLoadError => 'Could not load recent expenses';

  @override
  String get noExpensesRecorded => 'No expenses recorded yet';

  @override
  String get startExpenseTracking => 'Tap + Add expense to start tracking.';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get analyticsLoadError => 'Could not load analytics';

  @override
  String get monthlyOverview => 'Monthly Overview';

  @override
  String get noExpensesThisMonth => 'No expenses this month';

  @override
  String get startTrackingExpenses =>
      'Start tracking to see your spending habits!';

  @override
  String get expensesByCategory => 'Expenses by Category';

  @override
  String get categoryBreakdown => 'Category Breakdown';

  @override
  String get addExpenseTitle => 'Add expense';

  @override
  String get spendQuestion => 'How much did you spend?';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryTravel => 'Travel';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryUtilities => 'Utilities';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get expenseDescriptionHint => 'What was this expense for?';

  @override
  String get shortDescriptionRequired => 'Add a short description.';

  @override
  String get scanReceipt => 'Scan Receipt';

  @override
  String get takePhoto => 'Take a Photo (Camera)';

  @override
  String get chooseGallery => 'Choose from Gallery';

  @override
  String get chooseDocument => 'Choose Document';

  @override
  String get receiptPreview => 'Receipt preview';

  @override
  String get removeReceipt => 'Remove receipt';

  @override
  String get analyzeReceipt => 'Analyze receipt';

  @override
  String get receiptSuggestionsNotice =>
      'AI suggestions are unverified. Review and edit the expense fields before saving.';

  @override
  String get receiptAnalysisFailed =>
      'Could not analyze this receipt. Check your connection and try again.';

  @override
  String get receiptReadError =>
      'Could not read the selected receipt. Choose another file and try again.';

  @override
  String get receiptEmptyFile => 'The selected receipt file is empty.';

  @override
  String get receiptFileTooLarge => 'The receipt file exceeds the 10 MB limit.';

  @override
  String get receiptUnsupportedFormat =>
      'Choose a JPEG, PNG, or WebP receipt image, or a PDF document.';

  @override
  String get receiptInvalidFile =>
      'The selected receipt file is invalid or damaged.';

  @override
  String get receiptPdfUnsupported =>
      'The current receipt analysis service accepts images only; PDF analysis is not enabled.';

  @override
  String get cameraPermissionRequired => 'Camera permission required';

  @override
  String get cameraPermissionDenied =>
      'Camera access was denied. Allow camera access to take a receipt photo.';

  @override
  String get cameraPermissionPermanent =>
      'Camera access is blocked. Enable it in system settings to take a receipt photo.';

  @override
  String get openAppSettings => 'Open settings';

  @override
  String get receiptSubtotal => 'Subtotal';

  @override
  String get receiptTax => 'Tax/GST';

  @override
  String get receiptDiscount => 'Discount';

  @override
  String get receiptCurrency => 'Currency';

  @override
  String get receiptPaymentMethod => 'Payment method';

  @override
  String get receiptInvoiceNumber => 'Receipt number';

  @override
  String get receiptAnalyzed =>
      'Receipt analyzed. Details automatically populated!';

  @override
  String get receiptExpenseDefault => 'Receipt expense';

  @override
  String get invalidReceiptAmount =>
      'The receipt analysis did not provide a valid amount.';

  @override
  String get saveExpense => 'Save Expense';

  @override
  String get analyzingReceipt => 'Analyzing receipt…';

  @override
  String get expenseSaved => 'Expense saved successfully.';

  @override
  String get operationFailed =>
      'Could not complete the request. Please try again.';

  @override
  String operationFailedWithDetails(String details) {
    return 'Could not complete the request: $details';
  }

  @override
  String get emiTrackerTitle => 'EMI Tracker';

  @override
  String get addEmi => 'Add EMI';

  @override
  String get emiLoadError => 'Could not load EMIs';

  @override
  String get noActiveEmis => 'No active EMIs';

  @override
  String get addEmiDescription =>
      'Tap + Add EMI to track your monthly loan installments.';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get emiAdded => 'EMI added successfully!';

  @override
  String get addNewEmi => 'Add New EMI';

  @override
  String get emiTitle => 'EMI Title';

  @override
  String get emiTitleHint => 'e.g., Motorcycle Loan';

  @override
  String get emiTitleRequired => 'Please enter a title for the EMI.';

  @override
  String get monthlyAmount => 'Monthly Amount (₹)';

  @override
  String get dueDateDay => 'Due Date Day of Month';

  @override
  String dayOfMonth(int day) {
    return 'Day $day of every month';
  }

  @override
  String get saveEmi => 'Save EMI';

  @override
  String get positiveAmountRequired => 'Please enter a valid positive amount.';

  @override
  String dueOnEveryMonth(String day) {
    return 'Due on the $day of every month';
  }

  @override
  String get emiDuration => 'Duration';

  @override
  String emiDurationMonths(int months) {
    return '$months months';
  }

  @override
  String emiDurationYears(int months, String years) {
    return '$months months ($years years)';
  }

  @override
  String get emiCustomDuration => 'Custom duration';

  @override
  String get emiCustomDurationMonths => 'Duration in months';

  @override
  String get emiDurationRequired => 'Enter a positive whole number of months.';

  @override
  String emiStartDate(String date) {
    return 'Start date: $date';
  }

  @override
  String emiEndDate(String date) {
    return 'End date: $date';
  }

  @override
  String emiTotalInstallments(int total) {
    return '$total total installments';
  }

  @override
  String emiInstallmentProgress(int paid, int total, int remaining) {
    return '$paid of $total installments paid · $remaining remaining';
  }

  @override
  String get emiCompleted => 'Completed';

  @override
  String get deactivateEmiTitle => 'Deactivate EMI?';

  @override
  String deactivateEmiConfirmation(String title) {
    return 'Deactivate $title? It will remain visible and can be reactivated.';
  }

  @override
  String get deactivateEmi => 'Deactivate';

  @override
  String get emiStatusUpdated => 'EMI status updated.';

  @override
  String get emiStatusUpdateFailed =>
      'Could not update EMI status. Please try again.';

  @override
  String get profileSettings => 'Profile & Settings';

  @override
  String get profileLoadError => 'Error loading profile';

  @override
  String get personalFinanceSettings => 'Personal Finance & Settings';

  @override
  String get financialPreferences => 'Financial Preferences';

  @override
  String get validSalaryRequired => 'Please enter a valid salary amount.';

  @override
  String get alertThreshold => 'Alert Threshold';

  @override
  String get thresholdDescription =>
      'Get notified when monthly spending reaches this % of salary.';

  @override
  String get manageEmi => 'Manage monthly loan installments';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkThemeEnabled => 'Dark theme enabled';

  @override
  String get lightThemeEnabled => 'Light theme enabled';

  @override
  String get appLanguage => 'App Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTamil => 'தமிழ் (Tamil)';

  @override
  String get languageTelugu => 'తెలుగు (Telugu)';

  @override
  String get languageMalayalam => 'മലയാളം (Malayalam)';

  @override
  String get languageKannada => 'ಕನ್ನಡ (Kannada)';

  @override
  String get languageHindi => 'हिन्दी (Hindi)';

  @override
  String get savePreferences => 'Save Preferences';

  @override
  String get preferencesSaved => 'Preferences saved successfully!';

  @override
  String preferencesSaveError(String details) {
    return 'Could not save preferences: $details';
  }

  @override
  String get signOut => 'Sign Out';

  @override
  String signOutError(String details) {
    return 'Could not sign out: $details';
  }

  @override
  String get userEmailFallback => 'User Email';

  @override
  String get salaryLabelRupees => 'Base Monthly Salary (₹)';
}
