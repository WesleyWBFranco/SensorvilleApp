import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _feedbackImageLinkController =
      TextEditingController();
  String? _feedbackImageUrl;
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
  void initState() {
    super.initState();
    tz.initializeTimeZones();
  }

  Widget _buildUserFeedbackList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Usuário não autenticado.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('feedback')
              .where('userId', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar seus feedbacks: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Você ainda não enviou nenhum feedback.'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final message = data['message'] as String? ?? 'Sem mensagem';
            final timestamp = data['timestamp'] as Timestamp?;
            final imageUrls =
                (data['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [];

            String formattedDate = '';
            if (timestamp != null) {
              final DateTime utcDateTime = timestamp.toDate();
  
              final brazilianTimeZone = tz.getLocation('America/Sao_Paulo');
  
              final brazilianDateTime = tz.TZDateTime.from(
                utcDateTime,
                brazilianTimeZone,
              );
              formattedDate = DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(brazilianDateTime);
            }

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message, style: const TextStyle(fontSize: 16.0)),
                    if (imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 8.0),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageUrls.length,
                          itemBuilder: (context, imageIndex) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.network(
                                imageUrls[imageIndex],
                                fit: BoxFit.cover,
                                width: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                      child: Text('Erro na imagem'),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 8.0),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12.0),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
            const Text(
              'Enviar Feedback',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: _messageController,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: 'Sua Mensagem',
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black38),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.amber),
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
                  borderSide: const BorderSide(color: Colors.black38),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.amber),
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
            const SizedBox(height: 24.0),
            const Text(
              'Seus Feedbacks Enviados:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            _buildUserFeedbackList(),
          ],
        ),
      ),
    );
  }
}
