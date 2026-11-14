# Performance Engineering Report — `nutrilens_provider`

**Debug HUD URL Query:** `?perf=1`  
**Keyboard Shortcut:** `Ctrl + Shift + P` or `Alt + P` (toggles `PerfDebugOverlay` anytime; zero runtime overhead when hidden)

---

## 1. Telemetry & Debug Tooling Implemented

### 1.1 Browser-Level Boot & Resource Instrumentation (`window.__portfolioPerf`)
- **Files:** `web/index.html`, `web/flutter_bootstrap.js`
- **Native Pre-Flutter Curtain (`#initial-loader`):**
  - Renders immediately on HTML first paint over `#07140E` (matching `AppColors.webBg`) with a wireframe-only Flutter SVG logo (`#9AA4B2` stroke) and a `120×2px` minimalist gliding bar below (replacing Flutter's default loader).
  - Dismisses cleanly on the `app-ready` DOM event (dispatched by Dart's `notifyAppReady()` after first frame, `GoogleFonts.pendingFonts()`, and `precacheImage()` settle, guarded by a `1500ms` Dart warmup timeout and a `2000ms` JS fallback timeout) with an upward translate (`-56px`), scale (`0.96`), opacity, and `backdrop-filter` blur transition.
- **Captured Timeline Marks & Stage Durations (`performance.now()` + `PerformanceObserver`):**
  - `htmlFirstPaintMs` (`first-contentful-paint` / `first-paint`)
  - `engineLoadMs` (`loaderStartMs` -> `engineInitEndMs`)
  - `dartBootMs` (`runAppStartMs` -> `runAppEndMs`)
  - `assetsAndFontsMs` (`runAppEndMs` -> `readyEventMs`)
  - `totalReadyMs` (`readyEventMs`, with `readySource`: `'flutter'` vs `'fallback-timeout'`)
- **Network & Memory Breakdown:**
  - Resource entries bucketed by `wasm`, `js`, `images`, `fonts`, and `other` (`transferSizeKb` and `decodedBodySizeKb`), plus cache-hit / opaque CDN detection and `performance.memory` (`jsHeapUsedMb` / `jsHeapTotalMb`).

### 1.2 In-App DevTools HUD (`PerfDebugOverlay`)
- **Files:**
  - `lib/core/services/perf_telemetry_models.dart`
  - `lib/core/services/perf_telemetry_service.dart` / `_platform.dart` / `_web.dart` / `_stub.dart`
  - `lib/core/services/app_ready_notifier.dart` / `_web.dart` / `_stub.dart`
  - `lib/widgets/perf_debug_overlay.dart`
  - `lib/main.dart` (`NutriLensApp` `MaterialApp.builder` `Stack` above `DesktopWrapper`)
- **Features:**
  - Zero runtime overhead when hidden (`SizedBox.shrink()`, `addTimingsCallback` only registered while visible).
  - Live boot timeline proportion bar, JS Heap & Flutter `PaintingBinding.instance.imageCache` (`Raster Cache`) readouts, network payload breakdown, rolling 60-frame FPS / UI Build / GPU Raster / Jank (`>16.6ms`) metrics, and `localStorage` baseline comparator (`nutrilens_perf_baseline_v1` via `Save as Baseline`, `Clear`, `Refresh`).

---

## 2. Optimizations Applied

### 2.1 Asset Compression & `ImageCache` Unification
Converted the bundled dish preview photo to WebP and updated all code, asset manifest, and test references (`pubspec.yaml`, `scanner_screen.dart`, `scanner_screen_widget_test.dart`, `scanner_viewmodel_test.dart`):

| Asset | Before (Format / Dims / Size) | After (Format / Dims / Size) | Reduction |
|---|---:|---:|---:|
| `assets/images/sample_meal` | JPG `1200×896` — `976.9 KB` | WebP `640×478` — `65.7 KB` (`67,302 B`) | **-93.3%** |

- **Startup `precacheImage` & `ImageCache` key alignment:** `_NutriLensAppState` precaches `assets/images/sample_meal.webp` during boot warmup without `cacheWidth`/`cacheHeight` overrides, matching `Image.asset` in `ScannerScreen` (no `cacheWidth`/`cacheHeight`) so both resolve to the exact same `ImageCache` key.

### 2.2 `RepaintBoundary` & Rebuild Isolation
- **`DesktopWrapper` (`lib/widgets/desktop_wrapper.dart`):** Wrapped `_PhoneBezelFrame` in `RepaintBoundary` to isolate interactive app repaints from the surrounding desktop showcase chrome.
- **`DashboardScreen` (`lib/features/diario/presentation/views/dashboard_screen.dart`):** Wrapped `_HeroCard` in `RepaintBoundary` inside its `SliverToBoxAdapter` so meal list scrolling does not dirty the hero card layer.
- **`CalorieRingWidget` (`lib/features/diario/presentation/widgets/calorie_ring_widget.dart`):** Wrapped `CustomPaint` (`_MultiLayerRingPainter`) in `RepaintBoundary`.
- **`HealthScoreDetailSheet` (`lib/features/diario/presentation/widgets/health_score_detail_sheet.dart`):** Wrapped `CustomPaint` (`_ScoreRingPainter`) in `RepaintBoundary`.
- **`AppNavBar` (`lib/features/shell/presentation/widgets/app_nav_bar.dart`):** Wrapped the floating dock navigation bar in `RepaintBoundary`.

---

## 3. Web Build & Automated Verification

- **`flutter analyze`:** **0 issues** (`No issues found!`).
- **`flutter test`:** **159/159 passed** (including updated `scanner_screen_widget_test.dart` / `scanner_viewmodel_test.dart` and new `perf_telemetry_models_test.dart` and `perf_debug_overlay_test.dart`).
- **`flutter build web --release --wasm`:** **exit code 0** (`√ Built build\web`).
  - `main.dart.wasm`: `2,818.3 KB` (`2,885,974 B`)
  - `main.dart.js` (JS fallback): `3,389.5 KB` (`3,470,850 B`)
  - `CupertinoIcons.ttf` tree-shaken `-99.4%` (`1,472 B`), `MaterialIcons-Regular.otf` tree-shaken `-98.9%` (`18,468 B`).
