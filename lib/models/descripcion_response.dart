import '../core/api_exception.dart';

class DescripcionResponse {
  const DescripcionResponse({required this.texto});

  factory DescripcionResponse.fromJson(Map<String, dynamic> json) {
    final texto = (json['descripcion'] as String?)?.trim();
    if (texto == null || texto.isEmpty) {
      throw const ApiException('La descripción llegó vacía.');
    }
    return DescripcionResponse(texto: texto);
  }

  final String texto;
}
