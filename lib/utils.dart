// FixMate — small helpers with no Flutter dependency
const String _accentsFrom = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
const String _accentsTo = 'aaaaaaceeeeiiiinooooouuuuyy';

// Lowercases and removes accents so "Yaoundé" matches "yaounde"
String normalizeSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final index = _accentsFrom.indexOf(char);
    buffer.write(index >= 0 ? _accentsTo[index] : char);
  }
  return buffer.toString();
}

const Map<String, List<String>> cameroonRegions = {
  'Littoral': ['Douala', 'Nkongsamba', 'Edéa'],
  'Centre': ['Yaoundé', 'Mbalmayo', 'Obala'],
  'West': ['Bafoussam', 'Dschang', 'Bamendjou'],
  'Southwest': ['Buea', 'Limbe', 'Kumba'],
  'Northwest': ['Bamenda'],
  'South': ['Ebolowa', 'Kribi'],
  'East': ['Bertoua'],
  'North': ['Garoua', 'Maroua'],
  'Adamawa': ['Ngaoundéré'],
};
