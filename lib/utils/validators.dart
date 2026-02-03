class Validators {
  static final RegExp nameRegex = RegExp(r'^[a-zA-Z ]+$');
  static final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Inserisci il nome';
    if (!nameRegex.hasMatch(value.trim())) return 'Inserisci solo lettere';
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Inserire l\'email';
    if (!emailRegex.hasMatch(value.trim()))
      return 'L\'email inserita non è valida';
    return null;
  }

  static String? validateConfirmEmail(String? value, String originalEmail) {
    if (value == null || value.isEmpty) {
      return 'L\'email deve essere confermata';
    }
    if (value.toLowerCase().trim() != originalEmail.toLowerCase().trim()) {
      return 'Le email non coincidono';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Inserisci una password';
    if (value.length < 6) return 'Almeno 6 caratteri';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Deve contenere un numero';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Deve contenere una maiuscola';
    }
    return null;
  }

  static String? validateConfirmPassword(
    String? value,
    String originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'La password deve essere confermata';
    }
    if (value != originalPassword) return 'Le password non coincidono';
    return null;
  }

  static String? validateEmailSignIn(String? value) {
    if (value == null || value.isEmpty) return 'Inserire l\'email';
    return null;
  }

  static String? validatePasswordSignIn(String? value) {
    if (value == null || value.isEmpty) return 'Inserire la password';
    return null;
  }

  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) return 'Inserire la data';
    return null;
  }

  static String? validateTime(String? value) {
    if (value == null || value.isEmpty) return 'Inserire l\'orario';
    return null;
  }
}
