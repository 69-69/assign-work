//RegExp
RegExp onlyNumbersRegExp = RegExp(r'^-?[0-9]+$');

RegExp nameRegExp = RegExp(
  r"^([a-zA-Z]{2,}\s[a-zA-Z]{1,}'?-?[a-zA-Z]{2,}\s?([a-zA-Z]{1,})?)",
);

RegExp emailRegExp = RegExp(
  r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
);

RegExp passwordRegExp = RegExp(
  r"^(?=.*[A-Za-z])(?=.*\d)(?=.*[$!%*#@?&])[A-Za-z\d$!%*#@?&]{8,}$",
);

RegExp passcodeRegExp = RegExp(
  r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[$!%*#@?&-])[A-Za-z\d$!%*#@?&-]{8,}$',
);
