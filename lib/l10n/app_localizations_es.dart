// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'NutriLens AI';

  @override
  String get navHome => 'Inicio';

  @override
  String get navPantry => 'Alacena';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navScanMealSemantics => 'Escanear plato o cargar comida';

  @override
  String get navScanMealTooltip => 'Escanear plato';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get edit => 'Modificar';

  @override
  String get delete => 'Eliminar';

  @override
  String get remove => 'Quitar';

  @override
  String get close => 'Cerrar';

  @override
  String get retry => 'Reintentar';

  @override
  String get apply => 'Aplicar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get create => 'Crear';

  @override
  String get choose => 'Elegir';

  @override
  String get add => 'Agregar';

  @override
  String get understood => 'Entendido';

  @override
  String get gramsUnit => 'gramos';

  @override
  String gramsTotal(int grams) {
    return '${grams}g total';
  }

  @override
  String get kcalUnit => 'kcal';

  @override
  String get pantryTag => 'Alacena';

  @override
  String get noBrand => 'sin marca';

  @override
  String get language => 'Idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get selectLanguageTitle => 'Elegir idioma';

  @override
  String get selectLanguageSubtitle =>
      'La app y el análisis con IA responderán en el idioma elegido.';

  @override
  String get macroProtein => 'Proteínas';

  @override
  String get macroCarbs => 'Carbos';

  @override
  String get macroFat => 'Grasas';

  @override
  String get macroProteinUpper => 'PROTEÍNAS';

  @override
  String get macroCarbsUpper => 'CARBOHIDRATOS';

  @override
  String get macroFatUpper => 'GRASAS';

  @override
  String get macroHealthyFatUpper => 'GRASAS SALUDABLES';

  @override
  String get macroProteinShort => 'Prot';

  @override
  String get macroCarbsShort => 'Carbos';

  @override
  String get macroFatShort => 'Grasas';

  @override
  String get mealTypeBreakfast => 'Desayuno';

  @override
  String get mealTypeLunch => 'Almuerzo';

  @override
  String get mealTypeSnackAfternoon => 'Merienda';

  @override
  String get mealTypeDinner => 'Cena';

  @override
  String get mealTypeSnack => 'Snack';

  @override
  String get mealTypeGeneric => 'Comida';

  @override
  String get categoryAll => 'Todos';

  @override
  String get categoryProteins => 'Proteínas';

  @override
  String get categoryCarbs => 'Carbos';

  @override
  String get categoryDairy => 'Lácteos';

  @override
  String get categoryFats => 'Grasas';

  @override
  String get categoryVegetables => 'Verduras / Frutas';

  @override
  String get categoryOthers => 'Otros / Especias';

  @override
  String get today => 'Hoy';

  @override
  String weekdaySun(int day) {
    return 'Do $day';
  }

  @override
  String weekdayMon(int day) {
    return 'Lu $day';
  }

  @override
  String weekdayTue(int day) {
    return 'Ma $day';
  }

  @override
  String weekdayWed(int day) {
    return 'Mi $day';
  }

  @override
  String weekdayThu(int day) {
    return 'Ju $day';
  }

  @override
  String weekdayFri(int day) {
    return 'Vi $day';
  }

  @override
  String weekdaySat(int day) {
    return 'Sa $day';
  }

  @override
  String get monthJan => 'Ene';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Abr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Ago';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dic';

  @override
  String get greetingGoodDay => 'Buen día,';

  @override
  String get streakNone => 'Sin racha';

  @override
  String get streakOneDay => '1 día de racha';

  @override
  String streakManyDays(int days) {
    return '$days días de racha';
  }

  @override
  String mealsCountLabel(int count) {
    return 'COMIDAS · $count';
  }

  @override
  String get noMealsThisDay => 'Todavía no hay comidas este día';

  @override
  String get noMealsThisDayHint =>
      'Tocá el botón de escanear para ver cómo se actualizan tus números.';

  @override
  String get calorieTargetTotal => 'Meta Total';

  @override
  String get calorieCriticalExcess => '¡Exceso Crítico!';

  @override
  String get calorieExcess => '¡Exceso!';

  @override
  String get calorieCurrent => 'Actuales';

  @override
  String get calorieExtras => 'Extras';

  @override
  String get calorieRemaining => 'Restantes';

  @override
  String get deleteMealTitle => '¿Eliminar comida?';

  @override
  String deleteMealMessage(String mealName) {
    return 'Se eliminará \"$mealName\" de tus comidas.';
  }

  @override
  String mealTimeLabel(String time) {
    return 'Hora: $time hs';
  }

  @override
  String get mealEnergyContribution => 'Aporte energético';

  @override
  String mealTargetKcal(int kcal) {
    return 'Meta: $kcal kcal';
  }

  @override
  String mealIngredientsCount(int count) {
    return 'Ingredientes ($count)';
  }

  @override
  String get editMealTitle => 'Modificar comida';

  @override
  String get editMealSubtitle =>
      'Ajustá ingredientes, porciones en gramos y macros.';

  @override
  String get editMealNoIngredients => 'No hay ingredientes en esta comida';

  @override
  String get removeIngredientTitle => '¿Quitar ingrediente?';

  @override
  String removeIngredientMessage(String name) {
    return 'Se quitará \"$name\" de esta comida.';
  }

  @override
  String get addIngredientFromPantry => 'Agregar ingrediente desde Mi Alacena';

  @override
  String get recalculatedTotal => 'TOTAL RECALCULADO';

  @override
  String mealUpdatedSnackbar(int count, int kcal) {
    return 'Comida modificada ($count ingredientes · $kcal kcal)';
  }

  @override
  String get gramsAmountTitle => 'Cantidad en gramos';

  @override
  String get healthScoreTitle => 'Health Score';

  @override
  String get healthScoreSubtitle => 'Evaluación según ingredientes y porciones';

  @override
  String get healthScoreBannerNoRecords =>
      'Todavía no registraste comidas hoy. Sumá un plato para ver tu puntaje nutricional.';

  @override
  String get healthScoreBannerExcellent =>
      '¡Excelente nutrición hoy! Tus elecciones de comida están súper balanceadas.';

  @override
  String get healthScoreBannerGood =>
      'Muy buena calidad nutricional en tu día, seguí sumando comidas frescas.';

  @override
  String get healthScoreBannerModerate =>
      'Buen camino nutricional; podés sumar más fibra o proteína magra hoy.';

  @override
  String get healthScoreBannerLow =>
      'Podés equilibrar tus próximas comidas con alimentos menos procesados.';

  @override
  String get healthScoreBadgeCalculating => 'Calculando';

  @override
  String get healthScoreSemanticsCalculating => 'Calculando puntaje de salud.';

  @override
  String healthScoreSemanticsError(String score) {
    return 'Error al calcular puntaje de salud, $score de 100.';
  }

  @override
  String get healthScoreSemanticsUnscored =>
      'Puntaje de salud sin calcular, ? de 100. Tocá para calcular con IA.';

  @override
  String healthScoreSemanticsStale(int score) {
    return 'Puntaje de salud desactualizado, $score de 100. Tocá para recalcular según tus cambios.';
  }

  @override
  String healthScoreSemanticsFresh(int score) {
    return 'Puntaje de salud $score de 100. Tocá para ver la explicación o recalcular.';
  }

  @override
  String get healthScoreTierExcellent => 'Calidad nutricional excelente';

  @override
  String get healthScoreTierGood => 'Buen balance nutricional';

  @override
  String get healthScoreTierModerate => 'Balance moderado';

  @override
  String get healthScoreTierLow => 'Perfil nutricional bajo';

  @override
  String get healthScoreStatusStale => 'Modificado desde el último cálculo';

  @override
  String get healthScoreStatusFresh =>
      'Evaluado sobre los ingredientes actuales';

  @override
  String get healthScoreStatusEmpty => 'Sin detalle guardado para esta comida';

  @override
  String get healthScoreCalculating => 'Calculando puntaje...';

  @override
  String get healthScoreAnalyzingIngredients => 'Analizando ingredientes...';

  @override
  String get healthScoreNoIngredientsHint =>
      'Agregá al menos un ingrediente para evaluar la calidad nutricional de esta comida.';

  @override
  String get healthScoreCalculateBtn => 'Calcular puntaje';

  @override
  String get healthScoreRecalculateFullBtn => 'Recalcular puntaje';

  @override
  String get healthScoreRecalculateBtn => 'Recalcular';

  @override
  String get healthScoreStaleHint =>
      'Editaste ingredientes o gramos. Recalculá para actualizar el puntaje.';

  @override
  String get healthScoreNoExplanationHint =>
      'Todavía no hay una explicación generada. Tocá \"Recalcular puntaje\" para obtener el análisis de tus ingredientes.';

  @override
  String healthScorePreservedScore(int score) {
    return 'Puntaje actual conservado: $score/100';
  }

  @override
  String get healthScoreCurrentUnknown => 'Puntaje actual: ?/100';

  @override
  String get healthScoreErrorTitle => 'No se pudo calcular el Health Score';

  @override
  String get healthScoreErrorMissingKey =>
      'La evaluación con IA requiere configurar GEMINI_API_KEY en este entorno.';

  @override
  String get healthScoreErrorNetwork =>
      'Error de conexión. Verificá tu acceso a internet e intentá nuevamente.';

  @override
  String get healthScoreErrorTimeout =>
      'La evaluación tardó demasiado. Intentá nuevamente en unos segundos.';

  @override
  String get healthScoreErrorRateLimit =>
      'Alcanzamos el límite temporal de consultas. Esperá un momento e intentá de nuevo.';

  @override
  String get healthScoreErrorUnavailable =>
      'El servicio de evaluación no está disponible en este momento. Probá más tarde.';

  @override
  String get healthScoreErrorInvalidResponse =>
      'No pudimos interpretar la evaluación nutricional. Intentá nuevamente.';

  @override
  String get healthScoreErrorNoIngredients =>
      'Agregá al menos un ingrediente para calcular el Health Score.';

  @override
  String get healthScoreErrorGeneric =>
      'No pudimos completar la evaluación nutricional. Intentá nuevamente.';

  @override
  String get scannerTitle => 'Escanear Plato';

  @override
  String get scannerCloseSemantics => 'Cerrar escáner';

  @override
  String get scannerCloseTooltip => 'Cerrar';

  @override
  String get scannerFlashOff => 'Apagar flash';

  @override
  String get scannerFlashOn => 'Encender flash';

  @override
  String get scannerGallery => 'Fototeca';

  @override
  String get scannerGallerySemantics => 'Elegir foto de fototeca';

  @override
  String get scannerManual => 'Manual';

  @override
  String get scannerManualSemantics => 'Armar comida manual';

  @override
  String get scannerRetakeSemantics => 'Retomar foto';

  @override
  String get scannerRetake => 'Retomar';

  @override
  String get scannerCapturing => 'Abriendo cámara...';

  @override
  String get scannerAnalyzing => 'Analizando nutrientes...';

  @override
  String get scannerTakingSeconds => 'Esto toma unos segundos';

  @override
  String get scannerErrorDismissSemantics => 'Descartar error';

  @override
  String get scannerErrorDismissTooltip => 'Cerrar aviso';

  @override
  String get scannerPreferPantry => 'Usar ingredientes de mi alacena';

  @override
  String get scannerCaptureSemantics => 'Escanear plato con cámara';

  @override
  String get cameraUnavailableTitle => 'Cámara en vivo no disponible';

  @override
  String get cameraUnavailableSubtitle =>
      'Usá la cámara del dispositivo, elegí de tu fototeca o armá tu comida manual.';

  @override
  String get brandConflictTitle => 'Elegí la marca';

  @override
  String brandConflictMessage(String genericName) {
    return 'Detectamos varias opciones en tu alacena para \"$genericName\". ¿Cuál usaste?';
  }

  @override
  String brandConflictOptionMacros(
    int kcal,
    String portion,
    int protein,
    int carbs,
    int fat,
  ) {
    return '$kcal kcal por $portion · P ${protein}g · C ${carbs}g · G ${fat}g';
  }

  @override
  String get reviewManualBuildTag => 'Armado manual';

  @override
  String get reviewChangeNameTooltip => 'Cambiar nombre';

  @override
  String get reviewMealNameTitle => 'Nombre de la comida';

  @override
  String get reviewMealNameHint => 'Ej: Almuerzo liviano, Bowl post entreno';

  @override
  String get reviewManualTotal => 'TOTAL DE LA COMIDA';

  @override
  String get reviewDetectedTotal => 'TOTAL DETECTADO';

  @override
  String reviewIngredientsCount(int count) {
    return 'Ingredientes ($count)';
  }

  @override
  String reviewDetectedIngredientsCount(int count) {
    return 'Ingredientes detectados ($count)';
  }

  @override
  String get reviewSwipeToRemove => 'Deslizá para quitar';

  @override
  String get reviewAddMealBtn => 'Agregar comida';

  @override
  String get reviewNoIngredientsTitle => 'Todavía no agregaste ingredientes';

  @override
  String get reviewNoIngredientsSubtitle =>
      'Tocá \"Agregar ingrediente desde Mi Alacena\" para armar tu comida.';

  @override
  String reviewMealAddedSnackbar(String title, int kcal) {
    return '¡$title agregada! (+$kcal kcal)';
  }

  @override
  String reviewDefaultMealTitle(int number) {
    return 'Comida $number';
  }

  @override
  String get scannerErrorMissingKey =>
      'La función con IA requiere configurar GEMINI_API_KEY en este entorno.';

  @override
  String get scannerErrorMissingImage =>
      'No se recibió ninguna imagen para analizar.';

  @override
  String get scannerErrorEmptyImage => 'La imagen seleccionada está vacía.';

  @override
  String get scannerErrorTooLarge =>
      'La imagen supera el máximo permitido de 15 MB.';

  @override
  String get scannerErrorUnsupportedFormat =>
      'Formato de imagen no soportado. Usá JPG, PNG, WEBP o HEIC.';

  @override
  String get scannerErrorInvalidImage => 'La imagen seleccionada no es válida.';

  @override
  String get scannerErrorCameraPerm =>
      'Necesitamos permiso de cámara para escanear el plato.';

  @override
  String get scannerErrorGalleryPerm =>
      'Necesitamos permiso de galería para elegir una foto.';

  @override
  String get scannerErrorNetwork =>
      'Error de conexión. Verificá tu acceso a internet e intentá nuevamente.';

  @override
  String get scannerErrorTimeout =>
      'El análisis tardó demasiado. Intentá nuevamente en unos segundos.';

  @override
  String get scannerErrorRateLimit =>
      'Alcanzamos el límite temporal de consultas. Esperá un momento e intentá de nuevo.';

  @override
  String get scannerErrorUnavailable =>
      'El servicio de análisis no está disponible en este momento. Probá más tarde.';

  @override
  String get scannerErrorInvalidResponse =>
      'No pudimos interpretar la respuesta de la IA. Intentá con otra foto.';

  @override
  String get scannerErrorNoFood =>
      'No pudimos reconocer alimentos en la foto. Probá más de cerca o con mejor luz.';

  @override
  String get scannerErrorEmptyIngredients =>
      'Agregá al menos un ingrediente para calcular el Health Score.';

  @override
  String get scannerErrorUnknown =>
      'No pudimos procesar la comida. Intentá nuevamente.';

  @override
  String get pantryTitle => 'Mi Alacena';

  @override
  String pantryActiveCount(int count) {
    return '$count ingredientes activos';
  }

  @override
  String get pantrySearchHint => 'Buscar alimento o marca...';

  @override
  String pantryAddSpecific(String query) {
    return 'Sumar \"$query\" a tu alacena';
  }

  @override
  String get pantryAddNew => 'Agregar nuevo ingrediente';

  @override
  String get pantryAddSubtitle => 'Tocá para cargar porción o escanear';

  @override
  String get pantryInfoBanner =>
      'La IA prioriza estos ingredientes al registrar tus comidas con foto, para calcular calorías y macros exactas.';

  @override
  String get pantryEditCatTitle => 'Editar nombre e ícono';

  @override
  String get pantryDeleteCatTitle => 'Eliminar categoría';

  @override
  String get pantryDeleteCatSubtitle => 'Los ingredientes pasarán a \"Otros\"';

  @override
  String pantryDeleteCatConfirmTitle(String categoryName) {
    return '¿Eliminar \"$categoryName\"?';
  }

  @override
  String get pantryDeleteCatConfirmMsg =>
      'Esta categoría se quitará de tus filtros y los alimentos asociados se moverán a la categoría \"Otros\".';

  @override
  String get pantrySelectCatTitle => 'SELECCIONAR CATEGORÍA';

  @override
  String get pantryNewCatBtn => 'Nueva categoría';

  @override
  String get pantryEditIngredient => 'MODIFICAR INGREDIENTE';

  @override
  String get pantryNewIngredient => 'NUEVO INGREDIENTE';

  @override
  String get pantryEditIngredientSub =>
      'Actualizá los valores de este alimento.';

  @override
  String get pantryNewIngredientSub =>
      'Cargá los datos según tu porción de paquete.';

  @override
  String get pantryProductLoaded => 'Producto cargado';

  @override
  String pantryIngredientUpdated(String name, String portion) {
    return 'Modificado: $name ($portion)';
  }

  @override
  String pantryIngredientAdded(String name, String portion) {
    return 'Agregado: $name ($portion)';
  }

  @override
  String get pantryFieldNameLabel => 'Nombre del alimento *';

  @override
  String get pantryFieldNameHint =>
      'Ej: Pan Integral, Yogur Griego, Galletitas';

  @override
  String get pantryFieldBrandLabel => 'Marca (opcional)';

  @override
  String get pantryFieldBrandHint => 'Ej: Fargo, La Serenísima';

  @override
  String get pantryFieldPortionLabel => 'Porción (g) *';

  @override
  String get pantryCategoryLabel => 'Categoría Nutricional';

  @override
  String get pantryNutritionValuesTitle =>
      'Valores Nutricionales de la Porción';

  @override
  String get pantryFieldCaloriesLabel => 'Calorías *';

  @override
  String get pantrySaveIngredientBtn => 'Guardar ingrediente';

  @override
  String get pantryErrEmptyName => 'El nombre del ingrediente es obligatorio.';

  @override
  String get pantryErrInvalidCat =>
      'Seleccioná una categoría nutricional válida.';

  @override
  String get pantryErrNonPositiveGrams =>
      'El tamaño de porción debe ser mayor a 0 gramos.';

  @override
  String get pantryErrNegativeCalories =>
      'Las calorías no pueden ser negativas.';

  @override
  String get pantryErrNegativeMacros =>
      'Los macros no pueden tener valores negativos.';

  @override
  String get pantryErrNotFound =>
      'No se encontró el ingrediente para modificar.';

  @override
  String get catDialogEditTitle => 'Editar Categoría';

  @override
  String get catDialogNewTitle => 'Nueva Categoría';

  @override
  String get catDialogNameHint => 'Ej: Suplementos, Snacks';

  @override
  String get catDialogPickEmoji => 'Elegí un ícono de comida:';

  @override
  String get deleteIngredientTitle => '¿Eliminar ingrediente?';

  @override
  String deleteIngredientMessage(String name) {
    return 'Se quitará \"$name\" de tu alacena.';
  }

  @override
  String ingredientPortionLabel(String portion) {
    return 'Porción: $portion';
  }

  @override
  String get ingredientPortionEnergy => 'Energía de la porción';

  @override
  String ingredientPer100g(int kcal, int p, int c, int g) {
    return 'Equivalente cada 100g: $kcal kcal · P ${p}g · C ${c}g · G ${g}g';
  }

  @override
  String get selectPantryTitle => 'SELECCIONAR DE ALACENA';

  @override
  String get selectPantrySearchHint => 'Buscar por nombre o marca...';

  @override
  String get selectPantryNotFound => 'No encontramos este ingrediente';

  @override
  String get selectPantryNotFoundSub =>
      'Podés sumarlo ahora mismo a tu alacena.';

  @override
  String get selectPantryCreateBtn => 'Crear ingrediente';

  @override
  String get selectPantryManualNewBtn => 'Nuevo ingrediente manual';

  @override
  String get barcodeTitle => 'ESCANEAR PRODUCTO';

  @override
  String get barcodeSubtitle => 'Código de barras o tabla nutricional';

  @override
  String get barcodeTabPhoto => 'Foto';

  @override
  String get barcodeTabCode => 'Código de barras';

  @override
  String get barcodePhotoTitle => 'Sacale una foto al producto';

  @override
  String get barcodePhotoSubtitle =>
      'Escaneá el frente del envase o la tabla nutricional para cargar sus datos.';

  @override
  String get barcodeTakePhoto => 'Sacar foto';

  @override
  String get barcodeUploadPhoto => 'Subir foto';

  @override
  String get barcodeInputHint => 'Ingresá el código de barras';

  @override
  String get barcodeQuickExamples => 'Ejemplos rápidos:';

  @override
  String get barcodeLoadingOpening => 'Abriendo...';

  @override
  String get barcodeLoadingAnalyzing => 'Analizando producto...';

  @override
  String get barcodeLoadingLookup => 'Buscando producto...';

  @override
  String get barcodeResultPortion => 'Porción';

  @override
  String get barcodeResultCalories => 'Calorías';

  @override
  String get barcodeRescan => 'Volver a escanear';

  @override
  String get barcodeErrMissingKey =>
      'La función con IA requiere configurar GEMINI_API_KEY en este entorno.';

  @override
  String get barcodeErrMissingCode =>
      'Ingresá los números del código de barras.';

  @override
  String get barcodeErrInvalidCode =>
      'El código de barras ingresado no es válido.';

  @override
  String get barcodeErrEmptyImage => 'La imagen seleccionada está vacía.';

  @override
  String get barcodeErrTooLarge =>
      'La imagen supera el máximo permitido de 10 MB.';

  @override
  String get barcodeErrUnsupportedMime =>
      'Formato de imagen no soportado. Usá JPG, PNG, WEBP o HEIC.';

  @override
  String get barcodeErrCameraPerm =>
      'Necesitamos permiso de cámara para escanear la etiqueta.';

  @override
  String get barcodeErrGalleryPerm =>
      'Necesitamos permiso de galería para elegir una foto.';

  @override
  String get barcodeErrLabelNotFound =>
      'No se pudo detectar un producto legible. Probá enfocando mejor la tabla nutricional o el código.';

  @override
  String barcodeErrProductNotFound(String code) {
    return 'No encontramos el producto con código $code en la base de datos.';
  }

  @override
  String get barcodeErrNetwork =>
      'Error de conexión. Verificá tu acceso a internet e intentá nuevamente.';

  @override
  String get barcodeErrTimeout =>
      'La consulta tardó demasiado. Intentá nuevamente en unos segundos.';

  @override
  String get barcodeErrRateLimit =>
      'Alcanzamos el límite temporal de consultas. Esperá un momento e intentá de nuevo.';

  @override
  String get barcodeErrUnavailable =>
      'El servicio de productos no está disponible en este momento. Probá más tarde.';

  @override
  String get barcodeErrInvalidResponse =>
      'No pudimos interpretar la respuesta del servicio. Intentá nuevamente.';

  @override
  String get barcodeErrUnknown =>
      'No se pudo procesar la solicitud. Intentá nuevamente.';

  @override
  String get profileTitle => 'MI PERFIL & METAS';

  @override
  String get profileSubtitle => 'Objetivos y consistencia nutricional';

  @override
  String profileGoalsUpdated(int kcal, int p, int c, int g) {
    return 'Metas actualizadas: $kcal kcal · P ${p}g · C ${c}g · G ${g}g';
  }

  @override
  String get dailyGoalsTitle => 'METAS DIARIAS';

  @override
  String get dailyGoalsKcalPerDay => 'kcal / día';

  @override
  String get editGoalsTitle => 'MODIFICAR METAS DIARIAS';

  @override
  String get editGoalsDailyKcal => 'Calorías diarias objetivo';

  @override
  String get editGoalsUpdateBtn => 'Actualizar metas';

  @override
  String get toleranceRangeTitle => 'RANGO DE TOLERANCIA';

  @override
  String get toleranceRangeSubtitle =>
      'Margen de éxito para completar tu racha diaria';

  @override
  String get toleranceValidWindow => 'VENTANA VÁLIDA';

  @override
  String get toleranceLowerLimit => 'Límite Inferior (-)';

  @override
  String get toleranceLowerMin => 'Mínimo requerido';

  @override
  String get toleranceUpperLimit => 'Límite Superior (+)';

  @override
  String get toleranceUpperMax => 'Máximo admitido';

  @override
  String get statsThisWeekFallback => 'Esta semana';

  @override
  String statsWeekCurrent(String range) {
    return 'Semana actual ($range)';
  }

  @override
  String statsWeekLast(String range) {
    return 'Semana pasada ($range)';
  }

  @override
  String statsWeekWeeksAgo(int count, String range) {
    return 'Hace $count semanas ($range)';
  }

  @override
  String statsWeekNext(String range) {
    return 'Semana siguiente ($range)';
  }

  @override
  String get statsWeekMonToSun => 'Lunes a Domingo';

  @override
  String get statsStreakTitle => 'Racha';

  @override
  String statsStreakDays(int days) {
    return '$days d';
  }

  @override
  String get statsComplianceTitle => 'Cumplimiento';

  @override
  String statsComplianceDays(int pct, int fulfilled, int total) {
    return '$pct% ($fulfilled/$total días)';
  }

  @override
  String get statsPantryUsageTitle => 'Aprovechamiento de alacena';

  @override
  String statsPantryUsagePct(int pct) {
    return '$pct% alacena propia';
  }

  @override
  String get statsTopFoodsTitle => 'TOP ALIMENTOS DE LA SEMANA';

  @override
  String get statsTopFoodsSubtitle =>
      'Los que mayor aporte dieron a cada macronutriente';

  @override
  String get statsNoMealsPeriod => 'Sin comidas registradas en este período.';

  @override
  String get statsNoMealsWeek => 'No hay comidas registradas para esta semana.';

  @override
  String statsTopContribution(String grams, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'comidas',
      one: 'comida',
    );
    return '${grams}g aportados · $count $_temp0';
  }
}
