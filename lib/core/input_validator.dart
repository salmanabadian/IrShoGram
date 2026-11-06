class InputValidator {
  InputValidator._();

  static String? username(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return 'نام کاربری الزامی است.';
    if (value.length < 3 || value.length > 30) {
      return 'نام کاربری باید بین ۳ تا ۳۰ نویسه باشد.';
    }
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
      return 'فقط حروف انگلیسی، عدد، نقطه و زیرخط مجاز است.';
    }
    return null;
  }

  static String? displayName(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return 'نام نمایشی الزامی است.';
    if (value.length > 80) return 'نام نمایشی بیش از حد طولانی است.';
    return null;
  }

  static String? bio(String? input) {
    if ((input ?? '').length > 300) return 'بیوگرافی حداکثر ۳۰۰ نویسه است.';
    return null;
  }

  static String? caption(String? input) {
    if ((input ?? '').length > 2200) return 'متن پست حداکثر ۲۲۰۰ نویسه است.';
    return null;
  }

  static String? comment(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return 'متن دیدگاه خالی است.';
    if (value.length > 2000) return 'دیدگاه حداکثر ۲۰۰۰ نویسه است.';
    return null;
  }

  static String? message(String? input) {
    final value = input?.trim() ?? '';
    if (value.length > 5000) return 'پیام حداکثر ۵۰۰۰ نویسه است.';
    if (value.isEmpty) return 'متن پیام خالی است.';
    return null;
  }

  static String? validateConversationParticipants(
    List<String> participantIds,
    String currentUid,
  ) {
    if (participantIds.length != 2 ||
        participantIds.toSet().length != 2 ||
        !participantIds.contains(currentUid)) {
      return 'گفتگو باید دقیقاً دو عضو یکتا، از جمله کاربر فعلی، داشته باشد.';
    }
    return null;
  }
}
