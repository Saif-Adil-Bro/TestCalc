import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Calculator Vault & App Picker',
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
  String _secretPin = '1234';
  bool _isVaultUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _secretPin = prefs.getString('secret_pin') ?? '1234';
    });
  }

  Future<void> _savePin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secret_pin', newPin);
    setState(() {
      _secretPin = newPin;
    });
  }

  bool _isOperator(String char) {
    return ['+', '-', '×', '÷', '%'].contains(char);
  }

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
          _showSnackBar('🔓 Secret Vault Unlocked!');
        } else {
          _evaluateExpression();
        }
      } else if (buttonText == '±') {
        if (_expression.startsWith('-')) {
          _expression = _expression.substring(1);
        } else if (_expression.isNotEmpty) {
          _expression = '-';
        }
      } else if (_isOperator(buttonText)) {
        if (_expression.isEmpty) {
          if (buttonText == '-') {
            _expression = '-';
          }
          return;
        }

        String lastChar = _expression[_expression.length - 1];
        if (_isOperator(lastChar)) {
          _expression = _expression.substring(0, _expression.length - 1) + buttonText;
        } else {
          _expression += buttonText;
        }
      } else if (buttonText == '.') {
        List<String> parts = _expression.split(RegExp(r'[+\-×÷%]'));
        String lastPart = parts.isNotEmpty ? parts.last : '';
        if (!lastPart.contains('.')) {
          if (_expression.isEmpty || _isOperator(_expression[_expression.length - 1])) {
            _expression += '0.';
          } else {
            _expression += '.';
          }
        }
      } else {
        _expression += buttonText;
      }
    });
  }

  void _showSnackBar(String message) {
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
        onChangePin: (newPin) async {
          await _savePin(newPin);
          _showSnackBar('🔒 PIN changed successfully to ');
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
  List<File> _hiddenPhotos = [];
  List<File> _hiddenFiles = [];
  List<Map<String, String>> _secretNotes = [];
  List<AppInfo> _installedApps = [];
  Set<String> _hiddenAppPackages = {};
  bool _isLoadingApps = true;

  @override
  void initState() {
    super.initState();
    _loadVaultData();
  }

  Future<void> _loadVaultData() async {
    final prefs = await SharedPreferences.getInstance();

    final notesJson = prefs.getString('secret_notes');
    if (notesJson != null) {
      final List decoded = jsonDecode(notesJson);
      _secretNotes = decoded.map((e) => Map<String, String>.from(e)).toList();
    } else {
      _secretNotes = [
        {'title': 'Welcome to Secret Vault', 'content': 'This note is stored encrypted on your device.'}
      ];
    }

    final hiddenList = prefs.getStringList('hidden_apps') ?? [];
    _hiddenAppPackages = hiddenList.toSet();

    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/vault_photos');
    final filesDir = Directory('${appDir.path}/vault_files');

    if (await photosDir.exists()) {
      _hiddenPhotos = photosDir.listSync().whereType<File>().toList();
    }
    if (await filesDir.exists()) {
      _hiddenFiles = filesDir.listSync().whereType<File>().toList();
    }

    try {
      List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true);
      _installedApps = apps.where((app) => app.packageName != 'com.example.flutter_calculator').toList();
    } catch (e) {
      debugPrint('Error loading installed apps: ');
    }

    if (mounted) {
      setState(() {
        _isLoadingApps = false;
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secret_notes', jsonEncode(_secretNotes));
  }

  Future<void> _toggleAppHide(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_hiddenAppPackages.contains(packageName)) {
        _hiddenAppPackages.remove(packageName);
      } else {
        _hiddenAppPackages.add(packageName);
      }
    });
    await prefs.setStringList('hidden_apps', _hiddenAppPackages.toList());
  }

  Future<void> _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/vault_photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final String newPath = '${photosDir.path}/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final File savedImage = await File(image.path).copy(newPath);

      setState(() {
        _hiddenPhotos.add(savedImage);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📸 Photo imported into Vault successfully!'), backgroundColor: Color(0xFF26E07F)),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final filesDir = Directory('${appDir.path}/vault_files');
      if (!await filesDir.exists()) {
        await filesDir.create(recursive: true);
      }
      final String originalName = result.files.single.name;
      final String newPath = '${filesDir.path}/${DateTime.now().millisecondsSinceEpoch}_$originalName';
      final File savedFile = await File(result.files.single.path!).copy(newPath);

      setState(() {
        _hiddenFiles.add(savedFile);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📁 File imported into Vault successfully!'), backgroundColor: Color(0xFF26E07F)),
        );
      }
    }
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

  // SEARCHABLE DYNAMIC APP PICKER
  void _openAppPickerModal() {
    TextEditingController searchController = TextEditingController();
    List<AppInfo> filteredApps = List.from(_installedApps);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF17181A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.apps_outage, color: Color(0xFFFF5A5F)),
                        SizedBox(width: 8),
                        Text(
                          'Select App to Hide',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search installed apps...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5A5F)),
                    filled: true,
                    fillColor: const Color(0xFF2E2F38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (query) {
                    setModalState(() {
                      filteredApps = _installedApps
                          .where((app) => app.name.toLowerCase().contains(query.toLowerCase()) || app.packageName.toLowerCase().contains(query.toLowerCase()))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _isLoadingApps
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        height: 380,
                        child: ListView.builder(
                          itemCount: filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = filteredApps[index];
                            final isHidden = _hiddenAppPackages.contains(app.packageName);

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E2F38),
                                borderRadius: BorderRadius.circular(12),
                                border: isHidden ? Border.all(color: const Color(0xFFFF5A5F), width: 1.5) : null,
                              ),
                              child: ListTile(
                                leading: app.icon != null
                                    ? Image.memory(app.icon!, width: 40, height: 40, gaplessPlayback: true, filterQuality: FilterQuality.low)
                                    : const Icon(Icons.android, size: 36, color: Color(0xFF26E07F)),
                                title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Text(app.packageName, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow, color: Color(0xFF26E07F)),
                                      tooltip: 'Launch App',
                                      onPressed: () {
                                        InstalledApps.startApp(app.packageName);
                                      },
                                    ),
                                    Checkbox(
                                      value: isHidden,
                                      activeColor: const Color(0xFFFF5A5F),
                                      onChanged: (val) {
                                        _toggleAppHide(app.packageName);
                                        setModalState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPhotosGallery() {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hidden Photos Gallery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5A5F)),
                    icon: const Icon(Icons.add_a_photo, size: 18),
                    label: const Text('Add Photo'),
                    onPressed: () async {
                      await _pickPhoto();
                      setModalState(() {});
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.grey),
              _hiddenPhotos.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No photos in secret vault. Tap Add Photo to import.')),
                    )
                  : SizedBox(
                      height: 380,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _hiddenPhotos.length,
                        itemBuilder: (context, index) {
                          final file = _hiddenPhotos[index];
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(file, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: () {
                                    file.deleteSync();
                                    setState(() {
                                      _hiddenPhotos.removeAt(index);
                                    });
                                    setModalState(() {});
                                  },
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black87,
                                    child: Icon(Icons.close, size: 14, color: Colors.red),
                                  ),
                                ),
                              ),
                            ],
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

  void _showDocumentsGallery() {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hidden Documents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF26E07F)),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Add Document'),
                    onPressed: () async {
                      await _pickFile();
                      setModalState(() {});
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.grey),
              _hiddenFiles.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No documents in vault. Tap Add Document to import.')),
                    )
                  : SizedBox(
                      height: 350,
                      child: ListView.builder(
                        itemCount: _hiddenFiles.length,
                        itemBuilder: (context, index) {
                          final file = _hiddenFiles[index];
                          final filename = file.path.split('/').last;
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E2F38),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.insert_drive_file, color: Color(0xFFF5A623)),
                              title: Text(filename, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  file.deleteSync();
                                  setState(() {
                                    _hiddenFiles.removeAt(index);
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

  void _showNotesModal() {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Secret Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
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
                              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                              const SizedBox(height: 8),
                              TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Content'), maxLines: 3),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                if (titleController.text.isNotEmpty) {
                                  setState(() {
                                    _secretNotes.add({
                                      'title': titleController.text,
                                      'content': contentController.text,
                                    });
                                  });
                                  _saveNotes();
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
                            _saveNotes();
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

  @override
  Widget build(BuildContext context) {
    final List<AppInfo> hiddenAppsList = _installedApps.where((app) => _hiddenAppPackages.contains(app.packageName)).toList();

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
                        Text('Default Launcher Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 2),
                        Text('Pick any installed app to hide from phone launcher.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5A5F)),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Pick App'),
                    onPressed: _openAppPickerModal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Protected Items & Apps',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_task, color: Color(0xFFFF5A5F)),
                  label: const Text('App Picker', style: TextStyle(color: Color(0xFFFF5A5F))),
                  onPressed: _openAppPickerModal,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildVaultCard(
                    icon: Icons.apps_outage,
                    title: 'Hidden Apps',
                    count: '${hiddenAppsList.length} Apps Picked',
                    color: const Color(0xFFFF5A5F),
                    onTap: _openAppPickerModal,
                  ),
                  _buildVaultCard(
                    icon: Icons.photo_library,
                    title: 'Hidden Photos',
                    count: '${_hiddenPhotos.length} Items',
                    color: const Color(0xFF4A90E2),
                    onTap: _showPhotosGallery,
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
                    onTap: _showDocumentsGallery,
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
}
