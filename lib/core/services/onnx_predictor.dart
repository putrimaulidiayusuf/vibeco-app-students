import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

class OnnxPredictor {
  static final OnnxPredictor _instance = OnnxPredictor._internal();
  factory OnnxPredictor() => _instance;
  OnnxPredictor._internal();

  OrtSession? _session;
  final List<String> _classNames = [
    "glass",
    "hazardous",
    "metal",
    "organic",
    "paper",
    "plastic",
    "textile",
  ];

  // Diverse Responses Database (in Indonesian)
  final Map<String, Map<String, List<String>>> _wasteInfoDb = {
    "paper": {
      "disposal": [
        "Buang kertas bersih ke tempat sampah khusus kertas. Pastikan kering dan terbebas dari sisa makanan.",
        "Masukkan kertas yang bersih ke dalam kotak daur ulang kertas. Hindari mencampurnya dengan sampah basah.",
        "Tempatkan di tempat penampungan kertas daur ulang. Pastikan tidak ada minyak atau kuah sisa makanan ya!"
      ],
      "recycling": [
        "Bisa didaur ulang menjadi kerajinan kertas buatan tangan (handmade paper), pembatas buku, kotak hiasan, atau kemasan ramah lingkungan.",
        "Kertas bekas sangat bagus dibuat menjadi bubur kertas untuk kerajinan tangan, topeng karton, atau pot tanaman organik.",
        "Dapat diolah kembali menjadi kertas baru, notes estetik, atau kantong belanja kertas (paper bag)."
      ],
      "impact": [
        "Mendaur ulang kertas menghemat jutaan pohon di hutan, mengurangi konsumsi air bersih, dan menekan emisi gas rumah kaca secara signifikan.",
        "Setiap ton kertas daur ulang menyelamatkan sekitar 17 pohon dewasa dan menghemat energi listrik yang besar.",
        "Membantu mengurangi tumpukan sampah di TPA (Tempat Pemrosesan Akhir) dan menjaga paru-paru bumi."
      ],
      "notes": [
        "Kertas yang kotor oleh minyak (seperti kardus pizza bekas atau kertas bungkus nasi) tidak bisa didaur ulang dan harus dibuang ke sampah organik.",
        "Struk belanja thermal (menggunakan tinta kimia) sebaiknya dibuang ke tempat sampah umum/residu karena mengandung bahan BPA.",
        "Selalu lepaskan staples, klip logam, atau selotip plastik sebelum menyalurkan kertas untuk didaur ulang."
      ]
    },
    "metal": {
      "disposal": [
        "Bilas kaleng logam atau botol kaleng terlebih dahulu, lalu masukkan ke dalam tong sampah daur ulang logam/anorganik.",
        "Bersihkan sisa isi kaleng logam dan buang ke wadah sampah khusus logam.",
        "Masukkan ke tempat sampah kuning atau anorganik logam setelah dibilas bersih."
      ],
      "recycling": [
        "Bisa didaur ulang 100% menjadi kaleng baru secara terus-menerus, atau dikreasikan menjadi tempat pensil, vas tanaman mini, dan dekorasi rumah.",
        "Logam dapat dilebur kembali menjadi bahan baku konstruksi, peralatan rumah tangga, atau dekorasi gantungan kunci.",
        "Dapat disalurkan ke bank sampah untuk dilebur ulang menjadi lembaran kaleng baru."
      ],
      "impact": [
        "Mendaur ulang aluminium menghemat hingga 95% energi yang dibutuhkan untuk memproduksi logam baru dari bijih mentah tambang.",
        "Sangat ramah lingkungan karena menekan polusi udara dan kerusakan alam akibat penambangan bauksit/besi.",
        "Mengurangi emisi karbon secara drastis dibanding proses ekstraksi logam mentah."
      ],
      "notes": [
        "Pastikan wadah aerosol (seperti semprotan parfum/obat nyamuk) sudah benar-benar kosong agar tidak memicu ledakan di tempat pemrosesan sampah.",
        "Hindari mencampur tutup botol logam kecil ke dalam sampah plastik biasa agar mudah disortir magnetik.",
        "Logam yang berkarat parah tetap dapat didaur ulang melalui proses peleburan industri."
      ]
    },
    "organic": {
      "disposal": [
        "Buang ke tempat sampah organik (hijau). Sampah ini akan terurai secara alami oleh mikroorganisme.",
        "Tempatkan di tempat sampah sisa makanan/dedaunan untuk diolah lebih lanjut.",
        "Masukkan ke wadah kompos mandiri di rumah atau tong sampah organik hijau."
      ],
      "recycling": [
        "Sangat bagus diolah menjadi pupuk kompos alami, cairan eco-enzyme untuk pembersih ramah lingkungan, atau difermentasi menjadi biogas.",
        "Dapat dibuat kompos penyubur tanaman pot, pupuk organik cair, atau pakan maggot black soldier fly (BSF).",
        "Bisa diolah menjadi kompos padat untuk kebun sekolah atau pelet pupuk alami."
      ],
      "impact": [
        "Mengurangi tumpukan sampah organik di TPA yang menjadi sumber gas metana penyebab efek rumah kaca.",
        "Menyuburkan tanah sekolah secara alami dan mengembalikan nutrisi penting ke dalam ekosistem mikro.",
        "Mencegah pencemaran air lindi sampah di pemukiman sekitar sekolah."
      ],
      "notes": [
        "Jangan mencampurkan sisa daging berlemak atau produk olahan susu dalam jumlah besar ke kompos rumahan biasa karena bisa mengundang bau menyengat dan hama.",
        "Pastikan tidak ada tusuk sate kayu tajam atau sisa bungkus plastik yang ikut terbuang ke sampah organik.",
        "Dedaunan kering sangat bagus dicampur dengan sampah basah sisa buah untuk menyeimbangkan karbon nitrogen pupuk."
      ]
    },
    "hazardous": {
      "disposal": [
        "Bawa sampah B3 (Bahan Berbahaya dan Beracun) ke tempat pengumpulan khusus atau pos penampungan sampah elektronik terdekat.",
        "Masukkan ke kotak pembuangan khusus baterai/bohlam bekas dan jauhkan dari jangkauan anak-anak.",
        "Bungkus baterai/cairan kimia bocor dengan plastik tebal sebelum menyerahkannya ke petugas pengelola limbah khusus B3."
      ],
      "recycling": [
        "Hanya dapat didaur ulang oleh industri berizin khusus untuk mengekstrak logam berharga dari sirkuit elektronik atau menetralisir racun.",
        "Kerajinan mandiri tidak disarankan demi alasan keamanan kesehatan karena mengandung merkuri atau timbal.",
        "Dapat diolah secara profesional untuk diambil kandungan nikel, litium, atau tembaga di dalam baterai bekas."
      ],
      "impact": [
        "Mencegah zat berbahaya seperti timbal, merkuri, dan asam baterai merembes ke air tanah yang dapat meracuni sumber air minum warga.",
        "Menghindari paparan racun langsung pada tanah sekitar sekolah yang bisa mematikan tanaman dan biota tanah.",
        "Melindungi ekosistem sungai dan saluran drainase dari pencemaran zat kimia aktif berbahaya."
      ],
      "notes": [
        "Baterai bekas, lampu LED/bohlam, obat-obatan kadaluarsa, botol racun serangga, dan termometer raksa adalah contoh limbah beracun B3.",
        "JANGAN PERNAH membakar sampah B3 karena asap pembakarannya mengandung racun sangat berbahaya bagi sistem pernapasan manusia.",
        "Jangan mencampur limbah B3 ke dalam tong sampah umum anorganik biasa demi keselamatan petugas kebersihan."
      ]
    },
    "textile": {
      "disposal": [
        "Kumpulkan pakaian layak pakai untuk disumbangkan. Pakaian robek/rusak disalurkan ke pos daur ulang kain.",
        "Tempatkan baju bekas di drop box donasi pakaian atau pilah sebagai limbah tekstil.",
        "Pisahkan pakaian bersih yang sudah tidak terpakai dari sampah rumah tangga basah."
      ],
      "recycling": [
        "Dapat dikreasikan menjadi kain lap bersih, tas kain belanja (tote bag), sarung bantal patchwork (kain perca), atau boneka kain.",
        "Kain katun bekas sangat bagus untuk kerajinan tali makrame, keset kaki rajutan, atau bantalan kursi santai.",
        "Industri mendaur ulangnya menjadi serat benang baru untuk pakaian daur ulang atau bahan isolator panas."
      ],
      "impact": [
        "Menekan limbah industri pakaian (fast fashion) yang merupakan salah satu pencemar lingkungan terbesar di dunia.",
        "Menghemat air dalam jumlah sangat besar yang biasanya dipakai dalam proses produksi pewarnaan tekstil baru.",
        "Mengurangi volume sampah kain sintetis di TPA yang sulit terurai secara alami."
      ],
      "notes": [
        "Pastikan kain dalam kondisi bersih dan kering sebelum didaur ulang agar tidak menimbulkan jamur dan bau tidak sedap.",
        "Gunting kancing plastik atau ritsleting logam dari baju bekas sebelum menggunakannya sebagai kain lap atau kerajinan perca.",
        "Serat sintetis seperti polyester membutuhkan waktu ratusan tahun untuk hancur di alam bebas."
      ]
    },
    "glass": {
      "disposal": [
        "Cuci bersih botol atau toples kaca, lalu masukkan ke dalam tong sampah daur ulang kaca/anorganik khusus.",
        "Bersihkan sisa cairan di dalam botol kaca dan tempatkan di tempat pembuangan anorganik.",
        "Kumpulkan toples kaca bersih ke dalam tempat sampah khusus kaca agar tidak bercampur sampah lainnya."
      ],
      "recycling": [
        "Bisa didaur ulang tanpa batas waktu tanpa penurunan kualitas produk, atau digunakan kembali sebagai toples bumbu dapur, vas bunga, dan tempat lilin estetik.",
        "Kaca dapat dicairkan kembali secara industri menjadi botol kaca baru atau diolah menjadi ubin kaca.",
        "Toples kaca bekas bisa disulap menjadi tempat penyimpanan makanan kering yang aman dan higienis."
      ],
      "impact": [
        "Mengurangi eksploitasi pasir silika di alam liar dan menghemat energi peleburan kaca baru hingga 30%.",
        "Mengurangi polusi udara pabrik kaca baru karena peleburan beling bekas membutuhkan suhu pembakaran lebih rendah.",
        "Menjaga lingkungan dari pecahan beling berbahaya yang bisa melukai makhluk hidup."
      ],
      "notes": [
        "Pecahan kaca tajam harus dibungkus koran bekas tebal and ditandai tulisan 'Awas Pecahan Kaca' sebelum dibuang agar aman bagi petugas kebersihan.",
        "Cermin dan lampu bohlam memiliki kandungan kimia yang berbeda dari kaca botol biasa, sehingga tidak boleh disatukan dalam wadah daur ulang kaca.",
        "Pastikan tutup plastik atau gabus botol kaca dilepas terlebih dahulu sebelum didaur ulang."
      ]
    },
    "plastic": {
      "disposal": [
        "Bilas wadah plastik bekas makanan, keringkan, lalu masukkan ke tong sampah plastik/anorganik.",
        "Remas botol plastik PET agar kempes untuk menghemat tempat, lalu buang ke tempat sampah plastik khusus.",
        "Pilah sampah plastik bersih dari sampah basah dan masukkan ke tempat penampungan anorganik daur ulang."
      ],
      "recycling": [
        "Dapat diolah kembali menjadi paving block ramah lingkungan, benang polyester pakaian, pot gantung tanaman, atau kerajinan kreatif.",
        "Botol plastik bekas bisa dibuat menjadi celengan anak, wadah alat tulis, atau hiasan lampu gantung.",
        "Bisa disalurkan ke bank sampah untuk dicacah industri menjadi bijih plastik daur ulang yang bernilai ekonomis."
      ],
      "impact": [
        "Mengurangi pencemaran sampah mikroplastik di lautan yang meracuni terumbu karang dan rantai makanan laut.",
        "Menghemat penggunaan minyak bumi sebagai bahan utama pembuatan bijih plastik murni.",
        "Mencegah penyumbatan saluran air yang sering memicu banjir di perkotaan saat musim hujan."
      ],
      "notes": [
        "Plastik sekali pakai (kresek tipis dan sedotan) sangat sulit didaur ulang secara ekonomi, sehingga cara terbaik adalah menolak penggunaannya.",
        "Periksa simbol segitiga kode daur ulang di bawah wadah (PETE 1, HDPE 2 adalah yang paling mudah diterima bank sampah).",
        "Rendam label stiker kertas pada botol plastik dan lepaskan agar bijih plastik daur ulang bersih optimal."
      ]
    }
  };

