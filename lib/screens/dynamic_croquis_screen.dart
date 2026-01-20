import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DynamicCroquisScreen extends StatefulWidget {
  final int salaId;
  final String salaNombre;
  final int idSede; // Added idSede

  const DynamicCroquisScreen({
    Key? key,
    required this.salaId,
    required this.salaNombre,
    required this.idSede,
  }) : super(key: key);

  @override
  State<DynamicCroquisScreen> createState() => _DynamicCroquisScreenState();
}

class _DynamicCroquisScreenState extends State<DynamicCroquisScreen> {
  final ApiService _api = ApiService();
  List<dynamic> escritorios = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      // FIX: The endpoint listarEscritoriosPorSala returns 500.
      // Fallback: Fetch all from Sede and filter locally.
      final allEscritorios = await _api.listarEscritoriosPorSede(widget.idSede);
      
      // Filter for this room
      final escritoriosData = allEscritorios.where((e) {
        final sId = e['sala_id'] ?? e['id_sala']; // Check standard keys
        return sId.toString() == widget.salaId.toString();
      }).toList();
      
      // Sort: Alpha-numeric sort approximation
      escritoriosData.sort((a, b) {
        final codA = (a['codigo'] ?? '').toString();
        final codB = (b['codigo'] ?? '').toString();
        return codA.compareTo(codB);
      });

