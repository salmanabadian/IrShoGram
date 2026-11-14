/// Maps native Google Sign-In failures to actionable Persian guidance.
String googleSignInErrorMessage({
  required String code,
  String? description,
}) {
  final details = description?.toLowerCase() ?? '';

  switch (code) {
    case 'providerConfigurationError':
      if (details.contains('no provider dependencies found') ||
          details.contains('credential manager')) {
        return 'سرویس انتخاب حساب Google روی گوشی در دسترس نیست. '
            'Google Play Services و Play Store را به‌روز کنید، '
            'مطمئن شوید دست‌کم یک حساب Google به گوشی اضافه شده و گوشی را راه‌اندازی مجدد کنید. '
            'اگر خطا ادامه داشت، تنظیمات OAuth و اثرانگشت SHA-1 و SHA-256 همین APK باید بررسی شود.';
      }
      return 'سرویس ورود Google روی این دستگاه در دسترس نیست یا درست پیکربندی نشده است. '
          'Google Play Services را به‌روز کنید و تنظیمات OAuth برنامه را بررسی کنید.';
    case 'clientConfigurationError':
      return 'تنظیمات شناسه OAuth برای این برنامه کامل یا معتبر نیست. '
          'شناسه بسته، Web Client ID و اثرانگشت SHA-1 و SHA-256 باید بررسی شوند.';
    case 'uiUnavailable':
      return 'صفحه انتخاب حساب Google باز نشد. برنامه را ببندید و دوباره باز کنید.';
    case 'canceled':
      return 'فرایند ورود لغو شد. اگر پس از انتخاب حساب رخ می‌دهد، '
          'ممکن است اثرانگشت امضای APK یا تنظیمات OAuth با Firebase مطابقت نداشته باشد.';
    case 'interrupted':
      return 'فرایند ورود Google قطع شد. اتصال اینترنت را بررسی و دوباره تلاش کنید.';
    default:
      return 'ورود با Google انجام نشد. اتصال اینترنت و تنظیمات حساب Google را بررسی کنید.';
  }
}
