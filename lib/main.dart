import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MercadoSmartApp());
}

class MercadoSmartApp extends StatelessWidget {
  const MercadoSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MercadoSmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A), // Slate 900
          primary: const Color(0xFF164E63),   // Cyan 900
          secondary: const Color(0xFF0891B2), // Cyan 600
          background: const Color(0xFFF8FAFC), // Slate 50
        ),
        fontFamily: 'Inter',
      ),
      home: const MainHomeScreen(),
    );
  }
}

// Modelos de dados
enum SectorType {
  BEBIDAS,
  CONFEITARIA,
  ACOUGE,
  PADARIA,
  LIMPEZA,
  HIGIENE,
  HORTIFRUTI,
  MERCEARIA,
  OUTROS
}

extension SectorExtension on SectorType {
  String get label {
    switch (this) {
      case SectorType.BEBIDAS: return 'Bebidas';
      case SectorType.CONFEITARIA: return 'Confeitaria';
      case SectorType.ACOUGE: return 'Açougue';
      case SectorType.PADARIA: return 'Padaria';
      case SectorType.LIMPEZA: return 'Produtos de Limpeza';
      case SectorType.HIGIENE: return 'Higiene Pessoal';
      case SectorType.HORTIFRUTI: return 'Hortifruti';
      case SectorType.MERCEARIA: return 'Mercearia';
      case SectorType.OUTROS: return 'Outros';
    }
  }

  String get emoji {
    switch (this) {
      case SectorType.BEBIDAS: return '🥤';
      case SectorType.CONFEITARIA: return '🧁';
      case SectorType.ACOUGE: return '🥩';
      case SectorType.PADARIA: return '🥖';
      case SectorType.LIMPEZA: return '🧼';
      case SectorType.HIGIENE: return '🧴';
      case SectorType.HORTIFRUTI: return '🥦';
      case SectorType.MERCEARIA: return '🥫';
      case SectorType.OUTROS: return '📦';
    }
  }

  Color get color {
    switch (this) {
      case SectorType.BEBIDAS: return Colors.teal;
      case SectorType.CONFEITARIA: return const Color(0xFFD946EF);
      case SectorType.ACOUGE: return Colors.red;
      case SectorType.PADARIA: return Colors.amber;
      case SectorType.LIMPEZA: return Colors.blue;
      case SectorType.HIGIENE: return Colors.cyan;
      case SectorType.HORTIFRUTI: return Colors.lightGreen;
      case SectorType.MERCEARIA: return Colors.orange;
      case SectorType.OUTROS: return Colors.grey;
    }
  }
}

class ShoppingItem {
  final String id;
  final String name;
  bool checked;
  SectorType sector;

  ShoppingItem({
    required this.id,
    required this.name,
    this.checked = false,
    this.sector = SectorType.OUTROS,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'checked': checked,
    'sector': sector.name,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      name: json['name'],
      checked: json['checked'] ?? false,
      sector: SectorType.values.byName(json['sector'] ?? 'OUTROS'),
    );
  }
}

class Market {
  final String id;
  final String name;
  List<SectorType> sectionsOrder;

  Market({
    required this.id,
    required this.name,
    required this.sectionsOrder,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sectionsOrder': sectionsOrder.map((e) => e.name).toList(),
  };

  factory Market.fromJson(Map<String, dynamic> json) {
    var rawList = json['sectionsOrder'] as List? ?? [];
    return Market(
      id: json['id'],
      name: json['name'],
      sectionsOrder: rawList.map((e) => SectorType.values.byName(e)).toList(),
    );
  }
}

// API de Integração Inteligente com o servidor Node/Python para Inventário, OCR e Classificação
class ApiService {
  // Substitua pela URL real de produção do backend
  static const String baseUrl = 'https://ais-dev-n3pvdcez6dsgxagddvdyp2-561013173850.us-west2.run.app/api';

