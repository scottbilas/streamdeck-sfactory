/// <reference path="libs/js/property-inspector.js" />

function throttle(delay, func) {
  let lastExecutionTime = 0, timerId

  return function (...args) {
    function apply() {
      lastExecutionTime = Date.now()
      func.apply(this, args)
    }

    clearTimeout(timerId)
    if (Date.now() - lastExecutionTime < delay)
      timerId = setTimeout(apply, delay) // ensure that the last change is always committed
    else
      apply() // throttle period passed, so commit (this gives us the live updates that debounce does not)
  }
}

$PI.onConnected((jsn) => {
  const {actionInfo, appInfo, connection, messageType, port, uuid} = jsn
  const {payload, context} = actionInfo
  const {settings} = payload

  const macro = document.querySelector('#property-macro')
  macro.onchange = throttle(150, () => {
    let selected = macro.options[macro.selectedIndex]
    let selectedType = selected.getAttribute('macroType')

    if (selectedType === 'hotbar') {
      $PI.setSettings({HotBarMacro: {Number: parseInt(macro.value, 10)}})
    } else {
      $PI.setSettings({BuildingMacro: {Type: macro.value}})
    }
  })

  if (settings.BuildingMacro) {
    macro.value = settings.BuildingMacro.Type
  }
  else if (settings.HotBarMacro) {
    macro.value = settings.HotBarMacro.Number
  }
})
