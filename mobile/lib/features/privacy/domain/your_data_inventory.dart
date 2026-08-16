/// Factual in-app copy for "Your data in TARU".
///
/// Product trust surface only — not a Privacy Policy and not legal advice.
/// Keep categories aligned with current TARU architecture.
class YourDataInventory {
  const YourDataInventory._();

  static const String screenTitle = 'Your data in TARU';

  static const String intro =
      'This page describes what kinds of information TARU currently keeps, '
      'where it generally comes from, and what TARU deliberately does not do '
      'with it. It is not a Privacy Policy.';

  static const List<YourDataCategory> categories = <YourDataCategory>[
    YourDataCategory(
      title: 'Account',
      source: 'Account identity',
      location: 'Stored with your TARU account',
      bullets: <String>[
        'Name and email used to sign in and identify your account.',
      ],
    ),
    YourDataCategory(
      title: 'Health profile',
      source: 'Self-reported',
      location: 'Stored with your TARU account',
      bullets: <String>[
        'Basics such as date of birth, sex, height, weight snapshot, blood '
            'group, pregnancy status, and emergency contact when you enter them.',
        'Self-reported conditions, allergies, and medicines.',
      ],
    ),
    YourDataCategory(
      title: 'Measurements',
      source: 'Manual measurement',
      location: 'Stored with your TARU account',
      bullets: <String>[
        'Weight records you add, with the date and time you choose.',
        'Blood pressure readings you type in (systolic and diastolic).',
      ],
    ),
    YourDataCategory(
      title: 'Routine',
      source: 'Routine log',
      location: 'Stored with your TARU account',
      bullets: <String>[
        'Medicine dose logs (for example taken or skipped).',
        'Lifestyle and habit logs for the routine checklist.',
        'Reminder preferences used to schedule local notifications on this '
            'device.',
      ],
    ),
    YourDataCategory(
      title: 'Reports',
      source: 'Report record / reviewed derived text',
      location:
          'Stored with your TARU account; original files stored as part of '
          'your uploaded report',
      bullets: <String>[
        'Report metadata such as type, title, and dates.',
        'The original file you upload.',
        'Reviewed extracted text only when you explicitly save it after review. '
            'Raw OCR or extraction preview is not kept unless you save it.',
      ],
    ),
    YourDataCategory(
      title: 'Evidence Brief',
      source: 'Generated from information already in TARU',
      location:
          'Generated when you create the brief; not stored as a separate '
          'cloud document',
      bullets: <String>[
        'Assembles a factual summary from records you already keep in TARU.',
        'Does not create a persistent Evidence Brief document in the cloud.',
        'Personal notes or questions you type for sharing stay on this device '
            'for the session and are not saved to the cloud.',
      ],
    ),
    YourDataCategory(
      title: 'Crash diagnostics',
      source: 'Optional technical diagnostics',
      location:
          'Sent only when you turn sharing on; preference stored on this device',
      bullets: <String>[
        'Optional. Default is off.',
        'When enabled, TARU may send technical crash information to help '
            'diagnose app failures.',
        'TARU does not intentionally attach health information to crash '
            'diagnostics.',
      ],
    ),
  ];

  static const String doesNotDoTitle =
      'What TARU doesn\'t do with this information';

  static const List<String> doesNotDo = <String>[
    'TARU does not diagnose conditions.',
    'TARU does not turn Evidence Brief into a clinical assessment.',
    'TARU does not automatically include OCR or report body text in Evidence '
        'Brief.',
    'TARU does not use Firebase Analytics.',
    'Evidence Brief notes are not saved to the cloud.',
  ];

  static const String controlsIntro =
      'You can export or delete information from Privacy & data:';
}

class YourDataCategory {
  const YourDataCategory({
    required this.title,
    required this.source,
    required this.location,
    required this.bullets,
  });

  final String title;
  final String source;
  final String location;
  final List<String> bullets;
}
