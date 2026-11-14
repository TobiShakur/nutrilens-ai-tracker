{{flutter_js}}
{{flutter_build_config}}

(function () {
  var buildVersion = 'r1';
  if (
    window._flutter &&
    _flutter.buildConfig &&
    Array.isArray(_flutter.buildConfig.builds)
  ) {
    _flutter.buildConfig.builds.forEach(function (build) {
      if (build.mainWasmPath && build.mainWasmPath.indexOf('?') === -1) {
        build.mainWasmPath += '?v=' + buildVersion;
      }
      if (
        build.jsSupportRuntimePath &&
        build.jsSupportRuntimePath.indexOf('?') === -1
      ) {
        build.jsSupportRuntimePath += '?v=' + buildVersion;
      }
      if (build.mainJsPath && build.mainJsPath.indexOf('?') === -1) {
        build.mainJsPath += '?v=' + buildVersion;
      }
    });
  }

  var dismissed = false;
  var perf = window.__portfolioPerf;

  function mark(key) {
    if (perf && perf.marks) {
      perf.marks[key] = Number(performance.now().toFixed(1));
    }
  }

  function dismissInitialLoader(source) {
    if (dismissed) {
      return;
    }
    dismissed = true;
    mark('readyEventMs');
    if (perf) {
      perf.readySource = source || 'flutter';
      if (typeof perf.snapshot === 'function') {
        perf.snapshot();
      }
    }
    var loader = document.getElementById('initial-loader');
    if (!loader) {
      return;
    }
    loader.classList.add('is-leaving');
    window.setTimeout(function () {
      if (loader.parentNode) {
        loader.remove();
        mark('loaderRemovedMs');
      }
    }, 580);
  }

  window.addEventListener(
    'app-ready',
    function () {
      dismissInitialLoader('flutter');
    },
    { once: true }
  );

  mark('loaderStartMs');
  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      mark('entrypointLoadedMs');
      const appRunner = await engineInitializer.initializeEngine();
      mark('engineInitEndMs');
      mark('runAppStartMs');
      await appRunner.runApp();
      mark('runAppEndMs');
      if (perf && typeof perf.recomputeStages === 'function') {
        perf.recomputeStages();
      }
      window.setTimeout(function () {
        dismissInitialLoader('fallback-timeout');
      }, 2000);
    },
  });
})();
