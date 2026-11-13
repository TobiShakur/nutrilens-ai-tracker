import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'NutriLens AI'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navPantry.
  ///
  /// In es, this message translates to:
  /// **'Alacena'**
  String get navPantry;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @navScanMealSemantics.
  ///
  /// In es, this message translates to:
  /// **'Escanear plato o cargar comida'**
  String get navScanMealSemantics;

  /// No description provided for @navScanMealTooltip.
  ///
  /// In es, this message translates to:
  /// **'Escanear plato'**
  String get navScanMealTooltip;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Modificar'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get remove;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @apply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get apply;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @create.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get create;

  /// No description provided for @choose.
  ///
  /// In es, this message translates to:
  /// **'Elegir'**
  String get choose;

  /// No description provided for @add.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get add;

  /// No description provided for @understood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get understood;

  /// No description provided for @gramsUnit.
  ///
  /// In es, this message translates to:
  /// **'gramos'**
  String get gramsUnit;

  /// No description provided for @gramsTotal.
  ///
  /// In es, this message translates to:
  /// **'{grams}g total'**
  String gramsTotal(int grams);

  /// No description provided for @kcalUnit.
  ///
  /// In es, this message translates to:
  /// **'kcal'**
  String get kcalUnit;

  /// No description provided for @pantryTag.
  ///
  /// In es, this message translates to:
  /// **'Alacena'**
  String get pantryTag;

  /// No description provided for @noBrand.
  ///
  /// In es, this message translates to:
  /// **'sin marca'**
  String get noBrand;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @selectLanguageTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegir idioma'**
  String get selectLanguageTitle;

  /// No description provided for @selectLanguageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'La app y el análisis con IA responderán en el idioma elegido.'**
  String get selectLanguageSubtitle;

  /// No description provided for @macroProtein.
  ///
  /// In es, this message translates to:
  /// **'Proteínas'**
  String get macroProtein;

  /// No description provided for @macroCarbs.
  ///
  /// In es, this message translates to:
  /// **'Carbos'**
  String get macroCarbs;

  /// No description provided for @macroFat.
  ///
  /// In es, this message translates to:
  /// **'Grasas'**
  String get macroFat;

  /// No description provided for @macroProteinUpper.
  ///
  /// In es, this message translates to:
  /// **'PROTEÍNAS'**
  String get macroProteinUpper;

  /// No description provided for @macroCarbsUpper.
  ///
  /// In es, this message translates to:
  /// **'CARBOHIDRATOS'**
  String get macroCarbsUpper;

  /// No description provided for @macroFatUpper.
  ///
  /// In es, this message translates to:
  /// **'GRASAS'**
  String get macroFatUpper;

  /// No description provided for @macroHealthyFatUpper.
  ///
  /// In es, this message translates to:
  /// **'GRASAS SALUDABLES'**
  String get macroHealthyFatUpper;

  /// No description provided for @macroProteinShort.
  ///
  /// In es, this message translates to:
  /// **'Prot'**
  String get macroProteinShort;

  /// No description provided for @macroCarbsShort.
  ///
  /// In es, this message translates to:
  /// **'Carbos'**
  String get macroCarbsShort;

  /// No description provided for @macroFatShort.
  ///
  /// In es, this message translates to:
  /// **'Grasas'**
  String get macroFatShort;

  /// No description provided for @mealTypeBreakfast.
  ///
  /// In es, this message translates to:
  /// **'Desayuno'**
  String get mealTypeBreakfast;

  /// No description provided for @mealTypeLunch.
  ///
  /// In es, this message translates to:
  /// **'Almuerzo'**
  String get mealTypeLunch;

  /// No description provided for @mealTypeSnackAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Merienda'**
  String get mealTypeSnackAfternoon;

  /// No description provided for @mealTypeDinner.
  ///
  /// In es, this message translates to:
  /// **'Cena'**
  String get mealTypeDinner;

  /// No description provided for @mealTypeSnack.
  ///
  /// In es, this message translates to:
  /// **'Snack'**
  String get mealTypeSnack;

  /// No description provided for @mealTypeGeneric.
  ///
  /// In es, this message translates to:
  /// **'Comida'**
  String get mealTypeGeneric;

  /// No description provided for @categoryAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get categoryAll;

  /// No description provided for @categoryProteins.
  ///
  /// In es, this message translates to:
  /// **'Proteínas'**
  String get categoryProteins;

  /// No description provided for @categoryCarbs.
  ///
  /// In es, this message translates to:
  /// **'Carbos'**
  String get categoryCarbs;

  /// No description provided for @categoryDairy.
  ///
  /// In es, this message translates to:
  /// **'Lácteos'**
  String get categoryDairy;

  /// No description provided for @categoryFats.
  ///
  /// In es, this message translates to:
  /// **'Grasas'**
  String get categoryFats;

  /// No description provided for @categoryVegetables.
  ///
  /// In es, this message translates to:
  /// **'Verduras / Frutas'**
  String get categoryVegetables;

  /// No description provided for @categoryOthers.
  ///
  /// In es, this message translates to:
  /// **'Otros / Especias'**
  String get categoryOthers;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @weekdaySun.
  ///
  /// In es, this message translates to:
  /// **'Do {day}'**
  String weekdaySun(int day);

  /// No description provided for @weekdayMon.
  ///
  /// In es, this message translates to:
  /// **'Lu {day}'**
  String weekdayMon(int day);

  /// No description provided for @weekdayTue.
  ///
  /// In es, this message translates to:
  /// **'Ma {day}'**
  String weekdayTue(int day);

  /// No description provided for @weekdayWed.
  ///
  /// In es, this message translates to:
  /// **'Mi {day}'**
  String weekdayWed(int day);

  /// No description provided for @weekdayThu.
  ///
  /// In es, this message translates to:
  /// **'Ju {day}'**
  String weekdayThu(int day);

  /// No description provided for @weekdayFri.
  ///
  /// In es, this message translates to:
  /// **'Vi {day}'**
  String weekdayFri(int day);

  /// No description provided for @weekdaySat.
  ///
  /// In es, this message translates to:
  /// **'Sa {day}'**
  String weekdaySat(int day);

  /// No description provided for @monthJan.
  ///
  /// In es, this message translates to:
  /// **'Ene'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In es, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In es, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In es, this message translates to:
  /// **'Abr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In es, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In es, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In es, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In es, this message translates to:
  /// **'Ago'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In es, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In es, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In es, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In es, this message translates to:
  /// **'Dic'**
  String get monthDec;

  /// No description provided for @greetingGoodDay.
  ///
  /// In es, this message translates to:
  /// **'Buen día,'**
  String get greetingGoodDay;

  /// No description provided for @streakNone.
  ///
  /// In es, this message translates to:
  /// **'Sin racha'**
  String get streakNone;

  /// No description provided for @streakOneDay.
  ///
  /// In es, this message translates to:
  /// **'1 día de racha'**
  String get streakOneDay;

  /// No description provided for @streakManyDays.
  ///
  /// In es, this message translates to:
  /// **'{days} días de racha'**
  String streakManyDays(int days);

  /// No description provided for @mealsCountLabel.
  ///
  /// In es, this message translates to:
  /// **'COMIDAS · {count}'**
  String mealsCountLabel(int count);

  /// No description provided for @noMealsThisDay.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay comidas este día'**
  String get noMealsThisDay;

  /// No description provided for @noMealsThisDayHint.
  ///
  /// In es, this message translates to:
  /// **'Tocá el botón de escanear para ver cómo se actualizan tus números.'**
  String get noMealsThisDayHint;

  /// No description provided for @calorieTargetTotal.
  ///
  /// In es, this message translates to:
  /// **'Meta Total'**
  String get calorieTargetTotal;

  /// No description provided for @calorieCriticalExcess.
  ///
  /// In es, this message translates to:
  /// **'¡Exceso Crítico!'**
  String get calorieCriticalExcess;

  /// No description provided for @calorieExcess.
  ///
  /// In es, this message translates to:
  /// **'¡Exceso!'**
  String get calorieExcess;

  /// No description provided for @calorieCurrent.
  ///
  /// In es, this message translates to:
  /// **'Actuales'**
  String get calorieCurrent;

  /// No description provided for @calorieExtras.
  ///
  /// In es, this message translates to:
  /// **'Extras'**
  String get calorieExtras;

  /// No description provided for @calorieRemaining.
  ///
  /// In es, this message translates to:
  /// **'Restantes'**
  String get calorieRemaining;

  /// No description provided for @deleteMealTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar comida?'**
  String get deleteMealTitle;

  /// No description provided for @deleteMealMessage.
  ///
  /// In es, this message translates to:
  /// **'Se eliminará \"{mealName}\" de tus comidas.'**
  String deleteMealMessage(String mealName);

  /// No description provided for @mealTimeLabel.
  ///
  /// In es, this message translates to:
  /// **'Hora: {time} hs'**
  String mealTimeLabel(String time);

  /// No description provided for @mealEnergyContribution.
  ///
  /// In es, this message translates to:
  /// **'Aporte energético'**
  String get mealEnergyContribution;

  /// No description provided for @mealTargetKcal.
  ///
  /// In es, this message translates to:
  /// **'Meta: {kcal} kcal'**
  String mealTargetKcal(int kcal);

  /// No description provided for @mealIngredientsCount.
  ///
  /// In es, this message translates to:
  /// **'Ingredientes ({count})'**
  String mealIngredientsCount(int count);

  /// No description provided for @editMealTitle.
  ///
  /// In es, this message translates to:
  /// **'Modificar comida'**
  String get editMealTitle;

  /// No description provided for @editMealSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustá ingredientes, porciones en gramos y macros.'**
  String get editMealSubtitle;

  /// No description provided for @editMealNoIngredients.
  ///
  /// In es, this message translates to:
  /// **'No hay ingredientes en esta comida'**
  String get editMealNoIngredients;

  /// No description provided for @removeIngredientTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar ingrediente?'**
  String get removeIngredientTitle;

  /// No description provided for @removeIngredientMessage.
  ///
  /// In es, this message translates to:
  /// **'Se quitará \"{name}\" de esta comida.'**
  String removeIngredientMessage(String name);

  /// No description provided for @addIngredientFromPantry.
  ///
  /// In es, this message translates to:
  /// **'Agregar ingrediente desde Mi Alacena'**
  String get addIngredientFromPantry;

  /// No description provided for @recalculatedTotal.
  ///
  /// In es, this message translates to:
  /// **'TOTAL RECALCULADO'**
  String get recalculatedTotal;

  /// No description provided for @mealUpdatedSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Comida modificada ({count} ingredientes · {kcal} kcal)'**
  String mealUpdatedSnackbar(int count, int kcal);

  /// No description provided for @gramsAmountTitle.
  ///
  /// In es, this message translates to:
  /// **'Cantidad en gramos'**
  String get gramsAmountTitle;

  /// No description provided for @healthScoreTitle.
  ///
  /// In es, this message translates to:
  /// **'Health Score'**
  String get healthScoreTitle;

  /// No description provided for @healthScoreSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Evaluación según ingredientes y porciones'**
  String get healthScoreSubtitle;

  /// No description provided for @healthScoreBannerNoRecords.
  ///
  /// In es, this message translates to:
  /// **'Todavía no registraste comidas hoy. Sumá un plato para ver tu puntaje nutricional.'**
  String get healthScoreBannerNoRecords;

  /// No description provided for @healthScoreBannerExcellent.
  ///
  /// In es, this message translates to:
  /// **'¡Excelente nutrición hoy! Tus elecciones de comida están súper balanceadas.'**
  String get healthScoreBannerExcellent;

  /// No description provided for @healthScoreBannerGood.
  ///
  /// In es, this message translates to:
  /// **'Muy buena calidad nutricional en tu día, seguí sumando comidas frescas.'**
  String get healthScoreBannerGood;

  /// No description provided for @healthScoreBannerModerate.
  ///
  /// In es, this message translates to:
  /// **'Buen camino nutricional; podés sumar más fibra o proteína magra hoy.'**
  String get healthScoreBannerModerate;

  /// No description provided for @healthScoreBannerLow.
  ///
  /// In es, this message translates to:
  /// **'Podés equilibrar tus próximas comidas con alimentos menos procesados.'**
  String get healthScoreBannerLow;

  /// No description provided for @healthScoreBadgeCalculating.
  ///
  /// In es, this message translates to:
  /// **'Calculando'**
  String get healthScoreBadgeCalculating;

  /// No description provided for @healthScoreSemanticsCalculating.
  ///
  /// In es, this message translates to:
  /// **'Calculando puntaje de salud.'**
  String get healthScoreSemanticsCalculating;

  /// No description provided for @healthScoreSemanticsError.
  ///
  /// In es, this message translates to:
  /// **'Error al calcular puntaje de salud, {score} de 100.'**
  String healthScoreSemanticsError(String score);

  /// No description provided for @healthScoreSemanticsUnscored.
  ///
  /// In es, this message translates to:
  /// **'Puntaje de salud sin calcular, ? de 100. Tocá para calcular con IA.'**
  String get healthScoreSemanticsUnscored;

  /// No description provided for @healthScoreSemanticsStale.
  ///
  /// In es, this message translates to:
  /// **'Puntaje de salud desactualizado, {score} de 100. Tocá para recalcular según tus cambios.'**
  String healthScoreSemanticsStale(int score);

  /// No description provided for @healthScoreSemanticsFresh.
  ///
  /// In es, this message translates to:
  /// **'Puntaje de salud {score} de 100. Tocá para ver la explicación o recalcular.'**
  String healthScoreSemanticsFresh(int score);

  /// No description provided for @healthScoreTierExcellent.
  ///
  /// In es, this message translates to:
  /// **'Calidad nutricional excelente'**
  String get healthScoreTierExcellent;

  /// No description provided for @healthScoreTierGood.
  ///
  /// In es, this message translates to:
  /// **'Buen balance nutricional'**
  String get healthScoreTierGood;

  /// No description provided for @healthScoreTierModerate.
  ///
  /// In es, this message translates to:
  /// **'Balance moderado'**
  String get healthScoreTierModerate;

  /// No description provided for @healthScoreTierLow.
  ///
  /// In es, this message translates to:
  /// **'Perfil nutricional bajo'**
  String get healthScoreTierLow;

  /// No description provided for @healthScoreStatusStale.
  ///
  /// In es, this message translates to:
  /// **'Modificado desde el último cálculo'**
  String get healthScoreStatusStale;

  /// No description provided for @healthScoreStatusFresh.
  ///
  /// In es, this message translates to:
  /// **'Evaluado sobre los ingredientes actuales'**
  String get healthScoreStatusFresh;

  /// No description provided for @healthScoreStatusEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin detalle guardado para esta comida'**
  String get healthScoreStatusEmpty;

  /// No description provided for @healthScoreCalculating.
  ///
  /// In es, this message translates to:
  /// **'Calculando puntaje...'**
  String get healthScoreCalculating;

  /// No description provided for @healthScoreAnalyzingIngredients.
  ///
  /// In es, this message translates to:
  /// **'Analizando ingredientes...'**
  String get healthScoreAnalyzingIngredients;

  /// No description provided for @healthScoreNoIngredientsHint.
  ///
  /// In es, this message translates to:
  /// **'Agregá al menos un ingrediente para evaluar la calidad nutricional de esta comida.'**
  String get healthScoreNoIngredientsHint;

  /// No description provided for @healthScoreCalculateBtn.
  ///
  /// In es, this message translates to:
  /// **'Calcular puntaje'**
  String get healthScoreCalculateBtn;

  /// No description provided for @healthScoreRecalculateFullBtn.
  ///
  /// In es, this message translates to:
  /// **'Recalcular puntaje'**
  String get healthScoreRecalculateFullBtn;

  /// No description provided for @healthScoreRecalculateBtn.
  ///
  /// In es, this message translates to:
  /// **'Recalcular'**
  String get healthScoreRecalculateBtn;

  /// No description provided for @healthScoreStaleHint.
  ///
  /// In es, this message translates to:
  /// **'Editaste ingredientes o gramos. Recalculá para actualizar el puntaje.'**
  String get healthScoreStaleHint;

  /// No description provided for @healthScoreNoExplanationHint.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay una explicación generada. Tocá \"Recalcular puntaje\" para obtener el análisis de tus ingredientes.'**
  String get healthScoreNoExplanationHint;

  /// No description provided for @healthScorePreservedScore.
  ///
  /// In es, this message translates to:
  /// **'Puntaje actual conservado: {score}/100'**
  String healthScorePreservedScore(int score);

  /// No description provided for @healthScoreCurrentUnknown.
  ///
  /// In es, this message translates to:
  /// **'Puntaje actual: ?/100'**
  String get healthScoreCurrentUnknown;

  /// No description provided for @healthScoreErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo calcular el Health Score'**
  String get healthScoreErrorTitle;

  /// No description provided for @healthScoreErrorMissingKey.
  ///
  /// In es, this message translates to:
  /// **'La evaluación con IA requiere configurar GEMINI_API_KEY en este entorno.'**
  String get healthScoreErrorMissingKey;

  /// No description provided for @healthScoreErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Verificá tu acceso a internet e intentá nuevamente.'**
  String get healthScoreErrorNetwork;

  /// No description provided for @healthScoreErrorTimeout.
  ///
  /// In es, this message translates to:
  /// **'La evaluación tardó demasiado. Intentá nuevamente en unos segundos.'**
  String get healthScoreErrorTimeout;

  /// No description provided for @healthScoreErrorRateLimit.
  ///
  /// In es, this message translates to:
  /// **'Alcanzamos el límite temporal de consultas. Esperá un momento e intentá de nuevo.'**
  String get healthScoreErrorRateLimit;

  /// No description provided for @healthScoreErrorUnavailable.
  ///
  /// In es, this message translates to:
  /// **'El servicio de evaluación no está disponible en este momento. Probá más tarde.'**
  String get healthScoreErrorUnavailable;

  /// No description provided for @healthScoreErrorInvalidResponse.
  ///
  /// In es, this message translates to:
  /// **'No pudimos interpretar la evaluación nutricional. Intentá nuevamente.'**
  String get healthScoreErrorInvalidResponse;

  /// No description provided for @healthScoreErrorNoIngredients.
  ///
  /// In es, this message translates to:
  /// **'Agregá al menos un ingrediente para calcular el Health Score.'**
  String get healthScoreErrorNoIngredients;

  /// No description provided for @healthScoreErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la evaluación nutricional. Intentá nuevamente.'**
  String get healthScoreErrorGeneric;

  /// No description provided for @scannerTitle.
  ///
  /// In es, this message translates to:
  /// **'Escanear Plato'**
  String get scannerTitle;

  /// No description provided for @scannerCloseSemantics.
  ///
  /// In es, this message translates to:
  /// **'Cerrar escáner'**
  String get scannerCloseSemantics;

  /// No description provided for @scannerCloseTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get scannerCloseTooltip;

  /// No description provided for @scannerFlashOff.
  ///
  /// In es, this message translates to:
  /// **'Apagar flash'**
  String get scannerFlashOff;

  /// No description provided for @scannerFlashOn.
  ///
  /// In es, this message translates to:
  /// **'Encender flash'**
  String get scannerFlashOn;

  /// No description provided for @scannerGallery.
  ///
  /// In es, this message translates to:
  /// **'Fototeca'**
  String get scannerGallery;

  /// No description provided for @scannerGallerySemantics.
  ///
  /// In es, this message translates to:
  /// **'Elegir foto de fototeca'**
  String get scannerGallerySemantics;

  /// No description provided for @scannerManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get scannerManual;

  /// No description provided for @scannerManualSemantics.
  ///
  /// In es, this message translates to:
  /// **'Armar comida manual'**
  String get scannerManualSemantics;

  /// No description provided for @scannerRetakeSemantics.
  ///
  /// In es, this message translates to:
  /// **'Retomar foto'**
  String get scannerRetakeSemantics;

  /// No description provided for @scannerRetake.
  ///
  /// In es, this message translates to:
  /// **'Retomar'**
  String get scannerRetake;

  /// No description provided for @scannerCapturing.
  ///
  /// In es, this message translates to:
  /// **'Abriendo cámara...'**
  String get scannerCapturing;

  /// No description provided for @scannerAnalyzing.
  ///
  /// In es, this message translates to:
  /// **'Analizando nutrientes...'**
  String get scannerAnalyzing;

  /// No description provided for @scannerTakingSeconds.
  ///
  /// In es, this message translates to:
  /// **'Esto toma unos segundos'**
  String get scannerTakingSeconds;

  /// No description provided for @scannerErrorDismissSemantics.
  ///
  /// In es, this message translates to:
  /// **'Descartar error'**
  String get scannerErrorDismissSemantics;

  /// No description provided for @scannerErrorDismissTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cerrar aviso'**
  String get scannerErrorDismissTooltip;

  /// No description provided for @scannerPreferPantry.
  ///
  /// In es, this message translates to:
  /// **'Usar ingredientes de mi alacena'**
  String get scannerPreferPantry;

  /// No description provided for @scannerCaptureSemantics.
  ///
  /// In es, this message translates to:
  /// **'Escanear plato con cámara'**
  String get scannerCaptureSemantics;

  /// No description provided for @scannerSamplePill.
  ///
  /// In es, this message translates to:
  /// **'Prueba'**
  String get scannerSamplePill;

  /// No description provided for @scannerSamplePillSemantics.
  ///
  /// In es, this message translates to:
  /// **'Probar con plato real de ejemplo'**
  String get scannerSamplePillSemantics;

  /// No description provided for @scannerSampleTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Sin foto a mano?'**
  String get scannerSampleTitle;

  /// No description provided for @scannerSampleDescription.
  ///
  /// In es, this message translates to:
  /// **'En web podés probar el escáner con un plato real si no tenés una foto a mano.'**
  String get scannerSampleDescription;

  /// No description provided for @scannerSampleCta.
  ///
  /// In es, this message translates to:
  /// **'Probar con plato real'**
  String get scannerSampleCta;

  /// No description provided for @scannerSampleCloseSemantics.
  ///
  /// In es, this message translates to:
  /// **'Cerrar aviso de plato de prueba'**
  String get scannerSampleCloseSemantics;

  /// No description provided for @scannerSampleImageSemantics.
  ///
  /// In es, this message translates to:
  /// **'Miniatura del plato de prueba'**
  String get scannerSampleImageSemantics;

  /// No description provided for @cameraUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Cámara en vivo no disponible'**
  String get cameraUnavailableTitle;

  /// No description provided for @cameraUnavailableSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usá la cámara del dispositivo, elegí de tu fototeca o armá tu comida manual.'**
  String get cameraUnavailableSubtitle;

  /// No description provided for @brandConflictTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegí la marca'**
  String get brandConflictTitle;

  /// No description provided for @brandConflictMessage.
  ///
  /// In es, this message translates to:
  /// **'Detectamos varias opciones en tu alacena para \"{genericName}\". ¿Cuál usaste?'**
  String brandConflictMessage(String genericName);

  /// No description provided for @brandConflictOptionMacros.
  ///
  /// In es, this message translates to:
  /// **'{kcal} kcal por {portion} · P {protein}g · C {carbs}g · G {fat}g'**
  String brandConflictOptionMacros(
    int kcal,
    String portion,
    int protein,
    int carbs,
    int fat,
  );

  /// No description provided for @reviewManualBuildTag.
  ///
  /// In es, this message translates to:
  /// **'Armado manual'**
  String get reviewManualBuildTag;

  /// No description provided for @reviewChangeNameTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cambiar nombre'**
  String get reviewChangeNameTooltip;

  /// No description provided for @reviewMealNameTitle.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la comida'**
  String get reviewMealNameTitle;

  /// No description provided for @reviewMealNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Almuerzo liviano, Bowl post entreno'**
  String get reviewMealNameHint;

  /// No description provided for @reviewManualTotal.
  ///
  /// In es, this message translates to:
  /// **'TOTAL DE LA COMIDA'**
  String get reviewManualTotal;

  /// No description provided for @reviewDetectedTotal.
  ///
  /// In es, this message translates to:
  /// **'TOTAL DETECTADO'**
  String get reviewDetectedTotal;

  /// No description provided for @reviewIngredientsCount.
  ///
  /// In es, this message translates to:
  /// **'Ingredientes ({count})'**
  String reviewIngredientsCount(int count);

  /// No description provided for @reviewDetectedIngredientsCount.
  ///
  /// In es, this message translates to:
  /// **'Ingredientes detectados ({count})'**
  String reviewDetectedIngredientsCount(int count);

  /// No description provided for @reviewSwipeToRemove.
  ///
  /// In es, this message translates to:
  /// **'Deslizá para quitar'**
  String get reviewSwipeToRemove;

  /// No description provided for @reviewAddMealBtn.
  ///
  /// In es, this message translates to:
  /// **'Agregar comida'**
  String get reviewAddMealBtn;

  /// No description provided for @reviewNoIngredientsTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no agregaste ingredientes'**
  String get reviewNoIngredientsTitle;

  /// No description provided for @reviewNoIngredientsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tocá \"Agregar ingrediente desde Mi Alacena\" para armar tu comida.'**
  String get reviewNoIngredientsSubtitle;

  /// No description provided for @reviewMealAddedSnackbar.
  ///
  /// In es, this message translates to:
  /// **'¡{title} agregada! (+{kcal} kcal)'**
  String reviewMealAddedSnackbar(String title, int kcal);

  /// No description provided for @reviewDefaultMealTitle.
  ///
  /// In es, this message translates to:
  /// **'Comida {number}'**
  String reviewDefaultMealTitle(int number);

  /// No description provided for @scannerErrorMissingKey.
  ///
  /// In es, this message translates to:
  /// **'La función con IA requiere configurar GEMINI_API_KEY en este entorno.'**
  String get scannerErrorMissingKey;

  /// No description provided for @scannerErrorMissingImage.
  ///
  /// In es, this message translates to:
  /// **'No se recibió ninguna imagen para analizar.'**
  String get scannerErrorMissingImage;

  /// No description provided for @scannerErrorEmptyImage.
  ///
  /// In es, this message translates to:
  /// **'La imagen seleccionada está vacía.'**
  String get scannerErrorEmptyImage;

  /// No description provided for @scannerErrorTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La imagen supera el máximo permitido de 15 MB.'**
  String get scannerErrorTooLarge;

  /// No description provided for @scannerErrorUnsupportedFormat.
  ///
  /// In es, this message translates to:
  /// **'Formato de imagen no soportado. Usá JPG, PNG, WEBP o HEIC.'**
  String get scannerErrorUnsupportedFormat;

  /// No description provided for @scannerErrorInvalidImage.
  ///
  /// In es, this message translates to:
  /// **'La imagen seleccionada no es válida.'**
  String get scannerErrorInvalidImage;

  /// No description provided for @scannerErrorCameraPerm.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos permiso de cámara para escanear el plato.'**
  String get scannerErrorCameraPerm;

  /// No description provided for @scannerErrorGalleryPerm.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos permiso de galería para elegir una foto.'**
  String get scannerErrorGalleryPerm;

  /// No description provided for @scannerErrorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Verificá tu acceso a internet e intentá nuevamente.'**
  String get scannerErrorNetwork;

  /// No description provided for @scannerErrorTimeout.
  ///
  /// In es, this message translates to:
  /// **'El análisis tardó demasiado. Intentá nuevamente en unos segundos.'**
  String get scannerErrorTimeout;

  /// No description provided for @scannerErrorRateLimit.
  ///
  /// In es, this message translates to:
  /// **'Alcanzamos el límite temporal de consultas. Esperá un momento e intentá de nuevo.'**
  String get scannerErrorRateLimit;

  /// No description provided for @scannerErrorUnavailable.
  ///
  /// In es, this message translates to:
  /// **'El servicio de análisis no está disponible en este momento. Probá más tarde.'**
  String get scannerErrorUnavailable;

  /// No description provided for @scannerErrorInvalidResponse.
  ///
  /// In es, this message translates to:
  /// **'No pudimos interpretar la respuesta de la IA. Intentá con otra foto.'**
  String get scannerErrorInvalidResponse;

  /// No description provided for @scannerErrorNoFood.
  ///
  /// In es, this message translates to:
  /// **'No pudimos reconocer alimentos en la foto. Probá más de cerca o con mejor luz.'**
  String get scannerErrorNoFood;

  /// No description provided for @scannerErrorEmptyIngredients.
  ///
  /// In es, this message translates to:
  /// **'Agregá al menos un ingrediente para calcular el Health Score.'**
  String get scannerErrorEmptyIngredients;

  /// No description provided for @scannerErrorUnknown.
  ///
  /// In es, this message translates to:
  /// **'No pudimos procesar la comida. Intentá nuevamente.'**
  String get scannerErrorUnknown;

  /// No description provided for @pantryTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi Alacena'**
  String get pantryTitle;

  /// No description provided for @pantryActiveCount.
  ///
  /// In es, this message translates to:
  /// **'{count} ingredientes activos'**
  String pantryActiveCount(int count);

  /// No description provided for @pantrySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar alimento o marca...'**
  String get pantrySearchHint;

  /// No description provided for @pantryAddSpecific.
  ///
  /// In es, this message translates to:
  /// **'Sumar \"{query}\" a tu alacena'**
  String pantryAddSpecific(String query);

  /// No description provided for @pantryAddNew.
  ///
  /// In es, this message translates to:
  /// **'Agregar nuevo ingrediente'**
  String get pantryAddNew;

  /// No description provided for @pantryAddSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tocá para cargar porción o escanear'**
  String get pantryAddSubtitle;

  /// No description provided for @pantryInfoBanner.
  ///
  /// In es, this message translates to:
  /// **'La IA prioriza estos ingredientes al registrar tus comidas con foto, para calcular calorías y macros exactas.'**
  String get pantryInfoBanner;

  /// No description provided for @pantryEditCatTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar nombre e ícono'**
  String get pantryEditCatTitle;

  /// No description provided for @pantryDeleteCatTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar categoría'**
  String get pantryDeleteCatTitle;

  /// No description provided for @pantryDeleteCatSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los ingredientes pasarán a \"Otros\"'**
  String get pantryDeleteCatSubtitle;

  /// No description provided for @pantryDeleteCatConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{categoryName}\"?'**
  String pantryDeleteCatConfirmTitle(String categoryName);

  /// No description provided for @pantryDeleteCatConfirmMsg.
  ///
  /// In es, this message translates to:
  /// **'Esta categoría se quitará de tus filtros y los alimentos asociados se moverán a la categoría \"Otros\".'**
  String get pantryDeleteCatConfirmMsg;

  /// No description provided for @pantrySelectCatTitle.
  ///
  /// In es, this message translates to:
  /// **'SELECCIONAR CATEGORÍA'**
  String get pantrySelectCatTitle;

  /// No description provided for @pantryNewCatBtn.
  ///
  /// In es, this message translates to:
  /// **'Nueva categoría'**
  String get pantryNewCatBtn;

  /// No description provided for @pantryEditIngredient.
  ///
  /// In es, this message translates to:
  /// **'MODIFICAR INGREDIENTE'**
  String get pantryEditIngredient;

  /// No description provided for @pantryNewIngredient.
  ///
  /// In es, this message translates to:
  /// **'NUEVO INGREDIENTE'**
  String get pantryNewIngredient;

  /// No description provided for @pantryEditIngredientSub.
  ///
  /// In es, this message translates to:
  /// **'Actualizá los valores de este alimento.'**
  String get pantryEditIngredientSub;

  /// No description provided for @pantryNewIngredientSub.
  ///
  /// In es, this message translates to:
  /// **'Cargá los datos según tu porción de paquete.'**
  String get pantryNewIngredientSub;

  /// No description provided for @pantryProductLoaded.
  ///
  /// In es, this message translates to:
  /// **'Producto cargado'**
  String get pantryProductLoaded;

  /// No description provided for @pantryIngredientUpdated.
  ///
  /// In es, this message translates to:
  /// **'Modificado: {name} ({portion})'**
  String pantryIngredientUpdated(String name, String portion);

  /// No description provided for @pantryIngredientAdded.
  ///
  /// In es, this message translates to:
  /// **'Agregado: {name} ({portion})'**
  String pantryIngredientAdded(String name, String portion);

  /// No description provided for @pantryFieldNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del alimento *'**
  String get pantryFieldNameLabel;

  /// No description provided for @pantryFieldNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Pan Integral, Yogur Griego, Galletitas'**
  String get pantryFieldNameHint;

  /// No description provided for @pantryFieldBrandLabel.
  ///
  /// In es, this message translates to:
  /// **'Marca (opcional)'**
  String get pantryFieldBrandLabel;

  /// No description provided for @pantryFieldBrandHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Fargo, La Serenísima'**
  String get pantryFieldBrandHint;

  /// No description provided for @pantryFieldPortionLabel.
  ///
  /// In es, this message translates to:
  /// **'Porción (g) *'**
  String get pantryFieldPortionLabel;

  /// No description provided for @pantryCategoryLabel.
  ///
  /// In es, this message translates to:
  /// **'Categoría Nutricional'**
  String get pantryCategoryLabel;

  /// No description provided for @pantryNutritionValuesTitle.
  ///
  /// In es, this message translates to:
  /// **'Valores Nutricionales de la Porción'**
  String get pantryNutritionValuesTitle;

  /// No description provided for @pantryFieldCaloriesLabel.
  ///
  /// In es, this message translates to:
  /// **'Calorías *'**
  String get pantryFieldCaloriesLabel;

  /// No description provided for @pantrySaveIngredientBtn.
  ///
  /// In es, this message translates to:
  /// **'Guardar ingrediente'**
  String get pantrySaveIngredientBtn;

  /// No description provided for @pantryErrEmptyName.
  ///
  /// In es, this message translates to:
  /// **'El nombre del ingrediente es obligatorio.'**
  String get pantryErrEmptyName;

  /// No description provided for @pantryErrInvalidCat.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná una categoría nutricional válida.'**
  String get pantryErrInvalidCat;

  /// No description provided for @pantryErrNonPositiveGrams.
  ///
  /// In es, this message translates to:
  /// **'El tamaño de porción debe ser mayor a 0 gramos.'**
  String get pantryErrNonPositiveGrams;

  /// No description provided for @pantryErrNegativeCalories.
  ///
  /// In es, this message translates to:
  /// **'Las calorías no pueden ser negativas.'**
  String get pantryErrNegativeCalories;

  /// No description provided for @pantryErrNegativeMacros.
  ///
  /// In es, this message translates to:
  /// **'Los macros no pueden tener valores negativos.'**
  String get pantryErrNegativeMacros;

  /// No description provided for @pantryErrNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el ingrediente para modificar.'**
  String get pantryErrNotFound;

  /// No description provided for @catDialogEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Categoría'**
  String get catDialogEditTitle;

  /// No description provided for @catDialogNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva Categoría'**
  String get catDialogNewTitle;

  /// No description provided for @catDialogNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Suplementos, Snacks'**
  String get catDialogNameHint;

  /// No description provided for @catDialogPickEmoji.
  ///
  /// In es, this message translates to:
  /// **'Elegí un ícono de comida:'**
  String get catDialogPickEmoji;

  /// No description provided for @deleteIngredientTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar ingrediente?'**
  String get deleteIngredientTitle;

  /// No description provided for @deleteIngredientMessage.
  ///
  /// In es, this message translates to:
  /// **'Se quitará \"{name}\" de tu alacena.'**
  String deleteIngredientMessage(String name);

  /// No description provided for @ingredientPortionLabel.
  ///
  /// In es, this message translates to:
  /// **'Porción: {portion}'**
  String ingredientPortionLabel(String portion);

  /// No description provided for @ingredientPortionEnergy.
  ///
  /// In es, this message translates to:
  /// **'Energía de la porción'**
  String get ingredientPortionEnergy;

  /// No description provided for @ingredientPer100g.
  ///
  /// In es, this message translates to:
  /// **'Equivalente cada 100g: {kcal} kcal · P {p}g · C {c}g · G {g}g'**
  String ingredientPer100g(int kcal, int p, int c, int g);

  /// No description provided for @selectPantryTitle.
  ///
  /// In es, this message translates to:
  /// **'SELECCIONAR DE ALACENA'**
  String get selectPantryTitle;

  /// No description provided for @selectPantrySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre o marca...'**
  String get selectPantrySearchHint;

  /// No description provided for @selectPantryNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos este ingrediente'**
  String get selectPantryNotFound;

  /// No description provided for @selectPantryNotFoundSub.
  ///
  /// In es, this message translates to:
  /// **'Podés sumarlo ahora mismo a tu alacena.'**
  String get selectPantryNotFoundSub;

  /// No description provided for @selectPantryCreateBtn.
  ///
  /// In es, this message translates to:
  /// **'Crear ingrediente'**
  String get selectPantryCreateBtn;

  /// No description provided for @selectPantryManualNewBtn.
  ///
  /// In es, this message translates to:
  /// **'Nuevo ingrediente manual'**
  String get selectPantryManualNewBtn;

  /// No description provided for @barcodeTitle.
  ///
  /// In es, this message translates to:
  /// **'ESCANEAR PRODUCTO'**
  String get barcodeTitle;

  /// No description provided for @barcodeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Código de barras o tabla nutricional'**
  String get barcodeSubtitle;

  /// No description provided for @barcodeTabPhoto.
  ///
  /// In es, this message translates to:
  /// **'Foto'**
  String get barcodeTabPhoto;

  /// No description provided for @barcodeTabCode.
  ///
  /// In es, this message translates to:
  /// **'Código de barras'**
  String get barcodeTabCode;

  /// No description provided for @barcodePhotoTitle.
  ///
  /// In es, this message translates to:
  /// **'Sacale una foto al producto'**
  String get barcodePhotoTitle;

  /// No description provided for @barcodePhotoSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escaneá el frente del envase o la tabla nutricional para cargar sus datos.'**
  String get barcodePhotoSubtitle;

  /// No description provided for @barcodeTakePhoto.
  ///
  /// In es, this message translates to:
  /// **'Sacar foto'**
  String get barcodeTakePhoto;

  /// No description provided for @barcodeUploadPhoto.
  ///
  /// In es, this message translates to:
  /// **'Subir foto'**
  String get barcodeUploadPhoto;

  /// No description provided for @barcodeInputHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresá el código de barras'**
  String get barcodeInputHint;

  /// No description provided for @barcodeQuickExamples.
  ///
  /// In es, this message translates to:
  /// **'Ejemplos rápidos:'**
  String get barcodeQuickExamples;

  /// No description provided for @barcodeLoadingOpening.
  ///
  /// In es, this message translates to:
  /// **'Abriendo...'**
  String get barcodeLoadingOpening;

  /// No description provided for @barcodeLoadingAnalyzing.
  ///
  /// In es, this message translates to:
  /// **'Analizando producto...'**
  String get barcodeLoadingAnalyzing;

  /// No description provided for @barcodeLoadingLookup.
  ///
  /// In es, this message translates to:
  /// **'Buscando producto...'**
  String get barcodeLoadingLookup;

  /// No description provided for @barcodeResultPortion.
  ///
  /// In es, this message translates to:
  /// **'Porción'**
  String get barcodeResultPortion;

  /// No description provided for @barcodeResultCalories.
  ///
  /// In es, this message translates to:
  /// **'Calorías'**
  String get barcodeResultCalories;

  /// No description provided for @barcodeRescan.
  ///
  /// In es, this message translates to:
  /// **'Volver a escanear'**
  String get barcodeRescan;

  /// No description provided for @barcodeErrMissingKey.
  ///
  /// In es, this message translates to:
  /// **'La función con IA requiere configurar GEMINI_API_KEY en este entorno.'**
  String get barcodeErrMissingKey;

  /// No description provided for @barcodeErrMissingCode.
  ///
  /// In es, this message translates to:
  /// **'Ingresá los números del código de barras.'**
  String get barcodeErrMissingCode;

  /// No description provided for @barcodeErrInvalidCode.
  ///
  /// In es, this message translates to:
  /// **'El código de barras ingresado no es válido.'**
  String get barcodeErrInvalidCode;

  /// No description provided for @barcodeErrEmptyImage.
  ///
  /// In es, this message translates to:
  /// **'La imagen seleccionada está vacía.'**
  String get barcodeErrEmptyImage;

  /// No description provided for @barcodeErrTooLarge.
  ///
  /// In es, this message translates to:
  /// **'La imagen supera el máximo permitido de 10 MB.'**
  String get barcodeErrTooLarge;

  /// No description provided for @barcodeErrUnsupportedMime.
  ///
  /// In es, this message translates to:
  /// **'Formato de imagen no soportado. Usá JPG, PNG, WEBP o HEIC.'**
  String get barcodeErrUnsupportedMime;

  /// No description provided for @barcodeErrCameraPerm.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos permiso de cámara para escanear la etiqueta.'**
  String get barcodeErrCameraPerm;

  /// No description provided for @barcodeErrGalleryPerm.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos permiso de galería para elegir una foto.'**
  String get barcodeErrGalleryPerm;

  /// No description provided for @barcodeErrLabelNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se pudo detectar un producto legible. Probá enfocando mejor la tabla nutricional o el código.'**
  String get barcodeErrLabelNotFound;

  /// No description provided for @barcodeErrProductNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos el producto con código {code} en la base de datos.'**
  String barcodeErrProductNotFound(String code);

  /// No description provided for @barcodeErrNetwork.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Verificá tu acceso a internet e intentá nuevamente.'**
  String get barcodeErrNetwork;

  /// No description provided for @barcodeErrTimeout.
  ///
  /// In es, this message translates to:
  /// **'La consulta tardó demasiado. Intentá nuevamente en unos segundos.'**
  String get barcodeErrTimeout;

  /// No description provided for @barcodeErrRateLimit.
  ///
  /// In es, this message translates to:
  /// **'Alcanzamos el límite temporal de consultas. Esperá un momento e intentá de nuevo.'**
  String get barcodeErrRateLimit;

  /// No description provided for @barcodeErrUnavailable.
  ///
  /// In es, this message translates to:
  /// **'El servicio de productos no está disponible en este momento. Probá más tarde.'**
  String get barcodeErrUnavailable;

  /// No description provided for @barcodeErrInvalidResponse.
  ///
  /// In es, this message translates to:
  /// **'No pudimos interpretar la respuesta del servicio. Intentá nuevamente.'**
  String get barcodeErrInvalidResponse;

  /// No description provided for @barcodeErrUnknown.
  ///
  /// In es, this message translates to:
  /// **'No se pudo procesar la solicitud. Intentá nuevamente.'**
  String get barcodeErrUnknown;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'MI PERFIL & METAS'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Objetivos y consistencia nutricional'**
  String get profileSubtitle;

  /// No description provided for @profileGoalsUpdated.
  ///
  /// In es, this message translates to:
  /// **'Metas actualizadas: {kcal} kcal · P {p}g · C {c}g · G {g}g'**
  String profileGoalsUpdated(int kcal, int p, int c, int g);

  /// No description provided for @dailyGoalsTitle.
  ///
  /// In es, this message translates to:
  /// **'METAS DIARIAS'**
  String get dailyGoalsTitle;

  /// No description provided for @dailyGoalsKcalPerDay.
  ///
  /// In es, this message translates to:
  /// **'kcal / día'**
  String get dailyGoalsKcalPerDay;

  /// No description provided for @editGoalsTitle.
  ///
  /// In es, this message translates to:
  /// **'MODIFICAR METAS DIARIAS'**
  String get editGoalsTitle;

  /// No description provided for @editGoalsDailyKcal.
  ///
  /// In es, this message translates to:
  /// **'Calorías diarias objetivo'**
  String get editGoalsDailyKcal;

  /// No description provided for @editGoalsUpdateBtn.
  ///
  /// In es, this message translates to:
  /// **'Actualizar metas'**
  String get editGoalsUpdateBtn;

  /// No description provided for @toleranceRangeTitle.
  ///
  /// In es, this message translates to:
  /// **'RANGO DE TOLERANCIA'**
  String get toleranceRangeTitle;

  /// No description provided for @toleranceRangeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Margen de éxito para completar tu racha diaria'**
  String get toleranceRangeSubtitle;

  /// No description provided for @toleranceValidWindow.
  ///
  /// In es, this message translates to:
  /// **'VENTANA VÁLIDA'**
  String get toleranceValidWindow;

  /// No description provided for @toleranceLowerLimit.
  ///
  /// In es, this message translates to:
  /// **'Límite Inferior (-)'**
  String get toleranceLowerLimit;

  /// No description provided for @toleranceLowerMin.
  ///
  /// In es, this message translates to:
  /// **'Mínimo requerido'**
  String get toleranceLowerMin;

  /// No description provided for @toleranceUpperLimit.
  ///
  /// In es, this message translates to:
  /// **'Límite Superior (+)'**
  String get toleranceUpperLimit;

  /// No description provided for @toleranceUpperMax.
  ///
  /// In es, this message translates to:
  /// **'Máximo admitido'**
  String get toleranceUpperMax;

  /// No description provided for @statsThisWeekFallback.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get statsThisWeekFallback;

  /// No description provided for @statsWeekCurrent.
  ///
  /// In es, this message translates to:
  /// **'Semana actual ({range})'**
  String statsWeekCurrent(String range);

  /// No description provided for @statsWeekLast.
  ///
  /// In es, this message translates to:
  /// **'Semana pasada ({range})'**
  String statsWeekLast(String range);

  /// No description provided for @statsWeekWeeksAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {count} semanas ({range})'**
  String statsWeekWeeksAgo(int count, String range);

  /// No description provided for @statsWeekNext.
  ///
  /// In es, this message translates to:
  /// **'Semana siguiente ({range})'**
  String statsWeekNext(String range);

  /// No description provided for @statsWeekMonToSun.
  ///
  /// In es, this message translates to:
  /// **'Lunes a Domingo'**
  String get statsWeekMonToSun;

  /// No description provided for @statsStreakTitle.
  ///
  /// In es, this message translates to:
  /// **'Racha'**
  String get statsStreakTitle;

  /// No description provided for @statsStreakDays.
  ///
  /// In es, this message translates to:
  /// **'{days} d'**
  String statsStreakDays(int days);

  /// No description provided for @statsComplianceTitle.
  ///
  /// In es, this message translates to:
  /// **'Cumplimiento'**
  String get statsComplianceTitle;

  /// No description provided for @statsComplianceDays.
  ///
  /// In es, this message translates to:
  /// **'{pct}% ({fulfilled}/{total} días)'**
  String statsComplianceDays(int pct, int fulfilled, int total);

  /// No description provided for @statsPantryUsageTitle.
  ///
  /// In es, this message translates to:
  /// **'Aprovechamiento de alacena'**
  String get statsPantryUsageTitle;

  /// No description provided for @statsPantryUsagePct.
  ///
  /// In es, this message translates to:
  /// **'{pct}% alacena propia'**
  String statsPantryUsagePct(int pct);

  /// No description provided for @statsTopFoodsTitle.
  ///
  /// In es, this message translates to:
  /// **'TOP ALIMENTOS DE LA SEMANA'**
  String get statsTopFoodsTitle;

  /// No description provided for @statsTopFoodsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los que mayor aporte dieron a cada macronutriente'**
  String get statsTopFoodsSubtitle;

  /// No description provided for @statsNoMealsPeriod.
  ///
  /// In es, this message translates to:
  /// **'Sin comidas registradas en este período.'**
  String get statsNoMealsPeriod;

  /// No description provided for @statsNoMealsWeek.
  ///
  /// In es, this message translates to:
  /// **'No hay comidas registradas para esta semana.'**
  String get statsNoMealsWeek;

  /// No description provided for @statsTopContribution.
  ///
  /// In es, this message translates to:
  /// **'{grams}g aportados · {count} {count, plural, =1{comida} other{comidas}}'**
  String statsTopContribution(String grams, int count);
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