  Future<void> initialize() async {
    if (_session != null) return;
    try {
      final ort = OnnxRuntime();
      _session = await ort.createSessionFromAsset('assets/vibecomodel.onnx');
    } catch (e) {
      debugPrint("Failed to initialize ONNX Runtime session: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> predict(String imagePath) async {
    await initialize();
    if (_session == null) {
      throw StateError("ONNX session is not initialized");
    }

    try {
      final File imageFile = File(imagePath);
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw ArgumentError("Failed to decode image at $imagePath");
      }

      final img.Image resized = img.copyResize(decoded, width: 224, height: 224, interpolation: img.Interpolation.linear);

      final Float32List inputData = Float32List(1 * 3 * 224 * 224);
      final int size = 224 * 224;

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final img.Pixel pixel = resized.getPixel(x, y);
          final double r = pixel.r / 255.0;
          final double g = pixel.g / 255.0;
          final double b = pixel.b / 255.0;

          final double rNorm = (r - 0.485) / 0.229;
          final double gNorm = (g - 0.456) / 0.224;
          final double bNorm = (b - 0.406) / 0.225;

          final int pixelIndex = y * 224 + x;
          inputData[pixelIndex] = rNorm;
          inputData[size + pixelIndex] = gNorm;
          inputData[2 * size + pixelIndex] = bNorm;
        }
      }

      final inputNames = _session!.inputNames;
      final String inputName = inputNames.isNotEmpty ? inputNames.first : 'input';

      final OrtValue inputTensor = await OrtValue.fromList(inputData, [1, 3, 224, 224]);

      final outputs = await _session!.run({inputName: inputTensor});
      inputTensor.dispose();

      if (outputs.isEmpty) {
        throw StateError("Model inference returned no outputs");
      }

      final String outputName = _session!.outputNames.isNotEmpty ? _session!.outputNames.first : 'output';
      final OrtValue outputVal = outputs[outputName]!;

      final List<dynamic> outputList = await outputVal.asList();
      final List<double> scores = (outputList.first as List<dynamic>).cast<double>();

      for (final tensor in outputs.values) {
        tensor.dispose();
      }

      double maxVal = scores.reduce(max);
      List<double> expScores = scores.map((s) => exp(s - maxVal)).toList();
      double sumExp = expScores.reduce((a, b) => a + b);
      List<double> probabilities = expScores.map((e) => e / sumExp).toList();

      int bestIdx = 0;
      double maxProb = 0.0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          bestIdx = i;
        }
      }

      final String rawClass = _classNames[bestIdx];
      final double confidence = maxProb;

      final random = Random();
      final Map<String, List<String>>? wasteInfo = _wasteInfoDb[rawClass];

      String disposal = "N/A";
      String recycling = "N/A";
      String impact = "N/A";
      String notes = "N/A";

      if (wasteInfo != null) {
        final disposalList = wasteInfo["disposal"] ?? ["N/A"];
        final recyclingList = wasteInfo["recycling"] ?? ["N/A"];
        final impactList = wasteInfo["impact"] ?? ["N/A"];
        final notesList = wasteInfo["notes"] ?? ["N/A"];

        disposal = disposalList[random.nextInt(disposalList.length)];
        recycling = recyclingList[random.nextInt(recyclingList.length)];
        impact = impactList[random.nextInt(impactList.length)];
        notes = notesList[random.nextInt(notesList.length)];
      }

      // Confidence threshold: if below 40%, mark as low confidence
      if (confidence < 0.40) {
        return {
          "success": true,
          "low_confidence": true,
          "class": rawClass.toUpperCase(),
          "confidence": confidence,
          "class_name": _translateCategory(rawClass),
          "disposal": disposal,
          "recycling": recycling,
          "impact": impact,
          "notes": notes,
        };
      }

      return {
        "success": true,
        "low_confidence": false,
        "class": rawClass.toUpperCase(),
        "confidence": confidence,
        "class_name": _translateCategory(rawClass),
        "disposal": disposal,
        "recycling": recycling,
        "impact": impact,
        "notes": notes,
      };
    } catch (e) {
      debugPrint("Prediction failed: $e");
      return {
        "success": false,
        "error": e.toString(),
      };
    }
  }

  String _translateCategory(String englishCategory) {
    switch (englishCategory) {
      case "glass": return "Kaca";
      case "hazardous": return "Limbah B3 (Berbahaya)";
      case "metal": return "Logam / Kaleng";
      case "organic": return "Organik / Sisa Makanan";
      case "paper": return "Kertas";
      case "plastic": return "Plastik";
      case "textile": return "Kain / Tekstil";
      default: return englishCategory.toUpperCase();
    }
  }

  Future<void> dispose() async {
    await _session?.close();
    _session = null;
  }
}
