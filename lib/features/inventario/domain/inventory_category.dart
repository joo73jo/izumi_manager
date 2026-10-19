enum InventoryCategory {
  filament('Filamentos', 'g'),
  plant('Plantas', 'unidad'),
  substrate('Sustratos', 'g'),
  packaging('Packaging', 'unidad'),
  other('Otros materiales', 'unidad');

  const InventoryCategory(this.label, this.defaultUnit);

  final String label;
  final String defaultUnit;
}
