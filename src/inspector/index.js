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

  // find DOM elements

  const macroElement = document.querySelector('#property-macro')
  const variantElement = document.querySelector('#property-variant')
  const variantDiv = document.querySelector('#div-variant')

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
      _config[macroElement.value].forEach(v => addOption(variantElement, v))
      variantElement.value = settings.Variant

      variantDiv.style.visibility = 'visible'
    }
    else {
      delete settings.Variant
      variantDiv.style.visibility = 'collapse'
    }

    // store settings in prefs, which will also update the app
    $PI.setSettings(settings)
  }

  const onchange = throttle(150, () => {
    settings = {Name: macroElement.value, Variant: variantElement.value}
    applySettings()
  })

  macroElement.onchange = onchange;
  variantElement.onchange = onchange;

  // TODO: fill this via a fragment
  Object.entries(_config).forEach(([groupName, group]) => {
    let optgroup = addOptGroup(macroElement, groupName)
    Object.entries(group).forEach(([buildableName, buildable]) => {
      addOption(optgroup, buildableName)
      _config[buildableName] = buildable.map(v => v.length ? v : "Normal")
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
