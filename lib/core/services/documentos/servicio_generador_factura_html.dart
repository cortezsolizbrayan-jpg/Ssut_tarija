import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Servicio para generar facturas en formato HTML
/// Permite visualización en WebView como documento profesional
class ServicioGeneradorFacturaHtml {
  
  /// Genera HTML de factura y retorna la ruta del archivo
  static Future<String> generarFacturaHtml(Map<String, dynamic> datosFactura) async {
    final html = _construirHtmlFactura(datosFactura);
    
    // Guardar en archivo temporal
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/factura_${DateTime.now().millisecondsSinceEpoch}.html');
    await file.writeAsString(html);
    
    return file.path;
  }
  
  /// Construye el HTML completo de la factura
  static String _construirHtmlFactura(Map<String, dynamic> datos) {
    final tipoPago = datos['tipoPago'] ?? 'matricula';
    final tipoTexto = tipoPago == 'matricula' ? 'Matrícula' : 'Colegiatura';
    final programaId = datos['programaId'] ?? 'N/A';
    final numeroDeposito = datos['numeroDeposito'] ?? 'N/A';
    final fechaDeposito = datos['fechaDeposito'] ?? 'N/A';
    final monto = datos['monto'] ?? '0';
    final nombreFacturacion = datos['nombreFacturacion'] ?? 'N/A';
    final nit = datos['nit'] ?? 'N/A';
    final email = datos['email'] ?? 'N/A';
    final telefono = datos['telefono'] ?? 'N/A';
    final tipoDocumento = datos['tipoDocumento'] ?? 'CI';
    final facturaEmpresa = datos['facturaEmpresa'] == true;
    
    return '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Comprobante de Pago - UPEA Posgrado</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Arial', sans-serif;
            background: #f5f5f5;
            padding: 20px;
            color: #333;
        }
        
