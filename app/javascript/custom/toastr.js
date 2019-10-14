import toastr from 'toastr';

// toastr options
toastr.options = ({
  "positionClass": "toast-top-right",
  "closeButton": true,
  "escapeHtml": false,
  // "timeOut": 100000,
  // "extendedTimeOut": 100000,
  "preventDuplicates": true,
  "preventOpenDuplicates": true,
})

window.toastr = toastr;
