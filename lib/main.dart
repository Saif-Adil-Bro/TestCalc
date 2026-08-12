import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorVaultApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CalculatorVaultApp();
  }
}

class CalculatorVaultApp extends StatelessWidget {
  const CalculatorVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator Vault & Launcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF17181A),
        primaryColor: const Color(0xFFFF5A5F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5A5F),
          secondary: Color(0xFF26E07F),
        ),
      ),
      home: const CalculatorVaultScreen(),
    );
  }
}

class CalculatorVaultScreen extends StatefulWidget {
  const CalculatorVaultScreen({super.key});

  @override
  State<CalculatorVaultScreen> createState() => _CalculatorVaultScreenState();
}

class _CalculatorVaultScreenState extends State<CalculatorVaultScreen> {
  String _expression = '';
  String _result = '0';
  String? _secretPin = '1234'; // Default secret PIN
  bool _isVaultUnlocked = false;

  void _onButtonPressed(String buttonText) {
    if (_isVaultUnlocked) return;

    setState(() {
      if (buttonText == 'AC') {
        _expression = '';
        _result = '0';
      } else if (buttonText == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (buttonText == '=') {
        if (_expression == _secretPin) {
          _isVaultUnlocked = true;
          _expression = '';
          _result = '0';
          _showVaultSnackBar('🔓 Secret Vault & App Hiding Unlocked!');
        } else if (_secretPin == null && _expression.length == 4 && RegExp(r'^\d+$').hasMatch(_expression)) {
          _secretPin = _expression;
          _isVaultUnlocked = true;
          _expression = '';
          _result = '0';
          _showVaultSnackBar('🔒 Secret PIN set to !');
        } else {
          _evaluateExpression();
        }
      } else if (buttonText == '±') {
        if (_expression.startsWith('-')) {
          _expression = _expression.substring(1);
        } else if (_expression.isNotEmpty) {
          _expression = '-';
        }
      } else if (buttonText == '%') {
        try {
          double val = double.parse(_result != '0' && _expression.isEmpty ? _result : _expression);
          _result = (val / 100).toString();
          _expression = '';
        } catch (_) {
          _result = 'Error';
        }
      } else {
        _expression += buttonText;
      }
    });
  }

  void _showVaultSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF26E07F),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _evaluateExpression() {
    try {
      String exp = _expression.replaceAll('×', '*').replaceAll('÷', '/');
      double evalResult = _simpleEvaluate(exp);
      if (evalResult % 1 == 0) {
        _result = evalResult.toInt().toString();
      } else {
        _result = evalResult.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    } catch (e) {
      _result = 'Error';
    }
  }

  double _simpleEvaluate(String expr) {
    List<String> tokens = [];
    String numberBuffer = '';
    
    for (int i = 0; i < expr.length; i++) {
      String char = expr[i];
      if ('0123456789.'.contains(char)) {
        numberBuffer += char;
      } else if ('+-*/'.contains(char)) {
        if (numberBuffer.isNotEmpty) {
          tokens.add(numberBuffer);
          numberBuffer = '';
        } else if (char == '-' && (tokens.isEmpty || '+-*/'.contains(tokens.last))) {
          numberBuffer += char;
          continue;
        }
        tokens.add(char);
      }
    }
    if (numberBuffer.isNotEmpty) {
      tokens.add(numberBuffer);
    }

    if (tokens.isEmpty) return 0;

    List<String> pass1 = [];
    int i = 0;
    while (i < tokens.length) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        String op = tokens[i];
        double prev = double.parse(pass1.removeLast());
        double next = double.parse(tokens[i + 1]);
        double res = (op == '*') ? (prev * next) : (prev / next);
        pass1.add(res.toString());
        i += 2;
      } else {
        pass1.add(tokens[i]);
        i++;
      }
    }

    double result = double.parse(pass1[0]);
    int j = 1;
    while (j < pass1.length) {
      String op = pass1[j];
      double next = double.parse(pass1[j + 1]);
      if (op == '+') result += next;
      if (op == '-') result -= next;
      j += 2;
    }

