# 示例音效包目录

此目录用于存放预制的示例音效包文件（`.msb` 格式）。

## 使用说明

1. 将你制作好的 `.msb` 音效包文件放在此目录
2. 文件必须命名为 `示例音效包.msb`（与 `AppConstants.samplePackName` 一致）
3. 音效包应该是 `category` 类型或 `multiple` 类型的导出文件

## 如何创建示例音效包

1. 在应用中添加你想要作为示例的音效
2. 设置好分类（建议使用有意义的分类名称）
3. 使用"导出当前分类"功能导出为 `.msb` 文件
4. 将导出的文件重命名为 `示例音效包.msb` 并放到此目录

## 音效包格式说明

`.msb` 文件是一个 JSON 格式的文件，包含：
- `version`: 版本号
- `type`: 类型（`sound`/`multiple`/`category`/`full`）
- `category`: 分类名称（仅 `category` 类型）
- `data` 或 `sounds`: 音效数据数组
- `exportedAt`: 导出时间

每个音效包含：
- `name`: 音效名称
- `category`: 分类
- `soundData`: Base64 编码的音频文件
- `soundFileName`: 音频文件名
- `imageData`: Base64 编码的图片文件（可选）
- `imageFileName`: 图片文件名（可选）
- `dominantColor`: 主色调（可选）
