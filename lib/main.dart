import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const SshApp());
}

class SshApp extends StatelessWidget {
  const SshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureSSH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const ConnectionScreen(),
    );
  }
}

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController(text: '192.168.1.');
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController(text: 'root');
  final _passwordController = TextEditingController(text: '');

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    SSHClient? client;
    try {
      final socket = await SSHSocket.connect(
        _hostController.text.trim(),
        int.parse(_portController.text.trim()),
        timeout: const Duration(seconds: 5),
      );

      client = SSHClient(
        socket,
        username: _usernameController.text.trim(),
        onPasswordRequest: () => _passwordController.text,
      );

      // Verify authentication handshake goes through
      await client.authenticated;

      if (!mounted) {
        client.close();
        return;
      }

      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TerminalScreen(
            client: client!,
            host: _hostController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      client?.close();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection Failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SecureSSH Client',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Remote Connection',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your SSH server credentials below',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _hostController,
                              decoration: const InputDecoration(
                                labelText: 'Host / IP',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? 'Enter host' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _portController,
                              decoration: const InputDecoration(
                                labelText: 'Port',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  value!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter username' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) =>
                            value!.isEmpty ? 'Enter password' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _connect,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Connect to Server',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TerminalScreen extends StatefulWidget {
  final SSHClient client;
  final String host;

  const TerminalScreen({super.key, required this.client, required this.host});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final List<String> _logs = [];
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    _appendLog(
      'Connected successfully to ${widget.host}\n'
      'Type commands below (e.g., uname -a, ls -l)',
    );
  }

  void _appendLog(String text) {
    if (!mounted) return;
    setState(() {
      _logs.add(text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runCommand(String command) async {
    if (command.trim().isEmpty) return;

    final cmdText = command;
    _commandController.clear();
    _appendLog('\$ $cmdText');

    setState(() => _isExecuting = true);

    try {
      // Execute command on remote machine and read standard output/error combined
      final result = await widget.client.run(cmdText);
      final output = utf8.decode(result);
      _appendLog(output.isEmpty ? '[Command executed with no output]' : output);
    } catch (e) {
      _appendLog('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isExecuting = false);
    }
  }

  @override
  void dispose() {
    widget.client.close();
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terminal: ${widget.host}',
          style: GoogleFonts.firaCode(fontSize: 14),
        ),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Disconnect',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black.withValues(alpha: 0.4),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      _logs[index],
                      style: GoogleFonts.firaCode(
                        fontSize: 13,
                        color: Colors.greenAccent[400],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_isExecuting)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: Colors.blueAccent,
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                const Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: GoogleFonts.firaCode(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _runCommand,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () => _runCommand(_commandController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
