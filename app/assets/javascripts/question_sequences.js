var buttons = "";
function updateColors(){
  buttons = $("#answers :button");
  for(var i=0; i < buttons.length; i++) {
    color = buttons[i].getAttribute('data-color');
    if (color != '') {
      buttons[i].style.backgroundColor = color;
    }
  }
};

$(document).on('turbolinks:load', updateColors);
