import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';

// Fungsi utama yang dipanggil saat aplikasi dimulai
void main() {
  // Menjalankan aplikasi Flutter dengan widget MyApp sebagai root widget
  runApp(MyApp());
}

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

// Class untuk mengelola state aplikasi dengan menggunakan Cubit
class UniversityCubit extends Cubit<List<University>> {
  UniversityCubit() : super([]);

  // Fungsi untuk mengambil data universitas dari API berdasarkan negara
  Future<void> fetchUniversityData(String country) async {
    final response = await http.get(Uri.parse('http://universities.hipolabs.com/search?country=$country'));
    if (response.statusCode == 200) {
      // Jika HTTP request berhasil, decode JSON dan kirimkan data ke state
      List<dynamic> data = json.decode(response.body);
      List<University> universities = data.map((json) => University.fromJson(json)).toList();
      emit(universities);
    } else {
      // Jika gagal, lemparkan Exception
      throw Exception('Failed to load university data');
    }
  }
}

// Kelas MyApp adalah widget utama dari aplikasi
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {  // Method build digunakan untuk merender tampilan aplikasi
    return MaterialApp(
      title: 'University List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (context) => UniversityCubit(), // Membuat instance UniversityCubit dan menyediakannya ke dalam widget-tree
        child: UniversityList(),
      ),
    );
  }
}

// Kelas UniversityList adalah StatefulWidget yang akan menangani perubahan status dalam aplikasi
class UniversityList extends StatefulWidget {
  @override
  // Method createState() digunakan untuk membuat instance dari _UniversityListState
  _UniversityListState createState() => _UniversityListState();
}

// Kelas _UniversityListState adalah State dari widget UniversityList
class _UniversityListState extends State<UniversityList> {
  late UniversityCubit _universityCubit; // Variabel untuk mengelola state aplikasi
  late String _selectedCountry; // Variabel untuk menyimpan negara yang dipilih

  @override
  void initState() {
    super.initState();
    _selectedCountry = "Indonesia"; // Set negara awal menjadi Indonesia
    _universityCubit = BlocProvider.of<UniversityCubit>(context); // Mengambil instance UniversityCubit dari Provider
    _universityCubit.fetchUniversityData(_selectedCountry); // Memanggil fungsi untuk mengambil data universitas
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
                _universityCubit.fetchUniversityData(newValue);
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<UniversityCubit, List<University>>( // Menggunakan BlocBuilder untuk membangun widget sesuai dengan state dari UniversityCubit
        builder: (context, universityList) { // Parameter builder menerima konteks dan data universityList yang merupakan List<University> dari state UniversityCubit
//     return universityList.isEmpty // Mengecek apakah universityList kosong
          return universityList.isEmpty
              ? Center(child: CircularProgressIndicator()) // Tampilkan loading spinner jika data belum tersedia
              : ListView.builder(
                  itemCount: universityList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(universityList[index].name),
                      subtitle: Text(universityList[index].website),
                    );
                  },
                );
        },
      ),
    );
  }
}
