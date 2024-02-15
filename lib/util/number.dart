
String doubleToString(double n, {int keepDecimal = 2}) {
  return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : keepDecimal);
}