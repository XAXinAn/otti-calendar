import 'package:flutter/material.dart';

class CategoryPickerPage extends StatelessWidget {
  final String? selectedCategory; // 改为可空

  const CategoryPickerPage({
    super.key,
    this.selectedCategory,
  });

  static const Map<String, Color> _categoryColors = {
    '工作': Color(0xFF2196F3),
    '学习': Color(0xFF4CAF50),
    '个人': Color(0xFFFF9800),
    '生活': Color(0xFF9C27B0),
    '健康': Color(0xFFF44336),
    '运动': Color(0xFF009688),
    '社交': Color(0xFFE91E63),
    '家庭': Color(0xFF3F51B5),
    '差旅': Color(0xFFFFC107),
    '其他': Color(0xFF9E9E9E),
  };

  static const List<Map<String, dynamic>> categories = [
    {'name': '工作', 'icon': Icons.work_outline},
    {'name': '学习', 'icon': Icons.school_outlined},
    {'name': '个人', 'icon': Icons.person_outline},
    {'name': '生活', 'icon': Icons.home_outlined},
    {'name': '健康', 'icon': Icons.favorite_border},
    {'name': '运动', 'icon': Icons.directions_run},
    {'name': '社交', 'icon': Icons.chat_bubble_outline},
    {'name': '家庭', 'icon': Icons.family_restroom},
    {'name': '差旅', 'icon': Icons.flight_takeoff},
    {'name': '其他', 'icon': Icons.more_horiz},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.grey, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 顶部文字提示
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 40.0),
            child: Text(
              '选择分类标签',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 30,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final categoryName = categories[index]['name'];
                  final categoryIcon = categories[index]['icon'];
                  
                  // 修改逻辑：进入页面时不显示选中效果，isSelected 始终为 false
                  const bool isSelected = false; 
                  
                  final Color baseColor = _categoryColors[categoryName] ?? Colors.grey;
                  // 所有图标在选择页均显示为原色
                  final Color itemColor = baseColor;

                  return GestureDetector(
                    onTap: () => Navigator.pop(context, categoryName),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          categoryIcon,
                          size: 32,
                          color: itemColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
