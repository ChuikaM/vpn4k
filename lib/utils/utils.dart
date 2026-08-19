String formatSecondsToTime(int totalSeconds) {
  if (totalSeconds <= 0) return "00h 00m 00s";

  int hours = totalSeconds ~/ 3600;
  int minutes = (totalSeconds % 3600) ~/ 60;
  int seconds = totalSeconds % 60;

  String h = hours.toString().padLeft(2, '0');
  String m = minutes.toString().padLeft(2, '0');
  String s = seconds.toString().padLeft(2, '0');

  return "${h}h ${m}m ${s}s";
}