      if (mounted) {
        setState(() {
          escritorios = escritoriosData;
          isLoading = false;
        });
      }
    } catch (e) {
      print("[DynamicCroquis] Error loading data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // backgroundColor: theme.scaffoldBackgroundColor, // Handled by theme
      appBar: AppBar(
        title: Text("Croquis: ${widget.salaNombre}"),
        centerTitle: true,
        // backgroundColor: theme.appBarTheme.backgroundColor, // Handled by theme
        // iconTheme: theme.appBarTheme.iconTheme, // Handled by theme
        elevation: 0,
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.scaffoldBackgroundColor, // Match page bg
            child: TextField(
              onChanged: (val) {
                setState(() {
                  searchQuery = val.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Buscar docente...",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                ),
              ),
            ),
          ),
          
          // GRID
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
                : escritorios.isEmpty
                    ? _buildEmptyState()
                    : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No hay escritorios registrados en esta sala.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (widget.salaNombre.toUpperCase().contains("INGAPIRCA")) {
      return _buildIngapircaGrid();
    } else {
      return _buildLloretBastidasGrid();
    }
  }

  Widget _buildIngapircaGrid() {
     // 1. Filter Data
     List<dynamic> coords = [];
     List<dynamic> desks = [];

     dynamic coordModas;
     dynamic coordIngles;
     dynamic coordCulinario;
     dynamic coordAtencion; // Treat as coord for positioning

     for (var desk in escritorios) {
        String code = (desk['codigo'] ?? "").toString().toUpperCase();
        if (code.contains("COORD") || code.contains("MODAS") || code.contains("INGLES") || code.contains("CULINARIO") || code.contains("ATENCION")) {
            if (code.contains("MODAS")) coordModas = desk;
            else if (code.contains("INGLES")) coordIngles = desk;
            else if (code.contains("CULINARIO")) coordCulinario = desk;
            else if (code.contains("ATENCION")) coordAtencion = desk;
            else coords.add(desk); // Fallback
        } else {
            desks.add(desk);
        }
     }

     return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(1000), 
      minScale: 0.1,
      maxScale: 4.0,
      constrained: false,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor, 
        padding: const EdgeInsets.all(200),
        child: CustomPaint(
          foregroundPainter: GridPainter(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // 1. LEFT COLUMN (Coordinators)
               Column(
                 mainAxisAlignment: MainAxisAlignment.start,
                 crossAxisAlignment: CrossAxisAlignment.end, // Align right to face main grid?
                 children: [
                    // Top Group: Modas + Culinario
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         // Modas (Vertical)
                         if (coordModas != null) _buildVerticalDesk(coordModas, "Coord.\nModas")
                         else _buildVerticalDesk(null, "Coord.\nModas", isEmptyPlaceholder: true),
                         
                         const SizedBox(width: 40),

                         // Culinario (Vertical? Or Rotated 180?)
                         // Image shows Culinario text upside down relative to Modas? 
                         // Let's assume standard vertical for now.
                         if (coordCulinario != null) _buildVerticalDesk(coordCulinario, "Coord.\nArte Culinario")
                         else _buildVerticalDesk(null, "Coord.\nArte Culinario", isEmptyPlaceholder: true),
                      ],
                    ),

                    const SizedBox(height: 150), // Gap

                    // Bottom Group: Ingles + Atencion
                    Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          if (coordIngles != null) _buildVerticalDesk(coordIngles, "Coord.\nInglés")
                          else _buildVerticalDesk(null, "Coord.\nInglés", isEmptyPlaceholder: true),

                          const SizedBox(width: 40),

                          if (coordAtencion != null) _buildVerticalDesk(coordAtencion, "Atención")
                          else _buildVerticalDesk(null, "Atención", isEmptyPlaceholder: true),
                       ],
                    )
                 ],
               ),

               const SizedBox(width: 150), // Gap to Main Grid

               // 2. MAIN GRID (2 Long Rows of Pairs)
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    // TOP ROW (22, 25-40)
                    // Visual from image: 22(bottom slot), gap, 25/26 ...
                    // Wait, standard pair function: Top odd, Bottom even?
                    // Let's look at 25/26: 25 is Top, 26 Bottom.
                    // 22: Single.
                    Row(
                      children: [
                         // 22 Block (Special)
                         Column(
                           children: [
                             _buildWoodenDesk(null, isLeft: true, isEmptyPlaceholder: true), // 21? Empty
                             const SizedBox(height: 8),
                             _buildDeskByNumber(desks, 22, "", isLeft: false), // 22 (Left or Right? Image shows vertical pair logic)
                           ],
                         ),
                         const SizedBox(width: 60),

                         // 25 - 40
                         // Pairs: (25,26), (27,28)...(39,40)
                         ...List.generate(8, (index) {
                            int topNum = 25 + (index * 2); // 25, 27, 29...
                            int botNum = topNum + 1;       // 26, 28, 30...
                            return Padding(
                              padding: const EdgeInsets.only(right: 60),
                              child: _buildVerticalPair(desks, topNum, botNum),
                            );
                         }),
                      ],
                    ),

                    const SizedBox(height: 100), // Aisle

                    // BOTTOM ROW (1-20)
                    // Pairs: (1,2), (3,4)...(19,20)
                    Row(
                      children: [
                        ...List.generate(10, (index) {
                            int topNum = 1 + (index * 2); // 1, 3, 5...
                            int botNum = topNum + 1;      // 2, 4, 6...
                            return Padding(
                              padding: const EdgeInsets.only(right: 60),
                              child: _buildVerticalPair(desks, topNum, botNum),
                            );
                        }),
                      ],
                    )
                 ],
               )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalPair(List<dynamic> desks, int topNum, int botNum) {
      return Column(
        children: [
           _buildDeskByNumber(desks, topNum, "", isLeft: true),
           const SizedBox(height: 8),
           _buildDeskByNumber(desks, botNum, "", isLeft: false), // False for visual variety or consistency?
           // In previous VerticalDesk, isLeft=true. 
           // In pairs (Top/Bottom), usually they face same way or opposite?
           // Image: Standard desks. Drawers seem to be all on left or all on right?
           // Image low res, let's assume standard left.
           // Actually let's replicate standard block look:
           // Top desk, Bottom desk.
        ],
      );
  }

  Widget _buildLloretBastidasGrid() {
    // 1. Buckets for Everything
    List<dynamic> coordTurismo = [];
    List<dynamic> coordMarketing = [];
    List<dynamic> coordDesarrollo = [];
    List<dynamic> ambiguousCoords = [];
    
    List<dynamic> desksT = [];
    List<dynamic> desksDS = [];
    List<dynamic> desksMD = [];

    // 2. Strict Sorting Hat
    for (var desk in escritorios) {
      String codigo = (desk['codigo'] ?? "").toString().toUpperCase().trim();
      
      // IS COORDINATOR?
      if (codigo.contains("COORD") || codigo.startsWith("C.")) {
         if (codigo.contains("TURISMO") || codigo.contains(" T ")) {
           coordTurismo.add(desk);
         } else if (codigo.contains("MARKETING") || codigo.contains("MKT") || codigo.contains("DIGITAL") || codigo.contains("M-D") || codigo.contains("MD")) {
           coordMarketing.add(desk);
         } else if (codigo.contains("DESARROLLO") || codigo.contains("SOFTWARE") || codigo.contains("D-S") || codigo.contains("DS")) {
           coordDesarrollo.add(desk);
         } else {
           ambiguousCoords.add(desk);
         }
         continue; 
      }

      // IS NORMAL DESK?
      if (codigo.contains("D-S") || codigo.contains("D.S") || codigo.contains("DS") || codigo.contains("SOFTWARE") || codigo.contains("DESARROLLO")) {
          desksDS.add(desk);
      } else if (codigo.contains("M-D") || codigo.contains("M.D") || codigo.contains("MD") || codigo.contains("MARKETING")) {
          desksMD.add(desk);
      } else if (codigo.contains("T.") || codigo.contains("T-") || codigo.startsWith("T") || codigo.contains("TURISMO")) {
          desksT.add(desk);
      } else {
          desksDS.add(desk); // Default safety
      }
    }

    // 3. Smart Assign Ambiguous Coordinators
    for (var aCoord in ambiguousCoords) {
        if (coordMarketing.isEmpty) {
            coordMarketing.add(aCoord);
        } else if (coordDesarrollo.isEmpty) {
            coordDesarrollo.add(aCoord);
        } else if (coordTurismo.isEmpty) {
            coordTurismo.add(aCoord); 
        } else {
            coordMarketing.add(aCoord);
        }
    }

    if (coordMarketing.isEmpty && coordDesarrollo.length > 1) {
        coordMarketing.add(coordDesarrollo.removeLast());
    } else if (coordDesarrollo.isEmpty && coordMarketing.length > 1) {
        coordDesarrollo.add(coordMarketing.removeLast());
    }

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(1000), 
      minScale: 0.1,
      maxScale: 4.0,
      constrained: false, 
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor, 
        padding: const EdgeInsets.fromLTRB(200, 200, 400, 200), 
        child: CustomPaint(
          foregroundPainter: GridPainter(), 
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end, 
            children: [
               
               // SECTION 1: TURISMO
               Padding(
                 padding: const EdgeInsets.only(right: 180),
                 child: _buildSection("T", desksT, 
                    leftCoord: coordTurismo.isNotEmpty ? coordTurismo.first : null
                 ),
               ),

               // SECTION 2: DESARROLLO DE SOFTWARE
               Padding(
                 padding: const EdgeInsets.only(right: 180),
                 child: _buildSection("D-S", desksDS),
               ),

               // SECTION 3: MARKETING
               Padding(
                 padding: const EdgeInsets.only(right: 0),
                 child: _buildSection("M-D", desksMD,
                    rightTopCoord: coordMarketing.isNotEmpty ? coordMarketing.first : null,
                    rightBottomCoord: coordDesarrollo.isNotEmpty ? coordDesarrollo.first : null
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDesk(dynamic desk, String label, {bool isEmptyPlaceholder = false}) {
     return Column(
       mainAxisSize: MainAxisSize.min,
       children: [
         RotatedBox(
           quarterTurns: 1, // Vertical
           child: _buildWoodenDesk(desk, isLeft: true, isEmptyPlaceholder: isEmptyPlaceholder),
         ),
         const SizedBox(height: 8),
         Text(
            label,
            style: const TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: Colors.grey
            ),
            textAlign: TextAlign.center,
         )
       ],
     );
  }

  Widget _buildSection(String title, List<dynamic> desks, {
    dynamic leftCoord,
    dynamic rightTopCoord,
    dynamic rightBottomCoord,
    bool showTitle = true
  }) {
    // Determine Ranges based on Title Prefix (Literal per Image)
    int lowStart = 0, lowEnd = 0;
    int highStart = 0, highEnd = 0;

    if (title == "T") {
      lowStart = 1; lowEnd = 4;
      highStart = 21; highEnd = 24;
    } else if (title.contains("D-S") || title == "D-S") {
      lowStart = 5; lowEnd = 12;
      highStart = 25; highEnd = 32;
    } else if (title.contains("M-D") || title == "M-D") {
      lowStart = 13; lowEnd = 20;
      highStart = 33; highEnd = 40;
    } else {
       // Fallback
       return Column(children:[_buildRowOfBlocks(desks)]);
    }

    return Row( // Wrap whole section in Row to accommodate Left Align
      crossAxisAlignment: CrossAxisAlignment.end, // Align T Coord with bottom?
      children: [
        // LEFT ACCESSORY (Turismo Coord)
        // Show if explicitly passed OR if this is "T" section (forcing literal layout)
        if (title == "T")
          Padding(
            padding: const EdgeInsets.only(right: 40, bottom: 20), // Gap and alignment
            child: _buildVerticalDesk(leftCoord, "Coord.\nTurismo", isEmptyPlaceholder: leftCoord == null),
          ),

        // MAIN COLUMN
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            // Top Row (High Numbers)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStrictRow(desks, highStart, highEnd, title),
                // RIGHT TOP ACCESSORY (Marketing Coord)
                if (title == "M-D")
                   Padding(
                     padding: const EdgeInsets.only(left: 40),
                     child: _buildVerticalDesk(rightTopCoord, "Coord.\nMarketing", isEmptyPlaceholder: rightTopCoord == null),
                   ),
              ],
            ),
            
            // Aisle Gap
            const SizedBox(height: 80), 

            // Bottom Row (Low Numbers)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStrictRow(desks, lowStart, lowEnd, title),
                // RIGHT BOTTOM ACCESSORY (Desarrollo Coord)
                if (title == "M-D")
                   Padding(
                     padding: const EdgeInsets.only(left: 40),
                     child: _buildVerticalDesk(rightBottomCoord, "Coord.\nDesarrollo", isEmptyPlaceholder: rightBottomCoord == null),
                   ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStrictRow(List<dynamic> sourceDesks, int startNum, int endNum, String prefix) {
      List<Widget> blocks = [];
      // Step: 4 desks per block
      for (int i = startNum; i <= endNum; i += 4) {
          blocks.add(_buildStrictBlock(sourceDesks, i, prefix));
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks.map((b) => Padding(
          padding: const EdgeInsets.only(right: 60), 
          child: b,
        )).toList(),
      );
  }

  Widget _buildStrictBlock(List<dynamic> sourceDesks, int startSeed, String prefix) {
      // 2x2 Layout:
      // [n]   [n+2]
      // [n+1] [n+3]
      // Example T: [21] [23]
      //            [22] [24]
      
      final n = startSeed;
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
               _buildDeskByNumber(sourceDesks, n, prefix, isLeft: true),
               const SizedBox(width: 8),
               _buildDeskByNumber(sourceDesks, n + 2, prefix, isLeft: false),
            ],
          ),
          const SizedBox(height: 12),
          Row(
             children: [
               _buildDeskByNumber(sourceDesks, n + 1, prefix, isLeft: true),
               const SizedBox(width: 8),
               _buildDeskByNumber(sourceDesks, n + 3, prefix, isLeft: false),
             ],
          )
        ],
      );
  }

  Widget _buildDeskByNumber(List<dynamic> desks, int targetNum, String prefix, {required bool isLeft}) {
      // Find exact desk match
      final match = desks.firstWhere((d) {
         String c = d['codigo'].toString().trim().toUpperCase(); 
         // c examples: "D-S.25", "D.S.25", "D-S 25", "T.1"
         
         // Strategy 1: Split by non-digits, take last segment
         final parts = c.split(RegExp(r'[^0-9]+'));
         // parts for D-S.25 -> [D, S, 25] (if split by dot) relative.
         // Actually regex [^0-9]+ splits "D-S.25" -> ["", "25"] or similar.
         
         int num = -1;
         if (parts.isNotEmpty) {
           // Iterate backwards to find first valid number
           for (var p in parts.reversed) {
             final pNum = int.tryParse(p);
             if (pNum != null) {
               num = pNum;
               break;
             }
           }
         }
         
         return num == targetNum;
      }, orElse: () => null);

      if (match != null) {
          return _buildWoodenDesk(match, isLeft: isLeft);
      } else {
          // Empty Placeholder
          return _buildWoodenDesk(null, isLeft: isLeft, isEmptyPlaceholder: true);
      }
  }

  // Legacy fallback for unknown sections
  Widget _buildRowOfBlocks(List<dynamic> desks) {
    List<Widget> blocks = [];
    for (int i = 0; i < desks.length; i += 4) {
      final end = (i + 4 < desks.length) ? i + 4 : desks.length;
      final chunk = desks.sublist(i, end);
      blocks.add(_buildBlockOf4(chunk));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((b) => Padding(
        padding: const EdgeInsets.only(right: 60), 
        child: b,
      )).toList(),
    );
  }

  Widget _buildBlockOf4(List<dynamic> chunk) {
    // 2x2 Transpose Logic (Column-Major Filling)
    // Input sorted: 1, 2, 3, 4
    // Visual Target:
    // [1] [3]
    // [2] [4]
    
    // Indices in Chunk:
    // TL: 0
    // BL: 1
    // TR: 2
    // BR: 3

    dynamic tl = chunk.isNotEmpty ? chunk[0] : null;
    dynamic bl = chunk.length > 1 ? chunk[1] : null;
    dynamic tr = chunk.length > 2 ? chunk[2] : null;
    dynamic br = chunk.length > 3 ? chunk[3] : null;

    // Row 1: TL + TR
    // Row 2: BL + BR

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Sub-Row
        Row(
          children: [
             (tl != null) ? _buildWoodenDesk(tl, isLeft: true) : _buildWoodenDesk(null, isLeft: true, isEmptyPlaceholder: true),
             const SizedBox(width: 8), // Pair Gap
             (tr != null) ? _buildWoodenDesk(tr, isLeft: false) : _buildWoodenDesk(null, isLeft: false, isEmptyPlaceholder: true),
          ],
        ),
        const SizedBox(height: 12), // Vertical gap in block
        // Bottom Sub-Row
        Row(
          children: [
             (bl != null) ? _buildWoodenDesk(bl, isLeft: true) : _buildWoodenDesk(null, isLeft: true, isEmptyPlaceholder: true),
             const SizedBox(width: 8),
             (br != null) ? _buildWoodenDesk(br, isLeft: false) : _buildWoodenDesk(null, isLeft: false, isEmptyPlaceholder: true),
          ],
        ),
      ],
    );
  }

  Widget _buildWoodenDesk(dynamic desk, {bool isLeft = true, bool isEmptyPlaceholder = false}) {
    // Extract Data
    final String codigo = desk != null ? (desk['codigo']?.toString() ?? "S/C") : "";
    final String? docente = desk != null ? (desk['docente_nombre'] ?? desk['docente']?['nombres'] ?? desk['docente']?['nombre']) : null; 
    final String? apellido = desk != null ? (desk['docente_apellido'] ?? desk['docente']?['apellidos'] ?? desk['docente']?['apellido']) : null;
    
    String nombreDocente = "";
    if (docente != null || apellido != null) {
      nombreDocente = "${docente ?? ''} ${apellido ?? ''}".trim();
    }
    
    final String estado = desk != null ? (desk['estado'] ?? "LIBRE") : "LIBRE";
    final bool isOccupied = estado.toUpperCase() != "LIBRE" && !isEmptyPlaceholder;
    
    bool isMatch = false;
    bool isDimmed = false;
    if (searchQuery.isNotEmpty && !isEmptyPlaceholder && desk != null) {
      if (nombreDocente.toLowerCase().contains(searchQuery)) {
        isMatch = true;
      } else {
        isDimmed = true;
      }
    }

    // COLORS (Literal Wood)
    final Color woodMain = isMatch ? const Color(0xFFFFD54F) : const Color(0xFFD7CCC8); // Lighter wood for surface
    final Color woodDrawer = isMatch ? const Color(0xFFFF6F00) : const Color(0xFF8D6E63); // Darker wood for drawer
    final Color woodBorder = const Color(0xFF4E342E); // Darker brown
    
    // Shadows
    final BoxShadow shadow = isMatch 
        ? BoxShadow(color: Colors.orangeAccent.withOpacity(0.6), blurRadius: 15, spreadRadius: 2)
        : BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(2, 3));

    // DIMENSIONS
    const double width = 140;
    const double height = 80;
    
    return Transform.scale(
      scale: isMatch ? 1.15 : 1.0,
      child: Opacity(
        opacity: isDimmed ? 0.3 : (isEmptyPlaceholder ? 0.5 : 1.0), // Faded if just a placeholder
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6), // Rounded for style
            boxShadow: isEmptyPlaceholder ? [] : [shadow], // No shadow for empty placeholder? Or yes? User said "vacios"
            // Let's keep shadow but maybe lighter.
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              textDirection: isLeft ? TextDirection.ltr : TextDirection.rtl, 
              children: [
                 // DRAWER UNIT
                 Container(
                   width: 38,
                   height: height,
                   decoration: BoxDecoration(
                     color: woodDrawer,
                     border: Border(
                       right: isLeft ? BorderSide(color: woodBorder, width: 1) : BorderSide.none,
                       left: !isLeft ? BorderSide(color: woodBorder, width: 1) : BorderSide.none,
                     ),
                   ),
                   child: Column( // Drawer handles
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: List.generate(3, (index) => 
                       Container(
                         height: 2, 
                         width: 16, 
                         color: woodBorder.withOpacity(0.6),
                         margin: const EdgeInsets.symmetric(horizontal: 8),
                       )
                     ),
                   ),
                 ),
                 
                 // DESK SURFACE
                 Expanded(
                   child: Container(
                     color: woodMain,
                     child: Stack(
                       children: [
                         // Surface Texture/Border detail
                         Positioned.fill(
                           child: Container(
                             decoration: BoxDecoration(
                               border: Border.all(color: woodBorder.withOpacity(0.3), width: 1),
                               gradient: LinearGradient(
                                 begin: Alignment.topLeft,
                                 end: Alignment.bottomRight,
                                 colors: [
                                   Colors.white.withOpacity(0.1),
                                   Colors.black.withOpacity(0.05),
                                 ]
                               )
                             ),
                           ),
                         ),
                         
                         // Code Number (Only if not placeholder)
                         if (!isEmptyPlaceholder)
                         Center(
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.5),
                               borderRadius: BorderRadius.circular(4),
                             ),
                             child: Text(
                               codigo,
                               style: TextStyle(
                                 fontSize: 18,
                                 fontWeight: FontWeight.bold,
                                 color: woodBorder,
                                 letterSpacing: 1,
                               ),
                             ),
                           ),
                         ),
                         
                         // Occupied Indicator
                         if (isOccupied)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                nombreDocente,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9, 
                                  fontWeight: FontWeight.w600,
                                  color: woodBorder,
                                ),
                              ),
                            )
                          ),
                       ],
                     ),
                   ),
                 )
              ],
            ),
          ),
        ),
      ),
    );
  }


}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.08)
      ..strokeWidth = 1;

    const double gridSize = 60; // Bigger grid for architect feel

    // Draw grid far beyond visible area roughly
    // Or dynamic based on size. size here is infinite in InteractiveViewer child?
    // Actually the child has a size. 
    // We'll just draw a grid covering the `size` passed which matches the Container size.
    
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
