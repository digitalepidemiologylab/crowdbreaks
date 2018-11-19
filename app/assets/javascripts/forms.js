// JS snippets to be used across forms

// File input (Show filename on file select)
$(document).on('turbolinks:load', function() {
  let inputs = document.querySelectorAll('.input-file');
  inputs.forEach((input) => {
    let uploadButton = input.parentNode.parentNode.previousSibling.previousSibling.querySelector('div')
    let filename = ''
    input.addEventListener('change', (e) => {
      filename = e.target.value.split('\\').pop()
      uploadButton.querySelector('span').innerHTML = filename
    })
  })
})

