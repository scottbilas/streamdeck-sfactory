/// <reference path="libs/js/property-inspector.js" />
/// <reference path="libs/js/utils.js" />

$PI.onConnected((jsn) => {
  const {actionInfo, appInfo, connection, messageType, port, uuid} = jsn
  const {payload, context} = actionInfo
  const {settings} = payload

  const macro = document.querySelector('#property-macro')
  // TODO: throttle this
  macro.onchange = () => {
    let selected = macro.options[macro.selectedIndex]
    let selectedType = selected.getAttribute('macroType')

    if (selectedType === 'hotbar') {
      $PI.setSettings({HotBarMacro: {Number: parseInt(macro.value, 10)}})
    } else {
      $PI.setSettings({BuildingMacro: {Type: macro.value}})
    }
  }

  if (settings.BuildingMacro) {
    macro.value = settings.BuildingMacro.Type
  }
  else if (settings.HotBarMacro) {
    macro.value = settings.HotBarMacro.Number
  }
})
