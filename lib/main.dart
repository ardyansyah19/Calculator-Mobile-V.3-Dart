import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'calculator_logic.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kalkulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1976D2),
        scaffoldBackgroundColor: const Color(0xFF263238),
        fontFamily: 'Roboto',
      ),
      home: const CalculatorHome(),
    );
  }
}

class HistoryEntry {
  final String expression;
  final String result;
  HistoryEntry(this.expression, this.result);
}

class CalculatorHome extends StatefulWidget {
  const CalculatorHome({super.key});

  @override
  State<CalculatorHome> createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<HistoryEntry> _history = [];
  final ScrollController _historyScroll = ScrollController();

  int _keypadTab = 0; // 0: dasar, 1: fungsi, 2: yunani/konstanta
  bool _rawKeyboard = false; // toggle keyboard sistem (ikon paling kanan)
  String? _errorText;
  String _lastResult = '';

  static const Color kOrange = Color(0xFFFF7A00);
  static const Color kBlue = Color(0xFF1E88E5);
  static const Color kKeyDark = Color(0xFF37474F);
  static const Color kKeyDarker = Color(0xFF2C393F);

  void _insert(String text) {
    final sel = _controller.selection;
    final oldText = _controller.text;
    int start = sel.start;
    int end = sel.end;
    if (start < 0 || end < 0) {
      start = oldText.length;
      end = oldText.length;
    }
    final newText = oldText.replaceRange(start, end, text);
    _controller.text = newText;
    final newPos = start + text.length;
    _controller.selection = TextSelection.collapsed(offset: newPos);
    setState(() => _errorText = null);
  }

  void _insertFunction(String name) {
    _insert('$name(');
  }

