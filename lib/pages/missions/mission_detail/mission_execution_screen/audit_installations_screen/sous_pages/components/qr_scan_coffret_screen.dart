import 'package:flutter/material.dart';
import 'package:inspec_app/models/audit_installations_electriques.dart';
import 'package:inspec_app/pages/missions/mission_detail/mission_execution_screen/audit_installations_screen/sous_pages/components/ajouter_coffret_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:inspec_app/models/mission.dart';
import 'package:inspec_app/constants/app_theme.dart';
import 'package:inspec_app/services/hive_service.dart';

class QrScanCoffretScreen extends StatefulWidget {
  final Mission mission;
  final String parentType;
  final int parentIndex;
  final bool isMoyenneTension;
  final int? zoneIndex;
  final bool isInZone;

  const QrScanCoffretScreen({
    super.key,
    required this.mission,
    required this.parentType,
    required this.parentIndex,
    required this.isMoyenneTension,
    this.zoneIndex,
    this.isInZone = false,
  });

  @override
  State<QrScanCoffretScreen> createState() => _QrScanCoffretScreenState();
}

class _QrScanCoffretScreenState extends State<QrScanCoffretScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String? _scannedQrCode;
  bool _isProcessing = false;
  bool _qrCodeDetected = false;
  CoffretArmoire? _existingCoffret;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onQrCodeDetect(BarcodeCapture barcodeCapture) {
    if (_isProcessing || _qrCodeDetected) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      final Barcode barcode = barcodes.first;
      final String? qrCode = barcode.rawValue;
      
      if (qrCode != null && qrCode.isNotEmpty && qrCode != _scannedQrCode) {
        setState(() {
          _isProcessing = true;
          _scannedQrCode = qrCode;
        });

        // Arrêter temporairement le scanner
        cameraController.stop();
        
        Future.delayed(const Duration(milliseconds: 500), () {
          _processQrCodeDetection(qrCode);
        });
      }
    }
  }

  void _processQrCodeDetection(String qrCode) async {
    try {
      // Vérifier si le QR code existe déjà
      _existingCoffret = HiveService.findCoffretByQrCode(
        widget.mission.id,
        qrCode,
      );

      setState(() {
        _isProcessing = false;
        _qrCodeDetected = true;
      });
    } catch (e) {
      print('❌ Erreur processQrCodeDetection: $e');
      _showError('Erreur lors du traitement du QR code: $e');
      _resetScanner();
    }
  }

  void _continuerAvecQrCode() {
    if (_scannedQrCode == null) return;

    if (_existingCoffret != null) {
      // Naviguer vers l'édition du coffret existant
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AjouterCoffretScreen(
            mission: widget.mission,
            parentType: widget.parentType,
            parentIndex: widget.parentIndex,
            isMoyenneTension: widget.isMoyenneTension,
            zoneIndex: widget.zoneIndex,
            coffret: _existingCoffret,
            isInZone: widget.isInZone,
          ),
        ),
      ).then((value) {
        // Rafraîchir l'écran précédent quand on revient
        if (value == true) {
          Navigator.pop(context, true);
        }
      });
    } else {
      // Naviguer vers la création d'un nouveau coffret
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AjouterCoffretScreen(
            mission: widget.mission,
            parentType: widget.parentType,
            parentIndex: widget.parentIndex,
            isMoyenneTension: widget.isMoyenneTension,
            zoneIndex: widget.zoneIndex,
            coffret: null,
            isInZone: widget.isInZone,
            qrCode: _scannedQrCode,
          ),
        ),
      ).then((value) {
        // Rafraîchir l'écran précédent quand on revient
        if (value == true) {
          Navigator.pop(context, true);
        }
      });
    }
  }

  void _recommencerScanner() {
    _resetScanner();
  }

  void _resetScanner() {
    setState(() {
      _scannedQrCode = null;
      _qrCodeDetected = false;
      _existingCoffret = null;
      _isProcessing = false;
    });
    // Redémarrer le scanner
    cameraController.start();
  }

  void _enterQrCodeManually() {
    final TextEditingController manualController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saisir le QR code manuellement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: manualController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Entrez le code QR',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context);
                  _processQrCodeManuel(value);
                }
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Le QR code doit être unique pour chaque coffret',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final value = manualController.text;
              if (value.isNotEmpty) {
                Navigator.pop(context);
                _processQrCodeManuel(value);
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _processQrCodeManuel(String qrCode) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Vérifier si le QR code existe déjà
      _existingCoffret = HiveService.findCoffretByQrCode(
        widget.mission.id,
        qrCode,
      );

      setState(() {
        _scannedQrCode = qrCode;
        _isProcessing = false;
        _qrCodeDetected = true;
      });
    } catch (e) {
      print('❌ Erreur processQrCodeManuel: $e');
      _showError('Erreur: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _toggleTorch() {
    cameraController.toggleTorch();
  }

  void _switchCamera() {
    cameraController.switchCamera();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        // Overlay de guidage
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: _qrCodeDetected ? Colors.green : Colors.blue,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Coin supérieur gauche
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
                top: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
              ),
            ),
          ),
        ),

        // Coin supérieur droit
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
                top: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
              ),
            ),
          ),
        ),

        // Coin inférieur gauche
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
                bottom: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
              ),
            ),
          ),
        ),

        // Coin inférieur droit
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
                bottom: BorderSide(
                  color: _qrCodeDetected ? Colors.green : Colors.blue,
                  width: 4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCodeDetectedPanel() {
    final isExisting = _existingCoffret != null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExisting ? Icons.check_circle : Icons.qr_code_scanner,
            color: isExisting ? Colors.orange : Colors.green,
            size: 64,
          ),
          const SizedBox(height: 16),
          
          Text(
            isExisting ? 'COFFRET EXISTANT DÉTECTÉ' : 'NOUVEAU QR CODE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _scannedQrCode!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (isExisting && _existingCoffret != null)
            Column(
              children: [
                Text(
                  'Nom: ${_existingCoffret!.nom}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'Type: ${_existingCoffret!.type}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'Localisation: ${_existingCoffret!.nom}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
              ],
            ),
          
          Text(
            isExisting 
              ? 'Ce QR code est déjà associé à un coffret existant.'
              : 'Ce QR code n\'est pas encore utilisé.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _recommencerScanner,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recommencer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _continuerAvecQrCode,
                  icon: Icon(isExisting ? Icons.edit : Icons.add),
                  label: Text(isExisting ? 'Éditer' : 'Continuer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExisting ? Colors.orange : AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannerInstructions() {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Scannez le QR code du coffret',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Placez le code QR dans le cadre ci-dessus',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _toggleTorch,
            tooltip: 'Torche',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: _switchCamera,
            tooltip: 'Changer caméra',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner (seulement visible si pas de QR code détecté)
          if (!_qrCodeDetected)
            MobileScanner(
              controller: cameraController,
              onDetect: _onQrCodeDetect,
              fit: BoxFit.cover,
            ),

          // Overlay de guidage
          _buildScannerOverlay(),

          // Instructions (seulement visible si pas de QR code détecté)
          if (!_qrCodeDetected && !_isProcessing)
            _buildScannerInstructions(),

          // Indicateur de traitement
          if (_isProcessing)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Traitement du QR code...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Panel QR code détecté
          if (_qrCodeDetected && _scannedQrCode != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildQrCodeDetectedPanel(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: !_qrCodeDetected
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _enterQrCodeManually,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Saisir manuellement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}