/// <reference path="libs/js/property-inspector.js" />
/// <reference path="utils.js" />

let _config, _jsn, _initialized

function init() {
  if (!_config || !_jsn || _initialized) return
  _initialized = true

  // extract setup data

  const {actionInfo, appInfo, connection, messageType, port, uuid} = _jsn
  const {payload, context} = actionInfo
  let {settings} = payload
  let lastSettings = {}

  // find DOM elements

  const macroElement = document.querySelector('#property-macro')
  const variantDiv = document.querySelector('#div-variant')
  const variantElement = document.querySelector('#property-variant')
  //const macroSkipElement = document.querySelector('#property-macro-skip')
  //const macroSkipValueElement = document.querySelector('#property-macro-skip-value')

  // configure change handlers

  const applySettings = function() {

    if (!settings) return

    // pick default if missing/invalid macro
    let variants = _config[settings.Name]
    if (!variants) {
      let name
      [name, variants] = Object.entries(_config)[0]
      settings = {Name: name}
    }
    macroElement.value = settings.Name

    // pick default if missing/invalid variant
    variantElement.innerHTML = ''
    if (variants.length) {
      if (!variants.includes(settings.Variant)) {
        settings.Variant = variants[0]
      }

      // TODO: fill this via a fragment
      // TODO: use fragment compare to skip reassigning
      _config[macroElement.value].forEach(v => addOption(variantElement, v || 'Normal', v))
      variantElement.value = settings.Variant

      //macroSkipElement.min = 0
      //macroSkipElement.max = variants.length - 1

      // if macro or variant changed, reset skip
      /*if (lastSettings.Name !== settings.Name || lastSettings.Variant !== settings.Variant) {
        macroSkipElement.value = variantElement.selectedIndex
      }

      macroSkipValueElement.textContent = macroSkipElement.value*/

      variantDiv.style.visibility = 'visible'
    }
    else {
      delete settings.Variant
      variantDiv.style.visibility = 'collapse'
    }

    // store settings in prefs, which will also update the app
    $PI.setSettings(settings)
    lastSettings = settings
  }

  const onchange = throttle(150, () => {
    settings = {Name: macroElement.value, Variant: variantElement.value}
    applySettings()
  })

  macroElement.onchange = onchange
  variantElement.onchange = onchange
  //macroSkipElement.oninput = onchange

/*  macroSkipElement.oninput = throttle(150, () => {
    settings.MacroSkip = macroSkipElement.value
    macroSkipValueElement.textContent = macroSkipElement.value
    $PI.setSettings(settings)
  })*/

  // fill macro dropdown and discover all variant types

  let allVariants = {}

  // TODO: fill this via a fragment
  Object.entries(_config).forEach(([groupName, group]) => {
    let optgroup = addOptGroup(macroElement, groupName)
    Object.entries(group).forEach(([buildableName, buildable]) => {
      addOption(optgroup, buildableName, buildableName)
      _config[buildableName] = buildable
      buildable.forEach(v => allVariants[v] = true)
    })
    delete _config[groupName]
  })

  // copy stored settings to DOM

  applySettings()
}

// init will happen after both a) buildables.json is parsed and b) we're connected to $PI

$PI.onConnected((jsn) => {
  _jsn = jsn
  init()
})

fetch('buildables.json')
    .then(response => response.json())
    .then(buildables => {
      _config = buildables
      _config['Special']['HotBar'] = [ '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' ]
      init()
    })
