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

function addOptGroup(parent, name) {
    let optgroup = document.createElement('optgroup')
    optgroup.label = name
    parent.appendChild(optgroup)

    return optgroup
}

function addOption(parent, name, value) {
    let option = document.createElement('option')
    option.textContent = name
    option.value = value
    parent.appendChild(option)

    return option
}