  // 1. Chamar classificação inteligente de setor e corredor por IA
  static Future<SectorType> classifyProduct(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/classify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'items': [name]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final sectorStr = data[0]['sector'].toString().toUpperCase();
          if (sectorStr.contains('BEBIDA')) return SectorType.BEBIDAS;
          if (sectorStr.contains('CONFEITARIA')) return SectorType.CONFEITARIA;
          if (sectorStr.contains('AÇOUGUE') || sectorStr.contains('CARNE')) return SectorType.ACOUGE;
          if (sectorStr.contains('PADARIA')) return SectorType.PADARIA;
          if (sectorStr.contains('LIMPEZA')) return SectorType.LIMPEZA;
          if (sectorStr.contains('HIGIENE')) return SectorType.HIGIENE;
          if (sectorStr.contains('HORTIFRUTI')) return SectorType.HORTIFRUTI;
          if (sectorStr.contains('MERCEARIA')) return SectorType.MERCEARIA;
        }
      }
    } catch (e) {
      debugPrint('Erro de rede na classificação via API de Inventário: $e');
    }
    return _heuristicsClassify(name);
  }

  // Heurística local para fallback rápido / offline
  static SectorType _heuristicsClassify(String name) {
    final clean = name.toLowerCase();
    if (clean.contains('refrigerante') || clean.contains('suco') || clean.contains('cerveja') || clean.contains('água') || clean.contains('coke') || clean.contains('bebida')) {
      return SectorType.BEBIDAS;
    }
    if (clean.contains('leite condensado') || clean.contains('chocolate') || clean.contains('bolo') || clean.contains('doce')) {
      return SectorType.CONFEITARIA;
    }
    if (clean.contains('carne') || clean.contains('frango') || clean.contains('açougue') || clean.contains('bife') || clean.contains('salame')) {
      return SectorType.ACOUGE;
    }
    if (clean.contains('pão') || clean.contains('brioche') || clean.contains('padaria') || clean.contains('baguete')) {
      return SectorType.PADARIA;
    }
    if (clean.contains('detergente') || clean.contains('sabão') || clean.contains('limpeza') || clean.contains('amaciante')) {
      return SectorType.LIMPEZA;
    }
    if (clean.contains('shampoo') || clean.contains('sabonete') || clean.contains('condicionador') || clean.contains('higiene') || clean.contains('pasta')) {
      return SectorType.HIGIENE;
    }
    if (clean.contains('banana') || clean.contains('alface') || clean.contains('tomate') || clean.contains('fruta') || clean.contains('hortifruti')) {
      return SectorType.HORTIFRUTI;
    }
    if (clean.contains('arroz') || clean.contains('feijão') || clean.contains('óleo') || clean.contains('hummus') || clean.contains('mercearia')) {
      return SectorType.MERCEARIA;
    }
    return SectorType.OUTROS;
  }

  // 2. Extrair itens manuscritas a partir de imagem em Base64 usando OCR integrada com ML Kit ou Cloud API
  static Future<List<String>> processOcrImage(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ocr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'mimeType': 'image/jpeg'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] != null) {
          return List<String>.from(data['items']);
        }
      }
    } catch (e) {
      debugPrint('Erro de rede no OCR da Lista: $e');
    }
    return [];
  }
}

