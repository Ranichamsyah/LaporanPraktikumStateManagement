// Import library yang diperlukan untuk membuat aplikasi Flutter dan melakukan HTTP request
import 'package:flutter/material.dart'; // Paket yang menyediakan berbagai widget dan alat UI untuk membangun aplikasi Flutter
import 'package:http/http.dart' as http; // Paket untuk melakukan HTTP request
import 'dart:convert'; // Paket untuk mengonversi data dari dan ke format JSON
import 'package:provider/provider.dart'; // Paket untuk mengelola state aplikasi

// Class untuk merepresentasikan data universitas
class University {
  final String name;
  final String website;

  University({required this.name, required this.website});

  // Factory method untuk membuat instance University dari JSON
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: json['web_pages'][0], // Ambil website pertama dari list
    );
  }
}

// Kelas untuk mengelola data universitas dengan menggunakan ChangeNotifier
class UniversityData extends ChangeNotifier {
  late List<University> _universities;

  UniversityData() {
    _universities = [];
    fetchUniversityData("Indonesia"); // Memanggil fungsi untuk mengambil data universitas
  }

  // Getter untuk mendapatkan daftar universitas
  List<University> get universities => _universities;

  // Fungsi untuk mengambil data universitas dari API
  Future<void> fetchUniversityData(String country) async {
    final response = await http.get(Uri.parse('http://universities.hipolabs.com/search?country=$country'));
    if (response.statusCode == 200) {
      // Jika HTTP request berhasil, decode JSON dan kembalikan datanya
      List<dynamic> data = json.decode(response.body);
      _universities = data.map((json) => University.fromJson(json)).toList();
      notifyListeners(); // Memberitahu listener bahwa data telah diperbarui
    } else {
      // Jika gagal, lemparkan Exception
      throw Exception('Failed to load university data');
    }
  }
}

// Kelas MyApp adalah widget utama dari aplikasi
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChangeNotifierProvider(
        create: (context) => UniversityData(), // Membuat instance UniversityData dan menyediakannya ke dalam widget-tree
        child: UniversityList(),
      ),
    );
  }
}

// Kelas UniversityList adalah StatefulWidget yang akan menangani perubahan status dalam aplikasi
class UniversityList extends StatefulWidget {
  @override
  _UniversityListState createState() => _UniversityListState();
}

// Kelas _UniversityListState adalah State dari widget UniversityList
class _UniversityListState extends State<UniversityList> {
  late String _selectedCountry; // Variabel untuk menyimpan negara yang dipilih
  late UniversityData _universityData; // Variabel untuk mengelola data universitas

  // Override method initState() dari State untuk melakukan inisialisasi state
  @override
  void initState() {
    super.initState();
    _selectedCountry = "Indonesia"; // Set negara awal menjadi Indonesia
    _universityData = Provider.of<UniversityData>(context, listen: false); // Mengambil instance UniversityData dari Provider
    _universityData.fetchUniversityData(_selectedCountry); // Memanggil fungsi untuk mengambil data universitas
  }

  // Override method build() untuk merender tampilan widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('University List'),
        actions: [
          // Widget DropdownButton untuk memilih negara
          DropdownButton<String>(
            value: _selectedCountry,
            items: <String>['Indonesia', 'Malaysia', 'Singapore', 'Thailand', 'Vietnam']
                .map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                // Saat negara dipilih, update state dan ambil data universitas baru
                setState(() {
                  _selectedCountry = newValue;
                });
                _universityData.fetchUniversityData(newValue);
              }
            },
          ),
        ],
      ),
      body: Consumer<UniversityData>(
        // Widget Consumer untuk berlangganan perubahan state UniversityData
        builder: (context, universityData, child) {
          return universityData.universities.isEmpty
              ? Center(child: CircularProgressIndicator()) // Tampilkan loading spinner jika data belum tersedia
              : ListView.builder(
                  itemCount: universityData.universities.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(universityData.universities[index].name),
                      subtitle: Text(universityData.universities[index].website),
                    );
                  },
                );
        },
      ),
    );
  }
}

// Fungsi utama yang dipanggil saat aplikasi dimulai
void main() {
  runApp(MyApp());
}