        .factura-container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border: 3px solid #005BAC;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(0, 91, 172, 0.2);
        }
        
        .header {
            background: linear-gradient(135deg, #005BAC 0%, #3D8FE0 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
            text-transform: uppercase;
            letter-spacing: 2px;
        }
        
        .header p {
            font-size: 14px;
            opacity: 0.9;
        }
        
        .comprobante-badge {
            display: inline-block;
            background: #4CAF50;
            color: white;
            padding: 8px 20px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            margin-top: 15px;
            text-transform: uppercase;
        }
        
        .content {
            padding: 40px;
        }
        
        .section {
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px dashed #e0e0e0;
        }
        
        .section:last-child {
            border-bottom: none;
        }
        
        .section-title {
            font-size: 18px;
            color: #005BAC;
            font-weight: bold;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
        }
        
        .section-title::before {
            content: '';
            display: inline-block;
            width: 4px;
            height: 20px;
            background: #005BAC;
            margin-right: 10px;
        }
        
        .info-row {
            display: flex;
            padding: 10px 0;
            border-bottom: 1px solid #f0f0f0;
        }
        
        .info-row:last-child {
            border-bottom: none;
        }
        
        .info-label {
            flex: 0 0 200px;
            font-weight: 600;
            color: #666;
            font-size: 14px;
        }
        
        .info-value {
            flex: 1;
            color: #333;
            font-size: 14px;
        }
        
        .monto-destacado {
            background: linear-gradient(135deg, #005BAC 0%, #3D8FE0 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            margin: 20px 0;
        }
        
        .monto-destacado .label {
            font-size: 14px;
            opacity: 0.9;
            margin-bottom: 5px;
        }
        
        .monto-destacado .valor {
            font-size: 36px;
            font-weight: bold;
        }
        
        .banco-info {
            background: #f8f9fb;
            border: 2px solid #005BAC;
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
        }
        
        .banco-info h3 {
            color: #005BAC;
            font-size: 16px;
            margin-bottom: 15px;
        }
        
        .cuenta-numero {
            font-size: 24px;
            font-weight: bold;
            color: #005BAC;
            letter-spacing: 2px;
            margin: 10px 0;
        }
        
        .estado-pago {
            background: #e8f5e9;
            border: 2px solid #4CAF50;
            border-radius: 10px;
            padding: 20px;
            display: flex;
            align-items: center;
            margin-top: 30px;
        }
        
        .estado-pago .icono {
            width: 50px;
            height: 50px;
            background: #4CAF50;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-right: 20px;
            font-size: 30px;
            color: white;
        }
        
        .estado-pago .texto h3 {
            color: #4CAF50;
            font-size: 18px;
            margin-bottom: 5px;
        }
        
        .estado-pago .texto p {
            color: #666;
            font-size: 13px;
        }
        
        .footer {
            background: #f8f9fb;
            padding: 20px;
            text-align: center;
            font-size: 12px;
            color: #666;
        }
        
        .footer p {
            margin: 5px 0;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .factura-container {
                border: none;
                box-shadow: none;
            }
        }
    </style>
</head>
<body>
    <div class="factura-container">
        <div class="header">
            <h1>UNIVERSIDAD PÚBLICA DE EL ALTO</h1>
            <p>DIRECCIÓN DE POSGRADO</p>
            <div class="comprobante-badge">COMPROBANTE DE $tipoTexto</div>
        </div>
        
        <div class="content">
            <!-- Información del Pago -->
            <div class="section">
                <div class="section-title">Información del Pago</div>
                <div class="info-row">
                    <div class="info-label">Tipo de Pago:</div>
                    <div class="info-value">$tipoTexto</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Programa:</div>
                    <div class="info-value">$programaId</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Número de Depósito:</div>
                    <div class="info-value">$numeroDeposito</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Fecha de Pago:</div>
                    <div class="info-value">$fechaDeposito</div>
                </div>
            </div>
            
            <!-- Monto Destacado -->
            <div class="monto-destacado">
                <div class="label">MONTO TOTAL</div>
                <div class="valor">Bs. $monto</div>
            </div>
            
            <!-- Datos de Facturación -->
            <div class="section">
                <div class="section-title">Datos de Facturación</div>
                <div class="info-row">
                    <div class="info-label">Tipo de Factura:</div>
                    <div class="info-value">${facturaEmpresa ? 'Factura Empresa' : 'Factura Personal'}</div>
                </div>
                <div class="info-row">
                    <div class="info-label">${facturaEmpresa ? 'Razón Social:' : 'Nombre Completo:'}</div>
                    <div class="info-value">$nombreFacturacion</div>
                </div>
                <div class="info-row">
                    <div class="info-label">$tipoDocumento:</div>
                    <div class="info-value">$nit</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Email:</div>
                    <div class="info-value">$email</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Teléfono:</div>
                    <div class="info-value">$telefono</div>
                </div>
            </div>
            
            <!-- Información Bancaria -->
            <div class="banco-info">
                <h3>📍 Información Bancaria</h3>
                <div class="info-row">
                    <div class="info-label">Banco:</div>
                    <div class="info-value">BANCO UNIÓN</div>
                </div>
                <div class="info-row">
                    <div class="info-label">Cuenta:</div>
                    <div class="info-value"><div class="cuenta-numero">100 000 047 130 25</div></div>
                </div>
                <div class="info-row">
                    <div class="info-label">Titular:</div>
                    <div class="info-value">DIRECCIÓN DE POSGRADO UPEA</div>
                </div>
            </div>
            
            <!-- Estado del Pago -->
            <div class="estado-pago">
                <div class="icono">✓</div>
                <div class="texto">
                    <h3>Pago Registrado</h3>
                    <p>Su pago ha sido registrado correctamente y está en proceso de verificación.</p>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p><strong>Universidad Pública de El Alto - Dirección de Posgrado</strong></p>
            <p>Este es un comprobante de registro de pago. No constituye factura fiscal.</p>
            <p>Generado el: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} a las ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}</p>
        </div>
    </div>
</body>
</html>
    ''';
  }
}