// Tela Principal de Gerenciamento da Lista de Compras
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  final List<ShoppingItem> _items = [];
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsJsonStr = prefs.getString('mercadosmart_items');
    if (itemsJsonStr != null) {
      final List<dynamic> decodedList = jsonDecode(itemsJsonStr);
      setState(() {
        _items.clear();
        _items.addAll(decodedList.map((x) => ShoppingItem.fromJson(x)));
      });
    } else {
      // Inserir itens recomendados do protótipo PDF
      setState(() {
        _items.addAll([
          ShoppingItem(id: '1', name: 'Carne moída', sector: SectorType.ACOUGE),
          ShoppingItem(id: '2', name: 'Frango', sector: SectorType.ACOUGE),
          ShoppingItem(id: '3', name: 'Leite condensado', sector: SectorType.CONFEITARIA),
          ShoppingItem(id: '4', name: 'Pão', sector: SectorType.PADARIA),
          ShoppingItem(id: '5', name: 'Refrigerante', sector: SectorType.BEBIDAS),
          ShoppingItem(id: '6', name: 'Arroz', sector: SectorType.MERCEARIA, checked: true),
          ShoppingItem(id: '7', name: 'Feijão', sector: SectorType.MERCEARIA, checked: true),
        ]);
      });
    }
  }

  Future<void> _saveCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    final listJsonStr = jsonEncode(_items.map((x) => x.toJson()).toList());
    await prefs.setString('mercadosmart_items', listJsonStr);
  }

  // Adicionar item e classificar usando IA / Inventário em tempo real
  Future<void> _handleAddItem() async {
    final String query = _inputController.text.trim();
    if (query.isEmpty) return;

    _inputController.clear();
    setState(() {
      _isLoading = true;
      // Inserção otimista rápida
      _items.insert(0, ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: query,
        sector: SectorType.OUTROS,
      ));
    });

    // Buscar classificação na API inteligente
    final SectorType resolvedSector = await ApiService.classifyProduct(query);

    setState(() {
      _items[0].sector = resolvedSector;
      _isLoading = false;
    });
    _saveCurrentData();
  }

  // Deletar item individualmente
  void _deleteItem(String id) {
    setState(() {
      _items.removeWhere((x) => x.id == id);
    });
    _saveCurrentData();
  }

  // Modificar Status do Checkbox
  void _toggleChecked(String id) {
    setState(() {
      final idx = _items.indexWhere((x) => x.id == id);
      if (idx != -1) {
        _items[idx].checked = !_items[idx].checked;
      }
    });
    _saveCurrentData();
  }

  // Simular a captura ou leitura de lista manuscrita (Prótipo Page 4)
  void _simulatePhotoOcr() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.cyan),
                  SizedBox(width: 8),
                  Text(
                    'Reconhecimento OCR Inteligente',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tire foto de uma folha de papel com ingredientes escritos à mão para que nossa IA organize tudo instantaneamente em categorias!',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Colors.cyan),
                title: const Text('Carregar Lote Exemplo do Prototype (English)'),
                subtitle: const Text('Monster, Cokes, Yogurt, Pizza Bread...'),
                onTap: () {
                  Navigator.pop(ctx);
                  _importPresetItems([
                    'Yogurt Cups',
                    'Hummus',
                    'Pita Bread',
                    'Salami',
                    'Monster Energy',
                    'Cokes',
                    'Coconut Water',
                    'Granola Bars',
                    'Cake',
                    'Shampoo',
                    'Conditioner'
                  ]);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.cyan),
                title: const Text('Carregar Lote Nacional (Português)'),
                subtitle: const Text('Cerveja, Carne moída, Banana, Sabonete...'),
                onTap: () {
                  Navigator.pop(ctx);
                  _importPresetItems([
                    'Presunto cozido',
                    'Água com gás',
                    'Sabonete líquido',
                    'Cerveja lata',
                    'Banana prata',
                    'Detergente Ypê'
                  ]);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _importPresetItems(List<String> list) async {
    setState(() {
      _isLoading = true;
    });

    for (var rawName in list) {
      final sector = await ApiService.classifyProduct(rawName);
      setState(() {
        _items.insert(0, ShoppingItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: rawName,
          sector: sector,
        ));
      });
    }

    setState(() {
      _isLoading = false;
    });
    _saveCurrentData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sucesso! ${list.length} itens extraídos via OCR e auto-categorizados.'),
          backgroundColor: Colors.teal[800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.cyan[900],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MercadoSmart',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Sua lista inteligente',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Resetar padrões',
            onPressed: () {
              setState(() {
                _items.clear();
                _items.addAll([
                  ShoppingItem(id: '1', name: 'Carne moída', sector: SectorType.ACOUGE),
                  ShoppingItem(id: '2', name: 'Frango', sector: SectorType.ACOUGE),
                  ShoppingItem(id: '3', name: 'Leite condensado', sector: SectorType.CONFEITARIA),
                  ShoppingItem(id: '4', name: 'Pão', sector: SectorType.PADARIA),
                  ShoppingItem(id: '5', name: 'Refrigerante', sector: SectorType.BEBIDAS),
                  ShoppingItem(id: '6', name: 'Arroz', sector: SectorType.MERCEARIA, checked: true),
                  ShoppingItem(id: '7', name: 'Feijão', sector: SectorType.MERCEARIA, checked: true),
                ]);
              });
              _saveCurrentData();
            },
          )
        ],
      ),
      body: _currentIndex == 0 ? _buildHomeTab() : const MarketsListTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF164E63),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Mercados',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Banner de Identidade do App
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF164E63), Color(0xFF0891B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Text('🤖', style: TextStyle(fontSize: 18)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Classificação com IA ativa!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Qualquer item adicionado será alocado no setor correto automaticamente.',
                        style: TextStyle(color: Colors.white70, fontSize: 10.5),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Formulário de adição de item
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Adicionar item...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleAddItem(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _handleAddItem,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF164E63),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.add, color: Colors.white),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),

          // Lista de Compras Principal
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text(
                      'Sua lista está vazia!\nTente adicionar alimentos acima ou use o OCR.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final secColor = item.sector.color;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.15)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Checkbox(
                            value: item.checked,
                            activeColor: const Color(0xFF164E63),
                            onChanged: (_) => _toggleChecked(item.id),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: item.checked ? TextDecoration.lineThrough : null,
                              color: item.checked ? Colors.grey : const Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: secColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: secColor.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(item.sector.emoji, style: const TextStyle(fontSize: 10)),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.sector.label.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: secColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                            onPressed: () => _deleteItem(item.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Botões de Ações do Protótipo (Page 1 V2)
          Container(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Navegar para seleção de mercado passando os itens
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectMarketScreen(items: _items),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_basket, size: 16),
                  label: const Text('Iniciar compras no mercado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF164E63),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _simulatePhotoOcr,
                  icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF0891B2)),
                  label: const Text('Importar lista manuscrita via foto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ABA 2: LISTA DE MERCADOS E CONFIGURAÇÃO DE SETORES
class MarketsListTab extends StatefulWidget {
  const MarketsListTab({super.key});

  @override
  State<MarketsListTab> createState() => _MarketsListTabState();
}

class _MarketsListTabState extends State<MarketsListTab> {
  final List<Market> _markets = [];

  @override
  void initState() {
    super.initState();
    _loadMarkets();
  }

  Future<void> _loadMarkets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('mercadosmart_markets');
    if (jsonStr != null) {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      setState(() {
        _markets.clear();
        _markets.addAll(decoded.map((x) => Market.fromJson(x)));
      });
    } else {
      setState(() {
        _markets.addAll([
          Market(
            id: 'atacadao',
            name: 'Atacadão',
            sectionsOrder: [
              SectorType.HORTIFRUTI,
              SectorType.MERCEARIA,
              SectorType.ACOUGE,
              SectorType.BEBIDAS,
              SectorType.PADARIA,
              SectorType.CONFEITARIA,
              SectorType.LIMPEZA,
              SectorType.HIGIENE,
              SectorType.OUTROS
            ],
          ),
          Market(
            id: 'assai',
            name: 'Assaí',
            sectionsOrder: [
              SectorType.BEBIDAS,
              SectorType.CONFEITARIA,
              SectorType.ACOUGE,
              SectorType.PADARIA,
              SectorType.LIMPEZA,
              SectorType.HIGIENE,
              SectorType.HORTIFRUTI,
              SectorType.MERCEARIA,
              SectorType.OUTROS
            ],
          )
        ]);
      });
      _saveMarkets();
    }
  }

  Future<void> _saveMarkets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_markets.map((x) => x.toJson()).toList());
    await prefs.setString('mercadosmart_markets', jsonStr);
  }

  void _reorderSection(String marketId, SectorType sector, bool moveUp) {
    setState(() {
      final mIdx = _markets.indexWhere((x) => x.id == marketId);
      if (mIdx == -1) return;

      final List<SectorType> order = _markets[mIdx].sectionsOrder;
      final idx = order.indexOf(sector);
      if (idx == -1) return;

      final targetIdx = moveUp ? idx - 1 : idx + 1;
      if (targetIdx < 0 || targetIdx >= order.length) return;

      // Swap
      final temp = order[idx];
      order[idx] = order[targetIdx];
      order[targetIdx] = temp;
    });
    _saveMarkets();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _markets.length,
      itemBuilder: (context, mIndex) {
        final market = _markets[mIndex];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          market.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Total de ${market.sectionsOrder.length} setores ativados',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Icon(Icons.edit_road, color: Color(0xFF0891B2)),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'ORDEM DE PRIORIDADE DE CORREDORES (Arraste ou clique para mover):',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: market.sectionsOrder.length,
                  itemBuilder: (context, sIndex) {
                    final sec = market.sectionsOrder[sIndex];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(sec.emoji, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Text(
                                sec.label,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: sIndex == 0 ? null : () => _reorderSection(market.id, sec, true),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: sIndex == market.sectionsOrder.length - 1
                                    ? null
                                    : () => _reorderSection(market.id, sec, false),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// TELA DE SELEÇÃO DO MERCADO (Page 2 do PDF)
class SelectMarketScreen extends StatelessWidget {
  final List<ShoppingItem> items;
  const SelectMarketScreen({super.key, required this.items});

  Future<List<Market>> _getMarkets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('mercadosmart_markets');
    if (jsonStr != null) {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((x) => Market.fromJson(x)).toList();
    }
    return [
      Market(
        id: 'atacadao',
        name: 'Atacadão',
        sectionsOrder: [
          SectorType.HORTIFRUTI,
          SectorType.MERCEARIA,
          SectorType.ACOUGE,
          SectorType.BEBIDAS,
          SectorType.PADARIA,
          SectorType.CONFEITARIA,
          SectorType.LIMPEZA,
          SectorType.HIGIENE,
          SectorType.OUTROS
        ],
      ),
      Market(
        id: 'assai',
        name: 'Assaí',
        sectionsOrder: [
          SectorType.BEBIDAS,
          SectorType.CONFEITARIA,
          SectorType.ACOUGE,
          SectorType.PADARIA,
          SectorType.LIMPEZA,
          SectorType.HIGIENE,
          SectorType.HORTIFRUTI,
          SectorType.MERCEARIA,
          SectorType.OUTROS
        ],
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Selecionar Estabelecimento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Market>>(
        future: _getMarkets(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SELECIONAR MERCADO',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Escolha onde você vai fazer suas compras hoje para ordenar sua lista de acordo com os corredores físicos deste mercado:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final m = list[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.18)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ordem de Início: ${m.sectionsOrder.first.label} ➔ ${m.sectionsOrder[1].label}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  )
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ActiveRouteScreen(items: items, market: m),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF164E63),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Text('Iniciar '),
                                  Icon(Icons.arrow_forward, size: 14),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

// TELA ROTA ATIVA: COMPRAS SEM RETROCESSO (Page 3 do PDF)
class ActiveRouteScreen extends StatefulWidget {
  final List<ShoppingItem> items;
  final Market market;

  const ActiveRouteScreen({
    super.key,
    required this.items,
    required this.market,
  });

  @override
  State<ActiveRouteScreen> createState() => _ActiveRouteScreenState();
}

class _ActiveRouteScreenState extends State<ActiveRouteScreen> {
  late List<ShoppingItem> _localItems;

  @override
  void initState() {
    super.initState();
    _localItems = List.from(widget.items);
  }

  void _toggleChecked(String id) {
    setState(() {
      final idx = _localItems.indexWhere((x) => x.id == id);
      if (idx != -1) {
        _localItems[idx].checked = !_localItems[idx].checked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar produtos pelas categorias na ordem configurada do mercado
    final grouped = <SectorType, List<ShoppingItem>>{};
    for (var sec in widget.market.sectionsOrder) {
      final matches = _localItems.where((x) => x.sector == sec).toList();
      if (matches.isNotEmpty) {
        grouped[sec] = matches;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Percurso: ${widget.market.name}'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Indicador de Progresso Geral da Compra
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ITINERÁRIO ATIVO',
                        style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                      Text(
                        'Minimizando percursos redundantes',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_localItems.where((x) => x.checked).length}/${_localItems.length} comprados',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grupos baseados nas seções em ordem física de corredor
            Expanded(
              child: grouped.isEmpty
                  ? const Center(
                      child: Text('Nenhum item adicionado para este trajeto.'),
                    )
                  : ListView.builder(
                      itemCount: grouped.keys.length,
                      itemBuilder: (context, index) {
                        final sec = grouped.keys.elementAt(index);
                        final list = grouped[sec]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Banner da Seção / Corredor
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: sec.color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${sec.emoji} ${sec.label.toUpperCase()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ),
                            // Lista de compras compacta
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withOpacity(0.15)),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: list.length,
                                itemBuilder: (ctx, i) {
                                  final item = list[i];
                                  return CheckboxListTile(
                                    value: item.checked,
                                    title: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        decoration: item.checked ? TextDecoration.lineThrough : null,
                                        color: item.checked ? Colors.grey : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    activeColor: const Color(0xFF164E63),
                                    onChanged: (_) => _toggleChecked(item.id),
                                    controlAffinity: ListTileControlAffinity.leading,
                                  );
                                },
                              ),
                            )
                          ],
                        );
                      },
                    ),
            ),

            if (_localItems.isNotEmpty && _localItems.every((x) => x.checked))
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.teal),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Excelente! Todas as compras da lista foram adquiridas na ordem ideal sem voltar atrás.',
                        style: TextStyle(fontSize: 12, color: Colors.teal),
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