    return result;
  }

  Widget _buildButton(String text, {Color? textColor, Color? bgColor}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor ?? const Color(0xFF2E2F38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.all(20.0),
          ),
          onPressed: () => _onButtonPressed(text),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isVaultUnlocked) {
      return VaultDashboardScreen(
        onLockVault: () {
          setState(() {
            _isVaultUnlocked = false;
            _expression = '';
            _result = '0';
          });
        },
        onChangePin: (newPin) {
          setState(() {
            _secretPin = newPin;
          });
          _showVaultSnackBar('🔒 PIN changed successfully to ');
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _expression,
                      style: const TextStyle(fontSize: 28, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _result,
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    _buildButton('AC', textColor: const Color(0xFF26E07F)),
                    _buildButton('⌫', textColor: const Color(0xFF26E07F)),
                    _buildButton('%', textColor: const Color(0xFF26E07F)),
                    _buildButton('÷', textColor: const Color(0xFFFF5A5F)),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('7'),
                    _buildButton('8'),
                    _buildButton('9'),
                    _buildButton('×', textColor: const Color(0xFFFF5A5F)),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('4'),
                    _buildButton('5'),
                    _buildButton('6'),
                    _buildButton('-', textColor: const Color(0xFFFF5A5F)),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('1'),
                    _buildButton('2'),
                    _buildButton('3'),
                    _buildButton('+', textColor: const Color(0xFFFF5A5F)),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('±'),
                    _buildButton('0'),
                    _buildButton('.'),
                    _buildButton('=', bgColor: const Color(0xFFFF5A5F)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class VaultDashboardScreen extends StatefulWidget {
  final VoidCallback onLockVault;
  final ValueChanged<String> onChangePin;

  const VaultDashboardScreen({
    super.key,
    required this.onLockVault,
    required this.onChangePin,
  });

  @override
  State<VaultDashboardScreen> createState() => _VaultDashboardScreenState();
}

class _VaultDashboardScreenState extends State<VaultDashboardScreen> {
  final List<String> _hiddenPhotos = [];
  final List<String> _hiddenFiles = [];
  final List<Map<String, String>> _secretNotes = [
    {'title': 'Welcome to Vault', 'content': 'This is your private space hidden behind the calculator.'}
  ];

  // App Hide & Launcher Management
  final Map<String, bool> _appHideStatus = {
    'WhatsApp': true,
    'Facebook': true,
    'Gallery / Photos': false,
    'Instagram': false,
    'Messages': false,
    'Settings': false,
    'Browser / Chrome': false,
  };

  void _toggleAppHide(String appName) {
    setState(() {
      _appHideStatus[appName] = !(_appHideStatus[appName] ?? false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_appHideStatus[appName]!
            ? '🙈  is now HIDDEN from Home Launcher'
            : '👁️  is now VISIBLE on Home Launcher'),
        backgroundColor: _appHideStatus[appName]! ? const Color(0xFFFF5A5F) : const Color(0xFF26E07F),
      ),
    );
  }

  void _showAppHideManager() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF17181A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.app_registration, color: Color(0xFFFF5A5F)),
                  SizedBox(width: 8),
                  Text(
                    'App Hide & Launcher Manager',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Toggle switch to hide apps from the Default Home Screen.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Divider(color: Colors.grey),
              SizedBox(
                height: 320,
                child: ListView(
                  children: _appHideStatus.keys.map((appName) {
                    bool isHidden = _appHideStatus[appName] ?? false;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E2F38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        value: isHidden,
                        activeColor: const Color(0xFFFF5A5F),
                        title: Text(appName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(isHidden ? 'Status: Hidden' : 'Status: Visible', style: TextStyle(color: isHidden ? Colors.redAccent : Colors.greenAccent)),
                        secondary: Icon(
                          isHidden ? Icons.visibility_off : Icons.visibility,
                          color: isHidden ? const Color(0xFFFF5A5F) : const Color(0xFF26E07F),
                        ),
                        onChanged: (val) {
                          _toggleAppHide(appName);
                          setModalState(() {});
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePinDialog() {
    TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Secret PIN'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Enter new 4-digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                widget.onChangePin(pinController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Update PIN'),
          ),
        ],
      ),
    );
  }

  void _addMockFile(String type) {
    setState(() {
      if (type == 'Photo') {
        _hiddenPhotos.add('Photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
      } else {
        _hiddenFiles.add('Document_${DateTime.now().millisecondsSinceEpoch}.pdf');
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🔒 Added private  to Vault')),
    );
  }

  @override
  Widget build(BuildContext context) {
    int hiddenAppsCount = _appHideStatus.values.where((h) => h).length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.security, color: Color(0xFF26E07F)),
            SizedBox(width: 8),
            Text('Vault & Home Launcher'),
          ],
        ),
        backgroundColor: const Color(0xFF2E2F38),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'Change Secret PIN',
            onPressed: _showChangePinDialog,
          ),
          IconButton(
            icon: const Icon(Icons.lock, color: Color(0xFFFF5A5F)),
            tooltip: 'Lock Vault',
            onPressed: widget.onLockVault,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2F38),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF26E07F).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home, size: 36, color: Color(0xFF26E07F)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Default Launcher Enabled', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 2),
                        Text('App acts as phone home screen & hides selected apps.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5A5F)),
                    onPressed: _showAppHideManager,
                    child: const Text('Hide Apps'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Protected Items & Apps',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildVaultCard(
                    icon: Icons.apps_outage,
                    title: 'Hidden Apps',
                    count: ' Apps Hidden',
                    color: const Color(0xFFFF5A5F),
                    onTap: _showAppHideManager,
                  ),
                  _buildVaultCard(
                    icon: Icons.photo_library,
                    title: 'Hidden Photos',
                    count: '${_hiddenPhotos.length} Items',
                    color: const Color(0xFF4A90E2),
                    onTap: () => _showItemsDialog('Hidden Photos', _hiddenPhotos, () => _addMockFile('Photo')),
                  ),
                  _buildVaultCard(
                    icon: Icons.note_alt,
                    title: 'Secret Notes',
                    count: '${_secretNotes.length} Notes',
                    color: const Color(0xFF26E07F),
                    onTap: _showNotesModal,
                  ),
                  _buildVaultCard(
                    icon: Icons.insert_drive_file,
                    title: 'Hidden Documents',
                    count: '${_hiddenFiles.length} Files',
                    color: const Color(0xFFF5A623),
                    onTap: () => _showItemsDialog('Hidden Documents', _hiddenFiles, () => _addMockFile('Document')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E2F38),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF17181A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Secret Notes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF26E07F)),
                    onPressed: () {
                      TextEditingController titleController = TextEditingController();
                      TextEditingController contentController = TextEditingController();

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Add Secret Note'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(labelText: 'Title'),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: contentController,
                                decoration: const InputDecoration(labelText: 'Secret Note Content'),
                                maxLines: 3,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (titleController.text.isNotEmpty) {
                                  setState(() {
                                    _secretNotes.add({
                                      'title': titleController.text,
                                      'content': contentController.text,
                                    });
                                  });
                                  Navigator.pop(context);
                                  setModalState(() {});
                                }
                              },
                              child: const Text('Save Note'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: ListView.builder(
                  itemCount: _secretNotes.length,
                  itemBuilder: (context, index) {
                    final note = _secretNotes[index];
                    return Card(
                      color: const Color(0xFF2E2F38),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(note['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(note['content'] ?? '', style: const TextStyle(color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _secretNotes.removeAt(index);
                            });
                            setModalState(() {});
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemsDialog(String title, List<String> items, VoidCallback onAdd) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title),
              IconButton(
                icon: const Icon(Icons.add_a_photo, color: Color(0xFFFF5A5F)),
                onPressed: () {
                  onAdd();
                  setDialogState(() {});
                },
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 250,
            child: items.isEmpty
                ? const Center(child: Text('No hidden items in vault.'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(Icons.lock, color: Color(0xFF26E07F)),
                      title: Text(items[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            items.removeAt(index);
                          });
                          setDialogState(() {});
                        },
                      ),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
