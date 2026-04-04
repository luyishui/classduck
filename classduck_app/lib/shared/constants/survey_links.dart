class SurveyLinks {
  SurveyLinks._();

  // 可通过 --dart-define=CLASSDUCK_SURVEY_URL 覆盖为正式问卷地址。
  static const String _baseSurveyUrl = String.fromEnvironment(
    'CLASSDUCK_SURVEY_URL',
    defaultValue: 'https://v.wjx.cn/vm/t705AZ0.aspx#',
  );

  // 可通过 --dart-define=CLASSDUCK_SHARE_URL 覆盖为项目分享地址。
  static const String projectShareUrl = String.fromEnvironment(
    'CLASSDUCK_SHARE_URL',
    defaultValue: 'https://github.com/luyishui/classduck',
  );

  static String get surveyHomeUrl => _baseSurveyUrl;

  static String get generalSurveyUrl => surveyHomeUrl;

  static String get importReportUrl => _withSection('import_report');

  static String get adaptationApplyUrl => _withSection('adaptation_apply');

  static String _withSection(String section) {
    final Uri? uri = Uri.tryParse(_baseSurveyUrl);
    if (uri == null || uri.host.isEmpty) {
      return _baseSurveyUrl;
    }

    final Map<String, String> query = <String, String>{
      ...uri.queryParameters,
      'from': 'classduck_app',
      'section': section,
    };

    return uri.replace(queryParameters: query).toString();
  }
}
