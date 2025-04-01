import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchBibleLink() async {
    final Uri _url = Uri.parse(
      'https://www.bibliaon.com/versiculo/mateus_22_37/',
    );
    if (!await launchUrl(_url)) {
      throw Exception('Não foi possível abrir o link da Bíblia: $_url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                children: [
                  Text(
                    'Desenvolvido por',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Wesley Franco & Jenifer Seibert',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    '"Ame o Senhor, seu Deus, de todo o seu coração, de toda a sua alma e de todo o seu entendimento"',
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.amber,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _launchBibleLink,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.book_outlined,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Mateus 22:37 (NVI)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber[800],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Column(
                children: [
                  Text(
                    'Versão do App',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1.0.0', // Defina aqui a versão atual do seu app
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
