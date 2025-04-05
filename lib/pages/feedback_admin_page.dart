import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/feedback.dart'; 

class FeedbackAdminPage extends StatefulWidget {
  const FeedbackAdminPage({super.key});

  @override
  State<FeedbackAdminPage> createState() => _FeedbackAdminPageState();
}

class _FeedbackAdminPageState extends State<FeedbackAdminPage> {
  final DateFormat _formatter = DateFormat('dd/MM/yyyy HH:mm');

  Future<void> _markAsRead(String feedbackId) async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(feedbackId)
          .update({'status': 'read'});
      setState(() {}); 
    } catch (e) {
      print('Erro ao marcar como lido: $e');
    }
  }

  Future<void> _markAsUnread(String feedbackId) async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(feedbackId)
          .update({'status': 'unread'});
      setState(() {}); 
    } catch (e) {
      print('Erro ao marcar como não lido: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('feedback')
                .orderBy('timestamp', descending: false)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar os feedbacks: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final feedbacksDocs = snapshot.data!.docs;
          final feedbacks =
              feedbacksDocs
                  .map(
                    (doc) => FeedbackMessage.fromFirestore(
                      doc.data(),
                    ).copyWith(id: doc.id),
                  )
                  .toList();

        
          feedbacks.sort((a, b) {
            if (a.status == 'unread' && b.status == 'read') {
              return -1; 
            } else if (a.status == 'read' && b.status == 'unread') {
              return 1; 
            } else {
              return a.timestamp.compareTo(b.timestamp);
            }
          });

          if (feedbacks.isEmpty) {
            return const Center(child: Text('Nenhum feedback recebido.'));
          }

          return ListView.builder(
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              final feedback = feedbacks[index];

              return FutureBuilder<DocumentSnapshot>(
                future:
                    feedback.userId != null
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(feedback.userId)
                            .get()
                        : Future.value(null),
                builder: (context, userSnapshot) {
                  String userName = 'Anônimo';
                  if (userSnapshot.connectionState == ConnectionState.done &&
                      userSnapshot.data?.exists == true) {
                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    userName =
                        userData?['first name'] ??
                        userData?['email'] ??
                        'Usuário Desconhecido';
                  } else if (feedback.userId != null) {
                    userName = 'Carregando nome...';
                  }

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Usuário: $userName',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          Text('Mensagem: ${feedback.message}'),
                          if (feedback.imageUrls.isNotEmpty) ...[
                            const SizedBox(height: 8.0),
                            const Text(
                              'Imagens:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: feedback.imageUrls.length,
                                itemBuilder: (context, imageIndex) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Image.network(
                                      feedback.imageUrls[imageIndex],
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return const Text(
                                          'Erro ao carregar imagem',
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
                            'Enviado em: ${_formatter.format(feedback.timestamp.toDate().toLocal())}',
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Status: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${feedback.status == 'unread' ? 'Não Lido' : 'Lido'}',
                                    style: TextStyle(
                                      color:
                                          feedback.status == 'unread'
                                              ? Colors.red
                                              : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 16.0),
                              if (feedback.status == 'unread')
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                  ),
                                  onPressed: () => _markAsRead(feedback.id!),
                                  child: const Text(
                                    'Marcar como Lido',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              else
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                  ),
                                  onPressed: () => _markAsUnread(feedback.id!),
                                  child: const Text(
                                    'Marcar como Não Lido',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
