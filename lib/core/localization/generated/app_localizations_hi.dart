// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'कासु ट्रैकर';

  @override
  String get splashTitle => 'कासु ट्रैकर';

  @override
  String get splashSubtitle => 'अपने पैसे का साफ़ हिसाब रखें।';

  @override
  String get continueToDashboard => 'जारी रखें';

  @override
  String get dashboardTitle => 'आपका डैशबोर्ड';

  @override
  String get dashboardPlaceholder => 'अपने वित्त की स्थिति एक नज़र में देखें।';

  @override
  String get additionalFundsTitle => 'अतिरिक्त धन';

  @override
  String get borrowedFundsTitle => 'उधार लिया धन';

  @override
  String get fundsReceived => 'कुल प्राप्त';

  @override
  String get fundsUsed => 'खर्चों के लिए आवंटित';

  @override
  String get fundsRemaining => 'उपलब्ध शेष राशि';

  @override
  String get addFund => 'धन जोड़ें';

  @override
  String get amountLabel => 'राशि';

  @override
  String get dateLabel => 'तारीख';

  @override
  String get sourceDescriptionLabel => 'स्रोत';

  @override
  String get purposeLabel => 'उद्देश्य';

  @override
  String get repaymentBalanceLabel => 'चुकाई जाने वाली शेष राशि';

  @override
  String get saveFund => 'सहेजें';

  @override
  String get updateFund => 'अपडेट करें';

  @override
  String get deactivateFund => 'निष्क्रिय करें';

  @override
  String get emptyFunds => 'इस महीने कोई धन दर्ज नहीं किया गया।';

  @override
  String get fundSaved => 'धन सफलतापूर्वक सहेजा गया।';

  @override
  String get fundDeactivated => 'धन स्रोत निष्क्रिय किया गया।';

  @override
  String get amountRequired => 'शून्य से अधिक राशि दर्ज करें।';

  @override
  String get sourceRequired => 'धन का स्रोत दर्ज करें।';

  @override
  String get purposeRequired => 'उद्देश्य दर्ज करें।';

  @override
  String get fundsFormTitle => 'धन का विवरण';

  @override
  String get salarySpent => 'वेतन से खर्च';

  @override
  String get salaryFundedExpenses => 'वेतन से चुकाए गए खर्च';

  @override
  String get remainingSalary => 'इस महीने का शेष वेतन';

  @override
  String get additionalFundsUsed => 'इस्तेमाल किया गया अतिरिक्त धन';

  @override
  String get additionalFundsAvailable => 'उपलब्ध अतिरिक्त धन';

  @override
  String get carryForwardUsed => 'आगे लाई गई शेष राशि का उपयोग';

  @override
  String get borrowedFundsUsed => 'इस्तेमाल किया गया उधार';

  @override
  String get actualExpenses => 'वास्तविक खर्च';

  @override
  String get monthlyEmiScheduled => 'मासिक EMI निर्धारित';

  @override
  String get nextEmiDue => 'अगली EMI की तारीख';

  @override
  String get emiSchedule => 'EMI अनुसूची';

  @override
  String get emiScheduled => 'निर्धारित';

  @override
  String get emiDueToday => 'आज देय EMI';

  @override
  String get noScheduledEmis => 'कोई सक्रिय EMI अनुसूची नहीं';

  @override
  String get emiPaymentNotTracked => 'भुगतान की स्थिति ट्रैक नहीं की जाती';

  @override
  String get unfundedOverspending => 'बिना धन के अतिरिक्त खर्च';

  @override
  String get summaryUnavailable => 'मासिक सारांश लोड नहीं हो सका।';

  @override
  String get summaryLoading => 'मासिक सारांश लोड हो रहा है...';

  @override
  String get salarySetupRequired =>
      'मासिक वेतन सेट नहीं है। धन मेनू से सेट करें।';

  @override
  String get emptyMonth => 'इस महीने कोई वित्तीय गतिविधि नहीं है।';

  @override
  String get establishCarryForward => 'शेष राशि आगे ले जाएँ';

  @override
  String get carryForwardEstablished => 'शेष राशि आगे ले जाई गई।';

  @override
  String get carryForwardAvailable => 'पिछले महीने की पात्र शेष राशि';

  @override
  String get salaryAvailable => 'इस महीने का उपलब्ध वेतन';

  @override
  String get expenseDetailsTitle => 'खर्च का विवरण';

  @override
  String get expenseDetailsNotFound => 'खर्च नहीं मिला।';

  @override
  String get expenseDetailsLoadError => 'यह खर्च लोड नहीं हो सका।';

  @override
  String get deleteExpense => 'खर्च हटाएँ';

  @override
  String get confirmExpenseDeleteMessage =>
      'क्या आप इस खर्च को हटाना चाहते हैं?';

  @override
  String get expenseDeleted => 'खर्च हटा दिया गया।';

  @override
  String get expenseFundingBreakdown => 'धन आवंटन';

  @override
  String get unfundedAmount => 'बिना धन की राशि';

  @override
  String get manageExpenseFunding => 'धन आवंटन प्रबंधित करें';

  @override
  String get allocationTitle => 'खर्च के लिए धन आवंटन';

  @override
  String get expenseAmount => 'खर्च की राशि';

  @override
  String get fundingSource => 'धन का स्रोत';

  @override
  String get sourceAvailable => 'उपलब्ध';

  @override
  String get assignedAmount => 'आवंटित';

  @override
  String get unallocatedAmount => 'शेष अनावंटित राशि';

  @override
  String get saveAllocation => 'बदलाव सहेजें';

  @override
  String get allocationSaved => 'खर्च के लिए धन आवंटन अपडेट किया गया।';

  @override
  String get allocationExceedsBalance => 'आवंटन उपलब्ध शेष राशि से अधिक है।';

  @override
  String get allocationExceedsExpense =>
      'आवंटन की कुल राशि खर्च के बराबर होनी चाहिए।';

  @override
  String get duplicateFundingSource =>
      'धन का एक स्रोत एक से अधिक बार सूचीबद्ध है।';

  @override
  String get allocationVerificationFailed =>
      'सर्वर ने अनुरोधित आवंटन की पुष्टि नहीं की। आपके बदलाव अभी भी इस स्क्रीन पर हैं।';

  @override
  String get expenseUnavailable =>
      'इस खर्च के लिए धन आवंटित नहीं किया जा सकता।';

  @override
  String get noFundingSources => 'इस महीने के लिए धन स्रोत उपलब्ध नहीं हैं।';

  @override
  String get allFunds => 'सभी अवधि';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get serverSessionExpired =>
      'आपका सत्र समाप्त हो गया है। फिर से साइन इन करें।';

  @override
  String get serverForbidden => 'आपको यह कार्रवाई करने की अनुमति नहीं है।';

  @override
  String get serverNotFound => 'अनुरोधित रिकॉर्ड नहीं मिला।';

  @override
  String get serverFailure =>
      'सेवा अस्थायी रूप से उपलब्ध नहीं है। फिर कोशिश करें।';

  @override
  String get serverRequestFailure => 'अनुरोध पूरा नहीं हो सका। फिर कोशिश करें।';

  @override
  String get fundsTitle => 'धन स्रोत';

  @override
  String get today => 'आज';

  @override
  String get baseMonthlySalary => 'मासिक मूल वेतन';

  @override
  String get combinedRemaining => 'कुल शेष धन';

  @override
  String get noNextEmi => 'अगली EMI निर्धारित नहीं है';

  @override
  String get setMonthlySalary => 'मासिक वेतन तय करें';

  @override
  String get salarySaved => 'मासिक वेतन सहेजा गया।';

  @override
  String get inactiveFundStatus => 'निष्क्रिय';

  @override
  String get invalidExpenseId => 'खर्च पहचान संख्या अमान्य है।';

  @override
  String get carryForwardRemaining => 'आगे लाई गई शेष राशि';

  @override
  String get salaryAllocated => 'इस महीने के वेतन से आवंटित';

  @override
  String get combinedBalanceDetail => 'सभी धन स्रोतों का कुल';

  @override
  String percentUsed(String percent) {
    return '$percent% इस्तेमाल हुआ';
  }

  @override
  String get saving => 'सहेजा जा रहा है…';

  @override
  String get navDashboard => 'डैशबोर्ड';

  @override
  String get navAnalytics => 'विश्लेषण';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get welcomeBack => 'वापसी पर स्वागत है';

  @override
  String get signInPrompt =>
      'अपने वित्त का प्रबंधन करने के लिए साइन इन करें या खाता बनाएँ।';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get showPassword => 'पासवर्ड दिखाएँ';

  @override
  String get hidePassword => 'पासवर्ड छिपाएँ';

  @override
  String get logIn => 'लॉग इन';

  @override
  String get signUp => 'साइन अप';

  @override
  String get emailRequired => 'अपना ईमेल दर्ज करें।';

  @override
  String get emailInvalid => 'मान्य ईमेल पता दर्ज करें।';

  @override
  String get passwordRequired => 'अपना पासवर्ड दर्ज करें।';

  @override
  String get passwordMinLength => 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए।';

  @override
  String get duplicateAccountPossible =>
      'इस ईमेल से खाता पहले से हो सकता है। लॉग इन करके देखें।';

  @override
  String get emailConfirmation =>
      'पंजीकरण भेज दिया गया है। खाता सत्यापित करने के लिए ईमेल देखें।';

  @override
  String get accountCreated => 'खाता सफलतापूर्वक बनाया गया!';

  @override
  String get signedIn => 'सफलतापूर्वक साइन इन किया।';

  @override
  String get authNetworkError =>
      'प्रमाणीकरण सेवा से संपर्क नहीं हो सका। कनेक्शन जाँचकर फिर कोशिश करें।';

  @override
  String get tooManyAttempts =>
      'बहुत सारे प्रयास हुए। कुछ देर बाद फिर कोशिश करें।';

  @override
  String get invalidCredentials => 'ईमेल या पासवर्ड गलत है।';

  @override
  String get emailNotConfirmed =>
      'साइन इन करने से पहले अपना ईमेल सत्यापित करें।';

  @override
  String get accountAlreadyExists =>
      'इस ईमेल से खाता पहले से मौजूद है। लॉग इन करें।';

  @override
  String get weakPassword => 'ज़्यादा मज़बूत पासवर्ड चुनकर फिर कोशिश करें।';

  @override
  String get accountCreationFailed => 'खाता नहीं बनाया जा सका। फिर कोशिश करें।';

  @override
  String get signInFailed =>
      'साइन इन नहीं हो सका। कनेक्शन जाँचकर फिर कोशिश करें।';

  @override
  String pageNotFound(String path) {
    return 'पृष्ठ नहीं मिला: $path';
  }

  @override
  String get addExpense => 'खर्च जोड़ें';

  @override
  String get previousMonth => 'पिछला महीना';

  @override
  String get nextMonth => 'अगला महीना';

  @override
  String get recentExpenses => 'हाल के खर्च';

  @override
  String get add => 'जोड़ें';

  @override
  String get collapseRecentExpenses => 'हाल के खर्च समेटें';

  @override
  String get expandRecentExpenses => 'हाल के खर्च दिखाएँ';

  @override
  String get collapseEmiSchedule => 'EMI अनुसूची समेटें';

  @override
  String get expandEmiSchedule => 'EMI अनुसूची दिखाएँ';

  @override
  String get recentExpensesLoadError => 'हाल के खर्च लोड नहीं हो सके';

  @override
  String get noExpensesRecorded => 'अभी तक कोई खर्च दर्ज नहीं है';

  @override
  String get startExpenseTracking =>
      'ट्रैकिंग शुरू करने के लिए + खर्च जोड़ें पर टैप करें।';

  @override
  String get analyticsTitle => 'विश्लेषण';

  @override
  String get analyticsLoadError => 'विश्लेषण लोड नहीं हो सका';

  @override
  String get monthlyOverview => 'मासिक सारांश';

  @override
  String get noExpensesThisMonth => 'इस महीने कोई खर्च नहीं';

  @override
  String get startTrackingExpenses =>
      'खर्च की आदतें देखने के लिए ट्रैकिंग शुरू करें!';

  @override
  String get expensesByCategory => 'श्रेणी के अनुसार खर्च';

  @override
  String get categoryBreakdown => 'श्रेणीवार विवरण';

  @override
  String get addExpenseTitle => 'खर्च जोड़ें';

  @override
  String get spendQuestion => 'आपने कितना खर्च किया?';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String get categoryTravel => 'यात्रा';

  @override
  String get categoryFood => 'भोजन';

  @override
  String get categoryUtilities => 'बिजली-पानी के बिल';

  @override
  String get categoryShopping => 'खरीदारी';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get expenseDescriptionHint => 'यह खर्च किस लिए था?';

  @override
  String get shortDescriptionRequired => 'छोटा-सा विवरण जोड़ें।';

  @override
  String get scanReceipt => 'रसीद स्कैन करें';

  @override
  String get takePhoto => 'फ़ोटो लें (कैमरा)';

  @override
  String get chooseGallery => 'गैलरी से चुनें';

  @override
  String get chooseDocument => 'दस्तावेज़ चुनें';

  @override
  String get receiptPreview => 'रसीद का पूर्वावलोकन';

  @override
  String get removeReceipt => 'रसीद हटाएँ';

  @override
  String get analyzeReceipt => 'रसीद का विश्लेषण करें';

  @override
  String get receiptSuggestionsNotice =>
      'AI सुझाव सत्यापित नहीं हैं। सहेजने से पहले खर्च के विवरण जाँचें और संपादित करें।';

  @override
  String get receiptAnalysisFailed =>
      'इस रसीद का विश्लेषण नहीं हो सका। कनेक्शन जाँचें और फिर कोशिश करें।';

  @override
  String get receiptReadError =>
      'चुनी गई रसीद पढ़ी नहीं जा सकी। दूसरी फ़ाइल चुनकर फिर कोशिश करें।';

  @override
  String get receiptEmptyFile => 'चुनी गई रसीद फ़ाइल खाली है।';

  @override
  String get receiptFileTooLarge => 'रसीद फ़ाइल 10 MB की सीमा से बड़ी है।';

  @override
  String get receiptUnsupportedFormat =>
      'JPEG, PNG या WebP रसीद छवि अथवा PDF दस्तावेज़ चुनें।';

  @override
  String get receiptInvalidFile =>
      'चुनी गई रसीद फ़ाइल अमान्य या क्षतिग्रस्त है।';

  @override
  String get receiptPdfUnsupported =>
      'मौजूदा रसीद विश्लेषण सेवा केवल छवियाँ स्वीकार करती है; PDF विश्लेषण उपलब्ध नहीं है।';

  @override
  String get cameraPermissionRequired => 'कैमरा अनुमति आवश्यक है';

  @override
  String get cameraPermissionDenied =>
      'कैमरा अनुमति अस्वीकार की गई। रसीद की फ़ोटो लेने के लिए कैमरा अनुमति दें।';

  @override
  String get cameraPermissionPermanent =>
      'कैमरा अनुमति अवरुद्ध है। इसे सिस्टम सेटिंग में सक्षम करें।';

  @override
  String get openAppSettings => 'सेटिंग खोलें';

  @override
  String get receiptSubtotal => 'उप-योग';

  @override
  String get receiptTax => 'कर/GST';

  @override
  String get receiptDiscount => 'छूट';

  @override
  String get receiptCurrency => 'मुद्रा';

  @override
  String get receiptPaymentMethod => 'भुगतान का तरीका';

  @override
  String get receiptInvoiceNumber => 'रसीद संख्या';

  @override
  String get receiptAnalyzed =>
      'रसीद का विश्लेषण हुआ। विवरण अपने आप भर दिए गए!';

  @override
  String get receiptExpenseDefault => 'रसीद का खर्च';

  @override
  String get invalidReceiptAmount =>
      'रसीद के विश्लेषण से मान्य राशि नहीं मिली।';

  @override
  String get saveExpense => 'खर्च सहेजें';

  @override
  String get analyzingReceipt => 'रसीद का विश्लेषण हो रहा है…';

  @override
  String get expenseSaved => 'खर्च सफलतापूर्वक सहेजा गया।';

  @override
  String get operationFailed => 'अनुरोध पूरा नहीं हो सका। फिर कोशिश करें।';

  @override
  String operationFailedWithDetails(String details) {
    return 'अनुरोध पूरा नहीं हो सका: $details';
  }

  @override
  String get emiTrackerTitle => 'EMI ट्रैकर';

  @override
  String get addEmi => 'EMI जोड़ें';

  @override
  String get emiLoadError => 'EMI लोड नहीं हो सकीं';

  @override
  String get noActiveEmis => 'कोई सक्रिय EMI नहीं';

  @override
  String get addEmiDescription =>
      'मासिक ऋण किस्तें ट्रैक करने के लिए + EMI जोड़ें पर टैप करें।';

  @override
  String get active => 'सक्रिय';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get emiAdded => 'EMI सफलतापूर्वक जोड़ी गई!';

  @override
  String get addNewEmi => 'नई EMI जोड़ें';

  @override
  String get emiTitle => 'EMI का नाम';

  @override
  String get emiTitleHint => 'जैसे, मोटरसाइकिल ऋण';

  @override
  String get emiTitleRequired => 'EMI का नाम दर्ज करें।';

  @override
  String get monthlyAmount => 'मासिक राशि (₹)';

  @override
  String get dueDateDay => 'महीने की देय तारीख';

  @override
  String dayOfMonth(int day) {
    return 'हर महीने की $day तारीख';
  }

  @override
  String get saveEmi => 'EMI सहेजें';

  @override
  String get positiveAmountRequired => 'मान्य धनात्मक राशि दर्ज करें।';

  @override
  String dueOnEveryMonth(String day) {
    return 'हर महीने की $day तारीख को देय';
  }

  @override
  String get emiDuration => 'अवधि';

  @override
  String emiDurationMonths(int months) {
    return '$months महीने';
  }

  @override
  String emiDurationYears(int months, String years) {
    return '$months महीने ($years वर्ष)';
  }

  @override
  String get emiCustomDuration => 'कस्टम अवधि';

  @override
  String get emiCustomDurationMonths => 'महीनों में अवधि';

  @override
  String get emiDurationRequired =>
      'महीनों की सकारात्मक पूर्ण संख्या दर्ज करें।';

  @override
  String emiStartDate(String date) {
    return 'शुरू होने की तारीख: $date';
  }

  @override
  String emiEndDate(String date) {
    return 'समाप्ति की तारीख: $date';
  }

  @override
  String emiTotalInstallments(int total) {
    return 'कुल $total किस्तें';
  }

  @override
  String emiInstallmentProgress(int paid, int total, int remaining) {
    return '$total किस्तों में से $paid चुकाई गईं · $remaining बाकी';
  }

  @override
  String get emiCompleted => 'पूरा हुआ';

  @override
  String get deactivateEmiTitle => 'EMI निष्क्रिय करें?';

  @override
  String deactivateEmiConfirmation(String title) {
    return '$title को निष्क्रिय करें? यह सूची में रहेगा और फिर से सक्रिय किया जा सकता है।';
  }

  @override
  String get deactivateEmi => 'निष्क्रिय करें';

  @override
  String get emiStatusUpdated => 'EMI की स्थिति अपडेट हो गई।';

  @override
  String get emiStatusUpdateFailed =>
      'EMI की स्थिति अपडेट नहीं हो सकी। फिर कोशिश करें।';

  @override
  String get profileSettings => 'प्रोफ़ाइल और सेटिंग';

  @override
  String get profileLoadError => 'प्रोफ़ाइल लोड करने में त्रुटि';

  @override
  String get personalFinanceSettings => 'व्यक्तिगत वित्त और सेटिंग';

  @override
  String get financialPreferences => 'वित्तीय प्राथमिकताएँ';

  @override
  String get validSalaryRequired => 'मान्य वेतन राशि दर्ज करें।';

  @override
  String get alertThreshold => 'चेतावनी सीमा';

  @override
  String get thresholdDescription =>
      'मासिक खर्च वेतन के इस प्रतिशत तक पहुँचने पर सूचना पाएँ।';

  @override
  String get manageEmi => 'मासिक ऋण किस्तें प्रबंधित करें';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get darkThemeEnabled => 'डार्क थीम चालू है';

  @override
  String get lightThemeEnabled => 'लाइट थीम चालू है';

  @override
  String get appLanguage => 'ऐप की भाषा';

  @override
  String get languageEnglish => 'English (अंग्रेज़ी)';

  @override
  String get languageTamil => 'தமிழ் (तमिल)';

  @override
  String get languageTelugu => 'తెలుగు (तेलुगु)';

  @override
  String get languageMalayalam => 'മലയാളം (मलयालम)';

  @override
  String get languageKannada => 'ಕನ್ನಡ (कन्नड़)';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get savePreferences => 'प्राथमिकताएँ सहेजें';

  @override
  String get preferencesSaved => 'प्राथमिकताएँ सफलतापूर्वक सहेजी गईं!';

  @override
  String preferencesSaveError(String details) {
    return 'प्राथमिकताएँ सहेजी नहीं जा सकीं: $details';
  }

  @override
  String get signOut => 'साइन आउट';

  @override
  String signOutError(String details) {
    return 'साइन आउट नहीं हो सका: $details';
  }

  @override
  String get userEmailFallback => 'उपयोगकर्ता ईमेल';

  @override
  String get salaryLabelRupees => 'मासिक मूल वेतन (₹)';
}
