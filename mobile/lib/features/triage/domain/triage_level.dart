/// How soon something needs medical attention.
///
/// [order] exists so the engine can take the worst answer across several
/// symptoms and several red flags without a pile of comparisons. Nothing in
/// TARU may ever move a level down: an assessment only ever escalates.
enum TriageLevel {
  selfCare(
    order: 0,
    headline: 'You can likely manage this at home',
    timeframe: 'Keep an eye on it',
  ),
  soon(
    order: 1,
    headline: 'Worth seeing a doctor in the next few days',
    timeframe: 'Within a few days',
  ),
  urgent(order: 2, headline: 'See a doctor today', timeframe: 'Today'),
  emergency(
    order: 3,
    headline: 'Get emergency help now',
    timeframe: 'Right now',
  );

  const TriageLevel({
    required this.order,
    required this.headline,
    required this.timeframe,
  });

  final int order;

  /// The single sentence that leads the result.
  final String headline;

  /// Short form for chips and summaries.
  final String timeframe;

  bool isAtLeast(TriageLevel other) => order >= other.order;

  TriageLevel orWorse(TriageLevel other) => other.order > order ? other : this;
}

/// Emergency numbers differ by country and TARU never asks where someone is,
/// so escalations name the common ones rather than confidently giving a number
/// that does not work where the phone happens to be.
const String emergencyNumberHint =
    'Call your local emergency number now — 112 in India and most of Europe, '
    '911 in the US, 999 in the UK.';
