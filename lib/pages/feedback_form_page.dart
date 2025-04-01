import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _feedbackImageLinkController =
      TextEditingController(); // Novo controller para o link
  String? _feedbackImageUrl; // Para armazenar o link da imagem
  bool _isLoading = false;

  void _addLinkToFeedback() {
    final link = _feedbackImageLinkController.text.trim();
    if (link.isNotEmpty && Uri.parse(link).isAbsolute) {
      setState(() {
        _feedbackImageUrl = link;
        _feedbackImageLinkController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um link de imagem válido.'),
        ),
      );
    }
  }

  Future<void> _submitFeedback() async {
    if (_messageController.text.isEmpty && _feedbackImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, digite uma mensagem ou adicione um link de imagem.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<String> imageUrls = [];
    if (_feedbackImageUrl != null) {
      imageUrls.add(_feedbackImageUrl!);
    }

    final user = FirebaseAuth.instance.currentUser;
    final feedbackCollection = FirebaseFirestore.instance.collection(
      'feedback',
    );

    try {
      await feedbackCollection.add({
        'userId': user?.uid,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
        'imageUrls': imageUrls,
      });

      _messageController.clear();
      setState(() {
        _feedbackImageUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback enviado com sucesso!')),
      );
    } catch (e) {
      print('Erro ao enviar feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao enviar o feedback.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _messageController,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: 'Sua Mensagem',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black38),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _feedbackImageLinkController,
              decoration: InputDecoration(
                labelText: 'Link da Imagem (Opcional)',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black38),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 15.0),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: _addLinkToFeedback,
              icon: const Icon(Icons.link, color: Colors.white),
              label: const Text(
                'Adicionar Link da Imagem',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8.0),
            if (_feedbackImageUrl != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Prévia da Imagem:'),
                  const SizedBox(height: 4.0),
                  SizedBox(
                    child: Image.network(
                      _feedbackImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('Erro ao carregar a imagem');
                      },
                    ),
                  ),

                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          _feedbackImageUrl = null;
                        });
                      },
                      child: const Text(
                        'Remover Link da Imagem',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: _isLoading ? null : _submitFeedback,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                        'Enviar Feedback',
                        style: TextStyle(color: Colors.white),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
