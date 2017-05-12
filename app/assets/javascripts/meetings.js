/* Selects the given time value by element ID */
function selectTimeValueByElementId(elementId) {
    var timeValue;
    switch (elementId) {
        case 'select30m':
            timeValue = 30;
            break;
        case 'select2h':
            timeValue = 120;
            break;
        default:
            timeValue = 60;
    }
    replaceHiddenInput(createNewHiddenInput(timeValue));
    document.getElementById('duration-input').value = '';
    var selected = document.getElementById(elementId);
    removeSelected();
    //setDurationInfoText(timeValue);
    selected.className += " selected";
};

/* Keyup function for manual duration input */
function durationInputKeyup(input){
  if (input.value) {
      removeSelected();
      replaceHiddenInput(createNewHiddenInput(input.value*60));
      setDurationInfoText(input.value);
  } else {
      selectTimeValueByElementId('select1h');
  }

}

/* Creates a new hidden duration field with the given value */
createNewHiddenInput = function(value) {
    var input = document.createElement("INPUT");
    input.setAttribute('type', 'hidden');
    input.setAttribute('name', 'meeting[duration]');
    input.setAttribute('value', value);
    return input;
};

/* Replaces the (possibly) existing hidden input with a new one */
replaceHiddenInput = function(newInput) {
    var durationdiv = document.getElementById('duration-value');
    while (durationdiv.hasChildNodes()) {
        durationdiv.removeChild(durationdiv.lastChild);
    }
    durationdiv.appendChild(newInput);
};

/* Sets the selected duration value to the info text on top of start button */
setDurationInfoText = function(value) {
    document.getElementById('duration-info').innerHTML = value;
};

/* Removes 'selected' class from every element that has it */
removeSelected = function() {
    var elements = document.getElementsByClassName('selected');
    for (var i = 0; i < elements.length; i++){
            elements[i].classList.remove('selected');
    }
};

/* Select 1h when the page loads */
window.onload = function() {
  if (document.getElementById('select1h')) {
    selectTimeValueByElementId('select1h');
  }
};
