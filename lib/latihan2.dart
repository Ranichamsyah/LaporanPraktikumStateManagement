import 'dart:convert'; //Impor pustaka dart:convert untuk mengonversi data JSON.
import 'package:flutter/material.dart';// Impor pustaka flutter untuk membangun antarmuka pengguna.
import 'package:http/http.dart' as http; // Impor pustaka http dari package http dengan alias http.
import 'package:flutter_bloc/flutter_bloc.dart'; // Impor flutter_bloc untuk manajemen state.

void main() { //Fungsi utama yang dipanggil saat aplikasi dijalankan.
  runApp(MyApp());
}

class University { //Deklarasi kelas University untuk merepresentasikan entitas universitas.
  final String name;
  final List<String> website;

  University({required this.name, required this.website});

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      name: json['name'],
      website: List<String>.from(json['web_pages']),
    );
  }
}

abstract class DataEvent {}

class SelectCountryEvent extends DataEvent { // Deklarasi kelas SelectCountryEvent untuk event memilih negara.
  final String country; 
  SelectCountryEvent(this.country); 
}

class FetchUniversitiesEvent extends DataEvent { // Deklarasi kelas FetchUniversitiesEvent untuk event mengambil data universitas.
  final String country; 
  FetchUniversitiesEvent(this.country); 
}

class UniversityState { // Deklarasi kelas UniversityState untuk menyimpan state aplikasi universitas.
  final List<University> universities; // Properti untuk menyimpan daftar universitas.
  final bool isLoading; // Properti untuk menunjukkan apakah aplikasi sedang memuat.
  final String error; // Properti untuk menyimpan pesan kesalahan.
  final String selectedCountry; // Properti untuk menyimpan negara yang dipilih.

  UniversityState({ // Konstruktor dengan nilai default.
    this.universities = const [], // Nilai default daftar universitas kosong.
    this.isLoading = false, // Nilai default isLoading false.
    this.error = '', 
    this.selectedCountry = 'Indonesia', 
  });

  UniversityState copyWith({ // Metode untuk menggandakan objek state dengan perubahan tertentu.
    List<University>? universities,
    bool? isLoading,
    String? error,
    String? selectedCountry,
  }) {
    return UniversityState(
      universities: universities ?? this.universities,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedCountry: selectedCountry ?? this.selectedCountry,
    );
  }
}

class UniversityBloc extends Bloc<DataEvent, UniversityState> { // Deklarasi kelas UniversityBloc untuk manajemen state aplikasi.
  UniversityBloc() : super(UniversityState()) { // Konstruktor dengan state awal UniversityState().
    // Event handler untuk memilih negara
    on<SelectCountryEvent>((event, emit) { // Event handler untuk event memilih negara.
      emit(state.copyWith(selectedCountry: event.country)); // Mengirim state baru dengan negara yang dipilih.
      add(FetchUniversitiesEvent(event.country)); // Memicu event untuk mengambil data universitas berdasarkan negara yang dipilih.
    });

    // Event handler untuk mengambil data universitas
    on<FetchUniversitiesEvent>((event, emit) async { 
      emit(state.copyWith(isLoading: true)); 
      try {
        final response = await http.get(Uri.parse(
            'http://universities.hipolabs.com/search?country=${event.country}')); // Mengambil data dari API berdasarkan negara.
        if (response.statusCode == 200) { // Jika permintaan berhasil.
          List jsonResponse = json.decode(response.body); // Mendekode data JSON.
          List<University> universities =
              jsonResponse.map((univ) => University.fromJson(univ)).toList(); // Mengonversi JSON ke objek University.
          emit(state.copyWith(
            universities: universities, 
            isLoading: false, 
            error: '', // Menghapus pesan kesalahan.
          ));
        } else { // Jika permintaan gagal.
          emit(state.copyWith(
            error: 'Failed to load universities', // Mengirim state baru dengan pesan kesalahan.
            isLoading: false, // isLoading menjadi false karena gagal memuat.
          ));
        }
      } catch (e) { // Penanganan kesalahan jika gagal mengambil data.
        emit(state.copyWith(
          error: 'Failed to load universities', // Mengirim state baru dengan pesan kesalahan.
          isLoading: false, // isLoading menjadi false karena gagal memuat.
        ));
      }
    });
  }
}

