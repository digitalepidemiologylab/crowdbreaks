// JS snippets to be used across forms

// File input (Show filename on file select)
function onChooseFile() {
  let inputs = Array.from(document.querySelectorAll('.input-file'));
  inputs.forEach((input) => {
    let uploadButton = input.parentNode.parentNode.previousSibling.previousSibling.querySelector('div')
    let filename = ''
    input.addEventListener('change', (e) => {
      filename = e.target.value.split('\\').pop()
      uploadButton.querySelector('span').innerHTML = filename
    })
  })
}


$(document).on('turbolinks:load', () => {
  onChooseFile();
});
