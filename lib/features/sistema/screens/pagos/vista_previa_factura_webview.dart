import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:refactor_template/core/services/documentos/servicio_generador_factura_html.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';

class VistaPreviaFacturaWebView extends StatefulWidget {
  static const name = 'vista-previa-factura-webview';
  
  final Map<String, dynamic> datosFactura;

  const VistaPreviaFacturaWebView({
    super.key,
    required this.datosFactura,
  });

  @override
  State<VistaPreviaFacturaWebView> createState() => _VistaPreviaFacturaWebViewState();
}

class _VistaPreviaFacturaWebViewState extends State<VistaPreviaFacturaWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _htmlPath;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      // Generar HTML de la factura
      final htmlPath = await ServicioGeneradorFacturaHtml.generarFacturaHtml(
        widget.datosFactura,
      );
      
      setState(() {
        _htmlPath = htmlPath;
      });
      
      // Configurar WebView
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFEEF1F8))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              setState(() => _isLoading = false);
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('Error cargando WebView: ${error.description}');
            },
          ),
        )
        ..loadFile(htmlPath);
        
    } catch (e) {
      debugPrint('Error inicializando WebView: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar factura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: _htmlPath == null
          ? _buildLoadingView()
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading) _buildLoadingOverlay(),
              ],
            ),
      floatingActionButton: _buildFloatingActions(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF005BAC),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Text(
            'Vista Previa de Factura',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.subtitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.description, color: Colors.amber, size: 22),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            if (_htmlPath != null) {
              _controller.reload();
            }
          },
          tooltip: 'Recargar',
        ),
        IconButton(
          icon: const Icon(Icons.print, color: Colors.white),
          onPressed: () {
            // TODO: Implementar impresión
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función de impresión en desarrollo'),
                backgroundColor: Color(0xFF005BAC),
              ),
            );
          },
          tooltip: 'Imprimir',
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005BAC)),
          ),
          SizedBox(height: 20),
          Text(
            'Generando factura...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005BAC)),
        ),
      ),
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'download',
          onPressed: () {
            // TODO: Implementar descarga de PDF
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función de descarga en desarrollo'),
                backgroundColor: Color(0xFF005BAC),
              ),
            );
          },
          backgroundColor: const Color(0xFF005BAC),
          child: const Icon(Icons.download, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'share',
          onPressed: () {
            // TODO: Implementar compartir
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función de compartir en desarrollo'),
                backgroundColor: Color(0xFF005BAC),
              ),
            );
          },
          backgroundColor: const Color(0xFF4CAF50),
          child: const Icon(Icons.share, color: Colors.white),
        ),
      ],
    );
  }
}


