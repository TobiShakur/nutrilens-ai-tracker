// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NutriLens AI';

  @override
  String get navHome => 'Home';

  @override
  String get navPantry => 'Pantry';

  @override
  String get navProfile => 'Profile';

  @override
  String get navScanMealSemantics => 'Scan plate or add meal';

  @override
  String get navScanMealTooltip => 'Scan plate';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get apply => 'Apply';

  @override
  String get confirm => 'Confirm';

  @override
  String get create => 'Create';

  @override
  String get choose => 'Choose';

  @override
  String get add => 'Add';

  @override
  String get understood => 'Got it';

  @override
  String get gramsUnit => 'grams';

  @override
  String gramsTotal(int grams) {
    return '${grams}g total';
  }

  @override
  String get kcalUnit => 'kcal';

  @override
  String get pantryTag => 'Pantry';

  @override
  String get noBrand => 'unbranded';

  @override
  String get language => 'Language';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get selectLanguageTitle => 'Select language';

  @override
  String get selectLanguageSubtitle =>
      'The app UI and AI analysis will respond in the selected language.';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroFat => 'Fat';

  @override
  String get macroProteinUpper => 'PROTEIN';

  @override
  String get macroCarbsUpper => 'CARBOHYDRATES';

  @override
  String get macroFatUpper => 'FAT';

  @override
  String get macroHealthyFatUpper => 'HEALTHY FATS';

  @override
  String get macroProteinShort => 'Prot';

  @override
  String get macroCarbsShort => 'Carbs';

  @override
  String get macroFatShort => 'Fat';

  @override
  String get mealTypeBreakfast => 'Breakfast';

  @override
  String get mealTypeLunch => 'Lunch';

  @override
  String get mealTypeSnackAfternoon => 'Afternoon Snack';

  @override
  String get mealTypeDinner => 'Dinner';

  @override
  String get mealTypeSnack => 'Snack';

  @override
  String get mealTypeGeneric => 'Meal';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryProteins => 'Protein';

  @override
  String get categoryCarbs => 'Carbs';

  @override
  String get categoryDairy => 'Dairy';

  @override
  String get categoryFats => 'Fats';

  @override
  String get categoryVegetables => 'Veggies / Fruit';

  @override
  String get categoryOthers => 'Other / Spices';

  @override
  String get today => 'Today';

  @override
  String weekdaySun(int day) {
    return 'Su $day';
  }

  @override
  String weekdayMon(int day) {
    return 'Mo $day';
  }

  @override
  String weekdayTue(int day) {
    return 'Tu $day';
  }

  @override
  String weekdayWed(int day) {
    return 'We $day';
  }

  @override
  String weekdayThu(int day) {
    return 'Th $day';
  }

  @override
  String weekdayFri(int day) {
    return 'Fr $day';
  }

  @override
  String weekdaySat(int day) {
    return 'Sa $day';
  }

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get greetingGoodDay => 'Good day,';

  @override
  String get streakNone => 'No streak';

  @override
  String get streakOneDay => '1-day streak';

  @override
  String streakManyDays(int days) {
    return '$days-day streak';
  }

  @override
  String mealsCountLabel(int count) {
    return 'MEALS · $count';
  }

  @override
  String get noMealsThisDay => 'No meals logged this day yet';

  @override
  String get noMealsThisDayHint =>
      'Tap the scan button to see your nutrition numbers update.';

  @override
  String get calorieTargetTotal => 'Daily Goal';

  @override
  String get calorieCriticalExcess => 'Critical Excess!';

  @override
  String get calorieExcess => 'Over Goal!';

  @override
  String get calorieCurrent => 'Current';

  @override
  String get calorieExtras => 'Over';

  @override
  String get calorieRemaining => 'Remaining';

  @override
  String get deleteMealTitle => 'Delete meal?';

  @override
  String deleteMealMessage(String mealName) {
    return '\"$mealName\" will be removed from your meals.';
  }

  @override
  String mealTimeLabel(String time) {
    return 'Time: $time';
  }

  @override
  String get mealEnergyContribution => 'Energy contribution';

  @override
  String mealTargetKcal(int kcal) {
    return 'Goal: $kcal kcal';
  }

  @override
  String mealIngredientsCount(int count) {
    return 'Ingredients ($count)';
  }

  @override
  String get editMealTitle => 'Edit meal';

  @override
  String get editMealSubtitle =>
      'Adjust ingredients, portions in grams, and macros.';

  @override
  String get editMealNoIngredients => 'There are no ingredients in this meal';

  @override
  String get removeIngredientTitle => 'Remove ingredient?';

  @override
  String removeIngredientMessage(String name) {
    return '\"$name\" will be removed from this meal.';
  }

  @override
  String get addIngredientFromPantry => 'Add ingredient from My Pantry';

  @override
  String get recalculatedTotal => 'RECALCULATED TOTAL';

  @override
  String mealUpdatedSnackbar(int count, int kcal) {
    return 'Meal updated ($count ingredients · $kcal kcal)';
  }

  @override
  String get gramsAmountTitle => 'Amount in grams';

  @override
  String get healthScoreTitle => 'Health Score';

  @override
  String get healthScoreSubtitle =>
      'Evaluation based on ingredients and portions';

  @override
  String get healthScoreBannerNoRecords =>
      'No meals logged today yet. Add a meal to see your nutritional score.';

  @override
  String get healthScoreBannerExcellent =>
      'Excellent nutrition today! Your meal choices are well balanced.';

  @override
  String get healthScoreBannerGood =>
      'Great nutritional quality today—keep adding fresh foods.';

  @override
  String get healthScoreBannerModerate =>
      'Good nutritional progress; you could add a bit more fiber or lean protein.';

  @override
  String get healthScoreBannerLow =>
      'You can balance your upcoming meals with less processed foods.';

  @override
  String get healthScoreBadgeCalculating => 'Scoring';

  @override
  String get healthScoreSemanticsCalculating => 'Calculating health score.';

  @override
  String healthScoreSemanticsError(String score) {
    return 'Error calculating health score, $score out of 100.';
  }

  @override
  String get healthScoreSemanticsUnscored =>
      'Health score not calculated yet, ? out of 100. Tap to score with AI.';

  @override
  String healthScoreSemanticsStale(int score) {
    return 'Health score outdated, $score out of 100. Tap to recalculate after your edits.';
  }

  @override
  String healthScoreSemanticsFresh(int score) {
    return 'Health score $score out of 100. Tap to view explanation or recalculate.';
  }

  @override
  String get healthScoreTierExcellent => 'Excellent nutritional quality';

  @override
  String get healthScoreTierGood => 'Good nutritional balance';

  @override
  String get healthScoreTierModerate => 'Moderate balance';

  @override
  String get healthScoreTierLow => 'Low nutritional profile';

  @override
  String get healthScoreStatusStale => 'Modified since last calculation';

  @override
  String get healthScoreStatusFresh => 'Evaluated on current ingredients';

  @override
  String get healthScoreStatusEmpty => 'No saved details for this meal';

  @override
  String get healthScoreCalculating => 'Calculating score...';

  @override
  String get healthScoreAnalyzingIngredients => 'Analyzing ingredients...';

  @override
  String get healthScoreNoIngredientsHint =>
      'Add at least one ingredient to evaluate the nutritional quality of this meal.';

  @override
  String get healthScoreCalculateBtn => 'Calculate score';

  @override
  String get healthScoreRecalculateFullBtn => 'Recalculate score';

  @override
  String get healthScoreRecalculateBtn => 'Recalculate';

  @override
  String get healthScoreStaleHint =>
      'You edited ingredients or grams. Recalculate to update the score.';

  @override
  String get healthScoreNoExplanationHint =>
      'No explanation generated yet. Tap \"Recalculate score\" to analyze your ingredients.';

  @override
  String healthScorePreservedScore(int score) {
    return 'Current score preserved: $score/100';
  }

  @override
  String get healthScoreCurrentUnknown => 'Current score: ?/100';

  @override
  String get healthScoreErrorTitle => 'Could not calculate Health Score';

  @override
  String get healthScoreErrorMissingKey =>
      'AI evaluation requires GEMINI_API_KEY to be configured in this environment.';

  @override
  String get healthScoreErrorNetwork =>
      'Connection error. Check your internet access and try again.';

  @override
  String get healthScoreErrorTimeout =>
      'Evaluation timed out. Please try again in a few seconds.';

  @override
  String get healthScoreErrorRateLimit =>
      'Temporary request limit reached. Wait a moment and try again.';

  @override
  String get healthScoreErrorUnavailable =>
      'The evaluation service is currently unavailable. Please try later.';

  @override
  String get healthScoreErrorInvalidResponse =>
      'Could not parse the nutritional evaluation. Please try again.';

  @override
  String get healthScoreErrorNoIngredients =>
      'Add at least one ingredient to calculate the Health Score.';

  @override
  String get healthScoreErrorGeneric =>
      'Could not complete the nutritional evaluation. Please try again.';

  @override
  String get scannerTitle => 'Scan Meal';

  @override
  String get scannerCloseSemantics => 'Close scanner';

  @override
  String get scannerCloseTooltip => 'Close';

  @override
  String get scannerFlashOff => 'Turn flash off';

  @override
  String get scannerFlashOn => 'Turn flash on';

  @override
  String get scannerGallery => 'Library';

  @override
  String get scannerGallerySemantics => 'Choose photo from library';

  @override
  String get scannerManual => 'Manual';

  @override
  String get scannerManualSemantics => 'Build meal manually';

  @override
  String get scannerRetakeSemantics => 'Retake photo';

  @override
  String get scannerRetake => 'Retake';

  @override
  String get scannerCapturing => 'Opening camera...';

  @override
  String get scannerAnalyzing => 'Analyzing nutrients...';

  @override
  String get scannerTakingSeconds => 'This takes a few seconds';

  @override
  String get scannerErrorDismissSemantics => 'Dismiss error';

  @override
  String get scannerErrorDismissTooltip => 'Close notice';

  @override
  String get scannerPreferPantry => 'Use ingredients from my pantry';

  @override
  String get scannerCaptureSemantics => 'Scan plate with camera';

  @override
  String get scannerSamplePill => 'Sample';

  @override
  String get scannerSamplePillSemantics => 'Try with a real sample meal';

  @override
  String get scannerSampleTitle => 'No photo handy?';

  @override
  String get scannerSampleDescription =>
      'On web you can try the scanner with a real meal photo if you don\'t have one handy.';

  @override
  String get scannerSampleCta => 'Try sample meal';

  @override
  String get scannerSampleCloseSemantics => 'Close sample meal card';

  @override
  String get scannerSampleImageSemantics => 'Sample meal thumbnail';

  @override
  String get cameraUnavailableTitle => 'Live camera unavailable';

  @override
  String get cameraUnavailableSubtitle =>
      'Use your device camera, pick from your photo library, or build your meal manually.';

  @override
  String get brandConflictTitle => 'Choose brand';

  @override
  String brandConflictMessage(String genericName) {
    return 'We found multiple options in your pantry for \"$genericName\". Which one did you use?';
  }

  @override
  String brandConflictOptionMacros(
    int kcal,
    String portion,
    int protein,
    int carbs,
    int fat,
  ) {
    return '$kcal kcal per $portion · P ${protein}g · C ${carbs}g · F ${fat}g';
  }

  @override
  String get reviewManualBuildTag => 'Manual entry';

  @override
  String get reviewChangeNameTooltip => 'Rename meal';

  @override
  String get reviewMealNameTitle => 'Meal name';

  @override
  String get reviewMealNameHint => 'e.g., Light lunch, Post-workout bowl';

  @override
  String get reviewManualTotal => 'MEAL TOTAL';

  @override
  String get reviewDetectedTotal => 'DETECTED TOTAL';

  @override
  String reviewIngredientsCount(int count) {
    return 'Ingredients ($count)';
  }

  @override
  String reviewDetectedIngredientsCount(int count) {
    return 'Detected ingredients ($count)';
  }

  @override
  String get reviewSwipeToRemove => 'Swipe to remove';

  @override
  String get reviewAddMealBtn => 'Add meal';

  @override
  String get reviewNoIngredientsTitle => 'No ingredients added yet';

  @override
  String get reviewNoIngredientsSubtitle =>
      'Tap \"Add ingredient from My Pantry\" to build your meal.';

  @override
  String reviewMealAddedSnackbar(String title, int kcal) {
    return '$title added! (+$kcal kcal)';
  }

  @override
  String reviewDefaultMealTitle(int number) {
    return 'Meal $number';
  }

  @override
  String get scannerErrorMissingKey =>
      'AI analysis requires GEMINI_API_KEY to be configured in this environment.';

  @override
  String get scannerErrorMissingImage => 'No image was provided to analyze.';

  @override
  String get scannerErrorEmptyImage => 'The selected image is empty.';

  @override
  String get scannerErrorTooLarge => 'The image exceeds the 15 MB limit.';

  @override
  String get scannerErrorUnsupportedFormat =>
      'Unsupported image format. Use JPG, PNG, WEBP, or HEIC.';

  @override
  String get scannerErrorInvalidImage => 'The selected image is invalid.';

  @override
  String get scannerErrorCameraPerm =>
      'We need camera permission to scan the plate.';

  @override
  String get scannerErrorGalleryPerm =>
      'We need photo library permission to pick a photo.';

  @override
  String get scannerErrorNetwork =>
      'Connection error. Check your internet access and try again.';

  @override
  String get scannerErrorTimeout =>
      'Analysis took too long. Please try again in a few seconds.';

  @override
  String get scannerErrorRateLimit =>
      'Temporary request limit reached. Wait a moment and try again.';

  @override
  String get scannerErrorUnavailable =>
      'The analysis service is currently unavailable. Please try later.';

  @override
  String get scannerErrorInvalidResponse =>
      'Could not understand the AI response. Please try another photo.';

  @override
  String get scannerErrorNoFood =>
      'Could not recognize food in the photo. Try getting closer or using better lighting.';

  @override
  String get scannerErrorEmptyIngredients =>
      'Add at least one ingredient to calculate the Health Score.';

  @override
  String get scannerErrorUnknown =>
      'Could not process the meal. Please try again.';

  @override
  String get pantryTitle => 'My Pantry';

  @override
  String pantryActiveCount(int count) {
    return '$count active ingredients';
  }

  @override
  String get pantrySearchHint => 'Search food or brand...';

  @override
  String pantryAddSpecific(String query) {
    return 'Add \"$query\" to your pantry';
  }

  @override
  String get pantryAddNew => 'Add new ingredient';

  @override
  String get pantryAddSubtitle => 'Tap to enter serving size or scan';

  @override
  String get pantryInfoBanner =>
      'AI prioritizes these ingredients when logging meals by photo to calculate exact calories and macros.';

  @override
  String get pantryEditCatTitle => 'Edit name and icon';

  @override
  String get pantryDeleteCatTitle => 'Delete category';

  @override
  String get pantryDeleteCatSubtitle => 'Ingredients will move to \"Other\"';

  @override
  String pantryDeleteCatConfirmTitle(String categoryName) {
    return 'Delete \"$categoryName\"?';
  }

  @override
  String get pantryDeleteCatConfirmMsg =>
      'This category will be removed from your filters and its foods will move to \"Other\".';

  @override
  String get pantrySelectCatTitle => 'SELECT CATEGORY';

  @override
  String get pantryNewCatBtn => 'New category';

  @override
  String get pantryEditIngredient => 'EDIT INGREDIENT';

  @override
  String get pantryNewIngredient => 'NEW INGREDIENT';

  @override
  String get pantryEditIngredientSub =>
      'Update the nutritional values of this food.';

  @override
  String get pantryNewIngredientSub =>
      'Enter nutritional data for your package serving.';

  @override
  String get pantryProductLoaded => 'Product loaded';

  @override
  String pantryIngredientUpdated(String name, String portion) {
    return 'Updated: $name ($portion)';
  }

  @override
  String pantryIngredientAdded(String name, String portion) {
    return 'Added: $name ($portion)';
  }

  @override
  String get pantryFieldNameLabel => 'Food name *';

  @override
  String get pantryFieldNameHint =>
      'e.g., Whole Wheat Bread, Greek Yogurt, Crackers';

  @override
  String get pantryFieldBrandLabel => 'Brand (optional)';

  @override
  String get pantryFieldBrandHint => 'e.g., Dave\'s Killer Bread, Chobani';

  @override
  String get pantryFieldPortionLabel => 'Serving (g) *';

  @override
  String get pantryCategoryLabel => 'Nutrition Category';

  @override
  String get pantryNutritionValuesTitle => 'Nutrition Facts per Serving';

  @override
  String get pantryFieldCaloriesLabel => 'Calories *';

  @override
  String get pantrySaveIngredientBtn => 'Save ingredient';

  @override
  String get pantryErrEmptyName => 'Food name is required.';

  @override
  String get pantryErrInvalidCat => 'Select a valid nutrition category.';

  @override
  String get pantryErrNonPositiveGrams =>
      'Serving size must be greater than 0 grams.';

  @override
  String get pantryErrNegativeCalories => 'Calories cannot be negative.';

  @override
  String get pantryErrNegativeMacros => 'Macros cannot have negative values.';

  @override
  String get pantryErrNotFound => 'Ingredient not found to update.';

  @override
  String get catDialogEditTitle => 'Edit Category';

  @override
  String get catDialogNewTitle => 'New Category';

  @override
  String get catDialogNameHint => 'e.g., Supplements, Snacks';

  @override
  String get catDialogPickEmoji => 'Choose a food icon:';

  @override
  String get deleteIngredientTitle => 'Delete ingredient?';

  @override
  String deleteIngredientMessage(String name) {
    return '\"$name\" will be removed from your pantry.';
  }

  @override
  String ingredientPortionLabel(String portion) {
    return 'Serving: $portion';
  }

  @override
  String get ingredientPortionEnergy => 'Serving energy';

  @override
  String ingredientPer100g(int kcal, int p, int c, int g) {
    return 'Per 100g equivalent: $kcal kcal · P ${p}g · C ${c}g · F ${g}g';
  }

  @override
  String get selectPantryTitle => 'PICK FROM PANTRY';

  @override
  String get selectPantrySearchHint => 'Search by name or brand...';

  @override
  String get selectPantryNotFound => 'Ingredient not found';

  @override
  String get selectPantryNotFoundSub =>
      'You can add it right now to your pantry.';

  @override
  String get selectPantryCreateBtn => 'Create ingredient';

  @override
  String get selectPantryManualNewBtn => 'New manual ingredient';

  @override
  String get barcodeTitle => 'SCAN PRODUCT';

  @override
  String get barcodeSubtitle => 'Barcode or nutrition facts label';

  @override
  String get barcodeTabPhoto => 'Photo';

  @override
  String get barcodeTabCode => 'Barcode';

  @override
  String get barcodePhotoTitle => 'Take a photo of the product';

  @override
  String get barcodePhotoSubtitle =>
      'Scan the front of the package or the nutrition label to auto-fill its data.';

  @override
  String get barcodeTakePhoto => 'Take photo';

  @override
  String get barcodeUploadPhoto => 'Upload photo';

  @override
  String get barcodeInputHint => 'Enter the barcode digits';

  @override
  String get barcodeQuickExamples => 'Quick examples:';

  @override
  String get barcodeLoadingOpening => 'Opening...';

  @override
  String get barcodeLoadingAnalyzing => 'Analyzing product...';

  @override
  String get barcodeLoadingLookup => 'Looking up product...';

  @override
  String get barcodeResultPortion => 'Serving';

  @override
  String get barcodeResultCalories => 'Calories';

  @override
  String get barcodeRescan => 'Scan again';

  @override
  String get barcodeErrMissingKey =>
      'AI analysis requires GEMINI_API_KEY to be configured in this environment.';

  @override
  String get barcodeErrMissingCode => 'Enter the barcode digits.';

  @override
  String get barcodeErrInvalidCode => 'The entered barcode is not valid.';

  @override
  String get barcodeErrEmptyImage => 'The selected image is empty.';

  @override
  String get barcodeErrTooLarge => 'The image exceeds the 10 MB limit.';

  @override
  String get barcodeErrUnsupportedMime =>
      'Unsupported image format. Use JPG, PNG, WEBP, or HEIC.';

  @override
  String get barcodeErrCameraPerm =>
      'We need camera permission to scan the label.';

  @override
  String get barcodeErrGalleryPerm =>
      'We need photo library permission to choose a photo.';

  @override
  String get barcodeErrLabelNotFound =>
      'Could not detect a readable product. Try focusing more clearly on the nutrition table or barcode.';

  @override
  String barcodeErrProductNotFound(String code) {
    return 'We couldn\'t find product with barcode $code in the database.';
  }

  @override
  String get barcodeErrNetwork =>
      'Connection error. Check your internet access and try again.';

  @override
  String get barcodeErrTimeout =>
      'Lookup timed out. Please try again in a few seconds.';

  @override
  String get barcodeErrRateLimit =>
      'Temporary request limit reached. Wait a moment and try again.';

  @override
  String get barcodeErrUnavailable =>
      'The product service is currently unavailable. Please try later.';

  @override
  String get barcodeErrInvalidResponse =>
      'Could not parse the service response. Please try again.';

  @override
  String get barcodeErrUnknown =>
      'Could not process the request. Please try again.';

  @override
  String get profileTitle => 'MY PROFILE & GOALS';

  @override
  String get profileSubtitle => 'Targets and nutritional consistency';

  @override
  String profileGoalsUpdated(int kcal, int p, int c, int g) {
    return 'Goals updated: $kcal kcal · P ${p}g · C ${c}g · F ${g}g';
  }

  @override
  String get dailyGoalsTitle => 'DAILY GOALS';

  @override
  String get dailyGoalsKcalPerDay => 'kcal / day';

  @override
  String get editGoalsTitle => 'EDIT DAILY GOALS';

  @override
  String get editGoalsDailyKcal => 'Daily calorie target';

  @override
  String get editGoalsUpdateBtn => 'Update goals';

  @override
  String get toleranceRangeTitle => 'TOLERANCE RANGE';

  @override
  String get toleranceRangeSubtitle =>
      'Target window to complete your daily streak';

  @override
  String get toleranceValidWindow => 'VALID WINDOW';

  @override
  String get toleranceLowerLimit => 'Lower Limit (-)';

  @override
  String get toleranceLowerMin => 'Minimum required';

  @override
  String get toleranceUpperLimit => 'Upper Limit (+)';

  @override
  String get toleranceUpperMax => 'Maximum allowed';

  @override
  String get statsThisWeekFallback => 'This week';

  @override
  String statsWeekCurrent(String range) {
    return 'Current week ($range)';
  }

  @override
  String statsWeekLast(String range) {
    return 'Last week ($range)';
  }

  @override
  String statsWeekWeeksAgo(int count, String range) {
    return '$count weeks ago ($range)';
  }

  @override
  String statsWeekNext(String range) {
    return 'Next week ($range)';
  }

  @override
  String get statsWeekMonToSun => 'Monday to Sunday';

  @override
  String get statsStreakTitle => 'Streak';

  @override
  String statsStreakDays(int days) {
    return '$days d';
  }

  @override
  String get statsComplianceTitle => 'Compliance';

  @override
  String statsComplianceDays(int pct, int fulfilled, int total) {
    return '$pct% ($fulfilled/$total days)';
  }

  @override
  String get statsPantryUsageTitle => 'Pantry usage';

  @override
  String statsPantryUsagePct(int pct) {
    return '$pct% own pantry';
  }

  @override
  String get statsTopFoodsTitle => 'TOP FOODS OF THE WEEK';

  @override
  String get statsTopFoodsSubtitle =>
      'Biggest contributors to each macronutrient';

  @override
  String get statsNoMealsPeriod => 'No meals logged in this period.';

  @override
  String get statsNoMealsWeek => 'No meals logged for this week.';

  @override
  String statsTopContribution(String grams, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'meals',
      one: 'meal',
    );
    return '${grams}g contributed · $count $_temp0';
  }
}
