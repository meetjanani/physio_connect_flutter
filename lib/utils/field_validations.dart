
var emailPattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
var mobilePattern = r'(^[0-9]*$)';
extension ValiationExtensions on String {
  validateVisitDateEmpty() {
    if(isEmpty || this == "" || this == 'Select Visit Date'){
      return 'Please select the Visit Date';
    }else{
      return null;
    }
  }

  validateEmpty() {
    if(isEmpty){
      return 'Please enter the value';
    }else{
      return null;
    }
  }
  validateEmail() {
    var regExp = RegExp(emailPattern);
    if (isEmpty) {
      return 'Email is required';
    } else if (!regExp.hasMatch(this)) {
      return 'Invalid email';
    } else {
      return null;
    }
  }

  String? validateConfirmPassword(String v, String password) {
    if (v.isEmpty || password.isEmpty) {
      return 'Repeat password is required';
    } else if (v.length < 6 || password.length < 6 || v != password) {
      return 'Password do not match';
    } else {
      return null;
    }
  }

  validatePassword() {
    if (isEmpty) {
      return 'Password is required';
    } else if (length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  validateMobile() {
    var regExp = RegExp(mobilePattern);
    if (replaceAll(" ", "").isEmpty) {
      return 'Mobile is required';
    } else if (replaceAll(" ", "").length != 10) {
      return 'Mobile number must 10 digits';
    } else if (!regExp.hasMatch(replaceAll(" ", ""))) {
      return 'Mobile number must be digits';
    }
    return null;
  }

  String? addressValidation() {
    if (isEmpty) {
      return 'Please enter Address';
    }
    return null;
  }

  String? nameValidation() {
    if (isEmpty) {
      return 'Please enter your Name';
    }
    return null;
  }

  String? projectNameValidation() {
    if (isEmpty) {
      return 'Please enter Project Name';
    }
    return null;
  }

  String? validatePinCode() {
    if (isEmpty) {
      return 'Pin code is required';
    } else if (length < 6) {
      return 'Pin code must be 6 characters';
    }
    return null;
  }

  String? siteVisitTitleValidation() {
    if (isEmpty) {
      return 'Please enter Title';
    }
    return null;
  }

  String? siteVisitDescriptionValidation() {
    if (isEmpty) {
      return 'Please enter Description';
    }
    return null;
  }
}