class MyApp extends StatelessWidget { // Deklarasi kelas MyApp sebagai root widget aplikasi.
  @override
  Widget build(BuildContext context) {
    return BlocProvider( // Menggunakan BlocProvider untuk menyediakan UniversityBloc ke seluruh aplikasi.
      create: (_) => UniversityBloc(), // Membuat instance dari UniversityBloc.
      child: MaterialApp( // Root widget aplikasi menggunakan MaterialApp.
        title: 'Universities in ASEAN', // Judul aplikasi.
        theme: ThemeData( // Tema aplikasi.
          primarySwatch: Colors.blue, // Warna primer aplikasi.
        ),
        home: UniversityList(), // Widget beranda aplikasi.
      ),
    );
  }
}

class UniversityList extends StatelessWidget { // Deklarasi kelas UniversityList untuk menampilkan daftar universitas.
  final List<String> countries = [ // Daftar negara ASEAN.
    'Indonesia',
    'Singapore',
    'Malaysia',
    'Thailand',
    'Philippines',
    'Vietnam',
    'Brunei',
    'Myanmar',
    'Laos',
    'Cambodia'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Menggunakan Scaffold sebagai kerangka aplikasi.
      appBar: AppBar( // AppBar sebagai bagian atas aplikasi.
        title: Text('Universities in ASEAN'), // Judul AppBar.
      ),
      body: Column( // Menggunakan Column untuk tata letak vertikal.
        children: [
          Padding( // Padding untuk memberikan ruang di sekitar DropdownButton.
            padding: EdgeInsets.all(8.0),
            child: DropdownButton<String>( // DropdownButton untuk memilih negara.
              value: context.watch<UniversityBloc>().state.selectedCountry, // Nilai dropdown berasal dari negara yang dipilih di state.
              onChanged: (newCountry) {
                context
                    .read<UniversityBloc>()
                    .add(SelectCountryEvent(newCountry!)); // Memperbarui state dengan memilih negara baru.
              },
              items: countries.map((String country) { // Mengonversi daftar negara menjadi item DropdownButton.
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
            ),
          ),
          Expanded( // Expanded untuk memperluas daftar universitas agar memenuhi sisa ruang.
            child: BlocBuilder<UniversityBloc, UniversityState>( // BlocBuilder untuk membangun UI berdasarkan state UniversityBloc.
              builder: (context, state) {
                if (state.isLoading) { // Jika sedang memuat.
                  return Center(child: CircularProgressIndicator()); // Tampilkan indikator loading.
                } else if (state.error.isNotEmpty) { // Jika ada kesalahan.
                  return Center(child: Text('Error: ${state.error}')); // Tampilkan pesan kesalahan.
                } else { // Jika tidak ada kesalahan.
                  return ListView.builder( // ListView untuk menampilkan daftar universitas.
                    itemCount: state.universities.length,
                    itemBuilder: (context, index) {
                      University university = state.universities[index]; // Mendapatkan universitas dari daftar universitas di state.
                      return Card( // Card untuk menampilkan universitas dalam bentuk kartu.
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: Icon(Icons.school, color: Colors.blue), // Icon sekolah di sebelah kiri.
                          title: Text(university.name, // Nama universitas sebagai judul.
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle:
                              Text('Website: ${university.website.join(', ')}'), // Website universitas sebagai subjudul.
                          trailing: IconButton( // IconButton untuk membuka website universitas.
                            icon: Icon(Icons.open_in_new, color: Colors.blue),
                            onPressed: () {
                              // Implementasi membuka website universitas
                              // dengan menggunakan URL di university.website[0]
                            },
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
