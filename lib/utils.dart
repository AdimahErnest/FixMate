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
  'Adamawa': ['Ngaoundéré', 'Banyo', 'Tibati', 'Tignère'],
  'Centre': ['Yaoundé', 'Mbalmayo', 'Obala', 'Bafia', 'Akonolinga'],
  'East': ['Bertoua', 'Abong-Mbang', 'Batouri', 'Yokadouma'],
  'Far North': ['Maroua', 'Kousséri', 'Mokolo', 'Yagoua', 'Mora'],
  'Littoral': ['Douala', 'Nkongsamba', 'Edéa', 'Mbanga', 'Manjo'],
  'North': ['Garoua', 'Guider', 'Poli', 'Figuil'],
  'Northwest': ['Bamenda', 'Kumbo', 'Wum', 'Ndop'],
  'South': ['Ebolowa', 'Kribi', 'Sangmélima', 'Ambam'],
  'Southwest': ['Buea', 'Limbe', 'Kumba', 'Mamfe', 'Tiko'],
  'West': ['Bafoussam', 'Dschang', 'Bamendjou', 'Mbouda', 'Foumban', 'Bafang'],
};
