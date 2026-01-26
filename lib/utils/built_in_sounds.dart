import 'package:flutter/material.dart';
import 'app_constants.dart';

/// @deprecated 此类已被废弃，请使用 AppConstants 中的方法
/// 保留此文件仅用于向后兼容，所有功能已迁移到 AppConstants
/// 
/// 示例音效现在通过预制的 .msb 文件提供，位于 assets/samples/ 目录
/// 欢迎界面和设置中的"导入示例音效"功能现在使用 ImportExportService.importFromAsset()
class BuiltInSounds {
  /// @deprecated 使用 AppConstants.getCategoryIcon() 替代
  static IconData getCategoryIcon(String category) {
    return AppConstants.getCategoryIcon(category);
  }

  /// @deprecated 使用 AppConstants.getCategoryColor() 替代
  static Color getCategoryColor(String category) {
    return AppConstants.getCategoryColor(category);
  }
}
