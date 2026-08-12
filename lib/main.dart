import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF17181A),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '0';

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'AC') {
        _expression = '';
        _result = '0';
      } else if (buttonText == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (buttonText == '=') {
        _evaluateExpression();
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
