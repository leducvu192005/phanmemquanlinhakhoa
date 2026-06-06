import 'package:flutter/material.dart';

class ClinicDetailScreen extends StatelessWidget {
  const ClinicDetailScreen({super.key});

  final Color primaryColor = const Color(0xFF0D9488);
  final Color accentColor = const Color(0xFF2DD4BF);
  final Color bgLight = const Color(0xFFF0FDFA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Giới thiệu Nha Khoa Sáng Răng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: primaryColor.withOpacity(0.2), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner & Overview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.healing, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'NHA KHOA SÁNG RĂNG',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Kiến tạo nụ cười rạng rỡ - Bảo vệ sức khỏe răng miệng toàn diện',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Được thành lập từ năm 2016, Nha Khoa Sáng Răng tự hào là thương hiệu chăm sóc răng miệng uy tín hàng đầu tại Việt Nam. Chúng tôi cam kết mang lại chất lượng điều trị tiêu chuẩn y khoa quốc tế kết hợp cùng sự phục vụ tận tâm và trang thiết bị hiện đại bậc nhất.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Triết lý & Sứ mệnh
            _buildSectionTitle('Sứ mệnh & Triết lý hoạt động'),
            _buildPhilosophyCard(),
            const SizedBox(height: 24),

            // Đội ngũ Bác sĩ
            _buildSectionTitle('Đội ngũ Bác sĩ chuyên gia'),
            _buildDoctorsList(),
            const SizedBox(height: 24),

            // Cơ sở vật chất
            _buildSectionTitle('Công nghệ & Cơ sở vật chất'),
            _buildFacilitiesCard(),
            const SizedBox(height: 24),

            // Cam kết chất lượng
            _buildSectionTitle('Cam kết & Chính sách bảo hành'),
            _buildCommitmentCard(),
            const SizedBox(height: 24),

            // Thông tin liên hệ
            _buildSectionTitle('Thông tin liên hệ & Giờ làm việc'),
            _buildContactCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildPhilosophyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Lấy khách hàng làm trọng tâm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Chúng tôi tin rằng mỗi khách hàng đều xứng đáng có một nụ cười đẹp và khỏe mạnh. Mọi chỉ định điều trị tại Nha Khoa Sáng Răng luôn dựa trên nguyên tắc tối thiểu xâm lấn, bảo tồn tối đa răng thật và mang lại sự thoải mái tuyệt đối cho bệnh nhân.',
            style: TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsList() {
    final doctors = [
      {
        'name': 'BS. CKII. Nguyễn Văn Cường',
        'role': 'Giám đốc chuyên môn',
        'exp': 'Hơn 15 năm kinh nghiệm nha khoa thẩm mỹ & Implant.',
        'edu': 'Tốt nghiệp Đại học Y Dược TP. HCM, tu nghiệp Implant tại ĐH Columbia (Mỹ).',
      },
      {
        'name': 'ThS. BS. Trần Thị Mai',
        'role': 'Trưởng khoa Niềng răng Chuyên sâu',
        'exp': 'Điều trị thành công hơn 2,000 ca chỉnh nha từ đơn giản đến phức tạp.',
        'edu': 'Tốt nghiệp Thạc sĩ Chỉnh nha tại Pháp (ĐH Bordeaux).',
      },
      {
        'name': 'BS. CKI. Lê Hoàng Nam',
        'role': 'Bác sĩ điều trị Nha khoa Tổng quát & Tiểu phẫu',
        'exp': 'Chuyên gia nhổ răng khôn không đau, điều trị tủy công nghệ sóng siêu âm.',
        'edu': 'Thành viên Hiệp hội Nha khoa Việt Nam.',
      }
    ];

    return Column(
      children: doctors.map((doc) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Text(
                doc['name']!.split(' ').last[0],
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doc['role']!,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: primaryColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doc['exp']!,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Học vấn: ${doc['edu']!}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.black38, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildFacilitiesCard() {
    final techItems = [
      {'name': 'Máy quét dấu hàm iTero Element 5D', 'desc': 'Quét dấu răng nhanh trong 60 giây, mô phỏng kết quả niềng răng trước sau chính xác.'},
      {'name': 'Hệ thống chụp CT Cone Beam 3D', 'desc': 'Khảo sát cấu trúc xương hàm đa chiều, hỗ trợ cấy ghép Implant an toàn tuyệt đối.'},
      {'name': 'Hệ thống vô trùng tiêu chuẩn Châu Âu', 'desc': 'Quy trình khử trùng khép kín Class B đảm bảo ngăn chặn 100% lây nhiễm chéo.'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: techItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['desc']!,
                      style: const TextStyle(fontSize: 11.5, color: Colors.black45, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCommitmentCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: const Column(
        children: [
          _CommitItem(title: 'Bảo hành minh bạch', desc: 'Chính sách bảo hành lên tới 10 năm cho răng sứ và trọn đời đối với trụ Implant chính hãng.'),
          _CommitItem(title: 'Vật liệu chính hãng', desc: '100% vật liệu sứ, trụ Implant, khay niềng răng có nguồn gốc rõ ràng, đầy đủ thẻ bảo hành quốc tế.'),
          _CommitItem(title: 'Chi phí công khai', desc: 'Bảng giá niêm yết rõ ràng, cam kết không phát sinh bất kỳ khoản phụ phí ngoài thỏa thuận ban đầu.'),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildContactRow(Icons.location_on_outlined, 'Cơ sở chính: 123 Đường Ba Tháng Hai, Quận 10, TP. Hồ Chí Minh'),
          const Divider(height: 20),
          _buildContactRow(Icons.phone_in_talk_outlined, 'Hotline hỗ trợ & Đặt lịch: 1900 6789'),
          const Divider(height: 20),
          _buildContactRow(Icons.email_outlined, 'Email liên hệ: info@nhakhoasangrang.vn'),
          const Divider(height: 20),
          _buildContactRow(Icons.access_time_outlined, 'Giờ làm việc: 08:00 - 20:00 (Thứ 2 đến Chủ nhật)'),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _CommitItem extends StatelessWidget {
  final String title;
  final String desc;
  const _CommitItem({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield, color: Colors.blueAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11.5, color: Colors.black45, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