  void _backspace() {
    final sel = _controller.selection;
    final oldText = _controller.text;
    if (oldText.isEmpty) return;
    int start = sel.start;
    int end = sel.end;
    if (start < 0 || end < 0 || start != end) {
      start = oldText.length;
      end = oldText.length;
    }
    if (start == 0) return;
    final newText = oldText.replaceRange(start - 1, end, '');
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: start - 1);
    setState(() => _errorText = null);
  }

  void _clear() {
    setState(() {
      _controller.clear();
      _errorText = null;
      _lastResult = '';
    });
  }

  void _equals() {
    final expr = _controller.text.trim();
    if (expr.isEmpty) return;
    try {
      final result = evaluateExpression(expr);
      final resultText = _formatNumber(result);
      setState(() {
        _history.add(HistoryEntry(expr, resultText));
        _lastResult = resultText;
        _errorText = null;
        _controller.text = resultText;
        _controller.selection = TextSelection.collapsed(
          offset: resultText.length,
        );
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_historyScroll.hasClients) {
          _historyScroll.animateTo(
            _historyScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } on CalcError catch (e) {
      setState(() => _errorText = e.message);
    } catch (e) {
      setState(() => _errorText = 'Ekspresi tidak valid');
    }
  }

  String _formatNumber(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e15) {
      return v.toStringAsFixed(0);
    }
    String s = v.toStringAsPrecision(12);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _historyScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFECEFF1),
        foregroundColor: Colors.black87,
        elevation: 1,
        titleSpacing: 8,
        title: Row(
          children: const [
            Icon(Icons.calculate_outlined, color: kBlue),
            SizedBox(width: 8),
            Text(
              'Kalkulator',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDisplay(),
            Expanded(child: _buildHistoryPanel()),
            _buildTabBar(),
            _buildKeypadArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kOrange, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              readOnly: !_rawKeyboard,
              showCursor: true,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              inputFormatters: _rawKeyboard
                  ? [FilteringTextInputFormatter.allow(RegExp(r'.'))]
                  : [],
            ),
          ),
          InkWell(
            onTap: _clear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: kOrange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'C',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kBlue.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: _errorText != null
          ? Text(
              _errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            )
          : _history.isEmpty
              ? const Text(
                  'Riwayat perhitungan akan tampil di sini',
                  style: TextStyle(color: Colors.black38),
                )
              : ListView.builder(
                  controller: _historyScroll,
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final h = _history[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${h.expression} = ${h.result}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildTabBar() {
    Widget tabBtn(String label, int index) {
      final selected = _keypadTab == index && !_rawKeyboard;
      return GestureDetector(
        onTap: () => setState(() {
          _keypadTab = index;
          _rawKeyboard = false;
        }),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? kBlue : kKeyDark,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? Colors.white : Colors.white24,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              tabBtn('1', 0),
              tabBtn('2', 1),
              tabBtn('3', 2),
            ],
          ),
          Row(
            children: [
              tabBtn('a-z', 3),
              tabBtn('α-ω', 4),
              GestureDetector(
                onTap: () {
                  setState(() => _rawKeyboard = !_rawKeyboard);
                  if (_rawKeyboard) {
                    _focusNode.requestFocus();
                  } else {
                    _focusNode.unfocus();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _rawKeyboard ? kBlue : kKeyDark,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.keyboard_alt_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadArea() {
    Widget grid;
    switch (_keypadTab) {
      case 1:
        grid = _buildFunctionKeypad();
        break;
      case 2:
        grid = _buildConstantsKeypad();
        break;
      case 3:
        grid = _buildAlphaKeypad();
        break;
      default:
        grid = _buildMainKeypad();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: grid,
    );
  }

  // Keypad utama, layout meniru urutan tombol pada gambar contoh.
  Widget _buildMainKeypad() {
    return Column(
      children: [
        _row([
          _key('%', kBlue, () => _insert('%')),
          _key('n!', kBlue, () => _insert('!')),
          _key('7', kKeyDark, () => _insert('7')),
          _key('8', kKeyDark, () => _insert('8')),
          _key('9', kKeyDark, () => _insert('9')),
          _key('÷', kKeyDarker, () => _insert('÷')),
          _key('(', kKeyDarker, () => _insert('(')),
        ]),
        _row([
          _key('|x|', kBlue, () => _insertFunction('abs')),
          _key('xⁿ', kBlue, () => _insert('^')),
          _key('4', kKeyDark, () => _insert('4')),
          _key('5', kKeyDark, () => _insert('5')),
          _key('6', kKeyDark, () => _insert('6')),
          _key('×', kKeyDarker, () => _insert('×')),
          _key(')', kKeyDarker, () => _insert(')')),
        ]),
        _row([
          _key('xʸ', kBlue, () => _insert('^')),
          _key('√', kBlue, () => _insertFunction('sqrt')),
          _key('1', kKeyDark, () => _insert('1')),
          _key('2', kKeyDark, () => _insert('2')),
          _key('3', kKeyDark, () => _insert('3')),
          _key('−', kKeyDarker, () => _insert('-')),
          _key('⌫', kOrange, _backspace, textColor: Colors.white),
        ]),
        _row([
          _key('a-z', kBlue, () => setState(() => _keypadTab = 3)),
          _key('0', kKeyDark, () => _insert('0')),
          _key('.', kKeyDark, () => _insert('.')),
          _key('π', kKeyDark, () => _insert('pi')),
          _key('+', kKeyDarker, () => _insert('+')),
          _key('=', kOrange, _equals, flex: 2, textColor: Colors.white),
        ]),
      ],
    );
  }

  // Tab fungsi ilmiah tambahan (trig, log, dsb) — bagian dari "semua fitur".
  Widget _buildFunctionKeypad() {
    return Column(
      children: [
        _row([
          _key('sin', kBlue, () => _insertFunction('sin')),
          _key('cos', kBlue, () => _insertFunction('cos')),
          _key('tan', kBlue, () => _insertFunction('tan')),
          _key('log', kBlue, () => _insertFunction('log')),
          _key('ln', kBlue, () => _insertFunction('ln')),
        ]),
        _row([
          _key('(', kKeyDarker, () => _insert('(')),
          _key(')', kKeyDarker, () => _insert(')')),
          _key('^', kKeyDarker, () => _insert('^')),
          _key('!', kKeyDarker, () => _insert('!')),
          _key('%', kKeyDarker, () => _insert('%')),
        ]),
        _row([
          _key('7', kKeyDark, () => _insert('7')),
          _key('8', kKeyDark, () => _insert('8')),
          _key('9', kKeyDark, () => _insert('9')),
          _key('4', kKeyDark, () => _insert('4')),
          _key('⌫', kOrange, _backspace, textColor: Colors.white),
        ]),
        _row([
          _key('5', kKeyDark, () => _insert('5')),
          _key('6', kKeyDark, () => _insert('6')),
          _key('1', kKeyDark, () => _insert('1')),
          _key('2', kKeyDark, () => _insert('2')),
          _key('3', kKeyDark, () => _insert('3')),
        ]),
        _row([
          _key('0', kKeyDark, () => _insert('0')),
          _key('.', kKeyDark, () => _insert('.')),
          _key('+', kKeyDarker, () => _insert('+')),
          _key('−', kKeyDarker, () => _insert('-')),
          _key('=', kOrange, _equals, textColor: Colors.white),
        ]),
      ],
    );
  }

  // Tab konstanta / simbol tambahan.
  Widget _buildConstantsKeypad() {
    return Column(
      children: [
        _row([
          _key('π', kBlue, () => _insert('pi')),
          _key('e', kBlue, () => _insert('e')),
          _key('√', kBlue, () => _insertFunction('sqrt')),
          _key('|x|', kBlue, () => _insertFunction('abs')),
        ]),
        _row([
          _key('(', kKeyDarker, () => _insert('(')),
          _key(')', kKeyDarker, () => _insert(')')),
          _key('^', kKeyDarker, () => _insert('^')),
          _key('!', kKeyDarker, () => _insert('!')),
        ]),
        _row([
          _key('7', kKeyDark, () => _insert('7')),
          _key('8', kKeyDark, () => _insert('8')),
          _key('9', kKeyDark, () => _insert('9')),
          _key('⌫', kOrange, _backspace, textColor: Colors.white),
        ]),
        _row([
          _key('4', kKeyDark, () => _insert('4')),
          _key('5', kKeyDark, () => _insert('5')),
          _key('6', kKeyDark, () => _insert('6')),
          _key('=', kOrange, _equals, textColor: Colors.white),
        ]),
      ],
    );
  }

  // Tab huruf, berguna bila ingin menuliskan nama variabel/fungsi manual.
  Widget _buildAlphaKeypad() {
    const letters = 'abcdefghijklmnopqrstuvwxyz';
    final rows = <Widget>[];
    for (int i = 0; i < letters.length; i += 7) {
      final chunk = letters.substring(
        i,
        (i + 7) > letters.length ? letters.length : i + 7,
      );
      rows.add(
        _row(
          chunk
              .split('')
              .map((c) => _key(c, kKeyDark, () => _insert(c)))
              .toList(),
        ),
      );
    }
    rows.add(
      _row([
        _key('123', kBlue, () => setState(() => _keypadTab = 0)),
        _key('⌫', kOrange, _backspace, textColor: Colors.white),
        _key('=', kOrange, _equals, textColor: Colors.white),
      ]),
    );
    return Column(children: rows);
  }

  Widget _row(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: children),
    );
  }

  Widget _key(
    String label,
    Color color,
    VoidCallback onTap, {
    int flex = 1,
    Color textColor = Colors.white,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onTap,
            child: Container(
              height: 46,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bantuan'),
        content: const Text(
          'Kalkulator ini mendukung: operasi dasar (+ − × ÷), pangkat (xʸ), '
          'akar (√), faktorial (n!), persen (%), nilai mutlak (|x|), '
          'fungsi trigonometri (sin, cos, tan), logaritma (log, ln), '
          'konstanta π dan e, serta tanda kurung.\n\n'
          'Ketuk tab 1/2/3 untuk berpindah antar keypad, dan a-z untuk '
          'menulis huruf secara manual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
